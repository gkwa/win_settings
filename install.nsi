!include FileFunc.nsh
!include LogicLib.nsh
!include MUI2.NSH

Name "${name}"
OutFile "${outfile}"

XPStyle on
ShowInstDetails hide
ShowUninstDetails hide

RequestExecutionLevel admin
Caption "Streambox $(^Name) Installer"

# use this as installdir
InstallDir '$PROGRAMFILES\Streambox\${name}'
#...but if this reg key exists, use this installdir instead of the above line
InstallDirRegKey HKLM 'Software\Streambox\${name}' InstallDir

VIAddVersionKey ProductName "${name}"
VIAddVersionKey FileDescription "Install powershell script for logon sttings"
VIAddVersionKey Language "English"
VIAddVersionKey LegalCopyright "@Streambox"
VIAddVersionKey CompanyName "Streambox"
VIAddVersionKey ProductVersion "${version}"
VIAddVersionKey FileVersion "${version}"
VIProductVersion "${version}"

;--------------------------------
;Interface Configuration

!define MUI_WELCOMEPAGE_TITLE "Welcome to the Streambox setup wizard."
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_RIGHT
!define MUI_HEADERIMAGE_BITMAP '${NSISDIR}\Streambox\Graphics\sblogo.bmp'
!define MUI_WELCOMEFINISHPAGE_BITMAP '${NSISDIR}\Streambox\Graphics\sbside.bmp'
!define MUI_UNWELCOMEFINISHPAGE_BITMAP '${NSISDIR}\Streambox\Graphics\sbside.bmp'
!define MUI_ICON '${NSISDIR}\Streambox\Icons\Streambox_128.ico'

UninstallText "This will uninstall ${name}"

;--------------------------------
;Pages

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_INSTFILES # this macro is the macro that invokes the Sections

!define MUI_WELCOMEPAGE_TITLE "Welcome to Streambox uninstall wizard."
!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_INSTFILES

;--------------------------------
; Languages

!insertmacro MUI_LANGUAGE "English"

;--------------------------------
; Functions

Function .onInit
	SetAutoClose true
FunctionEnd

Function UN.onInit
	SetAutoClose true
	ReadRegStr $INSTDIR HKLM 'Software\Streambox\${name}' InstallDir
FunctionEnd

Section section1 section_section1
	ExpandEnvStrings $0 %ALLUSERSPROFILE%
	SetOutPath "$0\Streambox\win_settings"

	File settings.ps1
	File include.ps1
	File StreamboxLogonSettings.xml

	nsExec::Exec '"$SYSDIR\schtasks.exe" /delete /f /tn StreamboxLogonSettings'
	nsExec::Exec '"$SYSDIR\schtasks.exe" /create /xml StreamboxLogonSettings.xml /tn StreamboxLogonSettings'

	SetOutPath "$INSTDIR"

	;Store uninstall info in add/remove programs
	${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
	IntFmt $0 "0x%08X" $0
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${name}" "EstimatedSize" "$0"
	WriteRegStr HKLM 'Software\Streambox\${name}' InstallDir '$INSTDIR'
	StrCpy $0 '$INSTDIR\Uninstall.exe'
	WriteUninstaller "$0"
	WriteRegStr HKLM 'Software\Microsoft\Windows\CurrentVersion\Uninstall\${name}' UninstallString "$0"
	WriteRegStr HKLM 'Software\Microsoft\Windows\CurrentVersion\Uninstall\${name}' Publisher Streambox
	WriteRegStr HKLM 'Software\Microsoft\Windows\CurrentVersion\Uninstall\${name}' DisplayVersion '${version}'
	WriteRegStr HKLM 'Software\Microsoft\Windows\CurrentVersion\Uninstall\${name}' DisplayName '${name} v${version}'
	WriteRegStr HKLM 'Software\Microsoft\Windows\CurrentVersion\Uninstall\${name}' DisplayIcon "$0"
	WriteRegDWORD HKLM 'Software\Microsoft\Windows\CurrentVersion\Uninstall\${name}' NoModify 1

SectionEnd

Section uninstall section_uninstall
	SetOutPath $TEMP

	nsExec::Exec '"$SYSDIR\schtasks.exe" /delete /f /tn StreamboxLogonSettings'

	ExpandEnvStrings $0 %ALLUSERSPROFILE%
	rmdir /r "$0\Streambox\win_settings"
	rmdir "$0\Streambox"

	rmdir /r '$INSTDIR'
	rmdir /r "$PROGRAMFILES\Streambox\${name}"
	rmdir "$PROGRAMFILES\Streambox"

	DeleteRegKey HKLM 'Software\Streambox\${name}'
	DeleteRegKey /ifempty HKLM 'Software\Streambox'

	# Remove from microsoft Add/remove Programs applet
	# Deleting this key also causes the applet to automatically refresh itself to show the updates
	DeleteRegKey HKLM 'Software\Microsoft\Windows\CurrentVersion\Uninstall\${name}'
SectionEnd

UninstallIcon '${NSISDIR}\Streambox\Icons\Streambox_128.ico'
