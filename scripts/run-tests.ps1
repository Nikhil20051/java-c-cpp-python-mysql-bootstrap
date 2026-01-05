<#
    Copyright (c) 2026 dmj.one
    
    This software is part of the dmj.one initiative.
    Created by Nikhil Bhardwaj.
    
    Licensed under the MIT License.
#>
<#
.SYNOPSIS
    Test Runner for all language samples

.DESCRIPTION
    Compiles and runs test programs for Java, C, C++, and Python
    Can test MySQL connectivity or basic language functionality

.PARAMETER Language
    Specify which language to test: java, maven, gradle, c, cpp, python, or all

.PARAMETER Basic
    Run basic tests without MySQL (for initial verification)

.EXAMPLE
    .\run-tests.ps1 all
    .\run-tests.ps1 java
    .\run-tests.ps1 python -Basic
#>

param(
    [Parameter(Position = 0)]
    [ValidateSet("java", "maven", "gradle", "c", "cpp", "python", "all", "basic")]
    [string]$Language = "all",
    
    [switch]$Basic
)

$ErrorActionPreference = "Continue"
$ScriptRoot = Split-Path -Parent $PSScriptRoot

# ============================================
# REFRESH ENVIRONMENT VARIABLES
# ============================================
# This ensures newly installed tools are found without requiring a terminal restart

# Refresh PATH from registry
$machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
$userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
$env:Path = "$machinePath;$userPath"

# Refresh JAVA_HOME
$javaHome = [System.Environment]::GetEnvironmentVariable("JAVA_HOME", "Machine")
if ($javaHome) {
    $env:JAVA_HOME = $javaHome
    # Add Java bin to PATH if not already there
    if ($env:Path -notlike "*$javaHome\bin*") {
        $env:Path = "$javaHome\bin;$env:Path"
    }
}

# Add common tool paths that may not be in PATH yet
$additionalPaths = @(
    "C:\Python312",
    "C:\Python312\Scripts",
    "C:\Python311",
    "C:\Python311\Scripts",
    "C:\ProgramData\mingw64\mingw64\bin",
    "C:\ProgramData\chocolatey\lib\mingw\tools\install\mingw64\bin",
    "C:\tools\mysql\current\bin",
    "C:\Program Files\Git\bin"
)

foreach ($path in $additionalPaths) {
    if ((Test-Path $path) -and ($env:Path -notlike "*$path*")) {
        $env:Path = "$env:Path;$path"
    }
}

function Write-Header($text) {
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor Cyan
    Write-Host "  $text" -ForegroundColor Cyan
    Write-Host ("=" * 60) -ForegroundColor Cyan
    Write-Host ""
}

function Write-SubHeader($text) {
    Write-Host ""
    Write-Host ("- " * 30) -ForegroundColor DarkGray
    Write-Host "  $text" -ForegroundColor Yellow
    Write-Host ("- " * 30) -ForegroundColor DarkGray
    Write-Host ""
}

