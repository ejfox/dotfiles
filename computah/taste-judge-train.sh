#!/bin/bash
# Retrain + revalidate the taste judge on the Mac, then ship it to computah.
#   taste-judge-train.sh v2        → ~/.cache/muse/judge/judge-v2.{npz,json,-report.txt} → PC farm\taste\
# Pulls fresh inputs from the PC (run `taste-embed.py embed` + `embed-studio` there first if
# there are new renders). Steers nothing: callers must check `ready` in the score output.
set -euo pipefail
V="${1:?usage: taste-judge-train.sh vN}"
H=ejfox@10.0.0.169; nc -z -G 2 10.0.0.169 22 >/dev/null 2>&1 || H=computah
D="$HOME/.cache/muse/judge"; mkdir -p "$D"
SRC="$(cd "$(dirname "$0")" && pwd)"
scp -q "$H:C:/Users/ejfox/farm/taste/render-embeds.npz" "$H:C:/Users/ejfox/farm/taste/studio-embeds.npz" \
       "$H:C:/Users/ejfox/farm/taste/render-scores.csv" "$H:C:/dev/computah/farm/sd/taste/events.jsonl" "$D/"
ssh "$H" 'dir /b C:\dev\computah\renders\favorites\*.png' | tr -d '\r' > "$D/favorites.txt"
ssh "$H" 'dir /b C:\dev\computah\renders\favorites\studio\*.png' | tr -d '\r' > "$D/studio-favorites.txt"
/usr/local/bin/python3 "$SRC/taste_judge.py" train --data "$D" --seen auto --out "$D/judge-$V.npz"
scp -q "$D/judge-$V.npz" "$D/judge-$V.json" "$D/judge-$V-report.txt" "$H:C:/Users/ejfox/farm/taste/"
echo "◆ shipped judge-$V → computah farm\\taste\\"
