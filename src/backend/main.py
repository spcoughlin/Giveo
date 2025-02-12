# main.py (or your API entrypoint)
import time
from collections import deque
import json
import os

# Third-party packages
from fastapi import FastAPI
from fastapi.responses import PlainTextResponse

from models.user import User
from models.sqlite_db import SQLiteDatabase
from helpers import react

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

json_path = os.path.join(os.path.dirname(__file__), "data", "tags.json") 
with open(json_path, "r") as f:
    Tags = json.load(f)

OnlineUsers = {}

# Instantiate the global database using SQLite
database = SQLiteDatabase("data.db")

# ---------------------
#   API Endpoints
# ---------------------
@app.get("/nextN")
def nextCharity(userID: str, n: int = 3):
    if userID not in OnlineUsers:
        return PlainTextResponse("FAIL: User not online")
    return {"array": OnlineUsers[userID].getNextN(n)}

@app.get("/reaction")
def reaction(userID: str, reactionNum: int, nonprofitID: str, amount: float = 0.0):
    if userID not in OnlineUsers:
        return PlainTextResponse("FAIL: User not online")
    if reactionNum > 3 or reactionNum < 0:
        return PlainTextResponse("FAIL: Invalid reaction number")
    user = OnlineUsers[userID]
    # Use the new get_nonprofit method from SQLiteDatabase
    nonprofit = database.get_nonprofit(nonprofitID)
    if nonprofit is None:
        return PlainTextResponse("FAIL: Nonprofit not found")
    if reactionNum == 3:
        react(3, user, nonprofit, amount)
    else:
        react(reactionNum, user, nonprofit)
    return PlainTextResponse("success")

@app.get("/logOn")
def logOn(userID: str):
    vector = database.get_user(userID)
    if vector is not None:
        user = User(userID, vector=vector)
    else:
        user = User(userID, new=True)
    OnlineUsers[userID] = user
    return PlainTextResponse("success")

@app.get("/logOff")
def logOut(userID: str):
    if userID not in OnlineUsers:
        return PlainTextResponse("FAIL: User not online")
    user = OnlineUsers[userID]
    new_vector = user.getFullVector()
    # Check if the user already exists in the database.
    if database.get_user(userID) is None:
        # If not, add the user.
        database.add_user(userID, new_vector)
    else:
        # Otherwise, update the user's vector.
        database.update_user_vector(userID, new_vector)
    del OnlineUsers[userID]
    return PlainTextResponse("success")

lastUpdate = time.time()

@app.get("/queueUpdate")
def queueUpdate(nonprofitID: str, primaryTags: list[int], secondaryTags: list[int]):
    updateQueue.append(nonprofitID)
    if time.time() - lastUpdate > 7200:
        # Placeholder for periodic update logic.
        pass
    return PlainTextResponse("success")

@app.get("/test")
def test():
    return {"message": "Hello World"}

@app.get("/isLoggedIn")
def isLoggedIn(userID: str):
    return PlainTextResponse("True" if userID in OnlineUsers else "False")

# -----------------
#   Main Methods
# -----------------
def run():
    global database
    database = SQLiteDatabase("data.db")

def exit():
    database.close()

