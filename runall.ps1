<#
.SYNOPSIS
    Universal Code Runner - Automatically compiles and runs any programming language file.

.DESCRIPTION
    This script detects the programming language from the file extension,
    compiles if necessary (C, C++, Java), and runs the code.
    
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

.PARAMETER Args
    Optional arguments to pass to the program.

.PARAMETER KeepExe
    If specified, keeps the compiled executable (for C/C++).

.PARAMETER MySQLUser
    MySQL username for SQL files (default: root).

.PARAMETER MySQLPass
    MySQL password for SQL files.

.EXAMPLE
    .\runall.ps1 hello.py
    .\runall.ps1 MyProgram.java
    .\runall.ps1 test.c
    .\runall.ps1 query.sql -MySQLUser root -MySQLPass mypassword
#>

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$FilePath,
    
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$Args,
    
    [switch]$KeepExe,
    
    [string]$MySQLUser = "root",
    
    [string]$MySQLPass = ""
)

# ============================================
# CONFIGURATION
# ============================================
$ErrorActionPreference = "Stop"

# Color output helpers
function Write-Success($text) { Write-Host "[SUCCESS] $text" -ForegroundColor Green }
function Write-Info($text) { Write-Host "[INFO] $text" -ForegroundColor Cyan }
function Write-Warn($text) { Write-Host "[WARN] $text" -ForegroundColor Yellow }
function Write-Err($text) { Write-Host "[ERROR] $text" -ForegroundColor Red }

function Write-Header($text) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host "  $text" -ForegroundColor Magenta
    Write-Host "========================================" -ForegroundColor Magenta
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
            "C:\Python312\python.exe",
            "C:\Python311\python.exe",
            "C:\Python310\python.exe",
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
        & $pythonExe $File.FullName $Args
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
        } else {
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
            $connectorPaths = @(
                "$PSScriptRoot\lib\mysql-connector-j\mysql-connector-j-8.3.0\mysql-connector-j-8.3.0.jar",
                "$PSScriptRoot\lib\mysql-connector-j-8.3.0.jar",
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
            & java -cp $classpath $className $Args
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
            } else {
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
        & $exePath $Args
        $exitCode = $LASTEXITCODE
        
        # Cleanup
        if (-not $KeepExe -and (Test-Path $exePath)) {
            Remove-Item $exePath -Force -ErrorAction SilentlyContinue
        }
    }
    
    # ----------------------------------------
    # C++
    # ----------------------------------------
    {$_ -in ".cpp", ".cxx", ".cc"} {
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
            } else {
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
        & $exePath $Args
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
        & node $File.FullName $Args
        $exitCode = $LASTEXITCODE
    }
    
    # ----------------------------------------
    # POWERSHELL
    # ----------------------------------------
    ".ps1" {
        Write-Info "Language: PowerShell"
        Write-Host ""
        Write-Host "----------------------------------------" -ForegroundColor Gray
        & powershell -ExecutionPolicy Bypass -File $File.FullName $Args
        $exitCode = $LASTEXITCODE
    }
    
    # ----------------------------------------
    # BATCH
    # ----------------------------------------
    {$_ -in ".bat", ".cmd"} {
        Write-Info "Language: Batch Script"
        Write-Host ""
        Write-Host "----------------------------------------" -ForegroundColor Gray
        & cmd /c $File.FullName $Args
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
        
        Write-Host ""
        Write-Host "----------------------------------------" -ForegroundColor Gray
        
        if ($MySQLPass) {
            & mysql -u $MySQLUser -p"$MySQLPass" -e "source $($File.FullName)"
        } else {
            Write-Info "No password provided. Trying without password..."
            & mysql -u $MySQLUser -e "source $($File.FullName)" 2>$null
            if ($LASTEXITCODE -ne 0) {
                Write-Info "Failed. Prompting for password..."
                & mysql -u $MySQLUser -p -e "source $($File.FullName)"
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
} else {
    Write-Err "Execution failed with exit code: $exitCode (${duration}s)"
}

exit $exitCode
