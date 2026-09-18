import SwiftUI

/// A stored environment value would freeze at panel-build time; a body re-reads under Observation.
private struct AppLocaleScope: ViewModifier {
    let settings: AppSettings

    func body(content: Content) -> some View {
        content.environment(\.locale, settings.language.locale)
    }
}

extension View {
    /// Every hosted root applies this, so switching language redraws a window instead of needing a relaunch.
    func appLocale(_ settings: AppSettings) -> some View {
        modifier(AppLocaleScope(settings: settings))
    }

    /// A panel rebuilt on every show takes the resolved locale, the way it already takes `metrics`.
    func appLocale(_ locale: Locale) -> some View {
        environment(\.locale, locale)
    }
}
