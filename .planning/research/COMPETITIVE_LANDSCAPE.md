# macOS Voice-to-Text / Dictation App Competitive Landscape

**Research Date:** February 9, 2026
**Scope:** Direct competitors, pricing, features, market gaps, App Store considerations
**Confidence Note:** All findings sourced from official sites, major tech publications, and developer documentation. Confidence levels marked per section.

---

## 1. Direct Competitors

### Tier 1: Established Players (Well-funded or High Traction)

#### Wispr Flow
- **Website:** https://wisprflow.ai
- **Pricing:** Free (2,000 words/week) | Pro $15/month or $144/year
- **Platforms:** macOS, Windows, iOS (Android in development)
- **Key Features:**
  - Cloud-based transcription (NOT local) -- 95%+ accuracy
  - AI-powered formatting and filler word removal ("um", "ah")
  - Command Mode (paid): edit/reformat text with voice ("make this professional")
  - IDE integrations for Cursor, VS Code, Windsurf (code dictation)
  - SOC 2 Type II compliant, HIPAA compliant
  - 100+ languages, switch on the fly
- **User Reception:** Strong among developers/power users. TechCrunch featured. Y Combinator connections.
- **Differentiator:** Only dictation tool with native IDE/coding integrations. Enterprise-grade compliance.
- **Weakness:** Cloud-dependent (privacy concern for some). Subscription model.
- **Confidence:** HIGH (official site, TechCrunch, multiple reviews)

