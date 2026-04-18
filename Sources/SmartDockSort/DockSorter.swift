import FoundationModels

struct SortResult {
    let names: [String]
    let summary: String
}

@Generable
struct SortedApps {
    @Guide(description: "The app names reordered according to the sorting instruction. Must contain exactly the same names as the input, no additions or removals.")
    var names: [String]

    @Guide(description: "A brief, friendly summary explaining the reasoning behind the proposed order.")
    var summary: String
}

enum DockSorter {
    static func sort(appNames: [String], instruction: String) async throws -> SortResult {
        guard case .available = SystemLanguageModel.default.availability else {
            throw SorterError.modelUnavailable
        }

        let session = LanguageModelSession {
            """
            You reorder a list of macOS app names. Return exactly the same names, \
            no additions or removals. Only change the order. Include a brief summary \
            explaining your reasoning. If the current order is already optimal, \
            return it unchanged and write a cheeky, complimentary summary praising \
            the user's impeccable taste in Dock organization.
            """
        }

        let prompt = """
            Apps: \(appNames.joined(separator: ", "))
            
            Sorting instruction: \(instruction)
            """

        let response = try await session.respond(to: prompt, generating: SortedApps.self)
        let sorted = response.content

        // Validate: must contain exactly the same set of names
        let inputSet = Set(appNames)
        let outputSet = Set(sorted.names)
        guard inputSet == outputSet, sorted.names.count == appNames.count else {
            print("Warning: model returned mismatched app list, using original order.")
            return SortResult(names: appNames, summary: "Could not generate a new ordering.")
        }

        return SortResult(names: sorted.names, summary: sorted.summary)
    }
}

enum SorterError: Error, CustomStringConvertible {
    case modelUnavailable

    var description: String {
        "Apple Intelligence is not available. Ensure you are on macOS 26+ with Apple Intelligence enabled."
    }
}
