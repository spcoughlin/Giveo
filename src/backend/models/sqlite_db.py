import sqlite3
import numpy as np
import json
from models.nonprofit import NonProfit  # your NonProfit class
from helpers import recover_nonprofit_tags  # helper that recovers primary/secondary tags

VECTOR_SIZE = 100

def vector_to_blob(vector: np.ndarray) -> bytes:
    vector = np.asarray(vector, dtype=np.float32).reshape(VECTOR_SIZE)
    return vector.tobytes()

def blob_to_vector(blob: bytes) -> np.ndarray:
    return np.frombuffer(blob, dtype=np.float32)

class SQLiteDatabase:
    def __init__(self, db_file):
        self.conn = sqlite3.connect(db_file, check_same_thread=False)
        self.ensure_tables()

    def ensure_tables(self):
        c = self.conn.cursor()
        # Create the users table (using a BLOB for the vector)
        c.execute('''
            CREATE TABLE IF NOT EXISTS users (
                id TEXT PRIMARY KEY,
                vector BLOB
            )
        ''')
        # Create the nonprofits table with id, primary_tags, and secondary_tags stored as JSON text
        c.execute('''
            CREATE TABLE IF NOT EXISTS nonprofits (
                id TEXT PRIMARY KEY,
                primary_tags TEXT,
                secondary_tags TEXT
            )
        ''')
        # Create the coin_ledger table
        c.execute('''
            CREATE TABLE IF NOT EXISTS coin_ledger (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp TEXT,
                userID TEXT,
                amount REAL,
                nonprofitID TEXT
            )
        ''')
        self.conn.commit()

    def add_vector(self, table: str, id_val: str, vector: np.ndarray):
        blob = vector_to_blob(vector)
        c = self.conn.cursor()
        try:
            c.execute(f"INSERT INTO {table} (id, vector) VALUES (?, ?)", (id_val, blob))
        except sqlite3.IntegrityError:
            raise ValueError(f"ID {id_val} already exists in table {table}")
        self.conn.commit()

    def update_vector(self, table: str, id_val: str, new_vector: np.ndarray):
        blob = vector_to_blob(new_vector)
        c = self.conn.cursor()
        c.execute(f"UPDATE {table} SET vector=? WHERE id=?", (blob, id_val))
        if c.rowcount == 0:
            raise ValueError(f"ID {id_val} not found in table {table}")
        self.conn.commit()

    def get_vector(self, table: str, id_val: str) -> np.ndarray:
        c = self.conn.cursor()
        c.execute(f"SELECT vector FROM {table} WHERE id=?", (id_val,))
        row = c.fetchone()
        if row is None:
            return None
        return blob_to_vector(row[0])

    # User convenience methods
    def add_user(self, id_val: str, vector: np.ndarray):
        self.add_vector("users", id_val, vector)

    def update_user_vector(self, id_val: str, new_vector: np.ndarray):
        self.update_vector("users", id_val, new_vector)

    def get_user(self, id_val: str) -> np.ndarray:
        return self.get_vector("users", id_val)

    # Nonprofit convenience methods (using JSON for tag lists)
    def add_nonprofit(self, id_val: str, primary_tags: list, secondary_tags: list):
        primary_json = json.dumps(primary_tags)
        secondary_json = json.dumps(secondary_tags)
        c = self.conn.cursor()
        try:
            c.execute("INSERT INTO nonprofits (id, primary_tags, secondary_tags) VALUES (?, ?, ?)",
                      (id_val, primary_json, secondary_json))
        except sqlite3.IntegrityError:
            raise ValueError(f"ID {id_val} already exists in table nonprofits")
        self.conn.commit()

    def update_nonprofit_tags(self, id_val: str, primary_tags: list, secondary_tags: list):
        primary_json = json.dumps(primary_tags)
        secondary_json = json.dumps(secondary_tags)
        c = self.conn.cursor()
        c.execute("UPDATE nonprofits SET primary_tags=?, secondary_tags=? WHERE id=?",
                  (primary_json, secondary_json, id_val))
        if c.rowcount == 0:
            raise ValueError(f"ID {id_val} not found in table nonprofits")
        self.conn.commit()

    def get_nonprofit(self, id_val: str):
        c = self.conn.cursor()
        c.execute("SELECT primary_tags, secondary_tags FROM nonprofits WHERE id=?", (id_val,))
        row = c.fetchone()
        if row is None:
            return None
        primary = json.loads(row[0])
        secondary = json.loads(row[1])
        return NonProfit(id_val, primary, secondary)

    def get_all_nonprofits(self):
        c = self.conn.cursor()
        c.execute("SELECT id, primary_tags, secondary_tags FROM nonprofits")
        results = []
        for row in c.fetchall():
            nonprofit_id = row[0]
            primary_tags = json.loads(row[1])
            secondary_tags = json.loads(row[2])
            results.append((nonprofit_id, primary_tags, secondary_tags))
        return results

    def get_json(self):
        """
        Return a JSON representation of the database,
        containing the users, nonprofits, and coin_ledger tables.
        """
        c = self.conn.cursor()
        # Build users dictionary: id -> vector list
        c.execute("SELECT * FROM users")
        users = {}
        for row in c.fetchall():
            user_id = row[0]
            vector_blob = row[1]
            vector_list = blob_to_vector(vector_blob).tolist() if vector_blob else None
            users[user_id] = vector_list

        # Build nonprofits dictionary: id -> {primary_tags, secondary_tags}
        c.execute("SELECT * FROM nonprofits")
        nonprofits = {}
        for row in c.fetchall():
            nonprofit_id = row[0]
            primary_tags = json.loads(row[1])
            secondary_tags = json.loads(row[2])
            nonprofits[nonprofit_id] = {
                "primary_tags": primary_tags,
                "secondary_tags": secondary_tags
            }

        # Build coin_ledger dictionary: id -> {timestamp, userID, amount, nonprofitID}
        c.execute("SELECT * FROM coin_ledger")
        coin_ledger = {}
        for row in c.fetchall():
            coin_id = row[0]
            coin_ledger[coin_id] = {
                "timestamp": row[1],
                "userID": row[2],
                "amount": row[3],
                "nonprofitID": row[4]
            }

        return {"users": users, "nonprofits": nonprofits, "coin_ledger": coin_ledger}

    def close(self):
        self.conn.close()

