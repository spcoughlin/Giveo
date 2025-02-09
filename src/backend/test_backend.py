# test_backend.py

import os
import random
import tempfile
import numpy as np
import pytest
import h5py

from fastapi.testclient import TestClient

# Import backend code.
# (Adjust the import below to match your module’s name or structure.)
from backend import (
    Database,
    UserTagTable,
    NonProfit,
    User,
    compute_nonprofit_vector,
    compute_query_vectory,
    cosine_similarity,
    react,
    OnlineUsers,
    updateQueue,
    app,
)

# ================================
# Tests for the Database class
# ================================

@pytest.fixture
def temp_database(tmp_path):
    """
    Create a temporary Database instance with HDF5 files in a temporary folder.
    """
    user_file = tmp_path / "users.h5"
    nonprofit_file = tmp_path / "nonprofits.h5"
    db = Database(str(user_file), str(nonprofit_file))
    yield db
    db.close()


def test_database_add_and_get_user(temp_database):
    # Add a user with id "testuser" and a simple vector (ones).
    test_vector = np.ones(100, dtype=np.float32)
    temp_database.addUser("testuser", test_vector)
    # Use the Database.get method to retrieve the vector.
    retrieved = temp_database.get(temp_database.userFile, "user", "testuser")
    assert np.allclose(retrieved, test_vector)


def test_database_update_user(temp_database):
    # Add a user and then update its vector.
    test_vector = np.ones(100, dtype=np.float32)
    temp_database.addUser("testuser", test_vector)
    new_vector = np.full(100, 2.0, dtype=np.float32)
    temp_database.updateUserVector("testuser", new_vector)
    retrieved = temp_database.get(temp_database.userFile, "user", "testuser")
    assert np.allclose(retrieved, new_vector)


# ================================
# Tests for the UserTagTable class
# ================================

def test_user_tag_table_set_get():
    utt = UserTagTable(userID=1)
    # Get the original value for a tag (say tag 0)
    original_val = utt.getVal(0)
    # Change its value
    utt.set(0, 0.9)
    assert np.isclose(utt.getVal(0), 0.9)
    # The sorted_list should now reflect the new value.
    sorted_vals = [val for (val, tag) in utt.sorted_list if tag == 0]
    assert sorted_vals and np.isclose(sorted_vals[0], 0.9)


def test_user_tag_table_remove():
    utt = UserTagTable(userID=1)
    utt.set(5, 0.8)
    utt.remove(5)
    with pytest.raises(KeyError):
        _ = utt.data[5]
    # Also, the sorted_list should not contain tag 5.
    for (val, tag) in utt.sorted_list:
        assert tag != 5


def test_user_tag_table_clone():
    utt = UserTagTable(userID=1)
    utt.set(0, 0.7)
    clone = utt.clone()
    assert clone.getVal(0) == utt.getVal(0)
    # Modify the clone and ensure the original remains unchanged.
    clone.set(0, 0.5)
    assert utt.getVal(0) == 0.7


def test_user_tag_table_get_comp_tags():
    utt = UserTagTable(userID=1)
    comp = utt.getCompTags()
    # Should return a dictionary with 20 entries.
    assert isinstance(comp, dict)
    assert len(comp) == 20


def test_user_tag_table_get_full_vector():
    utt = UserTagTable(userID=1)
    vec = utt.getFullVector()
    assert vec.shape[0] == 100
    # Check that for each tag in data the corresponding vector entry matches.
    for tag, weight in utt.data.items():
        assert np.isclose(vec[tag], weight)
    # Ensure that tags in the zeroTags deque have value zero.
    for tag in utt.zeroTags:
        assert vec[tag] == 0.0


def test_user_tag_table_like():
    # Create a dummy NonProfit with known primary and secondary tag lists.
    dummy_np = NonProfit("np1", primary=[0, 1], secondary=[2, 3])
    utt = UserTagTable(userID=1)
    # Record the initial values.
    init = {tag: utt.getVal(tag) for tag in [0, 1, 2, 3]}
    utt.like(dummy_np)
    # For primary tags: new_val = old + (1 - old) * 0.1
    for tag in [0, 1]:
        expected = init[tag] + (1 - init[tag]) * 0.1
        assert np.isclose(utt.getVal(tag), expected)
    # For secondary tags: new_val = old + (1 - old) * 0.01
    for tag in [2, 3]:
        expected = init[tag] + (1 - init[tag]) * 0.01
        assert np.isclose(utt.getVal(tag), expected)


