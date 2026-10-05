# Static file server for the sd folder + a few action routes (favorites, open folder).
# file:// blocks fetch() and caches <img>; HTTP fixes both.
$root    = 'C:\dev\computah\farm\sd'
$gallery = 'C:\dev\computah\renders\muse-gallery'
$favdir  = 'C:\dev\computah\renders\favorites'
$downdir = 'C:\dev\computah\renders\downvotes'
$studiodir = 'C:\dev\computah\renders\mathblend\masterpieces'

# A new favorite also goes to EJ's Discord channel (2026-10-05). Fire-and-forget: the
# poster runs hidden and logs to logs\fave-post.log; the wall never waits on Discord.
function Post-Fave($png, $kind) {
  if (-not (Test-Path $png)) { return }
  if (-not (Test-Path 'C:\dev\computah\farm\sd\discord-faves.url')) { return }
  Start-Process -WindowStyle Hidden -FilePath 'C:\Users\ejfox\farm\taste\venv\Scripts\python.exe' `
    -ArgumentList @('C:\dev\computah\bin\fave_post.py', "`"$png`"", "`"$([IO.Path]::ChangeExtension($png, '.json'))`"", $kind) -EA 0
}
$prefix = 'http://+:7861/'
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)
try { $listener.Start() } catch { 'listener failed: ' + $_; exit 1 }
'preview-server up on 7861 serving ' + $root

$mime = @{ '.html'='text/html'; '.png'='image/png'; '.js'='application/javascript'; '.css'='text/css'; '.txt'='text/plain'; '.log'='text/plain'; '.json'='application/json' }

function Send-Json($resp, $obj) {
  $json = ($obj | ConvertTo-Json -Compress)
  $b = [Text.Encoding]::UTF8.GetBytes($json)
  $resp.ContentType = 'application/json'
  $resp.Headers.Add('Access-Control-Allow-Origin', '*')
  $resp.Headers.Add('Cache-Control', 'no-store')
  $resp.ContentLength64 = $b.Length
  $resp.OutputStream.Write($b, 0, $b.Length)
  $resp.OutputStream.Close()
}

