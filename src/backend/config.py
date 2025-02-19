# config.py
import os
import os.path

# Use the DATABASE_PATH environment variable if set; otherwise use the default production file.
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATABASE_PATH = os.environ.get("DATABASE_PATH", os.path.join(BASE_DIR, "data", "data.db"))
DB_GET_PASSWORD = os.environ.get("DB_GET_PASSWORD", "BWQ7CZ9ue3va")

