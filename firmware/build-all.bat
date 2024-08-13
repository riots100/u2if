@echo off
setlocal enabledelayedexpansion

REM Get the current directory name
for %%i in ("%CD%") do set "dirname=%%~nxi"

REM Check if the script is launched in the "firmware" directory
if /i not "%dirname%"=="firmware" (
    echo This script has to be launched in the firmware directory
    exit /b -1
)

REM Get the version from CMakeLists.txt
for /f "tokens=2 delims== " %%a in ('findstr "project(u2if VERSION" "%CD%\source\CMakeLists.txt"') do set "VERSION=%%a"

set "RELEASE_DIR=%CD%\release"

REM Get the number of processors
for /f %%a in ('wmic cpu get NumberOfLogicalProcessors /value') do (
    for /f "delims=" %%b in ("%%a") do set "CORES_NB=%%b"
)
set "CORES_NB=%CORES_NB:NumberOfLogicalProcessors=%%"

REM Function to build the project
:build
    echo Build for board %2 (I2S_ALLOW=%3, HUB75_ALLOW=%6, WS2812=%4 with %5 max leds)
    set "tmp_dir=%TEMP%\ci-%RANDOM%%RANDOM%%RANDOM%%RANDOM%"
    mkdir "%tmp_dir%"
    set "FIRMWARE_ROOT_DIR=%CD%"
    cd /d "%tmp_dir%"
    cmake -G Ninja -DBOARD=%2 -DI2S_ALLOW=%3 -DWS2812_ENABLED=%4 -DWS2812_SIZE=%5 -DHUB75_ALLOW=%6 "%FIRMWARE_ROOT_DIR%\source"
    ninja -j%CORES_NB%
    copy u2if.uf2 "%RELEASE_DIR%\u2if_%1_v%VERSION%.uf2"
    cd /d "%FIRMWARE_ROOT_DIR%"
    rmdir /s /q "%tmp_dir%"
goto :eof

REM Create release directory if it doesn't exist
if not exist "%RELEASE_DIR%" mkdir "%RELEASE_DIR%"

REM Call the build function
call :build pico PICO 0 1 10 0
