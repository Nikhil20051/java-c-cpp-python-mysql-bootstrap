# Install Java - Quick script (self-elevating)
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "Installing Java (Eclipse Temurin)..." -ForegroundColor Yellow

# Refresh PATH first
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

# Install Java
& "C:\ProgramData\chocolatey\bin\choco.exe" install temurin -y

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n[SUCCESS] Java installed!" -ForegroundColor Green
    
    # Set JAVA_HOME
    $javaPaths = @(
        "C:\Program Files\Eclipse Adoptium\jdk-*",
        "C:\Program Files\Temurin\jdk-*"
    )
    foreach ($pattern in $javaPaths) {
        $found = Get-ChildItem -Path $pattern -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) {
            [System.Environment]::SetEnvironmentVariable("JAVA_HOME", $found.FullName, "Machine")
            Write-Host "JAVA_HOME set to: $($found.FullName)" -ForegroundColor Green
            break
        }
    }
} else {
    Write-Host "[ERROR] Failed to install Java" -ForegroundColor Red
}

Write-Host "`nPress any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
