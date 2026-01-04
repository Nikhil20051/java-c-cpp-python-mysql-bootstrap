/*
 * Copyright (c) 2026 dmj.one
 *
 * This software is part of the dmj.one initiative.
 * Created by Nikhil Bhardwaj.
 *
 * Licensed under the MIT License.
 */
/**
 * C MySQL Test Program
 * Demonstrates CRUD operations and database connectivity using MySQL C API
 * 
 * Compile: gcc -o mysql_test mysql_test.c -I"%MYSQL_INCLUDE%" -L"%MYSQL_LIB%" -lmysqlclient
 * Run: mysql_test.exe
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef _WIN32
#include <windows.h>
#endif

/* MySQL C API Header */
#include <mysql.h>

/* Database configuration */
#define DB_HOST "localhost"
#define DB_USER "appuser"
#define DB_PASS "Rg4%e1aCQZ^laRzR"
#define DB_NAME "testdb"
#define DB_PORT 3306

/* Global MySQL connection handle */
MYSQL *conn = NULL;

/* Function prototypes */
void print_header(const char* title);
void print_success(const char* message);
void print_error(const char* message);
void print_separator(int width);
int connect_to_database(void);
void test_select(void);
void test_insert(void);
void test_update(void);
void test_join(void);
void test_aggregates(void);
void cleanup(void);
void close_connection(void);

/* Print formatted header */
void print_header(const char* title) {
    printf("\n============================================\n");
    printf("  %s\n", title);
    printf("============================================\n\n");
}

/* Print success message */
void print_success(const char* message) {
    printf("[OK] %s\n", message);
}

/* Print error message */
void print_error(const char* message) {
    printf("[ERROR] %s\n", message);
}

/* Print separator line */
void print_separator(int width) {
    for (int i = 0; i < width; i++) {
        printf("-");
    }
    printf("\n");
}

/* Connect to MySQL database */
int connect_to_database(void) {
    print_header("Connecting to MySQL Database");
    
    /* Initialize MySQL library */
    conn = mysql_init(NULL);
    if (conn == NULL) {
        print_error("Failed to initialize MySQL");
        return 0;
    }
    
    /* Connect to database */
    if (mysql_real_connect(conn, DB_HOST, DB_USER, DB_PASS, 
                          DB_NAME, DB_PORT, NULL, 0) == NULL) {
        fprintf(stderr, "[ERROR] Connection failed: %s\n", mysql_error(conn));
        mysql_close(conn);
        return 0;
    }
    
    printf("[OK] Connected to MySQL Server version: %s\n", mysql_get_server_info(conn));
    printf("[OK] Connected to database: %s\n", DB_NAME);
    
    /* Set character set to UTF-8 */
    mysql_set_character_set(conn, "utf8mb4");
    
    return 1;
}

/* Test 1: Basic SELECT query */
void test_select(void) {
    print_header("Test 1: SELECT Query");
    
    const char* query = "SELECT id, name, email, age FROM users";
    
    if (mysql_query(conn, query)) {
        fprintf(stderr, "[ERROR] SELECT failed: %s\n", mysql_error(conn));
        return;
    }
    
    MYSQL_RES *result = mysql_store_result(conn);
    if (result == NULL) {
        fprintf(stderr, "[ERROR] Failed to store result: %s\n", mysql_error(conn));
        return;
    }
    
    printf("Users in database:\n");
    print_separator(70);
    printf("%-5s %-20s %-35s %-5s\n", "ID", "Name", "Email", "Age");
    print_separator(70);
    
    int num_rows = 0;
    MYSQL_ROW row;
    while ((row = mysql_fetch_row(result))) {
        printf("%-5s %-20s %-35s %-5s\n", 
               row[0] ? row[0] : "N/A",
               row[1] ? row[1] : "N/A",
               row[2] ? row[2] : "N/A",
               row[3] ? row[3] : "N/A");
        num_rows++;
    }
    
    print_separator(70);
    printf("[OK] Retrieved %d users successfully!\n", num_rows);
    
    mysql_free_result(result);
}

/* Test 2: INSERT with escaped values */
void test_insert(void) {
    print_header("Test 2: INSERT Query");
    
    /* Prepare the data */
    const char* name = "Test User (C)";
    const char* email = "c.test@example.com";
    int age = 30;
    
    /* Escape strings to prevent SQL injection */
    char escaped_name[256];
    char escaped_email[256];
    mysql_real_escape_string(conn, escaped_name, name, strlen(name));
    mysql_real_escape_string(conn, escaped_email, email, strlen(email));
    
    /* Build query */
    char query[512];
    snprintf(query, sizeof(query), 
             "INSERT INTO users (name, email, age) VALUES ('%s', '%s', %d)",
             escaped_name, escaped_email, age);
    
    if (mysql_query(conn, query)) {
        const char* error = mysql_error(conn);
        if (strstr(error, "Duplicate entry")) {
            printf("[INFO] User already exists (duplicate email)\n");
        } else {
            fprintf(stderr, "[ERROR] INSERT failed: %s\n", error);
        }
        return;
    }
    
    unsigned long long insert_id = mysql_insert_id(conn);
    printf("[OK] Inserted new user with ID: %llu\n", insert_id);
}

