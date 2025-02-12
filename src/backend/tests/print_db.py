import sqlite3
import numpy as np

VECTOR_SIZE = 100

def blob_to_vector(blob: bytes) -> np.ndarray:
    """
    Convert a binary blob (BLOB) back into a NumPy array of shape (VECTOR_SIZE,).
    """
    return np.frombuffer(blob, dtype=np.float32)

def list_users(conn):
    cursor = conn.cursor()
    cursor.execute("SELECT id, vector FROM users")
    users = cursor.fetchall()
    
    print("=== Users ===")
    for user_id, vector_blob in users:
        vector = blob_to_vector(vector_blob)
        # For brevity, you might want to show only the first few values of the vector.
        print(f"User ID: {user_id}")
        print(f"Vector: {vector}\n")

def list_nonprofits(conn):
    cursor = conn.cursor()
    cursor.execute("SELECT id, vector FROM nonprofits")
    nonprofits = cursor.fetchall()
    
    print("=== Nonprofits ===")
    for np_id, vector_blob in nonprofits:
        vector = blob_to_vector(vector_blob)
        print(f"Nonprofit ID: {np_id}")
        print(f"Vector: {vector}\n")

def main():
    # Connect to the single database file
    import os
    db_path = os.path.join(os.path.dirname(__file__), "..", "data", "data.db")
    conn = sqlite3.connect(db_path)
    
    try:
        list_users(conn)
        list_nonprofits(conn)
    finally:
        conn.close()

if __name__ == "__main__":
    main()

