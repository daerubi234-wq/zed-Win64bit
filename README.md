# zed-Win64bit

ZedAI-IDE

## Windows x64 Installer (automated)

This repository includes automation to build a Windows x64 installer (`zed-setup-x64.exe`) via GitHub Actions.

- CI workflow: `.github/workflows/windows.yml` builds on `windows-latest`, runs the build script, and uploads the installer as an artifact.
- Build script: `scripts/build-windows.ps1` — builds Rust (`cargo`) and Node (`npm`) parts if present, collects artifacts into `dist/windows-x64`, and runs the NSIS script.
- NSIS script: `installer/zed_installer.nsi` — packages the `dist/windows-x64` folder into `zed-setup-x64.exe` and creates shortcuts.

To trigger a build:

1. Push to `main`, create a Release, or run the workflow manually in Actions.
2. Download the artifact named `zed-windows-x64-installer` from the workflow run.

To build locally on Windows (recommended on a Windows 10/11 machine):

1. Install Rust and Node.js and ensure `cargo`, `npm` are on PATH.
2. Install NSIS (or use Chocolatey):

```
choco install nsis -y
```

3. From PowerShell (run as Administrator to allow Program Files install):

```
powershell -ExecutionPolicy ByPass -File .\scripts\build-windows.ps1
```

The installer will be produced at `dist\windows-x64\zed-setup-x64.exe`.
# zed-Win64bit
ZedAI-IDE
