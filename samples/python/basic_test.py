# Copyright (c) 2026 dmj.one
#
# This software is part of the dmj.one initiative.
# Created by Nikhil Bhardwaj.
#
# Licensed under the MIT License.
#!/usr/bin/env python3
"""
Python Basic Test Program
Tests Python installation without MySQL dependency
"""

import sys
import os
import json
import math
import datetime
import tempfile
from collections import Counter, defaultdict
from dataclasses import dataclass
from typing import List, Dict
import threading
import time


def print_header(title: str):
    print(f"\n{'=' * 60}")
    print(f"  {title}")
    print(f"{'=' * 60}\n")


def test_basic_operations():
    """Test 1: Basic Operations"""
    print_header("Test 1: Basic Operations")
    
    # Arithmetic
    a, b = 10, 3
    print(f"Addition: {a} + {b} = {a + b}")
    print(f"Subtraction: {a} - {b} = {a - b}")
    print(f"Multiplication: {a} * {b} = {a * b}")
    print(f"Division: {a} / {b} = {a / b:.2f}")
    print(f"Floor Division: {a} // {b} = {a // b}")
    print(f"Modulo: {a} % {b} = {a % b}")
    print(f"Power: {a} ** {b} = {a ** b}")
    
    # String operations
    hello = "Hello"
    world = "World"
    print(f"String concatenation: {hello} {world}!")
    print(f"String formatting: {hello.lower()}, {world.upper()}")
    print(f"String slicing: {'Python'[0:3]} = Pyt")
    
    print("[OK] Basic operations test passed!")


def test_data_structures():
    """Test 2: Data Structures"""
    print_header("Test 2: Data Structures")
    
    # List
    my_list = [1, 2, 3, 4, 5]
    my_list.append(6)
    print(f"List: {my_list}")
    print(f"List comprehension (squares): {[x**2 for x in my_list]}")
    
    # Dictionary
    my_dict = {"name": "Alice", "age": 30, "city": "NYC"}
    print(f"Dictionary: {my_dict}")
    print(f"Dict keys: {list(my_dict.keys())}")
    
    # Set
    my_set = {1, 2, 2, 3, 3, 3}  # Duplicates removed
    print(f"Set (no duplicates): {my_set}")
    
    # Tuple
    my_tuple = (1, "two", 3.0)
    print(f"Tuple (immutable): {my_tuple}")
    
    # Counter
    words = ["apple", "banana", "apple", "cherry", "banana", "apple"]
    word_count = Counter(words)
    print(f"Counter: {dict(word_count)}")
    
    # defaultdict
    dd = defaultdict(list)
    dd["fruits"].append("apple")
    dd["fruits"].append("banana")
    print(f"defaultdict: {dict(dd)}")
    
    print("[OK] Data structures test passed!")


def test_oop():
    """Test 3: Object-Oriented Programming"""
    print_header("Test 3: Object-Oriented Programming")
    
    # Using dataclass
    @dataclass
    class Person:
        name: str
        age: int
        
        def greet(self):
            return f"Hello, I'm {self.name}!"
    
    # Inheritance
    class Employee(Person):
        def __init__(self, name: str, age: int, role: str):
            super().__init__(name, age)
            self.role = role
        
        def work(self):
            return f"{self.name} is working as {self.role}"
    
    person = Person("Alice", 30)
    employee = Employee("Bob", 25, "Developer")
    
    print(f"Person: {person}")
    print(f"Person greet: {person.greet()}")
    print(f"Employee: {employee}")
    print(f"Employee work: {employee.work()}")
    print(f"Employee is Person: {isinstance(employee, Person)}")
    
    print("[OK] OOP test passed!")


def test_functional():
    """Test 4: Functional Programming"""
    print_header("Test 4: Functional Programming")
    
    numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    
    # map
    squared = list(map(lambda x: x**2, numbers))
    print(f"Map (squares): {squared}")
    
    # filter
    evens = list(filter(lambda x: x % 2 == 0, numbers))
    print(f"Filter (evens): {evens}")
    
    # reduce (from functools)
    from functools import reduce
    total = reduce(lambda x, y: x + y, numbers)
    print(f"Reduce (sum): {total}")
    
    # zip
    letters = ['a', 'b', 'c']
    nums = [1, 2, 3]
    zipped = list(zip(letters, nums))
    print(f"Zip: {zipped}")
    
    # enumerate
    fruits = ["apple", "banana", "cherry"]
    enumerated = [(i, f) for i, f in enumerate(fruits)]
    print(f"Enumerate: {enumerated}")
    
    print("[OK] Functional programming test passed!")


