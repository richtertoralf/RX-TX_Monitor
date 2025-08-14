' Start_NIC_Monitor_GUI.vbs
Dim fso, scriptDir, ps1, cmd
Set fso = CreateObject("Scripting.FileSystemObject")
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
ps1 = scriptDir & "\NIC_Realtime_Monitor_GUI.ps1"

' Windows PowerShell 5.1 explizit aufrufen, Fenster verstecken
cmd = "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & ps1 & """"

CreateObject("Wscript.Shell").Run cmd, 0, False
