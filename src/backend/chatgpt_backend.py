import random
import time
from collections import deque
from copy import deepcopy
import os
import json

# Third-party packages
import numpy as np
from sortedcontainers import SortedList
from fastapi import FastAPI
from fastapi.responses import PlainTextResponse
import h5py

# -----------------
#    Global Data
# -----------------
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

with open("tags.json", "r") as f:
    Tags = json.load(f)


# -----------------
#     Classes
# -----------------

class BiMap:
    def __init__(self, filename="mapping.json"):
        self.filename = filename
        self.string_to_int = {}
        self.int_to_string = {}
        self.count = 0
        self.load()  # Load mappings on startup

    def add(self, key: str):
        """Adds a new mapping."""
        if key in self.string_to_int:
            raise ValueError("Key or value already exists!")
        self.string_to_int[key] = self.count
        self.int_to_string[self.count] = key
        self.count += 1

    def get_int(self, key: str):
        return self.string_to_int.get(key)

    def get_string(self, value: int):
        return self.int_to_string.get(value)

    def save(self):
        """Save mappings to a file."""
        with open(self.filename, "w") as f:
            json.dump({"string_to_int": self.string_to_int}, f)

    def load(self):
        """Load mappings from a file."""
        try:
            with open(self.filename, "r") as f:
                data = json.load(f)
                self.string_to_int = data.get("string_to_int", {})
                self.int_to_string = {v: k for k, v in self.string_to_int.items()}
                self.count = max(self.int_to_string.keys(), default=-1) + 1
        except FileNotFoundError:
            pass  # No file exists yet, start fresh


class Database:
    def __init__(self, userFile, nonprofitFile):
        self.userFile = h5py.File(userFile, "a")
        self.nonprofitFile = h5py.File(nonprofitFile, "a")

        self.ensureDatasets(self.userFile, "user")
        # Make sure the nonprofit datasets go in the nonprofit file!
        self.ensureDatasets(self.nonprofitFile, "nonprofit")

    def _to_bytes(self, id_val):
        """Ensure that IDs are stored as UTF-8–encoded bytes."""
        if isinstance(id_val, str):
            return id_val.encode("utf-8")
        return id_val

    def ensureDatasets(self, file, name):
        if f"{name}_ids" not in file:
            file.create_dataset(f"{name}_ids", shape=(0,), maxshape=(None,), dtype="S12")
            file.create_dataset(f"{name}_vectors", shape=(0, 100), maxshape=(None, 100), dtype=np.float32)

    def addVector(self, file, name, id_val, vector):
        ids = file[f"{name}_ids"]
        vectors = file[f"{name}_vectors"]

        size = ids.shape[0]
        ids.resize((size + 1,))
        vectors.resize((size + 1, 100))

        ids[size] = self._to_bytes(id_val)
        vectors[size] = vector

    def addUser(self, id_val, vector):
        self.addVector(self.userFile, "user", id_val, vector)

    def addNonprofit(self, id_val, vector):
        self.addVector(self.nonprofitFile, "nonprofit", id_val, vector)

    def updateVector(self, file, name, id_val, newVector):
        id_bytes = self._to_bytes(id_val)
        ids = file[f"{name}_ids"][:]
        vectors = file[f"{name}_vectors"]

        index = np.where(ids == id_bytes)[0]
        if index.size == 0:
            raise ValueError(f"ID {id_val} not found in dataset {name}")
        vectors[index[0]] = newVector

    def updateUserVector(self, id_val, newVector):
        self.updateVector(self.userFile, "user", id_val, newVector)

    def updateNonprofitVector(self, id_val, newVector):
        self.updateVector(self.nonprofitFile, "nonprofit", id_val, newVector)

    def get(self, file, name, id_val):
        id_bytes = self._to_bytes(id_val)
        ids = file[f"{name}_ids"][:]
        vectors = file[f"{name}_vectors"]
        if id_bytes not in ids:
            return None

        index = np.where(ids == id_bytes)[0]
        return vectors[index[0]]

    def getUser(self, id_val):
        return self.get(self.userFile, "user", id_val)

    def getNonprofitVector(self, id_val):
        return self.get(self.nonprofitFile, "nonprofit", id_val)

    def getNonprofit(self, id_val):
        """
        For reaction purposes, we query the MongoDB charities collection
        and instantiate a NonProfit object.
        """
        doc = charitiesCollection.find_one({"_id": id_val})
        if doc is None:
            return None
        primary = doc.get("primary", [])
        secondary = doc.get("secondary", [])
        return NonProfit(id_val, primary, secondary)

    def close(self):
        self.userFile.close()
        self.nonprofitFile.close()

    def backup(self):
        self.userFile.close()
        self.nonprofitFile.close()
        self.userFile = h5py.File(self.userFile.filename, "a")
        self.nonprofitFile = h5py.File(self.nonprofitFile.filename, "a")
        self.ensureDatasets(self.userFile, "user")
        self.ensureDatasets(self.nonprofitFile, "nonprofit")


database: Database = Database("users.h5", "nonprofits.h5")


class UserTagTable:
    def __init__(self, userID, vector=None):
        self.sorted_list = SortedList()  # stored as (value, tag)
        self.zeroTags = deque()
        if vector is None:
            self.data = {int(tag): 0.5 for tag in Tags}  # assume Tags can be cast to int keys
        else:
            self.data = {}
            for i in range(len(vector)):
                self.data[i] = float(vector[i])
                if vector[i] == 0:
                    self.zeroTags.append(i)
        # Initialize sorted_list
        for tag, val in self.data.items():
            self.sorted_list.add((val, tag))

    def set(self, tag, val):
        # Remove any old value from the sorted list if present.
        if tag in self.data:
            old_val = self.data[tag]
            try:
                self.sorted_list.remove((old_val, tag))
            except ValueError:
                pass  # In case it isn’t in the sorted list for some reason.
        self.data[tag] = val
        self.sorted_list.add((val, tag))
    
        if val == 0:
            # Tag effectively 'zeroed out'
            self.zeroTags.append(tag)
            try:
                self.sorted_list.remove((val, tag))
            except ValueError:
                pass
    
        # Instead of a recursive call, process the zeroTags queue iteratively.
        while len(self.zeroTags) > 25:
            bumped_tag = self.zeroTags.popleft()
            # Directly update the tag value to 10.0 without calling set() recursively.
            if bumped_tag in self.data:
                old_val = self.data[bumped_tag]
                try:
                    self.sorted_list.remove((old_val, bumped_tag))
                except ValueError:
                    pass
            self.data[bumped_tag] = 10.0
            self.sorted_list.add((10.0, bumped_tag))

    
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
        # Rebuild sorted_list (for simplicity)
        self.sorted_list = SortedList(((v, t) for t, v in self.data.items()))

    def clone(self):
        """Deep copy this UserTagTable."""
        clone = UserTagTable(-1)
        clone.data = deepcopy(self.data)
        clone.sorted_list = SortedList(self.sorted_list)
        clone.zeroTags = deepcopy(self.zeroTags)
        return clone

    def getCompTags(self):
        """Return top-20 tags (lowest values in sorted_list) and their values."""
        query = {}
        # It is assumed that the sorted_list has at least 20 elements.
        for i in range(min(20, len(self.sorted_list))):
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

        vec = np.zeros(total_tags, dtype=np.float32)
        for tag, weight in dictVersion.items():
            if tag < total_tags:
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
            new_val = self.getVal(tag) * 0.9
            self.set(tag, new_val if new_val >= 0.0005 else 0)

        for tag in nonprofit.tags["secondary"]:
            new_val = self.getVal(tag) * 0.99
            self.set(tag, new_val if new_val >= 0.0005 else 0)

    def dislike(self, nonprofit):
        for tag in nonprofit.tags["primary"]:
            new_val = self.getVal(tag) * 0.75
            self.set(tag, new_val if new_val >= 0.0005 else 0)

        for tag in nonprofit.tags["secondary"]:
            new_val = self.getVal(tag) * 0.975
            self.set(tag, new_val if new_val >= 0.0005 else 0)


class NonProfit:
    def __init__(self, id_val, primary, secondary):
        self.id = id_val
        self.tags = {"primary": primary, "secondary": secondary}


