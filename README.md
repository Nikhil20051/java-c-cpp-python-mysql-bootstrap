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

1.  **Install Complete Environment**: Installs Java, GCC (C), G++ (C++), Python, MySQL, and VS Code.
2.  **Install 'd1run' Globally**: Makes the `d1run` command work in any folder.
3.  **Setup Database**: Creates a sample MySQL database (`testdb`) with data.
4.  **Verify Installation**: Checks if everything is installed correctly.
5.  **Run Tests**: Runs sample programs in all languages to ensure they work.
6.  **Uninstall Everything**: Removes all tools installed by this project.

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
