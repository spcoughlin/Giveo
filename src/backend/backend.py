import json
import random
from collections import deque
from copy import deepcopy

# Third-party packages
import numpy as np
from sortedcontainers import SortedList

# -----------------
#    Global Data
# -----------------
Tags = {
    # TODO: Add tags
    -1: "gem",
    -2: "trending",
    -3: "repeat"
}

Events = {
    0: "basic",
    1: "disrupt",
    2: "return",
    3: "gem",
    4: "trending",
    5: "repeat"
}

with open("tags.txt", "r") as f:
    for line in f:
        temp = line.split(" : ")
        Tags[int(temp[0])] = temp[1]


# -----------------
#     Classes
# -----------------
class UserTagTable:
    def __init__(self, userID):
        self.data = {tag: 50.0 for tag in Tags}
        self.sorted_list = SortedList()  # stored as (value, tag)
        self.zeroTags = deque()
        # Initialize sorted_list
        for tag, val in self.data.items():
            self.sorted_list.add((val, tag))

    def set(self, tag, val):
        """Update the value for a tag, keep sorted_list in sync."""
        if tag in self.data:
            old_val = self.data[tag]
            # Remove old entry from the sorted structure
            self.sorted_list.remove((old_val, tag))

        self.data[tag] = val
        self.sorted_list.add((val, tag))

        if val == 0:
            # Tag effectively 'zeroed out'
            self.zeroTags.append(tag)
            self.sorted_list.remove((val, tag))
            if len(self.zeroTags) > 25:
                # too many zeroed-out tags => bump the oldest zeroed tag
                self.set(self.zeroTags.popleft(), 10.0)

    def remove(self, tag):
        """Remove a tag from data and sorted_list."""
        if tag in self.data:
            old_val = self.data[tag]
            del self.data[tag]
            self.sorted_list.remove((old_val, tag))

    def getVal(self, tag):
        return self.data[tag]

    def getNthTag(self, n):
        """Get the nth tag in ascending or descending order (using negative index)."""
        if 0 <= abs(n) < len(self.sorted_list):
            return self.sorted_list[n][1]
        raise IndexError("Tag index out of range")

    def swap(self, tag1, tag2):
        """Swap two tag values, used for certain 'disrupt' or 'return' events."""
        self.data[tag1], self.data[tag2] = self.data[tag2], self.data[tag1]

    def clone(self):
        """Deep copy this UserTagTable."""
        clone = UserTagTable(-1)
        clone.data = deepcopy(self.data)
        clone.sorted_list = SortedList(self.sorted_list)
        clone.zeroTags = deepcopy(self.zeroTags)
        return clone

    def getCompTags(self):
        """Return top-20 tags (lowest indices in sorted_list) and their values."""
        query = {}
        limit = min(20, len(self.sorted_list))
        for i in range(limit):
            tag = self.getNthTag(i)
            query[tag] = self.getVal(tag)
        return query

    # ---------------
    #    Behaviors
    # ---------------
    def like(self, nonprofit):
        for tag in nonprofit.tags["primary"]:
            val = self.getVal(tag)
            self.set(tag, val + (100 - val) * 0.1)

        for tag in nonprofit.tags["secondary"]:
            val = self.getVal(tag)
            self.set(tag, val + (100 - val) * 0.01)

    def donate(self, nonprofit):
        for tag in nonprofit.tags["primary"]:
            val = self.getVal(tag)
            self.set(tag, val + (100 - val) * 0.25)

        for tag in nonprofit.tags["secondary"]:
            val = self.getVal(tag)
            self.set(tag, val + (100 - val) * 0.025)

    def ignore(self, nonprofit):
        for tag in nonprofit.tags["primary"]:
            val = self.getVal(tag) * 0.9
            self.set(tag, val if val >= 0.05 else 0)

        for tag in nonprofit.tags["secondary"]:
            val = self.getVal(tag) * 0.99
            self.set(tag, val if val >= 0.05 else 0)

    def dislike(self, nonprofit):
        for tag in nonprofit.tags["primary"]:
            val = self.getVal(tag) * 0.75
            self.set(tag, val if val >= 0.05 else 0)

        for tag in nonprofit.tags["secondary"]:
            val = self.getVal(tag) * 0.975
            self.set(tag, val if val >= 0.05 else 0)


