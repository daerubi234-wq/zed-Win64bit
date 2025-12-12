; NSIS installer script for Zed Windows x64
; This script packages contents of the dist/windows-x64 folder

Name "Zed"
OutFile "zed-setup-x64.exe"
InstallDir "$PROGRAMFILES64\Zed"
RequestExecutionLevel admin

Page directory
Page instfiles

Section "Install"
  SetOutPath "$INSTDIR"
  ; include all files from the dist folder
  File /r "dist\windows-x64\*"

  ; create shortcuts to ZedAI.exe specifically
  CreateShortCut "$DESKTOP\\ZedAI.lnk" "$INSTDIR\\ZedAI.exe"
  CreateShortCut "$SMPROGRAMS\\ZedAI.lnk" "$INSTDIR\\ZedAI.exe"

  ; register uninstall
  WriteUninstaller "$INSTDIR\\uninstall.exe"
SectionEnd

Section "Uninstall"
  Delete "$DESKTOP\Zed.lnk"
  Delete "$SMPROGRAMS\Zed.lnk"
  RMDir /r "$INSTDIR"
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Zed"
SectionEnd
