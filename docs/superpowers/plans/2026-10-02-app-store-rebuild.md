# SongLumen App Store Rebuild Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace SongLumen's shell and LaunchAgent implementation with a sandboxed Mac App Store menu-bar application.

**Architecture:** A Swift/AppKit application owns Music monitoring, artwork loading, the reusable now-playing panel, and login-item registration. Music monitoring publishes immutable track snapshots; the panel renders text immediately and accepts asynchronous artwork only when its track identity still matches.

**Tech Stack:** Swift, AppKit, Foundation, Apple Events, ServiceManagement, XCTest, Xcode archive tooling.

**Spec:** `docs/superpowers/specs/2026-10-02-app-store-design.md`

## Global Constraints

- The app is sandboxed and uses no shell scripts, launch agents, or external helper processes.
- It requests only the entitlement required to control Music through Apple Events.
- Track polling remains 0.1 seconds while enabled.
- Artwork retry duration is at most three seconds and must not delay text display.
- The app uses `SMAppService.mainApp` for optional Start at Login.
- Support URL is `https://terralayer.dev/SongLumen`.

## Review Focus

- Automation permission is denied: menu state explains the recovery path without crashing.
- A rapid second track change occurs before the first artwork arrives: only current artwork can display.
- The Music app quits during polling: monitoring becomes idle and resumes safely.
- A track has no artwork: card uses a placeholder rather than a prior cover image.
- The login-item preference cannot be registered: the toggle reports its actual state.

---

### Task 1: Sandboxed app project and track model

**Files:**
- Create: `SongLumen.xcodeproj/project.pbxproj`
- Create: `SongLumen/App/SongLumenApp.swift`
- Create: `SongLumen/Models/TrackSnapshot.swift`
- Create: `SongLumenTests/TrackSnapshotTests.swift`
- Modify: `Info.plist`
- Create: `SongLumen.entitlements`

**Interfaces:**
- Produces: `struct TrackSnapshot: Equatable { let id: String; let title: String; let artist: String }`.
- Produces: an accessory AppKit app with sandbox and Music Apple Events entitlement.

- [ ] **Step 1: Write failing TrackSnapshot equality tests**

```swift
XCTAssertEqual(TrackSnapshot(id: "a", title: "One", artist: "A"), TrackSnapshot(id: "a", title: "One", artist: "A"))
XCTAssertNotEqual(TrackSnapshot(id: "a", title: "One", artist: "A"), TrackSnapshot(id: "b", title: "One", artist: "A"))
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `xcodebuild test -scheme SongLumen -destination 'platform=macOS'`
Expected: FAIL because the project and model do not exist.

- [ ] **Step 3: Create the App Store project and `TrackSnapshot` model**

Configure `SongLumen.entitlements` for App Sandbox and `com.apple.security.automation.apple-events`; remove the build path's scripts and LaunchAgent resources from the target.

- [ ] **Step 4: Run the test to verify it passes**

Run: `xcodebuild test -scheme SongLumen -destination 'platform=macOS'`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add SongLumen.xcodeproj SongLumen SongLumenTests Info.plist SongLumen.entitlements
git commit -m "feat: create sandboxed SongLumen app"
```

### Task 2: Music monitor and card state

**Files:**
- Create: `SongLumen/Music/MusicMonitor.swift`
- Create: `SongLumen/UI/NowPlayingState.swift`
- Create: `SongLumenTests/NowPlayingStateTests.swift`

**Interfaces:**
- Consumes: `TrackSnapshot` from Task 1.
- Produces: `final class MusicMonitor` that publishes `TrackSnapshot?` changes.
- Produces: `final class NowPlayingState` with `func show(_ snapshot: TrackSnapshot)` and `func applyArtwork(_ data: Data, for id: String)`.

- [ ] **Step 1: Write failing state tests for track replacement and stale artwork rejection**

```swift
state.show(first)
state.show(second)
state.applyArtwork(Data([1]), for: first.id)
XCTAssertNil(state.artwork)
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `xcodebuild test -scheme SongLumen -destination 'platform=macOS'`
Expected: FAIL because `NowPlayingState` does not exist.

- [ ] **Step 3: Implement Music polling and state transitions**

Poll Music every 0.1 seconds through Apple Events. Only emit a snapshot when its persistent ID differs; present the permission-denied and Music-unavailable states to the app delegate.

- [ ] **Step 4: Run tests to verify them pass**

Run: `xcodebuild test -scheme SongLumen -destination 'platform=macOS'`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add SongLumen/Music SongLumen/UI/NowPlayingState.swift SongLumenTests/NowPlayingStateTests.swift
git commit -m "feat: monitor Music tracks in process"
```