function Test-Java {
    Write-Header "Testing Java"
    
    $javaDir = "$ScriptRoot\samples\java"
    
    if ($Basic) {
        Write-SubHeader "Running Basic Java Test"
        
        # Compile and run basic test
        Push-Location $javaDir
        try {
            Write-Host "Compiling BasicTest.java..." -ForegroundColor Yellow
            javac -encoding UTF-8 BasicTest.java 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[OK] Compilation successful!" -ForegroundColor Green
                Write-Host "`nRunning BasicTest..." -ForegroundColor Yellow
                java BasicTest
                Write-Host ""
                Write-Host "[OK] Java basic test completed!" -ForegroundColor Green
            }
            else {
                Write-Host "[ERROR] Compilation failed!" -ForegroundColor Red
            }
        }
        finally {
            Pop-Location
        }
    }
    else {
        Write-SubHeader "Running MySQL Connectivity Test"
        
        # Find MySQL Connector/J
        $connectorPath = Get-ChildItem -Path "$ScriptRoot\lib" -Recurse -Filter "mysql-connector-j-*.jar" | Select-Object -First 1
        
        if (!$connectorPath) {
            # Try alternative locations
            $altPaths = @(
                "C:\Program Files\MySQL\Connector J*\mysql-connector-j-*.jar",
                "C:\ProgramData\chocolatey\lib\mysql-connector\lib\mysql-connector-j-*.jar"
            )
            foreach ($path in $altPaths) {
                $found = Get-ChildItem -Path $path -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($found) {
                    $connectorPath = $found
                    break
                }
            }
        }
        
        if ($connectorPath) {
            $classpath = "$javaDir;$($connectorPath.FullName)"
            Write-Host "Using MySQL Connector: $($connectorPath.FullName)" -ForegroundColor Gray
            
            Push-Location $javaDir
            try {
                Write-Host "Compiling MySQLTest.java..." -ForegroundColor Yellow
                javac -encoding UTF-8 -cp $classpath MySQLTest.java 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "[OK] Compilation successful!" -ForegroundColor Green
                    Write-Host "`nRunning MySQL test..." -ForegroundColor Yellow
                    java -cp $classpath MySQLTest
                }
                else {
                    Write-Host "[ERROR] Compilation failed!" -ForegroundColor Red
                }
            }
            finally {
                Pop-Location
            }
        }
        else {
            Write-Host "[ERROR] MySQL Connector/J not found!" -ForegroundColor Red
            Write-Host "Please download it from: https://dev.mysql.com/downloads/connector/j/" -ForegroundColor Yellow
        }
    }
}

function Test-Maven {
    Write-Header "Testing Maven Project"
    
    $mavenDir = "$ScriptRoot\samples\java\maven-demo"
    
    # Check if Maven is installed
    $mvn = Get-Command mvn -ErrorAction SilentlyContinue
    if (-not $mvn) {
        Write-Host "[ERROR] Maven (mvn) is not installed!" -ForegroundColor Red
        Write-Host "Install with: choco install maven" -ForegroundColor Yellow
        return
    }
    
    if (-not (Test-Path $mavenDir)) {
        Write-Host "[ERROR] Maven demo project not found at: $mavenDir" -ForegroundColor Red
        return
    }
    
    Write-SubHeader "Building and Running Maven Project"
    Write-Host "Project: $mavenDir" -ForegroundColor Gray
    Write-Host ""
    
    Push-Location $mavenDir
    try {
        # Clean, compile and run in one command
        Write-Host "Running: mvn clean compile exec:java..." -ForegroundColor Yellow
        Write-Host ""
        
        & mvn clean compile exec:java "-Dexec.mainClass=one.dmj.App" 2>&1 | ForEach-Object {
            $line = "$_"
            # Filter Maven noise but show app output
            if ($line -match "^\[INFO\] ---.*exec-maven-plugin") {
                # Skip this line, exec is starting
            }
            elseif ($_ -match "^\[INFO\] (Downloading|Downloaded)") {
                Write-Host $_ -ForegroundColor Gray
            }
            elseif ($_ -match "^\[INFO\] (BUILD|Scanning)") {
                # Skip general build progress
            }
            elseif ($_ -match "^\[ERROR\]") {
                Write-Host $_ -ForegroundColor Red
            }
            elseif ($_ -match "^\[WARNING\]") {
                Write-Host $_ -ForegroundColor Yellow
            }
            elseif ($line -notmatch "^\[INFO\]" -and $line.Trim()) {
                Write-Host $line
            }
        }
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "[OK] Maven project test completed!" -ForegroundColor Green
        }
        else {
            Write-Host "[ERROR] Maven build/run failed (exit code: $LASTEXITCODE)" -ForegroundColor Red
        }
    }
    finally {
        Pop-Location
    }
}

