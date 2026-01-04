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
    Specify which language to test: java, c, cpp, python, or all

.PARAMETER Basic
    Run basic tests without MySQL (for initial verification)

.EXAMPLE
    .\run-tests.ps1 all
    .\run-tests.ps1 java
    .\run-tests.ps1 python -Basic
#>

param(
    [Parameter(Position=0)]
    [ValidateSet("java", "c", "cpp", "python", "all", "basic")]
    [string]$Language = "all",
    
    [switch]$Basic
)

$ErrorActionPreference = "Continue"
$ScriptRoot = $PSScriptRoot

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
            javac BasicTest.java 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[OK] Compilation successful!" -ForegroundColor Green
                Write-Host "`nRunning BasicTest..." -ForegroundColor Yellow
                java BasicTest
                Write-Host ""
                Write-Host "[OK] Java basic test completed!" -ForegroundColor Green
            } else {
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
                javac -cp $classpath MySQLTest.java 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "[OK] Compilation successful!" -ForegroundColor Green
                    Write-Host "`nRunning MySQL test..." -ForegroundColor Yellow
                    java -cp $classpath MySQLTest
                } else {
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

function Test-Python {
    Write-Header "Testing Python"
    
    $pythonDir = "$ScriptRoot\samples\python"
    
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
            } else {
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
                Write-Host "Compiling mysql_test.c..." -ForegroundColor Yellow
                gcc -o mysql_test.exe mysql_test.c -I"$mysqlInclude" -L"$mysqlLib" -lmysqlclient 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "[OK] Compilation successful!" -ForegroundColor Green
                    Write-Host "`nRunning MySQL test..." -ForegroundColor Yellow
                    .\mysql_test.exe
                } else {
                    Write-Host "[ERROR] Compilation failed!" -ForegroundColor Red
                    Write-Host "Note: C MySQL connectivity requires MySQL C library (libmysqlclient)" -ForegroundColor Yellow
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
            } else {
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
                Write-Host "Compiling mysql_test.cpp..." -ForegroundColor Yellow
                g++ -o mysql_test.exe mysql_test.cpp -I"$mysqlInclude" -L"$mysqlLib" -lmysqlclient -std=c++17 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "[OK] Compilation successful!" -ForegroundColor Green
                    Write-Host "`nRunning MySQL test..." -ForegroundColor Yellow
                    .\mysql_test.exe
                } else {
                    Write-Host "[ERROR] Compilation failed!" -ForegroundColor Red
                    Write-Host "Note: C++ MySQL connectivity requires MySQL C library (libmysqlclient)" -ForegroundColor Yellow
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
        Test-C
        Test-Cpp
        Test-Python
    }
}

Write-Host ""
Write-Host ("*" * 60) -ForegroundColor Green
Write-Host "*  Test Run Complete!                                        *" -ForegroundColor Green
Write-Host ("*" * 60) -ForegroundColor Green
Write-Host ""

