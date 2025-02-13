import sqlite3
import datetime
import hashlib

class CoinLedger:
    def __init__(self, db_path='data.db'):
        """Initializes the ledger and creates the table if it doesn't exist."""
        self.conn = sqlite3.connect(db_path)
        self.create_table()

    def create_table(self):
        """Creates the coin_ledger table with required columns."""
        cursor = self.conn.cursor()
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS coin_ledger (
                transactionID TEXT PRIMARY KEY,
                timestamp TEXT,
                userID TEXT,
                amount REAL,
                nonprofitID TEXT
            )
        ''')
        self.conn.commit()

    def add(self, userID, amount, nonprofitID):
        """
        Adds a payment from a user to a charity to the ledger.
        
        Parameters:
            userID (str): The user's ID.
            amount (float): The amount of coins paid.
            nonprofitID (str): The nonprofit's ID.
        
        Returns:
            str: The generated transactionID.
        """
        # Generate a timestamp in UTC
        timestamp = datetime.datetime.now().isoformat()

        # Create a transactionID by hashing the timestamp and transaction details
        transaction_data = f"{timestamp}-{userID}-{amount}-{nonprofitID}"
        transactionID = hashlib.sha256(transaction_data.encode('utf-8')).hexdigest()

        # Insert the new transaction into the database
        cursor = self.conn.cursor()
        cursor.execute('''
            INSERT INTO coin_ledger (transactionID, timestamp, userID, amount, nonprofitID)
            VALUES (?, ?, ?, ?, ?)
        ''', (transactionID, timestamp, userID, amount, nonprofitID))
        self.conn.commit()

        return transactionID

    def remove(self, transactionID):
        """
        Removes a transaction from the ledger, e.g., in case of refund or cancellation.
        
        Parameters:
            transactionID (str): The ID of the transaction to be removed.
        """
        cursor = self.conn.cursor()
        cursor.execute('''
            DELETE FROM coin_ledger WHERE transactionID = ?
        ''', (transactionID,))
        self.conn.commit()

    def __del__(self):
        """Closes the database connection when the instance is destroyed."""
        self.conn.close()
