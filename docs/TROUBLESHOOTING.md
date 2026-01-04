# Solutions.

**Even the best systems encounter entropy. Here is how to fix it.**

We designed the system to self-repair, but sometimes the variables are outside our control. Use this guide to resolve common issues.

## Intelligent Diagnostics

Before you panic, let the software diagnose itself.
1.  Run `start.bat`.
2.  Select **Option 2 (Verify Environment)**.
3.  Read the output. Red text indicates the specific point of failure.

---

## Common Scenarios

### 1. "The MySQL service failed to start."
**Symptom**: You see errors about "Connection refused" or "Access denied".
**Solution**:
MySQL handles can sometimes get locked by the OS.
*   Run `start.bat` and select **Option 8 (Reset MySQL Database)**. This often clears corrupted data states.
*   Open Windows Services (`services.msc`), find **MySQL**, and manually click **Restart**.

### 2. "Python/Java is not recognized."
**Symptom**: `d1run` says command not found.
**Solution**:
Windows Environment Variables sometimes require a system restart to propagate fully.
*   **Restart your computer.**
*   If that fails, run **Option 1 (Install/Update)** again. It re-asserts the PATH variables.

### 3. "The Auto-Push Monitor isn't pushing."
**Symptom**: You changed files, but GitHub shows nothing.
**Solution**:
*   Check the threshold. You might have changed 499 lines, and the limit is 500.
*   Check your internet connection.
*   View the logs in the `scripts/auto-push-monitor/logs` directory (if enabled).

### 4. "My C++ code won't compile."
**Symptom**: `fatal error: mysql.h: No such file`.
**Solution**:
Are you using `d1run`?
*   If you manually type `g++ myapp.cpp`, **it will fail**. You must link the libraries manually.
*   Always use `d1run myapp.cpp`. We handle the linking complexity for you.

---

## The "Nuclear Option"

If everything is broken and you want a fresh start:
1.  Delete the entire repository folder.
2.  Download it again from GitHub.
3.  Run `start.bat`.

The bootstrap is stateless. It will rebuild the world from scratch.

## Need Help?

If you are stuck, we are here.
Open an issue on [GitHub Issues](https://github.com/Nikhil20051/java-c-cpp-python-mysql-bootstrap/issues).

**Be descriptive.** Tell us what you saw, what you did, and what happened.
