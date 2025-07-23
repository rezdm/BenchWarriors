drop procedure if exists sp_run_performance_tests;
drop table if exists people;
go

print 'Current server configuration:';
select 
     name
   , value
   , value_in_use
   , description
from sys.configurations 
where name in ('max degree of parallelism', 'cost threshold for parallelism')
order by name;
print '';

-- recommended settings for this workload
print 'Recommended settings for performance testing:';
print '============================================';

declare @cpu_count int = (select cpu_count from sys.dm_os_sys_info);
declare @recommended_maxdop int;
declare @recommended_threshold int = 50; -- higher threshold for analytical workloads

-- calculate optimal maxdop based on microsoft best practices
set @recommended_maxdop = case 
    when @cpu_count <= 8 then @cpu_count
    when @cpu_count <= 16 then 8
    else 8 -- cap at 8 for very high cpu count systems
end;

print 'CPU count: ' + cast(@cpu_count as varchar(10));
print 'Recommended maxdop: ' + cast(@recommended_maxdop as varchar(10));
print 'Recommended cost threshold: ' + cast(@recommended_threshold as varchar(10));
print '';

exec sp_configure 'max degree of parallelism', @recommended_maxdop;
exec sp_configure 'cost threshold for parallelism', @recommended_threshold;
reconfigure;

create table people (
     id int identity(1,1) primary key clustered
   , name nvarchar(100) not null
   , age int not null
   , department nvarchar(50) not null
   , salary decimal(10,2) not null
   , hire_date datetime2 not null
    
    -- add indexes for performance
   , index ix_people_age_salary nonclustered (age, salary)
   , index ix_people_department nonclustered (department)
   , index ix_people_hire_date nonclustered (hire_date)
   , index ix_people_name nonclustered (name)
);
go

with number_sequences as (
    select 1 as n
    union all
    select n + 1 
    from number_sequences 
    where n < 1000000
)
, departments_data as (
    select 
         row_number() over (order by (select null)) as rn
       , dept
    from (values 
        ('Engineering')
      , ('Sales')
      , ('Marketing')
      , ('HR')
      , ('Finance')
    ) as departments(dept)
)
, names_data as (
    select 
         row_number() over (order by (select null)) as rn
       , name_part
    from (values 
        ('John')
      , ('Jane')
      , ('Bob')
      , ('Alice')
      , ('Charlie')
      , ('Diana')
      , ('Eve')
      , ('Frank')
    ) as names(name_part)
)
insert into people (name, age, department, salary, hire_date)
select 
     nd.name_part + cast(ns.n as nvarchar(10)) as name
   , 22 + (abs(checksum(newid())) % 43) as age
   , dd.dept as department
   , 30000 + (abs(checksum(newid())) % 120000) as salary
   , dateadd(day, -(abs(checksum(newid())) % 3650), getdate()) as hire_date
from number_sequences ns
cross join departments_data dd
cross join names_data nd
where ns.n <= 1000000
    and dd.rn = ((ns.n - 1) % 5) + 1
    and nd.rn = ((ns.n - 1) % 8) + 1
option (maxrecursion 0);
go

update statistics people;
go

