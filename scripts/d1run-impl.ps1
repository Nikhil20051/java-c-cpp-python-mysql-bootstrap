<#
    Copyright (c) 2026 dmj.one
    
    This software is part of the dmj.one initiative.
    Created by Nikhil Bhardwaj.
    
    Licensed under the MIT License.
#>
<#
.SYNOPSIS
    d1run v3.0 - Universal Code Runner with Release Builds by Default
    
.DESCRIPTION
    Simply run: d1run <filename> [arguments]
    
    The script automatically:
    - Detects the language from file extension
    - Compiles with RELEASE/STATIC settings (portable .exe for C/C++)
    - Runs the program with your arguments
    - Keeps the executable for future use
    - Provides detailed error reports with line numbers and suggestions
    
    Supported: Python, Java, C, C++, JavaScript, PowerShell, Batch, SQL

.PARAMETER FilePath
    Path to the source file.

.PARAMETER Arguments
    Arguments passed to your program (not to d1run).

.PARAMETER Clean
    Remove executable after running (by default executables are kept).

.PARAMETER VerboseOutput
    Enable verbose debug output.

.EXAMPLE
    d1run hello.cpp              # Compile and run (portable static build)
    d1run hello.cpp 5 10         # Run with arguments 5 and 10
    d1run add.py 3 4             # Python with arguments
    d1run MyClass.java arg1      # Java with argument
    d1run test.cpp -Clean        # Compile, run, then delete .exe
#>

param(
    [Parameter(Position = 0)]
    [string]$FilePath = "",
    
    [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
    [string[]]$Arguments = @(),
    
    [string]$MySQLUser = "root",
    [string]$MySQLPass = "",
    [string]$MySQLHost = "localhost",
    [int]$MySQLPort = 3306,
    [string]$MySQLDatabase = "",
    
    [switch]$Clean,          # Remove executable after running
    [switch]$VerboseOutput,
    [switch]$Help,
    [switch]$Version
)

# ============================================
# CONFIGURATION
# ============================================
$ErrorActionPreference = "Continue"
$ScriptVersion = "3.1.0"
$ScriptName = "d1run"

# ============================================
# OUTPUT HELPERS
# ============================================
function Write-Success([string]$text) { Write-Host "[SUCCESS] $text" -ForegroundColor Green }
function Write-Info([string]$text) { Write-Host "[INFO] $text" -ForegroundColor Cyan }
function Write-Warn([string]$text) { Write-Host "[WARN] $text" -ForegroundColor Yellow }
function Write-Err([string]$text) { Write-Host "[ERROR] $text" -ForegroundColor Red }
function Write-Dbg([string]$text) { if ($VerboseOutput) { Write-Host "[DEBUG] $text" -ForegroundColor DarkGray } }

function Write-Header([string]$text) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host "  $text" -ForegroundColor Magenta
    Write-Host "========================================" -ForegroundColor Magenta
}

function Write-OutputSeparator {
    Write-Host ""
    Write-Host "----------------------- OUTPUT -----------------------" -ForegroundColor Gray
    Write-Host ""
}

# ============================================
# COMPREHENSIVE ERROR REPORTING
# ============================================
function Format-ErrorReport {
    param(
        [string]$Language,
        [string]$Phase,
        [string]$RawError,
        [string]$FilePath,
        [int]$ExitCode
    )
    
    Write-Host ""
    Write-Host "==================================================================" -ForegroundColor Red
    Write-Host "                         ERROR REPORT                             " -ForegroundColor Red
    Write-Host "==================================================================" -ForegroundColor Red
    Write-Host ""
    
    Write-Host "  Language:    " -NoNewline -ForegroundColor White
    Write-Host "$Language" -ForegroundColor Yellow
    
    Write-Host "  Phase:       " -NoNewline -ForegroundColor White
    Write-Host "$Phase" -ForegroundColor Yellow
    
    Write-Host "  Exit Code:   " -NoNewline -ForegroundColor White
    Write-Host "$ExitCode" -ForegroundColor Yellow
    
    Write-Host "  File:        " -NoNewline -ForegroundColor White
    Write-Host "$FilePath" -ForegroundColor Cyan
    
    Write-Host "  Timestamp:   " -NoNewline -ForegroundColor White
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
    
    Write-Host ""
    Write-Host "------------------------- ERROR DETAILS -------------------------" -ForegroundColor Red
    Write-Host ""
    
    # Parse error and extract line numbers
    $lineNumber = $null
    $columnNumber = $null
    $errorType = ""
    
    if ($RawError) {
        $lines = $RawError -split "`n"
        
        foreach ($line in $lines) {
            $trimmed = $line.Trim()
            if (-not $trimmed) { continue }
            
            # Extract line numbers based on language
            switch ($Language.ToLower()) {
                "python" {
                    if ($trimmed -match 'line (\d+)') {
                        $lineNumber = [int]$Matches[1]
                    }
                    if ($trimmed -match '^(\w+Error|\w+Exception):') {
                        $errorType = ($trimmed -split ":")[0]
                    }
                }
                "java" {
                    if ($trimmed -match '\.java:(\d+):') {
                        $lineNumber = [int]$Matches[1]
                    }
                    if ($trimmed -match '^(Exception|Error|java\.\w+)') {
                        $errorType = "Runtime Exception"
                    }
                }
                "c" {
                    if ($trimmed -match '\.c:(\d+):(\d+):') {
                        $lineNumber = [int]$Matches[1]
                        $columnNumber = [int]$Matches[2]
                    }
                }
                "c++" {
                    if ($trimmed -match '\.(cpp|cxx|cc):(\d+):(\d+):') {
                        $lineNumber = [int]$Matches[2]
                        $columnNumber = [int]$Matches[3]
                    }
                }
                "javascript" {
                    if ($trimmed -match ':(\d+):\d+') {
                        $lineNumber = [int]$Matches[1]
                    }
                }
                "sql" {
                    if ($trimmed -match 'at line (\d+)') {
                        $lineNumber = [int]$Matches[1]
                    }
                }
            }
            
            # Format output with highlighting
            if ($trimmed -match "error|exception|traceback" -and $trimmed -notmatch "erroraction") {
                Write-Host "  >> $trimmed" -ForegroundColor Red
            }
            elseif ($trimmed -match "warning") {
                Write-Host "  !! $trimmed" -ForegroundColor Yellow
            }
            elseif ($trimmed -match "^\s*\^+\s*$") {
                Write-Host "     $trimmed" -ForegroundColor Red
            }
            elseif ($trimmed -match "^\s*at\s+") {
                Write-Host "     $trimmed" -ForegroundColor DarkGray
            }
            else {
                Write-Host "     $trimmed" -ForegroundColor White
            }
        }
    }
    
    # Show line number prominently
    if ($lineNumber) {
        Write-Host ""
        Write-Host "  *** Error Location: LINE $lineNumber" -NoNewline -ForegroundColor Yellow
        if ($columnNumber) {
            Write-Host ", COLUMN $columnNumber" -ForegroundColor Yellow
        }
        else {
            Write-Host "" -ForegroundColor Yellow
        }
    }
    
    Write-Host ""
    Write-Host "------------------------- SUGGESTIONS ---------------------------" -ForegroundColor Cyan
    Write-Host ""
    
    # Get language-specific suggestions
    $suggestions = Get-ErrorSuggestions -Language $Language -RawError $RawError -Phase $Phase
    $i = 1
    foreach ($suggestion in $suggestions) {
        Write-Host "  $i. $suggestion" -ForegroundColor White
        $i++
    }
    
    Write-Host ""
    Write-Host "------------------------- NEED HELP? ----------------------------" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "  If this is a d1run bug, please report it with this information:" -ForegroundColor White
    Write-Host "  GitHub: https://github.com/Nikhil20051/java-c-cpp-python-mysql-bootstrap/issues" -ForegroundColor Gray
    Write-Host "  Include: Error message, file type, and steps to reproduce" -ForegroundColor Gray
    Write-Host ""
    Write-Host "==================================================================" -ForegroundColor Red
    Write-Host ""
}

