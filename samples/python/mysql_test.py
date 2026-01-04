# Copyright (c) 2026 dmj.one
#
# This software is part of the dmj.one initiative.
# Created by Nikhil Bhardwaj.
#
# Licensed under the MIT License.
#!/usr/bin/env python3
"""
Python MySQL Test Program
Demonstrates CRUD operations and database connectivity using mysql-connector-python

Run: python samples/python/mysql_test.py
"""

import mysql.connector
from mysql.connector import Error
from datetime import datetime
import sys

# Database configuration
DB_CONFIG = {
    'host': 'localhost',
    'port': 3306,
    'database': 'testdb',
    'user': 'testuser',
    'password': 'testpass123',
    'autocommit': True
}


class MySQLTest:
    def __init__(self):
        self.connection = None
        self.connect()
    
    def connect(self):
        """Establish database connection"""
        try:
            self.connection = mysql.connector.connect(**DB_CONFIG)
            if self.connection.is_connected():
                db_info = self.connection.get_server_info()
                print(f"[OK] Connected to MySQL Server version {db_info}")
                
                cursor = self.connection.cursor()
                cursor.execute("SELECT DATABASE();")
                database = cursor.fetchone()[0]
                print(f"[OK] Connected to database: {database}")
                cursor.close()
                
        except Error as e:
            print(f"[ERROR] Failed to connect to MySQL: {e}")
            sys.exit(1)
    
    def test_select(self):
        """Test 1: Basic SELECT query"""
        print("\n=== Test 1: SELECT Query ===")
        
        try:
            cursor = self.connection.cursor(dictionary=True)
            cursor.execute("SELECT id, name, email, age FROM users")
            users = cursor.fetchall()
            
            print("Users in database:")
            print("-" * 60)
            print(f"{'ID':<5} {'Name':<20} {'Email':<30} {'Age':<5}")
            print("-" * 60)
            
            for user in users:
                print(f"{user['id']:<5} {user['name']:<20} {user['email']:<30} {user['age'] or 'N/A':<5}")
            
            print("-" * 60)
            print(f"[OK] Retrieved {len(users)} users successfully!")
            cursor.close()
            
        except Error as e:
            print(f"[ERROR] SELECT failed: {e}")
    
    def test_insert(self):
        """Test 2: INSERT with parameterized query"""
        print("\n=== Test 2: INSERT Query ===")
        
        try:
            cursor = self.connection.cursor()
            query = "INSERT INTO users (name, email, age) VALUES (%s, %s, %s)"
            values = ("Test User (Python)", "python.test@example.com", 28)
            
            cursor.execute(query, values)
            self.connection.commit()
            
            print(f"[OK] Inserted new user with ID: {cursor.lastrowid}")
            cursor.close()
            
        except Error as e:
            if "Duplicate entry" in str(e):
                print("[INFO] User already exists (duplicate email)")
            else:
                print(f"[ERROR] INSERT failed: {e}")
    
    def test_update(self):
        """Test 3: UPDATE query"""
        print("\n=== Test 3: UPDATE Query ===")
        
        try:
            cursor = self.connection.cursor()
            query = "UPDATE users SET age = age + 1 WHERE email = %s"
            cursor.execute(query, ("python.test@example.com",))
            self.connection.commit()
            
            print(f"[OK] Updated {cursor.rowcount} row(s)")
            cursor.close()
            
        except Error as e:
            print(f"[ERROR] UPDATE failed: {e}")
    
    def test_join(self):
        """Test 4: JOIN query"""
        print("\n=== Test 4: JOIN Query (Orders with User and Product info) ===")
        
        try:
            cursor = self.connection.cursor(dictionary=True)
            query = """
                SELECT o.id, u.name AS customer, p.name AS product, 
                       o.quantity, o.total_price, o.status
                FROM orders o
                JOIN users u ON o.user_id = u.id
                JOIN products p ON o.product_id = p.id
                ORDER BY o.order_date DESC
            """
            cursor.execute(query)
            orders = cursor.fetchall()
            
            print("-" * 90)
            print(f"{'ID':<5} {'Customer':<20} {'Product':<20} {'Qty':<8} {'Total':<12} {'Status':<12}")
            print("-" * 90)
            
            for order in orders:
                print(f"{order['id']:<5} {order['customer']:<20} {order['product']:<20} "
                      f"{order['quantity']:<8} ${order['total_price']:<11.2f} {order['status']:<12}")
            
            print("-" * 90)
            print("[OK] JOIN query executed successfully!")
            cursor.close()
            
        except Error as e:
            print(f"[ERROR] JOIN query failed: {e}")
    
    def test_aggregates(self):
        """Test 5: Aggregate functions"""
        print("\n=== Test 5: Aggregate Functions ===")
        
        try:
            cursor = self.connection.cursor(dictionary=True)
            
            # Count users
            cursor.execute("SELECT COUNT(*) AS count FROM users")
            result = cursor.fetchone()
            print(f"Total users: {result['count']}")
            
            # Average age
            cursor.execute("SELECT AVG(age) AS avg_age FROM users WHERE age IS NOT NULL")
            result = cursor.fetchone()
            print(f"Average user age: {result['avg_age']:.2f}" if result['avg_age'] else "Average user age: N/A")
            
            # Total revenue
            cursor.execute("SELECT SUM(total_price) AS revenue FROM orders WHERE status = 'delivered'")
            result = cursor.fetchone()
            print(f"Total revenue (delivered orders): ${result['revenue']:.2f}" if result['revenue'] else "Total revenue: $0.00")
            
            # Products inventory
            cursor.execute("SELECT SUM(quantity) AS total_stock FROM products")
            result = cursor.fetchone()
            print(f"Total products in stock: {result['total_stock']}")
            
            print("[OK] Aggregate queries completed successfully!")
            cursor.close()
            
        except Error as e:
            print(f"[ERROR] Aggregate query failed: {e}")
    
    def test_transaction(self):
        """Test 6: Transaction handling"""
        print("\n=== Test 6: Transaction Test ===")
        
        try:
            # Disable autocommit for transaction
            self.connection.autocommit = False
            cursor = self.connection.cursor()
            
            # Insert a temporary product
            cursor.execute(
                "INSERT INTO products (name, description, price, quantity) "
                "VALUES ('Test Product', 'Transaction test', 99.99, 10)"
            )
            print("[OK] Inserted test product")
            
            # Rollback the transaction
            self.connection.rollback()
            print("[OK] Transaction rolled back successfully!")
            
            # Verify rollback
            cursor.execute("SELECT COUNT(*) FROM products WHERE name = 'Test Product'")
            count = cursor.fetchone()[0]
            if count == 0:
                print("[OK] Rollback verified - test product not in database")
            
            # Re-enable autocommit
            self.connection.autocommit = True
            cursor.close()
            
        except Error as e:
            print(f"[ERROR] Transaction test failed: {e}")
            self.connection.rollback()
            self.connection.autocommit = True
    
    def test_stored_procedure(self):
        """Test 7: Create and call stored procedure (if supported)"""
        print("\n=== Test 7: Stored Procedure Test ===")
        
        try:
            cursor = self.connection.cursor()
            
            # Drop procedure if exists
            cursor.execute("DROP PROCEDURE IF EXISTS GetUserCount")
            
            # Create stored procedure
            create_proc = """
                CREATE PROCEDURE GetUserCount(OUT user_count INT)
                BEGIN
                    SELECT COUNT(*) INTO user_count FROM users;
                END
            """
            cursor.execute(create_proc)
            self.connection.commit()
            print("[OK] Stored procedure created")
            
            # Call the stored procedure
            args = [0]  # OUT parameter
            result = cursor.callproc('GetUserCount', args)
            print(f"[OK] Stored procedure returned: user_count = {result[0]}")
            
            cursor.close()
            
        except Error as e:
            print(f"[WARN] Stored procedure test skipped: {e}")
    
    def test_batch_insert(self):
        """Test 8: Batch insert operation"""
        print("\n=== Test 8: Batch Insert Test ===")
        
        try:
            cursor = self.connection.cursor()
            
            # Create temporary test table
            cursor.execute("""
                CREATE TEMPORARY TABLE IF NOT EXISTS temp_test (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    value VARCHAR(100)
                )
            """)
            
            # Batch insert
            batch_data = [(f"Value {i}",) for i in range(1, 101)]
            cursor.executemany("INSERT INTO temp_test (value) VALUES (%s)", batch_data)
            self.connection.commit()
            
            print(f"[OK] Batch inserted {cursor.rowcount} rows")
            
            # Verify
            cursor.execute("SELECT COUNT(*) FROM temp_test")
            count = cursor.fetchone()[0]
            print(f"[OK] Verified: {count} rows in temporary table")
            
            cursor.close()
            
        except Error as e:
            print(f"[ERROR] Batch insert failed: {e}")
    
    def cleanup(self):
        """Clean up test data"""
        print("\n=== Cleanup ===")
        
        try:
            cursor = self.connection.cursor()
            cursor.execute("DELETE FROM users WHERE email = 'python.test@example.com'")
            self.connection.commit()
            print(f"[OK] Cleaned up {cursor.rowcount} test user(s)")
            cursor.close()
            
        except Error as e:
            print(f"[WARN] Cleanup failed: {e}")
    
    def close(self):
        """Close database connection"""
        if self.connection and self.connection.is_connected():
            self.connection.close()
            print("\n[OK] Database connection closed.")


def main():
    print("â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—")
    print("â•‘           Python MySQL Connectivity Test                  â•‘")
    print("â•‘           Testing CRUD Operations                         â•‘")
    print("â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•")
    
    test = MySQLTest()
    
    # Run all tests
    test.test_select()
    test.test_insert()
    test.test_update()
    test.test_join()
    test.test_aggregates()
    test.test_transaction()
    test.test_stored_procedure()
    test.test_batch_insert()
    test.cleanup()
    
    # Summary
    print("\nâ•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—")
    print("â•‘         All Python MySQL Tests Completed!                 â•‘")
    print("â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•")
    
    test.close()


if __name__ == "__main__":
    main()

