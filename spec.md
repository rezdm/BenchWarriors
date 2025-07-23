# Cross-Language Performance Benchmark

A comprehensive performance testing suite for comparing data processing capabilities across different programming languages and platforms.

## Table of Contents

- [Overview](#overview)
- [Test Environment](#test-environment)
- [Data Models](#data-models)
- [Test Suite](#test-suite)
- [Implementation Guide](#implementation-guide)
- [Performance Measurement](#performance-measurement)


## Overview

This benchmark suite tests common enterprise data processing operations across multiple programming languages to provide meaningful performance comparisons. The tests simulate real-world business scenarios involving filtering, grouping, aggregation, and data transformation operations.

### Supported Languages

- **C# (.NET Core 9.0)**
- **Java (17+)**
- **C++ (17+)**
- **SQL (T-SQL)**
- **Python (3.13+)**
- **Go** (not yet)
- **Rust** (not yet)
- **JavaScript (Node.js)** (not yet)
- **Additional languages can be added following the specification**

## Test Environment
The project started as comparing in a specific environment, in Windows

## Data Models

### Core Entity: Person

```csharp
Person {
    int      Id 
    string   Name 
    int      Age 
    string   Department 
    decimal  Salary 
    DateTime HireDate 
}
```

### Result Models

```csharp
// Test 1 Result
DepartmentStats {
    string  Department 
    int     Count
    decimal AverageSalary
    decimal MaxSalary
    int     MinAge
}

// Test 2 Result  
AgeGroupStats {
    string  Department
    int     AgeGroup
    int     Count
    decimal TotalSalary
    double  AverageTenure
}

// Test 3 Result
PersonProjection {
    int    Id
    string UpperName
    int    NameLength
    string FormattedSalary
    bool   IsManager
}

// Test 4 Result
DepartmentAnalysis {
    string Department
    int    EmployeeCount
    int    HighEarners
    double AverageAge
}

// Test 5 Result
YoungProfessional {
    int    Id
    string Name
    int    Age
    string SalaryBracket
    double YearsOfService
    bool   IsYoungProfessional
}
```

## Test Suite

### Test Configuration

```
Dataset Size: 1,000,000 records
Random Seed: 42 (for reproducible results)
Iterations: 5 per test (excluding warm-up)
Timing: Microsecond precision
Memory: Force garbage collection between iterations
```

### Test 1: Complex Query Chain

**Purpose**: Multi-step filtering, grouping, and aggregation

**Algorithm**:
1. Filter people (age > 25 AND salary > 50,000)
2. Group by department
3. Calculate statistics (count, average/max salary, min age)
4. Filter groups with count > 10
5. Sort by average salary descending

**Expected Complexity**: O(n log n)

### Test 2: GroupBy with Aggregation

**Purpose**: Advanced grouping with composite keys and date calculations

**Algorithm**:
1. Group by department and age decade ((age/10)*10)
2. Calculate group statistics (count, total salary, average tenure)
3. Filter groups with count > 5
4. Sort by department, then age group

**Expected Complexity**: O(n log n)

### Test 3: String Operations

**Purpose**: String manipulation, formatting, and projection

**Algorithm**:
1. Filter people with 'a' or 'e' in name
2. Project to new structure with string transformations
3. Filter by name length > 5
4. Sort by uppercase name

**Expected Complexity**: O(n log n)

### Test 4: Nested Queries

**Purpose**: Complex querying patterns and multiple data passes

**Algorithm**:
1. Get unique departments
2. For each department, analyze employees
3. Filter departments with > 50 employees
4. Calculate high earners and average age
5. Sort by high earners count descending

**Expected Complexity**: O(n * d) where d = departments

### Test 5: Projection with Business Logic

**Purpose**: Date calculations, conditional logic, and top-N processing

**Algorithm**:
1. Filter recent hires (last 5 years)
2. Apply business logic (salary brackets, service years)
3. Filter young professionals (age < 30, salary > 60,000)
4. Sort by years of service descending
5. Take top 1,000 results

**Expected Complexity**: O(n log n)

## Implementation Guide

### Data Generation

```pseudocode
GenerateTestData(count: int) -> List<Person> {
    random = new Random(42)  // Fixed seed for consistency
    departments = ["Engineering", "Sales", "Marketing", "HR", "Finance"]
    namePrefix = ["John", "Jane", "Bob", "Alice", "Charlie", "Diana", "Eve", "Frank"]
    
    FOR i = 1 TO count:
        person = new Person {
            Id = i,
            Name = namePrefix[(i-1) % 8] + i.ToString(),
            Age = random.Next(22, 65),
            Department = departments[(i-1) % 5],
            Salary = random.Next(30000, 150001),
            HireDate = DateTime.Now.AddDays(-random.Next(1, 3651))
        }
        people.Add(person)
    
    RETURN people
}
```

### Performance Measurement

```pseudocode
MeasurePerformance(operationName: string, operation: Function) {
    times = []
    
    // Warm-up iteration (excluded from results)
    operation()
    
    FOR i = 1 TO 5:
        ClearSystemCaches()
        
        startTime = GetHighPrecisionTime()
        result = operation()
        endTime = GetHighPrecisionTime()
        
        times.Add(endTime - startTime)
    
    avgTime = Average(times)
    minTime = Min(times)
    maxTime = Max(times)
    
    Print($"{operationName,-25}: Avg: {avgTime:F1}ms, Min: {minTime}ms, Max: {maxTime}ms")
}
```

### Output Format

```
Performance Test Results:
========================
Runtime: [Language Version and Implementation]
CPU Count: [Number of logical processors]
Dataset Size: 1,000,000 records

Complex Query Chain        : Avg: 245.3ms, Min: 234ms, Max: 267ms
GroupBy with Aggregation   : Avg: 156.7ms, Min: 149ms, Max: 171ms
String Operations          : Avg: 445.2ms, Min: 421ms, Max: 467ms
Nested Queries            : Avg: 189.1ms, Min: 178ms, Max: 203ms
Projection with Filter    : Avg: 134.8ms, Min: 127ms, Max: 145ms

Test completed successfully!
```
