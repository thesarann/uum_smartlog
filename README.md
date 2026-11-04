# UUM SmartLog

A Flutter mobile app for logging and managing study sessions. Built for Assignment 1 (STTPK2143).

## Purpose

UUM SmartLog helps university students record and track their study sessions. Students often lose track of how much time they spend studying each subject. This app provides a simple, persistent, offline log so students can review their study habits and stay accountable.

**Intended users:** University students who want a lightweight, offline study tracker.

**How it addresses the need:** The app lets students quickly log a study session with a title, subject, duration, and optional notes. All records are stored locally in SQLite, so they persist across app restarts. Students can view, edit, delete, and paginate through their saved sessions.

## Record Fields

| Field | Type | Required | Validation |
|---|---|---|---|
| Title | Text | Yes | Minimum 3 characters |
| Subject / Category | Dropdown | Yes | Must be selected from list |
| Duration (minutes) | Integer | Yes | Must be > 0 and ≤ 1440 |
| Notes | Text | No | Optional free text |
| Created At | Timestamp | Auto | Set on insert (ISO 8601) |

## Database Structure

**Database name:** `uum_smartlog.db`
**Table name:** `study_sessions`

| Column | Type | Constraints |
|---|---|---|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT |
| `title` | TEXT | NOT NULL |
| `subject` | TEXT | NOT NULL |
| `durationMinutes` | INTEGER | NOT NULL |
| `notes` | TEXT | Nullable |
| `createdAt` | TEXT | NOT NULL (ISO 8601 timestamp) |

Records are ordered by `createdAt DESC, id DESC` (newest first). Pagination uses SQL `LIMIT 10 OFFSET (page-1)*10`.

## Setup Steps

### Prerequisites

- Flutter SDK (3.13.0 or later)
- Android Studio / VS Code with Flutter plugin
- Android emulator or physical Android device

### Steps

1. Clone the repository:
git clone https://github.com/[your-username]/uum_smartlog.git
cd uum_smartlog

2. Install dependencies:
flutter pub get

3. Ensure the asset exists at `assets/images/uum_logo.png`. Replace with your own logo if needed.

4. Run the app:
flutter run

### Building an APK
flutter build apk --release


The APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

## Main Flow

1. **Splash screen** — Displays for ~3 seconds, then navigates to home.
2. **Home screen** — Lists saved study sessions (10 per page, newest first). Shows an empty state when no records exist. Has an Add button (FAB) and an app-bar refresh action.
3. **Add record** — Form with title, subject dropdown, duration, and optional notes. Validation runs before the confirmation dialog appears. Cancel leaves nothing saved; Confirm inserts into SQLite and reloads page 1.
4. **Details** — Tap a record to view all saved fields in a dialog.
5. **Edit** — From the details dialog, tap Edit to open a prefilled form. Validate, confirm, and update the same SQLite record.
6. **Delete** — Long-press a record to show a delete confirmation dialog. Delete only on confirm.
7. **Refresh** — Re-queries SQLite for the current page.
8. **Pagination** — Bottom controls show current page and total pages with Previous/Next. Disabled at boundaries. After deletion, the app clamps to the nearest valid page.

## Project Structure
lib/
├── main.dart # App entry point
├── models/
│ └── study_session.dart # StudySession model (toMap/fromMap)
├── database/
│ └── database_helper.dart # SQLite helper (CRUD + pagination)
└── screens/
├── splash_screen.dart # 3-second splash
├── home_screen.dart # List, pagination, details, delete
└── add_edit_screen.dart # Add/Edit form with validation

## Key Technical Details

- **State management:** `setState` only (as required).
- **Database:** `sqflite` package with `path` for joining database paths.
- **Pagination:** SQL `LIMIT 10 OFFSET (page-1)*10` — records are not loaded all at once.
- **Date formatting:** `intl` package for readable timestamps in the details dialog.
- **Validation:** `Form` + `TextFormField` validators with `AutovalidateMode.onUserInteraction`.

## Verification Summary

| Check | Result |
|---|---|
| Splash → Home transition (~3s) | ✅ Pass |
| Records persist after app restart | ✅ Pass |
| Blank field validation messages | ✅ Pass |
| Invalid duration (0, negative, non-numeric, > 1440) rejected | ✅ Pass |
| Save cancel leaves nothing saved | ✅ Pass |
| Save confirm inserts record | ✅ Pass |
| Details dialog shows all fields | ✅ Pass |
| Edit updates the same record | ✅ Pass |
| Edit cancel preserves original values | ✅ Pass |
| Delete cancel preserves record | ✅ Pass |
| Delete confirm removes only that record | ✅ Pass |
| Refresh re-queries SQLite | ✅ Pass |
| 21 records → 3 pages, ≤10 per page | ✅ Pass |
| Previous disabled on page 1, Next disabled on last page | ✅ Pass |
| Delete last record on last page → clamps to valid page | ✅ Pass |
| Empty state with both pagination buttons disabled | ✅ Pass |

## Course Information

- **Course:** STTPK2143 Application Programming
- **Assignment:** Assignment 1
- **Student:** Saranraj A/L Marimuthu
- **Matric No:** 309771
- **Class/Group:** Group A
