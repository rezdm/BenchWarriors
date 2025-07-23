#!/usr/bin/env python3
"""
Python 3.13.3 Performance Demo
Equivalent to the C# LINQ and Java Stream performance tests
Optimized for maximum performance using modern Python features
"""

import sys
import time
import random
from datetime import datetime, timedelta
from dataclasses import dataclass
from typing import List, Dict, Tuple, Iterator
from collections import defaultdict, Counter
from functools import reduce
from itertools import groupby, takewhile, islice
import statistics
import locale
import gc
import multiprocessing

# Set locale for currency formatting
try:
    locale.setlocale(locale.LC_ALL, 'en_US.UTF-8')
except locale.Error:
    try:
        locale.setlocale(locale.LC_ALL, 'English_United States.1252')
    except locale.Error:
        pass  # Use default locale

@dataclass(slots=True, frozen=True)  # Python 3.10+ slots for memory efficiency
class Person:
    """Immutable Person dataclass with slots for memory efficiency"""
    id: int
    name: str
    age: int
    department: str
    salary: float
    hire_date: datetime

@dataclass(slots=True, frozen=True)
class DepartmentStats:
    department: str
    count: int
    average_salary: float
    max_salary: float
    min_age: int

@dataclass(slots=True, frozen=True)
class AgeGroupStats:
    department: str
    age_group: int
    count: int
    total_salary: float
    average_tenure: float

@dataclass(slots=True, frozen=True)
class PersonProjection:
    id: int
    upper_name: str
    name_length: int
    formatted_salary: str
    is_manager: bool

@dataclass(slots=True, frozen=True)
class DepartmentAnalysis:
    department: str
    employee_count: int
    high_earners: int
    average_age: float

@dataclass(slots=True, frozen=True)
class YoungProfessional:
    id: int
    name: str
    age: int
    salary_bracket: str
    years_of_service: float
    is_young_professional: bool

class PerformanceTimer:
    """High-precision timer for performance measurement"""
    
    def __init__(self):
        self.start_time = None
        self.end_time = None
    
    def start(self):
        gc.collect()  # Force garbage collection for consistent timing
        self.start_time = time.perf_counter()
    
    def stop(self):
        self.end_time = time.perf_counter()
        return (self.end_time - self.start_time) * 1000  # Convert to milliseconds

def generate_test_data(count: int) -> List[Person]:
    """Generate test data efficiently using list comprehension and random seed"""
    random.seed(42)  # Fixed seed for consistent results
    
    departments = ['Engineering', 'Sales', 'Marketing', 'HR', 'Finance']
    names = ['John', 'Jane', 'Bob', 'Alice', 'Charlie', 'Diana', 'Eve', 'Frank']
    
    # Pre-generate random values for better performance
    ages = [random.randint(22, 64) for _ in range(count)]
    salaries = [random.uniform(30000, 150000) for _ in range(count)]
    hire_days = [random.randint(1, 3650) for _ in range(count)]
    
    return [
        Person(
            id=i,
            name=f"{names[i % len(names)]}{i}",
            age=ages[i-1],
            department=departments[(i-1) % len(departments)],
            salary=salaries[i-1],
            hire_date=datetime.now() - timedelta(days=hire_days[i-1])
        )
        for i in range(1, count + 1)
    ]

def run_complex_operations(people: List[Person]) -> List[DepartmentStats]:
    """Complex operation chain equivalent to LINQ complex operations"""
    
    # Filter and group efficiently
    filtered = [p for p in people if p.age > 25 and p.salary > 50000]
    
    # Group by department using defaultdict for better performance
    groups = defaultdict(list)
    for person in filtered:
        groups[person.department].append(person)
    
    # Calculate stats and filter
    stats = []
    for dept, dept_people in groups.items():
        if len(dept_people) > 10:
            salaries = [p.salary for p in dept_people]
            ages = [p.age for p in dept_people]
            
            stats.append(DepartmentStats(
                department=dept,
                count=len(dept_people),
                average_salary=statistics.mean(salaries),
                max_salary=max(salaries),
                min_age=min(ages)
            ))
    
    # Sort by average salary descending
    return sorted(stats, key=lambda x: x.average_salary, reverse=True)

