import SwiftUI

/// Represents the available theme options for the application.
enum Theme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    /// A stable identifier for each theme case.
    var id: Self { self }

    /// A user-friendly name for display in the UI.
    var displayName: String {
        switch self {
        case .system:
            "System"
        case .light:
            "Light"
        case .dark:
            "Dark"
        }
    }

    /// The corresponding `ColorScheme` value to apply to a SwiftUI view.
    ///
    /// For the `.system` case, this returns `nil`, which tells SwiftUI
    /// to follow the system's appearance setting.
    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