function Get-ErrorSuggestions {
    param(
        [string]$Language,
        [string]$RawError,
        [string]$Phase
    )
    
    $suggestions = @()
    $errorLower = $RawError.ToLower()
    
    switch ($Language.ToLower()) {
        "python" {
            if ($errorLower -match "modulenotfounderror|no module named") {
                $moduleName = "the module"
                if ($RawError -match "No module named '(.+)'") { 
                    $moduleName = $Matches[1] 
                }
                $suggestions += "Install the missing module: pip install $moduleName"
                $suggestions += "Check if you are using the correct Python environment"
            }
            if ($errorLower -match "syntaxerror") {
                $suggestions += "Check for missing colons at the end of if/for/while/def/class statements"
                $suggestions += "Verify matching parentheses, brackets, and quotes"
                $suggestions += "Ensure proper indentation - Python uses 4 spaces"
            }
            if ($errorLower -match "indentationerror") {
                $suggestions += "Use consistent indentation - 4 spaces recommended"
                $suggestions += "Do not mix tabs and spaces"
                $suggestions += "Check the line mentioned and lines above it"
            }
            if ($errorLower -match "nameerror") {
                $suggestions += "Check for typos in variable or function names"
                $suggestions += "Make sure the variable is defined before use"
                $suggestions += "Check if you need to import a module"
            }
            if ($errorLower -match "typeerror") {
                $suggestions += "Check the types of variables you are operating on"
                $suggestions += "Ensure function arguments match expected types"
            }
            if ($errorLower -match "filenotfounderror") {
                $suggestions += "Verify the file path is correct"
                $suggestions += "Use absolute paths or check the working directory"
            }
            if ($errorLower -match "permission") {
                $suggestions += "Run with administrator privileges if needed"
                $suggestions += "Check file and folder permissions"
            }
            if ($errorLower -match "zerodivisionerror") {
                $suggestions += "Check for division by zero in your code"
                $suggestions += "Add validation before division operations"
            }
            if ($errorLower -match "keyerror") {
                $suggestions += "Check if the dictionary key exists before accessing"
                $suggestions += "Use dict.get() method for safe access"
            }
            if ($errorLower -match "indexerror") {
                $suggestions += "Check list/array indices are within bounds"
                $suggestions += "Use len() to verify list length before access"
            }
            if ($errorLower -match "valueerror") {
                $suggestions += "Check if the value is valid for the operation"
                $suggestions += "Validate input before conversion"
            }
            if ($errorLower -match "attributeerror") {
                $suggestions += "Check if the object has the attribute or method"
                $suggestions += "Verify the object is of the expected type"
            }
        }
        
        "java" {
            if ($errorLower -match "cannot find symbol") {
                $suggestions += "Check for typos in class, method, or variable names"
                $suggestions += "Ensure required classes are imported"
                $suggestions += "Verify the class is in the classpath"
            }
            if ($errorLower -match "class.*should be declared in a file named") {
                $suggestions += "Rename the file to match the public class name"
                $suggestions += "Or rename the class to match the filename"
            }
            if ($errorLower -match "classnotfoundexception") {
                $suggestions += "Ensure the class file exists and is in the classpath"
                $suggestions += "For MySQL: check if mysql-connector-j.jar is in the classpath"
            }
            if ($errorLower -match "nullpointerexception") {
                $suggestions += "Check if an object is null before using it"
                $suggestions += "Initialize objects before calling methods on them"
            }
            if ($errorLower -match "arrayindexoutofboundsexception") {
                $suggestions += "Check array indices - Java arrays are 0-indexed"
                $suggestions += "Verify the array has enough elements"
            }
            if ($errorLower -match "illegal start of expression") {
                $suggestions += "Check for missing semicolons on previous lines"
                $suggestions += "Verify bracket matching"
            }
            if ($errorLower -match "expected") {
                $suggestions += "Check for missing semicolons, brackets, or parentheses"
                $suggestions += "Verify the syntax matches Java requirements"
            }
            if ($errorLower -match "jdbc|mysql|sql") {
                $suggestions += "Ensure MySQL Connector/J is in the classpath"
                $suggestions += "Check database connection parameters"
                $suggestions += "Verify MySQL service is running"
            }
            if ($errorLower -match "stringindexoutofboundsexception") {
                $suggestions += "Check string index is within valid range"
                $suggestions += "Use string.length() to verify bounds"
            }
            if ($errorLower -match "numberformatexception") {
                $suggestions += "Ensure the string contains a valid number"
                $suggestions += "Add validation before parsing"
            }
        }
        
        "c" {
            if ($errorLower -match "undefined reference") {
                $suggestions += "Check if all required libraries are linked"
                $suggestions += "Ensure function implementations exist"
                $suggestions += "For MySQL: add -lmysqlclient to compile command"
            }
            if ($errorLower -match "implicit declaration of function") {
                $suggestions += "Include the header file that declares this function"
                $suggestions += "Check for typos in function name"
            }
            if ($errorLower -match "undeclared") {
                $suggestions += "Declare the variable before using it"
                $suggestions += "Include necessary header files"
            }
            if ($errorLower -match "expected") {
                $suggestions += "Check for missing semicolons, brackets, or parentheses"
                $suggestions += "Verify proper C syntax"
            }
            if ($errorLower -match "segmentation fault|sigsegv") {
                $suggestions += "Check for null pointer dereference"
                $suggestions += "Verify array bounds"
                $suggestions += "Check for use-after-free errors"
                $suggestions += "Ensure pointers are properly initialized"
            }
            if ($errorLower -match "mysql\.h.*no such file") {
                $suggestions += "MySQL development headers not installed"
                $suggestions += "Set MYSQL_INCLUDE environment variable"
                $suggestions += "Consider using Python or Java for MySQL connectivity"
            }
            if ($errorLower -match "conflicting types") {
                $suggestions += "Check function declaration matches definition"
                $suggestions += "Include the proper header file"
            }
            if ($errorLower -match "incompatible") {
                $suggestions += "Check variable types match expected types"
                $suggestions += "Use proper type casting if needed"
            }
        }
        
        "c++" {
            if ($errorLower -match "undefined reference") {
                $suggestions += "Check if all required libraries are linked"
                $suggestions += "Ensure method implementations exist (not just declarations)"
                $suggestions += "For templates: ensure implementation is in header or explicitly instantiated"
            }
            if ($errorLower -match "no matching function") {
                $suggestions += "Check function argument types and count"
                $suggestions += "Ensure template arguments are correct"
            }
            if ($errorLower -match "was not declared in this scope") {
                $suggestions += "Include the necessary header file"
                $suggestions += "Add: using namespace std; or use std:: prefix"
            }
            if ($errorLower -match "expected.*before") {
                $suggestions += "Check for missing semicolons in class definitions"
                $suggestions += "Verify template syntax"
                $suggestions += "Check for missing brackets or parentheses"
            }
            if ($errorLower -match "stoi|stod|stof|to_string") {
                $suggestions += "Include the string header: #include <string>"
                $suggestions += "Use std:: prefix or add: using namespace std;"
            }
            if ($errorLower -match "vector|map|set|list|queue|stack") {
                $suggestions += "Include the appropriate STL header"
                $suggestions += "Use std:: prefix for STL containers"
            }
            if ($errorLower -match "cout|cin|endl") {
                $suggestions += "Include iostream: #include <iostream>"
                $suggestions += "Use std:: prefix or add: using namespace std;"
            }
            if ($errorLower -match "segmentation fault|sigsegv") {
                $suggestions += "Check for null pointer dereference"
                $suggestions += "Verify array/vector bounds"
                $suggestions += "Check iterator validity"
                $suggestions += "Use smart pointers to prevent memory issues"
            }
            if ($errorLower -match "bad_alloc") {
                $suggestions += "Check for memory allocation failures"
                $suggestions += "Reduce memory usage or handle allocation errors"
            }
        }
        
        "javascript" {
            if ($errorLower -match "cannot find module") {
                $suggestions += "Run: npm install to install dependencies"
                $suggestions += "Check if the module name is correct"
                $suggestions += "Verify package.json has the dependency listed"
            }
            if ($errorLower -match "is not defined") {
                $suggestions += "Check for typos in variable or function names"
                $suggestions += "Ensure the variable is declared with let, const, or var"
                $suggestions += "Check if module is properly imported"
            }
            if ($errorLower -match "unexpected token") {
                $suggestions += "Check for syntax errors like missing brackets or commas"
                $suggestions += "Verify JSON format if parsing JSON"
            }
            if ($errorLower -match "cannot read propert") {
                $suggestions += "Check if the object is undefined or null"
                $suggestions += "Use optional chaining (?.) for safe access"
            }
            if ($errorLower -match "syntaxerror") {
                $suggestions += "Check for missing brackets, parentheses, or quotes"
                $suggestions += "Verify proper JavaScript syntax"
            }
        }
        
        "sql" {
            if ($errorLower -match "access denied") {
                $suggestions += "Check MySQL username and password"
                $suggestions += "Verify user has permissions for the database"
                $suggestions += "Use: -MySQLUser and -MySQLPass parameters"
            }
            if ($errorLower -match "syntax") {
                $suggestions += "Check SQL syntax near the mentioned position"
                $suggestions += "Verify table and column names"
                $suggestions += "Check for missing quotes around string values"
            }
            if ($errorLower -match "table.*doesn.t exist") {
                $suggestions += "Check if the table name is spelled correctly"
                $suggestions += "Ensure you are connected to the correct database"
                $suggestions += "Use: -MySQLDatabase parameter"
            }
            if ($errorLower -match "can.t connect|connection refused") {
                $suggestions += "Verify MySQL service is running"
                $suggestions += "Check host and port settings"
            }
            if ($errorLower -match "unknown column") {
                $suggestions += "Check column name spelling"
                $suggestions += "Verify the column exists in the table"
            }
            if ($errorLower -match "duplicate entry") {
                $suggestions += "Check for duplicate primary key or unique constraint violations"
                $suggestions += "Use INSERT IGNORE or ON DUPLICATE KEY UPDATE"
            }
        }
        
        "powershell" {
            if ($errorLower -match "not recognized") {
                $suggestions += "Check if the command or cmdlet is installed"
                $suggestions += "Verify the module is imported"
            }
            if ($errorLower -match "cannot bind") {
                $suggestions += "Check parameter names and types"
                $suggestions += "Verify required parameters are provided"
            }
        }
    }
    
    # Add generic suggestions if no specific ones were added
    if ($suggestions.Count -eq 0) {
        $suggestions += "Review the error message carefully for hints"
        $suggestions += "Check the line number mentioned in the error"
        $suggestions += "Search for this error online for more solutions"
    }
    
    # Always add helpful tips
    $suggestions += "Use -VerboseOutput flag for more detailed debugging information"
    
    return $suggestions
}

