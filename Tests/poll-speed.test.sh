#!/bin/zsh
set -euo pipefail

script_path="${1:-$PWD/app/Resources/music-track-notifier.sh}"
rg -F 'MUSIC_POLL_SECONDS:-0.1' "$script_path" >/dev/null
echo '0.1-second music polling verified'
