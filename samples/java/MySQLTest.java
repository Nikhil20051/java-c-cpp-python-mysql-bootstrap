import java.sql.*;
import java.util.Scanner;

/**
 * Java MySQL Test Program
 * Demonstrates CRUD operations and database connectivity
 * 
 * Compile: javac -cp ".;lib/mysql-connector-j-8.3.0/mysql-connector-j-8.3.0.jar" samples/java/MySQLTest.java
 * Run: java -cp ".;lib/mysql-connector-j-8.3.0/mysql-connector-j-8.3.0.jar;samples/java" MySQLTest
 */
public class MySQLTest {
    // Database configuration
    private static final String DB_URL = "jdbc:mysql://localhost:3306/testdb";
    private static final String DB_USER = "testuser";
    private static final String DB_PASSWORD = "testpass123";
    
    private Connection connection;
    
    public MySQLTest() {
        try {
            // Load the MySQL JDBC driver
            Class.forName("com.mysql.cj.jdbc.Driver");
            System.out.println("[OK] MySQL JDBC Driver loaded successfully!");
            
            // Establish connection
            connection = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
            System.out.println("[OK] Connected to MySQL database successfully!");
            
        } catch (ClassNotFoundException e) {
            System.err.println("[ERROR] MySQL JDBC Driver not found!");
            System.err.println("Make sure mysql-connector-j-8.x.x.jar is in your classpath.");
            System.exit(1);
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to connect to database: " + e.getMessage());
            System.exit(1);
        }
    }
    
    /**
     * Test 1: Basic SELECT query
     */
    public void testSelect() {
        System.out.println("\n=== Test 1: SELECT Query ===");
        String query = "SELECT id, name, email, age FROM users";
        
        try (Statement stmt = connection.createStatement();
             ResultSet rs = stmt.executeQuery(query)) {
            
            System.out.println("Users in database:");
            System.out.println("-".repeat(60));
            System.out.printf("%-5s %-20s %-30s %-5s%n", "ID", "Name", "Email", "Age");
            System.out.println("-".repeat(60));
            
            int count = 0;
            while (rs.next()) {
                int id = rs.getInt("id");
                String name = rs.getString("name");
                String email = rs.getString("email");
                int age = rs.getInt("age");
                System.out.printf("%-5d %-20s %-30s %-5d%n", id, name, email, age);
                count++;
            }
            System.out.println("-".repeat(60));
            System.out.println("[OK] Retrieved " + count + " users successfully!");
            
        } catch (SQLException e) {
            System.err.println("[ERROR] SELECT failed: " + e.getMessage());
        }
    }
    
    /**
     * Test 2: INSERT with PreparedStatement
     */
    public void testInsert() {
        System.out.println("\n=== Test 2: INSERT Query ===");
        String query = "INSERT INTO users (name, email, age) VALUES (?, ?, ?)";
        
        try (PreparedStatement pstmt = connection.prepareStatement(query, Statement.RETURN_GENERATED_KEYS)) {
            pstmt.setString(1, "Test User (Java)");
            pstmt.setString(2, "java.test@example.com");
            pstmt.setInt(3, 25);
            
            int rowsAffected = pstmt.executeUpdate();
            
            if (rowsAffected > 0) {
                ResultSet rs = pstmt.getGeneratedKeys();
                if (rs.next()) {
                    long newId = rs.getLong(1);
                    System.out.println("[OK] Inserted new user with ID: " + newId);
                }
            }
            
        } catch (SQLException e) {
            if (e.getMessage().contains("Duplicate entry")) {
                System.out.println("[INFO] User already exists (duplicate email)");
            } else {
                System.err.println("[ERROR] INSERT failed: " + e.getMessage());
            }
        }
    }
    
    /**
     * Test 3: UPDATE query
     */
    public void testUpdate() {
        System.out.println("\n=== Test 3: UPDATE Query ===");
        String query = "UPDATE users SET age = age + 1 WHERE email = ?";
        
        try (PreparedStatement pstmt = connection.prepareStatement(query)) {
            pstmt.setString(1, "java.test@example.com");
            
            int rowsAffected = pstmt.executeUpdate();
            System.out.println("[OK] Updated " + rowsAffected + " row(s)");
            
        } catch (SQLException e) {
            System.err.println("[ERROR] UPDATE failed: " + e.getMessage());
        }
    }
    