def test_user_tag_table_donate():
    dummy_np = NonProfit("np1", primary=[10, 11], secondary=[12, 13])
    utt = UserTagTable(userID=1)
    init = {tag: utt.getVal(tag) for tag in [10, 11, 12, 13]}
    utt.donate(dummy_np)
    for tag in [10, 11]:
        expected = init[tag] + (1 - init[tag]) * 0.25
        assert np.isclose(utt.getVal(tag), expected)
    for tag in [12, 13]:
        expected = init[tag] + (1 - init[tag]) * 0.025
        assert np.isclose(utt.getVal(tag), expected)


def test_user_tag_table_ignore():
    dummy_np = NonProfit("np1", primary=[20], secondary=[21])
    utt = UserTagTable(userID=1)
    utt.set(20, 0.8)
    utt.set(21, 0.8)
    utt.ignore(dummy_np)
    # For primary, new = 0.8 * 0.9
    assert np.isclose(utt.getVal(20), 0.8 * 0.9)
    # For secondary, new = 0.8 * 0.99
    assert np.isclose(utt.getVal(21), 0.8 * 0.99)


def test_user_tag_table_dislike():
    dummy_np = NonProfit("np1", primary=[30], secondary=[31])
    utt = UserTagTable(userID=1)
    utt.set(30, 0.8)
    utt.set(31, 0.8)
    utt.dislike(dummy_np)
    # For primary, new = 0.8 * 0.75
    assert np.isclose(utt.getVal(30), 0.8 * 0.75)
    # For secondary, new = 0.8 * 0.975
    assert np.isclose(utt.getVal(31), 0.8 * 0.975)


# ================================
# Tests for NonProfit and vector functions
# ================================

def test_nonprofit():
    np_obj = NonProfit("np_test", primary=[0, 1], secondary=[2])
    assert np_obj.id == "np_test"
    assert np_obj.tags["primary"] == [0, 1]
    assert np_obj.tags["secondary"] == [2]


def test_compute_nonprofit_vector():
    nonprofit_dict = {"primary": [1, 5], "secondary": [3, 7]}
    vec = compute_nonprofit_vector(nonprofit_dict, total_tags=100)
    # Primary tags should have value 10.
    for tag in [1, 5]:
        assert vec[tag] == 10
    # Secondary tags should have value 1.
    for tag in [3, 7]:
        assert vec[tag] == 1
    # All other entries should be 0.
    for i in range(100):
        if i not in [1, 5, 3, 7]:
            assert vec[i] == 0


def test_compute_query_vectory():
    query = {0: 0.5, 10: 0.7}
    vec = compute_query_vectory(query, total_tags=100)
    assert np.isclose(vec[0], 0.5)
    assert np.isclose(vec[10], 0.7)
    for i in range(100):
        if i not in query:
            assert vec[i] == 0


def test_cosine_similarity():
    vec1 = np.array([1, 0, 0], dtype=np.float32)
    vec2 = np.array([1, 0, 0], dtype=np.float32)
    sim = cosine_similarity(vec1, vec2)
    assert np.isclose(sim, 1.0)
    vec3 = np.array([0, 1, 0], dtype=np.float32)
    sim = cosine_similarity(vec1, vec3)
    assert np.isclose(sim, 0.0)


# ================================
# Tests for the react function
# ================================

def test_react_like():
    # Create dummy user and nonprofit objects that record which reaction was called.
    class DummyUser:
        def __init__(self):
            self.liked = False
        def like(self, np_obj):
            self.liked = True

    class DummyNP:
        pass

    user = DummyUser()
    np_obj = DummyNP()
    react(0, user, np_obj)
    assert user.liked is True


def test_invalid_reaction():
    user = User(222)
    dummy_np = NonProfit("dummy", primary=[0], secondary=[1])
    with pytest.raises(Exception):
        react(999, user, dummy_np)


