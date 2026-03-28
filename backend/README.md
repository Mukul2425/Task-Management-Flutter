# Backend (FastAPI + SQLite)
## Setup
```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```
## Run
```bash
uvicorn app.main:app --reload --port 8000
```
The API will auto-create `app.db` (SQLite) on startup.