    /**
     * Test 4: JOIN query
     */
    public void testJoin() {
        System.out.println("\n=== Test 4: JOIN Query (Orders with User and Product info) ===");
        String query = """
            SELECT o.id, u.name AS customer, p.name AS product, 
                   o.quantity, o.total_price, o.status
            FROM orders o
            JOIN users u ON o.user_id = u.id
            JOIN products p ON o.product_id = p.id
            ORDER BY o.order_date DESC
            """;
        
        try (Statement stmt = connection.createStatement();
             ResultSet rs = stmt.executeQuery(query)) {
            
            System.out.println("-".repeat(90));
            System.out.printf("%-5s %-20s %-20s %-8s %-12s %-12s%n", 
                             "ID", "Customer", "Product", "Qty", "Total", "Status");
            System.out.println("-".repeat(90));
            
            while (rs.next()) {
                System.out.printf("%-5d %-20s %-20s %-8d $%-11.2f %-12s%n",
                    rs.getInt("id"),
                    rs.getString("customer"),
                    rs.getString("product"),
                    rs.getInt("quantity"),
                    rs.getDouble("total_price"),
                    rs.getString("status"));
            }
            System.out.println("-".repeat(90));
            System.out.println("[OK] JOIN query executed successfully!");
            
        } catch (SQLException e) {
            System.err.println("[ERROR] JOIN query failed: " + e.getMessage());
        }
    }
    
    /**
     * Test 5: Aggregate functions
     */
    public void testAggregates() {
        System.out.println("\n=== Test 5: Aggregate Functions ===");
        
        try (Statement stmt = connection.createStatement()) {
            // Count users
            ResultSet rs = stmt.executeQuery("SELECT COUNT(*) AS count FROM users");
            if (rs.next()) {
                System.out.println("Total users: " + rs.getInt("count"));
            }
            
            // Average age
            rs = stmt.executeQuery("SELECT AVG(age) AS avg_age FROM users WHERE age IS NOT NULL");
            if (rs.next()) {
                System.out.printf("Average user age: %.2f%n", rs.getDouble("avg_age"));
            }
            
            // Total revenue
            rs = stmt.executeQuery("SELECT SUM(total_price) AS revenue FROM orders WHERE status = 'delivered'");
            if (rs.next()) {
                System.out.printf("Total revenue (delivered orders): $%.2f%n", rs.getDouble("revenue"));
            }
            
            // Products inventory
            rs = stmt.executeQuery("SELECT SUM(quantity) AS total_stock FROM products");
            if (rs.next()) {
                System.out.println("Total products in stock: " + rs.getInt("total_stock"));
            }
            
            System.out.println("[OK] Aggregate queries completed successfully!");
            
        } catch (SQLException e) {
            System.err.println("[ERROR] Aggregate query failed: " + e.getMessage());
        }
    }
    
    /**
     * Test 6: Transaction handling
     */
    public void testTransaction() {
        System.out.println("\n=== Test 6: Transaction Test ===");
        
        try {
            // Disable auto-commit
            connection.setAutoCommit(false);
            
            // Perform multiple operations
            Statement stmt = connection.createStatement();
            
            // Insert a temporary product
            stmt.executeUpdate("INSERT INTO products (name, description, price, quantity) " +
                             "VALUES ('Test Product', 'Transaction test', 99.99, 10)");
            System.out.println("[OK] Inserted test product");
            
            // Rollback the transaction
            connection.rollback();
            System.out.println("[OK] Transaction rolled back successfully!");
            
            // Verify rollback
            ResultSet rs = stmt.executeQuery("SELECT COUNT(*) FROM products WHERE name = 'Test Product'");
            if (rs.next() && rs.getInt(1) == 0) {
                System.out.println("[OK] Rollback verified - test product not in database");
            }
            
            // Re-enable auto-commit
            connection.setAutoCommit(true);
            
        } catch (SQLException e) {
            System.err.println("[ERROR] Transaction test failed: " + e.getMessage());
            try {
                connection.rollback();
                connection.setAutoCommit(true);
            } catch (SQLException ex) {
                // Ignore
            }
        }
    }
    
    /**
     * Clean up test data
     */
    public void cleanup() {
        System.out.println("\n=== Cleanup ===");
        
        try (Statement stmt = connection.createStatement()) {
            int deleted = stmt.executeUpdate("DELETE FROM users WHERE email = 'java.test@example.com'");
            System.out.println("[OK] Cleaned up " + deleted + " test user(s)");
        } catch (SQLException e) {
            System.err.println("[WARN] Cleanup failed: " + e.getMessage());
        }
    }
    
    /**
     * Close database connection
     */
    public void close() {
        try {
            if (connection != null && !connection.isClosed()) {
                connection.close();
                System.out.println("\n[OK] Database connection closed.");
            }
        } catch (SQLException e) {
            System.err.println("[WARN] Error closing connection: " + e.getMessage());
        }
    }
    
    public static void main(String[] args) {
        System.out.println("╔══════════════════════════════════════════════════════════╗");
        System.out.println("║           Java MySQL Connectivity Test                    ║");
        System.out.println("║           Testing CRUD Operations                         ║");
        System.out.println("╚══════════════════════════════════════════════════════════╝");
        
        MySQLTest test = new MySQLTest();
        
        // Run all tests
        test.testSelect();
        test.testInsert();
        test.testUpdate();
        test.testJoin();
        test.testAggregates();
        test.testTransaction();
        test.cleanup();
        
        // Summary
        System.out.println("\n╔══════════════════════════════════════════════════════════╗");
        System.out.println("║           All Java MySQL Tests Completed!                 ║");
        System.out.println("╚══════════════════════════════════════════════════════════╝");
        
        test.close();
    }
}
