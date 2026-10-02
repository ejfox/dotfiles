' ops-show.vbs -- run ops-show.ps1 with no visible console (schtask ops-show)
CreateObject("WScript.Shell").Run "powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File C:\dev\computah\farm\sd\ops-show.ps1", 0, False
