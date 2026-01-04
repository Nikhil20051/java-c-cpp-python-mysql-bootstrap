/*
 * Copyright (c) 2026 dmj.one
 *
 * This software is part of the dmj.one initiative.
 * Created by Nikhil Bhardwaj.
 *
 * Licensed under the MIT License.
 */
/**
 * C++ MySQL Test Program
 * Demonstrates CRUD operations and database connectivity using MySQL C++ Connector
 * 
 * This program uses the MySQL C API wrapped in C++ classes for a more modern approach.
 * 
 * Compile: g++ -o mysql_test mysql_test.cpp -I"%MYSQL_INCLUDE%" -L"%MYSQL_LIB%" -lmysqlclient
 * Run: mysql_test.exe
 */

#include <iostream>
#include <string>
#include <vector>
#include <memory>
#include <iomanip>
#include <sstream>

#ifdef _WIN32
#include <windows.h>
#endif

/* MySQL C API Header */
#include <mysql.h>

using namespace std;

/* Database configuration */
const string DB_HOST = "localhost";
const string DB_USER = "appuser";
const string DB_PASS = "Rg4%e1aCQZ^laRzR";
const string DB_NAME = "testdb";
const int DB_PORT = 3306;

/**
 * Simple RAII wrapper for MySQL connection
 */
class MySQLConnection {
private:
    MYSQL* conn;
    bool connected;

public:
    MySQLConnection() : conn(nullptr), connected(false) {
        conn = mysql_init(nullptr);
        if (!conn) {
            throw runtime_error("Failed to initialize MySQL");
        }
    }

    ~MySQLConnection() {
        if (conn) {
            mysql_close(conn);
        }
    }

    bool connect(const string& host, const string& user, 
                const string& password, const string& database, int port) {
        if (mysql_real_connect(conn, host.c_str(), user.c_str(), password.c_str(),
                              database.c_str(), port, nullptr, 0) == nullptr) {
            cerr << "[ERROR] Connection failed: " << mysql_error(conn) << endl;
            return false;
        }
        
        mysql_set_character_set(conn, "utf8mb4");
        connected = true;
        return true;
    }

    bool isConnected() const { return connected; }

    MYSQL* getConnection() { return conn; }

    string getServerInfo() {
        return mysql_get_server_info(conn);
    }

    string escape(const string& str) {
        vector<char> buffer(str.length() * 2 + 1);
        mysql_real_escape_string(conn, buffer.data(), str.c_str(), str.length());
        return string(buffer.data());
    }

    bool query(const string& sql) {
        if (mysql_query(conn, sql.c_str()) != 0) {
            cerr << "[ERROR] Query failed: " << mysql_error(conn) << endl;
            return false;
        }
        return true;
    }

    unsigned long long getInsertId() {
        return mysql_insert_id(conn);
    }

    unsigned long long getAffectedRows() {
        return mysql_affected_rows(conn);
    }

    const char* getError() {
        return mysql_error(conn);
    }
};

/**
 * RAII wrapper for MySQL result set
 */
class MySQLResult {
private:
    MYSQL_RES* result;

public:
    MySQLResult(MYSQL* conn) {
        result = mysql_store_result(conn);
    }

    ~MySQLResult() {
        if (result) {
            mysql_free_result(result);
        }
    }

    bool isValid() const { return result != nullptr; }

    int numRows() const {
        return result ? (int)mysql_num_rows(result) : 0;
    }

    int numFields() const {
        return result ? mysql_num_fields(result) : 0;
    }

    MYSQL_ROW fetchRow() {
        return result ? mysql_fetch_row(result) : nullptr;
    }

    MYSQL_FIELD* fetchFields() {
        return result ? mysql_fetch_fields(result) : nullptr;
    }
};

// Utility functions
void printHeader(const string& title) {
    cout << "\n============================================" << endl;
    cout << "  " << title << endl;
    cout << "============================================\n" << endl;
}

void printSeparator(int width) {
    cout << string(width, '-') << endl;
}

