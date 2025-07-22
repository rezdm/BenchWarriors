import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.concurrent.ThreadLocalRandom;
import java.util.function.Supplier;
import java.util.stream.Collectors;
import java.util.stream.IntStream;
import java.text.NumberFormat;
import java.util.Locale;

public class Program {
    
    // Using Java 17+ record for immutable data class
    public record Person(
        int id,
        String name,
        int age,
        String department,
        double salary,
        LocalDateTime hireDate
    ) {}
    
    // Java 17+ record for result types
    public record DepartmentStats(
        String department,
        int count,
        double averageSalary,
        double maxSalary,
        int minAge
    ) {}
    
    public record AgeGroupStats(
        String department,
        int ageGroup,
        int count,
        double totalSalary,
        double averageTenure
    ) {}
    
    public record PersonProjection(
        int id,
        String upperName,
        int nameLength,
        String formattedSalary,
        boolean isManager
    ) {}
    
    public record DepartmentAnalysis(
        String department,
        List<Person> employees,
        int highEarners,
        double averageAge
    ) {}
    
    public record YoungProfessional(
        int id,
        String name,
        int age,
        String salaryBracket,
        double yearsOfService,
        boolean isYoungProfessional
    ) {}
    
    public static void main(String[] args) {
        System.out.printf("Running on: Java %s%n", System.getProperty("java.version"));
        System.out.printf("JVM: %s %s%n", 
            System.getProperty("java.vm.name"), 
            System.getProperty("java.vm.version"));
        System.out.printf("Available processors: %d%n", Runtime.getRuntime().availableProcessors());
        System.out.println();
        
        // Generate test data
        var people = generateTestData(1_000_000);
        
        // Warm up JIT
        runComplexStreamOperations(people.stream().limit(1000).toList());
        
        System.out.println("Performance Test Results:");
        System.out.println("========================");
        
        // Run performance tests
        measurePerformance("Complex Stream Chain", () -> runComplexStreamOperations(people));
        measurePerformance("GroupBy with Aggregation", () -> runGroupByOperations(people));
        measurePerformance("String Operations", () -> runStringOperations(people));
        measurePerformance("Nested Queries", () -> runNestedQueries(people));
        measurePerformance("Projection with Filter", () -> runProjectionOperations(people));
        
        System.out.println("\nPress Enter to exit...");
        try {
            System.in.read();
        } catch (Exception e) {
            // Ignore
        }
    }
    
    // Using modern Java features for efficient data generation
    private static List<Person> generateTestData(int count) {
        var random = ThreadLocalRandom.current();
        var departments = List.of("Engineering", "Sales", "Marketing", "HR", "Finance");
        var names = List.of("John", "Jane", "Bob", "Alice", "Charlie", "Diana", "Eve", "Frank");
        
        return IntStream.range(1, count + 1)
            .parallel() // Parallel generation for better performance
            .mapToObj(i -> new Person(
                i,
                names.get(random.nextInt(names.size())) + i,
                random.nextInt(22, 65),
                departments.get(random.nextInt(departments.size())),
                random.nextDouble(30_000, 150_000),
                LocalDateTime.now().minusDays(random.nextInt(1, 3650))
            ))
            .toList(); // Java 16+ toList() - more efficient than collect(Collectors.toList())
    }
    
    private static List<DepartmentStats> runComplexStreamOperations(List<Person> people) {
        return people.stream()
            .filter(p -> p.age() > 25 && p.salary() > 50_000)
            .sorted(Comparator.comparing(Person::department)
                .thenComparing(Person::salary, Comparator.reverseOrder()))
            .collect(Collectors.groupingBy(Person::department))
            .entrySet().stream()
            .map(entry -> new DepartmentStats(
                entry.getKey(),
                entry.getValue().size(),
                entry.getValue().stream().mapToDouble(Person::salary).average().orElse(0.0),
                entry.getValue().stream().mapToDouble(Person::salary).max().orElse(0.0),
                entry.getValue().stream().mapToInt(Person::age).min().orElse(0)
            ))
            .filter(stats -> stats.count() > 10)
            .sorted(Comparator.comparingDouble(DepartmentStats::averageSalary).reversed())
            .toList();
    }
    
