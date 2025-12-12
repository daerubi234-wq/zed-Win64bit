<#
PowerShell smoke-test for the produced NSIS installer.
Usage: run on Windows runner after the installer `zed-setup-x64.exe` is produced.
#>

param(
    [string]$InstallerPath = "$PSScriptRoot\..\zed-setup-x64.exe",
    [string]$InstallDir = "C:\\temp\\zed-test"
)

$ErrorActionPreference = 'Stop'

Write-Host "Installer path: $InstallerPath"
if (-Not (Test-Path $InstallerPath)) { throw "Installer not found at $InstallerPath" }

if (Test-Path $InstallDir) { Remove-Item -Recurse -Force -Path $InstallDir }
New-Item -ItemType Directory -Path $InstallDir | Out-Null

Write-Host "Running installer silently to: $InstallDir"
$argsList = "/S", "/D=$InstallDir"
$p = Start-Process -FilePath $InstallerPath -ArgumentList $argsList -Wait -PassThru
Write-Host "Installer exited with code: $($p.ExitCode)"

if ($p.ExitCode -ne 0) { Write-Host "Installer returned non-zero exit code"; exit 2 }

# Look specifically for ZedAI.exe in install dir
$exePath = Join-Path $InstallDir "ZedAI.exe"
if (-Not (Test-Path $exePath)) {
    Write-Host "ZedAI.exe not found in $InstallDir"; exit 3
}
Write-Host "Found executable: $exePath"

function Try-Run($arguments) {
    Write-Host "Trying: $exePath $arguments"
    try {
        & $exePath $arguments | Out-Null
        $code = $LASTEXITCODE
    } catch {
        $code = $LASTEXITCODE
    }
    Write-Host "Exit code: $code"
    return $code
}

$tests = @("--version", "-v", "--help", "-h", "")
foreach ($t in $tests) {
    $code = Try-Run $t
    if ($code -eq 0) { Write-Host "Smoke test passed with args: '$t'"; exit 0 }
}

Write-Host "Smoke tests failed for all common flags; attempting to run without waiting (sanity run)"
try {
    $proc = Start-Process -FilePath $exePath -NoNewWindow -PassThru
    Start-Sleep -Seconds 5
    if (-not $proc.HasExited) { $proc.Kill(); Write-Host "Process started and killed (non-blocking run)"; exit 0 }
    else { Write-Host "Process exited with code $($proc.ExitCode)"; exit $proc.ExitCode }
} catch {
    Write-Host "Failed to run executable: $_"; exit 4
}
