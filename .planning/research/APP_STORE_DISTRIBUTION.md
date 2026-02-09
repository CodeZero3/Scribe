# Scribe: Mac App Store & Distribution Research

**Date:** 2026-02-09
**Scope:** Practical requirements and challenges for publishing Scribe on the Mac App Store or distributing via notarized DMG

---

## Table of Contents

1. [Apple Developer Program Cost](#1-apple-developer-program-cost)
2. [The Sandbox Problem: CGEvent Tap & Text Insertion](#2-the-sandbox-problem-cgevent-tap--text-insertion)
3. [App Sandbox Entitlements for Scribe](#3-app-sandbox-entitlements-for-scribe)
4. [Distribution Options: App Store vs. Notarized DMG](#4-distribution-options-app-store-vs-notarized-dmg)
5. [ML Model Bundling (WhisperKit)](#5-ml-model-bundling-whisperkit)
6. [API Key Management (Gemini)](#6-api-key-management-gemini)
7. [Build System: SPM to Xcode Project](#7-build-system-spm-to-xcode-project)
8. [App Store Review Timeline & Common Rejections](#8-app-store-review-timeline--common-rejections)
9. [Recommendation & Decision Matrix](#9-recommendation--decision-matrix)

---

## 1. Apple Developer Program Cost

**Confidence: HIGH (official source)**

| Item | Cost |
|------|------|
| Apple Developer Program (individual) | **$99 USD/year** |
| Apple Developer Enterprise Program | $299 USD/year (not needed) |
| Fee waiver eligibility | Nonprofits, accredited educational institutions, government entities |

The $99/year membership is required for **both** distribution paths (App Store and Developer ID/notarized DMG). There is no way to distribute a signed/notarized macOS app without this membership.

**Source:** [Apple Developer Program - What's Included](https://developer.apple.com/programs/whats-included/)

---

## 2. The Sandbox Problem: CGEvent Tap & Text Insertion

**Confidence: HIGH (official Apple Developer Forums, DTS responses)**

This is the **critical blocker** for Mac App Store distribution. Scribe uses two capabilities that interact with the sandbox differently:

### 2a. CGEvent Tap for Push-to-Talk (Monitoring Events) -- COMPATIBLE

Scribe's `HotkeyManager.swift` creates a CGEvent tap with `.listenOnly` option:

```swift
CGEvent.tapCreate(
    tap: .cgSessionEventTap,
    place: .tailAppendEventTap,
    options: .listenOnly,       // <-- Key: listen only, not active
    eventsOfInterest: eventMask,
    ...
)
```

**This IS compatible with App Sandbox and the Mac App Store.** The `listenOnly` CGEvent tap uses the **Input Monitoring** privilege (System Settings > Privacy & Security > Input Monitoring), which is available to sandboxed apps. Apple provides APIs to check and request this:

- `CGPreflightListenEventAccess()` -- check if granted
- `CGRequestListenEventAccess()` -- prompt the user

**Example of a sandboxed App Store app using this:** Magnet (window management app) is sandboxed and on the Mac App Store.

**Source:** [Apple Developer Forums - Accessibility Permission In Sandbox For Keyboard](https://developer.apple.com/forums/thread/789896), [AeroSpace Issue #1012](https://github.com/nikitabobko/AeroSpace/issues/1012)

### 2b. CGEvent.post for Text Insertion (Posting Events) -- NOT COMPATIBLE

Scribe's `TextInserter.swift` uses `CGEvent.post()` to simulate Cmd+V:

```swift
keyDown?.post(tap: .cghidEventTap)  // <-- This is the problem
```

**This is NOT allowed in a sandboxed app.** From Apple DTS (Quinn "The Eskimo"):

> "Posting keyboard or mouse events using functions like CGEventPost is not allowed from a sandboxed app... that would allow an app to easily escape its sandbox."

The `CGEvent.post()` function requires the **Accessibility** privilege (System Settings > Privacy & Security > Accessibility), which is **fundamentally incompatible with App Sandbox**:

- The Accessibility permission prompt **never appears** for sandboxed apps
- The app **cannot be manually added** to the Accessibility list when sandboxed
- `AXIsProcessTrusted()` always returns **false** in a sandboxed app

**Source:** [Apple Developer Forums - Accessibility permission in sandboxed app](https://developer.apple.com/forums/thread/707680), [Apple Developer Forums - Sending paste events to other apps](https://developer.apple.com/forums/thread/61387)

### 2c. Workaround Options for Text Insertion

If you want to pursue the App Store path, you would need to replace the `CGEvent.post()` approach:

| Approach | Feasibility | Trade-off |
|----------|-------------|-----------|
| **Clipboard-only (no auto-paste)** | Easy | User must manually Cmd+V after dictation. Scribe copies to clipboard, shows notification. |
| **NSPasteboard + user-triggered paste** | Easy | Same as above but with a button/hotkey hint. |
| **Services menu integration** | Medium | Register as a macOS Service; user invokes via Services menu or keyboard shortcut. Sandboxed-compatible. |
| **Drop the sandbox entirely** | Easy (code) | Eliminates App Store as an option. Must distribute via notarized DMG. |

**The clipboard-only approach is the simplest App Store-compatible solution** but degrades the user experience from "automatic text insertion" to "copies to clipboard, user pastes manually."

---

## 3. App Sandbox Entitlements for Scribe

**Confidence: HIGH (official documentation)**

If pursuing App Store distribution, Scribe would need these entitlements:

### Required Entitlements

| Entitlement | Key | Purpose |
|-------------|-----|---------|
| App Sandbox | `com.apple.security.app-sandbox` | Required for App Store |
| Microphone (Sandbox) | `com.apple.security.device.audio-input` | AVAudioEngine recording |
| Microphone (Hardened Runtime) | `com.apple.security.device.microphone` | Needed alongside sandbox entitlement |
| Outgoing Network | `com.apple.security.network.client` | Gemini API calls |

### NOT Available in Sandbox

| Capability | Status | Impact on Scribe |
|------------|--------|------------------|
| Accessibility API (`AXIsProcessTrusted`) | Blocked | Cannot use `CGEvent.post()` for text insertion |
| Posting keyboard events (`CGEvent.post`) | Blocked | Must use clipboard-only approach |
| Writing to arbitrary file paths | Blocked | Debug log to `~/Desktop/scribe_debug.log` must be removed |
| Read/write user-selected files | Needs entitlement | `com.apple.security.files.user-selected.read-write` |

### Additional Changes Needed

The `AudioRecorder.swift` writes a debug log to `~/Desktop/scribe_debug.log`. This would need to be removed or changed to use `os.Logger` / `OSLog` instead, as sandboxed apps cannot write to arbitrary file system locations.

**Source:** [Apple Developer Documentation - Configuring the macOS App Sandbox](https://developer.apple.com/documentation/xcode/configuring-the-macos-app-sandbox), [Apple - Enabling App Sandbox Entitlements](https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/EnablingAppSandbox.html)

---

## 4. Distribution Options: App Store vs. Notarized DMG

**Confidence: HIGH (official documentation)**

### Option A: Mac App Store

| Aspect | Details |
|--------|---------|
| **Cost** | $99/year + Apple takes 15-30% of revenue |
| **Sandbox required** | Yes, mandatory |
| **CGEvent.post** | Not possible -- must remove auto-paste |
| **Discovery** | App Store search, categories, editorial |
| **Updates** | Automatic via App Store |
| **Trust** | High -- users trust App Store apps |
| **Code signing** | Automatic via Xcode/App Store Connect |
| **Review** | Required for every update |

### Option B: Notarized DMG (Developer ID)

| Aspect | Details |
|--------|---------|
| **Cost** | $99/year, no revenue share |
| **Sandbox required** | No (but hardened runtime IS required for notarization) |
| **CGEvent.post** | Fully works with Accessibility permission |
| **Discovery** | Your website, Product Hunt, social media, etc. |
| **Updates** | You build your own update mechanism (Sparkle framework is standard) |
| **Trust** | Good -- notarized apps pass Gatekeeper checks |
| **Code signing** | Developer ID Application certificate |
| **Review** | Automated notarization scan only (no human review) |

### Notarization Process for DMG Distribution

1. **Enroll** in Apple Developer Program ($99/year)
2. **Create certificates** in Apple Developer portal (Developer ID Application + Developer ID Installer)
3. **Code sign** the app with Developer ID Application certificate:
   ```bash
   codesign --force --options runtime --sign "Developer ID Application: Your Name (TEAMID)" Scribe.app
   ```
4. **Create DMG** containing the signed app
5. **Notarize** using `xcrun notarytool`:
   ```bash
   xcrun notarytool submit Scribe.dmg --apple-id your@email.com --team-id TEAMID --password app-specific-password --wait
   ```
6. **Staple** the notarization ticket to the DMG:
   ```bash
   xcrun stapler staple Scribe.dmg
   ```

**Important:** As of November 2023, `altool` is deprecated. You must use `xcrun notarytool`.

**Hardened Runtime Entitlements for Notarized Distribution:**

Even without the App Store sandbox, notarized apps require hardened runtime. You would declare:
- `com.apple.security.device.microphone` (for mic access)
- `com.apple.security.automation.apple-events` (if using AppleEvents)

But you do NOT need `com.apple.security.app-sandbox`, which means `CGEvent.post()` works normally with the Accessibility permission.

**Source:** [Apple - Notarizing macOS software before distribution](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution), [Apple - Developer ID](https://developer.apple.com/developer-id/)

---

## 5. ML Model Bundling (WhisperKit)

**Confidence: HIGH (official docs + WhisperKit repo)**

### Model Sizes (Whisper CoreML variants)

| Model | Parameters | Approximate Size |
|-------|-----------|-----------------|
| whisper-tiny | 39M | ~40 MB |
| whisper-base | 244M | ~150 MB |
| whisper-small | 244M | ~290 MB |
| whisper-large-v3 | 1.55B | ~3 GB |

### Mac App Store Size Limits

The Mac App Store allows apps up to **200 GB uncompressed** -- model size is not a concern for any Whisper variant.

**Source:** [Apple - Maximum build file sizes](https://developer.apple.com/help/app-store-connect/reference/maximum-build-file-sizes/)

### Bundling Strategy Options

| Strategy | Pros | Cons |
|----------|------|------|
| **Bundle in app** | Works offline immediately, simplest | Larger download, models ship with every update |
| **Download on first launch** | Smaller initial download | Needs network, user waits on first use |
| **Background Assets framework** | Download before first launch | More complex, Apple framework (macOS 13+) |
| **On-Demand Resources** | Apple-managed lazy download | Primarily designed for iOS/tvOS, limited macOS support |

### Current Scribe Behavior

WhisperKit currently downloads models on first use from HuggingFace. For App Store distribution, you have two good options:

1. **Bundle whisper-tiny or whisper-base in the app** (~40-150 MB). This is well within limits and provides instant functionality. You can bundle models in the app's Resources directory and point WhisperKit to `Bundle.main.resourceURL`.

2. **Keep the download-on-demand approach** but host models yourself (or continue using HuggingFace). This keeps the app binary small but requires network on first use.

**Recommendation:** Bundle the `whisper-tiny` model (~40 MB) for immediate offline use. Optionally allow downloading larger models from settings. This gives the best first-run experience.

**Source:** [WhisperKit GitHub](https://github.com/argmaxinc/WhisperKit), [Apple - Reducing the Size of Your Core ML App](https://developer.apple.com/documentation/coreml/reducing-the-size-of-your-core-ml-app), [Apple - Background Assets](https://developer.apple.com/documentation/BackgroundAssets)

---

## 6. API Key Management (Gemini)

**Confidence: HIGH (security best practices, multiple sources)**

Scribe currently stores the Gemini API key in UserDefaults:

```swift
var apiKey: String {
    get { UserDefaults.standard.string(forKey: "geminiAPIKey") ?? "" }
    set { UserDefaults.standard.set(newValue, forKey: "geminiAPIKey") }
}
```

### The Three Options

#### Option 1: User Brings Their Own Key (BYOK) -- Current Approach

| Aspect | Details |
|--------|---------|
| **How it works** | User enters their own Gemini API key in settings |
| **Security** | User's key, user's responsibility |
| **Cost to you** | Zero API costs |
| **App Store compliance** | Allowed -- many apps do this (e.g., MacGPT, ChatGPT clients) |
| **UX friction** | User must obtain and enter a key |
| **Improvement needed** | Move from UserDefaults to **macOS Keychain** for secure storage |

**Keychain migration code pattern:**
```swift
import Security

func saveAPIKey(_ key: String) {
    let data = key.data(using: .utf8)!
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: "com.scribe.gemini-api-key",
        kSecValueData as String: data
    ]
    SecItemDelete(query as CFDictionary) // Remove old
    SecItemAdd(query as CFDictionary, nil)
}
```

#### Option 2: Developer-Provided Backend Proxy

| Aspect | Details |
|--------|---------|
| **How it works** | Your server holds the API key, app calls your server |
| **Security** | Key never exposed to users |
| **Cost to you** | Server costs + API costs for all users |
| **App Store compliance** | Allowed and preferred by Apple |
| **UX friction** | None -- works out of the box |
| **Complexity** | Need to build, host, and maintain a backend |

This requires a server (e.g., Cloudflare Workers, Supabase Edge Functions, or a simple Hono/Express API) that:
1. Authenticates the Scribe user (via app receipt validation or simple auth)
2. Proxies requests to Gemini API with your key
3. Implements rate limiting to prevent abuse

#### Option 3: Hybrid (Recommended)

| Aspect | Details |
|--------|---------|
| **How it works** | Free tier uses your backend (limited calls/day), power users enter their own key |
| **Security** | Best of both worlds |
| **Cost to you** | Moderate -- free tier costs are capped |
| **UX friction** | Minimal -- works immediately, power users can upgrade |

### Recommendation for App Store

**Start with BYOK (Option 1) but migrate storage from UserDefaults to Keychain.** This is the simplest path that is fully App Store compliant. The BYOK pattern is well-established in the Mac app ecosystem.

If you want to offer a "just works" experience later, add a backend proxy as a premium/subscription feature.

**Source:** [Apple - Keychain Services](https://developer.apple.com/documentation/security/keychain-services), [Apple - Storing Keys in the Keychain](https://developer.apple.com/documentation/security/storing-keys-in-the-keychain), [BFF Pattern - GitGuardian](https://blog.gitguardian.com/stop-leaking-api-keys-the-backend-for-frontend-bff-pattern-explained/)

---

## 7. Build System: SPM to Xcode Project

**Confidence: MEDIUM (community experience + official docs)**

Scribe currently builds via `swift build -c release` using a `Package.swift` with no `.xcodeproj`. For App Store submission, you need:

### Requirements

1. **Xcode project or workspace** -- App Store submission requires archiving through Xcode (Product > Archive), which needs a proper Xcode project.

2. **Info.plist** -- Required for App Store apps. Must include:
   - `CFBundleIdentifier` (e.g., `com.yourname.Scribe`)
   - `CFBundleVersion` and `CFBundleShortVersionString`
   - `NSMicrophoneUsageDescription` (required for mic access)
   - `LSUIElement` = `true` (if menu-bar-only app)

3. **Entitlements file** (.entitlements) -- Declares sandbox and capability entitlements.

4. **Provisioning Profile** -- From Apple Developer portal.

### Migration Path

You can generate an Xcode project from your `Package.swift`:

```bash
# This opens the package as an Xcode workspace
open Package.swift
```

Or create a dedicated `.xcodeproj`:
- In Xcode: File > New > Project > macOS App
- Add the existing Swift files
- Add WhisperKit and HotKey as SPM dependencies within the Xcode project
- Configure signing, entitlements, and Info.plist

**Known issue:** Some developers report that archiving SPM-only projects can fail with "No such module" errors during the archive step. Using a proper Xcode project with SPM dependencies (rather than a standalone Package.swift) avoids this.

**Source:** [Apple - Swift packages in Xcode](https://developer.apple.com/documentation/xcode/swift-packages), [The.Swift.Dev - Building macOS apps with SPM](https://theswiftdev.com/how-to-build-macos-apps-using-only-the-swift-package-manager/)

---

## 8. App Store Review Timeline & Common Rejections

**Confidence: HIGH (Apple official + community consensus)**

### Timeline

| Stage | Duration |
|-------|----------|
| Initial submission review | **24-48 hours** (typical) |
| Re-review after rejection | **24-72 hours** |
| Complex/edge-case apps | Up to **7 days** |
| Expedited review (available on request) | **24 hours** |

### Common Rejection Reasons for Utility Apps

| Reason | Risk for Scribe | Mitigation |
|--------|----------------|------------|
| **4.2 - Minimum Functionality** | LOW -- Scribe has clear utility | Ensure feature set is well-demonstrated |
| **2.4.5 - App Sandbox violations** | HIGH if CGEvent.post is used | Must remove or replace auto-paste |
| **5.1.1 - Data Collection/Privacy** | MEDIUM | Add privacy policy, declare mic usage clearly |
| **2.1 - App Completeness** | LOW | Ensure onboarding covers API key setup |
| **Crashes/Bugs** | LOW | Test on multiple macOS versions |
| **Missing privacy descriptions** | MEDIUM | `NSMicrophoneUsageDescription` must explain why |
| **Guideline 2.5.4 - Multitasking** | LOW | N/A for macOS |

### Scribe-Specific Review Risks

1. **Input Monitoring permission request** -- The reviewer must understand why the app needs this. Include a clear explanation in the App Review Notes field and in the app's onboarding.

2. **Network calls to third-party API** -- Apple may ask about data handling. Prepare a privacy policy that covers what data is sent to Gemini (transcribed text for optimization).

3. **BYOK pattern** -- Apple generally allows this but may ask why the app isn't using Apple's own ML APIs. Be prepared to explain that WhisperKit runs locally and Gemini is for optional text optimization.

**Source:** [Apple - App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/), [Apple - Common App Rejections](https://developer.apple.com/app-store/review/#common-app-rejections), [Adapty - App Store Review Guidelines 2026](https://adapty.io/blog/how-to-pass-app-store-review/)

---

## 9. Recommendation & Decision Matrix

### The Core Decision

| Factor | App Store | Notarized DMG |
|--------|-----------|---------------|
| Auto-paste (CGEvent.post) | NOT POSSIBLE | Works perfectly |
| User discovery | Built-in App Store audience | Must drive own traffic |
| Revenue share | Apple takes 15-30% | 0% |
| Annual cost | $99 | $99 |
| Review process | Human review per update | Automated scan only |
| User trust | Very high | Good (notarized) |
| Update mechanism | Automatic | Must build yourself (Sparkle) |
| Sandbox required | Yes | No |
| Time to ship | Longer (Xcode project, entitlements, review) | Shorter |

### Recommended Path: Notarized DMG First, App Store Later

**Rationale:**

1. **The auto-paste feature is a core differentiator.** Removing it for the App Store significantly degrades the UX. Scribe's value proposition is "speak and the text appears" -- not "speak, then manually paste."

2. **Notarized DMG distribution lets you ship the full experience** while still providing macOS Gatekeeper trust (users see "Apple checked it for malicious software").

3. **You can still pursue App Store later** with a modified version that uses clipboard-only mode, if you want the discovery benefits. Some apps ship both versions (e.g., one on the App Store with reduced features, and a "direct" version with full capabilities).

### Concrete Next Steps

If you decide to distribute via **notarized DMG**:

1. Enroll in Apple Developer Program ($99)
2. Generate Developer ID Application certificate
3. Create an Xcode project (or use `xcodebuild` with your Package.swift)
4. Add proper Info.plist with `NSMicrophoneUsageDescription`
5. Enable hardened runtime, declare entitlements (microphone, accessibility)
6. Code sign with Developer ID certificate
7. Create DMG, notarize with `notarytool`, staple
8. Set up a website/landing page for distribution
9. Consider Sparkle framework for auto-updates
10. Move API key storage from UserDefaults to Keychain

If you decide to pursue the **App Store**:

1. All of the above, plus:
2. Create proper Xcode project with App Sandbox enabled
3. Replace `CGEvent.post()` with clipboard-only approach
4. Remove `~/Desktop/scribe_debug.log` file writing
5. Add privacy policy URL
6. Configure App Store Connect listing
7. Submit for review

### Cost Summary

| Item | One-time | Annual |
|------|----------|--------|
| Apple Developer Program | -- | $99 |
| Domain/website for distribution | ~$12 | ~$12 |
| Notarization | Free (included in program) | -- |
| **Total (notarized DMG path)** | **~$12** | **~$111** |

---

## Sources

### Official Apple Documentation
- [Apple Developer Program - Membership](https://developer.apple.com/programs/whats-included/)
- [Apple Developer Program - Enrollment](https://developer.apple.com/programs/enroll/)
- [App Sandbox Documentation](https://developer.apple.com/documentation/security/app-sandbox)
- [Configuring the macOS App Sandbox](https://developer.apple.com/documentation/xcode/configuring-the-macos-app-sandbox)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Common App Rejections](https://developer.apple.com/app-store/review/#common-app-rejections)
- [Developer ID / Signing](https://developer.apple.com/developer-id/)
- [Notarizing macOS Software](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)
- [Maximum Build File Sizes](https://developer.apple.com/help/app-store-connect/reference/maximum-build-file-sizes/)
- [Keychain Services](https://developer.apple.com/documentation/security/keychain-services)
- [Reducing CoreML App Size](https://developer.apple.com/documentation/coreml/reducing-the-size-of-your-core-ml-app)
- [Background Assets Framework](https://developer.apple.com/documentation/BackgroundAssets)
- [Swift Packages in Xcode](https://developer.apple.com/documentation/xcode/swift-packages)
- [Enabling App Sandbox Entitlements](https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/EnablingAppSandbox.html)

### Apple Developer Forums (DTS Responses)
- [Accessibility Permission in Sandboxed App](https://developer.apple.com/forums/thread/707680)
- [Accessibility Permission in Sandbox for Keyboard](https://developer.apple.com/forums/thread/789896)
- [Sending Paste Events to Other Apps](https://developer.apple.com/forums/thread/61387)
- [CGEventPost Not Allowed in Sandboxed Apps](https://developer.apple.com/forums/thread/724603)

### Third-Party / Community
- [WhisperKit GitHub](https://github.com/argmaxinc/WhisperKit)
- [WhisperKit CoreML Models on HuggingFace](https://huggingface.co/argmaxinc/whisperkit-coreml)
- [Accessibility Permission in macOS (Jano.dev)](https://jano.dev/apple/macos/swift/2025/01/08/Accessibility-Permission.html)
- [Adapty - App Store Review Guidelines 2026](https://adapty.io/blog/how-to-pass-app-store-review/)
- [BFF Pattern for API Key Security](https://blog.gitguardian.com/stop-leaking-api-keys-the-backend-for-frontend-bff-pattern-explained/)