create procedure sp_run_performance_tests @use_parallel_hints bit = 1 as begin
    set nocount on;
    
    declare @start_time datetime2(7);
    declare @end_time datetime2(7);
    declare @duration bigint;
    declare @iteration_count int = 5;
    declare @current_iteration int;
    declare @total_duration bigint;
    declare @min_duration bigint;
    declare @max_duration bigint;
    declare @avg_duration bigint;
    declare @maxdop_hint nvarchar(20) = '';
    
    declare @cpu_count int = (select cpu_count from sys.dm_os_sys_info);
    declare @optimal_maxdop int = case 
        when @cpu_count <= 8 then @cpu_count
        when @cpu_count <= 16 then 8
        else 8
    end;
    
    if @use_parallel_hints = 1
        set @maxdop_hint = 'option (maxdop ' + cast(@optimal_maxdop as varchar(2)) + ')';
    
    create table #timing_results (
         test_name nvarchar(100)
       , iteration int
       , duration_ms bigint
    );
    
    print 'SQL performance test results:';
    print '====================================';
    print 'SQL server version: ' + @@version;
    print 'Database: ' + db_name();
    print 'CPU count: ' + cast(@cpu_count as varchar(10));
    print 'Using maxdop hint: ' + case when @use_parallel_hints = 1 then cast(@optimal_maxdop as varchar(10)) else 'no' end;
    print '';
    
    -- test 1: complex query chain (equivalent to complex linq chain)
    set @current_iteration = 1;
    while @current_iteration <= @iteration_count begin
        dbcc dropcleanbuffers;
        dbcc freeproccache;
        
        set @start_time = sysdatetime();
        
        declare @json_result1 nvarchar(max);
        with filtered_people as (
            select department, age, salary
            from people 
            where age > 25 and salary > 50000
        )
        , department_stats as (
            select 
                 department
               , count(*) as count
               , avg(salary) as average_salary
               , max(salary) as max_salary
               , min(age) as min_age
            from filtered_people
            group by department
            having count(*) > 10
        )
        select @json_result1 = (
            select 
                 department
               , count
               , average_salary
               , max_salary
               , min_age
            from department_stats
            order by average_salary desc
            for json path
        )
        option (maxdop 8, recompile);
        
        select len(@json_result1) as json_length, 'TEST_RESULT_JSON' as marker;
        
        set @end_time = sysdatetime();
        set @duration = datediff(microsecond, @start_time, @end_time) / 1000;
        
        insert into #timing_results values ('Complex query chain', @current_iteration, @duration);
        set @current_iteration = @current_iteration + 1;
    end;
    
    -- test 2: groupby with aggregation (equivalent to groupby operations)
    set @current_iteration = 1;
    while @current_iteration <= @iteration_count
    begin
        dbcc dropcleanbuffers;
        dbcc freeproccache;
        
        set @start_time = sysdatetime();
        
        declare @json_result2 nvarchar(max);
        with age_groups_data as (
            select 
                 department
               , (age / 10) * 10 as age_group
               , salary
               , datediff(day, hire_date, getdate()) as tenure_days
            from people
        )
        , grouped_stats as (
            select 
                 department
               , age_group
               , count(*) as count
               , sum(salary) as total_salary
               , avg(cast(tenure_days as float)) as average_tenure
            from age_groups_data
            group by department, age_group
            having count(*) > 5
        )
        select @json_result2 = (
            select 
                 department
               , age_group
               , count
               , total_salary
               , average_tenure
            from grouped_stats
            order by department, age_group
            for json path
        )
        option (maxdop 8, recompile);
        
        select len(@json_result2) as json_length, 'TEST_RESULT_JSON' as marker;
        
        set @end_time = sysdatetime();
        set @duration = datediff(microsecond, @start_time, @end_time) / 1000;
        
        insert into #timing_results values ('GroupBy with aggregation', @current_iteration, @duration);
        set @current_iteration = @current_iteration + 1;
    end;
    
    -- test 3: string operations
    set @current_iteration = 1;
    while @current_iteration <= @iteration_count
    begin
        dbcc dropcleanbuffers;
        dbcc freeproccache;
        
        set @start_time = sysdatetime();
        
        declare @json_result3 nvarchar(max);
        with strings_processed as (
            select 
                 id
               , upper(name) as upper_name
               , len(name) as name_length
               , format(salary, 'c', 'en-us') as formatted_salary
               , case 
                    when name like '%manager' or salary > 100000 then 1 
                    else 0 
                 end as is_manager
            from people
            where name like '%a%' or name like '%e%'
        )
        select @json_result3 = (
            select 
                 id
               , upper_name
               , name_length
               , formatted_salary
               , is_manager
            from strings_processed
            where name_length > 5
            order by upper_name
            for json path
        )
        option (maxdop 8, recompile);
        
        select len(@json_result3) as json_length, 'TEST_RESULT_JSON' as marker;
        
        set @end_time = sysdatetime();
        set @duration = datediff(microsecond, @start_time, @end_time) / 1000;
        
        insert into #timing_results values ('String operations', @current_iteration, @duration);
        set @current_iteration = @current_iteration + 1;
    end;
    
    -- test 4: nested queries (equivalent to nested queries)
    set @current_iteration = 1;
    while @current_iteration <= @iteration_count
    begin
        dbcc dropcleanbuffers;
        dbcc freeproccache;
        
        set @start_time = sysdatetime();
        
        declare @json_result4 nvarchar(max);
        with departments_analysis as (
            select 
                 department
               , count(*) as employee_count
               , sum(case when salary > 75000 then 1 else 0 end) as high_earners
               , avg(cast(age as float)) as average_age
            from people
            group by department
            having count(*) > 50
        )
        select @json_result4 = (
            select 
                 department
               , employee_count
               , high_earners
               , average_age
            from departments_analysis
            order by high_earners desc
            for json path
        )
        option (maxdop 8, recompile);
        
        select len(@json_result4) as json_length, 'TEST_RESULT_JSON' as marker;
        
        set @end_time = sysdatetime();
        set @duration = datediff(microsecond, @start_time, @end_time) / 1000;
        
        insert into #timing_results values ('Nested queries', @current_iteration, @duration);
        set @current_iteration = @current_iteration + 1;
    end;
    
    -- test 5: projection with filter (equivalent to projection operations)
    set @current_iteration = 1;
    while @current_iteration <= @iteration_count
    begin
        dbcc dropcleanbuffers;
        dbcc freeproccache;
        
        set @start_time = sysdatetime();
        
        declare @json_result5 nvarchar(max);
        with recent_hires as (
            select 
                 id
               , name
               , age
               , salary
               , datediff(day, hire_date, getdate()) / 365.25 as years_of_service
               , case 
                    when salary < 40000 then 'Entry level'
                    when salary < 60000 then 'Junior'
                    when salary < 80000 then 'Mid level'
                    when salary < 100000 then 'Senior'
                    else 'Executive'
                 end as salary_bracket
            from people
            where hire_date > dateadd(year, -5, getdate())
        )
        , young_professionals as (
            select 
                 id
               , name
               , age
               , salary_bracket
               , years_of_service
               , case when age < 30 and salary > 60000 then 1 else 0 end as is_young_professional
            from recent_hires
            where age < 30 and salary > 60000
        )
        select @json_result5 = (
            select top 1000
                 id
               , name
               , age
               , salary_bracket
               , years_of_service
               , is_young_professional
            from young_professionals
            order by years_of_service desc
            for json path
        )
        option (maxdop 8, recompile);
        
        select len(@json_result5) as json_length, 'TEST_RESULT_JSON' as marker;
        
        set @end_time = sysdatetime();
        set @duration = datediff(microsecond, @start_time, @end_time) / 1000;
        
        insert into #timing_results values ('Projection with filter', @current_iteration, @duration);
        set @current_iteration = @current_iteration + 1;
    end;
    
    -- calculate and display results
    declare test_cursor cursor for
    select distinct test_name from #timing_results order by test_name;
    
    declare @test_name nvarchar(100);
    
    open test_cursor;
    fetch next from test_cursor into @test_name;
    
    while @@fetch_status = 0
    begin
        select 
             @avg_duration = avg(duration_ms)
           , @min_duration = min(duration_ms)
           , @max_duration = max(duration_ms)
        from #timing_results 
        where test_name = @test_name;
        
        print left(@test_name + replicate(' ', 25), 25) + ': avg: ' + 
              format(@avg_duration, 'n1') + 'ms, min: ' + 
              cast(@min_duration as nvarchar(10)) + 'ms, max: ' + 
              cast(@max_duration as nvarchar(10)) + 'ms';
        
        fetch next from test_cursor into @test_name;
    end;
    
    close test_cursor;
    deallocate test_cursor;
    
    -- cleanup
    drop table #timing_results;
    
    print '';
    print 'Performance test completed.';
end;
go


exec sp_run_performance_tests