    private static List<AgeGroupStats> runGroupByOperations(List<Person> people) {
        return people.stream()
            .collect(Collectors.groupingBy(p -> 
                Map.entry(p.department(), p.age() / 10 * 10)))
            .entrySet().stream()
            .map(entry -> {
                var employees = entry.getValue();
                var key = entry.getKey();
                return new AgeGroupStats(
                    key.getKey(),
                    key.getValue(),
                    employees.size(),
                    employees.stream().mapToDouble(Person::salary).sum(),
                    employees.stream()
                        .mapToLong(p -> ChronoUnit.DAYS.between(p.hireDate(), LocalDateTime.now()))
                        .average().orElse(0.0)
                );
            })
            .filter(stats -> stats.count() > 5)
            .sorted(Comparator.comparing(AgeGroupStats::department)
                .thenComparingInt(AgeGroupStats::ageGroup))
            .toList();
    }
    
    private static List<PersonProjection> runStringOperations(List<Person> people) {
        var formatter = NumberFormat.getCurrencyInstance(Locale.US);
        
        return people.stream()
            .filter(p -> p.name().contains("a") || p.name().contains("e"))
            .map(p -> new PersonProjection(
                p.id(),
                p.name().toUpperCase(),
                p.name().length(),
                formatter.format(p.salary()),
                p.name().endsWith("Manager") || p.salary() > 100_000
            ))
            .filter(proj -> proj.nameLength() > 5)
            .sorted(Comparator.comparing(PersonProjection::upperName))
            .toList();
    }
    
    private static List<DepartmentAnalysis> runNestedQueries(List<Person> people) {
        var grouped = people.stream().collect(Collectors.groupingBy(Person::department));
    
        return grouped.entrySet().stream()
            .map(entry -> {
                var dept = entry.getKey();
                var deptEmployees = entry.getValue();
                var highEarners = (int) deptEmployees.stream()
                    .filter(p -> p.salary() > 75_000).count();
                var averageAge = deptEmployees.stream()
                    .mapToInt(Person::age).average().orElse(0.0);
    
                return new DepartmentAnalysis(dept, deptEmployees, highEarners, averageAge);
            })
            .filter(analysis -> analysis.employees().size() > 50)
            .sorted(Comparator.comparingInt(DepartmentAnalysis::highEarners).reversed())
            .toList();
    }

    private static Object runProjectionOperations(List<Person> people) {
        var fiveYearsAgo = LocalDateTime.now().minusYears(5);
        
        var result = people.stream()
            .filter(p -> p.hireDate().isAfter(fiveYearsAgo))
            .map(p -> {
                var yearsOfService = ChronoUnit.DAYS.between(p.hireDate(), LocalDateTime.now()) / 365.25;
                return new YoungProfessional(
                    p.id(),
                    p.name(),
                    p.age(),
                    getSalaryBracket(p.salary()),
                    yearsOfService,
                    p.age() < 30 && p.salary() > 60_000
                );
            })
            .filter(YoungProfessional::isYoungProfessional)
            .sorted(Comparator.comparingDouble(YoungProfessional::yearsOfService).reversed())
            .limit(1000)
            .toList();
        return null;
    }
    
    // Java 17+ pattern matching in switch expressions
    private static String getSalaryBracket(double salary) {
        return switch ((int) (salary / 20_000)) {
            case 0, 1 -> "Entry Level";
            case 2 -> "Junior";
            case 3 -> "Mid Level";
            case 4 -> "Senior";
            default -> "Executive";
        };
    }
    
    private static void measurePerformance(String operationName, Supplier<Object> operation) {
        // Warm up
        operation.get();
        
        final int iterations = 5;
        var times = new ArrayList<Long>();
        
        for (int i = 0; i < iterations; i++) {
            // Force garbage collection
            System.gc();
            try {
                Thread.sleep(100); // Give GC time to complete
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
            
            var startTime = System.nanoTime();
            operation.get();
            var endTime = System.nanoTime();
            
            times.add((endTime - startTime) / 1_000_000); // Convert to milliseconds
        }
        
        var avgTime = times.stream().mapToLong(Long::longValue).average().orElse(0.0);
        var minTime = times.stream().mapToLong(Long::longValue).min().orElse(0L);
        var maxTime = times.stream().mapToLong(Long::longValue).max().orElse(0L);
        
        System.out.printf("%-25s: Avg: %.1fms, Min: %dms, Max: %dms%n", 
            operationName, avgTime, minTime, maxTime);
    }
}