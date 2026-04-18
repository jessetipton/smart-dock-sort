# AGENTS.md

## Project Overview

smart-dock-sort is a macOS CLI tool that uses Apple's on-device Foundation Models framework to intelligently organize the user's Dock icons. It reads the current Dock layout, uses the model to categorize each app, sorts deterministically by category and then alphabetically, previews the result, and applies it on user confirmation.

## Build & Run

Requires macOS 26+ (Tahoe), Apple Silicon, Xcode 26+ (for the FoundationModels macro plugin).

```sh
# Build (must use Xcode SDK, not Command Line Tools)
swift build --sdk $(xcrun --sdk macosx --show-sdk-path)

# Run
swift run --sdk $(xcrun --sdk macosx --show-sdk-path) SmartDockSort

# Run with custom instruction
swift run --sdk $(xcrun --sdk macosx --show-sdk-path) SmartDockSort --instruction "put browsers first"

# Run with debug output (shows model's category assignments)
swift run --sdk $(xcrun --sdk macosx --show-sdk-path) SmartDockSort --debug
```

The terminal running the tool needs Full Disk Access enabled in System Settings → Privacy & Security.

## Architecture

Single executable target (`SmartDockSort`) with three components:

- **SmartDockSort.swift** — `AsyncParsableCommand` entry point. Orchestrates the flow: read → categorize → sort → display → confirm → apply. Accepts `--instruction` for custom sorting criteria and `--debug` (`-d`) for diagnostic output.
- **DockReader.swift** — Reads/writes the Dock configuration. Uses `UserDefaults(suiteName: "com.apple.dock")` to access the `persistent-apps` array. Each entry is a dictionary with `tile-data` containing `file-label` (display name) and `file-data` containing the app path. Also reads each app's `LSApplicationCategoryType` from its bundle's `Info.plist` to provide category hints to the model. After reordering, writes back and runs `killall Dock` to restart.
- **DockSorter.swift** — On-device AI integration. Uses `LanguageModelSession` from the `FoundationModels` framework with `@Generable` structs (`CategorizedApp`, `CategorizedApps`) for structured output. The model assigns a category label to each app; sorting is then done deterministically in Swift (grouped by category, alphabetical within groups). If the model returns fewer entries than expected, falls back to name-based matching.

## Key Technical Details

- **FoundationModels macros** (`@Generable`, `@Guide`) require the Xcode SDK. Plain `swift build` with Command Line Tools will fail with "plugin not found" errors. Always pass `--sdk $(xcrun --sdk macosx --show-sdk-path)`.
- **Info.plist** is embedded into the binary via linker flags (`-sectcreate __TEXT __info_plist`). This is required for FoundationModels to work in a CLI context.
- **Bundle metadata**: The tool reads `LSApplicationCategoryType` from each app's `Info.plist` (via the path in `tile-data` → `file-data` → `_CFURLString`) and passes it to the model as a hint. Not all apps have this field.
- **Categorize, don't reorder**: The model only assigns category labels — it never reorders apps directly. This avoids the on-device model's inability to reliably produce valid permutations. All sorting is deterministic Swift code.
- The on-device model has a ~4096 token context window. The prompt includes all app names and categories, which fits comfortably for typical Dock sizes.
- Only `persistent-apps` (app icons on the left side of the Dock) are handled. `persistent-others` (folders/files on the right side) are not touched.
- Finder is not included in `persistent-apps` — it's hardcoded by the Dock process itself.

## Code Style

- Swift 6.2, strict concurrency
- Minimal dependencies: only `swift-argument-parser` (for CLI) and `FoundationModels` (system framework)
- Enums with static methods for stateless utility types (`DockReader`, `DockSorter`)
- Errors are enums conforming to `CustomStringConvertible` for user-friendly messages
