<#
    Copyright (c) 2026 dmj.one
    
    This software is part of the dmj.one initiative.
    Created by Nikhil Bhardwaj.
    
    Licensed under the MIT License.
#>
<#
.SYNOPSIS
    Credentials Manager for the development environment.
    Generates, rotates, and manages MySQL credentials securely.

.DESCRIPTION
    This script manages database credentials by:
    - Generating secure random passwords
    - Storing credentials in a local config file (gitignored)
    - Rotating passwords safely with backup/recovery
    - Updating MySQL users with new credentials
    - Updating sample files to use current credentials

.PARAMETER Action
    The action to perform: Init, Rotate, Show, Export, Recover

.PARAMETER Force
    Force regeneration even if credentials exist

.EXAMPLE
    .\credentials-manager.ps1 -Action Init
    .\credentials-manager.ps1 -Action Rotate
    .\credentials-manager.ps1 -Action Show
#>

param(
    [Parameter(Position = 0)]
    [ValidateSet("Init", "Rotate", "Show", "Export", "Recover", "Verify")]
    [string]$Action = "Init",
    
    [switch]$Force
)

$ErrorActionPreference = "Continue"
$ProjectRoot = Split-Path -Parent $PSScriptRoot

# Configuration paths
$CredentialsFile = Join-Path $ProjectRoot ".credentials.json"
$CredentialsBackupDir = Join-Path $ProjectRoot ".credentials-backup"
$EnvFile = Join-Path $ProjectRoot ".env"

# ============================================
# UTILITY FUNCTIONS
# ============================================

function Write-Info($text) {
    Write-Host "[INFO] $text" -ForegroundColor Yellow
}

function Write-Success($text) {
    Write-Host "[SUCCESS] $text" -ForegroundColor Green
}

function Write-ErrorMsg($text) {
    Write-Host "[ERROR] $text" -ForegroundColor Red
}

function Write-Header($text) {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "  $text" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
}

function New-SecurePassword {
    param(
        [int]$Length = 16
    )
    
    # Character sets for password generation
    $uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    $lowercase = 'abcdefghijklmnopqrstuvwxyz'
    $numbers = '0123456789'
    $special = '!@#$%^&*_-+='
    
    $allChars = $uppercase + $lowercase + $numbers + $special
    
    # Ensure at least one of each type
    $password = ""
    $password += $uppercase[(Get-Random -Maximum $uppercase.Length)]
    $password += $lowercase[(Get-Random -Maximum $lowercase.Length)]
    $password += $numbers[(Get-Random -Maximum $numbers.Length)]
    $password += $special[(Get-Random -Maximum $special.Length)]
    
    # Fill the rest randomly
    for ($i = 4; $i -lt $Length; $i++) {
        $password += $allChars[(Get-Random -Maximum $allChars.Length)]
    }
    
    # Shuffle the password
    $charArray = $password.ToCharArray()
    $shuffled = $charArray | Sort-Object { Get-Random }
    return -join $shuffled
}

function Get-Credentials {
    if (Test-Path $CredentialsFile) {
        try {
            $content = Get-Content $CredentialsFile -Raw
            return $content | ConvertFrom-Json
        }
        catch {
            Write-ErrorMsg "Failed to read credentials file: $_"
            return $null
        }
    }
    return $null
}

function Save-Credentials {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Credentials
    )
    
    # Create backup before saving
    if (Test-Path $CredentialsFile) {
        if (!(Test-Path $CredentialsBackupDir)) {
            New-Item -ItemType Directory -Path $CredentialsBackupDir -Force | Out-Null
        }
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupFile = Join-Path $CredentialsBackupDir "credentials_$timestamp.json"
        Copy-Item $CredentialsFile $backupFile -Force
        Write-Info "Backup created: $backupFile"
    }
    
    # Save new credentials
    $json = $Credentials | ConvertTo-Json -Depth 10
    $json | Out-File $CredentialsFile -Encoding UTF8
    
    Write-Success "Credentials saved to $CredentialsFile"
}

