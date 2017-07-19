cls
@echo off
echo ==========================================
echo Windows Server 2016 configuration script.
echo written by Archon Gnosis 
echo ==========================================
echo This script configures the following:
echo  * Disable IE ESC for Administrators
echo  * Enables Remote Desktop Connections
echo  * Sets the TimeZone to Australia Central Standard Time
echo ==========================================
echo Creating Temp Foldermkdir C:\Temp
echo Disabling IE ESC for Administrators
REG ADD "HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" /v IsInstalled /t REG_DWORD /d 00000000 /f
echo Setting RDP
Cscript %windir%\system32\SCRegEdit.wsf /ar 0
echo Setting Region
tzutil /s "Cen. Australia Standard Time"
echo Setting Taskbar to "Combine when full"
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"  /v "TaskbarGlomLevel" /t REG_DWORD /d 00000001 /f
echo Logoff needed for IE ESC disabled
pause Ready to logoff?
logoff
