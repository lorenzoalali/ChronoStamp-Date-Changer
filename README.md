# ChronoStamp Date Changer

A simple macOS utility to set a file's creation and modification dates based on a date found in its filename.

## Description

Do you have a collection of photos, documents, or scanned files with names like `2023-10-26_receipt.pdf` or `19981225_vacation_photo.jpg`? This tool lets you drag and drop those files to automatically update their filesystem "Date Created" attribute to match the date in their name. The "Date Modified" is also updated, but only if the file's current modification date is older than the date in the filename. This helps keep your files chronologically sorted and accurately timestamped without losing the last-modified date for recently edited files.

## Features

-   **Drag and Drop Interface**: Simply drop files onto the app window to add them to the processing queue.
-   **Batch Processing**: Update dates for multiple files at once.
-   **Flexible Date Parsing**: Recognizes several common date formats at the start of a filename.
-   **Safe**: The app only changes file metadata (timestamps); the file contents are never altered.

## How to Use

1.  **Launch** the application.
2.  **Drag and drop** one or more files onto the designated drop zone in the window.
3.  The files will appear in a list.
4.  Click the **"Update File Dates"** button.
5.  The app will process each file. The "Date Created" will be set from the filename. The "Date Modified" will only be updated if the date from the filename is more recent than the file's existing modification date. The list will clear after processing is complete.

## Supported Filename Formats

The date must appear at the very beginning of the filename. The following formats are supported:

-   **Exact Date**: `YYYY-MM-DD`, `YYYY_MM_DD`, or `YYYYMMDD`
    -   Example: `2023-04-15_notes.txt` sets the date to April 15, 2023.
-   **Month**: `YYYY-MM`, `YYYY_MM`, or `YYYYMM`
    -   Example: `2023-04_report.docx` sets the date to the *last day* of that month (April 30, 2023).
-   **Year Range**: `YYYY-YYYY`, `YYYY_YYYY`, or `YYYYYYYY`
    -   Example: `2021-2022_project.zip` sets the date to the *last day* of the second year (December 31, 2022).

**Notes:**
-   Years must be between 1900 and 2200.
-   For 8-digit strings without separators (e.g., `20230415`), the tool first tries to parse it as `YYYYMMDD`. If that is not a valid date, it then tries to parse it as a `YYYYYYYY` year range.

## Requirements

-   macOS 13.0 (Ventura) or later.

> Note: This application has been developed and tested on macOS Tahoe (26).

## Building from Source

1.  Clone this repository.
2.  Open the `.xcodeproj` file in Xcode.
3.  Select the app's target and `My Mac` as the run destination.
4.  Build and run (⌘+R).

## License

This project is licensed under the MIT License.
