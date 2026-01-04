<#
    Copyright (c) 2026 dmj.one
    
    This software is part of the dmj.one initiative.
    Created by Nikhil Bhardwaj.
    
    Licensed under the MIT License.
#>
# Self-elevation: Check if running as Administrator
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Requesting Administrator privileges..." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

<#
.SYNOPSIS
    Complete Development Environment Bootstrap for Windows 11
    Installs Java, C, C++, Python, MySQL and all required connectors

.DESCRIPTION
    This script will install and configure:
    - Chocolatey Package Manager
    - Java Development Kit (JDK 21)
    - MinGW-w64 (GCC/G++ for C/C++)
    - Python 3.12+
    - MySQL Server and MySQL Workbench
    - MySQL Connectors for all languages
    - All required environment variables

.NOTES
    File Name      : install-dev-environment.ps1
    Author         : Development Bootstrap System
    Prerequisite   : Windows 11, Administrator privileges
    
.EXAMPLE
    Right-click and "Run with PowerShell as Administrator"
    OR
    powershell -ExecutionPolicy Bypass -File install-dev-environment.ps1
#>

# ============================================
# CONFIGURATION
# ============================================
$ErrorActionPreference = "Continue"
$ProgressPreference = 'SilentlyContinue'

# Colors for output
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Header($text) {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "  $text" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Success($text) {
    Write-Host "[SUCCESS] $text" -ForegroundColor Green
}

function Write-Info($text) {
    Write-Host "[INFO] $text" -ForegroundColor Yellow
}

function Write-Error($text) {
    Write-Host "[ERROR] $text" -ForegroundColor Red
}

# Project root and log file
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$LogFile = "$ProjectRoot\logs\installation-log.txt"
if (!(Test-Path "$ProjectRoot\logs")) {
    New-Item -ItemType Directory -Path "$ProjectRoot\logs" -Force | Out-Null
}
Start-Transcript -Path $LogFile -Append

Write-Header "Development Environment Bootstrap for Windows 11"
Write-Host "Starting installation at $(Get-Date)" -ForegroundColor White
Write-Host "This process may take 15-30 minutes depending on your internet speed." -ForegroundColor Yellow
Write-Host ""

# ============================================
# STEP 1: Install Chocolatey Package Manager
# ============================================
Write-Header "Step 1: Installing Chocolatey Package Manager"

if (!(Test-Path "$env:ProgramData\chocolatey\choco.exe")) {
    Write-Info "Chocolatey not found. Installing..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    try {
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        Write-Success "Chocolatey installed successfully!"
    }
    catch {
        Write-Error "Failed to install Chocolatey: $_"
        exit 1
    }
}
else {
    Write-Success "Chocolatey is already installed."
}

# Refresh environment variables
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

# Enable global confirmation to avoid prompts
choco feature enable -n allowGlobalConfirmation

# ============================================
# STEP 2: Install Java Development Kit
# ============================================
Write-Header "Step 2: Installing Java Development Kit (JDK 21)"

# Try to find real java (not Windows Store alias)
$javaExe = Get-Command java -ErrorAction SilentlyContinue | Where-Object { $_.Source -notlike "*WindowsApps*" }
if (!$javaExe) {
    Write-Info "Installing Eclipse Temurin JDK 21..."
    # temurin21 is the reliable package name
    choco install temurin21 -y
    if ($LASTEXITCODE -ne 0) {
        Write-Info "Trying alternative: temurin..."
        choco install temurin -y
    }
    Write-Success "Java JDK installed!"
}
else {
    Write-Success "Java is already installed: $($javaExe.Source)"
}

# Refresh PATH after Java install
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

# Set JAVA_HOME - check multiple possible locations
$javaPaths = @(
    "C:\Program Files\Eclipse Adoptium\jdk-21*",
    "C:\Program Files\OpenJDK\jdk-21",
    "C:\Program Files\Java\jdk-21*",
    "C:\Program Files\Eclipse Adoptium\jdk-*"
)
foreach ($pattern in $javaPaths) {
    $found = Get-ChildItem -Path $pattern -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) {
        [System.Environment]::SetEnvironmentVariable("JAVA_HOME", $found.FullName, "Machine")
        $env:JAVA_HOME = $found.FullName
        Write-Success "JAVA_HOME set to $($found.FullName)"
        break
    }
}

# ============================================
# STEP 3: Install MinGW-w64 (C/C++ Compiler)
# ============================================
Write-Header "Step 3: Installing MinGW-w64 (GCC/G++ for C/C++)"

$gccCheck = Get-Command gcc -ErrorAction SilentlyContinue
if (!$gccCheck) {
    Write-Info "Installing MinGW-w64..."
    choco install mingw -y
    Write-Success "MinGW-w64 installed!"
}
else {
    Write-Success "GCC is already installed: $(gcc --version | Select-Object -First 1)"
}

# ============================================
# STEP 4: Install Python
# ============================================
Write-Header "Step 4: Installing Python 3.12"

