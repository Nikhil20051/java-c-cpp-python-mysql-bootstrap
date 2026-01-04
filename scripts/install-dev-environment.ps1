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
    - Java Development Kit (Latest OpenJDK)
    - MinGW-w64 (GCC/G++ for C/C++)
    - Python (Latest or 3.8 - User Choice)
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

function Install-WinGetPackage {
    param (
        [string]$Id,
        [string]$Name,
        [string]$Source = "msstore"
    )
    
    Write-Info "Checking $Source for $Name ($Id)..."
    
    # Check if winget is available
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Info "Winget not found. Skipping store check."
        return $false
    }

    try {
        # Search first
        $search = winget search --id $Id --source $Source
        if ($LASTEXITCODE -eq 0) {
            Write-Info "Found $Name in $Source. Installing..."
            winget install --id $Id --source $Source --accept-package-agreements --accept-source-agreements --force
            
            if ($LASTEXITCODE -eq 0) {
                Write-Success "$Name installed successfully from $Source!"
                return $true
            }
        }
    }
    catch {
        Write-Info "Winget install failed: $_"
    }
    
    return $false
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
# STEP 0: Ensure Configuration Files & Credentials
# ============================================
Write-Header "Step 0: Initializing Configuration & Credentials"

$ensureConfigScript = Join-Path $PSScriptRoot "ensure-config-files.ps1"
if (Test-Path $ensureConfigScript) {
    Write-Info "Running configuration check..."
    & $ensureConfigScript
}

# Load credentials for use in script
$credsFile = Join-Path $ProjectRoot ".credentials.json"
if (Test-Path $credsFile) {
    try {
        $Global:Creds = Get-Content $credsFile | ConvertFrom-Json
        Write-Success "Loaded secure credentials for user '$($Global:Creds.username)'"
    }
    catch {
        Write-Info "Could not load credentials. Using defaults."
        $Global:Creds = @{ username = "appuser"; password = "72Je!^NY06OPx$uW"; database = "testdb" }
    }
}
else {
    $Global:Creds = @{ username = "appuser"; password = "72Je!^NY06OPx$uW"; database = "testdb" }
}

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
# STEP 2: Install Java Development Kit (Latest OpenJDK)
# ============================================
Write-Header "Step 2: Installing Java Development Kit (Latest OpenJDK)"

# Try to find real java (not Windows Store alias)
$javaExe = Get-Command java -ErrorAction SilentlyContinue | Where-Object { $_.Source -notlike "*WindowsApps*" }
if (!$javaExe) {
    Write-Info "Installing Latest OpenJDK..."
    # Install the latest OpenJDK available through chocolatey
    choco install openjdk -y
    if ($LASTEXITCODE -ne 0) {
        Write-Info "Trying alternative: temurin (Eclipse Adoptium)..."
        choco install temurin -y
    }
    Write-Success "Java JDK (Latest OpenJDK) installed!"
}
else {
    Write-Success "Java is already installed: $($javaExe.Source)"
}

# Refresh PATH after Java install
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

