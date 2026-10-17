# komorebi-restart.ps1: restart komorebi on EJ's desktop to load komorebi.json changes.
# Run by the interactive `komorebi-restart` task (from SSH, komorebi would start in
# session 0 with no desktop). Starts it the way it was running (komorebi + whkd, no
# bar). If the new config doesn't come up, restores the newest pre-* backup and
# starts again, so EJ is never left without a tiler. Result -> komorebi-restart.txt.
$ErrorActionPreference = 'SilentlyContinue'
$log = 'C:\dev\computah\show\komorebi-restart.txt'
$cfg = "$env:USERPROFILE\komorebi.json"

function Up { (komorebic state 2>$null | Out-String) -match '"monitors"' }

komorebic stop --whkd | Out-Null
Start-Sleep -Seconds 3
komorebic start --whkd | Out-Null
for ($i = 0; $i -lt 20 -and -not (Up); $i++) { Start-Sleep -Seconds 1 }

if ((komorebic state 2>$null | Out-String) -match '"BOARD"') {
  "ok" | Set-Content -Encoding ascii $log
} else {
  $bak = Get-ChildItem "$cfg.pre-*" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if ($bak) { Copy-Item $bak.FullName $cfg -Force }
  komorebic stop --whkd | Out-Null
  Start-Sleep -Seconds 3
  komorebic start --whkd | Out-Null
  for ($i = 0; $i -lt 20 -and -not (Up); $i++) { Start-Sleep -Seconds 1 }
  "restored-backup up=$(Up)" | Set-Content -Encoding ascii $log
}