# Check for real Python (not Windows Store alias)
$pythonExe = Get-Command python -ErrorAction SilentlyContinue | Where-Object { $_.Source -notlike "*WindowsApps*" }
if (!$pythonExe) {
    Write-Info "Installing Python 3.12..."
    choco install python --version=3.12.0 -y
    if ($LASTEXITCODE -ne 0) {
        Write-Info "Trying alternative python package..."
        choco install python3 -y
    }
    Write-Success "Python installed!"
}
else {
    Write-Success "Python is already installed: $($pythonExe.Source)"
}

# Refresh environment
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

# Install pip packages - with error handling
Write-Info "Installing Python packages (mysql-connector-python, pymysql)..."
try {
    # Find real python executable
    $pythonPaths = @(
        "C:\Python312\python.exe",
        "C:\Python311\python.exe",
        "C:\Python310\python.exe",
        "C:\Program Files\Python312\python.exe",
        "C:\Program Files\Python311\python.exe"
    )
    $realPython = $pythonPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
    
    if ($realPython) {
        & $realPython -m pip install --upgrade pip 2>$null
        & $realPython -m pip install mysql-connector-python pymysql 2>$null
        Write-Success "Python MySQL packages installed!"
    }
    else {
        Write-Info "Python packages will need to be installed after restart."
    }
}
catch {
    Write-Info "Python packages will need to be installed after restart."
}

# ============================================
# STEP 5: Install MySQL Server
# ============================================
Write-Header "Step 5: Installing MySQL Server"

$mysqlCheck = Get-Command mysql -ErrorAction SilentlyContinue
if (!$mysqlCheck) {
    Write-Info "Installing MySQL Server..."
    choco install mysql -y
    Write-Success "MySQL Server installed!"
}
else {
    Write-Success "MySQL is already installed."
}

# Install MySQL Workbench
Write-Info "Installing MySQL Workbench..."
choco install mysql.workbench -y
Write-Success "MySQL Workbench installed!"

# ============================================
# STEP 6: Install MySQL Connector/J (Java)
# ============================================
Write-Header "Step 6: Installing MySQL Connector/J for Java"

$connectorJPath = "$ProjectRoot\lib\mysql-connector-j"
if (!(Test-Path $connectorJPath)) {
    New-Item -ItemType Directory -Path $connectorJPath -Force | Out-Null
}

# Download MySQL Connector/J
$connectorJUrl = "https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-j-8.3.0.zip"
$connectorJZip = "$connectorJPath\mysql-connector-j.zip"

if (!(Test-Path "$connectorJPath\mysql-connector-j-8.3.0\mysql-connector-j-8.3.0.jar")) {
    Write-Info "Downloading MySQL Connector/J..."
    try {
        Invoke-WebRequest -Uri $connectorJUrl -OutFile $connectorJZip -UseBasicParsing
        Expand-Archive -Path $connectorJZip -DestinationPath $connectorJPath -Force
        Remove-Item $connectorJZip -Force
        Write-Success "MySQL Connector/J downloaded and extracted!"
    }
    catch {
        Write-Info "Using alternative: Installing via Chocolatey..."
        choco install mysql-connector -y 2>$null
    }
}
else {
    Write-Success "MySQL Connector/J is already installed."
}

# ============================================
# STEP 7: Install MySQL Connector/C (C/C++)
# ============================================
Write-Header "Step 7: Installing MySQL Connector/C for C/C++"

$connectorCPath = "$ProjectRoot\lib\mysql-connector-c"
if (!(Test-Path $connectorCPath)) {
    New-Item -ItemType Directory -Path $connectorCPath -Force | Out-Null
}

# MySQL Connector/C is included with MySQL Server
# We'll set up the paths
$mysqlPath = "C:\tools\mysql\current"
if (Test-Path $mysqlPath) {
    $includePath = "$mysqlPath\include"
    $libPath = "$mysqlPath\lib"
    
    # Set environment variables for C/C++ compilation
    [System.Environment]::SetEnvironmentVariable("MYSQL_INCLUDE", $includePath, "Machine")
    [System.Environment]::SetEnvironmentVariable("MYSQL_LIB", $libPath, "Machine")
    $env:MYSQL_INCLUDE = $includePath
    $env:MYSQL_LIB = $libPath
    
    Write-Success "MySQL C/C++ connector paths configured!"
    Write-Info "MYSQL_INCLUDE: $includePath"
    Write-Info "MYSQL_LIB: $libPath"
}
else {
    Write-Info "MySQL path not found at default location. Will need manual configuration."
}

# ============================================
# STEP 8: Configure MySQL Service
# ============================================
Write-Header "Step 8: Configuring MySQL Service"

# Check if MySQL service exists and start it
$mysqlService = Get-Service -Name "MySQL*" -ErrorAction SilentlyContinue
if ($mysqlService) {
    if ($mysqlService.Status -ne "Running") {
        Write-Info "Starting MySQL service..."
        Start-Service $mysqlService.Name
    }
    Write-Success "MySQL service is running!"
}
else {
    Write-Info "MySQL service not found. You may need to initialize MySQL manually."
}

