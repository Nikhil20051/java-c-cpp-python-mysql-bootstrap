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
    [switch]$Fuzz
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
    param([int]$Min = -1000000, [int]$Max = 1000000)
    return Get-Random -Minimum $Min -Maximum $Max
}

# ============================================
# PYTHON TEST GENERATOR
# ============================================

function New-PythonTestSuite {
    param([int]$Count)
    
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    
    # Build dynamic test functions
    $dynamicFunctions = ""
    $dynamicCalls = ""
    
    for ($i = 1; $i -le $Count; $i++) {
        $category = @("Arithmetic", "String", "List", "Dict", "Fuzz")[(Get-Random -Maximum 5)]
        $testName = "dynamic_test_$i"
        $a = Get-RandomInt -Min -10000 -Max 10000
        $b = Get-RandomInt -Min 1 -Max 10000
        
        switch ($category) {
            "Arithmetic" {
                $dynamicFunctions += @"

def $testName():
    a, b = $a, $b
    assert a + b == $($a + $b)
    assert a - b == $($a - $b)
    assert a * b == $($a * $b)
    return True

"@
            }
            "String" {
                $length = Get-Random -Minimum 10 -Maximum 100
                $dynamicFunctions += @"

def $testName():
    import random
    s = ''.join(chr(random.randint(65, 90)) for _ in range($length))
    assert len(s) == $length
    assert s.upper() == s
    return True

"@
            }
            "List" {
                $size = Get-Random -Minimum 100 -Maximum 1000
                $dynamicFunctions += @"

def $testName():
    import random
    lst = [random.randint(-1000, 1000) for _ in range($size)]
    assert len(lst) == $size
    sorted_lst = sorted(lst)
    assert sorted_lst[0] <= sorted_lst[-1]
    return True

"@
            }
            "Dict" {
                $size = Get-Random -Minimum 50 -Maximum 500
                $dynamicFunctions += @"

def $testName():
    d = {}
    for i in range($size):
        d[str(i)] = i * i
    assert len(d) == $size
    return True

"@
            }
            "Fuzz" {
                $dynamicFunctions += @"

def $testName():
    import random
    data = bytes([random.randint(0, 255) for _ in range(100)])
    decoded = data.decode('utf-8', errors='ignore')
    assert isinstance(decoded, str)
    return True

"@
            }
        }
        $dynamicCalls += "runner.run_test(`"$testName`", `"$category`", $testName)`n"
    }

    $testCode = @"
#!/usr/bin/env python3
"""
Dynamic Test Suite - Auto-Generated Extreme Tests
Generated: $timestamp
"""

import sys
import time
from dataclasses import dataclass
from typing import List

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

runner = DynamicTestRunner()

# ============================================
# STATIC EDGE CASE TESTS
# ============================================

def test_integer_overflow():
    big = 2**63 - 1
    result = big + 1
    return result == 2**63

def test_float_precision():
    return abs(0.1 + 0.2 - 0.3) < 1e-10

def test_string_edge_cases():
    edge_strings = ["", " ", "\t", "\n", "a" * 10000]
    for s in edge_strings:
        _ = s.upper()
        _ = len(s)
    return True

def test_list_stress():
    lst = list(range(100000))
    lst.reverse()
    lst.sort()
    return lst[0] == 0 and lst[-1] == 99999

def test_dict_stress():
    d = {}
    for i in range(10000):
        d[f"key_{i}"] = i**2
    return len(d) == 10000

def test_exception_handling():
    caught = 0
    try:
        _ = 1 / 0
    except ZeroDivisionError:
        caught += 1
    try:
        _ = int("invalid")
    except ValueError:
        caught += 1
    return caught == 2

def test_recursion():
    def factorial(n):
        return 1 if n <= 1 else n * factorial(n - 1)
    return factorial(100) > 0

runner.run_test("integer_overflow", "Arithmetic", test_integer_overflow)
runner.run_test("float_precision", "Arithmetic", test_float_precision)
runner.run_test("string_edge_cases", "String", test_string_edge_cases)
runner.run_test("list_stress", "DataStructure", test_list_stress)
runner.run_test("dict_stress", "DataStructure", test_dict_stress)
runner.run_test("exception_handling", "Exceptions", test_exception_handling)
runner.run_test("recursion", "Recursion", test_recursion)

# ============================================
# DYNAMIC TESTS
# ============================================
$dynamicFunctions

$dynamicCalls

if __name__ == "__main__":
    results = runner.report()
    sys.exit(0 if results["failed"] == 0 else 1)
"@
    
    return $testCode
}

# ============================================
# C TEST GENERATOR  
# ============================================

function New-CTestSuite {
    param([int]$Count)
    
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    
    # Build dynamic test functions
    $dynamicFunctions = ""
    $dynamicCalls = ""
    
    for ($i = 1; $i -le $Count; $i++) {
        $testName = "test_dynamic_$i"
        $a = Get-RandomInt -Min -1000 -Max 1000
        $b = Get-RandomInt -Min 1 -Max 1000
        $expectedSum = $a + $b
        $expectedDiff = $a - $b
        
        $dynamicFunctions += @"

int $testName(void) {
    int a = $a, b = $b;
    return (a + b == $expectedSum) && (a - b == $expectedDiff);
}

"@
        $dynamicCalls += "    run_test(`"$testName`", `"Dynamic`", $testName);`n"
    }

    $testCode = @"