# ================================
# Tests for the User class methods
# ================================

def test_user_get_full_vector():
    user = User(101)
    vec = user.getFullVector()
    assert vec.shape[0] == 100


def test_user_get_next_n(monkeypatch):
    # Create a user with an upcomingQueue already populated.
    user = User(789)
    user.upcomingQueue =  __import__("collections").deque(["np1", "np2", "np3"])
    user.upcomingSet = {"np1", "np2", "np3"}
    # Monkey-patch refreshQueue so that it does nothing when called.
    monkeypatch.setattr(user, "refreshQueue", lambda: None)
    next_items = user.getNextN(2)
    assert next_items == ["np1", "np2"]
    assert "np1" not in user.upcomingSet
    assert "np2" not in user.upcomingSet


def test_user_choose_event():
    user = User(111)
    # Ensure the user has an attribute 'donations' (even if empty) so that event 5 works.
    user.donations = []
    for _ in range(10):
        event = user.chooseEvent()
        assert event in [0, 1, 2, 3, 4, 5]


def test_user_refresh_queue(monkeypatch):
    # Prepare a dummy nonprofit file for the global database.
    dummy_ids = np.array([b"np1", b"np2", b"np3"], dtype="S12")
    # For simplicity, let every nonprofit vector be a 100-D vector of ones.
    dummy_vectors = np.ones((3, 100), dtype=np.float32)
    dummy_nonprofit_file = {
        "nonprofit_ids": dummy_ids,
        "nonprofit_vectors": dummy_vectors,
    }
    # Patch the global database’s nonprofitFile to our dummy object.
    monkeypatch.setattr(Database, "nonprofitFile", dummy_nonprofit_file)
    # Create a dummy user.
    user = User(456)
    # Force chooseEvent to return 0 (so that getCompTags is used directly).
    monkeypatch.setattr(user, "chooseEvent", lambda: 0)
    # Override getCompTags so that the user query vector is a known vector.
    monkeypatch.setattr(user, "getCompTags", lambda event=0: np.ones(100, dtype=np.float32))
    user.refreshQueue()
    # upcomingQueue should now have up to 10 nonprofit IDs (decoded to str).
    for np_id in user.upcomingQueue:
        assert np_id in [b.decode("utf-8") for b in dummy_ids]


# ================================
# Tests for the API endpoints
# ================================

client = TestClient(app)

def dummy_getUser(userID):
    # Always return None so that a new user is created.
    return None

def dummy_getNonprofit(nonprofitID):
    # Return a simple NonProfit object.
    return NonProfit(str(nonprofitID), primary=[0, 1], secondary=[2, 3])


@pytest.fixture(autouse=True)
def patch_database(monkeypatch):
    # Patch the global database methods so that logOn and reaction work without real HDF5 access.
    monkeypatch.setattr("backend.database.getUser", dummy_getUser)
    monkeypatch.setattr("backend.database.getNonprofit", dummy_getNonprofit)


def test_log_on_and_log_off():
    # Test /logOn: it should add a user to OnlineUsers.
    response = client.post("/logOn", params={"userID": 123})
    assert response.status_code == 200
    assert response.text == "success"
    assert 123 in OnlineUsers

    # Test /reaction.
    response = client.post("/reaction", params={"userID": 123, "reactionNum": 0, "nonprofitID": 1})
    assert response.status_code == 200
    # Test /nextN: manually set the upcomingQueue for the user.
    OnlineUsers[123].upcomingQueue = __import__("collections").deque(["np_test"])
    OnlineUsers[123].upcomingSet = {"np_test"}
    response = client.get("/nextN", params={"userID": 123, "n": 1})
    data = response.json()
    assert "array" in data
    # Test /logOff.
    response = client.post("/logOff", params={"userID": 123})
    assert response.status_code == 200
    assert response.text == "success"
    assert 123 not in OnlineUsers


def test_queue_update():
    # Clear the updateQueue.
    updateQueue.clear()
    response = client.post("/queueUpdate", params={"nonprofitID": 999})
    assert response.status_code == 200
    assert response.text == "success"
    # Check that the nonprofitID was added.
    assert updateQueue[-1] == 999

