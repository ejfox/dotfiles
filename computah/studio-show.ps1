# studio-show.ps1 -- open the Blender studio's still viewer (studio.html) as an Edge app
# window on the PC's own desktop. Run via schtask studio-show (/IT, through
# studio-show.vbs so no console flashes). Idempotent: closes its own previous window.
# Replaces the GUI Blender studio window, whose progressive repaint leaked dwm VRAM.
# Source of truth: ~/.dotfiles/computah/studio-show.ps1 (keep ASCII-only).
$profileDir = 'C:\Users\ejfox\edge-studio-profile'
Get-CimInstance Win32_Process -Filter "Name='msedge.exe'" |
  Where-Object { $_.CommandLine -like '*edge-studio-profile*' } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Start-Sleep -Milliseconds 800
$edge = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
Start-Process $edge -ArgumentList @(
  '--app=http://localhost:7861/studio.html',
  "--user-data-dir=$profileDir", '--disk-cache-size=1',
  '--no-first-run', '--disable-sync', '--disable-features=Translate,msImplicitSignin',
  '--window-size=1600,1000'
)