class User:
    def __init__(self, id_val, vector=None, new=False):
        if new:
            # new user
            self.id = id_val
            self.tags = UserTagTable(self.id)
            # Compute and store the full query vector (from the top tags)
            self.vector = compute_query_vectory(self.tags.getCompTags())
            UserMap.add(id_val)
        else:
            self.id = id_val
            # If a stored vector exists, build the tag table from it.
            self.tags = UserTagTable(self.id, vector=vector) if vector is not None else UserTagTable(self.id)

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
        if 2 <= r < 75:
            return 0
        if 76 <= r < 85:
            # check for special tag -1 in the tag data
            if -1 in self.tags.data:
                return 3
            else:
                return 0 if random.getrandbits(1) else 3
        if 86 <= r < 95:
            return 4 if -2 in self.tags.data else 0
        if 96 <= r < 99:
            return 5 if -3 in self.tags.data else (0 if random.getrandbits(1) else 5)
        return 0

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
                # gem (placeholder for specialized nonprofit searches)
                return self.tags.getCompTags()
            case 4:
                # trending
                return self.tags.getCompTags()
            case 5:
                # repeat – could pick from a random donation’s tags if available
                return self.tags.getCompTags()
        return self.tags.getCompTags()

    # --------------------
    #   Reaction methods
    # --------------------
    def like(self, nonprofit):
        self.tags.like(nonprofit)

    def donate(self, nonprofit, amount):
        self.tags.donate(nonprofit)

    def ignore(self, nonprofit):
        self.tags.ignore(nonprofit)

    def dislike(self, nonprofit):
        self.tags.dislike(nonprofit)

    # --------------------
    #   Scheduling / Next
    # --------------------

    def refreshQueue(self):
        """
        Refresh the upcomingQueue with new charity IDs.
        If all charities have been seen, clear the seen-set so that charities may be repeated.
        """
        # Get the current user query vector (100-dimensional)
        user_query = self.getCompTags(self.chooseEvent())
        user_vec = compute_query_vectory(user_query)
        candidates = []

        # Retrieve all nonprofit IDs and vectors from the HDF5 file.
        np_ids = database.nonprofitFile["nonprofit_ids"][:]  # stored as byte strings
        np_vectors = database.nonprofitFile["nonprofit_vectors"][:]  # shape (N, 100)

        # First pass: Filter out charities already seen or queued.
        for idx, np_id in enumerate(np_ids):
            charity_id = np_id.decode("utf-8") if isinstance(np_id, bytes) else np_id

            if charity_id in self.seenSet or charity_id in self.upcomingSet:
                continue

            vec = np_vectors[idx]
            sim = cosine_similarity(user_vec, vec)
            candidates.append((sim, charity_id))

        # If no candidates are found, assume the user has seen everything.
        # Clear the seen history so charities can be re-queued.
        if not candidates:
            self.seenSet.clear()
            self.seenQueue.clear()
            # Re-run candidate selection without filtering on seenSet.
            for idx, np_id in enumerate(np_ids):
                charity_id = np_id.decode("utf-8") if isinstance(np_id, bytes) else np_id

                # We still avoid duplicates in upcomingQueue.
                if charity_id in self.upcomingSet:
                    continue

                vec = np_vectors[idx]
                sim = cosine_similarity(user_vec, vec)
                candidates.append((sim, charity_id))

        # Sort candidates by similarity (highest first) and take the top 10.
        candidates.sort(key=lambda x: x[0], reverse=True)
        top_ten = candidates[:10]

        for sim, charity_id in top_ten:
            self.upcomingQueue.append(charity_id)
            self.upcomingSet.add(charity_id)


    def getNextN(self, n):
        """
        Pop up to n items from upcomingQueue, return as a list.
        If the queue is empty, try to refresh it.
        """
        sending = []
        while len(sending) < n:
            # If the upcomingQueue is empty, try to refresh it.
            if not self.upcomingQueue:
                self.refreshQueue()
                # If still empty after refresh, break out to avoid an infinite loop.
                if not self.upcomingQueue:
                    break
    
            # Now safely pop an item since the queue is not empty.
            charity = self.upcomingQueue.popleft()
            sending.append(charity)
            self.upcomingSet.remove(charity)
            self.seenQueue.append(charity)
            self.seenSet.add(charity)
            if len(self.seenQueue) > 50:
                byebye = self.seenQueue.popleft()
                self.seenSet.remove(byebye)
        return sending


    def getFullVector(self):
        return self.tags.getFullVector()


