' studio-show.vbs -- run studio-show.ps1 with no visible console (schtask studio-show)
CreateObject("WScript.Shell").Run "powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File C:\dev\computah\farm\sd\studio-show.ps1", 0, False
