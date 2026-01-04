# Universal Code Runner & Dev Environment Bootstrap

**Everything you need to code in Java, C, C++, Python, and MySQL on Windows 11.**

This project does two things:
1.  **Sets up your computer**: One-click installation of all development tools.
2.  **Runs your code**: A universal tool (`d1run`) to run any file without complex commands.

---

## 🚀 Quick Start (Reading Time: 30 seconds)

### 1. Download & Install
1.  Download this project and unzip it.
2.  Double-click **`start.bat`**.
3.  Select **Option 1** (`Install Complete Environment`).
4.  Wait for it to finish, then restart your computer.

### 2. Run Your First Code
After restarting, open a terminal (Command Prompt or PowerShell) and type:

```powershell
d1run hello.py       # Runs Python
d1run app.java       # Runs Java
d1run main.c         # Runs C
d1run script.js      # Runs Node.js
```

**That's it! You are ready to code.**

---

## 🛠️ The `start.bat` Menu

The **`start.bat`** file in the root folder is your main control center. Double-click it to see this menu:

1.  **FULL INSTALL** ⭐: Installs EVERYTHING in one step:
    - Java, GCC (C), G++ (C++), Python, MySQL Server, Git, VS Code
    - `d1run` universal code runner (installed globally)
    - MySQL Workbench (optional - you'll be asked)
    - **Automatically checks for updates before installing!**
    - **After install, just restart and code!**
2.  **Check for Updates** 🔄: Downloads the latest version from GitHub (no Git required!).
3.  **Install 'd1run' Globally Only**: Makes the `d1run` command work in any folder (if already have tools installed).
4.  **Setup Database**: Creates a sample MySQL database (`testdb`) with data.
5.  **Verify Installation**: Checks if everything is installed correctly.
6.  **Run Tests**: Runs sample programs in all languages to ensure they work.
7.  **Uninstall Everything**: Removes all tools installed by this project.
8.  **Uninstall 'd1run' Only**: Removes just the global `d1run` command.

---

## 🔄 Auto-Update Feature

This project includes a built-in auto-update mechanism that works **without Git**:

- **Automatic Check**: When you select Option 1, it automatically checks if there's a newer version available.
- **Manual Check**: Use Option 2 to check for and install updates manually.
- **No Git Required**: Updates are downloaded directly from GitHub using HTTP - no need to install Git!
- **Backup First**: Before updating, your existing files are backed up in case you need to rollback.
- **User Confirmation**: You're always asked before downloading updates.

To check for updates at any time, just run `start.bat` and select Option 2.


---

## ⚡ Universal Code Runner (`d1run`)

The star of this show is **`d1run`**. It automatically detects your file language, compiles it (if needed), links necessary libraries (like MySQL), and runs it.

**Usage:**
```powershell
d1run <filename> [arguments]
```

**Examples:**
```powershell
d1run myscript.py            # Python
d1run MyClass.java           # Java (Auto-compiles & runs)
d1run program.cpp            # C++ (Auto-links MySQL if needed)
d1run server.js              # Node.js
d1run query.sql              # SQL (Runs directly in MySQL)
```

**Features:**
*   **Automatic Compilation**: You don't need to run `javac` or `gcc` manually.
*   **Automatic MySQL Linking**: If your C/C++ code includes `<mysql.h>`, `d1run` automatically links the libraries.
*   **Smart Java**: It finds the `public class` name automatically.
*   **Clean**: It cleans up `.class` and `.exe` files after running (unless you use `-KeepExe`).

---

## 📂 Project Structure

We keep it clean. Here is what matters:

*   **`start.bat`**: The only file you need to run to manage everything.
*   **`scripts/`**: Contains the logic. You don't need to touch this unless you are customize things.
*   **`samples/`**: Example code for every language (Check these out!).
*   **`database/`**: SQL scripts for the test database.
*   **`lib/`**: External libraries (like MySQL Connectors).

---

## 📝 License & Attribution

This project by **Nikhil Bhardwaj** is a part of **[dmj.one](https://dmj.one)**'s educational initiative.

Licensed under the **MIT License**. You are free to use, modify, and distribute this software.

Copyright (c) 2026 dmj.one