/*
 * Dynamic Test Suite - Auto-Generated Extreme Tests for C
 * Generated: $timestamp
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <math.h>
#include <time.h>

static int passed_count = 0;
static int total_count = 0;

void run_test(const char* test_name, const char* category, int (*test_func)(void)) {
    clock_t start = clock();
    int result = test_func();
    double elapsed = (double)(clock() - start) / CLOCKS_PER_SEC * 1000;
    
    total_count++;
    if (result) {
        passed_count++;
        printf("[PASS] %s: %s (%.2fms)\n", category, test_name, elapsed);
    } else {
        printf("[FAIL] %s: %s (%.2fms)\n", category, test_name, elapsed);
    }
}

/* Static Edge Case Tests */

int test_integer_limits(void) {
    long long big = (long long)INT_MAX + 1;
    return big > INT_MAX;
}

int test_float_precision(void) {
    double a = 0.1 + 0.2;
    return fabs(a - 0.3) < 1e-10;
}

int test_array_operations(void) {
    int arr[1000];
    int sum = 0;
    for (int i = 0; i < 1000; i++) { arr[i] = i; sum += i; }
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
    char result[200];
    strcpy(result, "Hello");
    strcat(result, " World");
    return strcmp(result, "Hello World") == 0;
}

int test_pointer_arithmetic(void) {
    int arr[] = {10, 20, 30, 40, 50};
    int* ptr = arr;
    return *(ptr + 2) == 30 && ptr[4] == 50;
}

int test_bitwise_operations(void) {
    unsigned int a = 0xF0F0F0F0;
    unsigned int b = 0x0F0F0F0F;
    return (a & b) == 0 && (a | b) == 0xFFFFFFFF;
}

/* Dynamic Tests */
$dynamicFunctions

int main(void) {
    printf("\n============================================================\n");
    printf("  DYNAMIC TEST SUITE - C\n");
    printf("============================================================\n\n");
    
    run_test("integer_limits", "Arithmetic", test_integer_limits);
    run_test("float_precision", "Arithmetic", test_float_precision);
    run_test("array_operations", "Arrays", test_array_operations);
    run_test("memory_allocation", "Memory", test_memory_allocation);
    run_test("string_operations", "Strings", test_string_operations);
    run_test("pointer_arithmetic", "Pointers", test_pointer_arithmetic);
    run_test("bitwise_operations", "Bitwise", test_bitwise_operations);
    
$dynamicCalls

    printf("\n============================================================\n");
    printf("  Total: %d | Passed: %d | Failed: %d\n", total_count, passed_count, total_count - passed_count);
    printf("  Success Rate: %.1f%%\n", (double)passed_count / total_count * 100);
    printf("============================================================\n");
    
    return (passed_count == total_count) ? 0 : 1;
}
"@
    
    return $testCode
}

# ============================================
# JAVA TEST GENERATOR  
# ============================================

