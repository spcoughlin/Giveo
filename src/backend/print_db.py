import sqlite3

# Define the database file
DB_FILE = "data/data.db"

# List of tables to display
tables = ["Nonprofits", "Users", "CoinLedger"]

# Connect to the SQLite database
conn = sqlite3.connect(DB_FILE)
cursor = conn.cursor()

for table in tables:
    print(f"=== Schema for table {table} ===")
    # Get the table schema from sqlite_master
    cursor.execute("SELECT sql FROM sqlite_master WHERE type='table' AND name=?", (table,))
    schema = cursor.fetchone()
    if schema:
        print(schema[0])
    else:
        print(f"Table {table} does not exist.")

    print(f"\n=== First 5 rows of {table} ===")
    try:
        cursor.execute(f"SELECT * FROM {table} LIMIT 5")
        rows = cursor.fetchall()
        # Print column names if available
        if cursor.description:
            column_names = [desc[0] for desc in cursor.description]
            print("\t".join(column_names))
        # Print each row
        for row in rows:
            print("\t".join(map(str, row)))
    except sqlite3.OperationalError as e:
        print(f"Could not query table {table}: {e}")
    
    print("\n" + "="*50 + "\n")

conn.close()

