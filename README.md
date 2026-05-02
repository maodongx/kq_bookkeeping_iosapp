# KQ Bookkeeping

A personal iOS bookkeeping app built with SwiftUI and SwiftData.

## Requirements

- macOS with Xcode 15 or later
- iOS 17+ target (SwiftData)
- Apple ID (for signing; personal team works for local/device builds)

## Getting started

```bash
git clone https://github.com/maodongx/kq_bookkeeping_iosapp.git
cd kq_bookkeeping_iosapp
open KQBookkeeping.xcodeproj
```

In Xcode:

1. Select the `KQBookkeeping` target → **Signing & Capabilities**
2. Pick your **Team** (your personal Apple ID is fine)
3. Choose a simulator (e.g. iPhone 16 Pro) and press ⌘R

## Project layout

```
KQBookkeeping/
├── KQBookkeeping/              # App source
│   ├── KQBookkeepingApp.swift  # @main entry
│   ├── ContentView.swift       # Root view
│   └── Item.swift              # SwiftData model (placeholder)
├── KQBookkeepingTests/         # Unit tests (Swift Testing)
├── KQBookkeepingUITests/       # UI tests (XCTest)
└── KQBookkeeping.xcodeproj
```

## License

[MIT](./LICENSE)
