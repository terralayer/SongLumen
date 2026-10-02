# SongLumen App Store Design

## Goal

Ship SongLumen as a free Mac App Store menu-bar app that presents a fast,
single now-playing card for Apple Music. `https://terralayer.dev/SongLumen`
is the public support URL.

## Constraints

- The app is sandboxed and uses no shell scripts, launch agents, or external
  helper processes.
- It asks only for permission to control Music through Apple Events.
- It preserves the current fast track-change response, artwork retries, and
  duplicate-card prevention.
- It supports optional login-item launch using Apple Service Management.

## Architecture

`SongLumenApp` owns a menu-bar status item and application lifecycle.
`MusicMonitor` polls the Music app directly with Apple Events and publishes a
new track identity and metadata whenever it changes. `ArtworkLoader` fetches
the current track artwork asynchronously, stores it in the app-container
cache, and ignores results whose track identity is no longer current.
`NowPlayingPanel` is a single reusable AppKit panel that renders the glow card
and updates its artwork in place.

The app invokes `SMAppService.mainApp` for the Start at Login preference. It
does not write outside its container or install a LaunchAgent.

## Track and Artwork Flow

1. `MusicMonitor` checks Music every 0.1 seconds while enabled.
2. A new persistent track ID immediately updates the panel title and artist.
3. `ArtworkLoader` starts independently and retries a missing artwork for up
   to three seconds.
4. A successful result only updates the panel when its persistent ID still
   matches the visible track.
5. New events reuse the same panel rather than spawning an additional card.

## Failure Handling

- If Music is unavailable, SongLumen remains idle and reports that state from
  its menu bar item.
- If automation permission is denied, the menu describes how to grant it in
  System Settings.
- Missing or delayed artwork leaves the card in a clean placeholder state.
- Artwork failures never delay the text card or show artwork from another
  track.

## Release Validation

- Unit coverage for track identity changes, stale artwork rejection, retry
  behavior, and single-panel reuse.
- A manual Music test covering a song change, a track with missing art, and a
  rapid track skip.
- Archive validation for sandboxing, Apple Events entitlement, universal
  build, Developer ID/App Store signing as appropriate, and a fresh install.
- App Store metadata: free price, support URL, privacy details, icon, and
  screenshots are completed in App Store Connect before submission.
