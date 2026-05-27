import Foundation

public extension Error {
    var userFacingMessage: String {
        if let localizedError = self as? any LocalizedError,
           let description = localizedError.errorDescription,
           !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return description
        }

        let localizedDescription = self.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if !localizedDescription.isEmpty,
           localizedDescription != "The operation could not be completed." {
            return localizedDescription
        }

        return String(describing: self)
    }
}