# ============================================
# C/C++ DEPENDENCY DETECTION & AUTO-INSTALL
# ============================================

# Known external library patterns and their installation info
$script:CppLibraries = @{
    # Boost Libraries (header-only subset)
    "boost/multiprecision" = @{
        Name        = "Boost.Multiprecision"
        Type        = "vcpkg"
        Package     = "boost-multiprecision"
        HeaderOnly  = $true
        Description = "High-precision arithmetic library"
    }
    "boost/asio"           = @{
        Name        = "Boost.Asio"
        Type        = "vcpkg"
        Package     = "boost-asio"
        HeaderOnly  = $false
        Description = "Networking and low-level I/O"
    }
    "boost/filesystem"     = @{
        Name        = "Boost.Filesystem"
        Type        = "vcpkg"
        Package     = "boost-filesystem"
        HeaderOnly  = $false
        Description = "Portable filesystem operations"
    }
    "boost/regex"          = @{
        Name        = "Boost.Regex"
        Type        = "vcpkg"
        Package     = "boost-regex"
        HeaderOnly  = $false
        Description = "Regular expressions library"
    }
    "boost/thread"         = @{
        Name        = "Boost.Thread"
        Type        = "vcpkg"
        Package     = "boost-thread"
        HeaderOnly  = $false
        Description = "Threading library"
    }
    "boost/date_time"      = @{
        Name        = "Boost.DateTime"
        Type        = "vcpkg"
        Package     = "boost-date-time"
        HeaderOnly  = $false
        Description = "Date and time library"
    }
    "boost/json"           = @{
        Name        = "Boost.JSON"
        Type        = "vcpkg"
        Package     = "boost-json"
        HeaderOnly  = $true
        Description = "JSON parsing library"
    }
    "boost/beast"          = @{
        Name        = "Boost.Beast"
        Type        = "vcpkg"
        Package     = "boost-beast"
        HeaderOnly  = $true
        Description = "HTTP and WebSocket library"
    }
    "boost/"               = @{
        Name        = "Boost"
        Type        = "vcpkg"
        Package     = "boost"
        HeaderOnly  = $false
        Description = "Complete Boost C++ Libraries"
    }
    # Other popular libraries
    "nlohmann/json"        = @{
        Name        = "nlohmann/json"
        Type        = "vcpkg"
        Package     = "nlohmann-json"
        HeaderOnly  = $true
        Description = "Modern JSON for C++"
    }
    "fmt/format"           = @{
        Name        = "fmt"
        Type        = "vcpkg"
        Package     = "fmt"
        HeaderOnly  = $false
        Description = "Modern formatting library"
    }
    "spdlog/"              = @{
        Name        = "spdlog"
        Type        = "vcpkg"
        Package     = "spdlog"
        HeaderOnly  = $true
        Description = "Fast logging library"
    }
    "Eigen/"               = @{
        Name        = "Eigen"
        Type        = "vcpkg"
        Package     = "eigen3"
        HeaderOnly  = $true
        Description = "Linear algebra library"
    }
    "opencv2/"             = @{
        Name        = "OpenCV"
        Type        = "vcpkg"
        Package     = "opencv4"
        HeaderOnly  = $false
        Description = "Computer vision library"
    }
    "curl/curl"            = @{
        Name        = "libcurl"
        Type        = "vcpkg"
        Package     = "curl"
        HeaderOnly  = $false
        Description = "URL transfer library"
    }
    "openssl/"             = @{
        Name        = "OpenSSL"
        Type        = "vcpkg"
        Package     = "openssl"
        HeaderOnly  = $false
        Description = "Cryptography library"
    }
    "sqlite3"              = @{
        Name        = "SQLite3"
        Type        = "vcpkg"
        Package     = "sqlite3"
        HeaderOnly  = $false
        Description = "Embedded SQL database"
    }
    "gtest/"               = @{
        Name        = "Google Test"
        Type        = "vcpkg"
        Package     = "gtest"
        HeaderOnly  = $false
        Description = "C++ testing framework"
    }
    "catch2/"              = @{
        Name        = "Catch2"
        Type        = "vcpkg"
        Package     = "catch2"
        HeaderOnly  = $true
        Description = "Modern C++ testing framework"
    }
    "imgui"                = @{
        Name        = "Dear ImGui"
        Type        = "vcpkg"
        Package     = "imgui"
        HeaderOnly  = $false
        Description = "Immediate mode GUI library"
    }
    "glfw"                 = @{
        Name        = "GLFW"
        Type        = "vcpkg"
        Package     = "glfw3"
        HeaderOnly  = $false
        Description = "OpenGL windowing library"
    }
    "glad/"                = @{
        Name        = "GLAD"
        Type        = "vcpkg"
        Package     = "glad"
        HeaderOnly  = $false
        Description = "OpenGL loader library"
    }
}

