<#
    Copyright (c) 2026 dmj.one
    
    This software is part of the dmj.one initiative.
    Created by Nikhil Bhardwaj.
    
    Licensed under the MIT License.
#>
<#
.SYNOPSIS
    Verifies that all development tools are properly installed

.DESCRIPTION
    This script checks for:
    - Java (JDK)
    - GCC/G++ (C/C++ Compiler)
    - Python
    - MySQL
    - All required environment variables
#>

function Write-Header($text) {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "  $text" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
}

function Test-Command($command, $name) {
    try {
        $result = & $command --version 2>&1 | Select-Object -First 1
        Write-Host "[PASS] $name : $result" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "[FAIL] $name is not installed or not in PATH" -ForegroundColor Red
        return $false
    }
}

function Test-JavaVersion {
    try {
        $result = java -version 2>&1 | Select-Object -First 1
        Write-Host "[PASS] Java : $result" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "[FAIL] Java is not installed or not in PATH" -ForegroundColor Red
        return $false
    }
}

Write-Header "Development Environment Verification"

$allPassed = $true

# Test Java
Write-Host "`nChecking Java..." -ForegroundColor Yellow
if (!(Test-JavaVersion)) { $allPassed = $false }
if ($env:JAVA_HOME) {
    Write-Host "       JAVA_HOME: $env:JAVA_HOME" -ForegroundColor Gray
} else {
    Write-Host "       JAVA_HOME: Not set" -ForegroundColor Red
}

# Test javac
try {
    $javacVersion = javac -version 2>&1
    Write-Host "[PASS] Java Compiler : $javacVersion" -ForegroundColor Green
}
catch {
    Write-Host "[FAIL] Java Compiler (javac) not found" -ForegroundColor Red
    $allPassed = $false
}

# Test GCC (C Compiler)
Write-Host "`nChecking C/C++ Compiler..." -ForegroundColor Yellow
if (!(Test-Command "gcc" "GCC (C Compiler)")) { $allPassed = $false }
if (!(Test-Command "g++" "G++ (C++ Compiler)")) { $allPassed = $false }

# Test Python
Write-Host "`nChecking Python..." -ForegroundColor Yellow
if (!(Test-Command "python" "Python")) { $allPassed = $false }

# Test pip
try {
    $pipVersion = pip --version 2>&1
    Write-Host "[PASS] pip : $pipVersion" -ForegroundColor Green
}
catch {
    Write-Host "[FAIL] pip is not installed" -ForegroundColor Red
    $allPassed = $false
}

# Test Python MySQL connector
Write-Host "`nChecking Python MySQL packages..." -ForegroundColor Yellow
$pythonCheck = python -c "import mysql.connector; print(f'mysql-connector-python {mysql.connector.__version__}')" 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "[PASS] mysql-connector-python installed" -ForegroundColor Green
} else {
    Write-Host "[FAIL] mysql-connector-python not installed" -ForegroundColor Red
    $allPassed = $false
}

# Test MySQL
Write-Host "`nChecking MySQL..." -ForegroundColor Yellow
try {
    $mysqlVersion = mysql --version 2>&1
    Write-Host "[PASS] MySQL Client : $mysqlVersion" -ForegroundColor Green
}
catch {
    Write-Host "[FAIL] MySQL is not installed or not in PATH" -ForegroundColor Red
    $allPassed = $false
}

# Check MySQL service
$mysqlService = Get-Service -Name "MySQL*" -ErrorAction SilentlyContinue
if ($mysqlService) {
    if ($mysqlService.Status -eq "Running") {
        Write-Host "[PASS] MySQL Service is running" -ForegroundColor Green
    } else {
        Write-Host "[WARN] MySQL Service exists but is not running" -ForegroundColor Yellow
    }
} else {
    Write-Host "[WARN] MySQL Service not found" -ForegroundColor Yellow
}

# Test Git
Write-Host "`nChecking Additional Tools..." -ForegroundColor Yellow
Test-Command "git" "Git" | Out-Null

# Test VS Code
try {
    $codeVersion = code --version 2>&1 | Select-Object -First 1
    Write-Host "[PASS] VS Code : $codeVersion" -ForegroundColor Green
}
catch {
    Write-Host "[INFO] VS Code not installed (optional)" -ForegroundColor Gray
}

# Environment Variables
Write-Host "`nChecking Environment Variables..." -ForegroundColor Yellow
$envVars = @("JAVA_HOME", "MYSQL_INCLUDE", "MYSQL_LIB")
foreach ($var in $envVars) {
    $value = [System.Environment]::GetEnvironmentVariable($var, "Machine")
    if ($value) {
        Write-Host "[PASS] $var = $value" -ForegroundColor Green
    } else {
        Write-Host "[WARN] $var is not set" -ForegroundColor Yellow
    }
}

# Summary
Write-Header "Verification Summary"

if ($allPassed) {
    Write-Host "All core components are installed correctly!" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now run the sample programs to test the setup:" -ForegroundColor White
    Write-Host "  - Java:   .\run-tests.ps1 java" -ForegroundColor Cyan
    Write-Host "  - C:      .\run-tests.ps1 c" -ForegroundColor Cyan
    Write-Host "  - C++:    .\run-tests.ps1 cpp" -ForegroundColor Cyan
    Write-Host "  - Python: .\run-tests.ps1 python" -ForegroundColor Cyan
    Write-Host "  - All:    .\run-tests.ps1 all" -ForegroundColor Cyan
} else {
    Write-Host "Some components are missing or not properly configured." -ForegroundColor Red
    Write-Host "Please run install-dev-environment.ps1 to install missing components." -ForegroundColor Yellow
}

Write-Host ""

