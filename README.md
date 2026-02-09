# Scribe

Free, open-source, fully local voice-to-text for macOS.

Speak anywhere on your Mac and have your words appear as text — powered by [WhisperKit](https://github.com/argmaxinc/WhisperKit), running entirely on-device.

## Features

- **System-wide dictation** — press Ctrl+Shift+Space from any app
- **100% local** — no cloud, no API keys, no subscriptions
- **AI text cleanup** — removes filler words, fixes punctuation
- **Dictation history** — searchable SQLite database of everything you've said
- **Re-paste** — Ctrl+Shift+V to re-insert the last dictation
- **Review mode** — optionally review and edit before insertion

## Requirements

- macOS 14 (Sonoma) or later
- Apple Silicon Mac (M1/M2/M3/M4)

## Install

### From Source

```bash
git clone https://github.com/YourUser/Scribe.git
cd Scribe
swift build -c release
chmod +x scripts/build-app.sh
./scripts/build-app.sh
open build/Scribe.app
```

### First Launch

1. Grant **Microphone** access when prompted
2. Grant **Accessibility** access in System Settings > Privacy & Security > Accessibility
3. Wait for the Whisper model to download (~142MB)
4. Press **Ctrl+Shift+Space** to start dictating!

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Ctrl+Shift+Space | Toggle dictation on/off |
| Ctrl+Shift+V | Re-paste last dictation |

## Tech Stack

- Swift + SwiftUI
- [WhisperKit](https://github.com/argmaxinc/WhisperKit) — on-device speech-to-text
- [HotKey](https://github.com/soffes/HotKey) — global keyboard shortcuts
- SQLite3 — dictation history storage
- AVFoundation — microphone capture

## License

MIT
