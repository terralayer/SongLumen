#!/bin/zsh
set -euo pipefail

script_path="${1:-$PWD/app/Resources/music-track-notifier.sh}"
rg -F 'extract_artwork_with_retry' "$script_path" >/dev/null
rg -F 'sleep 0.2' "$script_path" >/dev/null
echo 'artwork retry window verified'
