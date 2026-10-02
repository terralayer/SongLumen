#!/bin/zsh
set -euo pipefail

poll_seconds="${MUSIC_POLL_SECONDS:-0.1}"
overlay_binary="${MUSIC_OVERLAY_BIN:-${0:A:h}/music-now-playing-overlay}"
artwork_cache_dir="$HOME/Library/Caches/TerraHomeLab/music-artwork"
overlay_pid_file="$HOME/Library/Caches/TerraHomeLab/music-overlay.pid"

current_track() {
  osascript <<'APPLESCRIPT' 2>/dev/null
tell application "Music"
  if player state is playing then
    set currentTrack to current track
    return (persistent ID of currentTrack) & tab & (name of currentTrack) & tab & (artist of currentTrack)
  end if
end tell
APPLESCRIPT
}

extract_artwork() {
  local artwork_path="$1"
  mkdir -p "$artwork_cache_dir"
  osascript - "$artwork_path" <<'APPLESCRIPT' >/dev/null 2>&1
on run argv
  set outputPath to POSIX file (item 1 of argv)
  tell application "Music"
    if player state is playing and (count of artworks of current track) > 0 then
      set artworkData to data of artwork 1 of current track
      set fileRef to open for access outputPath with write permission
      set eof of fileRef to 0
      write artworkData to fileRef
      close access fileRef
    end if
  end tell
end run
APPLESCRIPT
}

extract_artwork_with_retry() {
  local artwork_path="$1"
  local attempt
  for attempt in {1..15}; do
    [[ -s "$artwork_path" ]] && return 0
    extract_artwork "$artwork_path" && [[ -s "$artwork_path" ]] && return 0
    sleep 0.2
  done
}

last_id=""
while true; do
  track="$(current_track || true)"
  if [[ -n "$track" ]]; then
    IFS=$'\t' read -r id title artist <<< "$track"
    if [[ -n "$id" && "$id" != "$last_id" ]]; then
      artwork_path="$artwork_cache_dir/$id.png"
      [[ -s "$artwork_path" ]] || (extract_artwork_with_retry "$artwork_path" || true) >/dev/null 2>&1 &
      if [[ -r "$overlay_pid_file" ]]; then
        previous_overlay_pid="$(<"$overlay_pid_file")"
        if kill -0 "$previous_overlay_pid" 2>/dev/null; then
          kill "$previous_overlay_pid"
        fi
      fi
      "$overlay_binary" "$artwork_path" "$title" "$artist" &
      echo $! > "$overlay_pid_file"
      last_id="$id"
    fi
  fi
  sleep "$poll_seconds"
done