class NonProfit:
    def __init__(self, id, primary, secondary):
        self.id = id
        self.tags = {"primary": primary, "secondary": secondary}
        self.dynamic_tags = {-1: 50.0, -2: 50.0, -3: 50.0}
        self.dtUpdates = 0

    def updateDynamicTags(self, dtVals: dict):
        self.dynamic_tags = {i: self.dynamic_tags[i] * self.dtUpdates for i in self.dynamic_tags}
        self.dtUpdates += 1
        for i in dtVals:
            self.dynamic_tags[i] += dtVals[i]
        self.dynamic_tags = {i: self.dynamic_tags[i]/self.dtUpdates for i in self.dynamic_tags}


class User:
    def __init__(self, id, tags: UserTagTable):
        self.id = id
        self.tags = tags
        self.donations = deque()
        self.seenSet = set()
        self.seenQueue = deque()
        self.upcomingSet = set()
        self.upcomingQueue = deque()

    def chooseEvent(self) -> int:
        """Simulates logic for picking an event (basic, disrupt, return, gem, trending, repeat, etc.)"""
        r = random.randint(0, 99)
        if r == 0:
            return 1  # disrupt
        if r == 1:
            return 2  # return
        if 2 <= r < 75:
            return 0  # basic
        if 75 <= r < 85:
            # gem
            return 3
        if 85 <= r < 95:
            # trending
            return 4
        if 95 <= r < 100:
            # repeat
            return 5

    def getCompTags(self, event) -> dict:
        """
        Return the 'composed' or 'adjusted' tag dictionary for each event scenario.
        """
        match event:
            case 0:
                return self.tags.getCompTags()
            case 1:
                # swap top 3 with bottom 3
                newTags = self.tags.clone()
                newTags.swap(newTags.getNthTag(0), newTags.getNthTag(-1))
                newTags.swap(newTags.getNthTag(1), newTags.getNthTag(-2))
                newTags.swap(newTags.getNthTag(2), newTags.getNthTag(-3))
                return newTags.getCompTags()
            case 2:
                # swap top tag with the oldest zeroed-out
                newTags = self.tags.clone()
                if newTags.zeroTags:
                    zeroed_tag = newTags.zeroTags.popleft()
                    newTags.swap(newTags.getNthTag(0), zeroed_tag)
                return newTags.getCompTags()
            case 3:
                # gem (just a placeholder for searching only gem NPs, etc.)
                return self.tags.getCompTags()
            case 4:
                # trending
                return self.tags.getCompTags()
            case 5:
                # repeat => pick from a random donation’s tags if available
                if len(self.donations) > 0:
                    np_ = self.donations[random.randint(0, len(self.donations) - 1)]
                    return np_.tags
                else:
                    return self.tags.getCompTags()
        return self.tags.getCompTags()

    # --------------------
    #   Reaction methods
    # --------------------
    def like(self, nonprofit):
        self.tags.like(nonprofit)

    def donate(self, nonprofit, amount):
        self.tags.donate(nonprofit)
        self.donations.append(nonprofit)

    def ignore(self, nonprofit):
        self.tags.ignore(nonprofit)

    def dislike(self, nonprofit):
        self.tags.dislike(nonprofit)

    # --------------------
    #   Scheduling / Next
    # --------------------
    def refreshQueue(self):
        """
        Dummy stub: In a real system, you'd query DB or recommendation engine,
        fill `self.upcomingQueue` with new nonprofits, etc.
        """
        pass

    def getNextN(self, n):
        """
        Pop n items from upcomingQueue, return as JSON.
        If the queue gets too small, refresh it.
        """
        sending = []
        for _ in range(n):
            if len(self.upcomingQueue) == 0:
                self.refreshQueue()
                if len(self.upcomingQueue) == 0:
                    # No data to provide
                    break
            NP = self.upcomingQueue.popleft()
            sending.append(NP)
            self.upcomingSet.discard(NP)

        return json.dumps(sending)


# -----------------
#   Vector Stuff
# -----------------
def compute_nonprofit_vector(nonprofit: dict, total_tags=100):
    """
    Build a 100-dimensional vector for a nonprofit
    """
    vec = np.zeros(total_tags)

    for tag in nonprofit.get("primary", []):
        vec[tag] = 10

    for tag in nonprofit.get("secondary", []):
        vec[tag] = 1

    return vec