/* Test 3: UPDATE query */
void test_update(void) {
    print_header("Test 3: UPDATE Query");
    
    const char* query = "UPDATE users SET age = age + 1 WHERE email = 'c.test@example.com'";
    
    if (mysql_query(conn, query)) {
        fprintf(stderr, "[ERROR] UPDATE failed: %s\n", mysql_error(conn));
        return;
    }
    
    unsigned long long affected_rows = mysql_affected_rows(conn);
    printf("[OK] Updated %llu row(s)\n", affected_rows);
}

/* Test 4: JOIN query */
void test_join(void) {
    print_header("Test 4: JOIN Query (Orders with User and Product info)");
    
    const char* query = 
        "SELECT o.id, u.name AS customer, p.name AS product, "
        "o.quantity, o.total_price, o.status "
        "FROM orders o "
        "JOIN users u ON o.user_id = u.id "
        "JOIN products p ON o.product_id = p.id "
        "ORDER BY o.order_date DESC";
    
    if (mysql_query(conn, query)) {
        fprintf(stderr, "[ERROR] JOIN query failed: %s\n", mysql_error(conn));
        return;
    }
    
    MYSQL_RES *result = mysql_store_result(conn);
    if (result == NULL) {
        fprintf(stderr, "[ERROR] Failed to store result: %s\n", mysql_error(conn));
        return;
    }
    
    print_separator(90);
    printf("%-5s %-20s %-20s %-8s %-12s %-12s\n", 
           "ID", "Customer", "Product", "Qty", "Total", "Status");
    print_separator(90);
    
    MYSQL_ROW row;
    while ((row = mysql_fetch_row(result))) {
        printf("%-5s %-20s %-20s %-8s $%-11s %-12s\n",
               row[0] ? row[0] : "N/A",
               row[1] ? row[1] : "N/A",
               row[2] ? row[2] : "N/A",
               row[3] ? row[3] : "N/A",
               row[4] ? row[4] : "N/A",
               row[5] ? row[5] : "N/A");
    }
    
    print_separator(90);
    print_success("JOIN query executed successfully!");
    
    mysql_free_result(result);
}

/* Test 5: Aggregate functions */
void test_aggregates(void) {
    print_header("Test 5: Aggregate Functions");
    
    MYSQL_RES *result;
    MYSQL_ROW row;
    
    /* Count users */
    if (mysql_query(conn, "SELECT COUNT(*) AS count FROM users") == 0) {
        result = mysql_store_result(conn);
        if (result && (row = mysql_fetch_row(result))) {
            printf("Total users: %s\n", row[0]);
        }
        mysql_free_result(result);
    }
    
    /* Average age */
    if (mysql_query(conn, "SELECT AVG(age) AS avg_age FROM users WHERE age IS NOT NULL") == 0) {
        result = mysql_store_result(conn);
        if (result && (row = mysql_fetch_row(result))) {
            printf("Average user age: %s\n", row[0] ? row[0] : "N/A");
        }
        mysql_free_result(result);
    }
    
    /* Total revenue */
    if (mysql_query(conn, "SELECT SUM(total_price) AS revenue FROM orders WHERE status = 'delivered'") == 0) {
        result = mysql_store_result(conn);
        if (result && (row = mysql_fetch_row(result))) {
            printf("Total revenue (delivered orders): $%s\n", row[0] ? row[0] : "0.00");
        }
        mysql_free_result(result);
    }
    
    /* Products inventory */
    if (mysql_query(conn, "SELECT SUM(quantity) AS total_stock FROM products") == 0) {
        result = mysql_store_result(conn);
        if (result && (row = mysql_fetch_row(result))) {
            printf("Total products in stock: %s\n", row[0] ? row[0] : "0");
        }
        mysql_free_result(result);
    }
    
    print_success("Aggregate queries completed successfully!");
}

/* Clean up test data */
void cleanup(void) {
    print_header("Cleanup");
    
    const char* query = "DELETE FROM users WHERE email = 'c.test@example.com'";
    
    if (mysql_query(conn, query)) {
        fprintf(stderr, "[WARN] Cleanup failed: %s\n", mysql_error(conn));
        return;
    }
    
    unsigned long long affected_rows = mysql_affected_rows(conn);
    printf("[OK] Cleaned up %llu test user(s)\n", affected_rows);
}

/* Close database connection */
void close_connection(void) {
    if (conn != NULL) {
        mysql_close(conn);
        print_success("Database connection closed.");
    }
}

/* Main function */
int main(int argc, char* argv[]) {
    printf("\n");
    printf("+============================================================+\n");
    printf("|           C MySQL Connectivity Test                        |\n");
    printf("|           Testing CRUD Operations                          |\n");
    printf("+============================================================+\n");
    
    /* Connect to database */
    if (!connect_to_database()) {
        fprintf(stderr, "\nFailed to connect to database. Exiting.\n");
        return 1;
    }
    
    /* Run tests */
    test_select();
    test_insert();
    test_update();
    test_join();
    test_aggregates();
    cleanup();
    
    /* Summary */
    printf("\n");
    printf("+============================================================+\n");
    printf("|           All C MySQL Tests Completed!                     |\n");
    printf("+============================================================+\n");
    
    /* Close connection */
    close_connection();
    
    return 0;
}

