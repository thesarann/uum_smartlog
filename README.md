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
