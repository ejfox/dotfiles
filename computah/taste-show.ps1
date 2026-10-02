# taste-show.ps1 -- open the "what the wall learned" page as an Edge app window
# on the PC's own desktop. Run via schtask taste-show (/IT, through taste-show.vbs
# so no console flashes). Idempotent: closes its own previous window first.
# PERSISTENT profile + 1-byte disk cache (same as wall-show): wiping the profile each
# launch made Edge re-run its account-sync onboarding popup over the page every time.
# Source of truth: ~/.dotfiles/computah/taste-show.ps1 (keep ASCII-only).
$profileDir = 'C:\Users\ejfox\edge-taste-profile'
Get-CimInstance Win32_Process -Filter "Name='msedge.exe'" |
  Where-Object { $_.CommandLine -like '*edge-taste-profile*' } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Start-Sleep -Milliseconds 800
$edge = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
Start-Process $edge -ArgumentList @(
  '--app=http://localhost:7861/taste.html',
  "--user-data-dir=$profileDir", '--disk-cache-size=1',
  '--no-first-run', '--disable-sync', '--disable-features=Translate,msImplicitSignin',
  '--window-size=1600,1000'
)
