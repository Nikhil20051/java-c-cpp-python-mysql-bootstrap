/**
 * C Basic Test Program
 * Tests C installation without MySQL dependency
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <time.h>

void print_header(const char* title) {
    printf("\n============================================================\n");
    printf("  %s\n", title);
    printf("============================================================\n\n");
}

void test_basic_operations(void) {
    print_header("Test 1: Basic Operations");
    
    int a = 10, b = 3;
    printf("Addition: %d + %d = %d\n", a, b, a + b);
    printf("Subtraction: %d - %d = %d\n", a, b, a - b);
    printf("Multiplication: %d * %d = %d\n", a, b, a * b);
    printf("Division: %d / %d = %d\n", a, b, a / b);
    printf("Modulo: %d %% %d = %d\n", a, b, a % b);
    printf("[OK] Basic operations test passed!\n");
}

void test_arrays(void) {
    print_header("Test 2: Arrays");
    
    int arr[] = {5, 2, 8, 1, 9};
    int n = 5;
    
    printf("Array: ");
    for (int i = 0; i < n; i++) printf("%d ", arr[i]);
    printf("\n[OK] Arrays test passed!\n");
}

void test_pointers(void) {
    print_header("Test 3: Pointers");
    
    int value = 42;
    int *ptr = &value;
    
    printf("Value: %d, Address: %p\n", value, (void*)&value);
    printf("Pointer value: %d\n", *ptr);
    printf("[OK] Pointers test passed!\n");
}

typedef struct {
    char name[50];
    int age;
} Person;

void test_structs(void) {
    print_header("Test 4: Structs");
    
    Person p = {"John Doe", 30};
    printf("Person: %s, Age: %d\n", p.name, p.age);
    printf("[OK] Structs test passed!\n");
}

void test_file_io(void) {
    print_header("Test 5: File I/O");
    
    FILE* fp = fopen("test.txt", "w");
    fprintf(fp, "Hello from C!\n");
    fclose(fp);
    
    fp = fopen("test.txt", "r");
    char line[100];
    fgets(line, 100, fp);
    printf("Read: %s", line);
    fclose(fp);
    
    remove("test.txt");
    printf("[OK] File I/O test passed!\n");
}

void test_memory(void) {
    print_header("Test 6: Dynamic Memory");
    
    int* arr = (int*)malloc(5 * sizeof(int));
    for (int i = 0; i < 5; i++) arr[i] = i * 10;
    
    printf("Dynamic array: ");
    for (int i = 0; i < 5; i++) printf("%d ", arr[i]);
    printf("\n");
    
    free(arr);
    printf("[OK] Dynamic memory test passed!\n");
}

int main(void) {
    printf("\n+============================================================+\n");
    printf("|           C Basic Test Program                             |\n");
    printf("+============================================================+\n");
    
    test_basic_operations();
    test_arrays();
    test_pointers();
    test_structs();
    test_file_io();
    test_memory();
    
    printf("\n+============================================================+\n");
    printf("|           All C Basic Tests Passed!                        |\n");
    printf("+============================================================+\n\n");
    
    return 0;
}
