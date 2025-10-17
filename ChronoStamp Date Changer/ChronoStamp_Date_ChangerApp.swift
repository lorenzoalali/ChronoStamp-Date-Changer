//
//  ChronoStamp_Date_ChangerApp.swift
//  ChronoStamp Date Changer
//
//  Created by Lorenzo Alali on 16/10/2025.
//

import SwiftUI

@main
struct ChronoStamp_Date_ChangerApp: App {
    /// Reads and writes the selected theme from UserDefaults.
    /// Defaults to `.system` if no value is set.
    @AppStorage("theme") private var theme: Theme = .system

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Apply the selected theme's color scheme to the main view.
                .preferredColorScheme(theme.colorScheme)
                // Set a sensible default and minimum size for the main window.
                .frame(minWidth: 500, idealWidth: 550, minHeight: 600, idealHeight: 650)
        }
        // These modifiers create a more modern, seamless window appearance
        // that works well with material backgrounds.
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unifiedCompact)
        .commands {
            // This adds a new menu item to the main app menu (e.g., "ChronoStamp Date Changer").
            CommandGroup(after: .appInfo) {
                if let url = URL(string: "https://github.com/lorenzoalali/ChronoStamp-Date-Changer") {
                    // This creates a menu item that opens the URL in the default web browser.
                    Link("Visit Project on GitHub", destination: url)
                }
            }
        }

        // This adds a "Settings" item to the main app menu and creates a window for it.
        Settings {
            SettingsView()
        }
        // Give the settings window a more appropriate style too.
        .windowResizability(.contentMinSize)
    }
}

/// A view that defines the content of the app's Settings window.
struct SettingsView: View {
    /// Binds the UI control to the theme preference stored in UserDefaults.
    @AppStorage("theme") private var theme: Theme = .system

    var body: some View {
        // Using a Form provides standard settings styling on macOS.
        Form {
            Section {
                // The picker allows the user to change the app's theme.
                Picker("Theme:", selection: $theme) {
                    ForEach(Theme.allCases) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
            } header: {
                Text("Appearance")
            }

            Section("Updates") {
                Text("You can check for new versions on the project's official repository.")
                if let url = URL(string: "https://github.com/lorenzoalali/ChronoStamp-Date-Changer") {
                    // This link will open the URL in the user's default browser.
                    Link("Check for Updates on GitHub", destination: url)
                }
            }
        }
        .padding(20)
        // Give the settings view a fixed width and let its height adapt to the content.
        .frame(width: 350)
        .background(.regularMaterial) // Apply consistent "glass" effect
    }
}
