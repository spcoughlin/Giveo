# tests/test_system.py
import sqlite3
import numpy as np
import pytest

# Import our new SQLiteDatabase from sqlite_db.py.
from models.sqlite_db import SQLiteDatabase, vector_to_blob, blob_to_vector
# Import the User class (which uses the global `database` instance from models.user)
from models.user import User
# Import the FastAPI app and the global database variable from main.
from fastapi.testclient import TestClient
from main import app

import os
os.environ["DATABASE_PATH"] = ":memory:"

# -----------------------------------------------------------------------------
# Tests for SQLiteDatabase
# -----------------------------------------------------------------------------

@pytest.fixture
def db():
    # Create a new in-memory database for each test.
    return SQLiteDatabase(":memory:")

def test_add_and_get_user(db):
    user_id = "test_user"
    vector = np.random.rand(100).astype(np.float32)
    db.add_user(user_id, vector)
    retrieved = db.get_user(user_id)
    np.testing.assert_array_equal(vector, retrieved)

def test_update_user(db):
    user_id = "test_user"
    vector = np.random.rand(100).astype(np.float32)
    db.add_user(user_id, vector)
    new_vector = np.random.rand(100).astype(np.float32)
    db.update_user_vector(user_id, new_vector)
    retrieved = db.get_user(user_id)
    np.testing.assert_array_equal(new_vector, retrieved)

def test_add_and_get_nonprofit(db):
    np_id = "nonprofit_1"
    vector = np.random.rand(100).astype(np.float32)
    db.add_nonprofit(np_id, vector)
    retrieved = db.get_nonprofit_vector(np_id)
    np.testing.assert_array_equal(vector, retrieved)

def test_get_all_nonprofits(db):
    nonprofits = [
        ("np_1", np.random.rand(100).astype(np.float32)),
        ("np_2", np.random.rand(100).astype(np.float32)),
    ]
    for np_id, vec in nonprofits:
        db.add_nonprofit(np_id, vec)
    all_nps = db.get_all_nonprofits()
    assert len(all_nps) == len(nonprofits)
    # Check that each nonprofit was added.
    for np_id, vec in nonprofits:
        matches = [v for id_found, v in all_nps if id_found == np_id]
        assert matches, f"Nonprofit {np_id} not found"
        np.testing.assert_array_equal(vec, matches[0])

# -----------------------------------------------------------------------------
# Tests for the User class (unit tests)
# -----------------------------------------------------------------------------

# For testing purposes we override compute_query_vectory and cosine_similarity.
# (Assume these functions are imported in models/user.py.)
@pytest.fixture(autouse=True)
def override_helpers(monkeypatch):
    def dummy_compute_query_vectory(query):
        # Return a predictable vector (e.g. all ones)
        return np.ones(100, dtype=np.float32)
    
    def dummy_cosine_similarity(vec1, vec2):
        # A dummy similarity: higher if the sum of differences is lower.
        # (Not a true cosine similarity, but works for our test.)
        diff = np.linalg.norm(vec1 - vec2)
        return 1 / (1 + diff)
    
    monkeypatch.setattr("models.user.compute_query_vectory", dummy_compute_query_vectory)
    monkeypatch.setattr("models.user.cosine_similarity", dummy_cosine_similarity)

@pytest.fixture
def test_db(tmp_path, monkeypatch):
    # Create a SQLiteDatabase in memory for testing the User class.
    test_db_instance = SQLiteDatabase(":memory:")
    # Override the global database used in the User class (from models/user.py)
    monkeypatch.setattr("models.user.database", test_db_instance)
    return test_db_instance

def test_user_refresh_queue(test_db):
    # Add several nonprofits to the test database.
    for i in range(5):
        np_id = f"np_{i}"
        # Use a vector that is predictable (e.g. a constant times ones)
        vec = np.ones(100, dtype=np.float32) * (i + 1)
        test_db.add_nonprofit(np_id, vec)
    
    # Create a new user (simulate a new user).
    user = User("user_test", new=True)
    # Initially, the user's upcomingQueue should be empty.
    assert len(user.upcomingQueue) == 0
    # Call refreshQueue, which should fill the upcomingQueue.
    user.refreshQueue()
    assert len(user.upcomingQueue) > 0
    # Test getNextN returns the expected number of charities.
    next_n = user.getNextN(3)
    assert len(next_n) <= 3
    # Ensure that the charities returned are among those added.
    nonprofit_ids = [f"np_{i}" for i in range(5)]
    for charity in next_n:
        assert charity in nonprofit_ids

# -----------------------------------------------------------------------------
# Integration tests for the FastAPI API endpoints
# -----------------------------------------------------------------------------

@pytest.fixture
def client(monkeypatch):
    # For testing the API, override the global database with an in-memory one.
    test_db_instance = SQLiteDatabase(":memory:")
    monkeypatch.setattr("main.database", test_db_instance)
    # Also reset the OnlineUsers global (in main.py) to an empty dict.
    monkeypatch.setattr("main.OnlineUsers", {})
    return TestClient(app)

def test_log_on_and_log_off(client):
    # Test /logOn: since the user doesn't exist, a new one will be created.
    response = client.get("/logOn", params={"userID": "test_user"})
    assert response.status_code == 200
    assert response.text.strip('"') == "success"

    # Check that the user is now logged in.
    response = client.get("/isLoggedIn", params={"userID": "test_user"})
    # isLoggedIn returns "True" as plain text.
    assert response.text.strip('"') == "True"

    # Log off the user.
    response = client.get("/logOff", params={"userID": "test_user"})
    assert response.status_code == 200
    assert response.text.strip('"') == "success"

    # Verify the user is no longer logged in.
    response = client.get("/isLoggedIn", params={"userID": "test_user"})
    assert response.text.strip('"') == "False"

def test_nextN_endpoint(client, monkeypatch):
    # First, log on a test user.
    client.get("/logOn", params={"userID": "test_user"})

    # Add some nonprofits to the database.
    # Get the database instance from main (which we overrode in the fixture).
    from main import database
    for i in range(3):
        np_id = f"np_{i}"
        vec = np.ones(100, dtype=np.float32) * (i + 1)
        database.add_nonprofit(np_id, vec)

    # Call the /nextN endpoint.
    response = client.get("/nextN", params={"userID": "test_user", "n": 2})
    assert response.status_code == 200
    data = response.json()
    # Expect an array of charity IDs.
    assert "array" in data
    assert isinstance(data["array"], list)
    # The list length should be at most 2.
    assert len(data["array"]) <= 2

def test_reaction_endpoint(client):
    # Log on a test user.
    client.get("/logOn", params={"userID": "test_user"})
    # Add a nonprofit to the database.
    from main import database
    np_id = "np_1"
    vec = np.ones(100, dtype=np.float32)
    database.add_nonprofit(np_id, vec)
    
    # Test the reaction endpoint.
    # Here we send reaction number 1 (for example).
    response = client.get("/reaction", params={
        "userID": "test_user",
        "reactionNum": 1,
        "nonprofitID": np_id
    })
    assert response.status_code == 200
    assert response.text.strip('"') == "success"

