from sortedcontainers import SortedList
from collections import deque
from copy import deepcopy
import numpy as np
import json
import os

json_path = os.path.join(os.path.dirname(__file__), "..", "data", "tags.json")
with open(json_path, "r") as f:
    Tags = json.load(f)

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
        for tag, val in self.data.items():
            self.sorted_list.add((val, tag))

    def set(self, tag, val):
        if tag in self.data:
            old_val = self.data[tag]
            try:
                self.sorted_list.remove((old_val, tag))
            except ValueError:
                pass
        self.data[tag] = val
        self.sorted_list.add((val, tag))
        if val == 0:
            self.zeroTags.append(tag)
            try:
                self.sorted_list.remove((val, tag))
            except ValueError:
                pass
        while len(self.zeroTags) > 25:
            bumped_tag = self.zeroTags.popleft()
            if bumped_tag in self.data:
                old_val = self.data[bumped_tag]
                try:
                    self.sorted_list.remove((old_val, bumped_tag))
                except ValueError:
                    pass
            self.data[bumped_tag] = 10.0
            self.sorted_list.add((10.0, bumped_tag))

    def remove(self, tag):
        if tag in self.data:
            old_val = self.data[tag]
            del self.data[tag]
            self.sorted_list.remove((old_val, tag))

    def getVal(self, tag):
        return self.data[tag]

    def getNthTag(self, n):
        if 0 <= abs(n) < len(self.sorted_list):
            return self.sorted_list[n][1]
        raise IndexError("Tag index out of range")

    def swap(self, tag1, tag2):
        self.data[tag1], self.data[tag2] = self.data[tag2], self.data[tag1]
        self.sorted_list = SortedList(((v, t) for t, v in self.data.items()))

    def clone(self):
        clone = UserTagTable(-1)
        clone.data = deepcopy(self.data)
        clone.sorted_list = SortedList(self.sorted_list)
        clone.zeroTags = deepcopy(self.zeroTags)
        return clone

    def getCompTags(self):
        query = {}
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

    # Behaviors
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


