# Development Environment Bootstrap for Windows 11

A complete one-click solution to set up a fresh Windows 11 system with Java, C, C++, Python, and MySQL development environments.

## 🚀 Zero-Knowledge Quick Start

**Just want to get started? Follow these 3 steps:**

1.  **Download & Unzip**: Click the green "< Code >" button above, select "Download ZIP", and extract it to a folder.
2.  **Install**: Open the folder, right-click on `INSTALL.bat`, and select **"Run as administrator"**.
    *   *Note: If a blue window appears saying "Windows protected your PC", click "More info" -> "Run anyway".*
3.  **Restart**: When the black window says "Installation Complete!", restart your computer.

That's it! All tools (Java, Python, C++, MySQL) are now installed.

### Verification (Optional)
After restarting, you can verify everything is working:
1.  Double-click `VERIFY.bat`.
2.  You should see a list of green `[PASS]` messages.

### Database Setup
To set up the test database (needed for samples):
1.  Double-click `SETUP_DB.bat`.
2.  If asked, enter the password you set (or just press Enter if you didn't set one).

---

## ⚡ Universal Code Runner (`runall`)

Run **any** code file with a single command! No need to remember compile commands.

### Usage
```powershell
.\runall.bat <filename> [arguments...]
```

### Examples
```powershell
# Python
.\runall.bat hello.py

# Java (auto-detects class name!)
.\runall.bat MyProgram.java

# C / C++
.\runall.bat program.c
.\runall.bat app.cpp

# SQL (runs in MySQL)
.\runall.bat query.sql

# With arguments
.\runall.bat calculator.py 5 10
```

### What It Does Automatically
| Language | Extension | Auto Actions |
|----------|-----------|--------------|
| Python | `.py` | Runs with Python interpreter |
| Java | `.java` | Detects class name, compiles, runs, cleans up `.class` files |
| C | `.c` | Compiles with GCC, runs, cleans up `.exe` |
| C++ | `.cpp` | Compiles with G++, runs, cleans up `.exe` |
| JavaScript | `.js` | Runs with Node.js |
| SQL | `.sql` | Executes in MySQL |
| PowerShell | `.ps1` | Runs script |
| Batch | `.bat` | Runs script |

**Smart Features:**
- ✅ Auto-detects `public class` name in Java files
- ✅ Auto-adds MySQL connector to classpath if JDBC is used
- ✅ Auto-links MySQL libraries for C/C++ if `mysql.h` is detected
- ✅ Cleans up compiled files after execution (use `-KeepExe` to keep them)
- ✅ Shows execution time and clear error messages

---

## 📁 Project Structure

```
java-c-cpp-python-mysql-bootstrap/
├── INSTALL.bat                    # One-click installer (run as admin)
├── UNINSTALL.bat                  # One-click uninstaller (run as admin)
├── VERIFY.bat                     # Quick verification (double-click)
├── SETUP_DB.bat                   # Database setup helper
├── runall.bat                     # Universal code runner
├── README.md                      # This file
├── LICENSE                        # MIT License
├── CONTRIBUTING.md                # Contribution guidelines
├── SECURITY.md                    # Security policy
├── .github/                       # GitHub templates
├── scripts/                       # PowerShell scripts
│   ├── install-dev-environment.ps1  # Main installation script
│   ├── uninstall-dev-environment.ps1 # Uninstallation script
│   ├── verify-installation.ps1      # Verify all tools are installed
│   ├── run-tests.ps1                # Run test programs
│   ├── runall.ps1                   # Universal code runner (PowerShell)
│   ├── quick-setup.ps1              # Minimal quick setup
│   └── install-java.ps1             # Java-only installer
├── database/                      # Database files
│   └── setup-database.sql           # Create test database and data
├── lib/                           # Downloaded libraries
│   └── mysql-connector-j/           # MySQL Java connector
├── samples/                       # Sample programs
│   ├── java/
│   │   ├── BasicTest.java           # Basic Java test
│   │   └── MySQLTest.java           # Java MySQL connectivity test
│   ├── python/
│   │   ├── basic_test.py            # Basic Python test
│   │   └── mysql_test.py            # Python MySQL connectivity test
│   ├── c/
│   │   ├── basic_test.c             # Basic C test
│   │   └── mysql_test.c             # C MySQL connectivity test
│   └── cpp/
│       ├── basic_test.cpp           # Basic C++ test
│       └── mysql_test.cpp           # C++ MySQL connectivity test
└── logs/                          # Generated logs (gitignored)
    └── installation-log.txt
```

## 🔧 Post-Installation Setup

### 1. Restart Your Computer

After installation, restart to apply PATH changes.

### 2. Initialize MySQL

Open PowerShell as Administrator:

```powershell
# Initialize MySQL data directory
mysqld --initialize-insecure

# Install MySQL as a Windows service
mysqld --install

# Start MySQL service
net start mysql
```

### 3. Set MySQL Root Password

```powershell
mysql -u root
```

Then in MySQL:
```sql
ALTER USER 'root'@'localhost' IDENTIFIED BY 'your_secure_password';
FLUSH PRIVILEGES;
EXIT;
```

### 4. Create Test Database

```powershell
mysql -u root -p < database\setup-database.sql
```

## 🧪 Running Tests

### Basic Tests (No MySQL Required)

Test that compilers and interpreters are working:

```powershell
.\scripts\run-tests.ps1 basic
```

Or test individual languages:
```powershell
.\scripts\run-tests.ps1 java -Basic
.\scripts\run-tests.ps1 python -Basic
.\scripts\run-tests.ps1 c -Basic
.\scripts\run-tests.ps1 cpp -Basic
```

### MySQL Connectivity Tests

After setting up MySQL:

```powershell
# Test all languages with MySQL
.\scripts\run-tests.ps1 all

# Or test individually
.\scripts\run-tests.ps1 java
.\scripts\run-tests.ps1 python
.\scripts\run-tests.ps1 c
.\scripts\run-tests.ps1 cpp
```

## 📝 Sample Programs

### Java Example

```java
// Compile
javac -cp ".;lib/mysql-connector-j-8.3.0/mysql-connector-j-8.3.0.jar" MySQLTest.java

// Run
java -cp ".;lib/mysql-connector-j-8.3.0/mysql-connector-j-8.3.0.jar" MySQLTest
```

### Python Example

```python
# Run directly
python mysql_test.py

# Or with virtual environment
python -m venv venv
.\venv\Scripts\activate
pip install mysql-connector-python
python mysql_test.py
```

### C/C++ Example

```bash
# C
gcc -o mysql_test.exe mysql_test.c -I"%MYSQL_INCLUDE%" -L"%MYSQL_LIB%" -lmysqlclient

# C++
g++ -o mysql_test.exe mysql_test.cpp -I"%MYSQL_INCLUDE%" -L"%MYSQL_LIB%" -lmysqlclient -std=c++17
```

## 🔍 Verification

Run the verification script to check all installations:

```powershell
.\VERIFY.bat
```

Expected output:
```
[PASS] Java : openjdk version "21.x.x"
[PASS] Java Compiler : javac 21.x.x
[PASS] GCC (C Compiler) : gcc.exe (x86_64-...) x.x.x
[PASS] G++ (C++ Compiler) : g++.exe (x86_64-...) x.x.x
[PASS] Python : Python 3.12.x
[PASS] pip : pip x.x.x
[PASS] mysql-connector-python installed
[PASS] MySQL Client : mysql Ver x.x.x
[PASS] MySQL Service is running
```

## 🗄️ Test Database

The `database\setup-database.sql` script creates:

- **Database**: `testdb`
- **User**: `testuser` / `testpass123`
- **Tables**:
  - `users` - Sample user data
  - `products` - Sample product catalog
  - `orders` - Sample orders with foreign keys

## 🛠️ Troubleshooting

### Chocolatey not recognized

Restart PowerShell or run:
```powershell
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
```

### MySQL service won't start

1. Check if data directory exists
2. Run `mysqld --initialize-insecure`
3. Try `mysqld --console` to see errors

### GCC/G++ not found

Add MinGW to PATH:
```powershell
$env:Path += ";C:\ProgramData\chocolatey\lib\mingw\tools\install\mingw64\bin"
```

### Python packages not found

```powershell
python -m pip install --upgrade pip
pip install mysql-connector-python
```

## 📦 Deploying to Other Systems

1. Copy the entire folder to the new system
2. Right-click `INSTALL.bat` → "Run as administrator"
3. Follow post-installation steps above

## 🗑️ Uninstallation

To completely remove everything installed by this bootstrap:

### Quick Uninstall
1. Right-click `UNINSTALL.bat` → **"Run as administrator"**
2. Type `UNINSTALL` when prompted to confirm
3. Restart your computer

### What Gets Removed
- Java (Eclipse Temurin JDK 21)
- MinGW-w64 (C/C++ Compiler)
- Python 3.12 and MySQL packages
- MySQL Server and Workbench
- Git
- Visual Studio Code
- Environment variables (JAVA_HOME, MYSQL_INCLUDE, MYSQL_LIB)
- Downloaded MySQL connectors
- Test database (`testdb`) and user (`testuser`)

### What Is NOT Removed
- Chocolatey (may be used by other software)
- Your own projects and code
- System files or other software

### Advanced Options

```powershell
# Uninstall everything without prompts
.\scripts\uninstall-dev-environment.ps1 -All

# Keep MySQL databases and data
.\scripts\uninstall-dev-environment.ps1 -All -KeepData

# Uninstall specific component only
.\scripts\uninstall-dev-environment.ps1 -Component mysql
.\scripts\uninstall-dev-environment.ps1 -Component python
.\scripts\uninstall-dev-environment.ps1 -Component java
```

## 📄 License

This bootstrap system is provided as-is for educational and development purposes.

Licensed under the [MIT License](LICENSE).
Copyright (c) 2026 [dmj.one](https://dmj.one).

**dmj.one - Dream, Manifest, Journey as ONE**

This project is part of the **dmj.one initiative** by **Nikhil Bhardwaj**.


## 🤝 Contributing

Feel free to submit issues and enhancement requests!
