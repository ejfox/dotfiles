# ops-show.ps1 -- open the computah STATUS page (services.json + live state) as an Edge app window.
# 2026-11-24: was the TASTE OPS board (ops.html); its data source (taste-telemetry) and the FLUX wall are
# retired, so the window would show a stale render. Same task, same Edge profile, same placement: only the
# page changed. Revert: --app=http://localhost:7861/ops.html.
# Run via schtask ops-show (/IT, through ops-show.vbs so no console flashes).
# Idempotent: closes its previous window first. PERSISTENT profile + 1-byte disk
# cache (same as wall-show) -- wiping the profile re-triggered Edge's sync onboarding.
# Source of truth: ~/.dotfiles/computah/ops-show.ps1 (keep ASCII-only).
$profileDir = 'C:\Users\ejfox\edge-ops-profile'
Get-CimInstance Win32_Process -Filter "Name='msedge.exe'" |
  Where-Object { $_.CommandLine -like '*edge-ops-profile*' } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Start-Sleep -Milliseconds 800
$edge = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
Start-Process $edge -ArgumentList @(
  '--app=http://localhost:7861/status.html',
  "--user-data-dir=$profileDir", '--disk-cache-size=1',
  '--no-first-run', '--disable-sync', '--disable-features=Translate,msImplicitSignin',
  '--window-size=1600,1000'
)
