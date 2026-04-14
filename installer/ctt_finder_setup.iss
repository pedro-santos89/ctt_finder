; CTT Finder — Inno Setup installer script
; Compile with Inno Setup 6: https://jrsoftware.org/isinfo.php
;
; Before compiling, build the Windows release:
;   flutter build windows --release
;
; Then compile this script:
;   iscc installer\ctt_finder_setup.iss
;
; Output: installer\Output\CTTFinderSetup.exe

#define MyAppName "CTT Finder"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Anima Rasa Prod."
#define MyAppExeName "ctt_finder.exe"
#define MyAppURL "https://github.com/anima-rasa-prod/ctt-finder"

; Path to the Flutter Windows release build (relative to this .iss file)
#define BuildDir "..\build\windows\x64\runner\Release"

[Setup]
AppId={{E3A7C1D2-4F5B-6E8A-9C0D-1B2E3F4A5B6C}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputDir=Output
OutputBaseFilename=CTTFinderSetup
SetupIconFile=
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest
UninstallDisplayIcon={app}\{#MyAppExeName}

[Languages]
Name: "portuguese"; MessagesFile: "compiler:Languages\Portuguese.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Main executable
Source: "{#BuildDir}\ctt_finder.exe"; DestDir: "{app}"; Flags: ignoreversion

; DLLs
Source: "{#BuildDir}\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#BuildDir}\geolocator_windows_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#BuildDir}\url_launcher_windows_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion

; Data folder (app.so, icudtl, flutter_assets)
Source: "{#BuildDir}\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
