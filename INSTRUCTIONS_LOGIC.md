# ChronoStamp App Logic Explanation

This document provides a detailed breakdown of the internal logic of the ChronoStamp Date Changer application.

## 1. User Interface (UI) and Interaction

The application is built with SwiftUI and consists of a single main view (`ContentView.swift`).

-   **Drag and Drop:** The central dashed rectangle is a drop zone. When files are dragged over it, the border highlights. The `.onDrop` modifier listens for items of type `UTType.fileURL`.
-   **File Handling:** When files are dropped, the `handleDrop` function is triggered. It asynchronously loads the URL for each dropped item and appends it to a `@State` variable called `fileURLs`. This state variable automatically updates the UI to show a list of the dropped files.
-   **Processing Trigger:** The "Update File Dates" button is enabled only when the `fileURLs` list is not empty. Clicking it calls the `processFiles` function.
-   **Results Alert:** After processing, a results summary is stored in the `@State` variable `processingResult`, and a boolean flag `isShowingResultAlert` is set to `true`. This triggers a SwiftUI `alert` to be displayed, showing the user how many files were updated successfully and listing any that failed.

## 2. Core Logic: File Processing

The `processFiles` function contains the main business logic. It executes when the user clicks the "Update File Dates" button.

1.  **Initialization:** It initializes a `successCount` integer and a `failedFiles` array of strings to track the outcome.
2.  **Iteration:** It loops through each `URL` in the `fileURLs` list.
3.  **Date Parsing:** For each file, it first calls the `parseDate(from:)` helper function, passing the filename. If this function returns `nil` (meaning no valid date could be parsed from the filename), the file is added to the `failedFiles` list, and the loop continues to the next file.

### 2.1. Attribute Update Logic (Key Change)

If a valid date (`newDate`) is successfully parsed from the filename, the app proceeds to update the file's filesystem attributes. This is done inside a `do-catch` block to handle potential errors from the `FileManager`.

-   **Creation Date:** The `creationDate` attribute is **always** set to the `newDate` parsed from the filename. This is the primary function of the app.

-   **Modification Date (Conditional):** The logic for the `modificationDate` is now conditional:
    1.  The app first reads the file's current attributes using `FileManager.default.attributesOfItem(atPath:)`.
    2.  It retrieves the current `modificationDate`.
    3.  It compares the `newDate` from the filename with the file's `currentModificationDate`.
    4.  The `modificationDate` attribute is only updated if `newDate` is **more recent than** (`>`) the `currentModificationDate`.
    5.  If the file's existing `modificationDate` is already more recent than (or the same as) the `newDate`, it is left untouched. This preserves the timestamp of the last actual modification if it happened after the date encoded in the filename.
    6.  If for some reason a modification date doesn't exist on the file, it is set to `newDate`.

-   **Applying Changes:** The `FileManager.default.setAttributes(...)` function is called with a dictionary containing only the attributes that need to be changed.

4.  **Error Handling:** If any part of the attribute reading or writing process fails (e.g., due to file permissions), the `catch` block executes, the file is added to the `failedFiles` list.
5.  **Cleanup and Results:** After the loop finishes, the results are saved, the results alert is triggered, and the `fileURLs` list is cleared to ready the app for the next batch.

## 3. Core Logic: Date Parsing

The `parseDate(from:)` function is responsible for extracting a `Date` object from a filename string.

1.  **Initial Regex Match:** It uses a single, broad regular expression (`/^(\d{4}[-_]\d{4}|\d{4}[-_]\d{2}[-_]\d{2}|\d{8}|\d{4}[-_]\d{2}|\d{6})/`) to find a potential date-like string at the very beginning (`^`) of the filename. If no pattern matches, it returns `nil` immediately.

2.  **Detailed Pattern Matching:** If a prefix is found, it is then checked against more specific patterns in a cascading `if-else if` structure to determine its format:
    -   `YYYY-YYYY` or `YYYY_YYYY`: A year range. The date is set to December 31st of the *second* year.
    -   `YYYY-MM-DD` or `YYYY_MM_DD`: A full date.
    -   `8 digits`: This is ambiguous and is handled with priority:
        -   First, it tries to parse it as `YYYYMMDD`. It checks if this forms a valid date (e.g., `20230229` is invalid).
        -   If it's not a valid date, it then tries to parse it as a `YYYYYYYY` year range.
    -   `YYYY-MM` or `YYYY_MM`: A year and month. The date is set to the **last day** of that month (e.g., `2023-02` becomes `2023-02-28`).
    -   `6 digits`: Assumed to be `YYYYMM`. The date is set to the last day of that month.

3.  **Validation:**
    -   Throughout the process, years are validated to be within a reasonable range (1900-2200).
    -   After all components (year, month, day) are determined, they are checked with `components.isValidDate(in: calendar)` to ensure the combination is valid (e.g., prevents dates like April 31st).

4.  **Date Creation:** If all checks pass, a `Date` object is created from the components (with the time set to a consistent 12:00 PM) and returned. If any check fails, the function returns `nil`.
