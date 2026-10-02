' taste-show.vbs -- run taste-show.ps1 with no visible console (schtask taste-show)
CreateObject("WScript.Shell").Run "powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File C:\dev\computah\farm\sd\taste-show.ps1", 0, False
