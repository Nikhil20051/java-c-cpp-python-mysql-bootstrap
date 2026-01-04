# 🚀 Universal Bootstrap: The Ultimate Developer Experience
> *“It just works. Everything you need to code in Java, C, C++, Python, and MySQL. One click. Zero headache.”*

---

## 🛑 The Problem: Setting Up is a Nightmare
You want to code. You don't want to spend hours debugging environment variables, fixing `PATH` errors, installing five different compilers, and troubleshooting why MySQL isn't connecting to Python. 

The traditional way is broken. It’s boring, frustrating, and a waste of your creative potential.

## ✨ The Solution: Universal Bootstrap
We’ve built the **iPhone of development environments**. A fully integrated, seamless, and beautiful system that installs effectively instantly and manages itself. It transforms a fresh Windows machine into a professional engineering workstation in minutes.

### 💎 Unique Value Propositions
> **[👉 View Full Feature List](FEATURES.md)**

#### 1. ⚡ One-Click Ecosystem
Double-click `start.bat`. That’s it. We handle the rest.
We install and configure:
- **Java Development Kit** (Latest OpenJDK)
- **Python** (Latest or 3.8 - your choice) 🐍
- **C/C++ Chain** (MinGW-w64 GCC/G++) 🔨
- **MySQL Server (Latest)** (Fully initialized service) 🗄️
- **VS Code** (The best editor) 💻
- **Git** (Version control) 🌳

#### 2. 🔮 `d1run`: The Only Command You Need
Forget `javac`, `g++`, `python`, `node`. We built **`d1run`**, a universal runner that intelligently understands your code.
- **Java?** It auto-compiles and finds your main class.
- **C++?** It auto-links valid libraries (even MySQL!).
- **Python?** It runs instantly.
- **SQL?** It executes queries directly against your local database.

**Just type:** `d1run my_script.any`

#### 3. 🛡️ Self-Updates & Resilience
This system is alive. Every time you run the installer, it checks our central repository for the latest improvements. It updates itself without you needing to know Git commands. It’s always fresh.

#### 4. 🤖 Code Preservation Bot (Bonus!)
Includes a powerful Auto-Push Monitor. Type `apm -Start` in any directory to watch it. If you modify more than 500 lines of code, it **automatically commits and pushes** your work to GitHub as a bot, ensuring you never lose significant progress.

---

## 🚀 How to Start (The 30-Second Guide)

1. **Download & Extract**
   Grab this project folder. Put it anywhere (e.g., `D:\MyCode`).

2. **Run `start.bat`**
   Double-click the file. You will see a beautiful menu.
   - Select **Option 1: FULL INSTALL**.
   - Watch the magic happen.
   - **restart your PC** to lock in the environment variables.

3. **Restart & Code**   
   Once you have restarted your PC, open any terminal (CMD/PowerShell) and type:
   ```powershell
   d1run hello.py
   ```

---

## 🎮 The Control Center (`start.bat`)
Your dashboard for everything.

| Option | Feature | Description |
| :--- | :--- | :--- |
| **1** | **FULL INSTALL** | Installs Java, C/C++, Python, MySQL, Git, VS Code + `d1run`. |
| **2** | **Update Software** | Fetches the latest version of this bootstrap from the cloud. |
| **3** | **Install `d1run`** | Only installs the magic runner (lightweight mode). |
| **4** | **Setup Database** | Re-initializes MySQL with a fresh `testdb` and sample data. |
| **5** | **Verify System** | Runs a diagnostic check on all tools. |
| **6** | **Run Tests** | Compiles and runs sample code in every language. |

---

## 🏆 For The Technical Mind
We didn't cut corners. This is professional-grade engineering.
- **Idempotence**: Run the installer 100 times; it won't break anything. It only fixes what's missing.
- **Sandbox Ready**: Fully tested in Windows Sandbox for isolated deployments.
- **Non-Destructive**: We respect your existing PATH entries while ensuring ours take precedence where needed.
- **Production MySQL**: We install the real MySQL Server service, not a toy implementation.

## 🤝 Open Source & Attribution
**Built with ❤️ for the [dmj.one](https://dmj.one) initiative.**
*Created by Nikhil Bhardwaj.*

Released under the **MIT License**.
*Copyright © 2026 dmj.one. All rights reserved.*

---
> *Programming shouldn't be hard. Setup shouldn't be boring. Welcome to the future.*
