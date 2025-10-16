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
        ScrollView {
            VStack(spacing: 24) {
                headerView
                
                dropZoneView
                    .onDrop(of: [UTType.fileURL], isTargeted: $isTargeted) { providers in
                        handleDrop(providers: providers)
                        return true // Indicates the drop was successful
                    }
                    .onTapGesture(perform: openFilePicker)
                
                if !fileURLs.isEmpty {
                    fileListView
                    
                    Button(action: processFiles) {
                        Label("Update File Dates", systemImage: "wand.and.stars")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                    .keyboardShortcut(.defaultAction)
                }
                
                instructionsView
            }
            .padding(.horizontal, 32)
            .padding(.vertical)
        }
        .alert("Processing Complete", isPresented: $isShowingResultAlert) {
            Button("OK") {}
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Subviews

    private var headerView: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.accentColor)
            
            Text("ChronoStamp Date Changer")
                .font(.largeTitle.weight(.bold))
            
            Text("Updates 'Date Created' to match the filename. 'Date Modified' is only updated if the filename date is more recent.")
                .font(.headline)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
    }
    
    private var dropZoneView: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.and.arrow.down.on.square.fill")
                .font(.system(size: 40, weight: .light))
            Text("Drop Files Here")
                .font(.title2.weight(.medium))
            Text("or click to select files")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            if isTargeted {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.accentColor.opacity(0.2))
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [10]))
                .foregroundStyle(isTargeted ? Color.accentColor : .secondary.opacity(0.5))
        )
        .scaleEffect(isTargeted ? 1.03 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isTargeted)
    }

    private var fileListView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Files to Process (\(fileURLs.count))")
                .font(.headline)
                .padding(.horizontal, 8)
            
            List {
                ForEach(fileURLs, id: \.self) { url in
                    Label(url.lastPathComponent, systemImage: "doc")
                }
                .onDelete { indexSet in
                    fileURLs.remove(atOffsets: indexSet)
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private var instructionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle")
                Text("Supported Filename Formats")
                    .font(.headline)
            }
            .foregroundColor(.secondary)
            
            Text("The date is parsed from the beginning of the filename.")
                .font(.callout)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("• **Full Date:** `YYYY-MM-DD` or `YYYYMMDD`")
                Text("• **Month:** `YYYY-MM` or `YYYYMM` (uses last day of month)")
                Text("• **Year Range:** `YYYY-YYYY` or `YYYYYYYY` (uses Dec 31 of second year)")
            }
            .font(.callout)
            .padding(.leading, 20)
            
            Text("Separators can be `-` or `_`, or even nothing. Years must be between 1900 and 2200.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Logic
    
    /// A computed property to generate the message for the results alert.
    private var alertMessage: String {
        guard let result = processingResult else {
            return "Processing finished with an unknown result."
        }
        
        var messages: [String] = []
        
        if result.successCount > 0 {
            messages.append("✅ Successfully updated \(result.successCount) files.")
        }
        
        if !result.failedFiles.isEmpty {
            let failedList = result.failedFiles.joined(separator: "\n")
            messages.append("❌ Failed to update \(result.failedFiles.count) files:\n\(failedList)")
        }
        
        // This case should not be reachable if there are files to process,
        // but it's a good fallback.
        if messages.isEmpty {
            return "No changes were made."
        }
        
        return messages.joined(separator: "\n\n")
    }

    /// Presents a file picker to the user for selecting files.
    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        if panel.runModal() == .OK {
            self.fileURLs.append(contentsOf: panel.urls)
        }
    }

    /// This function is called when files are dropped onto the view.
    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (urlData, error) in
                DispatchQueue.main.async {
                    guard let urlData = urlData as? Data, let url = URL(dataRepresentation: urlData, relativeTo: nil) else {
                        return
                    }
                    if !self.fileURLs.contains(url) {
                        self.fileURLs.append(url)
                    }
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
            guard let newDate = parseDate(from: fileName) else {
                failedFiles.append(fileName)
                continue
            }
            
            do {
                var attributesToUpdate: [FileAttributeKey: Any] = [.creationDate: newDate]
                let currentAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
                
                if let currentModificationDate = currentAttributes[.modificationDate] as? Date {
                    if newDate > currentModificationDate {
                        attributesToUpdate[.modificationDate] = newDate
                    }
                } else {
                    attributesToUpdate[.modificationDate] = newDate
                }
                
                try FileManager.default.setAttributes(attributesToUpdate, ofItemAtPath: url.path)
                successCount += 1
            } catch {
                failedFiles.append(fileName)
            }
        }
        
        self.processingResult = ProcessingResult(successCount: successCount, failedFiles: failedFiles)
        self.isShowingResultAlert = true
        fileURLs.removeAll()
    }

    /// Parses a filename to extract a date based on predefined rules.
    private func parseDate(from fileName: String) -> Date? {
        guard let match = fileName.firstMatch(of: /^(\d{4}[-_]\d{4}|\d{4}[-_]\d{2}[-_]\d{2}|\d{8}|\d{4}[-_]\d{2}|\d{6})/) else {
            return nil
        }

        let datePrefix = String(match.1)
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents(hour: 12, minute: 0)
        
        let YEAR_MIN = 1900
        let YEAR_MAX = 2200

        func isValidYear(_ y: Int) -> Bool { (YEAR_MIN...YEAR_MAX).contains(y) }
        
        if let rangeMatch = datePrefix.firstMatch(of: /^(\d{4})[-_](\d{4})$/) {
            guard let y1 = Int(rangeMatch.1), let y2 = Int(rangeMatch.2), isValidYear(y1), isValidYear(y2) else { return nil }
            components.year = y2
            components.month = 12
            components.day = 31
        }
        else if let fullDateMatch = datePrefix.firstMatch(of: /^(\d{4})[-_](\d{2})[-_](\d{2})$/) {
            guard let y = Int(fullDateMatch.1), let m = Int(fullDateMatch.2), let d = Int(fullDateMatch.3), isValidYear(y) else { return nil }
            components.year = y
            components.month = m
            components.day = d
        }
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
        else if let yearMonthMatch = datePrefix.firstMatch(of: /^(\d{4})[-_](\d{2})$/) {
            guard let y = Int(yearMonthMatch.1), let m = Int(yearMonthMatch.2), isValidYear(y) else { return nil }
            var tempComponents = DateComponents(year: y, month: m)
            
            if let dateForMonth = calendar.date(from: tempComponents), let range = calendar.range(of: .day, in: .month, for: dateForMonth) {
                tempComponents.day = range.count
                components = tempComponents
            } else { return nil }
        }
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

// MARK: - Extensions

extension DateComponents {
    /// Checks if the components form a valid date in the given calendar.
    /// For example, it returns false for components representing February 30th.
    func isValidDate(in calendar: Calendar) -> Bool {
        return calendar.date(from: self) != nil
    }
}
