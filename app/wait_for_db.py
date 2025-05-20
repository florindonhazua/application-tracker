import os
import time
from sqlalchemy import create_engine
from sqlalchemy.exc import OperationalError

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://user:password@db/apptrackerdb")
MAX_TRIES = 30
WAIT_SECONDS = 2

def check_db_connection():
    engine = create_engine(DATABASE_URL)
    for i in range(MAX_TRIES):
        try:
            # Try to establish a connection
            with engine.connect() as connection:
                print("Database connection successful.")
                return True
        except OperationalError as e:
            print(f"Database connection attempt {i+1}/{MAX_TRIES} failed: {e}")
            if i < MAX_TRIES - 1:
                print(f"Retrying in {WAIT_SECONDS} seconds...")
                time.sleep(WAIT_SECONDS)
            else:
                print("Max retries reached. Could not connect to the database.")
                return False
    return False

if __name__ == "__main__":
    if not check_db_connection():
        exit(1) # Exit with error code if connection failed
    print("Proceeding to start application...") 