function Get-CppDependencies {
    param([string]$SourceFile)
    
    $dependencies = @()
    $content = Get-Content $SourceFile -Raw -ErrorAction SilentlyContinue
    if (-not $content) { return $dependencies }
    
    # Find all #include statements with angle brackets (external libs)
    $includeMatches = [regex]::Matches($content, '#include\s*<([^>]+)>')
    
    foreach ($match in $includeMatches) {
        $includePath = $match.Groups[1].Value
        
        # Skip standard library headers
        $stdHeaders = @(
            "iostream", "iomanip", "fstream", "sstream", "string", "cstring",
            "vector", "map", "set", "list", "queue", "stack", "deque", "array",
            "algorithm", "functional", "numeric", "iterator", "utility",
            "memory", "limits", "cmath", "cstdlib", "cstdio", "ctime", "chrono",
            "thread", "mutex", "condition_variable", "future", "atomic",
            "exception", "stdexcept", "typeinfo", "type_traits", "concepts",
            "optional", "variant", "any", "tuple", "bitset", "regex",
            "filesystem", "random", "ratio", "complex", "valarray",
            "cassert", "cctype", "cerrno", "cfenv", "cfloat", "cinttypes",
            "ciso646", "climits", "clocale", "csetjmp", "csignal", "cstdarg",
            "cstddef", "cstdint", "cwchar", "cwctype", "initializer_list",
            "unordered_map", "unordered_set", "forward_list", "span", "ranges",
            "format", "source_location", "numbers", "bit", "compare", "coroutine",
            "new", "typeindex", "execution", "charconv", "syncstream", "latch",
            "barrier", "semaphore", "stop_token", "version"
        )
        
        # Check if this is a standard header
        $isStdHeader = $false
        $headerBase = ($includePath -split '/')[0]
        if ($stdHeaders -contains $headerBase -or $stdHeaders -contains $includePath) {
            $isStdHeader = $true
        }
        # Also check for C++ standard prefix patterns
        if ($includePath -match "^(c[a-z]+|std[a-z]*)$") {
            $isStdHeader = $true
        }
        
        if (-not $isStdHeader) {
            # Check against known libraries
            foreach ($libPattern in $script:CppLibraries.Keys) {
                if ($includePath -like "$libPattern*") {
                    $libInfo = $script:CppLibraries[$libPattern]
                    $dependencies += @{
                        Include = $includePath
                        Library = $libInfo
                        Pattern = $libPattern
                    }
                    break
                }
            }
            
            # If not found in known libs, add as unknown dependency
            $found = $false
            foreach ($dep in $dependencies) {
                if ($dep.Include -eq $includePath) { $found = $true; break }
            }
            if (-not $found) {
                $dependencies += @{
                    Include = $includePath
                    Library = $null
                    Pattern = $null
                }
            }
        }
    }
    
    return $dependencies
}

function Test-VcpkgInstalled {
    $vcpkg = Get-Command vcpkg -ErrorAction SilentlyContinue
    return $null -ne $vcpkg
}

function Get-VcpkgRoot {
    # Try common locations
    $possiblePaths = @(
        "$env:VCPKG_ROOT",
        "C:\vcpkg",
        "C:\tools\vcpkg",
        "$env:USERPROFILE\vcpkg",
        "$env:LOCALAPPDATA\vcpkg"
    )
    
    foreach ($path in $possiblePaths) {
        if ($path -and (Test-Path (Join-Path $path "vcpkg.exe"))) {
            return $path
        }
    }
    return $null
}

function Install-Vcpkg {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "  INSTALLING VCPKG PACKAGE MANAGER" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""
    
    $vcpkgDir = "C:\vcpkg"
    
    try {
        if (-not (Test-Path $vcpkgDir)) {
            Write-Info "Cloning vcpkg..."
            & git clone https://github.com/Microsoft/vcpkg.git $vcpkgDir 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0) {
                Write-Err "Failed to clone vcpkg"
                return $false
            }
        }
        
        Write-Info "Bootstrapping vcpkg..."
        Push-Location $vcpkgDir
        & .\bootstrap-vcpkg.bat 2>&1 | Out-Null
        Pop-Location
        
        if ($LASTEXITCODE -ne 0) {
            Write-Err "Failed to bootstrap vcpkg"
            return $false
        }
        
        # Add to PATH for this session
        $env:PATH = "$vcpkgDir;$env:PATH"
        $env:VCPKG_ROOT = $vcpkgDir
        
        Write-Success "vcpkg installed successfully!"
        return $true
    }
    catch {
        Write-Err "Failed to install vcpkg: $($_.Exception.Message)"
        return $false
    }
}

