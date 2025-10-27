# solo4 README

## What the app stores
It stores a simple list of notes you type in (each note has the text, whether it’s done, and when it was created).

Reason: a list can grow and needs to stick around after you close the app, so it must be saved locally.

## The storage I used
SQLite for the actual notes list (the real data).

shared_preferences for tiny app settings (a switch that shows/hides completed notes, and a one-time ‘welcome’ message flag).

## How to run the project
1. Navigate to the lib/ directory and run:

    flutter pub get
    flutter run

2. In the app, add 5 or more notes. Check a couple as ‘done’.

3. Flip the ‘Show completed’ switch off (so completed notes hide).

4. Fully close the app (swipe it away / stop it).

5. Re-open the app:
    Your notes are still there (from SQLite).
    The switch setting is remembered (from shared_preferences).

6. Tap ‘Clear all’, close the app, and re-open then list stays empty (the changes should be saved).

## Data format and edge case
Notes (SQLite table)
    id (number), text (string), done (0 or 1), createdAt (number of milliseconds since 1970).
    Think of it as a little spreadsheet on your phone with those columns.

Settings (shared_preferences)
    show_completed (true/false), first_run_shown (true/false).