def run_groupby_operations(people: List[Person]) -> List[AgeGroupStats]:
    """GroupBy operations with aggregation"""
    
    # Create groups efficiently
    groups = defaultdict(list)
    now = datetime.now()
    
    for person in people:
        key = (person.department, (person.age // 10) * 10)
        groups[key].append(person)
    
    # Calculate group statistics
    results = []
    for (dept, age_group), group_people in groups.items():
        if len(group_people) > 5:
            total_salary = sum(p.salary for p in group_people)
            tenure_days = [(now - p.hire_date).days for p in group_people]
            
            results.append(AgeGroupStats(
                department=dept,
                age_group=age_group,
                count=len(group_people),
                total_salary=total_salary,
                average_tenure=statistics.mean(tenure_days)
            ))
    
    # Sort by department, then age group
    return sorted(results, key=lambda x: (x.department, x.age_group))

def run_string_operations(people: List[Person]) -> List[PersonProjection]:
    """String operations with filtering and projection"""
    
    # Filter people with 'a' or 'e' in name
    filtered = [p for p in people if 'a' in p.name or 'e' in p.name]
    
    # Project to new structure
    projections = []
    for person in filtered:
        try:
            formatted_salary = locale.currency(person.salary, grouping=True)
        except:
            formatted_salary = f"${person.salary:,.2f}"
            
        projection = PersonProjection(
            id=person.id,
            upper_name=person.name.upper(),
            name_length=len(person.name),
            formatted_salary=formatted_salary,
            is_manager=person.name.endswith('Manager') or person.salary > 100000
        )
        
        if projection.name_length > 5:
            projections.append(projection)
    
    # Sort by upper name
    return sorted(projections, key=lambda x: x.upper_name)

def run_nested_queries(people: List[Person]) -> List[DepartmentAnalysis]:
    """Nested queries equivalent"""
    
    # Get unique departments
    departments = list(set(p.department for p in people))
    
    results = []
    for dept in departments:
        dept_people = [p for p in people if p.department == dept]
        
        if len(dept_people) > 50:
            high_earners = sum(1 for p in dept_people if p.salary > 75000)
            average_age = statistics.mean(p.age for p in dept_people)
            
            results.append(DepartmentAnalysis(
                department=dept,
                employee_count=len(dept_people),
                high_earners=high_earners,
                average_age=average_age
            ))
    
    # Sort by high earners descending
    return sorted(results, key=lambda x: x.high_earners, reverse=True)

def run_projection_operations(people: List[Person]) -> List[YoungProfessional]:
    """Projection with filtering operations"""
    
    five_years_ago = datetime.now() - timedelta(days=5*365)
    now = datetime.now()
    
    # Filter recent hires
    recent_hires = [p for p in people if p.hire_date > five_years_ago]
    
    def get_salary_bracket(salary: float) -> str:
        if salary < 40000:
            return 'Entry Level'
        elif salary < 60000:
            return 'Junior'
        elif salary < 80000:
            return 'Mid Level'
        elif salary < 100000:
            return 'Senior'
        else:
            return 'Executive'
    
    # Project and filter young professionals
    young_pros = []
    for person in recent_hires:
        years_of_service = (now - person.hire_date).days / 365.25
        is_young_prof = person.age < 30 and person.salary > 60000
        
        if is_young_prof:
            young_pros.append(YoungProfessional(
                id=person.id,
                name=person.name,
                age=person.age,
                salary_bracket=get_salary_bracket(person.salary),
                years_of_service=years_of_service,
                is_young_professional=is_young_prof
            ))
    
    # Sort by years of service descending and take top 1000
    sorted_pros = sorted(young_pros, key=lambda x: x.years_of_service, reverse=True)
    return sorted_pros[:1000]

def measure_performance(operation_name: str, operation_func, *args) -> float:
    """Measure performance of an operation with multiple iterations"""
    
    iterations = 5
    times = []
    
    # Warm up
    operation_func(*args)
    
    for _ in range(iterations):
        timer = PerformanceTimer()
        timer.start()
        result = operation_func(*args)
        duration = timer.stop()
        times.append(duration)
    
    avg_time = statistics.mean(times)
    min_time = min(times)
    max_time = max(times)
    
    print(f"{operation_name:<25}: Avg: {avg_time:.1f}ms, Min: {min_time:.0f}ms, Max: {max_time:.0f}ms")
    return avg_time

def main():
    """Main performance testing function"""
    
    print(f"Running on: Python {sys.version}")
    print(f"CPU Count: {multiprocessing.cpu_count()}")
    print()
    
    # Generate test data
    print("Generating test data...")
    people = generate_test_data(1_000_000)
    
    # Warm up JIT/interpreter
    print("Warming up...")
    run_complex_operations(people[:1000])
    
    print("\nPerformance Test Results:")
    print("========================")
    
    # Run performance tests
    measure_performance("Complex Operations", run_complex_operations, people)
    measure_performance("GroupBy with Aggregation", run_groupby_operations, people)
    measure_performance("String Operations", run_string_operations, people)
    measure_performance("Nested Queries", run_nested_queries, people)
    measure_performance("Projection with Filter", run_projection_operations, people)

if __name__ == "__main__":
    main()