function Install-CppDependency {
    param(
        [hashtable]$Dependency,
        [switch]$Force
    )
    
    $libInfo = $Dependency.Library
    if (-not $libInfo) {
        Write-Warn "Unknown library for include: $($Dependency.Include)"
        return $false
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  INSTALLING: $($libInfo.Name)" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Description: $($libInfo.Description)" -ForegroundColor Gray
    Write-Host "  Package: $($libInfo.Package)" -ForegroundColor Gray
    Write-Host ""
    
    # Check for vcpkg
    if (-not (Test-VcpkgInstalled)) {
        Write-Warn "vcpkg not found. Attempting to install..."
        
        # Check for Git first
        $git = Get-Command git -ErrorAction SilentlyContinue
        if (-not $git) {
            Write-Err "Git is required to install vcpkg but was not found."
            Write-Host ""
            Write-Host "  To install Git:" -ForegroundColor Yellow
            Write-Host "  1. Run: choco install git" -ForegroundColor Cyan
            Write-Host "  2. Restart your terminal" -ForegroundColor Gray
            Write-Host ""
            return $false
        }
        
        if (-not (Install-Vcpkg)) {
            return $false
        }
    }
    
    $vcpkgRoot = Get-VcpkgRoot
    if (-not $vcpkgRoot) {
        Write-Err "Could not locate vcpkg installation"
        return $false
    }
    
    $vcpkgExe = Join-Path $vcpkgRoot "vcpkg.exe"
    $triplet = "x64-mingw-static"  # For static MinGW builds
    
    Write-Info "Installing $($libInfo.Package) via vcpkg..."
    Write-Host "  This may take several minutes for large libraries..." -ForegroundColor Gray
    Write-Host ""
    
    try {
        # Try mingw triplet first (matches our g++ builds)
        $result = & $vcpkgExe install "$($libInfo.Package):$triplet" 2>&1
        $installExitCode = $LASTEXITCODE
        
        if ($installExitCode -ne 0) {
            # Fallback to default triplet
            $triplet = "x64-windows-static"
            Write-Warn "MinGW build not available, trying Windows static build..."
            $result = & $vcpkgExe install "$($libInfo.Package):$triplet" 2>&1
            $installExitCode = $LASTEXITCODE
        }
        
        if ($installExitCode -eq 0) {
            Write-Success "$($libInfo.Name) installed successfully!"
            
            # Show include path info
            $includePath = Join-Path $vcpkgRoot "installed\$triplet\include"
            $libPath = Join-Path $vcpkgRoot "installed\$triplet\lib"
            
            Write-Host ""
            Write-Host "  Include path: $includePath" -ForegroundColor Gray
            Write-Host "  Library path: $libPath" -ForegroundColor Gray
            Write-Host ""
            
            return @{
                Success     = $true
                IncludePath = $includePath
                LibPath     = $libPath
                Triplet     = $triplet
            }
        }
        else {
            Write-Err "Failed to install $($libInfo.Package)"
            Write-Host ""
            Write-Host "  vcpkg output:" -ForegroundColor Yellow
            $result | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
            return $false
        }
    }
    catch {
        Write-Err "Exception during installation: $($_.Exception.Message)"
        return $false
    }
}

function Resolve-CppDependencies {
    param(
        [string]$SourceFile,
        [string]$ErrorOutput
    )
    
    $result = @{
        NeedsInstall = $false
        MissingLibs  = @()
        IncludePaths = @()
        LibPaths     = @()
        LinkLibs     = @()
    }
    
    # Check if error is about missing header
    if ($ErrorOutput -notmatch "No such file or directory|cannot open source file|file not found") {
        return $result
    }
    
    # Parse which header is missing
    $missingHeader = $null
    if ($ErrorOutput -match "fatal error:\s*([^:]+):\s*No such file or directory") {
        $missingHeader = $Matches[1].Trim()
    }
    elseif ($ErrorOutput -match "cannot open source file\s+[`"']?([^`"'\s]+)") {
        $missingHeader = $Matches[1].Trim()
    }
    
    if (-not $missingHeader) { return $result }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "  MISSING DEPENDENCY DETECTED" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Missing header: " -NoNewline -ForegroundColor White
    Write-Host "$missingHeader" -ForegroundColor Red
    Write-Host ""
    
    # Find matching library
    $matchedLib = $null
    $matchedPattern = $null
    foreach ($libPattern in $script:CppLibraries.Keys) {
        if ($missingHeader -like "$libPattern*") {
            $matchedLib = $script:CppLibraries[$libPattern]
            $matchedPattern = $libPattern
            break
        }
    }
    
    if ($matchedLib) {
        Write-Host "  Identified as: " -NoNewline -ForegroundColor White
        Write-Host "$($matchedLib.Name)" -ForegroundColor Cyan
        Write-Host "  Description: $($matchedLib.Description)" -ForegroundColor Gray
        Write-Host ""
        
        # Prompt user for auto-install
        Write-Host "  Would you like d1run to automatically install this dependency?" -ForegroundColor Yellow
        Write-Host "  This will use vcpkg (Microsoft's C++ package manager)." -ForegroundColor Gray
        Write-Host ""
        
        $response = Read-Host "  Install $($matchedLib.Name)? (Y/N)"
        
        if ($response -match "^[Yy]") {
            $installResult = Install-CppDependency -Dependency @{ Include = $missingHeader; Library = $matchedLib }
            
            if ($installResult -and $installResult.Success) {
                $result.NeedsInstall = $false
                $result.IncludePaths += $installResult.IncludePath
                $result.LibPaths += $installResult.LibPath
                
                Write-Host ""
                Write-Success "Dependency installed! Retrying compilation..."
                Write-Host ""
                
                return $result
            }
        }
        
        # Show manual installation instructions
        Write-Host ""
        Write-Host "  MANUAL INSTALLATION OPTIONS:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Option 1 - Using vcpkg:" -ForegroundColor Cyan
        Write-Host "    1. git clone https://github.com/Microsoft/vcpkg.git C:\vcpkg" -ForegroundColor White
        Write-Host "    2. C:\vcpkg\bootstrap-vcpkg.bat" -ForegroundColor White
        Write-Host "    3. C:\vcpkg\vcpkg install $($matchedLib.Package):x64-mingw-static" -ForegroundColor White
        Write-Host "    4. Compile with: g++ -I C:\vcpkg\installed\x64-mingw-static\include ..." -ForegroundColor White
        Write-Host ""
        Write-Host "  Option 2 - Using Chocolatey (if available):" -ForegroundColor Cyan
        Write-Host "    choco install boost" -ForegroundColor White
        Write-Host ""
        
        $result.NeedsInstall = $true
        $result.MissingLibs += $matchedLib
    }
    else {
        Write-Host "  This header is from an unrecognized library." -ForegroundColor Yellow  
        Write-Host ""
        Write-Host "  SUGGESTIONS:" -ForegroundColor Cyan
        Write-Host "  1. Search for the library online and download it" -ForegroundColor White
        Write-Host "  2. Install via vcpkg: vcpkg search <library-name>" -ForegroundColor White
        Write-Host "  3. Use header-only version if available" -ForegroundColor White
        Write-Host ""
        
        $result.NeedsInstall = $true
    }
    
    return $result
}

# ============================================
# BUILD INFO DISPLAY
# ============================================
function Show-BuildInfo {
    param([string]$ExePath, [string]$Lang)
    
    if (Test-Path $ExePath) {
        $fileSize = (Get-Item $ExePath).Length
        $sizeKB = [math]::Round($fileSize / 1KB, 1)
        $sizeMB = [math]::Round($fileSize / 1MB, 2)
        
        $sizeStr = if ($sizeMB -ge 1) { "$sizeMB MB" } else { "$sizeKB KB" }
        
        Write-Host ""
        Write-Host "  Built: " -NoNewline -ForegroundColor Green
        Write-Host "$ExePath" -ForegroundColor Cyan
        Write-Host "  Size:  $sizeStr (Static/Portable)" -ForegroundColor Gray
    }
}

# ============================================
# HELP AND VERSION
# ============================================
function Show-Help {
    Write-Host ''
    Write-Host '==============================================================' -ForegroundColor Cyan
    Write-Host '  d1run v3.0 - Universal Code Runner' -ForegroundColor Cyan
    Write-Host '  Part of the dmj.one initiative' -ForegroundColor Cyan
    Write-Host '==============================================================' -ForegroundColor Cyan
    Write-Host ''
    Write-Host 'USAGE:' -ForegroundColor Yellow
    Write-Host '  d1run <filename> [arguments...]'
    Write-Host ''
    Write-Host '  Arguments after filename are passed to YOUR PROGRAM.'
    Write-Host ''
    Write-Host 'EXAMPLES:' -ForegroundColor Yellow
    Write-Host '  d1run hello.cpp                # Compile and run C++'
    Write-Host '  d1run add.cpp 5 3              # Run with arguments 5 and 3'
    Write-Host '  d1run script.py arg1 arg2      # Python with arguments'
    Write-Host '  d1run App.java                 # Compile and run Java'
    Write-Host '  d1run query.sql                # Execute SQL in MySQL'
    Write-Host ''
    Write-Host 'SUPPORTED LANGUAGES:' -ForegroundColor Yellow
    Write-Host '  .c .cpp .cc .cxx    C/C++ (Static release build - PORTABLE!)'
    Write-Host '  .java               Java (auto-compiles)'
    Write-Host '  .py                 Python'
    Write-Host '  .js                 JavaScript (Node.js)'
    Write-Host '  .ps1                PowerShell'
    Write-Host '  .bat .cmd           Batch'
    Write-Host '  .sql                SQL (MySQL)'
    Write-Host ''
    Write-Host 'OPTIONS:' -ForegroundColor Yellow
    Write-Host '  -Clean              Delete executable after running'
    Write-Host '  -VerboseOutput      Show debug information'
    Write-Host '  -MySQLUser          MySQL username (default: root)'
    Write-Host '  -MySQLPass          MySQL password'
    Write-Host '  -MySQLDatabase      MySQL database to use'
    Write-Host '  -Help               Show this help'
    Write-Host '  -Version            Show version'
    Write-Host ''
    Write-Host 'KEY FEATURES:' -ForegroundColor Magenta
    Write-Host '  * C/C++ builds are STATIC by default - run on ANY Windows!'
    Write-Host '  * Executables are KEPT in the same folder as source'
    Write-Host '  * Detailed error reports with line numbers and suggestions'
    Write-Host '  * Arguments after filename go directly to your program'
    Write-Host ''
}

