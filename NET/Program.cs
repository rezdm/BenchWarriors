using System;
using System.Collections.Generic;
using System.Linq;
using System.Diagnostics;

namespace ConsoleApp1;

public class Person {
    public int Id { get; set; }
    public string Name { get; set; }
    public int Age { get; set; }
    public string Department { get; set; }
    public decimal Salary { get; set; }
    public DateTime HireDate { get; set; }
}

internal static class Program {
    private static void Main(string[] args) {
#if NET9_0
        Console.WriteLine("Running on .NET 9.0");
#elif NET48
    Console.WriteLine("Running on .NET Framework 4.8");
#endif
        Console.WriteLine($"Running on: {System.Runtime.InteropServices.RuntimeInformation.FrameworkDescription}");
        Console.WriteLine($"Architecture: {System.Runtime.InteropServices.RuntimeInformation.ProcessArchitecture}");
        Console.WriteLine();

        // Generate test data
        var people = GenerateTestData(1_000_000);
            
        // Warm up JIT
        RunComplexLinqOperations(people.Take(1000).ToList());
            
        Console.WriteLine("Performance Test Results:");
        Console.WriteLine("========================");
            
        // Run performance tests
        MeasurePerformance("Complex LINQ Chain", () => RunComplexLinqOperations(people));
        MeasurePerformance("GroupBy with Aggregation", () => RunGroupByOperations(people));
        MeasurePerformance("String Operations", () => RunStringOperations(people));
        MeasurePerformance("Nested Queries", () => RunNestedQueries(people));
        MeasurePerformance("Projection with Where", () => RunProjectionOperations(people));
            
        //Console.WriteLine("\nPress any key to exit...");
        //Console.ReadKey();
    }

    private static List<Person> GenerateTestData(int count) {
        var random = new Random(42); // Fixed seed for consistent results
        var departments = new[] { "Engineering", "Sales", "Marketing", "HR", "Finance" };
        var names = new[] { "John", "Jane", "Bob", "Alice", "Charlie", "Diana", "Eve", "Frank" };
            
        return Enumerable.Range(1, count).Select(i => new Person {
                Id = i,
                Name = names[random.Next(names.Length)] + i,
                Age = random.Next(22, 65),
                Department = departments[random.Next(departments.Length)],
                Salary = random.Next(30000, 150000),
                HireDate = DateTime.Now.AddDays(-random.Next(1, 3650))
            })
            .ToList()
        ;
    }

    private static void RunComplexLinqOperations(List<Person> people) {
        var result = people
            .Where(p => p.Age > 25 && p.Salary > 50000)
            .OrderBy(p => p.Department)
            .ThenByDescending(p => p.Salary)
            .GroupBy(p => p.Department)
            .Select(g => new {
                Department = g.Key,
                Count = g.Count(),
                AverageSalary = g.Average(p => p.Salary),
                MaxSalary = g.Max(p => p.Salary),
                MinAge = g.Min(p => p.Age)
            })
            .Where(x => x.Count > 10)
            .OrderByDescending(x => x.AverageSalary)
            .ToList()
        ;
    }

    private static void RunGroupByOperations(List<Person> people) {
        var result = people
            .GroupBy(p => new { p.Department, AgeGroup = p.Age / 10 * 10 })
            .Select(g => new {
                g.Key.Department,
                AgeGroup = g.Key.AgeGroup,
                Count = g.Count(),
                TotalSalary = g.Sum(p => p.Salary),
                AverageTenure = g.Average(p => (DateTime.Now - p.HireDate).TotalDays)
            })
            .Where(x => x.Count > 5)
            .OrderBy(x => x.Department)
            .ThenBy(x => x.AgeGroup)
            .ToList()
        ;
    }

    private static void RunStringOperations(List<Person> people) {
        var result = people
            .Where(p => p.Name.Contains("a") || p.Name.Contains("e"))
            .Select(p => new {
                p.Id,
                UpperName = p.Name.ToUpper(),
                NameLength = p.Name.Length,
                FormattedSalary = p.Salary.ToString("C"),
                IsManager = p.Name.EndsWith("Manager") || p.Salary > 100000
            })
            .Where(x => x.NameLength > 5)
            .OrderBy(x => x.UpperName)
            .ToList()
        ;
    }

    private static void RunNestedQueries(List<Person> people) {
        var departments = people.Select(p => p.Department).Distinct().ToList();
            
        var result = departments.Select(dept => new {
                Department = dept,
                Employees = people.Where(p => p.Department == dept).ToList(),
                HighEarners = people.Where(p => p.Department == dept && p.Salary > 75000).Count(),
                AverageAge = people.Where(p => p.Department == dept).Average(p => p.Age)
            })
            .Where(x => x.Employees.Count > 50)
            .OrderByDescending(x => x.HighEarners)
            .ToList()
        ;
    }

    private static void RunProjectionOperations(List<Person> people) {
        var result = people
            .Where(p => p.HireDate > DateTime.Now.AddYears(-5))
            .Select(p => new {
                p.Id,
                p.Name,
                p.Age,
                SalaryBracket = GetSalaryBracket(p.Salary),
                YearsOfService = (DateTime.Now - p.HireDate).TotalDays / 365.25,
                IsYoungProfessional = p.Age < 30 && p.Salary > 60000
            })
            .Where(x => x.IsYoungProfessional)
            .OrderByDescending(x => x.YearsOfService)
            .Take(1000)
            .ToList()
        ;
    }

    private static string GetSalaryBracket(decimal salary) {
        return salary switch {
            < 40000 => "Entry Level",
            < 60000 => "Junior",
            < 80000 => "Mid Level",
            < 100000 => "Senior",
            _ => "Executive"
        };
    }

    private static void MeasurePerformance(string operationName, Action operation) {
        // Warm up
        operation();
            
        const int iterations = 5;
        var times = new List<long>();
            
        for (int i = 0; i < iterations; i++) {
            GC.Collect();
            GC.WaitForPendingFinalizers();
            GC.Collect();
                
            var sw = Stopwatch.StartNew();
            operation();
            sw.Stop();
                
            times.Add(sw.ElapsedMilliseconds);
        }
            
        var avgTime = times.Average();
        var minTime = times.Min();
        var maxTime = times.Max();
            
        Console.WriteLine($"{operationName,-25}: Avg: {avgTime:F1}ms, Min: {minTime}ms, Max: {maxTime}ms");
    }
}