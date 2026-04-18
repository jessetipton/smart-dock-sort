import Foundation

struct DockApp {
    let label: String
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
            return DockApp(label: label, entry: entry)
        }
        guard !result.isEmpty else { throw DockError.emptyDock }
        return result
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
