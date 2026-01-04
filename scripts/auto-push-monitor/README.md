# Auto-Push Monitor

A portable PowerShell module that automatically pushes your git repository changes to GitHub when they exceed a configurable line threshold.

## Features

- **Automatic Backup**: Pushes changes before they exceed 500 lines (configurable)
- **Bot Identity**: Commits are made with "Automatic Update Bot" identity, making them easily distinguishable from manual commits
- **Non-Invasive**: Does not modify your global git configuration
- **Portable**: Copy this entire folder to any project to use it
- **Configurable**: Threshold, interval, and target folder can all be customized

## Quick Start

```powershell
# Check current status
.\auto-push-monitor.ps1

# Start monitoring (uses config.json settings)
.\auto-push-monitor.ps1 -Start

# Stop monitoring
.\auto-push-monitor.ps1 -Stop
```

## Commands

| Command | Description |
|---------|-------------|
| `-Start` | Start monitoring the repository |
| `-Stop` | Stop the monitor |
| `-Status` | Show current status (default) |
| `-Configure` | Interactive configuration |

## Parameters for -Start

| Parameter | Description |
|-----------|-------------|
| `-TargetFolder <path>` | Override the folder to monitor |
| `-LineThreshold <number>` | Override the line change threshold |
| `-CheckIntervalSeconds <number>` | Override the check interval |

### Examples

```powershell
# Monitor a different folder
.\auto-push-monitor.ps1 -Start -TargetFolder "D:\MyOtherProject"

# Use a lower threshold
.\auto-push-monitor.ps1 -Start -LineThreshold 100

# Check more frequently
.\auto-push-monitor.ps1 -Start -CheckIntervalSeconds 10
```

## Configuration

Edit `config.json` to change default settings:

```json
{
  "TargetFolder": "path/to/repo",
  "LineThreshold": 500,
  "CheckIntervalSeconds": 30,
  "Enabled": true
}
```

## How It Works

1. The monitor periodically checks for unstaged changes in your repository
2. It calculates the total lines added/removed across all modified files
3. When changes exceed the threshold, it:
   - Stages all changes
   - Creates a commit with the bot identity
   - Pushes to the remote repository
4. Your working directory is left with the changes still present (they were just backed up)

## Bot Identity

Automatic commits are made with:
- **Name**: Automatic Update Bot
- **Email**: auto-update-bot@noreply.local

This makes them easily identifiable in your git history:

```
git log --oneline
abc1234 [AUTO-PUSH] Automatic backup before large changes
def5678 Your manual commit message
```

## Portability

To use this module in another project:

1. Copy the entire `auto-push-monitor` folder to your project
2. Update `config.json` with your project's path
3. Run `.\auto-push-monitor.ps1 -Start`

## Files

| File | Purpose |
|------|---------|
| `auto-push-monitor.ps1` | Main script |
| `config.json` | Configuration settings |
| `monitor.pid` | Process ID (created when running) |
| `monitor.log` | Activity log |
| `README.md` | This documentation |

## Troubleshooting

### "Not a git repository"
Ensure the target folder contains a `.git` directory.

### "Failed to push"
Check that you have push access to the remote repository and your credentials are configured.

### Monitor not detecting changes
The monitor only detects changes to tracked files and new untracked files. Files in `.gitignore` are excluded.
