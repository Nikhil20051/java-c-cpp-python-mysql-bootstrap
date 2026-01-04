# ✨ Comprehensive Feature List
> *The complete breakdown of everything the Universal Bootstrap system can do.*

This document serves as the master tracking list for all capabilities of the **Universal Bootstrap** environment.

---

## 🛠️ Core Installation & Environment (`start.bat`)
The installer is idempotent and handles the complete setup of a professional engineering workstation.

- **Automated Toolchain Setup**
  - [x] **Java Development Kit**: Installs Latest OpenJDK (automatically sets `JAVA_HOME`).
  - [x] **Python Environment**: Interactive choice between **Latest Python** or **Python 3.8** (legacy compatibility).
  - [x] **C/C++ Compiler**: Installs MinGW-w64 (GCC/G++) for native compilation.
  - [x] **MySQL Server**: Installs full MySQL Server (not just client).
  - [x] **MySQL Workbench**: Optional installation of the GUI database manager.
  - [x] **Visual Studio Code**: Installs the latest VS Code editor.
  - [x] **Git**: Installs Git version control system.
  - [x] **Build Tools**: Adds `make`, `gcc`, `g++` to global PATH.

- **Intelligent Configuration**
  - [x] **Path Management**: Automatically audits and refreshes User and Machine `PATH` variables.
  - [x] **Service Management**: Auto-initializes, starts, and verifies the MySQL Windows Service.
  - [x] **Dependency Resolution**: Automatically downloads missing MySQL C/C++ headers if the server package omits them.
  - [x] **Python Dependencies**: Auto-installs `mysql-connector-python` and `pymysql` via pip.
  - [x] **Java Libraries**: Downloads `mysql-connector-j` jar for JDBC connectivity.

---

## 🔮 `d1run`: Universal Code Runner
A global command-line tool (`d1run`) to execute code in any language instantly.

- **Universal Language Support**
  - [x] **Python** (`.py`): Runs with the configured system Python.
  - [x] **Java** (`.java`): Auto-compiles and runs.
    - *Smart Class Detection*: Finds the `public class` name even if it doesn't match the filename (warns user).
    - *Auto-Classpath*: Automatically includes MySQL JDBC drivers if `import java.sql` is detected.
  - [x] **C** (`.c`) & **C++** (`.cpp`): Compiles Single-File execution.
    - *Static Linking*: Defaults to `-static` builds (creates portable `.exe` files that run anywhere).
    - *Release Mode*: Compiles with `-O2` and `-s` (strip symbols) for performance.
    - *Auto-Link MySQL*: Automatically links `libmysqlclient` if `mysql.h` usage is detected.
  - [x] **JavaScript** (`.js`): Executes via Node.js.
  - [x] **SQL** (`.sql`): Executes directly against the local MySQL instance.
  - [x] **Shell Scripts**: Runs `.bat`, `.cmd`, and `.ps1` files transparently.

- **Advanced Execution Features**
  - [x] **Argument Passing**: Pass arguments directly to your script (e.g., `d1run app.py arg1 arg2`).
  - [x] **Error Intelligence**: Parses raw compiler output to generate readable **Error Reports** with line numbers and specific fix suggestions.
  - [x] **Clean Mode**: `d1run file.c -Clean` runs the code and immediately deletes the generated `.exe`.
  - [x] **Database Context**: Supports `-MySQLUser`, `-MySQLPass`, `-MySQLDatabase` flags for SQL execution.

---

## 🤖 `apm`: Auto-Push Monitor
A background daemon ("DMJ.one Code-Ninja") that ensures work is never lost.

- **Monitoring Capabilities**
  - [x] **Watcher**: Monitors a specific folder (recursive) for file changes.
  - [x] **Threshold Trigger**: Automatically actions when added/removed lines exceed a limit (Default: 500 lines).
  - [x] **Bot Identity**: Commits using a distinct identity (`DMJ.one Code-Ninja`) to separate manual vs. auto-saves.
  - [x] **Global Access**: Manage from anywhere using the `apm` command.

- **Controls**
  - [x] `apm -Start`: Start monitoring the current directory.
  - [x] `apm -Stop`: Stop the background process.
  - [x] `apm -Status`: View current changes and monitor status.
  - [x] `apm -Configure`: Interactive setup for threshold, bot name, and target folder.

---

## 🛡️ Self-Maintenance & System Health
Features designed to keep the environment healthy and up-to-date.

- **Update System**
  - [x] **Self-Update**: Checks the central GitHub repository for newer versions of the bootstrap scripts.
  - [x] **Automatic Backup**: Backs up current scripts to `.update-backup` before applying changes.
  - [x] **Version Tracking**: Compares local `VERSION` file with remote.

- **Database Tools**
  - [x] **Auto-Setup**: `start.bat` Option 4 drops and recreates a clean `testdb` with `users`, `products`, and `orders` tables.
  - [x] **Credential Management**: Generates/Loads generic test credentials (`testuser` / `testpass123`) for development ease.
  - [x] **Recovery**: Can initialize a raw MySQL Data directory if the service is broken or missing.

- **Quality Assurance**
  - [x] **Verify System**: `start.bat` Option 5 runs a diagnostic on all installed tools (`java --version`, `gcc --version`, etc.).
  - [x] **Run Tests**: `start.bat` Option 6 compiles and executes a "Hello World + Database" sample in every supported language to prove the system works.

---

## 📋 Technical Specifications
- **OS Support**: Windows 10 / Windows 11
- **Architecture**: x64
- **License**: MIT License
- **Attribution**: Built for the [dmj.one](https://dmj.one) initiative.