function Update-EnvFile {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Credentials
    )
    
    $envContent = @"
# Database Configuration (Auto-generated - DO NOT COMMIT)
# Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

DB_HOST=localhost
DB_PORT=3306
DB_NAME=$($Credentials.database)
DB_USER=$($Credentials.username)
DB_PASSWORD=$($Credentials.password)
DB_ROOT_USER=root
DB_ROOT_PASSWORD=

# For Java
MYSQL_USER=$($Credentials.username)
MYSQL_PASSWORD=$($Credentials.password)
MYSQL_DATABASE=$($Credentials.database)
"@
    
    $envContent | Out-File $EnvFile -Encoding UTF8
    Write-Success ".env file updated"
}

function Update-MySQLUser {
    param(
        [string]$Username,
        [string]$NewPassword,
        [string]$OldPassword = "",
        [string]$Database = "testdb"
    )
    
    Write-Info "Updating MySQL user '$Username' password..."
    
    # Try to find mysql client
    $mysqlPath = $null
    $possiblePaths = @(
        "mysql",
        "C:\tools\mysql\current\bin\mysql.exe",
        "C:\Program Files\MySQL\MySQL Server 9.2\bin\mysql.exe",
        "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe"
    )
    
    foreach ($path in $possiblePaths) {
        if (Get-Command $path -ErrorAction SilentlyContinue) {
            $mysqlPath = $path
            break
        }
        if (Test-Path $path) {
            $mysqlPath = $path
            break
        }
    }
    
    if (!$mysqlPath) {
        Write-ErrorMsg "MySQL client not found. User password will be set on next database setup."
        return $false
    }
    
    # Create SQL commands
    $sql = @"
-- Drop user if exists and recreate with new password
DROP USER IF EXISTS '$Username'@'localhost';
CREATE USER '$Username'@'localhost' IDENTIFIED BY '$NewPassword';
GRANT ALL PRIVILEGES ON $Database.* TO '$Username'@'localhost';
FLUSH PRIVILEGES;
SELECT 'User $Username updated successfully!' AS status;
"@
    
    # Try without password first (fresh install)
    try {
        $result = $sql | & $mysqlPath -u root 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "MySQL user updated successfully!"
            return $true
        }
    }
    catch {}
    
    # If old password is known (rotation scenario with root password)
    if ($OldPassword) {
        try {
            $result = $sql | & $mysqlPath -u root -p"$OldPassword" 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Success "MySQL user updated successfully!"
                return $true
            }
        }
        catch {}
    }
    
    Write-Info "MySQL user will be created/updated on next database setup run."
    return $false
}