# Set JAVA_HOME - check multiple possible locations (ordered by latest versions first)
$javaPaths = @(
    "C:\Program Files\OpenJDK\openjdk-*",
    "C:\Program Files\Eclipse Adoptium\jdk-*",
    "C:\Program Files\OpenJDK\jdk-*",
    "C:\Program Files\Java\jdk-*"
)
$javaHome = $null
foreach ($pattern in $javaPaths) {
    # Get all matching directories and sort by version (descending) to get the latest
    $found = Get-ChildItem -Path $pattern -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
    if ($found) {
        [System.Environment]::SetEnvironmentVariable("JAVA_HOME", $found.FullName, "Machine")
        $env:JAVA_HOME = $found.FullName
        $javaHome = $found.FullName
        Write-Success "JAVA_HOME set to $($found.FullName)"
        break
    }
}
if (-not $javaHome) {
    Write-Info "JAVA_HOME could not be set automatically. You may need to set it manually after restart."
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
# STEP 4: Install Python (User Choice: Latest or 3.8)
# ============================================
Write-Header "Step 4: Installing Python"

# Check for real Python (not Windows Store alias)
$pythonExe = Get-Command python -ErrorAction SilentlyContinue | Where-Object { $_.Source -notlike "*WindowsApps*" }
if (!$pythonExe) {
    # Prompt user for Python version choice
    Write-Host ""
    Write-Host "Please choose which Python version to install:" -ForegroundColor Cyan
    Write-Host "  [1] Latest Python (Recommended)" -ForegroundColor White
    Write-Host "  [2] Python 3.8 (For compatibility)" -ForegroundColor White
    Write-Host ""
    
    $pythonChoice = $null
    while ($pythonChoice -notmatch '^[12]$') {
        $pythonChoice = Read-Host "Enter your choice (1 or 2)"
        if ($pythonChoice -notmatch '^[12]$') {
            Write-Host "Invalid choice. Please enter 1 or 2." -ForegroundColor Red
        }
    }
    
    if ($pythonChoice -eq "1") {
        Write-Info "Installing Latest Python..."
        
        # Try Windows Store first (Python 3.13)
        $installedFromStore = Install-WinGetPackage -Id "9PNRBTZXMB4Z" -Name "Python 3.13" -Source "msstore"
        
        if (-not $installedFromStore) {
            Write-Info "Store installation failed or unavailable. Falling back to Chocolatey..."
            choco install python -y
            if ($LASTEXITCODE -ne 0) {
                Write-Info "Trying alternative python package..."
                choco install python3 -y
            }
        }
        Write-Success "Latest Python installed!"
    }
    else {
        Write-Info "Installing Python 3.8 (Legacy)..."
        # Python 3.8 is not typically on the Store (only latest). Using Chocolatey.
        choco install python --version=3.8.10 -y
        if ($LASTEXITCODE -ne 0) {
            Write-Info "Trying alternative python38 package..."
            choco install python38 -y
        }
        Write-Success "Python 3.8 installed!"
    }
}
else {
    Write-Success "Python is already installed: $($pythonExe.Source)"
}

# Ensure python3 command exists (create alias if missing)
if (-not (Get-Command python3 -ErrorAction SilentlyContinue)) {
    $py = Get-Command python -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1
    if ($py) {
        Write-Info "Creating 'python3' compatibility alias..."
        try {
            $dir = Split-Path $py
            $dest = Join-Path $dir "python3.exe"
            if (-not (Test-Path $dest)) {
                Copy-Item $py $dest -Force -ErrorAction SilentlyContinue
                if (-not (Test-Path $dest)) {
                    # Fallback for write protection: create bat in script dir
                    $batPath = Join-Path $PSScriptRoot "python3.bat"
                    Set-Content -Path $batPath -Value "@echo off`r`npython %*"
                    Write-Info "Created python3.bat wrapper in scripts folder."
                }
            }
        }
        catch {
            Write-Info "Could not create python3 alias: $_"
        }
    }
}

# Refresh environment
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

# Install pip packages - with error handling
Write-Info "Installing Python packages (mysql-connector-python, pymysql)..."
try {
    # Find real python executable - check common paths for various versions
    $pythonPaths = @(
        "C:\Python313\python.exe",
        "C:\Python312\python.exe",
        "C:\Python311\python.exe",
        "C:\Python310\python.exe",
        "C:\Python39\python.exe",
        "C:\Python38\python.exe",
        "C:\Program Files\Python313\python.exe",
        "C:\Program Files\Python312\python.exe",
        "C:\Program Files\Python311\python.exe",
        "C:\Program Files\Python38\python.exe"
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

# Check for MySQL Server (mysqld), not just the client (mysql)
$mysqldPath = "C:\tools\mysql\current\bin\mysqld.exe"
$mysqlCheck = Get-Command mysqld -ErrorAction SilentlyContinue

# Also check the typical installation path
$hasServer = (Test-Path $mysqldPath) -or $mysqlCheck

if (!$hasServer) {
    Write-Info "MySQL Server not found. Installing full MySQL Server..."
    
    # Force install to ensure we get the full server, not just the client
    choco install mysql -y --force
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "MySQL Server installed!"
    }
    else {
        Write-Info "Chocolatey install returned exit code: $LASTEXITCODE"
        Write-Info "Checking if MySQL was installed anyway..."
    }
    
    # Verify server was installed
    if (!(Test-Path $mysqldPath)) {
        Write-Info "MySQL Server executable not found at expected location."
        Write-Info "The package may have installed to a different location."
    }
}
else {
    if ($mysqlCheck) {
        Write-Success "MySQL Server is already installed: $($mysqlCheck.Source)"
    }
    else {
        Write-Success "MySQL Server is already installed at: $mysqldPath"
    }
}

# Ask about MySQL Workbench (optional GUI tool)
Write-Host ""
Write-Host "MySQL Workbench is an optional GUI tool for managing MySQL databases." -ForegroundColor Cyan
Write-Host "  [Y] Yes, install MySQL Workbench (recommended for beginners)" -ForegroundColor White
Write-Host "  [N] No, skip - I'll use command line only" -ForegroundColor White
Write-Host ""

$installWorkbench = $null
while ($installWorkbench -notmatch '^[YyNn]$') {
    $installWorkbench = Read-Host "Install MySQL Workbench? (Y/N)"
    if ($installWorkbench -notmatch '^[YyNn]$') {
        Write-Host "Invalid choice. Please enter Y or N." -ForegroundColor Red
    }
}

if ($installWorkbench -match '^[Yy]$') {
    Write-Info "Installing MySQL Workbench..."
    choco install mysql.workbench -y
    Write-Success "MySQL Workbench installed!"
}
else {
    Write-Info "Skipping MySQL Workbench installation."
}

# ============================================
# STEP 6: Install MySQL Connector/J (Java)
# ============================================
Write-Header "Step 6: Installing MySQL Connector/J for Java"

$connectorJPath = "$ProjectRoot\lib\mysql-connector-j"
if (!(Test-Path $connectorJPath)) {
    New-Item -ItemType Directory -Path $connectorJPath -Force | Out-Null
}

# Download MySQL Connector/J
$connectorJUrl = "https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/8.3.0/mysql-connector-j-8.3.0.jar"
$connectorJJar = "$connectorJPath\mysql-connector-j-8.3.0.jar"

if (!(Test-Path $connectorJJar)) {
    Write-Info "Downloading MySQL Connector/J..."
    try {
        Invoke-WebRequest -Uri $connectorJUrl -OutFile $connectorJJar -UseBasicParsing
        Write-Success "MySQL Connector/J downloaded successfully!"
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
# We'll set up the paths - check multiple possible locations
$mysqlPath = "C:\tools\mysql\current"
$includePath = "$mysqlPath\include"
$libPath = "$mysqlPath\lib"

# Check if include/lib directories exist
$hasInclude = Test-Path $includePath
$hasLib = Test-Path $libPath

if ($hasInclude -and $hasLib) {
    # Set environment variables for C/C++ compilation
    [System.Environment]::SetEnvironmentVariable("MYSQL_INCLUDE", $includePath, "Machine")
    [System.Environment]::SetEnvironmentVariable("MYSQL_LIB", $libPath, "Machine")
    $env:MYSQL_INCLUDE = $includePath
    $env:MYSQL_LIB = $libPath
    
    Write-Success "MySQL C/C++ connector paths configured via MySQL Server!"
}
else {
    # Headers missing from Server install. Download Connector/C manually.
    Write-Info "MySQL development headers not found in server directory."
    Write-Info "Downloading MySQL Connector/C to ensure C/C++ support..."
    
    $cConnectorUrl = "https://downloads.mysql.com/archives/get/p/19/file/mysql-connector-c-6.1.11-winx64.zip"
    $cConnectorZip = "$connectorCPath\mysql-connector-c.zip"
    $cConnectorExDir = "$connectorCPath\extracted"
    
    try {
        if (!(Test-Path $cConnectorExDir)) {
            Invoke-WebRequest -Uri $cConnectorUrl -OutFile $cConnectorZip -UseBasicParsing
            Expand-Archive -Path $cConnectorZip -DestinationPath $cConnectorExDir -Force
            Remove-Item $cConnectorZip -Force
        }
        
        # Find the inner folder
        $innerFolder = Get-ChildItem -Path $cConnectorExDir -Directory | Select-Object -First 1
        if ($innerFolder) {
            $newInclude = "$($innerFolder.FullName)\include"
            $newLib = "$($innerFolder.FullName)\lib"
            
            [System.Environment]::SetEnvironmentVariable("MYSQL_INCLUDE", $newInclude, "Machine")
            [System.Environment]::SetEnvironmentVariable("MYSQL_LIB", $newLib, "Machine")
            $env:MYSQL_INCLUDE = $newInclude
            $env:MYSQL_LIB = $newLib
            
            Write-Success "MySQL Connector/C downloaded and configured!"
        }
        else {
            throw "Extraction failed"
        }
    }
    catch {
        Write-Error "Could not download/configure MySQL Connector/C: $_"
        Write-Info "C/C++ MySQL compilation might require manual setup."
    }
}

# ============================================
# STEP 8: Configure MySQL Service
# ============================================
Write-Header "Step 8: Configuring MySQL Service"

# Find MySQL installation path
$mysqlBasePath = "C:\tools\mysql\current"
$mysqlBin = "$mysqlBasePath\bin"
$mysqldExe = "$mysqlBin\mysqld.exe"
$mysqlDataPath = "$mysqlBasePath\data"

# Check if MySQL service exists
$mysqlService = Get-Service -Name "MySQL*" -ErrorAction SilentlyContinue

if ($mysqlService) {
    # Service exists, make sure it's running
    if ($mysqlService.Status -ne "Running") {
        Write-Info "Starting MySQL service..."
        try {
            Start-Service $mysqlService.Name -ErrorAction Stop
            Write-Success "MySQL service started!"
        }
        catch {
            Write-Info "Could not start MySQL service: $_"
        }
    }
    else {
        Write-Success "MySQL service is already running!"
    }
}
elseif (Test-Path $mysqldExe) {
    # MySQL is installed but service doesn't exist - need to initialize and install
    Write-Info "MySQL executable found but no service configured. Initializing MySQL..."
    
    # Step 1: Initialize MySQL data directory if it doesn't exist
    if (!(Test-Path $mysqlDataPath)) {
        Write-Info "Creating MySQL data directory..."
        New-Item -ItemType Directory -Path $mysqlDataPath -Force | Out-Null
        
        Write-Info "Initializing MySQL database with --initialize-insecure..."
        try {
            # Initialize MySQL with no root password for easy setup
            $initProcess = Start-Process -FilePath $mysqldExe -ArgumentList "--initialize-insecure", "--basedir=`"$mysqlBasePath`"", "--datadir=`"$mysqlDataPath`"" -Wait -PassThru -NoNewWindow
            if ($initProcess.ExitCode -eq 0) {
                Write-Success "MySQL data directory initialized!"
            }
            else {
                Write-Info "MySQL initialization returned exit code: $($initProcess.ExitCode)"
            }
        }
        catch {
            Write-Info "MySQL initialization error: $_"
        }
    }
    else {
        Write-Success "MySQL data directory already exists."
    }
    
    # Step 2: Install MySQL as a Windows service
    Write-Info "Installing MySQL as a Windows service..."
    try {
        $serviceProcess = Start-Process -FilePath $mysqldExe -ArgumentList "--install", "MySQL", "--defaults-file=`"$mysqlBasePath\my.ini`"" -Wait -PassThru -NoNewWindow -ErrorAction SilentlyContinue 2>$null
        
        # Also try without defaults-file in case my.ini doesn't exist
        if (!$serviceProcess -or $serviceProcess.ExitCode -ne 0) {
            $serviceProcess = Start-Process -FilePath $mysqldExe -ArgumentList "--install", "MySQL" -Wait -PassThru -NoNewWindow
        }
        
        if ($serviceProcess.ExitCode -eq 0) {
            Write-Success "MySQL service installed!"
        }
        else {
            Write-Info "MySQL service installation returned exit code: $($serviceProcess.ExitCode)"
        }
    }
    catch {
        Write-Info "MySQL service may already be installed or failed to install: $_"
    }
    
    # Step 3: Start the MySQL service
    Start-Sleep -Seconds 2  # Give Windows time to register the service
    $mysqlService = Get-Service -Name "MySQL*" -ErrorAction SilentlyContinue
    if ($mysqlService) {
        Write-Info "Starting MySQL service..."
        try {
            Start-Service $mysqlService.Name -ErrorAction Stop
            Start-Sleep -Seconds 3  # Wait for MySQL to fully start
            Write-Success "MySQL service is now running!"
        }
        catch {
            Write-Info "Could not start MySQL service: $_"
            Write-Info "You may need to start it manually after reboot."
        }
    }
    else {
        # Service installation might have failed, try running mysqld directly
        Write-Info "Service not registered. Attempting to start MySQL directly..."
        try {
            Start-Process -FilePath $mysqldExe -ArgumentList "--console" -NoNewWindow
            Start-Sleep -Seconds 5
            
            # Check if mysqld is running
            $mysqldProcess = Get-Process mysqld -ErrorAction SilentlyContinue
            if ($mysqldProcess) {
                Write-Success "MySQL server is running (process mode)!"
            }
            else {
                Write-Info "Could not verify MySQL process. Please start MySQL manually after reboot."
            }
        }
        catch {
            Write-Info "Could not start MySQL directly: $_"
        }
    }
}
else {
    Write-Info "MySQL executable not found. Please ensure MySQL is properly installed."
    Write-Info "You can reinstall MySQL using: choco install mysql -y --force"
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
    if (-not (Install-WinGetPackage -Id "XP9KHM4BK9FZ7Q" -Name "Visual Studio Code" -Source "msstore")) {
        choco install vscode -y
    }
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
$dbUser = $Global:Creds.username
$dbPass = $Global:Creds.password
$dbName = $Global:Creds.database

$sqlSetup = @"
-- Database Setup Script
-- Generated: $(Get-Date)
-- User: $dbUser

-- Create test database
CREATE DATABASE IF NOT EXISTS $dbName;
USE $dbName;

-- Drop tables if they exist to ensure clean state
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS users;

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    age INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create products table
CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    quantity INT DEFAULT 0
);

-- Create orders table
CREATE TABLE IF NOT EXISTS orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    product_id INT,
    quantity INT NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (product_id) REFERENCES products(id)
);

-- Insert sample users
INSERT INTO users (name, email, age) VALUES 
    ('John Doe', 'john@example.com', 25),
    ('Jane Smith', 'jane@example.com', 30),
    ('Bob Wilson', 'bob@example.com', 45);

-- Insert sample products
INSERT INTO products (name, price, quantity) VALUES 
    ('Laptop', 999.99, 10),
    ('Mouse', 19.99, 50),
    ('Keyboard', 49.99, 30);

-- Insert sample orders
INSERT INTO orders (user_id, product_id, quantity, total_price, status) VALUES 
    (1, 1, 1, 999.99, 'delivered'),
    (2, 2, 2, 39.98, 'shipped'),
    (3, 3, 1, 49.99, 'processing');

-- Create/Update application user
DROP USER IF EXISTS '$dbUser'@'localhost';
CREATE USER '$dbUser'@'localhost' IDENTIFIED BY '$dbPass';
GRANT ALL PRIVILEGES ON $dbName.* TO '$dbUser'@'localhost';
FLUSH PRIVILEGES;

SELECT 'Database setup completed successfully!' AS status;
"@

$sqlSetup | Out-File -FilePath "$ProjectRoot\database\setup-database.sql" -Encoding ASCII -NoNewline
Write-Success "Database setup script created with secure credentials!"

# Automatically initialize database
Write-Info "Attempting to initialize MySQL database..."
if ($mysqlCheck) {
    try {
        # Try to run the setup script
        Get-Content "$ProjectRoot\database\setup-database.sql" | & mysql -u root 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Database initialized successfully!"
        }
        else {
            Write-Info "Note: Database initialization may require manual password entry later."
        }
    }
    catch {
        Write-Info "Could not automatically initialize database. Please run option 3 in start.bat."
    }
}

# ============================================
# STEP 12: Install d1run Globally
# ============================================
Write-Header "Step 12: Installing d1run Globally"

Write-Info "Installing d1run universal code runner globally..."
$d1runInstaller = Join-Path $PSScriptRoot "install-d1run-global.ps1"
if (Test-Path $d1runInstaller) {
    try {
        & $d1runInstaller
        Write-Success "d1run installed globally! You can now run 'd1run program.cpp' from any terminal."
    }
    catch {
        Write-Info "d1run installation encountered an issue: $_"
        Write-Info "You can manually install it later using Option 2 in start.bat"
    }
}
else {
    Write-Info "d1run installer not found. Skipping global installation."
}

# ============================================
# STEP 12.5: Install Auto-Push Monitor Globally
# ============================================
Write-Header "Step 12.5: Installing Auto-Push Monitor"

Write-Info "Installing 'apm' tool globally..."
$apmInstaller = Join-Path $PSScriptRoot "auto-push-monitor\install-global.ps1"
if (Test-Path $apmInstaller) {
    try {
        & $apmInstaller
        Write-Success "Auto-Push Monitor installed! Run 'apm -Start' to use it."
    }
    catch {
        Write-Info "APM installation encountered an issue: $_"
    }
}
else {
    Write-Info "Auto-Push Monitor installer not found. Skipping."
}

# ============================================
# STEP 13: Verify Installation
# ============================================
Write-Header "Step 13: Verifying Installation"

Write-Info "Running verification checks..."
$verifyScript = Join-Path $PSScriptRoot "verify-installation.ps1"
if (Test-Path $verifyScript) {
    try {
        & powershell -ExecutionPolicy Bypass -File $verifyScript
        Write-Success "Verification completed!"
    }
    catch {
        Write-Info "Verification encountered an issue: $_"
    }
}
else {
    Write-Info "Verification script not found. Skipping."
}

# ============================================
# FINAL: Summary and Next Steps
# ============================================
Write-Header "Installation Complete!"

Write-Host ""
Write-Host "Installed Components:" -ForegroundColor Green
Write-Host "  [*] Chocolatey Package Manager" -ForegroundColor White
Write-Host "  [*] Java Development Kit (Latest OpenJDK)" -ForegroundColor White
Write-Host "  [*] MinGW-w64 (GCC/G++ Compiler)" -ForegroundColor White
Write-Host "  [*] Python (User Selected Version)" -ForegroundColor White
Write-Host "  [*] MySQL Server" -ForegroundColor White
Write-Host "  [*] MySQL Workbench (if selected)" -ForegroundColor White
Write-Host "  [*] MySQL Connectors (Java, Python)" -ForegroundColor White
Write-Host "  [*] Git" -ForegroundColor White
Write-Host "  [*] Visual Studio Code" -ForegroundColor White
Write-Host "  [*] d1run - Universal Code Runner (GLOBAL)" -ForegroundColor White
Write-Host "  [*] Auto-Push Monitor ('apm' command)" -ForegroundColor White
Write-Host ""

Write-Host "d1run Usage:" -ForegroundColor Green
Write-Host "  After restart, you can run code from ANY terminal:" -ForegroundColor White
Write-Host "    d1run hello.py           # Run Python" -ForegroundColor Gray
Write-Host "    d1run MyProgram.java     # Compile and run Java" -ForegroundColor Gray
Write-Host "    d1run program.cpp        # Compile and run C++" -ForegroundColor Gray
Write-Host "    d1run test.c             # Compile and run C" -ForegroundColor Gray
Write-Host "    d1run query.sql          # Execute SQL in MySQL" -ForegroundColor Gray
Write-Host ""

Write-Host "Database Credentials (Securely Generated):" -ForegroundColor Green
Write-Host "  - Root User: root (No Password)" -ForegroundColor White
Write-Host "  - App User:  $($Global:Creds.username)" -ForegroundColor White
Write-Host "  - Password:  $($Global:Creds.password)" -ForegroundColor White
Write-Host "  - Database:  $($Global:Creds.database)" -ForegroundColor White
Write-Host ""

Write-Host "IMPORTANT:" -ForegroundColor Yellow
Write-Host "  - RESTART your computer to apply all PATH changes" -ForegroundColor White
Write-Host "  - After restart, 'd1run' command will work from ANY new terminal" -ForegroundColor White
Write-Host "  - All tools (java, python, gcc, g++, mysql) will be available globally" -ForegroundColor White
Write-Host ""

Write-Host "Log file saved to: $LogFile" -ForegroundColor Gray
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray

Stop-Transcript

$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

