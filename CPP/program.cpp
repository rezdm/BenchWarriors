#include <iostream>
#include <string>
#include <vector>
#include <random>
#include <chrono>
#include <algorithm>
#include <numeric>
#include <unordered_map>
#include <unordered_set>
#include <map>
#include <set>
#include <iomanip>
#include <memory>

using namespace std;
using namespace std::chrono;

struct Person {
    int id;
    string name;
    int age;
    string department;
    double salary;
    system_clock::time_point hireDate;
    
    // Cache frequently used computed values
    mutable int ageGroup = -1; // (age / 10) * 10, cached
    
    int getAgeGroup() const {
        if (ageGroup == -1) {
            ageGroup = (age / 10) * 10;
        }
        return ageGroup;
    }
};

using Clock = system_clock;
using Seconds = duration<double>;
using Days = duration<int, ratio<86400>>;

vector<Person> generateTestData(int count) {
    vector<Person> people;
    people.reserve(count);
    
    mt19937 rng(42);
    uniform_int_distribution<int> ageDist(22, 64);
    uniform_real_distribution<double> salaryDist(30000, 150000);
    uniform_int_distribution<int> dayDist(1, 3650);
    
    // Use string_view for better performance in lookups
    static const vector<string> names = { "John", "Jane", "Bob", "Alice", "Charlie", "Diana", "Eve", "Frank" };
    static const vector<string> departments = { "Engineering", "Sales", "Marketing", "HR", "Finance" };
    
    uniform_int_distribution<int> nameIndex(0, static_cast<int>(names.size()) - 1);
    uniform_int_distribution<int> deptIndex(0, static_cast<int>(departments.size()) - 1);
    
    auto now = Clock::now();
    
    for (int i = 1; i <= count; ++i) {
        people.emplace_back(Person{
            i,
            names[nameIndex(rng)] + to_string(i),
            ageDist(rng),
            departments[deptIndex(rng)],
            salaryDist(rng),
            now - Days(dayDist(rng)),
            -1 // ageGroup cache initialized
        });
    }
    
    return people;
}

void measure(const string& label, const vector<Person>& people, void(*op)(const vector<Person>&)) {
    op(people); // warm-up
    
    vector<long long> times;
    times.reserve(5);
    
    for (int i = 0; i < 5; ++i) {
        auto start = high_resolution_clock::now();
        op(people);
        auto end = high_resolution_clock::now();
        times.push_back(duration_cast<microseconds>(end - start).count()); // Use microseconds for better precision
    }
    
    auto avg = accumulate(times.begin(), times.end(), 0LL) / static_cast<long long>(times.size());
    auto minTime = *min_element(times.begin(), times.end());
    auto maxTime = *max_element(times.begin(), times.end());
    
    cout << setw(25) << left << label << ": "
         << "Avg: " << fixed << setprecision(2) << avg / 1000.0 << "ms, "
         << "Min: " << minTime / 1000.0 << "ms, "
         << "Max: " << maxTime / 1000.0 << "ms" << endl;
}

void runComplexOperations(const vector<Person>& people) {
    // Pre-allocate with estimated size
    vector<Person> filtered;
    filtered.reserve(people.size() / 4); // Estimate 25% pass filter
    
    // Use copy_if for filtering
    copy_if(people.begin(), people.end(), back_inserter(filtered),
        [](const Person& p) { return p.age > 25 && p.salary > 50000; });
    
    // Sort the filtered results
    sort(filtered.begin(), filtered.end(), 
        [](const Person& a, const Person& b) {
            // Avoid tuple construction for better performance
            if (a.department != b.department) return a.department < b.department;
            return a.salary > b.salary; // Descending salary
        });
    
    // Use unordered_map with reserve
    unordered_map<string, vector<Person>> grouped;
    grouped.reserve(8); // Estimate number of departments
    
    for (const auto& p : filtered) {
        grouped[p.department].push_back(p);
    }
    
    for (const auto& [dept, group] : grouped) {
        if (group.size() <= 10) continue;
        
        // Use single pass for all aggregations
        double totalSalary = 0;
        double maxSalary = 0;
        int minAge = 100;
        
        for (const auto& p : group) {
            totalSalary += p.salary;
            if (p.salary > maxSalary) maxSalary = p.salary;
            if (p.age < minAge) minAge = p.age;
        }
        
        double avgSalary = totalSalary / static_cast<double>(group.size());
        [[maybe_unused]] auto stat = make_tuple(dept, group.size(), avgSalary, maxSalary, minAge);
    }
}