# ============================================
# STEP 9: Install Additional Tools
# ============================================
Write-Header "Step 9: Installing Additional Development Tools"

# Install Git
$gitCheck = Get-Command git -ErrorAction SilentlyContinue
if (!$gitCheck) {
    Write-Info "Installing Git..."
    choco install git -y
    Write-Success "Git installed!"
}
else {
    Write-Success "Git is already installed."
}

# Install Visual Studio Code (optional but useful)
$codeCheck = Get-Command code -ErrorAction SilentlyContinue
if (!$codeCheck) {
    Write-Info "Installing Visual Studio Code..."
    choco install vscode -y
    Write-Success "VS Code installed!"
}
else {
    Write-Success "VS Code is already installed."
}

# ============================================
# STEP 10: Refresh Environment Variables
# ============================================
Write-Header "Step 10: Refreshing Environment Variables"

# Refresh PATH
$machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
$userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
$env:Path = "$machinePath;$userPath"

# Add MinGW to PATH if not already there
$mingwBin = "C:\ProgramData\mingw64\mingw64\bin"
$mingwBin2 = "C:\ProgramData\chocolatey\lib\mingw\tools\install\mingw64\bin"

foreach ($path in @($mingwBin, $mingwBin2)) {
    if ((Test-Path $path) -and ($env:Path -notlike "*$path*")) {
        $env:Path += ";$path"
        $currentPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
        [System.Environment]::SetEnvironmentVariable("Path", "$currentPath;$path", "Machine")
        Write-Success "Added $path to PATH"
    }
}

Write-Success "Environment variables refreshed!"

# ============================================
# STEP 11: Create Test Database
# ============================================
Write-Header "Step 11: Setting Up Test Database"

# Create SQL setup script
$sqlSetup = @"
-- Create test database
CREATE DATABASE IF NOT EXISTS testdb;
USE testdb;

-- Create test table
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO users (name, email) VALUES 
    ('John Doe', 'john@example.com'),
    ('Jane Smith', 'jane@example.com'),
    ('Bob Wilson', 'bob@example.com');

-- Create test user for applications
CREATE USER IF NOT EXISTS 'testuser'@'localhost' IDENTIFIED BY 'testpass123';
GRANT ALL PRIVILEGES ON testdb.* TO 'testuser'@'localhost';
FLUSH PRIVILEGES;

SELECT 'Database setup completed successfully!' AS status;
"@

$sqlSetup | Out-File -FilePath "$ProjectRoot\database\setup-database.sql" -Encoding UTF8
Write-Success "Database setup script created!"
Write-Info "Run the database\setup-database.sql script in MySQL to create the test database."

# ============================================
# FINAL: Summary and Next Steps
# ============================================
Write-Header "Installation Complete!"

Write-Host ""
Write-Host "Installed Components:" -ForegroundColor Green
Write-Host "  [*] Chocolatey Package Manager" -ForegroundColor White
Write-Host "  [*] Java Development Kit (JDK 21)" -ForegroundColor White
Write-Host "  [*] MinGW-w64 (GCC/G++ Compiler)" -ForegroundColor White
Write-Host "  [*] Python 3.12" -ForegroundColor White
Write-Host "  [*] MySQL Server" -ForegroundColor White
Write-Host "  [*] MySQL Workbench" -ForegroundColor White
Write-Host "  [*] MySQL Connectors (Java, Python)" -ForegroundColor White
Write-Host "  [*] Git" -ForegroundColor White
Write-Host "  [*] Visual Studio Code" -ForegroundColor White
Write-Host ""

Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. RESTART YOUR TERMINAL/COMPUTER to apply PATH changes" -ForegroundColor White
Write-Host "  2. Initialize MySQL:" -ForegroundColor White
Write-Host "     mysqld --initialize-insecure" -ForegroundColor Cyan
Write-Host "     mysqld --install" -ForegroundColor Cyan
Write-Host "     net start mysql" -ForegroundColor Cyan
Write-Host "  3. Set MySQL root password:" -ForegroundColor White
Write-Host "     mysql -u root" -ForegroundColor Cyan
Write-Host "     ALTER USER 'root'@'localhost' IDENTIFIED BY 'your_password';" -ForegroundColor Cyan
Write-Host "  4. Run the test database setup:" -ForegroundColor White
Write-Host "     mysql -u root -p < database\setup-database.sql" -ForegroundColor Cyan
Write-Host "  5. Run the verification script:" -ForegroundColor White
Write-Host "     .\VERIFY.bat" -ForegroundColor Cyan
Write-Host "  6. Run sample programs to test each language" -ForegroundColor White
Write-Host ""

Write-Host "Log file saved to: $LogFile" -ForegroundColor Gray
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray

Stop-Transcript

$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

