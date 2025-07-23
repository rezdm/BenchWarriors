i@echo off
setlocal enabledelayedexpansion

:: sql performance test runner
:: runs tests.sql and shows only print statements (no select results)

echo ================================================
echo SQL performance test runner
echo ================================================
echo.

:: configuration - modify these as needed
set SERVER_NAME=localhost
set DATABASE_NAME=perf
set SQL_FILE=tests.sql
set OUTPUT_FILE=test_results.txt
set USE_WINDOWS_AUTH=1

:: check if sql file exists
if not exist "%SQL_FILE%" (
    echo error: %SQL_FILE% not found!
    echo please ensure the sql script file exists in the current directory.
    pause
    exit /b 1
)

:: build sqlcmd connection string
if %USE_WINDOWS_AUTH%==1 (
    set CONNECTION=-S %SERVER_NAME% -d %DATABASE_NAME% -E
    echo connecting to: %SERVER_NAME% database: %DATABASE_NAME% ^(windows auth^)
) else (
    set /p USERNAME=enter sql server username: 
    set /p PASSWORD=enter sql server password: 
    set CONNECTION=-S %SERVER_NAME% -d %DATABASE_NAME% -U !USERNAME! -P !PASSWORD!
    echo connecting to: %SERVER_NAME% database: %DATABASE_NAME% ^(sql auth^)
)

echo.

:: run the sql script with optimized sqlcmd parameters
echo running performance tests...
echo.

sqlcmd %CONNECTION% ^
    -i "%SQL_FILE%" ^
    -o "%OUTPUT_FILE%" ^
    -h -1 ^
    -w 999 ^
    -s "|" ^
    -W ^
    -r 1 ^
    -m 1 ^
    2>&1

:: check if sqlcmd executed successfully
if %ERRORLEVEL% neq 0 (
    echo.
    echo error: sqlcmd failed with error code %ERRORLEVEL%
    echo check your connection settings and sql syntax
    pause
    exit /b %ERRORLEVEL%
)

:: filter output to show only print statements and remove select results
echo filtering output to show only print statements...
echo.

:: create filtered output
(
    for /f "usebackq delims=" %%a in ("%OUTPUT_FILE%") do (
        set "line=%%a"
        
        :: skip empty lines and result set formatting
        if not "!line!"=="" (
            if not "!line!"=="--------------------" (
                if not "!line:TEST_RESULT_JSON=!"=="!line!" (
                    rem skip json result marker lines
                ) else if not "!line:rows affected=!"=="!line!" (
                    rem skip rows affected messages  
                ) else if not "!line!"=="Changed database context to 'tempdb'." (
                    if not "!line!"=="Changed database context to 'master'." (
                        if not "!line:~0,1!"=="|" (
                            if not "!line!"=="(1 rows affected)" (
                                if not "!line!"=="(10 rows affected)" (
                                    if not "!line!"=="(5 rows affected)" (
                                        if not "!line:json_length=!"=="!line!" (
                                            rem skip json length header lines
                                        ) else (
                                            echo !line!
                                        )
                                    )
                                )
                            )
                        )
                    )
                )
            )
        )
    )
) > "%OUTPUT_FILE%.filtered"

:: display the filtered results
echo ================================================
echo performance test results:
echo ================================================
echo.
type "%OUTPUT_FILE%.filtered"
echo.
echo ================================================

:: cleanup option
echo.
rem set /p CLEANUP=delete temporary files? (y/n): 
set CLEAUNUP="n"
if /i "%CLEANUP%"=="y" (
    del "%OUTPUT_FILE%" 2>nul
    del "%OUTPUT_FILE%.filtered" 2>nul
    echo temporary files deleted.
) else (
    echo temporary files kept:
    echo   - %OUTPUT_FILE% ^(full output^)
    echo   - %OUTPUT_FILE%.filtered ^(filtered output^)
)

