//
//  ChronoStamp_Date_ChangerApp.swift
//  ChronoStamp Date Changer
//
//  Created by Lorenzo Alali on 16/10/2025.
//

import SwiftUI

@main
struct ChronoStamp_Date_ChangerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
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
    }
}

/// A view that defines the content of the app's Settings window.
struct SettingsView: View {
    var body: some View {
        // Using a Form provides standard settings styling on macOS.
        Form {
            Section("Updates") {
                Text("You can check for new versions on the project's official repository.")
                if let url = URL(string: "https://github.com/lorenzoalali/ChronoStamp-Date-Changer") {
                    // This link will open the URL in the user's default browser.
                    Link("Check for Updates on GitHub", destination: url)
                }
            }
        }
        .padding()
        .frame(width: 400, height: 100) // Give the settings view a reasonable default size.
    }
}
