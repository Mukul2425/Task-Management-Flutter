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


@app.get("/tasks", response_model=list[TaskOut])
def list_tasks(db: Session = Depends(get_db)):
    tasks = db.execute(select(Task).order_by(Task.due_date.asc(), Task.id.asc())).scalars().all()
    return tasks


@app.get("/tasks/{task_id}", response_model=TaskOut)
def get_task(task_id: int, db: Session = Depends(get_db)):
    task = db.get(Task, task_id)
    if task is None:
        raise HTTPException(status_code=404, detail="Task not found.")
    return task


@app.post("/tasks", response_model=TaskOut, status_code=201)
async def create_task(payload: TaskCreate, db: Session = Depends(get_db)):
    await asyncio.sleep(2)
    _validate_blocked_by(db, None, payload.blocked_by_id)

    task = Task(
        title=payload.title.strip(),
        description=payload.description.strip(),
        due_date=payload.due_date,
        status=TaskStatus(payload.status),
        blocked_by_id=payload.blocked_by_id,
    )
    db.add(task)
    db.commit()
    db.refresh(task)
    return task


@app.put("/tasks/{task_id}", response_model=TaskOut)
async def update_task(task_id: int, payload: TaskUpdate, db: Session = Depends(get_db)):
    task = db.get(Task, task_id)
    if task is None:
        raise HTTPException(status_code=404, detail="Task not found.")

    await asyncio.sleep(2)
    _validate_blocked_by(db, task_id, payload.blocked_by_id)

    task.title = payload.title.strip()
    task.description = payload.description.strip()
    task.due_date = payload.due_date
    task.status = TaskStatus(payload.status)
    task.blocked_by_id = payload.blocked_by_id

    db.add(task)
    db.commit()
    db.refresh(task)
    return task


@app.delete("/tasks/{task_id}", status_code=204)
def delete_task(task_id: int, db: Session = Depends(get_db)):
    task = db.get(Task, task_id)
    if task is None:
        raise HTTPException(status_code=404, detail="Task not found.")

    dependents = db.execute(select(Task).where(Task.blocked_by_id == task_id)).scalars().all()
    for dep in dependents:
        dep.blocked_by_id = None
        db.add(dep)

    db.delete(task)
    db.commit()
    return None

