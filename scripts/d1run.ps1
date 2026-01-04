<#
    Copyright (c) 2026 dmj.one
    
    This software is part of the dmj.one initiative.
    Created by Nikhil Bhardwaj.
    
    Licensed under the MIT License.
#>
<#
.SYNOPSIS
    d1run - Universal Code Runner - Automatically compiles and runs any programming language file.
    
.DESCRIPTION
    This script detects the programming language from the file extension,
    compiles if necessary (C, C++, Java), and runs the code.
    
    ALL PARAMETERS ARE OPTIONAL. If no file is provided, shows help.
    
    Supported Languages:
    - Python (.py)
    - Java (.java) - auto-detects public class name
    - C (.c)
    - C++ (.cpp, .cxx, .cc)
    - PowerShell (.ps1)
    - Batch (.bat, .cmd)
    - JavaScript/Node.js (.js)
    - SQL (.sql) - executes in MySQL

.PARAMETER FilePath
    Path to the source file to run. Can be relative or absolute.

.PARAMETER Arguments
    Optional arguments to pass to the program as an array or space-separated values.

.PARAMETER KeepExe
    If specified, keeps the compiled executable (for C/C++/Java).

.PARAMETER MySQLUser
    MySQL username for SQL files (default: root).

.PARAMETER MySQLPass
    MySQL password for SQL files (default: empty).

.PARAMETER MySQLHost
    MySQL host for SQL files (default: localhost).

.PARAMETER MySQLPort
    MySQL port for SQL files (default: 3306).

.PARAMETER MySQLDatabase
    MySQL database to use for SQL files.

.PARAMETER Verbose
    Enable verbose output for debugging.

.PARAMETER Help
    Show this help message.

.PARAMETER Version
    Show version information.

.EXAMPLE
    d1run
    d1run hello.py
    d1run MyProgram.java
    d1run test.c -KeepExe
    d1run query.sql -MySQLUser admin -MySQLPass secret -MySQLDatabase testdb
    d1run program.cpp -Arguments "arg1","arg2"
#>

param(
    [Parameter(Position = 0)]
    [string]$FilePath = "",
    
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments = @(),
    
    [Alias("Keep")]
    [switch]$KeepExe,
    
    [string]$MySQLUser = "root",
    
    [string]$MySQLPass = "",
    
    [string]$MySQLHost = "localhost",
    
    [int]$MySQLPort = 3306,
    
    [string]$MySQLDatabase = "",
    
    [switch]$VerboseOutput,
    
    [switch]$Help,
    
    [switch]$Version
)

# ============================================
# CONFIGURATION
# ============================================
$ErrorActionPreference = "Stop"
$ScriptVersion = "1.0.0"
$ScriptName = "d1run"

# Color output helpers
function Write-Success($text) { Write-Host "[SUCCESS] $text" -ForegroundColor Green }
function Write-Info($text) { Write-Host "[INFO] $text" -ForegroundColor Cyan }
function Write-Warn($text) { Write-Host "[WARN] $text" -ForegroundColor Yellow }
function Write-Err($text) { Write-Host "[ERROR] $text" -ForegroundColor Red }
function Write-Debug($text) { if ($VerboseOutput) { Write-Host "[DEBUG] $text" -ForegroundColor DarkGray } }

function Write-Header($text) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host "  $text" -ForegroundColor Magenta
    Write-Host "========================================" -ForegroundColor Magenta
}

function Show-Help {
    Write-Host ''
    Write-Host '╔══════════════════════════════════════════════════════════════════╗' -ForegroundColor Cyan
    Write-Host '║                                                                  ║' -ForegroundColor Cyan
    Write-Host '║   d1run - Universal Code Runner v1.0.0                           ║' -ForegroundColor Cyan
    Write-Host '║   Part of the dmj.one initiative                                 ║' -ForegroundColor Cyan
    Write-Host '║                                                                  ║' -ForegroundColor Cyan
    Write-Host '╚══════════════════════════════════════════════════════════════════╝' -ForegroundColor Cyan
    Write-Host ''
    Write-Host 'USAGE:' -ForegroundColor Yellow
    Write-Host '  d1run [FilePath] [Options]'
    Write-Host ''
    Write-Host 'OPTIONS:' -ForegroundColor Yellow
    Write-Host '  -FilePath [path]       Path to source file - optional positional'
    Write-Host '  -Arguments [args]      Arguments to pass to the program'
    Write-Host '  -KeepExe               Keep compiled executable for C/C++/Java'
    Write-Host '  -MySQLUser             MySQL username - default: root'
    Write-Host '  -MySQLPass             MySQL password - default: empty'
    Write-Host '  -MySQLHost             MySQL host - default: localhost'
    Write-Host '  -MySQLPort [port]      MySQL port - default: 3306'
    Write-Host '  -MySQLDatabase         MySQL database to use'
    Write-Host '  -VerboseOutput         Enable verbose output'
    Write-Host '  -Help                  Show this help message'
    Write-Host '  -Version               Show version information'
    Write-Host ''
    Write-Host 'SUPPORTED LANGUAGES:' -ForegroundColor Yellow
    Write-Host '  .py      - Python'
    Write-Host '  .java    - Java with auto class detection'
    Write-Host '  .c       - C with GCC'
    Write-Host '  .cpp     - C++ with G++'
    Write-Host '  .js      - JavaScript with Node.js'
    Write-Host '  .ps1     - PowerShell'
    Write-Host '  .bat     - Batch Script'
    Write-Host '  .sql     - SQL with MySQL'
    Write-Host ''
    Write-Host 'EXAMPLES:' -ForegroundColor Yellow
    Write-Host '  d1run                              # Show this help'
    Write-Host '  d1run hello.py                     # Run Python script'
    Write-Host '  d1run MyProgram.java               # Compile and run Java'
    Write-Host '  d1run test.c -KeepExe              # Compile C and keep .exe'
    Write-Host '  d1run app.cpp arg1 arg2            # Run C++ with args'
    Write-Host '  d1run query.sql -MySQLUser root -MySQLDatabase mydb'
    Write-Host ''
}

