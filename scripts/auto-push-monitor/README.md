# Code Preservation Bot.

**Peace of mind, automated.**

Programming is about flow. You shouldn't have to break your concentration just to save your progress. But we all know the fear of a crash, a mistake, or a lost hour of work.

We built the **Code Preservation Bot** to end that fear.

It lives in the background. It watches your code. When you are productive—writing new features, refactoring core logic—it silently steps in.

It detects when you've made significant changes. It automatically pushes a secure backup to GitHub. It does this using a "Bot Identity," so your personal git history remains clean and purely yours.

**It guards your work, so you don't have to.**

## How To Use It (Anywhere)

This technology isn't tied to one project. It is portable. You can—and should—take it with you.

**To protect another project:**

1.  **Copy**: Copy this entire `auto-push-monitor` folder.
2.  **Paste**: Drop it into the root folder of your other project (e.g., `D:\MyNewApp`).
3.  **Activate**: Open the folder, right-click `auto-push-monitor.ps1` and selecting "Run with PowerShell" (or type `.\auto-push-monitor.ps1 -Start` in a terminal).

That is it. Your new project is now monitored.

## Control

You stay in command.

| Action | Command |
| :--- | :--- |
| **Start Guarding** | `.\auto-push-monitor.ps1 -Start` |
| **Stop Guarding** | `.\auto-push-monitor.ps1 -Stop` |
| **Check Status** | `.\auto-push-monitor.ps1` |

## One Detail.

If you want to change how often it saves, just open `config.json`.
It is simple. It is readable.

*   `LineThreshold`: How many lines of code trigger a save? (Default: 250)
*   `CheckIntervalSeconds`: How often does it check? (Default: 10)

**Code without fear.**

*Dream. Manifest. Journey.*
*Copyright © 2026 [dmj.one](https://dmj.one).*
