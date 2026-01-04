# Development Environment Bootstrap for Windows 11

A complete one-click solution to set up a fresh Windows 11 system with Java, C, C++, Python, and MySQL development environments.

## 🚀 Quick Start

### One-Click Installation

1. **Right-click** on `INSTALL.bat` and select **"Run as administrator"**
2. Wait for the installation to complete (15-30 minutes)
3. **Restart your computer**
4. Run `verify-installation.ps1` to confirm everything is installed

### What Gets Installed

| Component | Version | Purpose |
|-----------|---------|---------|
| Chocolatey | Latest | Package manager |
| OpenJDK | 21 | Java development |
| MinGW-w64 | Latest | C/C++ compiler (GCC/G++) |
| Python | 3.12 | Python development |
| MySQL Server | Latest | Database server |
| MySQL Workbench | Latest | Database GUI |
| Git | Latest | Version control |
| VS Code | Latest | Code editor |

## 📁 Project Structure

```
java-c-cpp-python-mysql-bootstrap/
├── INSTALL.bat                    # One-click installer (run as admin)
├── install-dev-environment.ps1   # Main PowerShell installation script
├── verify-installation.ps1       # Verify all tools are installed
├── run-tests.ps1                 # Run test programs
├── setup-database.sql            # Create test database and data
├── README.md                     # This file
├── lib/                          # Downloaded libraries
│   └── mysql-connector-j/        # MySQL Java connector
└── samples/
    ├── java/
    │   ├── BasicTest.java        # Basic Java test
    │   └── MySQLTest.java        # Java MySQL connectivity test
    ├── python/
    │   ├── basic_test.py         # Basic Python test
    │   └── mysql_test.py         # Python MySQL connectivity test
    ├── c/
    │   ├── basic_test.c          # Basic C test
    │   └── mysql_test.c          # C MySQL connectivity test
    └── cpp/
        ├── basic_test.cpp        # Basic C++ test
        └── mysql_test.cpp        # C++ MySQL connectivity test
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
mysql -u root -p < setup-database.sql
```

## 🧪 Running Tests

### Basic Tests (No MySQL Required)

Test that compilers and interpreters are working:

```powershell
.\run-tests.ps1 basic
```

Or test individual languages:
```powershell
.\run-tests.ps1 java -Basic
.\run-tests.ps1 python -Basic
.\run-tests.ps1 c -Basic
.\run-tests.ps1 cpp -Basic
```

### MySQL Connectivity Tests

After setting up MySQL:

```powershell
# Test all languages with MySQL
.\run-tests.ps1 all

# Or test individually
.\run-tests.ps1 java
.\run-tests.ps1 python
.\run-tests.ps1 c
.\run-tests.ps1 cpp
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
.\verify-installation.ps1
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

The `setup-database.sql` script creates:

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

## 📄 License

This bootstrap system is provided as-is for educational and development purposes.

## 🤝 Contributing

Feel free to submit issues and enhancement requests!
