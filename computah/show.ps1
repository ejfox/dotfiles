# show.ps1: lays out "computah show" windows on the PC's 4K monitor.
# Deployed by `computah show` to C:\dev\computah\show\run.ps1 and run through the
# interactive `show-run` task (SSH alone lands in session 0, which has no desktop).
#
# items\order.txt lists the wrapper pages to show, one per line (<id>.html).
# Each opens as an Edge --app window titled "◆ show · <name>". komorebi is told to
# IGNORE that title, so EJ's tiled windows are never rearranged. This script
# places the show windows itself, in a grid on the work area:
#   1 = left half · 2 = left/right · 3-4 = 2x2 · 5-6 = 3x2 · 7-9 = 3x3
# Windows EJ closed drop out of order.txt. clear.txt = close all and reset.
$ErrorActionPreference = 'SilentlyContinue'
$root  = 'C:\dev\computah\show'
$items = "$root\items"
$udd   = "$root\edge-profile"
$order = "$items\order.txt"
$log   = "$root\last-run.txt"

Add-Type @"
using System; using System.Text; using System.Runtime.InteropServices; using System.Collections.Generic;
public class W {
  public delegate bool EnumProc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc f, IntPtr l);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr a, int x, int y, int cx, int cy, uint f);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [StructLayout(LayoutKind.Sequential)] public struct R { public int L, T, Rt, B; }
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out R r);
  public static Dictionary<string, IntPtr> Titled(string prefix) {
    var d = new Dictionary<string, IntPtr>();
    EnumWindows((h, l) => {
      if (!IsWindowVisible(h)) return true;
      var sb = new StringBuilder(512); GetWindowText(h, sb, 512);
      var t = sb.ToString(); if (t.StartsWith(prefix) && !d.ContainsKey(t)) d[t] = h;
      return true; }, IntPtr.Zero);
    return d;
  }
}
"@
[W]::SetProcessDPIAware() | Out-Null
Add-Type -AssemblyName System.Windows.Forms
$PREFIX = [char]0x25C6 + ' show'
$out = @()

# Every item's Edge process uses this profile, so killing by profile hits only show windows
function Close-All {
  Get-CimInstance Win32_Process -Filter "Name='msedge.exe'" |
    Where-Object { $_.CommandLine -match [regex]::Escape($udd) } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
}

if (Test-Path "$root\clear.txt") {
  Close-All
  Remove-Item -Force "$root\clear.txt", $order
  Get-ChildItem $items -File | Remove-Item -Force
  "cleared" | Set-Content -Encoding ascii $log
  exit
}

komorebic ignore-rule title $PREFIX | Out-Null

$ids = @()
if (Test-Path $order) { $ids = Get-Content -Encoding utf8 $order | Where-Object { $_ -and (Test-Path "$items\$_") } }

# Titles come from each wrapper page's <title>
function Title-Of($id) {
  $html = Get-Content -Raw -Encoding utf8 "$items\$id"
  if ($html -match '<title>(.*?)</title>') { return [System.Net.WebUtility]::HtmlDecode($matches[1]) }
}

# Edge appends " - [InPrivate]" to the page title, so match the page title or that form
function Find-Win($open, $t) {
  foreach ($k in $open.Keys) { if ($k -eq $t -or $k.StartsWith("$t - ")) { return $open[$k] } }
  return $null
}

# Open any item that has no window yet
$open = [W]::Titled($PREFIX)
foreach ($id in $ids) {
  $t = Title-Of $id
  if (-not (Find-Win $open $t)) {
    $url = 'file:///' + ("$items\$id" -replace '\\','/')
    # InPrivate: Edge never signs this profile in, so no "now syncing" popup
    Start-Process msedge -ArgumentList "--user-data-dir=$udd", '--inprivate', '--no-first-run',
      '--no-default-browser-check', '--disable-sync', "--app=$url"
  }
}

# Wait for the windows to exist (Edge cold start can take a few seconds)
$want = @{}; foreach ($id in $ids) { $want[(Title-Of $id)] = $id }
for ($i = 0; $i -lt 30; $i++) {
  $open = [W]::Titled($PREFIX)
  $missing = @($want.Keys | Where-Object { -not (Find-Win $open $_) })
  if ($missing.Count -eq 0) { break }
  Start-Sleep -Milliseconds 500
}

# Lay out the open windows in the order they were shown
$live = @()
foreach ($id in $ids) { $w = Find-Win $open (Title-Of $id); if ($w) { $live += ,@($id, $w) } }
$n = $live.Count
if ($n -gt 0) {
  $wa = ([System.Windows.Forms.Screen]::PrimaryScreen).WorkingArea
  # PowerShell's switch runs EVERY matching clause, hence the breaks
  switch ($n) { {$_ -le 2} {$c=2;$r=1; break} {$_ -le 4} {$c=2;$r=2; break} {$_ -le 6} {$c=3;$r=2; break} default {$c=3;$r=[math]::Ceiling($n/3)} }
  $cw = [int]($wa.Width / $c); $rh = [int]($wa.Height / $r)
  # A fresh Edge --app window re-applies its own size a moment after it appears, which
  # undoes an early placement. So place, wait, read the real rect back, and repeat
  # until every window sits where it should (or ~8 s pass).
  $bad = $n
  for ($pass = 1; $pass -le 12 -and $bad -gt 0; $pass++) {
    for ($k = 0; $k -lt $n; $k++) {
      $h = $live[$k][1]; $x = $wa.X + ($k % $c) * $cw; $y = $wa.Y + [math]::Floor($k / $c) * $rh
      [W]::ShowWindow($h, 9) | Out-Null          # SW_RESTORE, in case it was maximized
      [W]::SetWindowPos($h, [IntPtr]::Zero, $x, $y, $cw, $rh, 0x0014) | Out-Null   # NOZORDER|NOACTIVATE
    }
    Start-Sleep -Milliseconds 700
    $bad = 0
    for ($k = 0; $k -lt $n; $k++) {
      $rect = New-Object W+R; [W]::GetWindowRect($live[$k][1], [ref]$rect) | Out-Null
      $x = $wa.X + ($k % $c) * $cw; $y = $wa.Y + [math]::Floor($k / $c) * $rh
      if ([math]::Abs($rect.L - $x) -gt 12 -or [math]::Abs($rect.T - $y) -gt 12 -or [math]::Abs(($rect.Rt - $rect.L) - $cw) -gt 24) { $bad++ }
    }
  }
  $out += "grid=${c}x${r} misplaced=$bad"
}

# Forget items whose window EJ closed (only once they have had time to open)
($live | ForEach-Object { $_[0] }) | Set-Content -Encoding utf8 $order
$out += "shown=$n"
$out | Set-Content -Encoding ascii $log