def userIDstringToInt(userID: str):
    return UserMap.get_int(userID)


def charityIDstringToInt(charityID: str):
    return NonprofitMap.get_int(charityID)


# -----------------
#   Vector Stuff
# -----------------
def compute_nonprofit_vector(nonprofit: dict, total_tags=100):
    """
    Build a 100-dimensional vector for a nonprofit.
    """
    vec = np.zeros(total_tags, dtype=np.float32)

    for tag in nonprofit.get("primary", []):
        if tag < total_tags:
            vec[tag] = 10

    for tag in nonprofit.get("secondary", []):
        if tag < total_tags:
            vec[tag] = 1

    return vec


def compute_query_vectory(query, total_tags=100):
    """
    Build a 100-dimensional vector for a query.
    (Only top ~20 tags are included, but we allocate 100 slots.)
    """
    vec = np.zeros(total_tags, dtype=np.float32)
    for tag, weight in query.items():
        if tag < total_tags:
            vec[tag] = weight
    return vec


def cosine_similarity(vec1, vec2):
    """
    Compute cosine similarity between two vectors.
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
    # userID (as int from UserMap) -> User object
}

NonprofitMap = BiMap("nonprofitMap.json")
UserMap = BiMap("userMap.json")


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
#  API Endpoints
# ---------------------

@app.get("/nextN")
def nextCharity(userID: str, n: int = 3):
    user_key = userIDstringToInt(userID)
    if user_key is None or user_key not in OnlineUsers:
        return PlainTextResponse("FAIL: User not online")
    return {"array": OnlineUsers[user_key].getNextN(n)}


@app.get("/reaction")
def reaction(userID: str, reactionNum: int, nonprofitID: str, amount: float = 0.0):
    user_key = userIDstringToInt(userID)
    if user_key is None or user_key not in OnlineUsers:
        return PlainTextResponse("FAIL: User not online")

    if reactionNum > 3 or reactionNum < 0:
        return PlainTextResponse("FAIL: Invalid reaction number")

    user = OnlineUsers[user_key]
    nonprofit = database.getNonprofit(nonprofitID)
    if nonprofit is None:
        return PlainTextResponse("FAIL: Nonprofit not found")

    if reactionNum == 3:
        react(3, user, nonprofit, amount)
    else:
        react(reactionNum, user, nonprofit)

    return PlainTextResponse("success")


@app.get("/logOn")
def logOn(userID: str):
    # Try to pull the stored vector from the HDF5 file.
    vector = database.getUser(userID)
    if vector is not None:
        user = User(userID, vector=vector)
    else:
        user = User(userID, new=True)
    # Store user in OnlineUsers keyed by the integer from our UserMap.
    user_key = userIDstringToInt(userID)
    OnlineUsers[user_key] = user
    return PlainTextResponse("success")


@app.get("/logOff")
def logOut(userID: str):
    user_key = userIDstringToInt(userID)
    if user_key not in OnlineUsers:
        return PlainTextResponse("FAIL: User not online")
    # Update the user vector in the HDF5 file before logging off.
    database.updateUserVector(userID, OnlineUsers[user_key].getFullVector())
    del OnlineUsers[user_key]
    return PlainTextResponse("success")


lastUpdate = time.time()


@app.get("/queueUpdate")
def queueUpdate(nonprofitID: str, primaryTags: list[int], secondaryTags: list[int]):
    updateQueue.append(nonprofitID)
    if time.time() - lastUpdate > 7200:
        # updateCharityTags()  # (Placeholder for periodic update logic)
        pass
    return PlainTextResponse("success")


@app.get("/test")
def test():
    return {"message": "Hello World"}


# def updateCharityTags():
#    while updateQueue:
#        on = updateQueue.popleft()
#        database.updateNonprofitVector(on)
#        break

# Main Methods
def run():
    global database
    database = Database("users.h5", "nonprofits.h5")
    if os.path.isfile("nonprofitMap.json"):
        NonprofitMap.load()
        UserMap.load()


def exit():
    database.close()
    NonprofitMap.save()
    UserMap.save()