def test_file_io():
    """Test 5: File I/O"""
    print_header("Test 5: File I/O")
    
    with tempfile.NamedTemporaryFile(mode='w', suffix='.txt', delete=False) as f:
        filename = f.name
        f.write("Hello from Python!\n")
        f.write("This is a test file.\n")
        f.write("Line 3.\n")
    
    print(f"File written: {filename}")
    
    # Read file
    with open(filename, 'r') as f:
        lines = f.readlines()
    print(f"Lines read: {len(lines)}")
    
    # JSON handling
    data = {"name": "Test", "values": [1, 2, 3]}
    json_str = json.dumps(data)
    print(f"JSON serialize: {json_str}")
    
    parsed = json.loads(json_str)
    print(f"JSON parse: {parsed}")
    
    # Cleanup
    os.unlink(filename)
    print(f"File deleted: {filename}")
    
    print("[OK] File I/O test passed!")


def test_datetime():
    """Test 6: Date and Time"""
    print_header("Test 6: Date and Time")
    
    now = datetime.datetime.now()
    today = datetime.date.today()
    
    print(f"Current DateTime: {now}")
    print(f"Current Date: {today}")
    print(f"Formatted: {now.strftime('%Y-%m-%d %H:%M:%S')}")
    
    # Date arithmetic
    next_week = today + datetime.timedelta(days=7)
    print(f"Date + 7 days: {next_week}")
    
    # Timestamp
    timestamp = now.timestamp()
    print(f"Timestamp: {timestamp}")
    
    print("[OK] Date/Time test passed!")


def test_math():
    """Test 7: Math Operations"""
    print_header("Test 7: Math Operations")
    
    print(f"Pi: {math.pi}")
    print(f"E: {math.e}")
    print(f"sqrt(16): {math.sqrt(16)}")
    print(f"sin(90Â°): {math.sin(math.radians(90)):.4f}")
    print(f"log(100): {math.log10(100)}")
    print(f"factorial(5): {math.factorial(5)}")
    print(f"gcd(48, 18): {math.gcd(48, 18)}")
    
    print("[OK] Math test passed!")


def test_threading():
    """Test 8: Threading"""
    print_header("Test 8: Threading")
    
    results = []
    
    def worker(name, delay):
        time.sleep(delay)
        results.append(f"{name} completed")
    
    threads = []
    for i in range(3):
        t = threading.Thread(target=worker, args=(f"Thread-{i+1}", 0.1))
        threads.append(t)
        t.start()
    
    for t in threads:
        t.join()
    
    print(f"Thread results: {results}")
    print(f"Active threads: {threading.active_count()}")
    
    print("[OK] Threading test passed!")


def test_exception_handling():
    """Test 9: Exception Handling"""
    print_header("Test 9: Exception Handling")
    
    # Try-except
    try:
        result = 10 / 0
    except ZeroDivisionError as e:
        print(f"Caught exception: {type(e).__name__}")
    
    # Custom exception
    class CustomError(Exception):
        pass
    
    try:
        raise CustomError("This is a custom error")
    except CustomError as e:
        print(f"Custom exception: {e}")
    
    # Finally block
    try:
        x = 1
    finally:
        print("Finally block always executes")
    
    print("[OK] Exception handling test passed!")


def main():
    print("+" + "=" * 58 + "+")
    print("|           Python Basic Test Program                      |")
    print("+" + "=" * 58 + "+")
    print(f"\nPython Version: {sys.version}")
    print(f"Platform: {sys.platform}")
    
    test_basic_operations()
    test_data_structures()
    test_oop()
    test_functional()
    test_file_io()
    test_datetime()
    test_math()
    test_threading()
    test_exception_handling()
    
    print("\n+" + "=" * 58 + "+")
    print("|         All Python Basic Tests Passed!                    |")
    print("+" + "=" * 58 + "+")


if __name__ == "__main__":
    main()

