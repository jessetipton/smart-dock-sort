# AGENTS.md

## Project Overview

smart-dock-sort is a macOS CLI tool that uses Apple's on-device Foundation Models framework to intelligently organize the user's Dock icons. It reads the current Dock layout, asks the local LLM to suggest a logical ordering, previews the result, and applies it on user confirmation.

## Build & Run

Requires macOS 26+ (Tahoe), Apple Silicon, Xcode 26+ (for the FoundationModels macro plugin).

```sh
# Build (must use Xcode SDK, not Command Line Tools)
swift build --sdk $(xcrun --sdk macosx --show-sdk-path)

# Run
swift run --sdk $(xcrun --sdk macosx --show-sdk-path) SmartDockSort

# Run with custom instruction
swift run --sdk $(xcrun --sdk macosx --show-sdk-path) SmartDockSort --instruction "put browsers first"
```

The terminal running the tool needs Full Disk Access enabled in System Settings → Privacy & Security.

## Architecture

Single executable target (`SmartDockSort`) with three components:

- **SmartDockSort.swift** — `AsyncParsableCommand` entry point. Orchestrates the flow: read → sort → display → confirm → apply. Accepts an `--instruction` flag for custom sorting criteria.
- **DockReader.swift** — Reads/writes the Dock configuration. Uses `UserDefaults(suiteName: "com.apple.dock")` to access the `persistent-apps` array. Each entry is a dictionary with `tile-data` containing `file-label` (display name) and other metadata. After reordering, writes back and runs `killall Dock` to restart.
- **DockSorter.swift** — On-device AI integration. Uses `LanguageModelSession` from the `FoundationModels` framework with a `@Generable` struct (`SortedApps`) for structured output. Validates the model's response contains exactly the same app names before returning.

## Key Technical Details

- **FoundationModels macros** (`@Generable`, `@Guide`) require the Xcode SDK. Plain `swift build` with Command Line Tools will fail with "plugin not found" errors. Always pass `--sdk $(xcrun --sdk macosx --show-sdk-path)`.
- **Info.plist** is embedded into the binary via linker flags (`-sectcreate __TEXT __info_plist`). This is required for FoundationModels to work in a CLI context.
- The on-device model has a ~4096 token context window. The prompt includes all app names and the sorting instruction, which fits comfortably for typical Dock sizes.
- The model's output is validated: if it returns a different set of names than the input, the tool falls back to the original order with a warning.
- Only `persistent-apps` (app icons on the left side of the Dock) are handled. `persistent-others` (folders/files on the right side) are not touched.
- Finder is not included in `persistent-apps` — it's hardcoded by the Dock process itself.

## Code Style

- Swift 6.2, strict concurrency
- Minimal dependencies: only `swift-argument-parser` (for CLI) and `FoundationModels` (system framework)
- Enums with static methods for stateless utility types (`DockReader`, `DockSorter`)
- Errors are enums conforming to `CustomStringConvertible` for user-friendly messages