function Update-SampleFiles {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Credentials
    )
    
    Write-Header "Updating Sample Files with Credentials"
    
    $username = $Credentials.username
    $password = $Credentials.password
    $database = $Credentials.database
    
    # Update Java sample
    $javaFile = Join-Path $ProjectRoot "samples\java\MySQLTest.java"
    if (Test-Path $javaFile) {
        $content = Get-Content $javaFile -Raw
        # Matches: getEnv("DB_USER", "value")
        $content = $content -replace 'getEnv\("DB_USER", "[^"]*"\)', "getEnv(`"DB_USER`", `"$username`")"
        $content = $content -replace 'getEnv\("DB_PASSWORD", "[^"]*"\)', "getEnv(`"DB_PASSWORD`", `"$password`")"
        $content | Set-Content $javaFile -NoNewline
        Write-Success "Updated: samples\java\MySQLTest.java"
    }
    
    # Update Python sample
    $pythonFile = Join-Path $ProjectRoot "samples\python\mysql_test.py"
    if (Test-Path $pythonFile) {
        $content = Get-Content $pythonFile -Raw
        # Matches: os.getenv('DB_USER', 'value')
        $content = $content -replace "os.getenv\('DB_USER', '[^']*'\)", "os.getenv('DB_USER', '$username')"
        $content = $content -replace "os.getenv\('DB_PASSWORD', '[^']*'\)", "os.getenv('DB_PASSWORD', '$password')"
        $content | Set-Content $pythonFile -NoNewline
        Write-Success "Updated: samples\python\mysql_test.py"
    }
    
    # Update C++ sample
    $cppFile = Join-Path $ProjectRoot "samples\cpp\mysql_test.cpp"
    if (Test-Path $cppFile) {
        $content = Get-Content $cppFile -Raw
        # Matches: getEnv("DB_USER", "value")
        $content = $content -replace 'getEnv\("DB_USER", "[^"]*"\)', "getEnv(`"DB_USER`", `"$username`")"
        # Matches DB_PASSWORD now (was DB_PASS)
        $content = $content -replace 'getEnv\("DB_PASSWORD", "[^"]*"\)', "getEnv(`"DB_PASSWORD`", `"$password`")"
        $content | Set-Content $cppFile -NoNewline
        Write-Success "Updated: samples\cpp\mysql_test.cpp"
    }
    
    # Update C sample
    $cFile = Join-Path $ProjectRoot "samples\c\mysql_test.c"
    if (Test-Path $cFile) {
        $content = Get-Content $cFile -Raw
        # Matches: const char* DEFAULT_USER = "value";
        $content = $content -replace 'const char\* DEFAULT_USER = "[^"]*";', "const char* DEFAULT_USER = `"$username`";"
        $content = $content -replace 'const char\* DEFAULT_PASS = "[^"]*";', "const char* DEFAULT_PASS = `"$password`";"
        $content | Set-Content $cFile -NoNewline
        Write-Success "Updated: samples\c\mysql_test.c"
    }
    
    # Update database setup SQL
    $sqlFile = Join-Path $ProjectRoot "database\setup-database.sql"
    if (Test-Path $sqlFile) {
        $content = Get-Content $sqlFile -Raw
        # Update CREATE USER statement
        $content = $content -replace "CREATE USER IF NOT EXISTS '[^']*'@'localhost' IDENTIFIED BY '[^']*'", "CREATE USER IF NOT EXISTS '$username'@'localhost' IDENTIFIED BY '$password'"
        # Update GRANT statement
        $content = $content -replace "GRANT ALL PRIVILEGES ON [^.]*\.\* TO '[^']*'@'localhost'", "GRANT ALL PRIVILEGES ON $database.* TO '$username'@'localhost'"
        $content | Set-Content $sqlFile -NoNewline
        Write-Success "Updated: database\setup-database.sql"
    }
}

function Update-StartBat {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Credentials
    )
    
    $startBat = Join-Path $ProjectRoot "start.bat"
    if (Test-Path $startBat) {
        $content = Get-Content $startBat -Raw
        # Update App User display
        $content = $content -replace 'App User:\s+\S+\s+\(Password:\s+\S+\)', "App User:  $($Credentials.username) (Password: $($Credentials.password))"
        # Update INFO display
        $content = $content -replace "user '[^']*' with password '[^']*'", "user '$($Credentials.username)' with password '$($Credentials.password)'"
        $content | Set-Content $startBat -NoNewline
        Write-Success "Updated: start.bat"
    }
}

function Update-InstallerScript {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Credentials
    )
    
    $installerFile = Join-Path $ProjectRoot "scripts\install-dev-environment.ps1"
    if (Test-Path $installerFile) {
        $content = Get-Content $installerFile -Raw
        
        # Update the default hardcoded credentials (fallback)
        # Matches: $Global:Creds = @{ username = "..."; password = "..."; database = "..." }
        $pattern = '\$Global:Creds = @\{ username = "[^"]*"; password = "[^"]*"; database = "[^"]*" \}'
        $replacement = "`$Global:Creds = @{ username = `"$($Credentials.username)`"; password = `"$($Credentials.password)`"; database = `"$($Credentials.database)`" }"
        
        if ($content -match $pattern) {
            $content = $content -replace $pattern, $replacement
            $content | Set-Content $installerFile -NoNewline
            Write-Success "Updated: scripts\install-dev-environment.ps1 (Defaults)"
        }
        else {
            Write-Info "Pattern not found in install-dev-environment.ps1 (already updated or structure changed)"
        }
    }
}

