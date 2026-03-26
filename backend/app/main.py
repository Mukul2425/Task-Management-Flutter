from __future__ import annotations

import asyncio

from fastapi import Depends, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import select
from sqlalchemy.orm import Session

from .db import SessionLocal, init_db
from .models import Task, TaskStatus
from .schemas import TaskCreate, TaskOut, TaskUpdate

app = FastAPI(title="Task Management API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@app.on_event("startup")
def _startup() -> None:
    init_db()


def _validate_blocked_by(db: Session, task_id: int | None, blocked_by_id: int | None) -> None:
    if blocked_by_id is None:
        return
    if task_id is not None and blocked_by_id == task_id:
        raise HTTPException(status_code=400, detail="A task cannot be blocked by itself.")

    blocker = db.get(Task, blocked_by_id)
    if blocker is None:
        raise HTTPException(status_code=400, detail="blocked_by_id does not exist.")


