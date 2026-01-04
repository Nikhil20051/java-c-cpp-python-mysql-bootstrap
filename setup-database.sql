-- Copyright (c) 2026 dmj.one
--
-- This software is part of the dmj.one initiative.
-- Created by Nikhil Bhardwaj.
--
-- Licensed under the MIT License.
-- Create test database
CREATE DATABASE IF NOT EXISTS testdb;
USE testdb;

-- Create test table
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO users (name, email) VALUES 
    ('John Doe', 'john@example.com'),
    ('Jane Smith', 'jane@example.com'),
    ('Bob Wilson', 'bob@example.com');

-- Create test user for applications
CREATE USER IF NOT EXISTS 'testuser'@'localhost' IDENTIFIED BY 'testpass123';
GRANT ALL PRIVILEGES ON testdb.* TO 'testuser'@'localhost';
FLUSH PRIVILEGES;

SELECT 'Database setup completed successfully!' AS status;

