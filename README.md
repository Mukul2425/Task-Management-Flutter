## Track + stretch goal

- **Track**: A (Flutter + Python FastAPI + SQLite)
- **Stretch goal implemented**: **Debounced search (300ms) + highlighted matches** in task titles

## Repo structure

- `backend/`: FastAPI REST API + SQLite
- `mobile/`: Flutter app source (Dart)

## Backend (FastAPI)

### Run

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

Notes:
- The API auto-creates `backend/app.db` on startup.
- **Task create + update intentionally sleep for 2 seconds** to simulate slow saves.

## Mobile (Flutter)

### Setup

From repo root:

```bash
cd mobile
flutter pub get
flutter run
```

If you need platform folders (android/ios) generated, run:

```bash
cd mobile
flutter create .
flutter pub get
flutter run
```

### Backend base URL

The app defaults to:
- Android emulator: `http://10.0.2.2:8000`
- iOS simulator / desktop: `http://127.0.0.1:8000`

You can change this in `mobile/lib/src/core/api/api_client.dart`.

## Core requirements mapping

- **Task model**: `title`, `description`, `due_date`, `status`, `blocked_by_id (optional)`
- **CRUD**: list/create/update/delete via REST
- **Blocked By visuals**: blocked tasks are greyed/locked until blocker is **Done**
- **Drafts**: create screen persists draft (SharedPreferences) if you navigate away or background
- **Search + filter**:
  - Search by title (debounced 300ms)
  - Filter by status dropdown
- **2-second delay handling**:
  - API delays create/update by 2 seconds
  - UI shows loading state and disables Save (prevents double-tap)

## AI usage report (what I asked for)

- Generate a clean FastAPI + SQLite CRUD skeleton with a 2s async delay for POST/PUT.
- Propose a Flutter UI architecture (Riverpod), plus drafts persistence for a form screen.
- Implement debounced search + highlighted matches in a Flutter list.

## AI mistakes I corrected

- A card border implementation initially referenced a `Border` in a way that doesn’t map to `RoundedRectangleBorder.side`. I replaced it with a `BorderSide` so the widget compiles cleanly.