void runGroupBy(const vector<Person>& people) {
    struct Key {
        string department;  // Use string instead of string_view
        int ageGroup;
        
        bool operator<(const Key& other) const {
            if (department != other.department) return department < other.department;
            return ageGroup < other.ageGroup;
        }
    };
    
    // Use map instead of unordered_map for simplicity
    map<Key, vector<const Person*>> groups;
    
    auto now = Clock::now();
    
    for (const auto& p : people) {
        Key key{ p.department, p.getAgeGroup() };
        groups[key].push_back(&p);
    }
    
    for (const auto& [key, group] : groups) {
        if (group.size() <= 5) continue;
        
        double totalSalary = 0.0;
        double totalTenure = 0.0;
        
        // Single loop for both calculations
        for (const auto* p : group) {
            totalSalary += p->salary;
            totalTenure += static_cast<double>(duration_cast<Days>(now - p->hireDate).count());
        }
        
        [[maybe_unused]] double avgTenure = totalTenure / static_cast<double>(group.size());
    }
}

void runStringOps(const vector<Person>& people) {
    vector<string> result;
    result.reserve(people.size() / 10); // Estimate result size
    
    for (const auto& p : people) {
        // Early exit optimization
        if (p.name.find('a') == string::npos && p.name.find('e') == string::npos)
            continue;
            
        if (p.name.size() <= 5) continue; // Check size before transformation
        
        string upper = p.name;
        transform(upper.begin(), upper.end(), upper.begin(), 
            [](unsigned char c) { return static_cast<char>(toupper(c)); }); // Safer cast
        
        result.push_back(move(upper));
    }
    
    sort(result.begin(), result.end());
}

void runNested(const vector<Person>& people) {
    // Use set for departments
    set<string> departments;
    
    for (const auto& p : people) {
        departments.insert(p.department);
    }
    
    for (const auto& dept : departments) {
        vector<const Person*> group;
        group.reserve(people.size() / departments.size()); // Estimate group size
        
        int highEarners = 0;
        int totalAge = 0;
        
        // Single pass through people for this department
        for (const auto& p : people) {
            if (p.department == dept) {
                group.push_back(&p);
                if (p.salary > 75000) highEarners++;
                totalAge += p.age;
            }
        }
        
        if (group.size() > 50) {
            [[maybe_unused]] double avgAge = static_cast<double>(totalAge) / static_cast<double>(group.size());
        }
    }
}

void runProjection(const vector<Person>& people) {
    auto now = Clock::now();
    auto cutoff = now - Days(static_cast<int>(365.25 * 5));
    
    vector<const Person*> result;
    result.reserve(people.size() / 20); // Estimate result size
    
    // Filter the people
    for (const auto& p : people) {
        if (p.hireDate > cutoff && p.age < 30 && p.salary > 60000) {
            result.push_back(&p);
        }
    }
    
    sort(result.begin(), result.end(), 
        [](const Person* a, const Person* b) {
            return a->hireDate < b->hireDate;
        });
    
    if (result.size() > 1000) {
        result.resize(1000);
    }
}

int main() {
    cout << "Running optimized native C++\n";
    cout << "Architecture: " << (sizeof(void*) == 8 ? "x64" : "x86") << "\n\n";
    
    auto people = generateTestData(1'000'000);
    
    // Warm-up with smaller dataset
    auto warmupData = vector<Person>(people.begin(), people.begin() + 1000);
    runComplexOperations(warmupData);
    
    cout << "Performance Test Results:\n========================\n";
    measure("Complex LINQ Chain", people, runComplexOperations);
    measure("GroupBy with Aggregation", people, runGroupBy);
    measure("String Operations", people, runStringOps);
    measure("Nested Queries", people, runNested);
    measure("Projection with Where", people, runProjection);
    
    return 0;
}
