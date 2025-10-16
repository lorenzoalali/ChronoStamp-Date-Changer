//
//  ContentView.swift
//  ChronoStamp Date Changer
//
//  Created by Lorenzo Alali on 16/10/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    /// A structure to hold the results of the file processing operation.
    struct ProcessingResult {
        let successCount: Int
        let failedFiles: [String]
    }

    // These @State variables hold the data for the view and update it when they change
    @State private var isTargeted = false // Tracks if a file is being dragged over the drop zone
    @State private var fileURLs: [URL] = [] // Stores the list of files the user has dropped
    @State private var processingResult: ProcessingResult?
    @State private var isShowingResultAlert = false

    var body: some View {
        // VStack arranges views vertically
        VStack(spacing: 16) {
            Text("ChronoStamp Date Changer")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)

            GroupBox("Supported Formats") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("The date is parsed from the beginning of the filename.")
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• **Full Date:** `YYYY-MM-DD` or `YYYYMMDD`")
                        Text("• **Month:** `YYYY-MM` or `YYYYMM` (uses last day of month)")
                        Text("• **Year Range:** `YYYY-YYYY` or `YYYYYYYY` (uses Dec 31 of second year)")
                    }
                    Text("Separators can be `-` or `_`.")
                        .font(.footnote)
                    Text("Years must be between 1900 and 2999.")
                        .font(.footnote)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // The main drop zone area
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [10]))
                .background(isTargeted ? Color.accentColor.opacity(0.1) : .clear, in: RoundedRectangle(cornerRadius: 12))
                .frame(minHeight: 150)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "folder.badge.plus")
                            .font(.largeTitle)
                        Text("Drop Files Here")
                            .font(.headline)
                    }
                    .foregroundColor(isTargeted ? .accentColor : .secondary)
                )
                // This modifier handles the drop action
                .onDrop(of: [UTType.fileURL], isTargeted: $isTargeted) { providers in
                    handleDrop(providers: providers)
                    return true // Indicates the drop was successful
                }

            // Display a list of the dropped files
            if !fileURLs.isEmpty {
                List {
                    ForEach(fileURLs, id: \.self) { url in
                        Label(url.lastPathComponent, systemImage: "doc")
                    }
                }
                .cornerRadius(8)
                .frame(maxHeight: 200) // Constrain the list height
            }

            // The button that triggers the script
            Button(action: processFiles) {
                Label("Update File Dates", systemImage: "calendar.badge.clock")
                    .font(.headline)
                    .frame(maxWidth: .infinity) // Makes the button wide
            }
            .buttonStyle(.borderedProminent) // Modern macOS button style
            .disabled(fileURLs.isEmpty) // The button is disabled if no files have been dropped
        }
        .padding()
        .alert("Processing Complete", isPresented: $isShowingResultAlert) {
            Button("OK") {}
        } message: {
            Text(alertMessage)
        }
    }

    /// A computed property to generate the message for the results alert.
    private var alertMessage: String {
        guard let result = processingResult else {
            // This case should ideally not be reached if the alert is presented correctly.
            return "Processing finished with an unknown result."
        }
        
        var messageText = "Successfully updated \(result.successCount) files."
        if !result.failedFiles.isEmpty {
            let failedList = result.failedFiles.joined(separator: "\n")
            messageText += "\n\nFailed to update \(result.failedFiles.count) files:\n\(failedList)"
        }
        return messageText
    }

    /// This function is called when files are dropped onto the view.
    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            // Asynchronously load the file URL from the dropped item
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (urlData, error) in
                // Switch to the main thread to update the UI
                DispatchQueue.main.async {
                    guard let urlData = urlData as? Data, let url = URL(dataRepresentation: urlData, relativeTo: nil) else {
                        return
                    }
                    // Add the valid file URL to our list
                    self.fileURLs.append(url)
                }
            }
        }
    }

    /// This function runs the file processing logic for each file in the `fileURLs` list.
    private func processFiles() {
        var successCount = 0
        var failedFiles: [String] = []

        for url in fileURLs {
            let fileName = url.lastPathComponent

            // 1. Try to parse a date from the filename
            guard let newDate = parseDate(from: fileName) else {
                failedFiles.append(fileName)
                continue // Skip to the next file
            }

            // 2. Try to set the new creation and modification dates
            do {
                let attributes: [FileAttributeKey: Any] = [
                    .creationDate: newDate,
                    .modificationDate: newDate
                ]
                // The .path property is needed here for the FileManager API
                try FileManager.default.setAttributes(attributes, ofItemAtPath: url.path)
                successCount += 1
            } catch {
                failedFiles.append(fileName)
            }
        }
        
        // 3. Set the result and show the alert
        self.processingResult = ProcessingResult(successCount: successCount, failedFiles: failedFiles)
        self.isShowingResultAlert = true
        
        // 4. Clear the file list from the UI after processing
        fileURLs.removeAll()
    }

    /// Parses a filename to extract a date based on predefined rules.
    /// - Parameter fileName: The name of the file (e.g., "2023-10-26-document.pdf").
    /// - Returns: A `Date` object if a valid date pattern is found, otherwise `nil`.
    private func parseDate(from fileName: String) -> Date? {
        // This regex captures all supported date formats at the start of the string.
        // Note: This modern Regex syntax requires macOS 13 or later.
        guard let match = fileName.firstMatch(of: /^(\d{4}[-_]\d{4}|\d{4}[-_]\d{2}[-_]\d{2}|\d{8}|\d{4}[-_]\d{2}|\d{6})/) else {
            return nil
        }

        let datePrefix = String(match.1)
        let calendar = Calendar(identifier: .gregorian)
        // We set the time to noon to be consistent.
        var components = DateComponents(hour: 12, minute: 0)
        
        let YEAR_MIN = 1900
        let YEAR_MAX = 2999

        func isValidYear(_ y: Int) -> Bool {
            return (YEAR_MIN...YEAR_MAX).contains(y)
        }
        
        // Case 1: Two-year format (YYYY-YYYY, YYYY_YYYY)
        if let rangeMatch = datePrefix.firstMatch(of: /^(\d{4})[-_](\d{4})$/) {
            guard let y1 = Int(rangeMatch.1), let y2 = Int(rangeMatch.2), isValidYear(y1), isValidYear(y2) else { return nil }
            components.year = y2
            components.month = 12
            components.day = 31
        }
        // Case 2: Full date format (YYYY-MM-DD, YYYY_MM_DD)
        else if let fullDateMatch = datePrefix.firstMatch(of: /^(\d{4})[-_](\d{2})[-_](\d{2})$/) {
            guard let y = Int(fullDateMatch.1), let m = Int(fullDateMatch.2), let d = Int(fullDateMatch.3), isValidYear(y) else { return nil }
            components.year = y
            components.month = m
            components.day = d
        }
        // Case 3: 8 digits (YYYYMMDD or YYYYYYYY)
        else if datePrefix.count == 8, let _ = try? /\d{8}/.wholeMatch(in: datePrefix) {
            guard let y_part1 = Int(datePrefix.prefix(4)) else { return nil }
            
            let m_part = Int(datePrefix.dropFirst(4).prefix(2))!
            let d_part = Int(datePrefix.dropFirst(6).prefix(2))!
            let tempComponents = DateComponents(year: y_part1, month: m_part, day: d_part)
            
            if isValidYear(y_part1), tempComponents.isValidDate(in: calendar) {
                components = tempComponents
            } else {
                guard let y_part2 = Int(datePrefix.suffix(4)), isValidYear(y_part1), isValidYear(y_part2) else { return nil }
                components.year = y_part2
                components.month = 12
                components.day = 31
            }
        }
        // Case 4: Year-month format (YYYY-MM, YYYY_MM)
        else if let yearMonthMatch = datePrefix.firstMatch(of: /^(\d{4})[-_](\d{2})$/) {
            guard let y = Int(yearMonthMatch.1), let m = Int(yearMonthMatch.2), isValidYear(y) else { return nil }
            var tempComponents = DateComponents(year: y, month: m)
            
            if let dateForMonth = calendar.date(from: tempComponents), let range = calendar.range(of: .day, in: .month, for: dateForMonth) {
                tempComponents.day = range.count // Last day of the month
                components = tempComponents
            } else { return nil }
        }
        // Case 5: 6 digits (YYYYMM)
        else if datePrefix.count == 6, let _ = try? /\d{6}/.wholeMatch(in: datePrefix) {
            guard let y = Int(datePrefix.prefix(4)), let m = Int(datePrefix.suffix(2)), isValidYear(y) else { return nil }
            var tempComponents = DateComponents(year: y, month: m)
            
            if let dateForMonth = calendar.date(from: tempComponents), let range = calendar.range(of: .day, in: .month, for: dateForMonth) {
                tempComponents.day = range.count
                components = tempComponents
            } else { return nil }
        } else {
            return nil
        }
        
        components.hour = 12
        components.minute = 0
        
        guard components.isValidDate(in: calendar) else { return nil }
        return calendar.date(from: components)
    }
}