# ============================================
# MAIN ACTIONS
# ============================================

function Initialize-Credentials {
    Write-Header "Initializing Credentials"
    
    $existingCreds = Get-Credentials
    
    if ($existingCreds -and !$Force) {
        Write-Info "Credentials already exist. Use -Force to regenerate."
        Write-Host ""
        Write-Host "Current credentials:" -ForegroundColor Cyan
        Write-Host "  Username: $($existingCreds.username)" -ForegroundColor White
        Write-Host "  Password: $($existingCreds.password)" -ForegroundColor White
        Write-Host "  Database: $($existingCreds.database)" -ForegroundColor White
        Write-Host "  Created:  $($existingCreds.created)" -ForegroundColor Gray
        Write-Host "  Version:  $($existingCreds.version)" -ForegroundColor Gray
        return
    }
    
    # Generate new credentials
    $newPassword = New-SecurePassword -Length 16
    
    $credentials = @{
        username    = "appuser"
        password    = $newPassword
        database    = "testdb"
        host        = "localhost"
        port        = 3306
        created     = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        lastRotated = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        version     = 1
    }
    
    # Save credentials
    Save-Credentials -Credentials $credentials
    
    # Update .env file
    Update-EnvFile -Credentials $credentials
    
    # Update all sample files
    Update-SampleFiles -Credentials $credentials
    
    # Update start.bat display
    Update-StartBat -Credentials $credentials
    
    # Update installer script
    Update-InstallerScript -Credentials $credentials
    
    # Try to update MySQL user
    Update-MySQLUser -Username $credentials.username -NewPassword $credentials.password -Database $credentials.database
    
    Write-Header "Credentials Initialized Successfully"
    Write-Host "New credentials have been generated and saved." -ForegroundColor Green
    Write-Host ""
    Write-Host "  Username: $($credentials.username)" -ForegroundColor White
    Write-Host "  Password: $($credentials.password)" -ForegroundColor White
    Write-Host "  Database: $($credentials.database)" -ForegroundColor White
    Write-Host ""
    Write-Host "Files updated:" -ForegroundColor Cyan
    Write-Host "  - .credentials.json (gitignored)" -ForegroundColor Gray
    Write-Host "  - .env (gitignored)" -ForegroundColor Gray
    Write-Host "  - samples/java/MySQLTest.java" -ForegroundColor Gray
    Write-Host "  - samples/python/mysql_test.py" -ForegroundColor Gray
    Write-Host "  - samples/cpp/mysql_test.cpp" -ForegroundColor Gray
    Write-Host "  - database/setup-database.sql" -ForegroundColor Gray
    Write-Host ""
}

