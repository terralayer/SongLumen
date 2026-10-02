#!/bin/zsh
set -euo pipefail

root="${0:A:h}"
out="$root/../../../outputs/SongLumen.app"
identity="Developer ID Application: Troy Shank (ZJQGNJ742R)"
rm -rf "$out"
mkdir -p "$out/Contents/MacOS" "$out/Contents/Resources"
build_universal() {
  local source="$1"
  local destination="$2"
  swiftc -target arm64-apple-macosx14.0 "$source" -o "$destination.arm64"
  swiftc -target x86_64-apple-macosx14.0 "$source" -o "$destination.x86_64"
  lipo -create "$destination.arm64" "$destination.x86_64" -output "$destination"
  rm "$destination.arm64" "$destination.x86_64"
}
build_universal "$root/Sources/MusicNowPlayingApp.swift" "$out/Contents/MacOS/MusicNowPlaying"
build_universal "$root/Resources/music-overlay.swift" "$out/Contents/Resources/music-now-playing-overlay"
cp "$root/Info.plist" "$out/Contents/Info.plist"
cp "$root/Resources/music-track-notifier.sh" "$out/Contents/Resources/music-track-notifier.sh"
cp "$root/Resources/com.terrahomelab.music-track-notifier.plist.template" "$out/Contents/Resources/com.terrahomelab.music-track-notifier.plist.template"
chmod +x "$out/Contents/Resources/music-track-notifier.sh"
codesign --force --sign "$identity" "$out/Contents/Resources/music-now-playing-overlay"
codesign --force --sign "$identity" "$out"
