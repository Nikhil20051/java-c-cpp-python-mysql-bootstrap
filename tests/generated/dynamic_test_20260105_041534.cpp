/*
 * Dynamic Test Suite - Auto-Generated Extreme Tests for C
 * Generated: 2026-01-05 04:15:34
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

int test_dynamic_1(void) {
    int a = -311, b = 372;
    int sum = a + b;
    int diff = a - b;
    int prod = a * b;
    int quot = a / b;
    return (sum == 61) && (diff == -683);
}

int test_dynamic_2(void) {
    int a = 789, b = 150;
    int sum = a + b;
    int diff = a - b;
    int prod = a * b;
    int quot = a / b;
    return (sum == 939) && (diff == 639);
}

int test_dynamic_3(void) {
    int a = 795, b = 275;
    int sum = a + b;
    int diff = a - b;
    int prod = a * b;
    int quot = a / b;
    return (sum == 1070) && (diff == 520);
}

int test_dynamic_4(void) {
    int a = -747, b = 901;
    int sum = a + b;
    int diff = a - b;
    int prod = a * b;
    int quot = a / b;
    return (sum == 154) && (diff == -1648);
}

int test_dynamic_5(void) {
    int a = -492, b = 230;
    int sum = a + b;
    int diff = a - b;
    int prod = a * b;
    int quot = a / b;
    return (sum == -262) && (diff == -722);
}

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
    
        RUN_TEST("test_dynamic_1", "Dynamic", test_dynamic_1);
    RUN_TEST("test_dynamic_2", "Dynamic", test_dynamic_2);
    RUN_TEST("test_dynamic_3", "Dynamic", test_dynamic_3);
    RUN_TEST("test_dynamic_4", "Dynamic", test_dynamic_4);
    RUN_TEST("test_dynamic_5", "Dynamic", test_dynamic_5);
    
    print_report();
    return (passed_count == result_count) ? 0 : 1;
}
