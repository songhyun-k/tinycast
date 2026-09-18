import SwiftUI

/// Which language Tinycast renders in; an unset key reads as `.system`.
enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case system
    case english = "en"
    case korean = "ko"

    var id: String { rawValue }

    /// Every language but `.system` names itself, the way macOS lists them.
    var title: LocalizedStringKey {
        switch self {
        case .system: "System"
        case .english: "English"
        case .korean: "한국어"
        }
    }

    /// `.autoupdatingCurrent` hands the choice back to Foundation, which then follows macOS live.
    var locale: Locale {
        switch self {
        case .system: .autoupdatingCurrent
        case .english, .korean: Locale(identifier: rawValue)
        }
    }

    /// AppKit has no environment to read, and `String(localized:locale:)` only formats with its
    /// locale rather than choosing a table, so a string outside SwiftUI resolves through the bundle.
    func localized(_ key: String) -> String {
        switch self {
        case .english: key
        case .system: Bundle.main.localizedString(forKey: key, value: key, table: nil)
        case .korean:
            Bundle.main.path(forResource: rawValue, ofType: "lproj")
                .flatMap(Bundle.init(path:))?
                .localizedString(forKey: key, value: key, table: nil) ?? key
        }
    }
}