function Show-Version {
    Write-Host ""
    Write-Host "$ScriptName v$ScriptVersion" -ForegroundColor Cyan
    Write-Host "Universal Code Runner - Part of dmj.one initiative"
    Write-Host "Created by Nikhil Bhardwaj"
    Write-Host ""
    Write-Host "Features:" -ForegroundColor Yellow
    Write-Host "  * Release builds by default (static linking for C/C++)"
    Write-Host "  * Detailed error reports with line numbers"
    Write-Host "  * Language-specific fix suggestions"
    Write-Host "  * Arguments passed directly to your program"
    Write-Host ""
}

# ============================================
# HANDLE HELP/VERSION/NO ARGS
# ============================================
if ($Help) { Show-Help; exit 0 }
if ($Version) { Show-Version; exit 0 }
if ([string]::IsNullOrWhiteSpace($FilePath)) { Show-Help; exit 0 }

# ============================================
# FILE VALIDATION
# ============================================
if (-not (Test-Path $FilePath)) {
    Write-Err "File not found: $FilePath"
    Write-Host ""
    Write-Host "Please check:" -ForegroundColor Yellow
    Write-Host "  1. The file path is correct" -ForegroundColor White
    Write-Host "  2. The file exists" -ForegroundColor White
    Write-Host "  3. You have permission to access it" -ForegroundColor White
    Write-Host ""
    Write-Host "Current directory: $(Get-Location)" -ForegroundColor Gray
    exit 1
}