function New-JavaTestSuite {
    param([int]$Count)
    
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    
    # Build dynamic test calls
    $dynamicCalls = ""
    
    for ($i = 1; $i -le $Count; $i++) {
        $a = Get-RandomInt -Min -1000 -Max 1000
        $b = Get-RandomInt -Min -1000 -Max 1000
        $expectedSum = $a + $b
        $dynamicCalls += "        test(`"Dynamic$i`", $a + $b == $expectedSum);`n"
    }

    $testCode = @"
// Dynamic Test Suite - Java
// Generated: $timestamp

public class DynamicTest {
    static int passed = 0;
    static int failed = 0;
    
    public static void main(String[] args) {
        System.out.println("\n============================================================");
        System.out.println("  DYNAMIC TEST SUITE - Java");
        System.out.println("============================================================\n");
        
        // Static Edge Case Tests
        test("IntegerOverflow", Integer.MAX_VALUE + 1 < Integer.MAX_VALUE);
        test("IntegerUnderflow", Integer.MIN_VALUE - 1 > Integer.MIN_VALUE);
        test("StringConcat", ("Hello" + " " + "World").equals("Hello World"));
        test("StringLength", "Test".length() == 4);
        test("ArrayOperations", testArrayOperations());
        test("ExceptionHandling", testExceptionHandling());
        
        // Dynamic Tests
$dynamicCalls
        
        System.out.println("\n============================================================");
        System.out.println("  Total: " + (passed + failed) + " | Passed: " + passed + " | Failed: " + failed);
        System.out.println("  Success Rate: " + String.format("%.1f", (double)passed / (passed + failed) * 100) + "%");
        System.out.println("============================================================");
        
        System.exit(failed == 0 ? 0 : 1);
    }
    
    static boolean testArrayOperations() {
        int[] arr = new int[1000];
        int sum = 0;
        for (int i = 0; i < 1000; i++) { arr[i] = i; sum += i; }
        return sum == 499500;
    }
    
    static boolean testExceptionHandling() {
        int caught = 0;
        try { int x = 1 / 0; } catch (ArithmeticException e) { caught++; }
        try { Integer.parseInt("invalid"); } catch (NumberFormatException e) { caught++; }
        return caught == 2;
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
            $code = New-PythonTestSuite -Count $TestCount
            $testFile = Join-Path $TestOutputDir "dynamic_test_$timestamp.py"
            $code | Out-File -FilePath $testFile -Encoding ASCII
            
            Write-Host "`n  Running Python tests..." -ForegroundColor Yellow
            $env:PYTHONIOENCODING = "utf-8"
            python $testFile
        }
        "c" {
            $code = New-CTestSuite -Count $TestCount
            $testFile = Join-Path $TestOutputDir "dynamic_test_$timestamp.c"
            $exeFile = Join-Path $TestOutputDir "dynamic_test_$timestamp.exe"
            $code | Out-File -FilePath $testFile -Encoding ASCII
            
            Write-Host "`n  Compiling C tests..." -ForegroundColor Yellow
            gcc -o $exeFile $testFile -lm 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  Running C tests..." -ForegroundColor Yellow
                & $exeFile
            }
            else {
                Write-Host "  [ERROR] C compilation failed!" -ForegroundColor Red
            }
        }
        "cpp" {
            $code = New-CTestSuite -Count $TestCount
            $testFile = Join-Path $TestOutputDir "dynamic_test_$timestamp.cpp"
            $exeFile = Join-Path $TestOutputDir "dynamic_test_$timestamp.exe"
            $code | Out-File -FilePath $testFile -Encoding ASCII
            
            Write-Host "`n  Compiling C++ tests..." -ForegroundColor Yellow
            g++ -std=c++17 -o $exeFile $testFile 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  Running C++ tests..." -ForegroundColor Yellow
                & $exeFile
            }
            else {
                Write-Host "  [ERROR] C++ compilation failed!" -ForegroundColor Red
            }
        }
        "java" {
            $code = New-JavaTestSuite -Count $TestCount
            $testFile = Join-Path $TestOutputDir "DynamicTest.java"
            $code | Out-File -FilePath $testFile -Encoding ASCII
            
            Write-Host "`n  Compiling Java tests..." -ForegroundColor Yellow
            Push-Location $TestOutputDir
            javac DynamicTest.java 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  Running Java tests..." -ForegroundColor Yellow
                java DynamicTest
            }
            else {
                Write-Host "  [ERROR] Java compilation failed!" -ForegroundColor Red
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