function Show-Version {
    Write-Host ""
    Write-Host "$ScriptName v$ScriptVersion" -ForegroundColor Cyan
    Write-Host "Universal Code Runner - Part of dmj.one initiative"
    Write-Host "Created by Nikhil Bhardwaj"
    Write-Host "Licensed under MIT License"
    Write-Host ""
}

# ============================================
# HANDLE HELP/VERSION/NO ARGS
# ============================================

if ($Help) {
    Show-Help
    exit 0
}

if ($Version) {
    Show-Version
    exit 0
}

if ([string]::IsNullOrWhiteSpace($FilePath)) {
    Show-Help
    exit 0
}

# ============================================
# VALIDATION
# ============================================

# Check if file exists
if (-not (Test-Path $FilePath)) {
    Write-Err "File not found: $FilePath"
    exit 1
}

# Get absolute path and file info
$File = Get-Item $FilePath
$FileName = $File.Name
$FileDir = $File.DirectoryName
$FileBaseName = $File.BaseName
$FileExtension = $File.Extension.ToLower()

Write-Header "Universal Code Runner"
Write-Info "File: $FileName"
Write-Info "Directory: $FileDir"
Write-Debug "Extension: $FileExtension"
Write-Debug "Arguments: $($Arguments -join ', ')"

# ============================================
# LANGUAGE DETECTION & EXECUTION
# ============================================

$startTime = Get-Date

