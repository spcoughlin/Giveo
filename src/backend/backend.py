import random
from collections import deque
from copy import deepcopy
import os
import json

# Third-party packages
import numpy as np
import sortedcontainers
from sortedcontainers import SortedList
from pymongo import MongoClient
from fastapi import FastAPI
from fastapi.responses import PlainTextResponse
import h5py

# -----------------
#    Global Data
# -----------------
CLOUD_MONGO_URI = os.getenv("MONGO_URI")
client = MongoClient(CLOUD_MONGO_URI)

cloudDB = client["SwipeApp"]
charitiesCollection = cloudDB["Charities"]

app = FastAPI()

updateQueue = deque()

Events = {
    0: "basic",
    1: "disrupt",
    2: "return",
    3: "gem",
    4: "trending",
    5: "repeat"
}

f = open("tags.json", "r")
Tags = json.load(f)
f.close()


# -----------------
#     Classes
# -----------------
class Database:
    def __init__(self, userFile, nonprofitFile):
        self.userFile = h5py.File(userFile, "a")
        self.nonprofitFile = h5py.File(nonprofitFile, "a")

        self.ensureDatasets(self.userFile, "user")
        self.ensureDatasets(self.userFile, "nonprofit")

    def ensureDatasets(self, file, name):
        if f"{name}_ids" not in file:
            file.create_dataset(f"{name}_ids", shape=(0,), maxshape=(None,), dtype="S12")
            file.create_dataset(f"{name}_vectors", shape=(0, 100), maxshape=(None, 100), dtype=np.float32)

    def addVector(self, file, name, id, vector):
        ids = file[f"{name}_ids"]
        vectors = file[f"{name}_vectors"]

        size = ids.shape[0]

        ids.resize((size + 1,))
        vectors.resize((size + 1, 100))

        ids[size] = id
        vectors[size] = vector

    def addUser(self, id, vector):
        self.addVector(self.userFile, "user", id, vector)

    def addNonprofit(self, id, vector):
        self.addVector(self.nonprofitFile, "nonprofit", id, vector)

    def updateVector(self, file, name, id, newVector):
        ids = file[f"{name}_ids"][:]
        vectors = file[f"{name}_vectors"]

        index = np.where(ids == id)[0]

        vectors[index[0]] = newVector

    def updateUserVector(self, id, newVector):
        self.updateVector(self.userFile, "user", id, newVector)

    def updateNonprofitVector(self, id, newVector):
        self.updateVector(self.nonprofitFile, "nonprofit", id, newVector)

    def get(self, file, name, id):
        ids = file[f"{name}_ids"][:]
        vectors = file[f"{name}_vectors"]
        if id not in ids:
            return None

        index = np.where(ids == id)[0]

        return vectors[index[0]]

    def getUser(self, id):
        self.get(self.userFile, "user", id)

    def getNonprofit(self, id):
        return self.get(self.nonprofitFile, "nonprofit", id)

    def close(self):
        self.userFile.close()
        self.nonprofitFile.close()

    def backup(self):
        self.userFile.close()
        self.nonprofitFile.close()
        self.userFile = h5py.File(self.userFile, "a")
        self.nonprofitFile = h5py.File(self.nonprofitFile, "a")
        self.ensureDatasets(self.userFile, "user")
        self.ensureDatasets(self.userFile, "nonprofit")


database: Database = Database("users.h5", "nonprofits.h5")


