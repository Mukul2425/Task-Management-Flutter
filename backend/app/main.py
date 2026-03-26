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




