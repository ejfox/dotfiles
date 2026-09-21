param([string]$a="mute",[int]$n=1)
Add-Type @'
using System; using System.Runtime.InteropServices;
public class K { [DllImport("user32.dll")] public static extern void keybd_event(byte k, byte s, uint f, IntPtr e); }
'@
function Tap($vk){ [K]::keybd_event($vk,0,0,[IntPtr]::Zero); Start-Sleep -Milliseconds 15; [K]::keybd_event($vk,0,2,[IntPtr]::Zero) }
switch ($a) {
  "mute" { Tap 0xAD; "muted-toggle" }
  "up"   { for($i=0;$i -lt $n;$i++){ Tap 0xAF }; "vol+$n" }
  "down" { for($i=0;$i -lt $n;$i++){ Tap 0xAE }; "vol-$n" }
}
