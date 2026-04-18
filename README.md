# smart-dock-sort 

A macOS command-line tool that uses Apple Intelligence to organize your Dock. It reads your current Dock layout, uses the on-device language model to categorize your apps, sorts them by category and then alphabetically, and applies the new order if you approve.

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
> mint install jessetipton/smart-dock-sort
> ```

## Usage

```sh
# Sort your Dock with the default instruction (group by category, then alphabetically)
smart-dock-sort

# Provide a custom sorting instruction
smart-dock-sort --instruction "put browsers first, then creative apps, then everything else"

# Show debug output (model's category assignments)
smart-dock-sort --debug
```

The tool will:
1. Read your current Dock apps and their bundle metadata
2. Ask the on-device model to categorize each app
3. Sort apps by category, then alphabetically within each category
4. Show you a numbered preview
5. Prompt you to apply (`y`) or cancel (`n`)

If you approve, the Dock restarts instantly with the new layout. If you cancel, nothing changes.

## How It Works

Your Dock configuration lives in `~/Library/Preferences/com.apple.dock.plist`. The tool reads the `persistent-apps` array (the app icons on the left side of the Dock) and extracts each app's name and `LSApplicationCategoryType` from its bundle's `Info.plist`.

The app names and any existing categories are sent to Apple's on-device Foundation Models framework. The model assigns a category label to each app. Sorting is then done deterministically in Swift — apps are grouped by category and sorted alphabetically within each group. The tool rewrites the plist and restarts the Dock.

Finder is not affected — it's hardcoded by macOS and doesn't appear in `persistent-apps`. Folders and files on the right side of the Dock (`persistent-others`) are also left untouched.

## Limitations

Apple's on-device model (~3B parameters) produces acceptable but often subpar results. You may notice:

- Apps categorized differently across runs
- Unusual or overly broad category labels
- Apps without an `LSApplicationCategoryType` in their bundle may be categorized less accurately

Earlier versions of this tool asked the model to reorder apps directly, but the on-device model struggled to reliably produce a valid permutation of the input list. The current approach — having the model only categorize apps while Swift handles the sorting — is significantly more reliable, though still imperfect.

The `--debug` (`-d`) flag shows exactly how the model categorized each app, which is useful for understanding unexpected results. Running the tool again may produce a different grouping.