function Rotate-Credentials {
    Write-Header "Rotating Credentials"
    
    $existingCreds = Get-Credentials
    
    if (!$existingCreds) {
        Write-Info "No existing credentials found. Running initialization..."
        Initialize-Credentials
        return
    }
    
    $oldPassword = $existingCreds.password
    $oldVersion = if ($existingCreds.version) { $existingCreds.version } else { 0 }
    
    # Generate new password
    $newPassword = New-SecurePassword -Length 16
    
    $credentials = @{
        username         = $existingCreds.username
        password         = $newPassword
        database         = $existingCreds.database
        host             = $existingCreds.host
        port             = $existingCreds.port
        created          = $existingCreds.created
        lastRotated      = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        version          = $oldVersion + 1
        previousPassword = $oldPassword
    }
    
    # Save credentials (this creates a backup)
    Save-Credentials -Credentials $credentials
    
    # Update .env file
    Update-EnvFile -Credentials $credentials
    
    # Update all sample files
    Update-SampleFiles -Credentials $credentials
    
    # Update start.bat display
    Update-StartBat -Credentials $credentials
    
    # Update installer script
    Update-InstallerScript -Credentials $credentials
    
    # Try to update MySQL user
    $mysqlUpdated = Update-MySQLUser -Username $credentials.username -NewPassword $credentials.password -OldPassword $oldPassword -Database $credentials.database
    
    Write-Header "Credentials Rotated Successfully"
    Write-Host "Password has been rotated (Version $oldVersion -> $($credentials.version))" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Username: $($credentials.username)" -ForegroundColor White
    Write-Host "  New Password: $($credentials.password)" -ForegroundColor White
    Write-Host "  Database: $($credentials.database)" -ForegroundColor White
    Write-Host ""
    if (!$mysqlUpdated) {
        Write-Host "[NOTE] MySQL user password not updated. Run database setup (Option 4) to apply." -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "Recovery: Previous password backed up in .credentials-backup/" -ForegroundColor Gray
    Write-Host "         Also stored as 'previousPassword' in credentials file" -ForegroundColor Gray
    Write-Host ""
}

function Show-Credentials {
    Write-Header "Current Credentials"
    
    $creds = Get-Credentials
    
    if (!$creds) {
        Write-ErrorMsg "No credentials found. Run 'credentials-manager.ps1 -Action Init' to create."
        return
    }
    
    Write-Host "  Username: $($creds.username)" -ForegroundColor White
    Write-Host "  Password: $($creds.password)" -ForegroundColor White
    Write-Host "  Database: $($creds.database)" -ForegroundColor White
    Write-Host "  Host:     $($creds.host):$($creds.port)" -ForegroundColor White
    Write-Host ""
    Write-Host "  Created:     $($creds.created)" -ForegroundColor Gray
    Write-Host "  Last Rotated: $($creds.lastRotated)" -ForegroundColor Gray
    Write-Host "  Version:     $($creds.version)" -ForegroundColor Gray
    
    if ($creds.previousPassword) {
        Write-Host ""
        Write-Host "  Previous Password: $($creds.previousPassword)" -ForegroundColor DarkGray
    }
    Write-Host ""
}

function Export-Credentials {
    Write-Header "Export Credentials"
    
    $creds = Get-Credentials
    
    if (!$creds) {
        Write-ErrorMsg "No credentials found."
        return
    }
    
    Write-Host "Copy and paste these environment variables:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "# PowerShell:" -ForegroundColor Gray
    Write-Host "`$env:DB_USER = '$($creds.username)'"
    Write-Host "`$env:DB_PASSWORD = '$($creds.password)'"
    Write-Host "`$env:DB_NAME = '$($creds.database)'"
    Write-Host ""
    Write-Host "# CMD:" -ForegroundColor Gray
    Write-Host "set DB_USER=$($creds.username)"
    Write-Host "set DB_PASSWORD=$($creds.password)"
    Write-Host "set DB_NAME=$($creds.database)"
    Write-Host ""
    Write-Host "# MySQL connection string:" -ForegroundColor Gray
    Write-Host "mysql -u $($creds.username) -p'$($creds.password)' $($creds.database)"
    Write-Host ""
}

function Recover-Credentials {
    Write-Header "Recover Previous Credentials"
    
    if (!(Test-Path $CredentialsBackupDir)) {
        Write-ErrorMsg "No backup directory found."
        return
    }
    
    $backups = Get-ChildItem $CredentialsBackupDir -Filter "*.json" | Sort-Object LastWriteTime -Descending
    
    if ($backups.Count -eq 0) {
        Write-ErrorMsg "No backup files found."
        return
    }
    
    Write-Host "Available backups:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $backups.Count; $i++) {
        $backup = $backups[$i]
        $content = Get-Content $backup.FullName | ConvertFrom-Json
        Write-Host "  [$($i + 1)] $($backup.Name) - Password: $($content.password.Substring(0, 4))..." -ForegroundColor White
    }
    
    Write-Host ""
    $selection = Read-Host "Enter backup number to restore (or 'q' to quit)"
    
    if ($selection -eq 'q') {
        return
    }
    
    $index = [int]$selection - 1
    if ($index -ge 0 -and $index -lt $backups.Count) {
        $backupFile = $backups[$index].FullName
        Copy-Item $backupFile $CredentialsFile -Force
        
        $restored = Get-Credentials
        
        # Update all files with restored credentials
        $credentials = @{
            username     = $restored.username
            password     = $restored.password
            database     = $restored.database
            host         = $restored.host
            port         = $restored.port
            created      = $restored.created
            lastRotated  = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            version      = $restored.version
            restoredFrom = $backups[$index].Name
        }
        
        Update-EnvFile -Credentials $credentials
        Update-SampleFiles -Credentials $credentials
        Update-StartBat -Credentials $credentials
        Update-InstallerScript -Credentials $credentials
        
        Write-Success "Credentials restored from $($backups[$index].Name)"
        Write-Host "Run database setup (Option 4) to apply the restored password to MySQL." -ForegroundColor Yellow
    }
    else {
        Write-ErrorMsg "Invalid selection."
    }
}