#### Superwhisper
- **Website:** https://superwhisper.com
- **Mac App Store:** Yes (https://apps.apple.com/us/app/superwhisper/id6471464415)
- **Pricing:** Free tier (4,000 words/week) | $8.49/month | $84.99/year | $249 lifetime
- **Platforms:** macOS, iOS
- **Key Features:**
  - Fully offline, on-device transcription (Whisper-based + Nvidia Parakeet models)
  - Multiple model tiers: Nano, Fast, Pro, Ultra (speed vs accuracy tradeoff)
  - Push-to-talk and continuous dictation modes
  - AI formatting/cleanup with custom presets
  - Keyboard shortcut activation, menu bar integration
  - v2.0: redesigned UI, mode switching from keyboard, recording history search, BYO API keys
  - 100+ languages
- **User Reception:** Praised for accuracy and privacy. Criticism: overwhelming configuration, unintuitive UX for simple use cases.
- **Differentiator:** Most model choices. Power-user oriented. Strong offline/privacy story.
- **Weakness:** Complex setup. Premium pricing ($249 lifetime is high).
- **Confidence:** HIGH (App Store listing, official site, Product Hunt reviews, TechCrunch)

#### MacWhisper / Whisper Transcription
- **Developer:** Jordi Bruin (Good Snooze)
- **Website:** https://goodsnooze.gumroad.com/l/macwhisper
- **Mac App Store:** Yes, as "Whisper Transcription" (https://apps.apple.com/us/app/whisper-transcription/id1668083311)
- **Pricing:**
  - Direct (Gumroad): Free tier | Pro ~59 EUR one-time
  - App Store: Free tier | Pro $79.99 lifetime (or $4.99/week, $8.99/month, $29.99/year)
- **Platforms:** macOS, iOS
- **Key Features:**
  - On-device transcription using Whisper + Nvidia Parakeet
  - Metal/GPU acceleration (~30x realtime speed)
  - Drag-and-drop file transcription
  - Meeting recording (Zoom, Teams, etc.)
  - Full text and speaker search
  - Pro: batch transcription, AI model support, translation
- **CRITICAL App Store Limitation:** The Mac App Store version ("Whisper Transcription") CANNOT do system-wide dictation due to sandbox restrictions. It is file-transcription only (import -> transcribe -> export). System-wide dictation (typing into any app) is ONLY available in the direct-download version from Gumroad.
- **User Reception:** Well-regarded for transcription quality. Frustration that App Store version is limited.
- **Differentiator:** Established brand, versatile (file transcription + meeting recording + dictation in direct version).
- **Weakness:** App Store version fundamentally limited. File-focused rather than dictation-focused.
- **Confidence:** HIGH (official support docs, App Store listing, Gumroad page)

#### Aqua Voice
- **Website:** https://aquavoice.com
- **Pricing:** Free trial | ~$8-10/month subscription
- **Platforms:** macOS, Windows
- **Key Features:**
  - Proprietary "Avalon" transcription model (not Whisper)
  - Extremely low latency: starts in <50ms, text in ~450ms
  - Screen/app context awareness for formatting
  - Custom dictionary for jargon, names, technical terms
  - Natural language style instructions ("use lowercase in iMessage")
  - Floating text box UI paradigm
  - 49 languages
- **User Reception:** 9to5Mac: "shows just how good Mac dictation could be." Y Combinator backed. Praised for speed.
- **Differentiator:** Fastest latency in category. Context-aware formatting. Proprietary model.
- **Weakness:** Cloud-dependent (subscription, not offline). Fewer languages than competitors.
- **Confidence:** HIGH (9to5Mac, TechCrunch, Product Hunt, official site)

---

### Tier 2: Notable Competitors

#### VoiceInk
- **Website:** https://tryvoiceink.com
- **Mac App Store:** Yes (https://apps.apple.com/us/app/voiceink-ai-dictation/id6751431158)
- **Pricing:** Solo $25 (1 device) | Personal $39 (2 devices) | Extended $49 (3 devices) -- one-time
- **Platforms:** macOS only
- **Key Features:**
  - Local AI models, fully offline, 99% accuracy claimed
  - "Power Mode": auto-applies settings based on active app/URL
  - Screen context awareness
  - Global shortcuts, system-wide
  - AI Assistant mode for conversational AI
  - Open source (GPL v3.0) -- code on GitHub
- **User Reception:** Growing fast. Affordable one-time pricing is appealing.
- **Differentiator:** Open source. Cheapest one-time purchase. App-aware Power Mode.
- **Weakness:** macOS only. Newer entrant, smaller community.
- **Confidence:** HIGH (App Store, GitHub repo, official site)

#### Monologue
- **Website:** https://www.monologue.to
- **Pricing:** Free (1,000 words trial) | $10/month standalone | $100/year | $30/month as part of Every subscription
- **Platforms:** macOS only
- **Key Features:**
  - Smart formatting (adapts to active app context)
  - Personal dictionary (learns proper nouns, acronyms, slang)
  - Flexible modes (email, docs, notes, code -- or custom)
  - 100+ languages
  - Privacy-focused: no audio/transcripts saved on servers
- **User Reception:** Launched September 2025. Early positive reception. Backed by Every (media company).
- **Differentiator:** Part of a media ecosystem. Strong formatting intelligence.
- **Weakness:** Subscription-only. Cloud processing. New/unproven long-term.
- **Confidence:** MEDIUM (official site, TechCrunch mention, Product Hunt)

#### SpeakMac
- **Website:** https://www.speakmac.app
- **Pricing:** $19 one-time purchase
- **Platforms:** macOS only
- **Key Features:**
  - Fully offline, no cloud
  - Simple push-to-talk with Fn key
  - System-wide in any app
  - No subscription, no accounts
- **User Reception:** Praised for simplicity and price point. "The offline dictation macOS should have had."
- **Differentiator:** Cheapest. Simplest. No-frills approach.
- **Weakness:** Limited features. No AI cleanup/formatting. Basic.
- **Confidence:** MEDIUM (official site, Product Hunt)

#### Voibe
- **Website:** https://www.getvoibe.com
- **Pricing:** Monthly, annual, or lifetime options (specific amounts not confirmed; has 3-day trial and 30-day refund)
- **Platforms:** macOS only
- **Key Features:**
  - On-device processing, 97%+ accuracy claimed
  - Push-to-talk with Fn key
  - Developer Mode
  - Real-time speed
- **User Reception:** Newer entrant. Positioning as privacy-first alternative.
- **Differentiator:** Developer mode. Privacy-first marketing.
- **Weakness:** Newer, less established. Limited public reviews.
- **Confidence:** MEDIUM (official site, blog comparisons)

#### Willow Voice
- **Website:** https://willowvoice.com
- **Pricing:** Not fully confirmed from search results
- **Platforms:** macOS
- **Key Features:**
  - Uses LLMs to generate full text from dictation
  - Local transcript storage
  - Opt-out of model training
  - Press Fn to speak in any app
- **User Reception:** Limited data available.
- **Confidence:** LOW (limited sources)

#### Whisper Notes
- **Website:** https://whispernotes.app
- **Pricing:** $4.99 one-time (iOS + Mac)
- **Key Features:** Same Whisper engine as MacWhisper, much cheaper, simpler interface.
- **Confidence:** MEDIUM (official site)

---

### Platform Built-ins

#### Apple Built-in Dictation (macOS Sequoia / Tahoe)
- **Pricing:** Free (built into macOS)
- **Key Features:**
  - On-device processing via Apple Intelligence / Neural Engine
  - macOS Tahoe (2025): New SpeechAnalyzer/SpeechTranscriber APIs -- 55% faster than Whisper
  - Spell mode: say "spell" then letters for difficult words
  - Fn key double-press activation (customizable)
  - Apple Silicon optimized
- **Limitations:**
  - Session timeout: ~30-60 seconds before pausing (NOT confirmed removed in Tahoe)
  - Poor accuracy with technical terms, jargon, names
  - No custom dictionary
  - No AI text cleanup/formatting
  - No speaker detection
  - Limited formatting commands
  - ~90-92% accuracy (vs 95-99% for third-party apps)
- **User Reception:** "Fine for casual use." Professionals universally seek alternatives. Repeated complaints about session limits and accuracy on technical content.
- **Confidence:** HIGH (Apple official docs, multiple reviews, user forums)

#### Google Voice Typing (via Chrome/Google Docs)
- **Pricing:** Free
- **Limitations:** Only works inside Google Docs/Chrome. Cloud-only. Not system-wide. Not a native macOS app.
- **Relevance:** Minimal direct competition for a native macOS dictation app.
- **Confidence:** HIGH (well-known limitation)

---

## 2. Pricing Model Summary

| App | Model | Price Range | Notes |
|-----|-------|-------------|-------|
| **Wispr Flow** | Freemium + Subscription | Free / $15/mo / $144/yr | Cloud. Most expensive subscription. |
| **Superwhisper** | Freemium + Sub/Lifetime | Free / $8.49/mo / $85/yr / $249 lifetime | Expensive lifetime. |
| **MacWhisper** | One-time (+ free tier) | Free / ~$60-80 one-time | Different pricing on Gumroad vs App Store. |
| **Aqua Voice** | Subscription | Free trial / ~$8-10/mo | Cloud-only. No lifetime option. |
| **VoiceInk** | One-time | $25 / $39 / $49 | Per-device tiers. Open source. |
| **Monologue** | Subscription | $10/mo / $100/yr | Or $30/mo as Every bundle. |
| **SpeakMac** | One-time | $19 | Cheapest option. |
| **Voibe** | Tiered (monthly/annual/life) | TBD | 3-day trial. |
| **Whisper Notes** | One-time | $4.99 | Simplest/cheapest. |
| **Apple Dictation** | Free | $0 | Built into macOS. |

**Market pricing sweet spots:**
- Budget: $5-25 one-time purchase (SpeakMac, Whisper Notes, VoiceInk Solo)
- Mid-range: $40-85/year or $60-80 one-time (MacWhisper, Superwhisper annual)
- Premium: $10-15/month subscription (Wispr Flow, Aqua, Monologue)
- Ultra-premium: $249 lifetime (Superwhisper)

---

## 3. Feature Comparison Matrix

| Feature | Scribe (Current) | Wispr Flow | Superwhisper | MacWhisper (Direct) | Aqua Voice | VoiceInk | SpeakMac |
|---------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **Local/Offline Transcription** | YES | No | YES | YES | No | YES | YES |
| **Push-to-Talk Hotkey** | YES (Ctrl+CapsLock) | YES | YES | YES | YES | YES | YES (Fn) |
| **System-wide Dictation** | YES | YES | YES | YES (not App Store) | YES | YES | YES |
| **AI Text Optimization** | YES (Gemini) | YES (built-in) | YES | YES (Pro) | YES | YES | No |
| **Auto-clipboard** | YES | YES (paste) | YES | YES | YES (paste) | YES | Partial |
| **Custom Dictionary** | No | YES | No | No | YES | No | No |
| **Context-aware Formatting** | No | YES (IDE) | Partial | No | YES (screen) | YES (Power Mode) | No |
| **Multiple AI Models** | No (WhisperKit only) | Proprietary | YES (4 tiers) | YES (Whisper + Parakeet) | Proprietary | Local models | Single |
| **File Transcription** | No | No | YES | YES (primary) | No | No | No |
| **Meeting Recording** | No | No | No | YES | No | No | No |
| **History/Search** | YES (SQLite) | No | YES (v2) | YES | No | No | No |
| **Multi-language** | Partial | 100+ | 100+ | 100+ | 49 | 100+ | Unknown |
| **Prompt Modes** | YES (3 modes) | YES (Command) | YES (presets) | Partial | YES (style) | YES (Power Mode) | No |
| **macOS App Store** | No | No | YES | YES (limited) | No | YES | No |

---

## 4. Market Gaps and User Complaints

### What Users Complain About Most (Verified from forums, reviews, Apple Community)

**1. Apple Dictation Session Timeouts** [HIGH confidence]
- The #1 complaint across all forums. Apple dictation stops after 30-60 seconds.
- Every third-party app markets "no timeout" as a key differentiator.
- Source: Apple Community forums, multiple review sites.

**2. Technical Jargon Accuracy** [HIGH confidence]
- "Kubernetes" becomes "communities." Medical/legal terms mangled.
- Custom dictionaries are rare (only Wispr Flow, Aqua Voice offer them).
- This is a gap Scribe could fill.

**3. Complexity vs Simplicity Tradeoff** [HIGH confidence]
- Superwhisper: "too many options, overwhelming for simple use"
- MacWhisper: "great for transcription, overkill for quick dictation"
- Users want something that "just works" for quick voice input without configuration.

**4. Cloud Privacy Concerns** [MEDIUM confidence]
- Wispr Flow, Aqua Voice, Monologue all require cloud. Users in healthcare/legal/enterprise want local-only.
- Local-only apps (Superwhisper, VoiceInk, SpeakMac) market heavily on this.

**5. Subscription Fatigue** [HIGH confidence]
- Users strongly prefer one-time purchase. Recurring complaints about Wispr Flow's $15/month.
- VoiceInk's $25 one-time and SpeakMac's $19 are praised specifically for being non-subscription.

**6. App Store Sandbox Limitations** [HIGH confidence]
- MacWhisper's App Store version loses system-wide dictation entirely.
- Users confused about feature differences between App Store and direct versions.
- This is a MAJOR consideration for Scribe's App Store strategy.

**7. No AI Cleanup in Budget Apps** [MEDIUM confidence]
- SpeakMac ($19) and Whisper Notes ($4.99) do raw transcription only.
- AI text optimization/cleanup is a premium differentiator.
- Gap: affordable app WITH AI cleanup.

**8. Bluetooth Microphone Issues** [MEDIUM confidence]
- Multiple apps struggle with Bluetooth mic sample rates.
- Scribe has ALREADY solved this (CoreAudio hardware format query fix).

### Underserved Niches

1. **Career-context optimization** -- No app tailors dictation output to user's professional field. Scribe's planned "Personal Career Optimization" would be unique.
2. **Affordable local + AI combo** -- Most affordable apps lack AI cleanup. Most AI-cleanup apps are subscriptions. Gap at $20-40 one-time with AI cleanup.
3. **History with linked optimizations** -- Scribe already has this (parent_id linking). No competitor offers visible optimization history.
4. **Simple UX with power features** -- Users want Superwhisper's power without its complexity.

---

## 5. App Store Publication Considerations

### Size Limits
- **macOS App Store limit: 200 GB uncompressed** (far exceeds WhisperKit model needs)
- WhisperKit models range from ~40 MB (tiny) to ~3.1 GB (large-v3)
- Bundling a mid-size model (e.g., base or small: ~150-500 MB) is entirely feasible
- Alternative: Download models on first launch (WhisperKit supports on-demand download from HuggingFace)
- **Confidence:** HIGH (Apple Developer documentation)

### Sandbox Restrictions -- THE CRITICAL ISSUE

**What the sandbox blocks:**
- **Accessibility API access** -- App Sandbox explicitly blocks Accessibility APIs. This means a sandboxed (App Store) app CANNOT:
  - Programmatically type/paste into other apps
  - Read text from other app windows
  - Simulate keystrokes in other apps
  - Control other applications
- **System-wide text insertion** -- No supported way to do Edit > Paste into another app from sandbox
- **This is why MacWhisper's App Store version cannot do system-wide dictation**

**What IS allowed in sandbox:**
- Microphone access (with `com.apple.security.device.audio-input` AND `com.apple.security.device.microphone` entitlements)
- Input Monitoring (available to sandboxed apps, even App Store apps)
- Clipboard read/write (NSPasteboard -- writing to clipboard IS allowed)
- Running ML models locally (CoreML, WhisperKit)

**Implications for Scribe:**
- Scribe currently uses the HotKey library + Accessibility APIs for push-to-talk and text insertion
- An App Store version would need to either:
  1. **Accept limited functionality** (transcribe to clipboard only, user manually pastes) -- like MacWhisper does
  2. **Distribute outside the App Store** to maintain full system-wide functionality
  3. **Use a hybrid approach** -- App Store version with clipboard workflow, direct-download version with full features

**Confidence:** HIGH (Apple Developer Forums, developer documentation, MacWhisper's documented limitations)

### Required Entitlements for App Store

| Entitlement | Purpose | Sandbox Compatible |
|------------|---------|:---:|
| `com.apple.security.device.audio-input` | Microphone access | YES |
| `com.apple.security.device.microphone` | Microphone (both needed) | YES |
| `com.apple.security.app-sandbox` | Required for App Store | YES (mandatory) |
| `com.apple.security.network.client` | Download ML models | YES |
| `com.apple.security.files.user-selected.read-write` | Import audio files | YES |
| Accessibility API | System-wide typing | NO -- blocked by sandbox |

### Common App Store Rejection Reasons (Relevant to Scribe)

1. **Missing purpose string for microphone** -- Must include `NSMicrophoneUsageDescription` in Info.plist with clear explanation
2. **Requesting unnecessary permissions** -- Only request what you actually use
3. **Missing functionality in review** -- If the app "doesn't do enough" without accessibility permissions, reviewers may reject
4. **Large binary without justification** -- If bundling large ML models, the app must clearly demonstrate why
5. **Temporary exception entitlements** -- Requests for sandbox exceptions may be denied; Apple discourages relying on them

**Confidence:** HIGH (Apple Developer documentation, App Store Review Guidelines)

### App Store vs Direct Distribution Decision Matrix

| Factor | App Store | Direct Download |
|--------|-----------|-----------------|
| **System-wide dictation** | NO (sandbox blocks it) | YES |
| **Accessibility API** | NO | YES |
| **Push-to-talk (global hotkey)** | LIMITED (Input Monitoring only) | YES (full HotKey) |
| **Text insertion into other apps** | NO (clipboard only) | YES |
| **Discovery/trust** | HIGH (App Store branding) | LOW (need marketing) |
| **Payment processing** | Apple handles (30% cut) | You handle (Gumroad, etc.) |
| **Auto-updates** | YES (App Store) | You implement (Sparkle, etc.) |
| **Code signing** | Apple handles | Developer ID + notarization |
| **Codesigning/mic issue** | Less likely (App Store signing) | Must codesign manually |

---

## 6. Strategic Observations for Scribe

### What Scribe Already Does Well (vs Competition)
1. **Local transcription via WhisperKit** -- privacy story matches Superwhisper, VoiceInk
2. **AI text optimization with modes** -- matches premium features of Wispr Flow, Superwhisper Pro
3. **Push-to-talk with global hotkey** -- standard table-stakes feature
4. **History with linked optimizations** -- UNIQUE. No competitor shows optimization lineage
5. **Bluetooth mic fix** -- solved a problem many competitors still have
6. **Gemini-powered optimization** -- more advanced than simple cleanup (career modes are planned)

### What Scribe Would Need for Competitive Parity
1. **Multiple language support** -- competitors offer 49-100+ languages
2. **Multiple model options** -- let users pick accuracy vs speed tradeoff
3. **Custom dictionary** -- only Wispr Flow and Aqua offer this; high-value gap
4. **App-context awareness** -- VoiceInk's Power Mode, Aqua's screen context
5. **Polished onboarding** -- Superwhisper criticized for complexity; Scribe should be simple

### Unique Differentiators Scribe Could Own
1. **Career-context AI optimization** -- No competitor does this. "Personal Career Optimization" is novel.
2. **Affordable local + AI combo** -- One-time $20-30 with AI cleanup fills a real gap
3. **Linked optimization history** -- Visual lineage of original -> optimized text is unique
4. **Simple UX** -- The "it just works" space is underserved between SpeakMac (too simple) and Superwhisper (too complex)

### Recommended Distribution Strategy

**Option A (Recommended): Dual Distribution**
- **Direct download** (primary): Full features including system-wide dictation, accessibility integration
- **App Store** (secondary): Transcription-focused version (clipboard output, file transcription) for discovery and trust
- This is exactly what MacWhisper does (MacWhisper direct = full features, Whisper Transcription on App Store = limited)

**Option B: Direct Download Only**
- Maintain full feature set
- Use notarization for trust
- Sell via Gumroad or similar ($0 platform fee on free plan, 10% on paid)
- Must handle updates yourself (Sparkle framework)
- Miss out on App Store discovery

**Option C: App Store Only**
- NOT recommended. Would lose system-wide dictation (Scribe's core value proposition)
- Would become a file-transcription tool competing with established MacWhisper

### Suggested Price Point
Based on competitive analysis, for a one-time purchase with local AI:
- **$25-35 one-time** positions Scribe between SpeakMac ($19, no AI) and MacWhisper Pro ($60-80)
- This is the "sweet spot" gap in the market: affordable + AI cleanup + local privacy
- Could also offer a free tier (limited words/day) to drive adoption

---

## 7. Sources

### Official / Publisher Sites
- [Wispr Flow Official](https://wisprflow.ai)
- [Superwhisper Official](https://superwhisper.com)
- [MacWhisper on Gumroad](https://goodsnooze.gumroad.com/l/macwhisper)
- [Whisper Transcription on App Store](https://apps.apple.com/us/app/whisper-transcription/id1668083311)
- [VoiceInk Official](https://tryvoiceink.com)
- [Aqua Voice Official](https://aquavoice.com)
- [Monologue Official](https://www.monologue.to)
- [SpeakMac Official](https://www.speakmac.app)
- [Voibe Official](https://www.getvoibe.com)
- [WhisperKit GitHub](https://github.com/argmaxinc/WhisperKit)
- [WhisperKit CoreML Models on HuggingFace](https://huggingface.co/argmaxinc/whisperkit-coreml)

### Apple Developer Documentation
- [Apple App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Maximum Build File Sizes](https://developer.apple.com/help/app-store-connect/reference/app-uploads/maximum-build-file-sizes/)
- [Configuring macOS App Sandbox](https://developer.apple.com/documentation/xcode/configuring-the-macos-app-sandbox)
- [Requesting Authorization for Media Capture](https://developer.apple.com/documentation/avfoundation/requesting-authorization-to-capture-and-save-media)
- [Protected Resources](https://developer.apple.com/documentation/bundleresources/protected-resources)

### Reviews and Comparisons
- [TechCrunch: Best AI Dictation Apps of 2025](https://techcrunch.com/2025/12/30/the-best-ai-powered-dictation-apps-of-2025/)
- [9to5Mac: Aqua Voice Review](https://9to5mac.com/2025/08/15/aqua-voice-shows-just-how-good-mac-dictation-could-be-if-apple-just-tried/)
- [Wispr Flow: Top 10 Dictation Tools December 2025](https://wisprflow.ai/post/top-10-dictation-tools-december-2025)
- [MacWhisper vs Whisper Transcription Differences](https://macwhisper.helpscoutdocs.com/article/40-macwhisper-whisper-transcription-difference)
- [Voice Dictation on macOS Tahoe: Native vs Third-Party](https://weesperneonflow.ai/en/blog/2025-10-27-voice-dictation-macos-tahoe-native-features-third-party-apps-2025/)
- [Superwhisper App Store Listing](https://apps.apple.com/us/app/superwhisper/id6471464415)
- [VoiceInk App Store Listing](https://apps.apple.com/us/app/voiceink-ai-dictation/id6751431158)
- [Superwhisper Reviews on Product Hunt](https://www.producthunt.com/products/superwhisper/reviews)
- [Choosing the Right AI Dictation App for Mac](https://afadingthought.substack.com/p/best-ai-dictation-tools-for-mac)

### Developer Forums and Technical
- [Sandbox Permissions for Clipboard (Apple Forums)](https://developer.apple.com/forums/thread/772649)
- [Accessibility Permission in Sandbox (Apple Forums)](https://developer.apple.com/forums/thread/810677)
- [Why Useful Mac Apps Aren't on App Store](https://alinpanaitiu.com/blog/apps-outside-app-store/)
- [Accessibility Permission in macOS](https://jano.dev/apple/macos/swift/2025/01/08/Accessibility-Permission.html)
- [CoreML Model Size Issues (Apple Forums)](https://developer.apple.com/forums/thread/751805)

### Market Data
- [Speech and Voice Recognition Market (MarketsAndMarkets)](https://www.marketsandmarkets.com/Market-Reports/speech-voice-recognition-market-202401714.html)
- [Digital Dictation Systems Market](https://www.verifiedmarketreports.com/product/digital-dictation-systems-market/)
