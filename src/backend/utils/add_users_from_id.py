import numpy as np
from models.sqlite_db import SQLiteDatabase
from config import DATABASE_PATH

VECTOR_SIZE = 100

def generate_vector(vector_size=VECTOR_SIZE):
    """
    Generate a random vector of length `vector_size` where:
      - Each element is 0 with probability 0.2,
      - Otherwise it is a random float between 0.05 and 1 with probability 0.8.
    Returns a numpy array of type float32.
    """
    # Generate an array of probabilities
    probs = np.random.rand(vector_size)
    # For each element, choose 0.0 if prob < 0.2, else a random number between 0.05 and 1.0.
    values = np.where(probs < 0.2,
                      0.0,
                      np.random.uniform(0.05, 1.0, size=vector_size))
    return values.astype(np.float32)

def main():
    # Create a connection to the database using the configured DATABASE_PATH
    db = SQLiteDatabase(DATABASE_PATH)
    
    print("User Vector Generator")
    print("Enter a user ID to generate a random vector (or type 'exit' to quit).")
    
    while True:
        user_id = input("Enter user ID: ").strip()
        if user_id.lower() == "exit" or user_id == "":
            break

        vector = generate_vector()
        try:
            db.add_user(user_id, vector)
            print(f"User '{user_id}' added with vector: {vector.tolist()}")
        except ValueError as e:
            print(f"Error: {e}")

    db.close()
    print("Exiting program.")

if __name__ == "__main__":
    main()