switch ($FileExtension) {
    # ----------------------------------------
    # PYTHON
    # ----------------------------------------
    ".py" {
        Write-Info "Language: Python"
        Write-Host ""
        
        # Find Python executable (avoid Windows Store stub)
        $pythonExe = $null
        $pythonPaths = @(
            "C:\Python313\python.exe",
            "C:\Python312\python.exe",
            "C:\Python311\python.exe",
            "C:\Python310\python.exe",
            "C:\Program Files\Python313\python.exe",
            "C:\Program Files\Python312\python.exe",
            "C:\Program Files\Python311\python.exe"
        )
        foreach ($p in $pythonPaths) {
            if (Test-Path $p) { $pythonExe = $p; break }
        }
        if (-not $pythonExe) {
            $pythonExe = (Get-Command python -ErrorAction SilentlyContinue | Where-Object { $_.Source -notlike "*WindowsApps*" }).Source
        }
        if (-not $pythonExe) {
            Write-Err "Python not found. Please install Python first."
            exit 1
        }
        
        Write-Info "Using: $pythonExe"
        Write-Host "----------------------------------------" -ForegroundColor Gray
        & $pythonExe $File.FullName $Arguments
        $exitCode = $LASTEXITCODE
    }
    
    # ----------------------------------------
    # JAVA
    # ----------------------------------------
    ".java" {
        Write-Info "Language: Java"
        
        # Find javac and java
        $javac = Get-Command javac -ErrorAction SilentlyContinue
        $java = Get-Command java -ErrorAction SilentlyContinue | Where-Object { $_.Source -notlike "*WindowsApps*" }
        
        if (-not $javac) {
            Write-Err "Java compiler (javac) not found. Please install JDK first."
            exit 1
        }
        
        # Parse the file to find the public class name
        $content = Get-Content $File.FullName -Raw
        $classMatch = [regex]::Match($content, 'public\s+class\s+(\w+)')
        
        if ($classMatch.Success) {
            $className = $classMatch.Groups[1].Value
        }
        else {
            # Fallback: use filename as class name
            $className = $FileBaseName
            Write-Warn "Could not find 'public class'. Using filename as class: $className"
        }
        
        Write-Info "Detected class: $className"
        
        # Check for MySQL connector if code uses JDBC
        $usesJDBC = $content -match "java\.sql\." -or $content -match "jdbc:"
        $classpath = "."
        
        if ($usesJDBC) {
            Write-Info "JDBC usage detected, adding MySQL connector to classpath..."
            $projectRoot = Split-Path -Parent $PSScriptRoot
            $connectorPaths = @(
                "$projectRoot\lib\mysql-connector-j\mysql-connector-j-8.3.0\mysql-connector-j-8.3.0.jar",
                "$projectRoot\lib\mysql-connector-j-8.3.0.jar",
                "C:\Program Files\MySQL\Connector J 8.0\mysql-connector-j-8.0.*.jar"
            )
            foreach ($cp in $connectorPaths) {
                $found = Get-ChildItem -Path $cp -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($found) {
                    $classpath = ".;$($found.FullName)"
                    Write-Info "Found connector: $($found.Name)"
                    break
                }
            }
        }
        
        # Compile
        Write-Info "Compiling..."
        Push-Location $FileDir
        try {
            & javac -cp $classpath $FileName 2>&1 | ForEach-Object { Write-Host $_ }
            if ($LASTEXITCODE -ne 0) {
                Write-Err "Compilation failed!"
                Pop-Location
                exit 1
            }
            Write-Success "Compilation successful!"
            
            # Run
            Write-Host ""
            Write-Host "----------------------------------------" -ForegroundColor Gray
            & java -cp $classpath $className $Arguments
            $exitCode = $LASTEXITCODE
            
            # Cleanup .class files
            if (-not $KeepExe) {
                Get-ChildItem -Path $FileDir -Filter "*.class" | Remove-Item -Force -ErrorAction SilentlyContinue
            }
        }
        finally {
            Pop-Location
        }
    }
    
    # ----------------------------------------
    # C
    # ----------------------------------------
    ".c" {
        Write-Info "Language: C"
        
        $gcc = Get-Command gcc -ErrorAction SilentlyContinue
        if (-not $gcc) {
            Write-Err "GCC not found. Please install MinGW first."
            exit 1
        }
        
        $exePath = Join-Path $FileDir "$FileBaseName.exe"
        
        # Check for MySQL usage
        $content = Get-Content $File.FullName -Raw
        $usesMySQL = $content -match "mysql\.h" -or $content -match "mysql_"
        
        $compileArgs = @("-o", $exePath, $File.FullName)
        
        if ($usesMySQL) {
            Write-Info "MySQL usage detected, adding MySQL libraries..."
            $mysqlInclude = $env:MYSQL_INCLUDE
            $mysqlLib = $env:MYSQL_LIB
            if ($mysqlInclude -and $mysqlLib) {
                $compileArgs += @("-I$mysqlInclude", "-L$mysqlLib", "-lmysqlclient")
            }
            else {
                Write-Warn "MYSQL_INCLUDE or MYSQL_LIB not set. Compilation may fail."
            }
        }
        
        # Compile
        Write-Info "Compiling..."
        & gcc @compileArgs 2>&1 | ForEach-Object { Write-Host $_ }
        if ($LASTEXITCODE -ne 0) {
            Write-Err "Compilation failed!"
            exit 1
        }
        Write-Success "Compilation successful!"
        
        # Run
        Write-Host ""
        Write-Host "----------------------------------------" -ForegroundColor Gray
        & $exePath $Arguments
        $exitCode = $LASTEXITCODE
        
        # Cleanup
        if (-not $KeepExe -and (Test-Path $exePath)) {
            Remove-Item $exePath -Force -ErrorAction SilentlyContinue
        }
    }
    
    # ----------------------------------------
    # C++
    # ----------------------------------------
    { $_ -in ".cpp", ".cxx", ".cc" } {
        Write-Info "Language: C++"
        
        $gpp = Get-Command g++ -ErrorAction SilentlyContinue
        if (-not $gpp) {
            Write-Err "G++ not found. Please install MinGW first."
            exit 1
        }
        
        $exePath = Join-Path $FileDir "$FileBaseName.exe"
        
        # Check for MySQL usage
        $content = Get-Content $File.FullName -Raw
        $usesMySQL = $content -match "mysql\.h" -or $content -match "mysql_" -or $content -match "cppconn"
        
        $compileArgs = @("-o", $exePath, $File.FullName, "-std=c++17")
        
        if ($usesMySQL) {
            Write-Info "MySQL usage detected, adding MySQL libraries..."
            $mysqlInclude = $env:MYSQL_INCLUDE
            $mysqlLib = $env:MYSQL_LIB
            if ($mysqlInclude -and $mysqlLib) {
                $compileArgs += @("-I$mysqlInclude", "-L$mysqlLib", "-lmysqlclient")
            }
            else {
                Write-Warn "MYSQL_INCLUDE or MYSQL_LIB not set. Compilation may fail."
            }
        }
        
        # Compile
        Write-Info "Compiling..."
        & g++ @compileArgs 2>&1 | ForEach-Object { Write-Host $_ }
        if ($LASTEXITCODE -ne 0) {
            Write-Err "Compilation failed!"
            exit 1
        }
        Write-Success "Compilation successful!"
        
        # Run
        Write-Host ""
        Write-Host "----------------------------------------" -ForegroundColor Gray
        & $exePath $Arguments
        $exitCode = $LASTEXITCODE
        
        # Cleanup
        if (-not $KeepExe -and (Test-Path $exePath)) {
            Remove-Item $exePath -Force -ErrorAction SilentlyContinue
        }
    }
    
    # ----------------------------------------
    # JAVASCRIPT (Node.js)
    # ----------------------------------------
    ".js" {
        Write-Info "Language: JavaScript (Node.js)"
        
        $node = Get-Command node -ErrorAction SilentlyContinue
        if (-not $node) {
            Write-Err "Node.js not found. Please install Node.js first."
            exit 1
        }
        
        Write-Host ""
        Write-Host "----------------------------------------" -ForegroundColor Gray
        & node $File.FullName $Arguments
        $exitCode = $LASTEXITCODE
    }
    
    # ----------------------------------------
    # POWERSHELL
    # ----------------------------------------
    ".ps1" {
        Write-Info "Language: PowerShell"
        Write-Host ""
        Write-Host "----------------------------------------" -ForegroundColor Gray
        & powershell -ExecutionPolicy Bypass -File $File.FullName $Arguments
        $exitCode = $LASTEXITCODE
    }
    
    # ----------------------------------------
    # BATCH
    # ----------------------------------------
    { $_ -in ".bat", ".cmd" } {
        Write-Info "Language: Batch Script"
        Write-Host ""
        Write-Host "----------------------------------------" -ForegroundColor Gray
        & cmd /c $File.FullName $Arguments
        $exitCode = $LASTEXITCODE
    }
    
    # ----------------------------------------
    # SQL (MySQL)
    # ----------------------------------------
    ".sql" {
        Write-Info "Language: SQL (MySQL)"
        
        $mysql = Get-Command mysql -ErrorAction SilentlyContinue
        if (-not $mysql) {
            Write-Err "MySQL client not found. Please install MySQL first."
            exit 1
        }
        
        Write-Debug "MySQL Host: $MySQLHost"
        Write-Debug "MySQL Port: $MySQLPort"
        Write-Debug "MySQL User: $MySQLUser"
        Write-Debug "MySQL Database: $MySQLDatabase"
        
        Write-Host ""
        Write-Host "----------------------------------------" -ForegroundColor Gray
        
        $mysqlArgs = @("-u", $MySQLUser, "-h", $MySQLHost, "-P", $MySQLPort)
        
        if ($MySQLDatabase) {
            $mysqlArgs += @("-D", $MySQLDatabase)
        }
        
        if ($MySQLPass) {
            $mysqlArgs += @("-p$MySQLPass")
            & mysql @mysqlArgs -e "source $($File.FullName)"
        }
        else {
            Write-Info "No password provided. Trying without password..."
            & mysql @mysqlArgs -e "source $($File.FullName)" 2>$null
            if ($LASTEXITCODE -ne 0) {
                Write-Info "Failed. Prompting for password..."
                $mysqlArgs += @("-p")
                & mysql @mysqlArgs -e "source $($File.FullName)"
            }
        }
        $exitCode = $LASTEXITCODE
    }
    
    # ----------------------------------------
    # UNKNOWN
    # ----------------------------------------
    default {
        Write-Err "Unsupported file type: $FileExtension"
        Write-Host ""
        Write-Host "Supported extensions:" -ForegroundColor Yellow
        Write-Host "  .py      - Python"
        Write-Host "  .java    - Java"
        Write-Host "  .c       - C"
        Write-Host "  .cpp     - C++"
        Write-Host "  .js      - JavaScript (Node.js)"
        Write-Host "  .ps1     - PowerShell"
        Write-Host "  .bat     - Batch Script"
        Write-Host "  .sql     - SQL (MySQL)"
        exit 1
    }
}

# ============================================
# SUMMARY
# ============================================
$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

Write-Host ""
Write-Host "----------------------------------------" -ForegroundColor Gray
if ($exitCode -eq 0) {
    Write-Success "Execution completed successfully! (${duration}s)"
}
else {
    Write-Err "Execution failed with exit code: $exitCode (${duration}s)"
}

exit $exitCode
