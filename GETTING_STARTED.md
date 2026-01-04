# Begin.

**From Zero to Engineer in Minutes.**

We didn't just make an installer. We created an onboarding experience. This guide will walk you through the very first moments of your journey with the Universal Bootstrap.

## Prerequisites

You need a computer.
*   **OS**: Windows 10 or Windows 11 (64-bit).
*   **Connection**: Internet access (for the initial download).
*   **Rights**: Administrator privileges (to install the services).

That is it. No pre-installed Java. No Python. No complex path variables. We handle all of that.

## The Installation

### 1. Download
Grab the latest version of the bootstrap.
*   Navigate to the [GitHub Repository](https://github.com/Nikhil20051/java-c-cpp-python-mysql-bootstrap).
*   Click the **Green Code Button**.
*   Select **Download ZIP**.

### 2. Extract
The magic cannot happen inside a ZIP file.
*   Right-click the downloaded `.zip` file.
*   Select **Extract All**.
*   Choose a destination (e.g., `C:\Dev` or `D:\Coding`).
    *   *Tip: Shorter paths are better.*

### 3. Ignite
*   Open the extracted folder.
*   Find **`start.bat`**.
*   **Double-click it.**

## The Black Box

When you run `start.bat`, you will see our dashboard. It is a simple, command-line interface designed for clarity.

You will see options like:
1.  **Install/Update Development Environment**
2.  **Verify Environment & Path**
3.  **Run All Tests**
4.  **...and more.**

**Select Option 1.**

Then, step back.

This is where the software shines. It will:
*   **Scan** your system for existing tools.
*   **Download** missing components (Java JDK, Python, MinGW C++, MySQL).
*   **Install** them silently in the background.
*   **Configure** your System PATH variables automatically.
*   **Initialize** the MySQL Database Service with a secure, standard configuration.
*   **Install** Visual Studio Code and Git if you don't have them.

It cleans up after itself. When it says **"Success"**, your machine has effectively been upgraded.

## Validation

Don't just take our word for it.

Return to the main menu in `start.bat` and **Select Option 2 (Verify Environment)**.

We will run a series of diagnostic health checks. You should see a cascade of green "OK" statuses.
*   `java` ... OK
*   `python` ... OK
*   `gcc` ... OK
*   `mysql` ... OK

If you see this, you are ready.

## Next Steps

Now that you have the power, you need to know how to wield it.
Proceed to [**The Manual**](docs/THE_MANUAL.md) to learn how to write, compile, and execute code with our unified engine.