void printSuccess(const string& message) {
    cout << "[OK] " << message << endl;
}

void printError(const string& message) {
    cerr << "[ERROR] " << message << endl;
}

/**
 * MySQL Test Class
 */
class MySQLTest {
private:
    unique_ptr<MySQLConnection> db;

public:
    MySQLTest() : db(make_unique<MySQLConnection>()) {}

    bool connect() {
        printHeader("Connecting to MySQL Database");
        
        if (!db->connect(DB_HOST, DB_USER, DB_PASS, DB_NAME, DB_PORT)) {
            return false;
        }

        cout << "[OK] Connected to MySQL Server version: " << db->getServerInfo() << endl;
        cout << "[OK] Connected to database: " << DB_NAME << endl;
        return true;
    }

    void testSelect() {
        printHeader("Test 1: SELECT Query");
        
        if (!db->query("SELECT id, name, email, age FROM users")) {
            return;
        }

        MySQLResult result(db->getConnection());
        if (!result.isValid()) {
            printError("Failed to get result set");
            return;
        }

        cout << "Users in database:" << endl;
        printSeparator(70);
        cout << left << setw(5) << "ID" 
             << setw(20) << "Name" 
             << setw(35) << "Email" 
             << setw(5) << "Age" << endl;
        printSeparator(70);

        int count = 0;
        MYSQL_ROW row;
        while ((row = result.fetchRow())) {
            cout << left << setw(5) << (row[0] ? row[0] : "N/A")
                 << setw(20) << (row[1] ? row[1] : "N/A")
                 << setw(35) << (row[2] ? row[2] : "N/A")
                 << setw(5) << (row[3] ? row[3] : "N/A") << endl;
            count++;
        }

        printSeparator(70);
        cout << "[OK] Retrieved " << count << " users successfully!" << endl;
    }

    void testInsert() {
        printHeader("Test 2: INSERT Query");
        
        string name = db->escape("Test User (C++)");
        string email = db->escape("cpp.test@example.com");
        int age = 32;

        stringstream query;
        query << "INSERT INTO users (name, email, age) VALUES ('"
              << name << "', '" << email << "', " << age << ")";

        if (!db->query(query.str())) {
            string error = db->getError();
            if (error.find("Duplicate entry") != string::npos) {
                cout << "[INFO] User already exists (duplicate email)" << endl;
            } else {
                printError("INSERT failed");
            }
            return;
        }

        cout << "[OK] Inserted new user with ID: " << db->getInsertId() << endl;
    }

    void testUpdate() {
        printHeader("Test 3: UPDATE Query");
        
        if (!db->query("UPDATE users SET age = age + 1 WHERE email = 'cpp.test@example.com'")) {
            return;
        }

        cout << "[OK] Updated " << db->getAffectedRows() << " row(s)" << endl;
    }

    void testJoin() {
        printHeader("Test 4: JOIN Query (Orders with User and Product info)");
        
        string query = 
            "SELECT o.id, u.name AS customer, p.name AS product, "
            "o.quantity, o.total_price, o.status "
            "FROM orders o "
            "JOIN users u ON o.user_id = u.id "
            "JOIN products p ON o.product_id = p.id "
            "ORDER BY o.order_date DESC";

        if (!db->query(query)) {
            return;
        }

        MySQLResult result(db->getConnection());
        if (!result.isValid()) {
            printError("Failed to get result set");
            return;
        }

        printSeparator(90);
        cout << left << setw(5) << "ID" 
             << setw(20) << "Customer" 
             << setw(20) << "Product"
             << setw(8) << "Qty" 
             << setw(12) << "Total"
             << setw(12) << "Status" << endl;
        printSeparator(90);

        MYSQL_ROW row;
        while ((row = result.fetchRow())) {
            cout << left << setw(5) << (row[0] ? row[0] : "N/A")
                 << setw(20) << (row[1] ? row[1] : "N/A")
                 << setw(20) << (row[2] ? row[2] : "N/A")
                 << setw(8) << (row[3] ? row[3] : "N/A")
                 << "$" << setw(11) << (row[4] ? row[4] : "N/A")
                 << setw(12) << (row[5] ? row[5] : "N/A") << endl;
        }

        printSeparator(90);
        printSuccess("JOIN query executed successfully!");
    }

