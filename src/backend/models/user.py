# models/user.py
import os
import sys
from collections import deque
import random

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from models.usertagtable import UserTagTable
from models.sqlite_db import SQLiteDatabase
from helpers import compute_query_vectory, cosine_similarity
from config import DATABASE_PATH  # import the central configuration

# Create the global database using the configured path.
database = SQLiteDatabase(DATABASE_PATH)


class User:
    def __init__(self, id_val, vector=None, new=False):
        self.id = id_val
        if new:
            self.tags = UserTagTable(self.id)
            self.vector = compute_query_vectory(self.tags.getCompTags())
        else:
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
        match event:
            case 0:
                return self.tags.getCompTags()
            case 1:
                newTags = self.tags.clone()
                newTags.swap(newTags.getNthTag(0), newTags.getNthTag(-1))
                newTags.swap(newTags.getNthTag(1), newTags.getNthTag(-2))
                newTags.swap(newTags.getNthTag(2), newTags.getNthTag(-3))
                return newTags.getCompTags()
            case 2:
                newTags = self.tags.clone()
                if newTags.zeroTags:
                    zeroed_tag = newTags.zeroTags.popleft()
                    newTags.swap(newTags.getNthTag(0), zeroed_tag)
                return newTags.getCompTags()
            case 3:
                return self.tags.getCompTags()
            case 4:
                return self.tags.getCompTags()
            case 5:
                return self.tags.getCompTags()
        return self.tags.getCompTags()

    # Reaction methods
    def like(self, nonprofit):
        self.tags.like(nonprofit)

    def donate(self, nonprofit, amount):
        self.tags.donate(nonprofit, amount)

    def ignore(self, nonprofit):
        self.tags.ignore(nonprofit)

    def dislike(self, nonprofit):
        self.tags.dislike(nonprofit)

    # Scheduling / Next
    def refreshQueue(self):
        user_query = self.getCompTags(self.chooseEvent())
        user_vec = compute_query_vectory(user_query)
        candidates = []
        # Retrieve all nonprofits from the SQLite DB.
        all_nonprofits = database.get_all_nonprofits()  # List of (nonprofit_id, vector)
        for charity_id, vec in all_nonprofits:
            if charity_id in self.seenSet or charity_id in self.upcomingSet:
                continue
            sim = cosine_similarity(user_vec, vec)
            candidates.append((sim, charity_id))
        if not candidates:
            self.seenSet.clear()
            self.seenQueue.clear()
            for charity_id, vec in all_nonprofits:
                if charity_id in self.upcomingSet:
                    continue
                sim = cosine_similarity(user_vec, vec)
                candidates.append((sim, charity_id))
        candidates.sort(key=lambda x: x[0], reverse=True)
        top_ten = candidates[:10]
        for sim, charity_id in top_ten:
            self.upcomingQueue.append(charity_id)
            self.upcomingSet.add(charity_id)

    def getNextN(self, n):
        sending = []
        while len(sending) < n:
            if not self.upcomingQueue:
                self.refreshQueue()
                if not self.upcomingQueue:
                    break
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
