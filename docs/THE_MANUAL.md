# The Manual.

**Control your craft.**

Most development environments force you to memorize a dictionary of commands. `javac`. `python`. `g++`. `cmake`. `pip`. Linker flags. Classpaths.

We believe your brain space is better used for problem-solving, not command-memorizing.

This manual explains how to use the **Universal Bootstrap** tools to write, run, and manage your code.

## The Core Tool: `d1run`

This is the heart of our automation. `d1run` (Day One Run) is a polyglot execution engine. It looks at your file, understands what language it is, determines what libraries it needs, and executes it.

### usage

Open your terminal (or use the built-in terminal in VS Code) and type:

```powershell
d1run <filename> [arguments]
```

### Examples

#### 1. Running Python
Standard Python execution.
```powershell
d1run hello.py
```
*   **What it does**: Locates the correct Python interpreter in our managed path and executes the script.

#### 2. Running Java
No more `javac` then `java`.
```powershell
d1run MyApplication.java
```
*   **What it does**: Compiles the Java file to bytecode and immediately executes the class. It automatically handles the classpath for you. 
*   **Maven/Gradle Support**: If `d1run` detects a `pom.xml` or `build.gradle` file in your project directory, it automatically switches to using Maven or Gradle respectively to build and run your project. It enables enterprise-grade dependency management without you needing to configure it manually.

#### 3. Running C++ (The Magic)
This is where `d1run` is revolutionary.
```powershell
d1run complex_app.cpp
```
*   **What it does**:
    *   Invokes `g++`.
    *   **Auto-Links**: If you use MySQL headers, it automatically includes the MySQL `include` and `lib` directories.
    *   **Static Linking**: It compiles with `--static`, so the resulting `.exe` can be copied to *any* Windows machine and run without installing MinGW or DLLs.
    *   **Executes**: Runs the resulting binary.

#### 4. Running C
Same power as C++, for pure C.
```powershell
d1run legacy.c
```

---

## The Database

Your environment comes with a production-grade MySQL Server.

*   **Host**: `localhost`
*   **Port**: `3306`
*   **User**: `root`
*   **Password**: *(Empty by default for local development ease, or set by you)*

### Resetting the Database
If you mess up your data (which you will, that's part of learning), you can wipe the slate clean.

1.  Run `start.bat`.
2.  Select **Option 4 (Setup Database)**.
3.  This drops all schemas and re-initializes a fresh "test_db".

---

## Security & Credentials

Hardcoding passwords is a sin. We provide a **Credentials Manager** to keep your secrets safe.

### Usage
The bootstrap automatically rotates keys for the "Code-Ninja" bot.
*   **Scripts**: Use `scripts\credentials-manager.ps1` to securely store and retrieve API keys or database passwords without saving them in plain text.

---

## The Auto-Push Monitor

**"I forgot to save to GitHub."**
Never say this again.

The **Auto-Push Monitor** is your safety net. It runs in the background while you work.

### How it works
1.  **Activates**: You turn it on via `start.bat` (**Option 9**) or by running `scripts\launch-monitor.bat`.
2.  **Watches**: It observes the folder `samples` (or your chosen project folder).
3.  **Detects**: It counts the lines of code you change.
4.  **Acts**: once you have changed **500 lines** (configurable), it automatically:
    *   Commits your work.
    *   Pushes it to your remote GitHub repository.
    *   Uses a special identity ("DMJ.one Code-Ninja") so you know which commits were automated.

**Peace of Mind.** You focus on the code. We ensure it is never lost.

---

## The Dynamic Test Suite

**"But does it work... everywhere?"**

We have included a powerful **Dynamic Test Generator** to stress-test your code.

### Usage
Run the test generator to create chaos and verify stability:
```powershell
d1run tests
```
*   **Stress Testing**: It throws random inputs, edge cases, and massive datasets at your code.
*   **Fuzz Testing**: Generates invalid data to see if your program crashes gracefully.
*   **Polyglot**: Writes tests for Python, C, C++, and Java automatically.

---

## Project Statistics

Want to see how much you've accomplished? We include a line-counting tool that provides deep insights into your codebase.

### Usage
```powershell
d1run stats
```
This generates a detailed report in `docs\PROJECT_STATS.md`, showing:
*   Total lines of code (LOC).
*   Language breakdown (Pie charts!).
*   Physical print metrics (How tall would the stack of paper be?).


---

## Folder Structure

Stay organized. The bootstrap expects a certain order, though you are free to roam.

*   `\root`
    *   `start.bat`: Your control center.
    *   `GETTING_STARTED.md`: Your first guide.
    *   `docs\`: Deep documentation (including this manual).
    *   `samples\`: Place your code here to test.
    *   `scripts\`: The engine room (PowerShell scripts).
    *   `lib\`: Libraries and dependencies.

## Advanced: Passing Arguments

Need to pass command line arguments to your C++ or Python program? `d1run` passes everything after the filename directly to your code.

```powershell
d1run data_processor.py --verbose --input file.txt
```
Your python script receives `--verbose`, `--input`, and `file.txt` exactly as expected.

## Conclusion

The tools are simple because the engineering behind them is complex. We hid the complexity so you can reveal your creativity.

**Go build something beautiful.**