    void testAggregates() {
        printHeader("Test 5: Aggregate Functions");
        
        // Count users
        if (db->query("SELECT COUNT(*) AS count FROM users")) {
            MySQLResult result(db->getConnection());
            MYSQL_ROW row;
            if (result.isValid() && (row = result.fetchRow())) {
                cout << "Total users: " << (row[0] ? row[0] : "0") << endl;
            }
        }

        // Average age
        if (db->query("SELECT AVG(age) AS avg_age FROM users WHERE age IS NOT NULL")) {
            MySQLResult result(db->getConnection());
            MYSQL_ROW row;
            if (result.isValid() && (row = result.fetchRow())) {
                cout << "Average user age: " << (row[0] ? row[0] : "N/A") << endl;
            }
        }

        // Total revenue
        if (db->query("SELECT SUM(total_price) AS revenue FROM orders WHERE status = 'delivered'")) {
            MySQLResult result(db->getConnection());
            MYSQL_ROW row;
            if (result.isValid() && (row = result.fetchRow())) {
                cout << "Total revenue (delivered orders): $" << (row[0] ? row[0] : "0.00") << endl;
            }
        }

        // Products inventory
        if (db->query("SELECT SUM(quantity) AS total_stock FROM products")) {
            MySQLResult result(db->getConnection());
            MYSQL_ROW row;
            if (result.isValid() && (row = result.fetchRow())) {
                cout << "Total products in stock: " << (row[0] ? row[0] : "0") << endl;
            }
        }

        printSuccess("Aggregate queries completed successfully!");
    }

    void testOOP() {
        printHeader("Test 6: C++ OOP Features - Using STL");
        
        // Demonstrate using STL containers with MySQL data
        vector<pair<int, string>> users;

        if (db->query("SELECT id, name FROM users")) {
            MySQLResult result(db->getConnection());
            MYSQL_ROW row;
            while ((row = result.fetchRow())) {
                if (row[0] && row[1]) {
                    users.emplace_back(atoi(row[0]), row[1]);
                }
            }
        }

        cout << "Users stored in STL vector:" << endl;
        for (const auto& user : users) {
            cout << "  ID: " << user.first << ", Name: " << user.second << endl;
        }

        printSuccess("C++ STL integration works correctly!");
    }

    void cleanup() {
        printHeader("Cleanup");
        
        if (!db->query("DELETE FROM users WHERE email = 'cpp.test@example.com'")) {
            cerr << "[WARN] Cleanup failed" << endl;
            return;
        }

        cout << "[OK] Cleaned up " << db->getAffectedRows() << " test user(s)" << endl;
    }

    void runAllTests() {
        testSelect();
        testInsert();
        testUpdate();
        testJoin();
        testAggregates();
        testOOP();
        cleanup();
    }
};

int main(int argc, char* argv[]) {
    cout << endl;
    cout << "+============================================================+" << endl;
    cout << "|           C++ MySQL Connectivity Test                      |" << endl;
    cout << "|           Testing CRUD Operations with OOP                 |" << endl;
    cout << "+============================================================+" << endl;

    try {
        MySQLTest test;
        
        if (!test.connect()) {
            cerr << "\nFailed to connect to database. Exiting." << endl;
            return 1;
        }

        test.runAllTests();

        cout << endl;
        cout << "+============================================================+" << endl;
        cout << "|           All C++ MySQL Tests Completed!                   |" << endl;
        cout << "+============================================================+" << endl;

    } catch (const exception& e) {
        cerr << "[FATAL] Exception: " << e.what() << endl;
        return 1;
    }

    cout << "\n[OK] Database connection closed." << endl;
    return 0;
}

