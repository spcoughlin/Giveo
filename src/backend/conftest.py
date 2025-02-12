# conftest.py
import os

# Set the database path for tests before any other modules are imported.
os.environ["DATABASE_PATH"] = ":memory:"

