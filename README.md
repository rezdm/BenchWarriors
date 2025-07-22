# BenchWarriors
Comparing LINQ, Stream, etc in different languages 

This projects started after a discussion on performance improvements in .NET Core vs .NET Framework. I did a small experiment (see NET folder) and ran the same code running in FW 4.8.1 vs Core 9.
Later I decided to extend the project and add more languages:

C#, .NET9
Java 17+, JDK 24
C++ 17+, MS VS 2022

Planned:
SQL, SQL Server 2022 -- this one is definitely interesting, but there are so many optimizations that can and should happen under the hood that this is a challenge on its own
Rust
Go
May be JS