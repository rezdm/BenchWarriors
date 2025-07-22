javac Program.java
rem java -XX:+UseG1GC JavaPerformanceDemo
java -XX:+UseG1GC -XX:+UseStringDeduplication -XX:CompileThreshold=100 Program