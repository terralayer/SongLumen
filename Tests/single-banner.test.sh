#!/bin/zsh
set -euo pipefail

script_path="${1:-$PWD/app/Resources/music-track-notifier.sh}"
rg -F 'music-overlay.pid' "$script_path" >/dev/null
rg -F 'kill "$previous_overlay_pid"' "$script_path" >/dev/null
echo 'single-banner replacement verified'
