import Foundation

struct DockApp {
    let label: String
    let category: String?
    let entry: [String: Any]
}

enum DockReader {
    static func readApps() throws -> [DockApp] {
        guard let defaults = UserDefaults(suiteName: "com.apple.dock"),
              let apps = defaults.array(forKey: "persistent-apps") as? [[String: Any]]
        else {
            throw DockError.cannotReadDock
        }
        let result = apps.compactMap { entry -> DockApp? in
            guard let tileData = entry["tile-data"] as? [String: Any],
                  let label = tileData["file-label"] as? String
            else { return nil }
            let category = Self.readCategory(from: tileData)
            return DockApp(label: label, category: category, entry: entry)
        }
        guard !result.isEmpty else { throw DockError.emptyDock }
        return result
    }

    private static func readCategory(from tileData: [String: Any]) -> String? {
        guard let fileData = tileData["file-data"] as? [String: Any],
              let urlString = fileData["_CFURLString"] as? String,
              let url = URL(string: urlString)
        else { return nil }
        let plistURL = url.appendingPathComponent("Contents/Info.plist")
        guard let data = try? Data(contentsOf: plistURL),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let category = plist["LSApplicationCategoryType"] as? String
        else { return nil }
        // "public.app-category.developer-tools" → "developer-tools"
        return category.replacingOccurrences(of: "public.app-category.", with: "")
    }

    static func applyOrder(_ apps: [DockApp]) throws {
        guard let defaults = UserDefaults(suiteName: "com.apple.dock") else {
            throw DockError.cannotReadDock
        }
        defaults.set(apps.map(\.entry), forKey: "persistent-apps")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        process.arguments = ["Dock"]
        try process.run()
        process.waitUntilExit()
    }
}

enum DockError: Error, CustomStringConvertible {
    case cannotReadDock
    case emptyDock

    var description: String {
        switch self {
        case .cannotReadDock: "Could not read Dock preferences."
        case .emptyDock: "No apps found in the Dock."
        }
    }
}