class UserTagTable:
    def __init__(self, userID, vector=None):
        self.sorted_list = SortedList()  # stored as (value, tag)
        self.zeroTags = deque()
        if not vector:
            self.data = {tag: .5 for tag in Tags}
        else:
            self.data = {}
            for i in range(len(vector)):
                self.data[i] = vector[i]
                if vector[i] == 0:
                    self.zeroTags.append(i)
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
        clone.data = deepcopy(self.data)  # Dont need deepcopy but :shrug:
        clone.sorted_list = SortedList(self.sorted_list)
        clone.zeroTags = deepcopy(self.zeroTags)
        return clone

    def getCompTags(self):
        """Return top-20 tags (lowest indices in sorted_list) and their values."""
        query = {}
        for i in range(20):
            tag = self.getNthTag(i)
            query[tag] = self.getVal(tag)
        return query

    def getFullVector(self, total_tags=100):
        dictVersion = {}
        for i in range(len(self.data)):
            tag = self.getNthTag(i)
            dictVersion[tag] = self.getVal(tag)
        for i in self.zeroTags:
            dictVersion[i] = 0.0

        vec = np.zeros(total_tags)
        for tag, weight in dictVersion.items():
            vec[tag] = weight
        return vec

    # ---------------
    #    Behaviors
    # ---------------

    def like(self, nonprofit):
        for tag in nonprofit.tags["primary"]:
            val = self.getVal(tag)
            self.set(tag, val + (1 - val) * 0.1)

        for tag in nonprofit.tags["secondary"]:
            val = self.getVal(tag)
            self.set(tag, val + (1 - val) * 0.01)

    def donate(self, nonprofit):
        for tag in nonprofit.tags["primary"]:
            val = self.getVal(tag)
            self.set(tag, val + (1 - val) * 0.25)

        for tag in nonprofit.tags["secondary"]:
            val = self.getVal(tag)
            self.set(tag, val + (1 - val) * 0.025)

    def ignore(self, nonprofit):
        for tag in nonprofit.tags["primary"]:
            val = self.getVal(tag) * 0.9
            self.set(tag, val if val >= 0.0005 else 0)

        for tag in nonprofit.tags["secondary"]:
            val = self.getVal(tag) * 0.99
            self.set(tag, val if val >= 0.0005 else 0)

    def dislike(self, nonprofit):
        for tag in nonprofit.tags["primary"]:
            val = self.getVal(tag) * 0.75
            self.set(tag, val if val >= 0.0005 else 0)

        for tag in nonprofit.tags["secondary"]:
            val = self.getVal(tag) * 0.975
            self.set(tag, val if val >= 0.0005 else 0)


class NonProfit:
    def __init__(self, id, primary, secondary):
        self.id = id
        self.tags = {"primary": primary, "secondary": secondary}


class User:
    def __init__(self, id, vector=None, new=False):
        if new:
            # new user
            self.id = id
            self.tags = UserTagTable(self.id)
            self.vector = compute_query_vectory(self.tags.getCompTags())
        else:
            self.id = id
            self.tags = UserTagTable(self.id, vector=vector) if vector else UserTagTable(self.id)

        self.seenSet = set()
        self.seenQueue = deque()
        self.upcomingSet = set()
        self.upcomingQueue = deque()

    def chooseEvent(self) -> int:
        r = random.randint(0, 99)
        if r == 0:
            return 1
        if r == 1:
            return 2
        if r in range(2, 75):
            return 0
        if r in range(76, 85):
            if -1 in self.tags:
                return 3
            else:
                return 0 if random.getrandbits(1) else 3
        if r in range(86, 95):
            return 4 if -2 in self.getCompTags(0) else 0
        if r in range(96, 99):
            if -3 in self.getCompTags(0):
                return 5
            else:
                return 0 if random.getrandbits(1) else 5

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
                # if len(self.donations) > 0:
                #    np_ = self.donations[random.randint(0, len(self.donations) - 1)]
                #    return np_.tags
                # else:
                return self.tags.getCompTags()
        return self.tags.getCompTags()

    # --------------------
    #   Reaction methods
    # --------------------
    def like(self, nonprofit):
        self.tags.like(nonprofit)
        # nonprofit.updateDynamicTags({-1: self.tags.getVal(-1),
        #                             -2: self.tags.getVal(-2),
        #                             -3: self.tags.getVal(-3)})

    def donate(self, nonprofit, amount):
        self.tags.donate(nonprofit)
        # nonprofit.updateDynamicTags({-1: self.tags.getVal(-1),
        #                             -2: self.tags.getVal(-2),
        #                             -3: self.tags.getVal(-3)})

    def ignore(self, nonprofit):
        self.tags.ignore(nonprofit)

    def dislike(self, nonprofit):
        self.tags.dislike(nonprofit)

    # --------------------
    #   Scheduling / Next
    # --------------------
    def refreshQueue(self):
        # Get the current user query vector (100-dimensional)
        user_vec = self.getCompTags(self.chooseEvent())
        candidates = []

        # Retrieve all nonprofit IDs and vectors from the HDF5 file.
        # (Assumes the nonprofits file has datasets named "nonprofit_ids" and "nonprofit_vectors")
        np_ids = database.nonprofitFile["nonprofit_ids"][:]  # e.g., an array of type S12 (byte strings)
        np_vectors = database.nonprofitFile["nonprofit_vectors"][:]  # shape (N, 100)

        # Loop through every nonprofit in the file.
        for idx, np_id in enumerate(np_ids):
            # Convert id to string if needed (if stored as a byte string)
            charity_id = np_id.decode("utf-8") if isinstance(np_id, bytes) else np_id

            # Skip if this charity has already been seen or is already in the upcoming queue.
            if charity_id in self.seenSet or charity_id in self.upcomingSet:
                continue

            # Get the nonprofit’s stored vector and compute cosine similarity.
            vec = np_vectors[idx]
            sim = cosine_similarity(user_vec, vec)
            candidates.append((sim, charity_id))

        # Sort candidates by similarity (highest first) and take the top 10.
        candidates.sort(key=lambda x: x[0], reverse=True)
        top_ten = candidates[:10]

        # For each selected candidate, re-create the NonProfit object.
        # We “recover” the primary and secondary tag lists by checking which indices in the vector
        # have a value of 10 (primary) or 1 (secondary). This assumes the nonprofit vector was generated
        # using compute_nonprofit_vector.
        for sim, charity_id in top_ten:
            self.upcomingQueue.append(charity_id)
            self.upcomingSet.add(charity_id)

    def getNextN(self, n):
        """
        Pop n items from upcomingQueue, return as JSON.
        If the queue gets too small, refresh it.
        """
        sending = []
        if len(self.upcomingSet) < n:
            self.refreshQueue()
        for _ in range(n):
            sending.append(NP := self.upcomingQueue.popleft())
            self.upcomingSet.remove(NP)
            self.seenQueue.append(NP)
            self.seenSet.add(NP)
            if len(self.seenQueue) > 50:
                byebye = self.seenQueue.popleft()
                self.seenSet.remove(byebye)
        return sending

    def getFullVector(self):
        return self.tags.getFullVector()


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


