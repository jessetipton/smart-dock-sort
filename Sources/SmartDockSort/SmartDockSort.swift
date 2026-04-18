import ArgumentParser

@main
struct SmartDockSort: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "smart-dock-sort",
        abstract: "Organize your macOS Dock icons using on-device AI."
    )

    @Option(
        name: .long,
        help: "Custom sorting instruction for the AI model."
    )
    var instruction: String = "Group apps by category (e.g., productivity, creative, communication, utilities, system), then alphabetically within each group."

    @Flag(
        name: [.customShort("d"), .long],
        help: "Print detailed debug info when the model returns a mismatched app list."
    )
    var debug = false

    mutating func run() async throws {
        let apps = try DockReader.readApps()

        if apps.count < 2 {
            print("Only \(apps.count) app(s) in the Dock, nothing to reorder.")
            return
        }

        print("Sorting \(apps.count) apps...")
        let currentNames = apps.map(\.label)
        let result = try await DockSorter.sort(
            apps: apps,
            instruction: instruction,
            debug: debug
        )

        if result.names == currentNames {
            print("\nYour Dock is already sorted this way. Nothing to change.")
            return
        }

        print("\n\(result.summary)\n")
        print("Proposed order:")
        for (i, name) in result.names.enumerated() {
            print("  \(i + 1). \(name)")
        }

        print("\nApply this order? (y/n): ", terminator: "")
        guard let answer = readLine(), answer.lowercased() == "y" else {
            print("Cancelled.")
            return
        }

        let lookup = Dictionary(apps.map { ($0.label, $0) }, uniquingKeysWith: { first, _ in first })
        let reordered = result.names.compactMap { lookup[$0] }

        try DockReader.applyOrder(reordered)
        print("Dock updated!")
    }
}
