<#
PowerShell script to run on Windows runners (GitHub Actions `windows-latest`).
It builds Rust and JS parts (if present), collects artifacts into `dist/windows-x64`,
and runs NSIS to create `zed-setup-x64.exe`.
#>

param(
    [string]$OutDir = "$PSScriptRoot\..\dist\windows-x64"
)

$ErrorActionPreference = 'Stop'

Write-Host "Output directory: $OutDir"
if (-Not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }

function Run-CargoBuild {
    # build root crate if present
    if (Test-Path "$PSScriptRoot\..\Cargo.toml") {
        Write-Host "Found Cargo.toml — running cargo build --release"
        Push-Location "$PSScriptRoot\.."
        & cargo build --release
        Pop-Location

        # copy any generated exe(s)
        $targetDir = Join-Path "$PSScriptRoot\.." "target\release"
        if (Test-Path $targetDir) {
            Get-ChildItem -Path $targetDir -Filter *.exe -File | ForEach-Object {
                    # Ensure the binary is named ZedAI.exe in the dist folder
                    $dest = Join-Path $OutDir $_.Name
                    Copy-Item -Path $_.FullName -Destination $dest -Force
                    if ($_.BaseName -ne 'ZedAI') {
                        $renamed = Join-Path $OutDir 'ZedAI.exe'
                        Copy-Item -Path $_.FullName -Destination $renamed -Force
                    }
                }
        }
    } else {
        Write-Host "No Cargo.toml found — skipping Rust build"
    }

    # build upstream vendored crate if present at vendor/zed
    $vendorManifest = Join-Path "$PSScriptRoot\.." "vendor\zed\Cargo.toml"
    if (Test-Path $vendorManifest) {
        Write-Host "Found vendor/zed Cargo.toml — building upstream zed crate"
        Push-Location "$PSScriptRoot\..\vendor\zed"
        & cargo build --release
        Pop-Location

        $vendorTarget = Join-Path "$PSScriptRoot\..\vendor\zed" "target\release"
        if (Test-Path $vendorTarget) {
            Get-ChildItem -Path $vendorTarget -Filter *.exe -File | ForEach-Object {
                $dest = Join-Path $OutDir $_.Name
                Copy-Item -Path $_.FullName -Destination $dest -Force
                # ensure we have a ZedAI.exe copy
                $renamed = Join-Path $OutDir 'ZedAI.exe'
                Copy-Item -Path $_.FullName -Destination $renamed -Force
            }
        }
    }
}

function Run-NodeBuild {
    # Look for package.json in repository root
    if (Test-Path "$PSScriptRoot\..\package.json") {
        Write-Host "Found package.json — running npm ci and npm run build"
        Push-Location "$PSScriptRoot\.."
        & npm ci
        if (Test-Path "package.json") {
            try { & npm run build } catch { Write-Host "npm run build failed or not defined, continuing" }
        }
        Pop-Location

        # try to copy common build output folders
        $candidates = @("dist", "build", "out")
        foreach ($c in $candidates) {
            $src = Join-Path "$PSScriptRoot\.." $c
            if (Test-Path $src) { Copy-Item -Path $src -Destination (Join-Path $OutDir $c) -Recurse -Force }
        }
    } else {
        Write-Host "No package.json found — skipping Node build"
    }
}

function Create-Installer {
    # Ensure NSIS is available (on GitHub Actions windows-latest install via choco)
    Write-Host "Looking for makensis..."
    $makensis = Get-Command makensis -ErrorAction SilentlyContinue
    if (-Not $makensis) {
        Write-Host "makensis not found. Attempting to install NSIS via choco"
        & choco install nsis -y
    }

    $installerScript = Join-Path "$PSScriptRoot\.." "installer\zed_installer.nsi"
    if (-Not (Test-Path $installerScript)) { throw "Installer script not found: $installerScript" }

    Push-Location "$PSScriptRoot\.."
    & makensis /V4 $installerScript
    Pop-Location

    # move created exe to OutDir
    $outExe = Join-Path "$PSScriptRoot\.." "zed-setup-x64.exe"
    if (Test-Path $outExe) { Move-Item -Path $outExe -Destination $OutDir -Force }
}

Run-CargoBuild
Run-NodeBuild
Create-Installer

Write-Host "Packaging complete. Artifacts placed in: $OutDir"
