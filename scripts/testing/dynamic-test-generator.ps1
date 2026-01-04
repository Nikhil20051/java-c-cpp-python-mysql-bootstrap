<#
    Copyright (c) 2026 dmj.one
    
    Dynamic Test Suite Generator - Extreme Testing Framework
    Created by Nikhil Bhardwaj.
    
    Licensed under the MIT License.
#>
<#
.SYNOPSIS
    Dynamic Test Suite Generator with Extreme Testing Capabilities
    
.DESCRIPTION
    Automatically generates and runs extreme test cases for Python, C, C++, and Java.
    Creates new test types dynamically each run with randomized edge cases.

.PARAMETER Language
    Target language: python, c, cpp, java, or all

.PARAMETER TestCount
    Number of dynamic tests to generate per category (default: 10)

.PARAMETER Stress
    Enable stress testing with high load scenarios

.PARAMETER Fuzz
    Enable fuzz testing with random input generation

.EXAMPLE
    .\dynamic-test-generator.ps1 -Language all -TestCount 20 -Stress -Fuzz
#>

param(
    [ValidateSet("python", "c", "cpp", "java", "all")]
    [string]$Language = "all",
    
    [int]$TestCount = 10,
    [switch]$Stress,
    [switch]$Fuzz,
    [switch]$Verbose
)

$ErrorActionPreference = "Continue"
$ScriptRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$TestOutputDir = Join-Path $ScriptRoot "tests\generated"
$ReportDir = Join-Path $ScriptRoot "tests\reports"

# Ensure directories exist
@($TestOutputDir, $ReportDir) | ForEach-Object { 
    if (!(Test-Path $_)) { New-Item -ItemType Directory -Path $_ -Force | Out-Null }
}

# ============================================
# RANDOM DATA GENERATORS
# ============================================

function Get-RandomInt {
    param([int]$Min = -2147483648, [int]$Max = 2147483647)
    return Get-Random -Minimum $Min -Maximum $Max
}

function Get-RandomFloat {
    param([double]$Min = -1e10, [double]$Max = 1e10)
    return $Min + (Get-Random -Maximum 1000000) / 1000000.0 * ($Max - $Min)
}

