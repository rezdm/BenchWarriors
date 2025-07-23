# BenchWarriors
Comparing LINQ, Stream, etc in different languages 

This projects started after a discussion on performance improvements in .NET Core vs .NET Framework. I did a small experiment (see NET folder) and ran the same code running in FW 4.8.1 vs Core 9.
Later I decided to extend the project and add more languages:

- C#, .NET9
- Java 17+, JDK 24
- C++ 17+, MS VS 2022
- SQL, SQL Server 2022 -- this one is definitely interesting, but there are so many optimizations that can and should happen under the hood that this is a challenge on its own

Planned:
- Rust
- Go
- May be JS


Results:

.NET:
```
Running on .NET 9.0
Running on: .NET 9.0.7
Architecture: X64

Performance Test Results:
========================
Complex LINQ Chain       : Avg: 554.0ms, Min: 501ms, Max: 580ms
GroupBy with Aggregation : Avg: 350.8ms, Min: 340ms, Max: 373ms
String Operations        : Avg: 728.6ms, Min: 679ms, Max: 781ms
Nested Queries           : Avg: 207.8ms, Min: 201ms, Max: 214ms
Projection with Where    : Avg: 197.0ms, Min: 195ms, Max: 199ms
```

Java:
```
Running on: Java 24
JVM: Java HotSpot(TM) 64-Bit Server VM 24+36-3646
Available processors: 20

Performance Test Results:
========================
Complex Stream Chain     : Avg: 594.6ms, Min: 565ms, Max: 631ms
GroupBy with Aggregation : Avg: 301.2ms, Min: 278ms, Max: 315ms
String Operations        : Avg: 317.2ms, Min: 308ms, Max: 332ms
Nested Queries           : Avg: 108.0ms, Min: 94ms, Max: 122ms
Projection with Filter   : Avg: 106.0ms, Min: 98ms, Max: 116ms
```

CPP:
```
Performance Test Results:

========================
Complex LINQ Chain       : Avg: 444.80ms, Min: 414.34ms, Max: 481.79ms
GroupBy with Aggregation : Avg: 55.57ms, Min: 51.25ms, Max: 60.54ms
String Operations        : Avg: 215.24ms, Min: 209.71ms, Max: 220.59ms
Nested Queries           : Avg: 69.34ms, Min: 64.31ms, Max: 79.00ms
Projection with Where    : Avg: 18.09ms, Min: 15.22ms, Max: 20.43ms
```

SQL:
```
Current server configuration:
cost threshold for parallelism|50|50|cost threshold for parallelism
max degree of parallelism|8|8|maximum degree of parallelism
ECHO is off.

Recommended settings for performance testing:
============================================
CPU count: 20
Recommended maxdop: 8
Recommended cost threshold: 50
ECHO is off.

SQL performance test results:
====================================
SQL server version: Microsoft SQL Server 2022 (RTM-GDR) (KB5058712) - 16.0.1140.6 (X64) 
	Jun 19 2025 11:40:25 
	Copyright (C) 2022 Microsoft Corporation
	Developer Edition (64-bit) on Windows 10 Enterprise 10.0 <X64> (Build 22631: ) (Hypervisor)
Database: perf
CPU count: 20
Using maxdop hint: 8
ECHO is off.
Complex query chain      : avg: 175.0ms, min: 159ms, max: 233ms
GroupBy with aggregation : avg: 253.0ms, min: 248ms, max: 260ms
Nested queries           : avg: 179.0ms, min: 177ms, max: 182ms
Projection with filter   : avg: 164.0ms, min: 163ms, max: 169ms
String operations        : avg: 1,918.0ms, min: 1831ms, max: 1990ms
ECHO is off.
Performance test completed.
```

Hardware:
```
================================================
system hardware information
================================================

cpu information:
---------------
cpu model: 13th Gen Intel(R) Core(TM) i9-13900H
base clock speed: 2600 mhz (approx 2.600 ghz
physical cores: 14
logical processors: 20

memory information:
------------------
total physical memory: 63.59 gb
total physical memory: 65111 mb

memory modules:
  -  : 8 GB @ 6400 MHz
  -  : 8 GB @ 6400 MHz
  -  : 8 GB @ 6400 MHz
  -  : 8 GB @ 6400 MHz
  -  : 8 GB @ 6400 MHz
  -  : 8 GB @ 6400 MHz
  -  : 8 GB @ 6400 MHz
  -  : 8 GB @ 6400 MHz

system information:
------------------
manufacturer: Dell Inc.
model: Precision 5680
serial number: 9V5FB24

additional details:
------------------
operating system: Microsoft Windows 11 Enterprise
os version: 10.0.22631
architecture: 64-bit

detailed cpu information:
------------------------
current speed: 2600 MHz
l2 cache size: 11776 KB
l3 cache size: 24576 KB

graphics information:
--------------------
gpu: Intel(R) Iris(R) Xe Graphics
  vram: 2 GB

motherboard information:
-----------------------
motherboard manufacturer: Dell Inc.
motherboard model: 03D3MR

storage information:
-------------------
drive: 3500 Micron 512GB
  model: 3500 Micron 512GB
  size: 477 GB
  interface: SCSI

drive: 3500 Micron 512GB
  model: 3500 Micron 512GB
  size: 477 GB
  interface: SCSI


================================================
hardware information collection completed
================================================
```