while ($listener.IsListening) {
  try {
    $ctx = $listener.GetContext()
    $path = $ctx.Request.Url.LocalPath.TrimStart('/')
    $q = $ctx.Request.QueryString
    $resp = $ctx.Response

    # â”€â”€ action routes â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if ($path -eq 'fav') {                       # toggle a favorite (copy/remove)
      $id = $q['id']; $on = $q['on']
      New-Item -ItemType Directory -Force -Path $favdir | Out-Null
      if ($id) {
        if ($on -eq '1') {
          foreach ($ext in @('png','json')) {
            $src = Join-Path $gallery ("muse-$id.$ext")
            if (Test-Path $src) { Copy-Item $src (Join-Path $favdir ("muse-$id.$ext")) -Force -EA 0 }
          }
          Post-Fave (Join-Path $favdir ("muse-$id.png")) 'wall'
        } elseif ($on -eq '0') {
          Get-ChildItem (Join-Path $favdir ("muse-$id.*")) -EA 0 | Remove-Item -Force -EA 0
        }
      }
      $state = [bool]($id -and (Test-Path (Join-Path $favdir ("muse-$id.png"))))
      Send-Json $resp @{ fav = $state }
      continue
    }
    if ($path -eq 'studiofav') {                 # star a Blender studio piece (2026-10-05)
      $name = [IO.Path]::GetFileName([string]$q['name']); $on = $q['on']   # bare file name only
      $sdir = Join-Path $favdir 'studio'
      New-Item -ItemType Directory -Force -Path $sdir | Out-Null
      if ($name) {
        if ($on -eq '1') {
          foreach ($ext in @('png','json')) {
            $src = Join-Path $studiodir ("$name.$ext")
            if (Test-Path $src) { Copy-Item $src (Join-Path $sdir ("$name.$ext")) -Force -EA 0 }
          }
          Post-Fave (Join-Path $sdir ("$name.png")) 'studio'
        } elseif ($on -eq '0') {
          Get-ChildItem (Join-Path $sdir ("$name.*")) -EA 0 | Remove-Item -Force -EA 0
        }
      }
      Send-Json $resp @{ fav = [bool]($name -and (Test-Path (Join-Path $sdir ("$name.png")))) }
      continue
    }
    if ($path -eq 'studiofavlist') {
      $ids = @(Get-ChildItem (Join-Path (Join-Path $favdir 'studio') '*.png') -EA 0 | ForEach-Object { $_.BaseName })
      Send-Json $resp @{ ids = $ids }
      continue
    }
    if ($path -eq 'favlist') {                   # ids currently favorited
      New-Item -ItemType Directory -Force -Path $favdir | Out-Null
      $ids = @(Get-ChildItem (Join-Path $favdir 'muse-*.png') -EA 0 | ForEach-Object { $_.BaseName -replace '^muse-','' })
      Send-Json $resp @{ ids = $ids }
      continue
    }
    # -- taste signals (2026-09-30): thumbs-down, inspect clicks, daily pair pick.
    #    Every event appends one JSON line to taste\events.jsonl; the Mac pulls it
    #    (muse-taste-backfill) and muse-taste-weights learns from SEEN renders only.
    if ($path -eq 'event') {
      $type = $q['type']
      $ok = $type -in @('inspect','down','pair')
      if ($ok) {
        $evdir = Join-Path $root 'taste'
        New-Item -ItemType Directory -Force -Path $evdir | Out-Null
        $ev = [ordered]@{ ts = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss'); type = $type }
        if ($type -eq 'pair') { $ev.win = $q['win']; $ev.lose = $q['lose'] }
        else { $ev.id = $q['id'] }
        if ($type -eq 'down') {
          $ev.on = ($q['on'] -ne '0')
          New-Item -ItemType Directory -Force -Path $downdir | Out-Null
          $id = $q['id']
          if ($id -and $ev.on) {
            foreach ($ext in @('png','json')) {
              $src = Join-Path $gallery ("muse-$id.$ext")
              if (Test-Path $src) { Copy-Item $src (Join-Path $downdir ("muse-$id.$ext")) -Force -EA 0 }
            }
          } elseif ($id) {
            Get-ChildItem (Join-Path $downdir ("muse-$id.*")) -EA 0 | Remove-Item -Force -EA 0
          }
        }
        $line = ($ev | ConvertTo-Json -Compress) + "`n"
        [System.IO.File]::AppendAllText((Join-Path $evdir 'events.jsonl'), $line, (New-Object System.Text.UTF8Encoding $false))
        if ($type -eq 'pair') { Set-Content -Path (Join-Path $evdir 'pair-last.txt') -Value (Get-Date).ToString('yyyy-MM-dd') -Encoding ascii -EA 0 }
      }
      Send-Json $resp @{ ok = $ok }
      continue
    }
    if ($path -eq 'downlist') {                  # ids currently thumbs-downed
      New-Item -ItemType Directory -Force -Path $downdir | Out-Null
      $ids = @(Get-ChildItem (Join-Path $downdir 'muse-*.png') -EA 0 | ForEach-Object { $_.BaseName -replace '^muse-','' })
      Send-Json $resp @{ ids = $ids }
      continue
    }
    if ($path -eq 'pairstate') {                 # is today's pair pick still due?
      $f = Join-Path $root 'taste\pair-last.txt'
      $last = if (Test-Path $f) { (Get-Content $f -EA 0 | Select-Object -First 1) } else { '' }
      Send-Json $resp @{ due = ($last -ne (Get-Date).ToString('yyyy-MM-dd')) }
      continue
    }
    if ($path -eq 'open') {                       # pop a folder in Explorer (via /it task)
      $tn = if ($q['which'] -eq 'favorites') { 'open-favorites' } else { 'open-gallery' }
      Start-Process schtasks -ArgumentList @('/run','/tn',$tn) -WindowStyle Hidden -EA 0
      Send-Json $resp @{ ok = $true }
      continue
    }

    # â”€â”€ static files â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if ($path -eq 'setn') {                       # UI reports its grid size -> generator follows
      $n = 0
      if ([int]::TryParse($q['n'], [ref]$n) -and $n -ge 2 -and $n -le 8) {
        Set-Content -Path (Join-Path $root 'wall-n.txt') -Value ([string]$n) -Encoding ascii -EA 0
      }
      Send-Json $resp @{ n = $n }
      continue
    }
    if ($path -eq 'setmode') {                    # wall source toggle: flux | mix | blender
      $m = [string]$q['m']                          # the Mac muse-loop reads wall-mode.txt
      if (@('flux','mix','blender') -contains $m) {
        Set-Content -Path (Join-Path $root 'wall-mode.txt') -Value $m -Encoding ascii -EA 0
      }
      Send-Json $resp @{ m = $m }
      continue
    }
    if ([string]::IsNullOrEmpty($path)) { $path = 'preview.html' }
    $file = Join-Path $root $path
    $resp.Headers.Add('Cache-Control', 'no-store, no-cache, must-revalidate')
    $resp.Headers.Add('Access-Control-Allow-Origin', '*')
    if (Test-Path $file -PathType Leaf) {
      $ext = [System.IO.Path]::GetExtension($file).ToLower()
      $resp.ContentType = $mime[$ext]; if (-not $resp.ContentType) { $resp.ContentType = 'application/octet-stream' }
      try {
        # FileShare.ReadWrite so we can serve files sd-cli is actively writing.
        $fs = [System.IO.File]::Open($file, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
        $ms = New-Object System.IO.MemoryStream
        $fs.CopyTo($ms); $fs.Close()
        $bytes = $ms.ToArray(); $ms.Close()
        $resp.ContentLength64 = $bytes.Length
        $resp.OutputStream.Write($bytes, 0, $bytes.Length)
      } catch { $resp.StatusCode = 503 }
    } else {
      $resp.StatusCode = 404
    }
    $resp.OutputStream.Close()
  } catch {}
}

