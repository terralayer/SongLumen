#!/bin/zsh
set -euo pipefail

app_path="${1:-$PWD/outputs/SongLumen.app}"
[[ -x "$app_path/Contents/MacOS/MusicNowPlaying" ]]
[[ -x "$app_path/Contents/Resources/music-track-notifier.sh" ]]
[[ -x "$app_path/Contents/Resources/music-now-playing-overlay" ]]
[[ -f "$app_path/Contents/Resources/com.terrahomelab.music-track-notifier.plist.template" ]]
[[ "$(lipo -archs "$app_path/Contents/MacOS/MusicNowPlaying")" == *arm64* && "$(lipo -archs "$app_path/Contents/MacOS/MusicNowPlaying")" == *x86_64* ]]
codesign --verify --deep --strict "$app_path"
echo 'signed universal app package verified'