function Test-Gradle {
    Write-Header "Testing Gradle Project"
    
    $gradleDir = "$ScriptRoot\samples\java\gradle-demo"
    
    # Check if Gradle is installed
    $gradle = Get-Command gradle -ErrorAction SilentlyContinue
    if (-not $gradle) {
        Write-Host "[ERROR] Gradle is not installed!" -ForegroundColor Red
        Write-Host "Install with: choco install gradle" -ForegroundColor Yellow
        return
    }
    
    if (-not (Test-Path $gradleDir)) {
        Write-Host "[ERROR] Gradle demo project not found at: $gradleDir" -ForegroundColor Red
        return
    }
    
    Write-SubHeader "Building and Running Gradle Project"
    Write-Host "Project: $gradleDir" -ForegroundColor Gray
    Write-Host ""
    
    Push-Location $gradleDir
    try {
        # Check for gradlew
        $gradleCmd = if (Test-Path "gradlew.bat") { ".\gradlew.bat" } else { "gradle" }
        
        # Clean, build and run in one go
        # We remove -q to see download progress, but filter noise
        Write-Host "Running: $gradleCmd clean build run..." -ForegroundColor Yellow
        Write-Host "(This may take a while if downloading dependencies...)" -ForegroundColor Gray
        Write-Host ""
        
        & $gradleCmd clean build run 2>&1 | ForEach-Object {
            $line = "$_"
            # Filter output but allow important info
            if ($line -match "Downloading") {
                Write-Host $_ -ForegroundColor Gray
            }
            elseif ($_ -match "^> Task") {
                # Skip task progress bars to keep clean
            }
            elseif ($_ -match "BUILD SUCCESSFUL") {
                Write-Host $_ -ForegroundColor Green
            }
            elseif ($_ -match "BUILD FAILED") {
                Write-Host $_ -ForegroundColor Red
            }
            elseif ($_ -match "Exception|Error:") {
                Write-Host $_ -ForegroundColor Red
            }
            elseif ($line.Trim() -and $line -notmatch "^>|^To opt-out") {
                Write-Host $line
            }
        }
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "[OK] Gradle project test completed!" -ForegroundColor Green
        }
        else {
            Write-Host "[ERROR] Gradle build/run failed (exit code: $LASTEXITCODE)" -ForegroundColor Red
        }
    }
    finally {
        Pop-Location
    }
}

function Test-Python {
    Write-Header "Testing Python"
    
    $pythonDir = "$ScriptRoot\samples\python"

    # --- FIX START: Force Python to use UTF-8 for output ---
    $env:PYTHONIOENCODING = "utf-8"
    # --- FIX END ---
    
    if ($Basic) {
        Write-SubHeader "Running Basic Python Test"
        Write-Host "Running basic_test.py..." -ForegroundColor Yellow
        python "$pythonDir\basic_test.py"
        Write-Host ""
        Write-Host "[OK] Python basic test completed!" -ForegroundColor Green
    }
    else {
        Write-SubHeader "Running MySQL Connectivity Test"
        
        # Check if mysql-connector-python is installed
        $checkModule = python -c "import mysql.connector" 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[WARN] mysql-connector-python not installed. Installing..." -ForegroundColor Yellow
            pip install mysql-connector-python
        }
        
        Write-Host "Running mysql_test.py..." -ForegroundColor Yellow
        python "$pythonDir\mysql_test.py"
    }
}

