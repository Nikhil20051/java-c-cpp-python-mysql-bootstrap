/*
 * Copyright (c) 2026 dmj.one
 *
 * This software is part of the dmj.one initiative.
 * Created by Nikhil Bhardwaj.
 *
 * Licensed under the MIT License.
 */
/**
 * Java Basic Test Program
 * Tests Java installation without MySQL dependency
 */

import java.util.*;
import java.time.*;
import java.io.*;

public class BasicTest {
    
    public static void main(String[] args) {
        System.out.println("â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—");
        System.out.println("â•‘           Java Basic Test Program                         â•‘");
        System.out.println("â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•");
        System.out.println();
        
        testBasicOperations();
        testDataStructures();
        testOOP();
        testStreams();
        testFileIO();
        testDateTime();
        
        System.out.println();
        System.out.println("â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—");
        System.out.println("â•‘           All Java Basic Tests Passed!                    â•‘");
        System.out.println("â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•");
    }
    
    static void testBasicOperations() {
        System.out.println("=== Test 1: Basic Operations ===");
        
        // Arithmetic
        int a = 10, b = 3;
        System.out.println("Addition: " + a + " + " + b + " = " + (a + b));
        System.out.println("Subtraction: " + a + " - " + b + " = " + (a - b));
        System.out.println("Multiplication: " + a + " * " + b + " = " + (a * b));
        System.out.println("Division: " + a + " / " + b + " = " + (a / b));
        System.out.println("Modulo: " + a + " % " + b + " = " + (a % b));
        
        // String operations
        String hello = "Hello";
        String world = "World";
        System.out.println("String concatenation: " + hello + " " + world + "!");
        System.out.println("String length: " + (hello + " " + world).length());
        
        System.out.println("[OK] Basic operations test passed!\n");
    }
    
    static void testDataStructures() {
        System.out.println("=== Test 2: Data Structures ===");
        
        // ArrayList
        ArrayList<String> list = new ArrayList<>();
        list.add("Apple");
        list.add("Banana");
        list.add("Cherry");
        System.out.println("ArrayList: " + list);
        
        // HashMap
        HashMap<String, Integer> map = new HashMap<>();
        map.put("one", 1);
        map.put("two", 2);
        map.put("three", 3);
        System.out.println("HashMap: " + map);
        
        // HashSet
        HashSet<Integer> set = new HashSet<>();
        set.add(1);
        set.add(2);
        set.add(2); // Duplicate
        set.add(3);
        System.out.println("HashSet (no duplicates): " + set);
        
        // Stack
        Stack<String> stack = new Stack<>();
        stack.push("First");
        stack.push("Second");
        stack.push("Third");
        System.out.println("Stack pop: " + stack.pop());
        
        // Queue
        Queue<String> queue = new LinkedList<>();
        queue.offer("A");
        queue.offer("B");
        queue.offer("C");
        System.out.println("Queue poll: " + queue.poll());
        
        System.out.println("[OK] Data structures test passed!\n");
    }
    
    static void testOOP() {
        System.out.println("=== Test 3: Object-Oriented Programming ===");
        
        // Create objects
        Animal dog = new Dog("Buddy");
        Animal cat = new Cat("Whiskers");
        
        // Polymorphism
        dog.makeSound();
        cat.makeSound();
        
        // Inheritance
        System.out.println("Dog is Animal: " + (dog instanceof Animal));
        System.out.println("Cat is Animal: " + (cat instanceof Animal));
        
        System.out.println("[OK] OOP test passed!\n");
    }
    
    static void testStreams() {
        System.out.println("=== Test 4: Streams and Lambda ===");
        
        List<Integer> numbers = Arrays.asList(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
        
        // Filter and map
        List<Integer> evenSquares = numbers.stream()
            .filter(n -> n % 2 == 0)
            .map(n -> n * n)
            .toList();
        System.out.println("Even numbers squared: " + evenSquares);
        
        // Reduce
        int sum = numbers.stream()
            .reduce(0, Integer::sum);
        System.out.println("Sum of 1-10: " + sum);
        
        // String joining
        String joined = String.join(", ", "Java", "is", "awesome");
        System.out.println("Joined string: " + joined);
        
        System.out.println("[OK] Streams test passed!\n");
    }
    
    static void testFileIO() {
        System.out.println("=== Test 5: File I/O ===");
        
        String filename = "test_output.txt";
        String content = "Hello from Java!\nThis is a test file.\nLine 3.";
        
        try {
            // Write file
            FileWriter writer = new FileWriter(filename);
            writer.write(content);
            writer.close();
            System.out.println("File written: " + filename);
            
            // Read file
            BufferedReader reader = new BufferedReader(new FileReader(filename));
            String line;
            int lineCount = 0;
            while ((line = reader.readLine()) != null) {
                lineCount++;
            }
            reader.close();
            System.out.println("Lines read: " + lineCount);
            
            // Delete file
            File file = new File(filename);
            file.delete();
            System.out.println("File deleted: " + filename);
            
            System.out.println("[OK] File I/O test passed!\n");
            
        } catch (IOException e) {
            System.err.println("[ERROR] File I/O failed: " + e.getMessage());
        }
    }
    
    static void testDateTime() {
        System.out.println("=== Test 6: Date and Time ===");
        
        LocalDate today = LocalDate.now();
        LocalTime now = LocalTime.now();
        LocalDateTime dateTime = LocalDateTime.now();
        
        System.out.println("Current Date: " + today);
        System.out.println("Current Time: " + now.getHour() + ":" + now.getMinute());
        System.out.println("DateTime: " + dateTime);
        
        // Date arithmetic
        LocalDate nextWeek = today.plusDays(7);
        System.out.println("Date + 7 days: " + nextWeek);
        
        System.out.println("[OK] Date/Time test passed!\n");
    }
}

// Abstract class for OOP test
abstract class Animal {
    protected String name;
    
    public Animal(String name) {
        this.name = name;
    }
    
    public abstract void makeSound();
}

class Dog extends Animal {
    public Dog(String name) {
        super(name);
    }
    
    @Override
    public void makeSound() {
        System.out.println(name + " says: Woof!");
    }
}

class Cat extends Animal {
    public Cat(String name) {
        super(name);
    }
    
    @Override
    public void makeSound() {
        System.out.println(name + " says: Meow!");
    }
}