### Task 3: Artwork loading and reusable card

**Files:**
- Create: `SongLumen/Music/ArtworkLoader.swift`
- Create: `SongLumen/UI/NowPlayingPanel.swift`
- Create: `SongLumenTests/ArtworkLoaderTests.swift`

**Interfaces:**
- Consumes: `TrackSnapshot` and `NowPlayingState` from Task 2.
- Produces: `final class ArtworkLoader` with `func load(for: TrackSnapshot, completion: @escaping (String, Data?) -> Void)`.
- Produces: `final class NowPlayingPanel` with `func render(_ state: NowPlayingState)`.

- [ ] **Step 1: Write failing artwork tests for retry limit, missing art, and stale result IDs**

```swift
XCTAssertEqual(retryPolicy.maximumAttempts, 15)
XCTAssertEqual(retryPolicy.delay, 0.2)
XCTAssertNil(loader.resultForMissingArtwork)
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `xcodebuild test -scheme SongLumen -destination 'platform=macOS'`
Expected: FAIL because `ArtworkLoader` does not exist.

- [ ] **Step 3: Implement asynchronous artwork retrieval and glow card reuse**

Retry no more than 15 times at 0.2-second intervals. Cache within `Library/Caches` of the app container. Reuse one borderless AppKit panel and update its image only through `NowPlayingState` identity matching.

- [ ] **Step 4: Run tests to verify them pass**

Run: `xcodebuild test -scheme SongLumen -destination 'platform=macOS'`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add SongLumen/Music/ArtworkLoader.swift SongLumen/UI/NowPlayingPanel.swift SongLumenTests/ArtworkLoaderTests.swift
git commit -m "feat: render now-playing card with safe artwork updates"
```

### Task 4: Menu, login item, archive, and release materials

**Files:**
- Modify: `SongLumen/App/SongLumenApp.swift`
- Create: `SongLumen/App/LoginItemController.swift`
- Create: `SongLumenTests/LoginItemControllerTests.swift`
- Modify: `README.md`
- Create: `AppStore/ReleaseChecklist.md`

**Interfaces:**
- Consumes: `MusicMonitor`, `NowPlayingPanel`, and `NowPlayingState` from Tasks 2-3.
- Produces: a status menu with monitoring state, Start at Login, and Quit controls.

- [ ] **Step 1: Write failing tests for login-item status and unavailable Music status copy**

```swift
XCTAssertEqual(controller.menuTitle(for: .notRegistered), "Start at Login")
XCTAssertTrue(statusCopy.contains("Music"))
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `xcodebuild test -scheme SongLumen -destination 'platform=macOS'`
Expected: FAIL because the menu controller does not exist.

- [ ] **Step 3: Implement menu controls and release checklist**

Use `SMAppService.mainApp` for the login preference. The checklist records free pricing, support URL, app privacy answers, icon, screenshots, archive validation, and App Store Connect submission.

- [ ] **Step 4: Run tests and archive validation**

Run: `xcodebuild test -scheme SongLumen -destination 'platform=macOS' && xcodebuild archive -scheme SongLumen -archivePath build/SongLumen.xcarchive`
Expected: tests PASS and archive succeeds with sandbox entitlements.

- [ ] **Step 5: Commit**

```bash
git add SongLumen/App README.md AppStore SongLumenTests/LoginItemControllerTests.swift
git commit -m "feat: add App Store release controls"
```

### Task 5: Manual verification and App Store Connect submission

**Files:**
- Modify: `AppStore/ReleaseChecklist.md`

**Interfaces:**
- Consumes: signed archive from Task 4.
- Produces: a submitted free SongLumen version in App Store Connect.

- [ ] **Step 1: Verify Music behavior manually**

Check one normal track change, rapid skip, missing-art track, Music quit/reopen, denied automation permission, and login-item toggle.

- [ ] **Step 2: Upload the validated archive in Xcode**

Expected: App Store Connect processing begins for the SongLumen build.

- [ ] **Step 3: Complete public release metadata**

Set free pricing, `https://terralayer.dev/SongLumen` support URL, privacy answers, description, icon, and required macOS screenshots.

- [ ] **Step 4: Submit for App Review**

Expected: App Store Connect shows SongLumen as Waiting for Review.

- [ ] **Step 5: Commit the completed local checklist**

```bash
git add AppStore/ReleaseChecklist.md
git commit -m "docs: record App Store submission"
```