def compute_query_vectory(query, total_tags=100):
    """
    Build a 100-dimensional vector for a query
    (only top ~20 tags are included, but we allocate 100 slots).
    """
    vec = np.zeros(total_tags)
    for tag, weight in query.items():
        vec[tag] = weight
    return vec


def cosine_similarity(vec1, vec2):
    """
    Compute cosine similarity between two vectors
    """
    dot_prod = np.dot(vec1, vec2)
    norm1 = np.linalg.norm(vec1)
    norm2 = np.linalg.norm(vec2)

    if norm1 == 0 or norm2 == 0:
        return 0.0
    return dot_prod / (norm1 * norm2)


# -----------------
#  Global Stores
# -----------------
OnlineUsers = {
    # userID -> User object
}

# Reactions map to methods on `User`, but each needs a `nonprofit` param if you want to do user.like(nonprofit).
# For a real system, you'd have to pass the chosen NonProfit or ID of the NP to these calls.
Reactions = {
    0: User.like,
    1: User.dislike,
    2: User.ignore,
    3: User.donate
}


# ---------------------
#  Helper “API” methods
# ---------------------
def nextCharity(userID: int, n: int):
    """
    Return next N charities from user’s queue (JSON).
    """
    if userID not in OnlineUsers:
        return json.dumps({"error": "User not found"})
    return OnlineUsers[userID].getNextN(n)


def reaction(userID: int, reactionNum: int, nonprofit: NonProfit = None, amount: float = 0.0):
    """
    Apply a reaction (like, dislike, ignore, donate) on behalf of user.
    If you do 'donate', pass an amount and a nonprofit object or ID.
    """
    if userID not in OnlineUsers:
        return {"error": "User not found"}

    user = OnlineUsers[userID]
    if reactionNum not in Reactions:
        return {"error": f"Invalid reaction {reactionNum}"}

    # Reaction is a bound method, e.g. User.like, which expects user.like(nonprofit)
    # For donate, we do user.donate(nonprofit, amount)
    react_func = Reactions[reactionNum]

    if reactionNum == 3:
        # Donate path
        if nonprofit is None:
            return {"error": "Must provide a nonprofit to donate to."}
        react_func(user, nonprofit, amount)  # user.donate(nonprofit, amount)
        return {"message": "Donation recorded"}
    else:
        # For like, dislike, ignore – we do user.like(nonprofit), etc.
        if nonprofit is None:
            return {"error": "Must provide a nonprofit to apply reaction"}
        react_func(user, nonprofit)
        return {"message": f"Reaction {reactionNum} applied"}


# ================================
#     LAMBDA HANDLER FUNCTIONS
# ================================
def nextCharity_lambda_handler(event, context):
    """
    AWS Lambda handler for 'nextCharity' requests.
    Expects JSON in event["body"]: { "userID": <int>, "n": <int> }
    """
    try:
        body = json.loads(event["body"]) if "body" in event else event
        userID = body.get("userID")
        n = body.get("n", 1)
    except Exception as e:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": f"Invalid input: {str(e)}"})
        }

    result_json = nextCharity(userID, n)
    return {
        "statusCode": 200,
        "body": result_json
    }


def reaction_lambda_handler(event, context):
    """
    AWS Lambda handler for 'reaction' requests.
    Expects JSON in event["body"]:
      {
         "userID": <int>,
         "reactionNum": <int>,
         "nonprofit": { "id": ..., "primary": [...], "secondary": [...] },
         "amount": <float>   (optional, only used if reactionNum=3 = donate)
      }
    """
    try:
        body = json.loads(event["body"]) if "body" in event else event
        userID = body.get("userID")
        reactionNum = body.get("reactionNum")
        nonprofit_dict = body.get("nonprofit")
        amount = body.get("amount", 0.0)

        # Convert nonprofit data to an object if provided
        np_obj = None
        if nonprofit_dict and "id" in nonprofit_dict:
            np_obj = NonProfit(
                id=nonprofit_dict["id"],
                primary=nonprofit_dict.get("primary", []),
                secondary=nonprofit_dict.get("secondary", [])
            )
    except Exception as e:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": f"Invalid input: {str(e)}"})
        }

    reaction_result = reaction(userID, reactionNum, nonprofit=np_obj, amount=amount)

    return {
        "statusCode": 200,
        "body": json.dumps(reaction_result)
    }