import json
import sqlite3

# Define the database and JSON file paths
DB_FILE = "data/data.db"          # Update if your database file has a different name
JSON_FILE = "output.json"  # Update with the actual JSON file path

# Connect to the SQLite database
conn = sqlite3.connect(DB_FILE)
cursor = conn.cursor()

# Create the Nonprofits table if it doesn't exist
cursor.execute("""
CREATE TABLE IF NOT EXISTS Nonprofits (
    id TEXT PRIMARY KEY,
    primary_tags TEXT,
    secondary_tags TEXT
)
""")

# Load JSON data from file
with open(JSON_FILE, "r", encoding="utf-8") as file:
    nonprofits_data = json.load(file)

# Insert data into the Nonprofits table
for entry in nonprofits_data:
    nonprofit_id = entry["id"]
    primary_tags = ", ".join(entry["primaryTags"])
    secondary_tags = ", ".join(entry["secondaryTags"])
    
    cursor.execute("""
    INSERT OR REPLACE INTO Nonprofits (id, primary_tags, secondary_tags)
    VALUES (?, ?, ?)
    """, (nonprofit_id, primary_tags, secondary_tags))

# Commit changes and close the database connection
conn.commit()
conn.close()

print("Data successfully inserted into the Nonprofits table.")

