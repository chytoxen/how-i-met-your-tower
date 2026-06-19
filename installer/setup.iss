; Inno Setup script for "How I Met Your Tower".
; Inno Setup is free: https://jrsoftware.org/isdl.php
; Build the game first (../build_windows.sh) so ../builds/HowIMetYourTower.exe exists,
; then open this in Inno Setup and click Compile. Output: HowIMetYourTower-Setup.exe
; — a normal Windows installer you can hand to friends.

#define MyAppName "How I Met Your Tower"
#define MyAppVersion "0.8.0"
#define MyAppPublisher "Squad Six"
#define MyAppExe "HowIMetYourTower.exe"

[Setup]
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\HowIMetYourTower
DefaultGroupName=How I Met Your Tower
DisableProgramGroupPage=yes
OutputBaseFilename=HowIMetYourTower-Setup
Compression=lzma2
SolidCompression=yes
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
WizardStyle=modern
UninstallDisplayIcon={app}\{#MyAppExe}

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional icons:"

[Files]
Source: "..\builds\HowIMetYourTower.exe"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\How I Met Your Tower"; Filename: "{app}\{#MyAppExe}"
Name: "{group}\Uninstall How I Met Your Tower"; Filename: "{uninstallexe}"
Name: "{commondesktop}\How I Met Your Tower"; Filename: "{app}\{#MyAppExe}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExe}"; Description: "Launch How I Met Your Tower"; Flags: nowait postinstall skipifsilent
