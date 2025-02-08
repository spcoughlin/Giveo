import random
import time
from collections import deque
from copy import deepcopy
import numpy as np
from sortedcontainers import SortedList
from fastapi import FastAPI

app = FastAPI()

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


class UserTagTable:
    def __init__(self, userID):
        self.data = {tag: 50.0 for tag in Tags}
        self.sorted_list = SortedList()  # stored in form (value, tag)
        self.zeroTags = deque()

    def set(self, tag, val):
        if tag in self.data:
            old_val = self.data[tag]
            self.sorted_list.remove((old_val, tag))
        self.data[tag] = val
        self.sorted_list.add((val, tag))
        if val == 0:
            self.zeroTags.append(tag)
            self.sorted_list.remove((val, tag))
            if len(self.zeroTags) > 25:
                # TOO MANY
                self.set(self.zeroTags.popleft(), 50.0)

    def remove(self, tag):
        if tag in self.data:
            old_val = self.data[tag]
            del self.data[tag]
            self.sorted_list.remove((old_val, tag))

    def getVal(self, tag):
        return self.data[tag]

    def getNthTag(self, n):
        """Get the nth ordered tag"""
        if 0 <= abs(n) < len(self.sorted_list):
            return self.sorted_list[n][1]
        raise IndexError("Index out of range")

    def swap(self, tag1, tag2):
        """swap two tag values for some events"""
        self.data[tag1], self.data[tag2] = self.data[tag2], self.data[tag1]

    def clone(self):
        clone = UserTagTable()
        clone.data = deepcopy(self.data)  # Dont need deepcopy but :shrug:
        clone.sorted_list = SortedList(self.sorted_list)
        return clone

    def getCompTags(self):
        query = {}
        for i in range(20):
            tag = self.getNthTag(i)
            query[tag] = self.getVal(tag)
        return query

    def like(self, nonprofit):
        for tag in nonprofit.tags["primary"]:
            self.set(tag, self.getVal(tag) + (100 - self.getVal(tag)) * 0.1)
        for tag in nonprofit.tags["secondary"]:
            self.set(tag, self.getVal(tag) + (100 - self.getVal(tag) * 0.01))

    def donate(self, nonprofit):
        for tag in nonprofit.tags["primary"]:
            self.set(tag, self.getVal(tag) + (100 - self.getVal(tag)) * 0.25)
        for tag in nonprofit.tags["secondary"]:
            self.set(tag, self.getVal(tag) + (100 - self.getVal(tag) * 0.025))

    def ignore(self, nonprofit):
        for tag in nonprofit.tags["primary"]:
            self.set(tag, self.getVal(tag) * .9)
            if self.getVal(tag) < .05:
                self.set(tag, 0)
        for tag in nonprofit.tags["secondary"]:
            self.set(tag, self.getVal(tag) * .99)
            if self.getVal(tag) < .05:
                self.set(tag, 0)

    def dislike(self, nonprofit):
        for tag in nonprofit.tags["primary"]:
            self.set(tag, self.getVal(tag) * .75)
            if self.getVal(tag) < .05:
                self.set(tag, 0)
        for tag in nonprofit.tags["secondary"]:
            self.set(tag, self.getVal(tag) * .975)
            if self.getVal(tag) < .05:
                self.set(tag, 0)


class NonProfit:
    # TODO: Reversed averages to impact strength of dynamic tags
    def __init__(self, id, primary, secondary):
        self.id = id
        self.tags = {"primary": primary, "secondary": secondary}
        self.dynamic_tags = {-1: 50.0, -2: 50.0, -3: 50.0}


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
        match event:
            case 0:
                return self.tags.getCompTags()
            case 1:
                # Replace user tags 0-2 with tags closest to (but not at) 0
                newTags = self.tags.clone()
                newTags.swap(newTags.getNthTag(0), newTags.getNthTag(-1))
                newTags.swap(newTags.getNthTag(1), newTags.getNthTag(-2))
                newTags.swap(newTags.getNthTag(2), newTags.getNthTag(-3))
                return newTags.getCompTags()
            case 2:
                # Replace user tag 0 with least recent tag to hit 0
                newTags = self.tags.clone()
                newTags.swap(newTags.getNthTag(0), newTags.zeroTags.popleft())
                return newTags.getCompTags()
            case 3:
                # Does not change user tags, but searches only within NPs with "gem" tag
                pass
            case 4:
                # Does not change user tags, but searches only within NPs with "trending" tag
                pass
            case 5:
                return self.donations[random.randint(0, len(self.donations) - 1)]

    def like(self, nonprofit):
        self.tags.like(nonprofit)

    def donate(self, nonprofit, amount):
        self.tags.donate(nonprofit)
        self.donations.append(nonprofit)

    def ignore(self, nonprofit):
        self.tags.ignore(nonprofit)

    def dislike(self, nonprofit):
        self.tags.dislike(nonprofit)


def compute_nonprofit_vector(nonprofit: dict, total_tags=100):
    """
    Build 100-dimensional vector for nonprofit
    :param nonprofit:
    :param total_tags:
    :return:
    """
    vec = np.zeros(total_tags)

    for tag in nonprofit.get('primary'):
        vec[tag] = 10

    for tag in nonprofit.get('secondary'):
        vec[tag] = 1

    return vec


def compute_query_vectory(query, total_tags=100):
    """
    Build 100-dimensional vector for query
    NOTE: though 100-dimensional, only 20 tags are included in query
    :param query:
    :param total_tags:
    :return:
    """
    vec = np.zeros(total_tags)
    for tag, weight in query.items():
        vec[tag] = weight

    return vec


def cosine_similarity(vec1, vec2):
    """
    compute similarity between 2 vectors
    :param vec1:
    :param vec2:
    :return:
    """
    dot_prod = np.dot(vec1, vec2)
    norm1 = np.linalg.norm(vec1)
    norm2 = np.linalg.norm(vec2)

    if norm1 == 0 or norm2 == 0:
        return 0.0

    return dot_prod / (norm1 * norm1)


OnlineUsers = {
    # Store online users in format ID:Object[User]
}
Reactions = {
    0: User.like,
    1: User.dislike,
    2: User.ignore,
    3: User.donate
}


# API Functions

@app.get("/nextCharities")
def nextCharity(userID: int, n: int):
    return OnlineUsers[userID].getNextN(n)


@app.post("/reaction")
def reaction(userID: int, reactionNum: int):
    OnlineUsers[userID].Reactions[reactionNum]()