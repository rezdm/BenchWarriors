@echo off
setlocal enabledelayedexpansion

echo ================================================
echo system hardware information
echo ================================================
echo.

:: get cpu information using powershell
echo cpu information:
echo ---------------
for /f "usebackq delims=" %%a in (`powershell -command "Get-CimInstance -ClassName Win32_Processor | Select-Object -ExpandProperty Name"`) do (
    echo cpu model: %%a
)

for /f "usebackq delims=" %%a in (`powershell -command "Get-CimInstance -ClassName Win32_Processor | Select-Object -ExpandProperty MaxClockSpeed"`) do (
    set /a clock_ghz=%%a/1000
    set /a clock_mhz=%%a%%1000
    echo base clock speed: %%a mhz (approx !clock_ghz!.!clock_mhz! ghz)
)

for /f "usebackq delims=" %%a in (`powershell -command "Get-CimInstance -ClassName Win32_Processor | Select-Object -ExpandProperty NumberOfCores"`) do (
    echo physical cores: %%a
)

for /f "usebackq delims=" %%a in (`powershell -command "Get-CimInstance -ClassName Win32_Processor | Select-Object -ExpandProperty NumberOfLogicalProcessors"`) do (
    echo logical processors: %%a
)

echo.

:: get memory information
echo memory information:
echo ------------------
for /f "usebackq delims=" %%a in (`powershell -command "[math]::Round((Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory/1GB, 2)"`) do (
    echo total physical memory: %%a gb
)

for /f "usebackq delims=" %%a in (`powershell -command "[math]::Round((Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory/1MB, 0)"`) do (
    echo total physical memory: %%a mb
)

echo.
echo memory modules:
powershell -command "Get-CimInstance -ClassName Win32_PhysicalMemory | ForEach-Object { $sizeGB = [math]::Round($_.Capacity/1GB, 0); Write-Output \"  - $($_.Manufacturer) $($_.PartNumber): $sizeGB GB @ $($_.Speed) MHz\" }"

echo.

:: get system model information
echo system information:
echo ------------------
for /f "usebackq delims=" %%a in (`powershell -command "Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -ExpandProperty Manufacturer"`) do (
    echo manufacturer: %%a
)

for /f "usebackq delims=" %%a in (`powershell -command "Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -ExpandProperty Model"`) do (
    echo model: %%a
)

for /f "usebackq delims=" %%a in (`powershell -command "Get-CimInstance -ClassName Win32_BIOS | Select-Object -ExpandProperty SerialNumber"`) do (
    echo serial number: %%a
)

echo.

:: get additional system details
echo additional details:
echo ------------------
for /f "usebackq delims=" %%a in (`powershell -command "Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -ExpandProperty Caption"`) do (
    echo operating system: %%a
)

for /f "usebackq delims=" %%a in (`powershell -command "Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -ExpandProperty Version"`) do (
    echo os version: %%a
)

for /f "usebackq delims=" %%a in (`powershell -command "Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -ExpandProperty OSArchitecture"`) do (
    echo architecture: %%a
)

echo.

:: get cpu details including current speed
echo detailed cpu information:
echo ------------------------
powershell -command "Get-CimInstance -ClassName Win32_Processor | ForEach-Object { Write-Output \"current speed: $($_.CurrentClockSpeed) MHz\"; Write-Output \"l2 cache size: $($_.L2CacheSize) KB\"; Write-Output \"l3 cache size: $($_.L3CacheSize) KB\" }"

echo.

:: get gpu information
echo graphics information:
echo --------------------
powershell -command "Get-CimInstance -ClassName Win32_VideoController | Where-Object { $_.Name -notlike '*Basic*' -and $_.Name -notlike '*Generic*' } | ForEach-Object { $vramGB = [math]::Round($_.AdapterRAM/1GB, 1); Write-Output \"gpu: $($_.Name)\"; if ($_.AdapterRAM -gt 0) { Write-Output \"  vram: $vramGB GB\" } }"

echo.

:: get motherboard information
echo motherboard information:
echo -----------------------
for /f "usebackq delims=" %%a in (`powershell -command "Get-CimInstance -ClassName Win32_BaseBoard | Select-Object -ExpandProperty Manufacturer"`) do (
    echo motherboard manufacturer: %%a
)

for /f "usebackq delims=" %%a in (`powershell -command "Get-CimInstance -ClassName Win32_BaseBoard | Select-Object -ExpandProperty Product"`) do (
    echo motherboard model: %%a
)

echo.

:: get storage information
echo storage information:
echo -------------------
powershell -command "Get-CimInstance -ClassName Win32_DiskDrive | ForEach-Object { $sizeGB = [math]::Round($_.Size/1GB, 0); Write-Output \"drive: $($_.Caption)\"; Write-Output \"  model: $($_.Model)\"; Write-Output \"  size: $sizeGB GB\"; Write-Output \"  interface: $($_.InterfaceType)\"; Write-Output \"\" }"

echo.
echo ================================================
echo hardware information collection completed
echo ================================================