function Test-C {
    Write-Header "Testing C"
    
    $cDir = "$ScriptRoot\samples\c"
    
    if ($Basic) {
        Write-SubHeader "Running Basic C Test"
        
        Push-Location $cDir
        try {
            Write-Host "Compiling basic_test.c..." -ForegroundColor Yellow
            gcc -o basic_test.exe basic_test.c 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[OK] Compilation successful!" -ForegroundColor Green
                Write-Host "`nRunning basic_test..." -ForegroundColor Yellow
                .\basic_test.exe
                Write-Host ""
                Write-Host "[OK] C basic test completed!" -ForegroundColor Green
            }
            else {
                Write-Host "[ERROR] Compilation failed!" -ForegroundColor Red
            }
        }
        finally {
            Pop-Location
        }
    }
    else {
        Write-SubHeader "Running MySQL Connectivity Test"
        
        # Check for MySQL installation
        $mysqlPath = "C:\tools\mysql\current"
        $mysqlInclude = "$mysqlPath\include"
        $mysqlLib = "$mysqlPath\lib"
        
        if (!(Test-Path $mysqlInclude)) {
            # Try alternative locations
            $altPaths = @(
                "C:\Program Files\MySQL\MySQL Server*\include",
                "C:\ProgramData\chocolatey\lib\mysql\tools\*\include"
            )
            foreach ($path in $altPaths) {
                $found = Get-ChildItem -Path $path -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($found) {
                    $mysqlInclude = $found.FullName
                    $mysqlLib = Join-Path $found.Parent.FullName "lib"
                    break
                }
            }
        }
        
        if (Test-Path $mysqlInclude) {
            Write-Host "MySQL Include: $mysqlInclude" -ForegroundColor Gray
            Write-Host "MySQL Lib: $mysqlLib" -ForegroundColor Gray
            
            Push-Location $cDir
            try {
                # Copy libmysql.dll to the executable directory
                $dllSource = Join-Path $mysqlLib "libmysql.dll"
                if (Test-Path $dllSource) {
                    Copy-Item -Path $dllSource -Destination $cDir -Force
                }

                Write-Host "Compiling mysql_test.c..." -ForegroundColor Yellow
                gcc -o mysql_test.exe mysql_test.c -I"$mysqlInclude" -L"$mysqlLib" -llibmysql 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "[OK] Compilation successful!" -ForegroundColor Green
                    Write-Host "`nRunning MySQL test..." -ForegroundColor Yellow
                    .\mysql_test.exe
                }
                else {
                    Write-Host "[ERROR] Compilation failed!" -ForegroundColor Red
                    Write-Host "Note: linking against libmysql.lib (DLL import lib) failed." -ForegroundColor Yellow
                }
            }
            finally {
                Pop-Location
            }
        }
        else {
            Write-Host "[ERROR] MySQL include directory not found!" -ForegroundColor Red
            Write-Host "Install MySQL Server or MySQL C Connector" -ForegroundColor Yellow
        }
    }
}

function Test-Cpp {
    Write-Header "Testing C++"
    
    $cppDir = "$ScriptRoot\samples\cpp"
    
    if ($Basic) {
        Write-SubHeader "Running Basic C++ Test"
        
        Push-Location $cppDir
        try {
            Write-Host "Compiling basic_test.cpp..." -ForegroundColor Yellow
            g++ -o basic_test.exe basic_test.cpp -std=c++17 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[OK] Compilation successful!" -ForegroundColor Green
                Write-Host "`nRunning basic_test..." -ForegroundColor Yellow
                .\basic_test.exe
                Write-Host ""
                Write-Host "[OK] C++ basic test completed!" -ForegroundColor Green
            }
            else {
                Write-Host "[ERROR] Compilation failed!" -ForegroundColor Red
            }
        }
        finally {
            Pop-Location
        }
    }
    else {
        Write-SubHeader "Running MySQL Connectivity Test"
        
        # Check for MySQL installation
        $mysqlPath = "C:\tools\mysql\current"
        $mysqlInclude = "$mysqlPath\include"
        $mysqlLib = "$mysqlPath\lib"
        
        if (!(Test-Path $mysqlInclude)) {
            # Try alternative locations
            $altPaths = @(
                "C:\Program Files\MySQL\MySQL Server*\include",
                "C:\ProgramData\chocolatey\lib\mysql\tools\*\include"
            )
            foreach ($path in $altPaths) {
                $found = Get-ChildItem -Path $path -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($found) {
                    $mysqlInclude = $found.FullName
                    $mysqlLib = Join-Path $found.Parent.FullName "lib"
                    break
                }
            }
        }
        
        if (Test-Path $mysqlInclude) {
            Write-Host "MySQL Include: $mysqlInclude" -ForegroundColor Gray
            Write-Host "MySQL Lib: $mysqlLib" -ForegroundColor Gray
            
            Push-Location $cppDir
            try {
                # Copy libmysql.dll to the executable directory
                $dllSource = Join-Path $mysqlLib "libmysql.dll"
                if (Test-Path $dllSource) {
                    Copy-Item -Path $dllSource -Destination $cppDir -Force
                }

                Write-Host "Compiling mysql_test.cpp..." -ForegroundColor Yellow
                g++ -o mysql_test.exe mysql_test.cpp -I"$mysqlInclude" -L"$mysqlLib" -llibmysql -std=c++17 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "[OK] Compilation successful!" -ForegroundColor Green
                    Write-Host "`nRunning MySQL test..." -ForegroundColor Yellow
                    .\mysql_test.exe
                }
                else {
                    Write-Host "[ERROR] Compilation failed!" -ForegroundColor Red
                    Write-Host "Note: linking against libmysql.lib (DLL import lib) failed." -ForegroundColor Yellow
                }
            }
            finally {
                Pop-Location
            }
        }
        else {
            Write-Host "[ERROR] MySQL include directory not found!" -ForegroundColor Red
            Write-Host "Install MySQL Server or MySQL C Connector" -ForegroundColor Yellow
        }
    }
}

