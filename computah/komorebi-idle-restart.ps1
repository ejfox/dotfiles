# komorebi-idle-restart.ps1: wait until the PC is idle (no render/film/Unity/Blender/
# game/player lock) for two checks 5 min apart, then run the interactive
# komorebi-restart task once. Gives up after 8 hours. Lives on the PC so it survives
# the Mac rebooting. Progress -> komorebi-idle.txt.
$ErrorActionPreference = 'SilentlyContinue'
$log = 'C:\dev\computah\show\komorebi-idle.txt'
$jobs = 'sb-render','Unity','blender','ffmpeg','FortniteClient-Win64-Shipping','sd-cli'
$idle = 0
for ($i = 0; $i -lt 96; $i++) {
  $busy = (Get-Process -Name $jobs -ErrorAction SilentlyContinue) -or
          (Test-Path 'C:\dev\computah\farm\GAME_ON') -or (Test-Path 'C:\Dev\sbw\PLAYER.lock')
  if ($busy) { $idle = 0 } else { $idle++ }
  "$(Get-Date -Format HH:mm) idle_checks=$idle" | Add-Content -Encoding ascii $log
  if ($idle -ge 2) {
    schtasks /run /tn komorebi-restart | Out-Null
    "$(Get-Date -Format HH:mm) restart task started" | Add-Content -Encoding ascii $log
    exit
  }
  Start-Sleep -Seconds 300
}
"$(Get-Date -Format HH:mm) never idle for 10 min in 8 h; restart not done" | Add-Content -Encoding ascii $log
