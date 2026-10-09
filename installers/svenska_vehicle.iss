#define MyAppName "Vehicle QR"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Svenska Solution"
#define MyAppExeName "svenska.exe" 

[Setup]
AppId={{A7B1C9D3-4E8F-4B2E-9D2A-E1F5C6D2A4B3}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputDir=C:\Users\admin\AndroidStudioProjects\svenska\installers
OutputBaseFilename=vehicle_QR_setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64
PrivilegesRequired=admin

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; 1. Flutter Release Build Files (App exe, data folder, flutter plugins dlls)
Source: "C:\Users\admin\AndroidStudioProjects\svenska\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

; 2. VC++ Runtime DLLs (From extra_dlls folder - resolves VCRUNTIME140_1.dll missing issue)
Source: "extra_dlls\vcruntime140.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "extra_dlls\vcruntime140_1.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "extra_dlls\msvcp140.dll"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent