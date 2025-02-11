import time
from collections import deque
import json

# Third-party packages
from fastapi import FastAPI
from fastapi.responses import PlainTextResponse

from models.user import User
from models.database import Database
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

with open("data/tags.json", "r") as f:
    Tags = json.load(f)

OnlineUsers = {}

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
    vector = database.getUser(userID)
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
    database.updateUserVector(userID, OnlineUsers[userID].getFullVector())
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
def isLoggedIn(userID):
    return PlainTextResponse("True" if userID in OnlineUsers else "False")

# -----------------
#   Main Methods
# -----------------
def run():
    global database
    database = Database("data/users.h5", "data/nonprofits.h5")

def exit():
    database.close()

