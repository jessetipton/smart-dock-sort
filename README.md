# smart-dock-sort 

A macOS command-line tool that uses Apple Intelligence to organize your Dock. It reads your current Dock layout, asks the on-device language model to suggest a logical ordering, shows you the result, and applies it if you approve.

Everything runs locally. No API keys. No data leaves your Mac.

## Requirements

- macOS 26+ (Tahoe)
- Apple Silicon
- Apple Intelligence enabled in System Settings
- Full Disk Access for your terminal (System Settings → Privacy & Security → Full Disk Access)

## Install

### Mint

```sh
mint install jessetipton/smart-dock-sort
```

> **Note:** Mint must build with the Xcode SDK for FoundationModels macros to resolve. If the install fails, set the SDK before running:
> ```sh
> export SDKROOT=$(xcrun --sdk macosx --show-sdk-path)
> mint install tiptonj/smart-dock-sort
> ```

## Usage

```sh
# Sort your Dock with the default instruction (group by category, then alphabetically)
smart-dock-sort

# Provide a custom sorting instruction
smart-dock-sort --instruction "put browsers first, then creative apps, then everything else"
```

The tool will:
1. Read your current Dock apps
2. Ask the on-device model to suggest an order
3. Show you a numbered preview
4. Prompt you to apply (`y`) or cancel (`n`)

If you approve, the Dock restarts instantly with the new layout. If you cancel, nothing changes.

## How It Works

Your Dock configuration lives in `~/Library/Preferences/com.apple.dock.plist`. The tool reads the `persistent-apps` array (the app icons on the left side of the Dock), extracts the app names, and sends them to Apple's on-device Foundation Models framework with your sorting instruction.

The model returns a reordered list as structured output. The tool validates that the model returned exactly the same set of apps (no additions or removals), then rewrites the plist and restarts the Dock.

Finder is not affected — it's hardcoded by macOS and doesn't appear in `persistent-apps`. Folders and files on the right side of the Dock (`persistent-others`) are also left untouched.