def react(n: int, user: User, nonProfit: NonProfit, amount=0.0):
    match n:
        case 0:
            user.like(nonProfit)
        case 1:
            user.dislike(nonProfit)
        case 2:
            user.ignore(nonProfit)
        case 3:
            user.donate(nonProfit, amount)
        case _:
            raise Exception("Invalid Reaction")


# ---------------------
#  API
# ---------------------

@app.get("/nextN")
def nextCharity(userID: int, n: int = 3):
    if userID not in OnlineUsers:
        return
    return {"array": OnlineUsers[userID].getNextN(n)}


@app.post("/reaction")
def reaction(userID: int, reactionNum: int, nonprofitID: int, amount: float = 0.0):
    if userID not in OnlineUsers:
        return PlainTextResponse("FAIL: User not online")

    if reactionNum > 3 or reactionNum < 0:
        return PlainTextResponse("FAIL: Invalid reaction number")

    user = OnlineUsers[userID]
    if reactionNum == 3:
        react(3, user, database.getNonprofit(nonprofitID), amount)

    else:
        react(reactionNum, user, database.getNonprofit(nonprofitID))

    return PlainTextResponse("success")


@app.post("/logOn")
def logOn(userID: int):
    # Pull User class data from db and construct a User Object
    user = User(userID, vector=v) if (v := database.getUser(id)) else User(userID)
    OnlineUsers[userID] = user
    return PlainTextResponse("success")


@app.post("/logOff")
def logOut(userID: int):
    # Remove User class, update tags in big (bug) db
    database.updateUserVector(userID, OnlineUsers[userID].getFullVector())
    del OnlineUsers[userID]
    return PlainTextResponse("success")


@app.post("/queueUpdate")
def queueUpdate(nonprofitID: int):
    updateQueue.append(nonprofitID)
    return PlainTextResponse("success")

@app.get("/test")
def test():
    return {"message": "Hello World"}


# Main Methods
def run():
    global database
    database = Database("users.h5", "nonprofits.h5")


def exit():
    database.close()
