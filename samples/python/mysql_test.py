# Copyright (c) 2026 dmj.one
#
# This software is part of the dmj.one initiative.
# Created by Nikhil Bhardwaj.
#
# Licensed under the MIT License.
#!/usr/bin/env python3
"""
Python MySQL Test Program - Enterprise Edition
Demonstrates CRUD operations, database connectivity, and robust error handling
using mysql-connector-python with professional logging and typing.

Run: python samples/python/mysql_test.py
"""

import mysql.connector
from mysql.connector import Error
from mysql.connector.cursor import MySQLCursor
from typing import Optional, List, Dict, Any, Tuple
import logging
import sys
import os
from contextlib import contextmanager

# ==============================================================================
# CONFIGURATION & LOGGING
# ==============================================================================

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - [%(levelname)s] - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger("MySQLTest")

# Configuration via Environment Variables (12-Factor App Pattern)
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'port': int(os.getenv('DB_PORT', 3306)),
    'database': os.getenv('DB_NAME', 'testdb'),
    'user': os.getenv('DB_USER', 'appuser'),
    'password': os.getenv('DB_PASSWORD', '72Je!^NY06OPx$uW'),
    'autocommit': True
}

class DatabaseManager:
    """Manages database connections and operations."""
    
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.connection = None

    @contextmanager
    def connect(self):
        """Context manager for database connections."""
        try:
            self.connection = mysql.connector.connect(**self.config)
            if self.connection.is_connected():
                logger.info(f"Connected to MySQL Server version {self.connection.server_info}")
                yield self.connection
        except Error as e:
            logger.error(f"Database connection failure: {e}")
            raise
        finally:
            if self.connection and self.connection.is_connected():
                self.connection.close()
                logger.info("Database connection closed.")

class UsersDAO:
    """Data Access Object for Users operations."""
    
    def __init__(self, connection):
        self.connection = connection

    def get_all(self) -> List[Dict[str, Any]]:
        try:
            with self.connection.cursor(dictionary=True) as cursor:
                cursor.execute("SELECT id, name, email, age FROM users")
                return cursor.fetchall()
        except Error as e:
            logger.error(f"Failed to fetch users: {e}")
            return []

    def create(self, name: str, email: str, age: int) -> Optional[int]:
        try:
            with self.connection.cursor() as cursor:
                query = "INSERT INTO users (name, email, age) VALUES (%s, %s, %s)"
                cursor.execute(query, (name, email, age))
                self.connection.commit()
                logger.info(f"User created with ID: {cursor.lastrowid}")
                return cursor.lastrowid
        except Error as e:
            if "Duplicate entry" in str(e):
                logger.warning(f"User with email {email} already exists.")
            else:
                logger.error(f"Failed to create user: {e}")
            return None

    def increment_age(self, email: str) -> bool:
        try:
            with self.connection.cursor() as cursor:
                query = "UPDATE users SET age = age + 1 WHERE email = %s"
                cursor.execute(query, (email,))
                self.connection.commit()
                return cursor.rowcount > 0
        except Error as e:
            logger.error(f"Failed to update user: {e}")
            return False

def print_separator(title: str):
    print(f"\n{'='*20} {title} {'='*20}")

def run_tests():
    logger.info("Starting Enterprise MySQL Test Suite...")
    
    db_manager = DatabaseManager(DB_CONFIG)
    
    try:
        with db_manager.connect() as conn:
            user_dao = UsersDAO(conn)

            # --- Test 1: READ ---
            print_separator("Test 1: Read Users")
            users = user_dao.get_all()
            print(f"{'ID':<5} {'Name':<20} {'Email':<30} {'Age':<5}")
            print("-" * 65)
            for user in users:
                print(f"{user['id']:<5} {user['name']:<20} {user['email']:<30} {user['age'] or 'N/A':<5}")
            logger.info(f"Retrieved {len(users)} users.")

            # --- Test 2: CREATE ---
            print_separator("Test 2: Create User")
            new_id = user_dao.create("Test User (Python)", "python.ent.test@example.com", 29)
            if new_id:
                logger.info("Create operation validated.")

            # --- Test 3: UPDATE ---
            print_separator("Test 3: Update User")
            if user_dao.increment_age("python.ent.test@example.com"):
                logger.info("Update operation validated.")
            else:
                logger.warning("Update operation affected 0 rows (user might not exist).")

            # --- CLEANUP ---
            print_separator("Cleanup")
            with conn.cursor() as cursor:
                cursor.execute("DELETE FROM users WHERE email = %s", ("python.ent.test@example.com",))
                conn.commit()
                logger.info(f"Cleaned up {cursor.rowcount} test records.")

    except Exception as e:
        logger.critical(f"Test suite failed due to unexpected error: {e}")
        sys.exit(1)

    logger.info("Test suite completed successfully.")

if __name__ == "__main__":
    run_tests()