# Get file information
try {
    $File = Get-Item $FilePath -ErrorAction Stop
    $FileName = $File.Name
    $FileDir = $File.DirectoryName
    $FileBaseName = $File.BaseName
    $FileExt = $File.Extension.ToLower()
}
catch {
    Write-Err "Could not access file: $FilePath"
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Header "d1run - Universal Code Runner"
Write-Info "File: $FileName"
Write-Info "Directory: $FileDir"
if ($Arguments.Count -gt 0) {
    Write-Info "Arguments: $($Arguments -join ' ')"
}
Write-Dbg "Extension: $FileExt"

# ============================================
# LOAD ENVIRONMENT VARIABLES (.env)
# ============================================
# Try to find .env file to ensure fresh credentials
$EnvPath = $null
$CurrentDir = $FileDir
for ($i = 0; $i -lt 5; $i++) {
    # Search up 5 levels max
    $TestPath = Join-Path $CurrentDir ".env"
    if (Test-Path $TestPath) {
        $EnvPath = $TestPath
        break
    }
    $Parent = Split-Path -Parent $CurrentDir
    if (-not $Parent -or $Parent -eq $CurrentDir) { break }
    $CurrentDir = $Parent
}

if ($EnvPath) {
    Write-Dbg "Loading environment from: $EnvPath"
    $EnvContent = Get-Content $EnvPath -Raw
    $EnvLines = $EnvContent -split "`r`n|`n"
    foreach ($line in $EnvLines) {
        $line = $line.Trim()
        if ($line -match "^#" -or $line -eq "") { continue }
        if ($line -match "^([^=]+)=(.*)$") {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            # Remove quotes if present
            if ($value -match "^['`"](.*)['`"]$") { $value = $matches[1] }
            
            # Set variable in current process scope
            [Environment]::SetEnvironmentVariable($name, $value, "Process")
            Write-Dbg "Set Env: $name"
        }
    }
}

# ============================================
# LANGUAGE EXECUTION
# ============================================
$startTime = Get-Date
$exitCode = 0

switch ($FileExt) {
    # ========================================
    # PYTHON
    # ========================================
    ".py" {
        Write-Info "Language: Python"
        
        # Find Python executable (avoid Windows Store stub)
        $pythonExe = $null
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
        foreach ($p in $pythonPaths) {
            if (Test-Path $p) { $pythonExe = $p; break }
        }
        if (-not $pythonExe) {
            $pythonCmd = Get-Command python -ErrorAction SilentlyContinue | Where-Object { $_.Source -notlike "*WindowsApps*" }
            if ($pythonCmd) { $pythonExe = $pythonCmd.Source }
        }
        if (-not $pythonExe) {
            Write-Err "Python not found!"
            Write-Host ""
            Write-Host "  To install Python:" -ForegroundColor Yellow
            Write-Host "  1. Run start.bat and choose Option 1 (FULL INSTALL)" -ForegroundColor Cyan
            Write-Host "  OR" -ForegroundColor White
            Write-Host "  2. choco install python" -ForegroundColor Cyan
            Write-Host "  3. Restart your terminal after installation" -ForegroundColor Gray
            Write-Host ""
            exit 1
        }
        
        Write-Dbg "Using: $pythonExe"
        Write-OutputSeparator
        
        # Run Python with error capture
        $tempErr = [System.IO.Path]::GetTempFileName()
        try {
            & $pythonExe $File.FullName @Arguments 2>$tempErr
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorOutput = Get-Content $tempErr -Raw -ErrorAction SilentlyContinue
                if ($errorOutput) {
                    Format-ErrorReport -Language "Python" -Phase "Runtime" -RawError $errorOutput -FilePath $File.FullName -ExitCode $exitCode
                }
            }
        }
        finally {
            Remove-Item $tempErr -ErrorAction SilentlyContinue
        }
    }
    
    # ========================================
    # JAVA
    # ========================================
    ".java" {
        Write-Info "Language: Java"
        
        # Find javac
        $javac = Get-Command javac -ErrorAction SilentlyContinue
        if (-not $javac) {
            Write-Err "Java compiler (javac) not found!"
            Write-Host ""
            Write-Host "  To install Java JDK:" -ForegroundColor Yellow
            Write-Host "  1. Run start.bat and choose Option 1 (FULL INSTALL)" -ForegroundColor Cyan
            Write-Host "  OR" -ForegroundColor White
            Write-Host "  2. choco install openjdk" -ForegroundColor Cyan
            Write-Host "  3. Restart your terminal after installation" -ForegroundColor Gray
            Write-Host ""
            exit 1
        }
        
        # Parse the file to find the public class name
        $content = Get-Content $File.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $content) {
            Write-Err "Could not read file: $($File.FullName)"
            exit 1
        }
        
        $classMatch = [regex]::Match($content, 'public\s+class\s+(\w+)')
        $className = if ($classMatch.Success) { $classMatch.Groups[1].Value } else { $FileBaseName }
        
        # Validate class name matches filename
        if ($className -ne $FileBaseName) {
            Write-Warn "Class name '$className' does not match filename '$FileBaseName'"
            Write-Host "  Java requires the public class name to match the filename." -ForegroundColor Yellow
        }
        
        Write-Info "Detected class: $className"
        
        # Check for MySQL connector if code uses JDBC
        $classpath = "."
        if ($content -match "java\.sql\." -or $content -match "jdbc:") {
            Write-Info "JDBC usage detected, searching for MySQL connector..."
            $scriptDir = $PSScriptRoot
            $projectRoot = Split-Path -Parent $scriptDir
            $connectorPaths = @(
                "$projectRoot\lib\mysql-connector-j\mysql-connector-j-8.3.0.jar",
                "$projectRoot\lib\mysql-connector-j\mysql-connector-j-8.3.0\mysql-connector-j-8.3.0.jar"
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
        $tempErr = [System.IO.Path]::GetTempFileName()
        try {
            & javac -cp $classpath $FileName 2>$tempErr
            $compileExitCode = $LASTEXITCODE
            
            if ($compileExitCode -ne 0) {
                $errorOutput = Get-Content $tempErr -Raw -ErrorAction SilentlyContinue
                Format-ErrorReport -Language "Java" -Phase "Compilation" -RawError $errorOutput -FilePath $File.FullName -ExitCode $compileExitCode
                Pop-Location
                exit $compileExitCode
            }
            Write-Success "Compiled successfully!"
            
            Write-OutputSeparator
            
            # Run
            "" | Out-File $tempErr -Encoding UTF8
            & java -cp $classpath $className @Arguments 2>$tempErr
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorOutput = Get-Content $tempErr -Raw -ErrorAction SilentlyContinue
                if ($errorOutput) {
                    Format-ErrorReport -Language "Java" -Phase "Runtime" -RawError $errorOutput -FilePath $File.FullName -ExitCode $exitCode
                }
            }
            
            # Cleanup .class files if -Clean specified
            if ($Clean) {
                Get-ChildItem -Path $FileDir -Filter "*.class" | Remove-Item -Force -ErrorAction SilentlyContinue
            }
        }
        finally {
            Pop-Location
            Remove-Item $tempErr -ErrorAction SilentlyContinue
        }
    }
    
    # ========================================
    # C
    # ========================================
    ".c" {
        Write-Info "Language: C"
        
        $gcc = Get-Command gcc -ErrorAction SilentlyContinue
        if (-not $gcc) {
            Write-Err "GCC not found!"
            Write-Host ""
            Write-Host "  To install GCC:" -ForegroundColor Yellow
            Write-Host "  1. Run start.bat and choose Option 1 (FULL INSTALL)" -ForegroundColor Cyan
            Write-Host "  OR" -ForegroundColor White
            Write-Host "  2. choco install mingw" -ForegroundColor Cyan
            Write-Host "  3. Restart your terminal after installation" -ForegroundColor Gray
            Write-Host ""
            exit 1
        }
        
        $exePath = Join-Path $FileDir "$FileBaseName.exe"
        
        # RELEASE BUILD with STATIC linking (default)
        $compileArgs = @(
            "-o", $exePath,
            $File.FullName,
            "-O2",                # Optimization
            "-s",                 # Strip symbols
            "-static",            # Static linking
            "-static-libgcc"      # Static GCC runtime
        )
        
        # Check for MySQL usage
        $content = Get-Content $File.FullName -Raw -ErrorAction SilentlyContinue
        if ($content -match "mysql\.h" -or $content -match "mysql_") {
            Write-Info "MySQL usage detected, adding MySQL libraries..."
            if ($env:MYSQL_INCLUDE -and $env:MYSQL_LIB -and (Test-Path $env:MYSQL_INCLUDE)) {
                $compileArgs += @("-I$env:MYSQL_INCLUDE", "-L$env:MYSQL_LIB", "-lmysqlclient")
            }
            else {
                Write-Warn "MYSQL_INCLUDE or MYSQL_LIB not set. MySQL compilation may fail."
            }
        }
        
        # Compile
        Write-Info "Compiling (static release)..."
        Write-Dbg "gcc $($compileArgs -join ' ')"
        
        $tempErr = [System.IO.Path]::GetTempFileName()
        try {
            & gcc @compileArgs 2>$tempErr
            $compileExitCode = $LASTEXITCODE
            
            if ($compileExitCode -ne 0) {
                $errorOutput = Get-Content $tempErr -Raw -ErrorAction SilentlyContinue
                Format-ErrorReport -Language "C" -Phase "Compilation" -RawError $errorOutput -FilePath $File.FullName -ExitCode $compileExitCode
                exit $compileExitCode
            }
            
            Write-Success "Compiled successfully!"
            Show-BuildInfo -ExePath $exePath -Lang "C"
            
            Write-OutputSeparator
            
            # Run
            "" | Out-File $tempErr -Encoding UTF8
            & $exePath @Arguments 2>$tempErr
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorOutput = Get-Content $tempErr -Raw -ErrorAction SilentlyContinue
                if ($errorOutput) {
                    Format-ErrorReport -Language "C" -Phase "Runtime" -RawError $errorOutput -FilePath $File.FullName -ExitCode $exitCode
                }
            }
            
            # Cleanup if -Clean specified
            if ($Clean -and (Test-Path $exePath)) {
                Remove-Item $exePath -Force -ErrorAction SilentlyContinue
            }
        }
        finally {
            Remove-Item $tempErr -ErrorAction SilentlyContinue
        }
    }
    
    # ========================================
    # C++
    # ========================================
    { $_ -in ".cpp", ".cxx", ".cc" } {
        Write-Info "Language: C++"
        
        $gpp = Get-Command g++ -ErrorAction SilentlyContinue
        if (-not $gpp) {
            Write-Err "G++ not found!"
            Write-Host ""
            Write-Host "  To install G++:" -ForegroundColor Yellow
            Write-Host "  1. Run start.bat and choose Option 1 (FULL INSTALL)" -ForegroundColor Cyan
            Write-Host "  OR" -ForegroundColor White
            Write-Host "  2. choco install mingw" -ForegroundColor Cyan
            Write-Host "  3. Restart your terminal after installation" -ForegroundColor Gray
            Write-Host ""
            exit 1
        }
        
        $exePath = Join-Path $FileDir "$FileBaseName.exe"
        
        # RELEASE BUILD with STATIC linking (default)
        $compileArgs = @(
            "-o", $exePath,
            $File.FullName,
            "-std=c++17",         # C++17 standard
            "-O2",                # Optimization
            "-s",                 # Strip symbols
            "-static",            # Static linking
            "-static-libgcc",     # Static GCC runtime
            "-static-libstdc++"   # Static C++ standard library
        )
        
        # Check for MySQL usage
        $content = Get-Content $File.FullName -Raw -ErrorAction SilentlyContinue
        if ($content -match "mysql\.h" -or $content -match "mysql_" -or $content -match "cppconn") {
            Write-Info "MySQL usage detected, adding MySQL libraries..."
            if ($env:MYSQL_INCLUDE -and $env:MYSQL_LIB -and (Test-Path $env:MYSQL_INCLUDE)) {
                $compileArgs += @("-I$env:MYSQL_INCLUDE", "-L$env:MYSQL_LIB", "-lmysqlclient")
            }
            else {
                Write-Warn "MYSQL_INCLUDE or MYSQL_LIB not set. MySQL compilation may fail."
            }
        }
        
        # Compile
        Write-Info "Compiling (static release)..."
        Write-Dbg "g++ $($compileArgs -join ' ')"
        
        $tempErr = [System.IO.Path]::GetTempFileName()
        try {
            & g++ @compileArgs 2>$tempErr
            $compileExitCode = $LASTEXITCODE
            
            if ($compileExitCode -ne 0) {
                $errorOutput = Get-Content $tempErr -Raw -ErrorAction SilentlyContinue
                Format-ErrorReport -Language "C++" -Phase "Compilation" -RawError $errorOutput -FilePath $File.FullName -ExitCode $compileExitCode
                exit $compileExitCode
            }
            
            Write-Success "Compiled successfully!"
            Show-BuildInfo -ExePath $exePath -Lang "C++"
            
            Write-OutputSeparator
            
            # Run
            "" | Out-File $tempErr -Encoding UTF8
            & $exePath @Arguments 2>$tempErr
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorOutput = Get-Content $tempErr -Raw -ErrorAction SilentlyContinue
                if ($errorOutput) {
                    Format-ErrorReport -Language "C++" -Phase "Runtime" -RawError $errorOutput -FilePath $File.FullName -ExitCode $exitCode
                }
            }
            
            # Cleanup if -Clean specified
            if ($Clean -and (Test-Path $exePath)) {
                Remove-Item $exePath -Force -ErrorAction SilentlyContinue
            }
        }
        finally {
            Remove-Item $tempErr -ErrorAction SilentlyContinue
        }
    }
    
    # ========================================
    # JAVASCRIPT (Node.js)
    # ========================================
    ".js" {
        Write-Info "Language: JavaScript (Node.js)"
        
        $node = Get-Command node -ErrorAction SilentlyContinue
        if (-not $node) {
            Write-Err "Node.js not found!"
            Write-Host ""
            Write-Host "  To install Node.js:" -ForegroundColor Yellow
            Write-Host "  choco install nodejs" -ForegroundColor Cyan
            Write-Host "  Restart your terminal after installation" -ForegroundColor Gray
            Write-Host ""
            exit 1
        }
        
        Write-OutputSeparator
        
        $tempErr = [System.IO.Path]::GetTempFileName()
        try {
            & node $File.FullName @Arguments 2>$tempErr
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorOutput = Get-Content $tempErr -Raw -ErrorAction SilentlyContinue
                if ($errorOutput) {
                    Format-ErrorReport -Language "JavaScript" -Phase "Runtime" -RawError $errorOutput -FilePath $File.FullName -ExitCode $exitCode
                }
            }
        }
        finally {
            Remove-Item $tempErr -ErrorAction SilentlyContinue
        }
    }
    
    # ========================================
    # POWERSHELL
    # ========================================
    ".ps1" {
        Write-Info "Language: PowerShell"
        Write-OutputSeparator
        
        $tempErr = [System.IO.Path]::GetTempFileName()
        try {
            & powershell -ExecutionPolicy Bypass -File $File.FullName @Arguments 2>$tempErr
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorOutput = Get-Content $tempErr -Raw -ErrorAction SilentlyContinue
                if ($errorOutput) {
                    Format-ErrorReport -Language "PowerShell" -Phase "Runtime" -RawError $errorOutput -FilePath $File.FullName -ExitCode $exitCode
                }
            }
        }
        finally {
            Remove-Item $tempErr -ErrorAction SilentlyContinue
        }
    }
    
    # ========================================
    # BATCH
    # ========================================
    { $_ -in ".bat", ".cmd" } {
        Write-Info "Language: Batch Script"
        Write-OutputSeparator
        
        $tempErr = [System.IO.Path]::GetTempFileName()
        try {
            & cmd /c $File.FullName @Arguments 2>$tempErr
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorOutput = Get-Content $tempErr -Raw -ErrorAction SilentlyContinue
                if ($errorOutput) {
                    Format-ErrorReport -Language "Batch" -Phase "Runtime" -RawError $errorOutput -FilePath $File.FullName -ExitCode $exitCode
                }
            }
        }
        finally {
            Remove-Item $tempErr -ErrorAction SilentlyContinue
        }
    }
    
    # ========================================
    # SQL (MySQL)
    # ========================================
    ".sql" {
        Write-Info "Language: SQL (MySQL)"
        
        $mysql = Get-Command mysql -ErrorAction SilentlyContinue
        if (-not $mysql) {
            Write-Err "MySQL client not found!"
            Write-Host ""
            Write-Host "  To install MySQL:" -ForegroundColor Yellow
            Write-Host "  1. Run start.bat and choose Option 1 (FULL INSTALL)" -ForegroundColor Cyan
            Write-Host "  OR" -ForegroundColor White
            Write-Host "  2. choco install mysql" -ForegroundColor Cyan
            Write-Host "  3. Restart your terminal after installation" -ForegroundColor Gray
            Write-Host ""
            exit 1
        }
        
        Write-Dbg "MySQL Host: $MySQLHost, Port: $MySQLPort, User: $MySQLUser, Database: $MySQLDatabase"
        Write-OutputSeparator
        
        $mysqlArgs = @("-u", $MySQLUser, "-h", $MySQLHost, "-P", $MySQLPort)
        if ($MySQLDatabase) { $mysqlArgs += @("-D", $MySQLDatabase) }
        
        $tempErr = [System.IO.Path]::GetTempFileName()
        try {
            if ($MySQLPass) {
                $mysqlArgs += "-p$MySQLPass"
            }
            
            & mysql @mysqlArgs -e "source $($File.FullName)" 2>$tempErr
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorOutput = Get-Content $tempErr -Raw -ErrorAction SilentlyContinue
                if ($errorOutput) {
                    # Check if password is needed
                    if ($errorOutput -match "Access denied" -and -not $MySQLPass) {
                        Write-Info "Password required. Enter MySQL password:"
                        $mysqlArgs += "-p"
                        "" | Out-File $tempErr -Encoding UTF8
                        & mysql @mysqlArgs -e "source $($File.FullName)" 2>$tempErr
                        $exitCode = $LASTEXITCODE
                        
                        if ($exitCode -ne 0) {
                            $errorOutput = Get-Content $tempErr -Raw -ErrorAction SilentlyContinue
                        }
                    }
                    
                    if ($exitCode -ne 0 -and $errorOutput) {
                        Format-ErrorReport -Language "SQL" -Phase "Execution" -RawError $errorOutput -FilePath $File.FullName -ExitCode $exitCode
                    }
                }
            }
        }
        finally {
            Remove-Item $tempErr -ErrorAction SilentlyContinue
        }
    }
    
    # ========================================
    # UNSUPPORTED
    # ========================================
    default {
        Write-Err "Unsupported file type: $FileExt"
        Write-Host ""
        Write-Host "Supported extensions:" -ForegroundColor Yellow
        Write-Host "  .py      - Python" -ForegroundColor White
        Write-Host "  .java    - Java" -ForegroundColor White
        Write-Host "  .c       - C" -ForegroundColor White
        Write-Host "  .cpp     - C++" -ForegroundColor White
        Write-Host "  .js      - JavaScript (Node.js)" -ForegroundColor White
        Write-Host "  .ps1     - PowerShell" -ForegroundColor White
        Write-Host "  .bat     - Batch Script" -ForegroundColor White
        Write-Host "  .sql     - SQL (MySQL)" -ForegroundColor White
        Write-Host ""
        Write-Host "If you need support for '$FileExt', please open an issue at:" -ForegroundColor Gray
        Write-Host "  https://github.com/Nikhil20051/java-c-cpp-python-mysql-bootstrap/issues" -ForegroundColor Cyan
        exit 1
    }
}

# ============================================
# SUMMARY
# ============================================
$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

Write-Host ""
Write-Host "==================================================================" -ForegroundColor Gray
if ($exitCode -eq 0) {
    Write-Success "Execution completed successfully! ($([math]::Round($duration, 2))s)"
}
else {
    Write-Err "Execution failed with exit code: $exitCode ($([math]::Round($duration, 2))s)"
    Write-Host ""
    Write-Host "Need help? Try:" -ForegroundColor Yellow
    Write-Host "  * Review the error report above for suggestions" -ForegroundColor White
    Write-Host "  * Use -VerboseOutput flag for more details" -ForegroundColor White
    Write-Host "  * Check the error line number in your code" -ForegroundColor White
}

exit $exitCode