# Main execution
Write-Host ""
Write-Host ("*" * 60) -ForegroundColor Magenta
Write-Host "*  Development Environment Test Runner                     *" -ForegroundColor Magenta
Write-Host "*  Language: $Language$(if($Basic){' (Basic mode)'}else{''})".PadRight(58) + "*" -ForegroundColor Magenta
Write-Host ("*" * 60) -ForegroundColor Magenta

switch ($Language) {
    "java" { Test-Java }
    "maven" { Test-Maven }
    "gradle" { Test-Gradle }
    "python" { Test-Python }
    "c" { Test-C }
    "cpp" { Test-Cpp }
    "basic" {
        $Basic = $true
        Test-Java
        Test-C
        Test-Cpp
        Test-Python
    }
    "all" {
        Test-Java
        Test-Maven
        Test-Gradle
        Test-C
        Test-Cpp
        Test-Python
    }
}

# ============================================
# RUN DYNAMIC TESTS
# ============================================

$dynamicTestScript = Join-Path $PSScriptRoot "testing\dynamic-test-generator.ps1"
if (Test-Path $dynamicTestScript) {
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor Magenta
    Write-Host "  Running Dynamic Test Suite (Auto-Generated Each Run)" -ForegroundColor Magenta
    Write-Host ("=" * 60) -ForegroundColor Magenta
    
    # Map special languages to the ones dynamic-test-generator knows about
    $dynamicLanguage = switch ($Language) {
        "basic" { "all" }
        "maven" { "java" }
        "gradle" { "java" }
        default { $Language }
    }
    & $dynamicTestScript -Language $dynamicLanguage -TestCount 5
}

# ============================================
# RUN WORKSPACE CLEANUP
# ============================================
$cleanupScript = Join-Path $PSScriptRoot "clean-workspace.ps1"
if (Test-Path $cleanupScript) {
    Write-Host ""
    Write-Host ("-" * 60) -ForegroundColor DarkGray
    Write-Host "  Cleaning Up Workspace..." -ForegroundColor Yellow
    Write-Host ("-" * 60) -ForegroundColor DarkGray
    
    & $cleanupScript *>$null
}

Write-Host ""
Write-Host ("*" * 60) -ForegroundColor Green
Write-Host "*  Test Run Complete!                                        *" -ForegroundColor Green
Write-Host ("*" * 60) -ForegroundColor Green
Write-Host ""
