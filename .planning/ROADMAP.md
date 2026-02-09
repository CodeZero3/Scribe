# Scribe Roadmap

**Last updated:** 2026-02-09

---

## Two-App Strategy

- **Scribe** (private) — Romeo's personal daily-driver dictation tool. Lives in `CodeZero3/Scribe` (private repo). All development happens here first.
- **AI Scribe** (public) — The public-facing product for the world. Will live in a separate fresh public repo. Forked from Scribe with clean git history, no planning docs or internal artifacts.

---

## Current State

Scribe is a functional macOS dictation app with local transcription (WhisperKit), push-to-talk hotkey (Ctrl+CapsLock), AI text optimization (Gemini), and dictation history with linked optimizations. Distributed as a locally-built .app bundle.

---

## Known Issues

### 1. First-Recording Timing
- **Status:** Mitigated
- **Severity:** Low
- **Description:** If hotkey is pressed before model finishes loading (~5s after launch), recording won't start. Added "Warming up..." status message and friendly "Still warming up" feedback when hotkey is pressed too early. Ready message shows for 5 seconds once model loads.
- **Mitigation:** Startup warmup indicator + zero-sample safety net auto-retry.

### 2. NSException Crash on Tap Installation
- **Status:** Open (rare edge case)
- **Severity:** Medium
- **Description:** `AVAudioEngineImpl::InstallTapOnNode` throws an uncatchable NSException (SIGABRT) when installing a tap with a format that doesn't match the engine's internal state. Occurs specifically on hotkey-triggered recording when Bluetooth format mismatch exists.
- **Potential fix:** Guard tap installation with a format comparison check; if formats disagree, reset engine before installing tap.

### 3. App Icon Cache
- **Status:** Low priority
- **Description:** New .icns installed and codesigned, but macOS icon cache doesn't refresh visually on Desktop. Requires logout/restart or deleting icon cache manually.

---

## Completed (Phase 1 — Stability & Polish)

- [x] Move Gemini API key storage from UserDefaults to macOS Keychain (with auto-migration)
- [x] Replace debug log file writing (`~/Desktop/scribe_debug.log`) with `os.Logger`/`OSLog`
- [x] Add startup warmup indicator ("Warming up..." → "Ready" → clear)
- [x] Friendlier "Still warming up" message when hotkey pressed before model loads

## Remaining (Phase 1)

- [ ] Dark mode verification and polish
- [ ] Guard tap installation with format check to prevent NSException (if reproducible)

---

## Phase 2: Personal Career Optimization

- [ ] New settings panel for user identity and career goals
- [ ] Research user's field and tailor optimization prompts
- [ ] Career-context-aware prompt templates
- [ ] This is Scribe's unique differentiator — no competitor offers this

---

## Phase 3: Public Release — "AI Scribe" (Approach 2 — Fresh Public Repo)

- **Product name:** AI Scribe
- **Distribution:** Free on GitHub + notarized DMG + tip jar
- **Strategy:** Fresh public repo (NOT flipping existing Scribe private repo to public)
- **Prerequisites:** Phase 1 + Phase 2 complete

### Steps:
1. Enroll in Apple Developer Program ($99/year)
2. Generate Developer ID Application certificate
3. Create Xcode project (or xcodebuild workflow) from Package.swift
4. Add proper Info.plist with `NSMicrophoneUsageDescription`
5. Enable hardened runtime, declare entitlements (microphone, accessibility)
6. Code sign with Developer ID certificate
7. Create DMG, notarize with `xcrun notarytool`, staple ticket
8. **Create new public repo** (e.g., `CodeZero3/AIScribe` or new org)
   - Copy only: source code, resources, Package.swift, LICENSE, README
   - Rename/rebrand: Scribe → AI Scribe throughout
   - Exclude: `.planning/`, debug artifacts, `.claude/` files, git history
   - Single clean initial commit
9. Write README with screenshots, install instructions, feature list
10. Add MIT LICENSE
11. Add "Buy me a coffee" / tip jar link (GitHub Sponsors, Ko-fi, or similar)
12. Create GitHub Release with notarized DMG attached
13. Consider Sparkle framework for auto-updates in future releases
14. Post on Product Hunt, Reddit r/macapps, Hacker News for organic discovery

---

## Distribution Decision

**Decided:** Option A — Free on GitHub with tip jar (notarized DMG)

**Rationale:**
- Aligns with goal of keeping products low-cost to help people
- No marketing budget — grassroots/word-of-mouth only
- Full features preserved (no App Store sandbox limitations)
- $99/year Apple Developer fee is the only cost
- App Store version may be considered later as a secondary discovery channel

**Competitive positioning:** Free local dictation with AI text optimization. Sits in the gap between SpeakMac ($19, no AI) and Superwhisper ($249, overwhelming). Career-context optimization is the unique differentiator no competitor has.

**Reference docs:**
- `.planning/research/COMPETITIVE_LANDSCAPE.md`
- `.planning/research/APP_STORE_DISTRIBUTION.md`