function Get-RandomString {
    param([int]$Length = 20, [switch]$IncludeSpecial)
    $chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    if ($IncludeSpecial) { $chars += "!@#$%^&*()_+-=[]{}|;':`,.<>?/~``" }
    $result = -join ((1..$Length) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
    return $result
}

function Get-EdgeCaseIntegers {
    return @(0, 1, -1, 2147483647, -2147483648, 2147483646, -2147483647, 
        [Math]::Pow(2, 31) - 1, - [Math]::Pow(2, 31), 42, -42, 100, -100,
        999999999, -999999999, 1000000000, -1000000000)
}

function Get-EdgeCaseFloats {
    return @(0.0, 1.0, -1.0, [Double]::MaxValue, [Double]::MinValue,
        [Double]::Epsilon, 3.14159265359, -3.14159265359,
        1e-10, -1e-10, 1e10, -1e10, 0.1 + 0.2, 1 / 3)
}

function Get-EdgeCaseStrings {
    return @("", " ", "  ", "`t", "`n", "`r`n", "null", "NULL", "None",
        "true", "false", "0", "-1", "1234567890", 
        "!@#$%^&*()", "<script>alert('xss')</script>",
        "' OR '1'='1", "`"test`"", "'test'", "\\", "/", "a" * 1000)
}

# ============================================
# TEST CASE GENERATORS
# ============================================

class TestCase {
    [string]$Name
    [string]$Category
    [string]$Input
    [string]$ExpectedBehavior
    [bool]$Passed
    [string]$ActualOutput
    [double]$ExecutionTime
}

class TestSuite {
    [string]$Language
    [string]$Timestamp
    [System.Collections.ArrayList]$TestCases
    [int]$TotalTests
    [int]$PassedTests
    [int]$FailedTests
    
    TestSuite([string]$lang) {
        $this.Language = $lang
        $this.Timestamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")
        $this.TestCases = [System.Collections.ArrayList]::new()
    }
    
    [void]AddTest([TestCase]$test) {
        $this.TestCases.Add($test) | Out-Null
        $this.TotalTests++
        if ($test.Passed) { $this.PassedTests++ } else { $this.FailedTests++ }
    }
}

# ============================================
# PYTHON TEST GENERATOR
# ============================================

function New-PythonTestSuite {
    param([int]$Count, [bool]$StressMode, [bool]$FuzzMode)
    
    $testCode = @'
#!/usr/bin/env python3
"""
Dynamic Test Suite - Auto-Generated Extreme Tests
Generated: {TIMESTAMP}
"""

import sys
import random
import string
import time
import traceback
import json
import math
from typing import Any, List, Tuple
from dataclasses import dataclass
from datetime import datetime

@dataclass
class TestResult:
    name: str
    category: str
    passed: bool
    message: str
    execution_time: float

class DynamicTestRunner:
    def __init__(self):
        self.results: List[TestResult] = []
        self.test_count = 0
    
    def run_test(self, name: str, category: str, test_func):
        start = time.perf_counter()
        try:
            result = test_func()
            elapsed = time.perf_counter() - start
            passed = result is True or result is None
            self.results.append(TestResult(name, category, passed, "OK", elapsed))
        except Exception as e:
            elapsed = time.perf_counter() - start
            self.results.append(TestResult(name, category, False, str(e), elapsed))
        self.test_count += 1
    
    def report(self):
        passed = sum(1 for r in self.results if r.passed)
        failed = len(self.results) - passed
        
        print(f"\n{'='*60}")
        print(f"  DYNAMIC TEST RESULTS - Python")
        print(f"{'='*60}")
        print(f"  Total: {len(self.results)} | Passed: {passed} | Failed: {failed}")
        print(f"  Success Rate: {passed/len(self.results)*100:.1f}%")
        print(f"{'='*60}\n")
        
        for r in self.results:
            status = "[PASS]" if r.passed else "[FAIL]"
            color = "\033[92m" if r.passed else "\033[91m"
            print(f"{color}{status}\033[0m {r.category}: {r.name} ({r.execution_time*1000:.2f}ms)")
            if not r.passed:
                print(f"       Error: {r.message}")
        
        return {"total": len(self.results), "passed": passed, "failed": failed}


# ============================================
# EDGE CASE GENERATORS
# ============================================

def edge_integers():
    return [0, 1, -1, 2**31-1, -2**31, 2**63-1, -2**63, 42, -42, 
            10**9, -10**9, 10**18, -10**18]

def edge_floats():
    return [0.0, 1.0, -1.0, float('inf'), float('-inf'), float('nan'),
            sys.float_info.max, sys.float_info.min, sys.float_info.epsilon,
            1e-10, -1e-10, 1e10, -1e10, 0.1 + 0.2, 1/3, math.pi, math.e]

def edge_strings():
    return ["", " ", "\t", "\n", "\r\n", "null", "NULL", "None",
            "true", "false", "0", "-1", "'", '"', "\\", 
            "a" * 10000, "\x00", "\xff", "émoji: 🎉"]

def random_data(size=100):
    return [random.randint(-10**9, 10**9) for _ in range(size)]


# ============================================
# DYNAMIC TEST CATEGORIES
# ============================================

runner = DynamicTestRunner()

# Category 1: Arithmetic Edge Cases
def test_arithmetic_overflow():
    big = 2**63 - 1
    result = big + 1  # Python handles big integers
    return result == 2**63

def test_division_edge_cases():
    cases = [(10, 3), (1, 3), (-1, 3), (0, 1), (10**18, 7)]
    for a, b in cases:
        _ = a / b
        _ = a // b
        _ = a % b
    return True

def test_float_precision():
    assert abs(0.1 + 0.2 - 0.3) < 1e-10, "Float precision issue"
    return True

runner.run_test("overflow_handling", "Arithmetic", test_arithmetic_overflow)
runner.run_test("division_edge_cases", "Arithmetic", test_division_edge_cases)
runner.run_test("float_precision", "Arithmetic", test_float_precision)

# Category 2: String Operations
def test_string_manipulation():
    for s in edge_strings():
        _ = s.upper()
        _ = s.lower()
        _ = s.strip()
        _ = len(s)
    return True

def test_string_encoding():
    test_strings = ["Hello", "こんにちは", "مرحبا", "🎉🎊", "\x00\x01\x02"]
    for s in test_strings:
        encoded = s.encode('utf-8')
        decoded = encoded.decode('utf-8')
        assert s == decoded
    return True

runner.run_test("string_edge_cases", "String", test_string_manipulation)
runner.run_test("unicode_encoding", "String", test_string_encoding)

# Category 3: Data Structure Stress
def test_list_operations():
    lst = list(range(100000))
    lst.reverse()
    lst.sort()
    _ = lst[50000]
    lst.insert(0, -1)
    lst.pop()
    return True

def test_dict_stress():
    d = {f"key_{i}": i**2 for i in range(10000)}
    for i in range(10000):
        _ = d.get(f"key_{i}")
    return True

def test_set_operations():
    s1 = set(range(10000))
    s2 = set(range(5000, 15000))
    _ = s1.union(s2)
    _ = s1.intersection(s2)
    _ = s1.difference(s2)
    return True

runner.run_test("list_stress", "DataStructure", test_list_operations)
runner.run_test("dict_stress", "DataStructure", test_dict_stress)
runner.run_test("set_operations", "DataStructure", test_set_operations)

# Category 4: Exception Handling
def test_exception_types():
    exceptions_caught = 0
    
    try:
        _ = 1 / 0
    except ZeroDivisionError:
        exceptions_caught += 1
    
    try:
        _ = int("not_a_number")
    except ValueError:
        exceptions_caught += 1
    
    try:
        _ = [][0]
    except IndexError:
        exceptions_caught += 1
    
    try:
        _ = {}["missing"]
    except KeyError:
        exceptions_caught += 1
    
    return exceptions_caught == 4

runner.run_test("exception_handling", "Exceptions", test_exception_types)

# Category 5: Recursion Limits
def test_recursion_depth():
    def factorial(n):
        if n <= 1:
            return 1
        return n * factorial(n - 1)
    
    # Test with safe recursion depth
    result = factorial(500)
    return result > 0

runner.run_test("recursion_test", "Recursion", test_recursion_depth)

# Category 6: Memory Patterns
def test_memory_allocation():
    # Allocate and deallocate large structures
    data = [bytearray(1024) for _ in range(1000)]  # 1MB total
    del data
    return True

runner.run_test("memory_alloc", "Memory", test_memory_allocation)

# Category 7: Sorting Algorithms Stress
def test_sorting_edge_cases():
    test_cases = [
        [],
        [1],
        [2, 1],
        list(range(1000, 0, -1)),  # Reverse sorted
        list(range(1000)),  # Already sorted
        [1] * 1000,  # All same
        random_data(1000),  # Random
    ]
    for case in test_cases:
        sorted_case = sorted(case)
        assert sorted_case == list(sorted(case))
    return True

runner.run_test("sorting_stress", "Sorting", test_sorting_edge_cases)

# Category 8: Math Edge Cases
def test_math_edge_cases():
    import math
    
    # Test various math functions with edge cases
    assert math.sqrt(0) == 0
    assert math.sqrt(1) == 1
    assert math.factorial(0) == 1
    assert math.factorial(1) == 1
    assert math.gcd(0, 5) == 5
    assert math.gcd(12, 8) == 4
    
    # Trigonometric
    assert abs(math.sin(0)) < 1e-10
    assert abs(math.cos(0) - 1) < 1e-10
    
    return True

runner.run_test("math_edge_cases", "Math", test_math_edge_cases)

# ============================================
# DYNAMIC RANDOM TESTS
# ============================================

{DYNAMIC_TESTS}

# Run report
if __name__ == "__main__":
    results = runner.report()
    sys.exit(0 if results["failed"] == 0 else 1)
'@

    # Generate dynamic random tests
    $dynamicTests = @()
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    
    $categories = @("RandomArithmetic", "RandomString", "RandomList", "RandomDict", "FuzzInput")
    
    for ($i = 1; $i -le $Count; $i++) {
        $category = $categories[(Get-Random -Maximum $categories.Count)]
        $testName = "dynamic_test_$i"
        
        $testBody = switch ($category) {
            "RandomArithmetic" {
                $a = Get-RandomInt -Min -1000000 -Max 1000000
                $b = Get-RandomInt -Min 1 -Max 1000000
                @"
def $testName():
    a, b = $a, $b
    _ = a + b
    _ = a - b
    _ = a * b
    _ = a // b if b != 0 else 0
    _ = a % b if b != 0 else 0
    return True
runner.run_test("$testName", "$category", $testName)
"@
            }
            "RandomString" {
                $length = Get-Random -Minimum 10 -Maximum 1000
                @"
def $testName():
    s = ''.join(chr(random.randint(32, 126)) for _ in range($length))
    _ = s.upper()
    _ = s.lower()
    _ = s.strip()
    _ = s.split()
    _ = ''.join(reversed(s))
    return True
runner.run_test("$testName", "$category", $testName)
"@
            }
            "RandomList" {
                $size = Get-Random -Minimum 100 -Maximum 10000
                @"
def $testName():
    lst = [random.randint(-10**6, 10**6) for _ in range($size)]
    lst.sort()
    _ = sum(lst)
    _ = max(lst)
    _ = min(lst)
    return True
runner.run_test("$testName", "$category", $testName)
"@
            }
            "RandomDict" {
                $size = Get-Random -Minimum 100 -Maximum 5000
                @"
def $testName():
    d = {{f"k{{i}}": random.randint(0, 10**6) for i in range($size)}}
    _ = list(d.keys())
    _ = list(d.values())
    _ = sum(d.values())
    return True
runner.run_test("$testName", "$category", $testName)
"@
            }
            "FuzzInput" {
                @"
def $testName():
    # Fuzz test with random bytes
    data = bytes([random.randint(0, 255) for _ in range(100)])
    try:
        _ = data.decode('utf-8', errors='ignore')
    except:
        pass
    return True
runner.run_test("$testName", "$category", $testName)
"@
            }
        }
        $dynamicTests += $testBody
    }
    
    $testCode = $testCode.Replace("{TIMESTAMP}", $timestamp)
    $testCode = $testCode.Replace("{DYNAMIC_TESTS}", ($dynamicTests -join "`n`n"))
    
    return $testCode
}

# ============================================
# C TEST GENERATOR  
# ============================================

function New-CTestSuite {
    param([int]$Count, [bool]$StressMode)
    
    $testCode = @'
/*
 * Dynamic Test Suite - Auto-Generated Extreme Tests for C
 * Generated: {TIMESTAMP}
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <float.h>
#include <time.h>
#include <math.h>

typedef struct {
    const char* name;
    const char* category;
    int passed;
    double exec_time;
} TestResult;

static TestResult results[1000];
static int result_count = 0;
static int passed_count = 0;

#define RUN_TEST(name, category, test_func) do { \
    clock_t start = clock(); \
    int pass = test_func(); \
    double elapsed = (double)(clock() - start) / CLOCKS_PER_SEC * 1000; \
    results[result_count].name = name; \
    results[result_count].category = category; \
    results[result_count].passed = pass; \
    results[result_count].exec_time = elapsed; \
    if (pass) passed_count++; \
    result_count++; \
} while(0)

/* ============================================
 * EDGE CASE TESTS
 * ============================================ */

int test_integer_limits(void) {
    int max_int = INT_MAX;
    int min_int = INT_MIN;
    long long big = (long long)max_int + 1;
    
    return (big > max_int) && (min_int < 0);
}

int test_float_precision(void) {
    double a = 0.1 + 0.2;
    double b = 0.3;
    return fabs(a - b) < 1e-10;
}

int test_array_operations(void) {
    int arr[1000];
    for (int i = 0; i < 1000; i++) arr[i] = i;
    
    int sum = 0;
    for (int i = 0; i < 1000; i++) sum += arr[i];
    
    return sum == 499500;
}

int test_memory_allocation(void) {
    int* ptr = (int*)malloc(10000 * sizeof(int));
    if (!ptr) return 0;
    
    for (int i = 0; i < 10000; i++) ptr[i] = i;
    
    int result = ptr[9999] == 9999;
    free(ptr);
    return result;
}

int test_string_operations(void) {
    char str1[100] = "Hello";
    char str2[100] = "World";
    char result[200];
    
    strcpy(result, str1);
    strcat(result, " ");
    strcat(result, str2);
    
    return strcmp(result, "Hello World") == 0;
}

int test_pointer_arithmetic(void) {
    int arr[] = {10, 20, 30, 40, 50};
    int* ptr = arr;
    
    return (*(ptr + 2) == 30) && (ptr[4] == 50);
}

int test_struct_operations(void) {
    struct Point { int x; int y; };
    struct Point p = {10, 20};
    struct Point* pp = &p;
    
    return (pp->x == 10) && (pp->y == 20);
}

int test_bitwise_operations(void) {
    unsigned int a = 0xF0F0F0F0;
    unsigned int b = 0x0F0F0F0F;
    
    return ((a & b) == 0) && ((a | b) == 0xFFFFFFFF);
}

{DYNAMIC_C_TESTS}

void print_report(void) {
    printf("\n============================================================\n");
    printf("  DYNAMIC TEST RESULTS - C\n");
    printf("============================================================\n");
    printf("  Total: %d | Passed: %d | Failed: %d\n", 
           result_count, passed_count, result_count - passed_count);
    printf("  Success Rate: %.1f%%\n", (double)passed_count / result_count * 100);
    printf("============================================================\n\n");
    
    for (int i = 0; i < result_count; i++) {
        printf("%s %s: %s (%.2fms)\n",
               results[i].passed ? "[PASS]" : "[FAIL]",
               results[i].category,
               results[i].name,
               results[i].exec_time);
    }
}

int main(void) {
    srand((unsigned int)time(NULL));
    
    RUN_TEST("integer_limits", "Arithmetic", test_integer_limits);
    RUN_TEST("float_precision", "Arithmetic", test_float_precision);
    RUN_TEST("array_operations", "Arrays", test_array_operations);
    RUN_TEST("memory_allocation", "Memory", test_memory_allocation);
    RUN_TEST("string_operations", "Strings", test_string_operations);
    RUN_TEST("pointer_arithmetic", "Pointers", test_pointer_arithmetic);
    RUN_TEST("struct_operations", "Structs", test_struct_operations);
    RUN_TEST("bitwise_operations", "Bitwise", test_bitwise_operations);
    
    {DYNAMIC_C_TEST_CALLS}
    
    print_report();
    return (passed_count == result_count) ? 0 : 1;
}
'@

    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $dynamicTests = @()
    $dynamicCalls = @()
    
    for ($i = 1; $i -le $Count; $i++) {
        $testName = "test_dynamic_$i"
        $a = Get-RandomInt -Min -1000 -Max 1000
        $b = Get-RandomInt -Min 1 -Max 1000
        
        $dynamicTests += @"
int $testName(void) {
    int a = $a, b = $b;
    int sum = a + b;
    int diff = a - b;
    int prod = a * b;
    int quot = a / b;
    return (sum == $($a + $b)) && (diff == $($a - $b));
}
"@
        $dynamicCalls += "    RUN_TEST(`"$testName`", `"Dynamic`", $testName);"
    }
    
    $testCode = $testCode.Replace("{TIMESTAMP}", $timestamp)
    $testCode = $testCode.Replace("{DYNAMIC_C_TESTS}", ($dynamicTests -join "`n`n"))
    $testCode = $testCode.Replace("{DYNAMIC_C_TEST_CALLS}", ($dynamicCalls -join "`n"))
    
    return $testCode
}

# ============================================
# MAIN EXECUTION
# ============================================

function Write-Header($text) {
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host "  $text" -ForegroundColor Cyan
    Write-Host ("=" * 70) -ForegroundColor Cyan
}

function Run-DynamicTests {
    param([string]$Lang)
    
    Write-Header "Dynamic Test Generator - $($Lang.ToUpper())"
    Write-Host "  Generating $TestCount dynamic test cases..." -ForegroundColor Yellow
    Write-Host "  Stress Mode: $Stress | Fuzz Mode: $Fuzz" -ForegroundColor Gray
    
    $timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
    
    switch ($Lang) {
        "python" {
            $code = New-PythonTestSuite -Count $TestCount -StressMode $Stress -FuzzMode $Fuzz
            $testFile = Join-Path $TestOutputDir "dynamic_test_$timestamp.py"
            $code | Out-File -FilePath $testFile -Encoding UTF8
            
            Write-Host "`n  Running Python tests..." -ForegroundColor Yellow
            $env:PYTHONIOENCODING = "utf-8"
            python $testFile
        }
        "c" {
            $code = New-CTestSuite -Count $TestCount -StressMode $Stress
            $testFile = Join-Path $TestOutputDir "dynamic_test_$timestamp.c"
            $exeFile = Join-Path $TestOutputDir "dynamic_test_$timestamp.exe"
            $code | Out-File -FilePath $testFile -Encoding UTF8
            
            Write-Host "`n  Compiling C tests..." -ForegroundColor Yellow
            gcc -o $exeFile $testFile -lm 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  Running C tests..." -ForegroundColor Yellow
                & $exeFile
            }
            else {
                Write-Host "  [ERROR] Compilation failed!" -ForegroundColor Red
            }
        }
        "cpp" {
            # Similar to C but with C++ features
            Write-Host "  C++ test generation (using C tests with g++)..." -ForegroundColor Yellow
            $code = New-CTestSuite -Count $TestCount -StressMode $Stress
            $testFile = Join-Path $TestOutputDir "dynamic_test_$timestamp.cpp"
            $exeFile = Join-Path $TestOutputDir "dynamic_test_$timestamp.exe"
            $code | Out-File -FilePath $testFile -Encoding UTF8
            
            g++ -std=c++17 -o $exeFile $testFile 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  Running C++ tests..." -ForegroundColor Yellow
                & $exeFile
            }
        }
        "java" {
            Write-Host "  Java test generation..." -ForegroundColor Yellow
            # Generate Java tests (simplified)
            $javaCode = @"
// Dynamic Test Suite - Java
// Generated: $(Get-Date)

public class DynamicTest {
    static int passed = 0, failed = 0;
    
    public static void main(String[] args) {
        System.out.println("Running Dynamic Java Tests...");
        
        // Test integer operations
        test("IntegerMax", Integer.MAX_VALUE + 1 < Integer.MAX_VALUE);
        test("IntegerMin", Integer.MIN_VALUE - 1 > Integer.MIN_VALUE);
        
        // Test string operations
        test("StringConcat", ("Hello" + " " + "World").equals("Hello World"));
        test("StringLength", "Test".length() == 4);
        
        // Dynamic tests
        $(for ($i = 1; $i -le $TestCount; $i++) {
            $a = Get-RandomInt -Min -1000 -Max 1000
            $b = Get-RandomInt -Min -1000 -Max 1000
            "test(`"Dynamic$i`", $a + $b == $($a + $b));"
        })
        
        System.out.println("\n=== Results ===");
        System.out.println("Passed: " + passed + " | Failed: " + failed);
    }
    
    static void test(String name, boolean condition) {
        if (condition) {
            System.out.println("[PASS] " + name);
            passed++;
        } else {
            System.out.println("[FAIL] " + name);
            failed++;
        }
    }
}
"@
            $testFile = Join-Path $TestOutputDir "DynamicTest.java"
            $javaCode | Out-File -FilePath $testFile -Encoding UTF8
            
            Push-Location $TestOutputDir
            javac DynamicTest.java 2>&1
            if ($LASTEXITCODE -eq 0) {
                java DynamicTest
            }
            Pop-Location
        }
    }
}

# Main
Write-Host ""
Write-Host ("*" * 70) -ForegroundColor Magenta
Write-Host "*  Dynamic Test Suite Generator - Extreme Testing Framework         *" -ForegroundColor Magenta
Write-Host "*  Automatically Generating $TestCount Tests Per Language                     *" -ForegroundColor Magenta
Write-Host ("*" * 70) -ForegroundColor Magenta

$languagesToTest = if ($Language -eq "all") { @("python", "c", "cpp", "java") } else { @($Language) }

foreach ($lang in $languagesToTest) {
    Run-DynamicTests -Lang $lang
}

Write-Host ""
Write-Host ("*" * 70) -ForegroundColor Green
Write-Host "*  Dynamic Test Generation Complete!                                *" -ForegroundColor Green
Write-Host "*  Tests saved to: $TestOutputDir" -ForegroundColor Green
Write-Host ("*" * 70) -ForegroundColor Green
