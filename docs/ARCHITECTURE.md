# Architecture.

**The anatomy of a universal environment.**

We did not simply throw scripts into a folder. We architected a system designed for resilience, portability, and idempotency.

This document details the internal design of the Java-C-CPP-Python-MySQL Bootstrap.

## Design Principles

### 1. Idempotency
Every script in this codebase is idempotent. You can run `install-dev-environment.ps1` once, or a thousand times. The result is always the same: a correct, consistent state. It checks before it writes. It validates before it installs.

### 2. Zero-Global-Dependency (Where Possible)
We strive to keep the environment contained. While we edit the User PATH for convenience, we prefer portable tools. `d1run` dynamically resolves paths rather than blindly trusting the global environment.

### 3. Fail-Safe Operations
The Auto-Push Monitor is built with a separate "process space" mentality. It runs independently of your compiler. If your code crashes, the monitor survives. If the monitor crashes, it restarts.

## Component Deep Dive

### The Bootstrapper (`start.bat` & `scripts/`)

The entry point is a Batch file, but the brain is PowerShell Core.
*   **`start.bat`**: A lightweight wrapper. Its only job is to elevate privileges (Admin Request) and launch the PowerShell controller.
*   **`install-dev-environment.ps1`**: The heavy lifter. It uses `winget` (Windows Package Manager) and direct HTTP calls to fetch dependencies.
*   **`ensure-config-files.ps1`**: The healer. It checks for critical configuration files (like `.env`) and recreates them from templates if they are missing.

### The Execution Engine (`d1run.ps1`)

`d1run` works on a **Pipeline Architecture**:
1.  **Input Analysis**: Parses extension (`.java`, `.cpp`, `.py`).
2.  **Environment Resolution**: Locates the absolute path of the compiler/interpreter. It does *not* assume `java` is in PATH; it looks where we installed it first.
3.  **Dependency Injection**:
    *   For C++, it injects `-I` (Include) and `-L` (Linker) flags for MySQL and OpenSSL.
    *   For Java, it constructs the Classpath `-cp` to include the MySQL JDBC driver located in `\lib`.
4.  **Process Execution**: Spawns the child process and pipes Standard IO (Stdin/Stdout/Stderr) directly to the user console.

### The Monitor (`auto-push-monitor`)

A dedicated daemon.
*   **FileSystemWatcher**: Uses the .NET `System.IO.FileSystemWatcher` class to listen for low-level disk I/O events (Changed, Created, Deleted).
*   **Debouncing**: Implements a "cool-down" logic. It aggregates rapid file changes (like a Save All action) into a single "event" to avoid spamming Git.
*   **Scope Isolation**: Uses a completely different `git config` (local to the repo) to set the "Code-Ninja" identity, ensuring it never touches your global `.gitconfig`.

## Data Persistence

*   **MySQL Service**: Installed as a Windows Service (`MySQL80` equivalent).
*   **Data Directory**: Default location `C:\ProgramData\MySQL`.
*   **Credentials**: Stored securely in embedded scripts (env-managed) or user-prompted during initialization.

## Directory Hierarchy

```text
/
├── .github/          # CI/CD Workflows (GitHub Actions)
├── database/         # SQL Initialization scripts
├── lib/              # JDBC JARs, C++ Headers (if portable)
├── samples/          # Playground for User Code
├── scripts/          # The Logic Core (PS1)
│   ├── auto-push-monitor/
│   └── ...
├── start.bat         # User Entry Point
└── LICENSE           # MIT License
```

## Security Model

*   **Execution Policy**: The scripts temporarily bypass execution policy (`-ExecutionPolicy Bypass`) only for the scope of the process. We do not permanently alter your system's security stance.
*   **Credential Handling**: Default credentials are transparently documented. Production usage suggests changing root passwords immediately after the first successful boot.

---

**Built with precision. Engineered for reliability.**
