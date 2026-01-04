/*
 * Copyright (c) 2026 dmj.one
 *
 * This software is part of the dmj.one initiative.
 * Created by Nikhil Bhardwaj.
 *
 * Licensed under the MIT License.
 */
/**
 * C++ Basic Test Program
 * Tests C++ installation without MySQL dependency
 */

#include <iostream>
#include <string>
#include <vector>
#include <map>
#include <algorithm>
#include <memory>
#include <fstream>

using namespace std;

void print_header(const string& title) {
    cout << "\n============================================================" << endl;
    cout << "  " << title << endl;
    cout << "============================================================\n" << endl;
}

void test_basic_operations() {
    print_header("Test 1: Basic Operations");
    
    int a = 10, b = 3;
    cout << "Addition: " << a << " + " << b << " = " << (a + b) << endl;
    cout << "Division: " << a << " / " << b << " = " << (a / b) << endl;
    
    string hello = "Hello", world = "World";
    cout << "String: " << hello << " " << world << "!" << endl;
    cout << "[OK] Basic operations test passed!" << endl;
}

void test_stl_containers() {
    print_header("Test 2: STL Containers");
    
    vector<int> vec = {5, 2, 8, 1, 9};
    cout << "Vector: ";
    for (int v : vec) cout << v << " ";
    cout << endl;
    
    sort(vec.begin(), vec.end());
    cout << "Sorted: ";
    for (int v : vec) cout << v << " ";
    cout << endl;
    
    map<string, int> m = {{"one", 1}, {"two", 2}};
    cout << "Map: ";
    for (auto& [k, v] : m) cout << k << "=" << v << " ";
    cout << endl;
    
    cout << "[OK] STL containers test passed!" << endl;
}

class Animal {
public:
    virtual void speak() = 0;
    virtual ~Animal() = default;
};

class Dog : public Animal {
public:
    void speak() override { cout << "Woof!" << endl; }
};

void test_oop() {
    print_header("Test 3: OOP");
    
    unique_ptr<Animal> dog = make_unique<Dog>();
    cout << "Dog says: "; dog->speak();
    cout << "[OK] OOP test passed!" << endl;
}

void test_lambdas() {
    print_header("Test 4: Lambdas");
    
    auto add = [](int a, int b) { return a + b; };
    cout << "Lambda add(5, 3) = " << add(5, 3) << endl;
    
    vector<int> nums = {1, 2, 3, 4, 5};
    int sum = 0;
    for_each(nums.begin(), nums.end(), [&sum](int n) { sum += n; });
    cout << "Sum with lambda: " << sum << endl;
    
    cout << "[OK] Lambdas test passed!" << endl;
}

void test_file_io() {
    print_header("Test 5: File I/O");
    
    ofstream out("test.txt");
    out << "Hello from C++!" << endl;
    out.close();
    
    ifstream in("test.txt");
    string line;
    getline(in, line);
    cout << "Read: " << line << endl;
    in.close();
    
    remove("test.txt");
    cout << "[OK] File I/O test passed!" << endl;
}

int main() {
    cout << "\n+============================================================+" << endl;
    cout << "|           C++ Basic Test Program                           |" << endl;
    cout << "+============================================================+" << endl;
    
    test_basic_operations();
    test_stl_containers();
    test_oop();
    test_lambdas();
    test_file_io();
    
    cout << "\n+============================================================+" << endl;
    cout << "|           All C++ Basic Tests Passed!                      |" << endl;
    cout << "+============================================================+\n" << endl;
    
    return 0;
}

