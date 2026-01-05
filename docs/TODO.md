# 🚀 Future Roadmap & Wishlist

> "The best way to predict the future is to invent it."

This document tracks ideas, feature requests, and the long-term vision for the Universal Bootstrap.

## 🏗️ Infrastructure & Core

- [ ] **Docker "Containerize This"**:
    - Add `d1run dockerize` command.
    - Automatically generate a `Dockerfile` and `docker-compose.yml` based on the project's language (Java, Python, C++, etc.).
    - Allow one-click local container deployment.

- [ ] **Cloud Deployment Adaptors**:
    - `d1run deploy aws` / `d1run deploy azure`.
    - Simple Terraform scripts to lift the current local environment to a cloud VM.

- [ ] **Linter & Formatter Integration**:
    - Pre-commit hooks for `clang-format` (C/C++), `black` (Python), and `google-java-format` (Java).
    - Ensure code consistency automatically.

## 🧠 Intelligence & AI

- [ ] **Local AI Code Reviewer**:
    - A script that sends the current diff to a local LLM (e.g., via Ollama) for a quick security and style review before auto-pushing.

- [ ] **Dependency Graph Visualizer**:
    - Generate a visual map of imports and dependencies for complex projects.

## 🎨 User Experience

- [ ] **Web-Based Dashboard**:
    - Replace the console text `start.bat` menu with a sleek local web interface (running on localhost).
    - Visual toggles for services (MySQL start/stop).
    - Real-time charts for the "Auto-Push Monitor" and "Project Stats".

- [ ] **Interactive CLI**:
    - Upgrade `d1run` to support an interactive mode (`d1run --interactive`) for complex argument building.

## 🛡️ Security

- [ ] **Secret Scanning**:
    - Prevent accidental commits of API keys or passwords by scanning file contents before the Auto-Push Monitor triggers.

- [ ] **Audit Trail**:
    - Keep a local immutable log of all commands executed via `d1run` for debugging and security auditing.

---

*Have an idea? Add it here. We build what we dream.*
