# FAQ.

**Questions, Answered.**

### Q: Is this really free?
**A:** Yes. 100%. Open Source. MIT License. We believe tools should be free so knowledge can be free.

### Q: Why not just use Docker?
**A:** Docker is brilliant, but it adds a layer of abstraction (containers) that can be confusing for beginners or overkill for simple native development. We believe in running code **on the metal**. When you compile C++ here, it runs on Windows, natively. It is faster, simpler, and closer to the hardware.

### Q: Can I use this for production?
**A:** The tools we install (OpenJDK, MySQL Server) are production-grade. However, this environment is tuned for **Development**. The security settings (like default passwords) are set for ease of access, not hardened security. Use the code you write here in production, but do not use this *setup* script to provision a production server.

### Q: Why PowerShell?
**A:** It is the native language of Windows automation. Ideally, we would use a cross-platform language, but to deeply configure Windows (registry, services, paths), PowerShell is the most robust tool for the job.

### Q: My antivirus thinks `d1run` is suspicious.
**A:** `d1run` acts as a "shell" that invokes other programs (compilers). Short-lived scripts that spawn processes can sometimes trigger heuristics. You can safely whitelist the folder. The code is open source; read it yourself in `scripts/d1run.ps1`.

### Q: Can I change the editor?
**A:** We install VS Code because it is the standard. But if you prefer IntelliJ, Eclipse, or Vim, go ahead. The environment variables are set globally. You can use any tool you like.

### Q: Who is behind this?
**A:** This is a project by the **dmj.one** initiative, maintained by Nikhil Bhardwaj. We are a collective of engineers dedicated to open education.

**Still have questions?**
Check the [Troubleshooting Guide](TROUBLESHOOTING.md) or ask us on GitHub.