function Verify-Credentials {
    Write-Header "Verifying Credentials Configuration"
    
    $allGood = $true
    
    # Check credentials file
    Write-Host "Checking .credentials.json..." -ForegroundColor Yellow -NoNewline
    if (Test-Path $CredentialsFile) {
        $creds = Get-Credentials
        if ($creds -and $creds.username -and $creds.password) {
            Write-Host " OK" -ForegroundColor Green
        }
        else {
            Write-Host " INVALID" -ForegroundColor Red
            $allGood = $false
        }
    }
    else {
        Write-Host " MISSING" -ForegroundColor Red
        $allGood = $false
    }
    
    # Check .env file
    Write-Host "Checking .env file..." -ForegroundColor Yellow -NoNewline
    if (Test-Path $EnvFile) {
        Write-Host " OK" -ForegroundColor Green
    }
    else {
        Write-Host " MISSING" -ForegroundColor Red
        $allGood = $false
    }
    
    # Check sample files for consistent credentials
    Write-Host "Checking sample files consistency..." -ForegroundColor Yellow
    
    if ($creds) {
        $javaFile = Join-Path $ProjectRoot "samples\java\MySQLTest.java"
        if (Test-Path $javaFile) {
            $content = Get-Content $javaFile -Raw
            if ($content -match "DB_PASSWORD = `"$([regex]::Escape($creds.password))`"") {
                Write-Host "  - Java sample: OK" -ForegroundColor Green
            }
            else {
                Write-Host "  - Java sample: OUT OF SYNC" -ForegroundColor Yellow
            }
        }
        
        $pythonFile = Join-Path $ProjectRoot "samples\python\mysql_test.py"
        if (Test-Path $pythonFile) {
            $content = Get-Content $pythonFile -Raw
            if ($content -match "'password': '$([regex]::Escape($creds.password))'") {
                Write-Host "  - Python sample: OK" -ForegroundColor Green
            }
            else {
                Write-Host "  - Python sample: OUT OF SYNC" -ForegroundColor Yellow
            }
        }
    }
    
    Write-Host ""
    if ($allGood) {
        Write-Success "All credentials are properly configured!"
    }
    else {
        Write-ErrorMsg "Some credentials are missing. Run 'credentials-manager.ps1 -Action Init' to fix."
    }
}

# ============================================
# MAIN EXECUTION
# ============================================

switch ($Action) {
    "Init" { Initialize-Credentials }
    "Rotate" { Rotate-Credentials }
    "Show" { Show-Credentials }
    "Export" { Export-Credentials }
    "Recover" { Recover-Credentials }
    "Verify" { Verify-Credentials }
}
