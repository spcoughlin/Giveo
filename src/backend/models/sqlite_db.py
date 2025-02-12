# sqlite_db.py
import sqlite3
import numpy as np
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
        c.execute('''
            CREATE TABLE IF NOT EXISTS users (
                id TEXT PRIMARY KEY,
                vector BLOB
            )
        ''')
        c.execute('''
            CREATE TABLE IF NOT EXISTS nonprofits (
                id TEXT PRIMARY KEY,
                vector BLOB
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

    # Nonprofit convenience methods
    def add_nonprofit(self, id_val: str, vector: np.ndarray):
        self.add_vector("nonprofits", id_val, vector)

    def update_nonprofit_vector(self, id_val: str, new_vector: np.ndarray):
        self.update_vector("nonprofits", id_val, new_vector)

    def get_nonprofit_vector(self, id_val: str) -> np.ndarray:
        return self.get_vector("nonprofits", id_val)
    
    def get_nonprofit(self, id_val: str):
        """
        Retrieve the nonprofit vector, recover its tags, and return a NonProfit object.
        """
        vector = self.get_nonprofit_vector(id_val)
        if vector is None:
            return None
        primary, secondary = recover_nonprofit_tags(vector)
        return NonProfit(id_val, primary, secondary)

    def get_all_nonprofits(self):
        """
        Return a list of tuples (nonprofit_id, vector) for all nonprofits.
        """
        c = self.conn.cursor()
        c.execute("SELECT id, vector FROM nonprofits")
        results = []
        for row in c.fetchall():
            nonprofit_id = row[0]
            vector = blob_to_vector(row[1])
            results.append((nonprofit_id, vector))
        return results

    def close(self):
        self.conn.close()

