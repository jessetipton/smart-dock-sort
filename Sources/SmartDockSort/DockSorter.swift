import FoundationModels

struct SortResult {
    let names: [String]
    let summary: String
    var failed = false
}

@Generable
struct CategorizedApp {
    @Guide(description: "The app name, exactly as provided in the input.")
    var name: String

    @Guide(description: "A short category label for this app, e.g. 'browser', 'developer-tools', 'productivity', 'creative', 'communication', 'entertainment', 'utilities', 'system'.")
    var category: String
}

@Generable
struct CategorizedApps {
    @Guide(description: "One entry per app from the input, in the same order as the input. Each entry has the app name and an assigned category.")
    var apps: [CategorizedApp]
}

enum DockSorter {
    static func sort(apps: [DockApp], instruction: String, debug: Bool = false) async throws -> SortResult {
        guard case .available = SystemLanguageModel.default.availability else {
            throw SorterError.modelUnavailable
        }

        let appNames = apps.map(\.label)

        let session = LanguageModelSession {
            """
            You categorize macOS apps. Given a list of app names (some with their \
            Mac App Store category), assign each app a short category label. \
            Return one entry per app in the same order as the input. \
            Use the app name exactly as given — do not rename or modify it.
            """
        }

        let appList = apps.map { app in
            if let category = app.category {
                return "- \(app.label) [\(category)]"
            }
            return "- \(app.label)"
        }.joined(separator: "\n")

        let prompt = """
            Categorize each of these \(apps.count) apps. Return exactly \
            \(apps.count) entries, one per app, in the same order.
            
            \(appList)
            """

        let response = try await session.respond(to: prompt, generating: CategorizedApps.self)
        let categorized = response.content.apps

        if debug {
            print("  Model categorized:")
            for app in categorized {
                print("    \(app.name): \(app.category)")
            }
        }

        // Build a lookup from the model's categories, matching by position if
        // the count matches, otherwise falling back to name matching.
        var categoryFor: [String: String] = [:]
        if categorized.count == appNames.count {
            for (i, name) in appNames.enumerated() {
                categoryFor[name] = categorized[i].category.lowercased()
            }
        } else {
            for entry in categorized {
                if appNames.contains(entry.name) {
                    categoryFor[entry.name] = entry.category.lowercased()
                }
            }
        }

        // Sort: group by category, alphabetically within each group.
        // Categories themselves are sorted alphabetically.
        let sorted = appNames.sorted { a, b in
            let catA = categoryFor[a] ?? "zzz"
            let catB = categoryFor[b] ?? "zzz"
            if catA != catB { return catA < catB }
            return a.localizedCaseInsensitiveCompare(b) == .orderedAscending
        }

        // Build a summary of the grouping
        var groups: [(String, [String])] = []
        var seen: Set<String> = []
        for name in sorted {
            let cat = categoryFor[name] ?? "other"
            if !seen.contains(cat) {
                seen.insert(cat)
                groups.append((cat, sorted.filter { (categoryFor[$0] ?? "other") == cat }))
            }
        }
        let summary = groups.map { "\($0.0): \($0.1.joined(separator: ", "))" }.joined(separator: " | ")

        return SortResult(names: sorted, summary: summary)
    }
}

enum SorterError: Error, CustomStringConvertible {
    case modelUnavailable

    var description: String {
        "Apple Intelligence is not available. Ensure you are on macOS 26+ with Apple Intelligence enabled."
    }
}
