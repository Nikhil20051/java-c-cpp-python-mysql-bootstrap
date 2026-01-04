-- Database Setup Script
-- Generated: 01/05/2026 03:33:16
-- User: appuser

-- Create test database
CREATE DATABASE IF NOT EXISTS testdb;
USE testdb;

-- Drop tables if they exist to ensure clean state
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS users;

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    age INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create products table
CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    quantity INT DEFAULT 0
);

-- Create orders table
CREATE TABLE IF NOT EXISTS orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    product_id INT,
    quantity INT NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (product_id) REFERENCES products(id)
);

-- Insert sample users
INSERT INTO users (name, email, age) VALUES 
    ('John Doe', 'john@example.com', 25),
    ('Jane Smith', 'jane@example.com', 30),
    ('Bob Wilson', 'bob@example.com', 45);

-- Insert sample products
INSERT INTO products (name, price, quantity) VALUES 
    ('Laptop', 999.99, 10),
    ('Mouse', 19.99, 50),
    ('Keyboard', 49.99, 30);

-- Insert sample orders
INSERT INTO orders (user_id, product_id, quantity, total_price, status) VALUES 
    (1, 1, 1, 999.99, 'delivered'),
    (2, 2, 2, 39.98, 'shipped'),
    (3, 3, 1, 49.99, 'processing');

-- Create/Update application user
DROP USER IF EXISTS 'appuser'@'localhost';
CREATE USER 'appuser'@'localhost' IDENTIFIED BY '72Je!^NY06OPx$uW';
GRANT ALL PRIVILEGES ON testdb.* TO 'appuser'@'localhost';
FLUSH PRIVILEGES;

SELECT 'Database setup completed successfully!' AS status;