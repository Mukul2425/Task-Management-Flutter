from __future__ import annotations

import datetime as dt
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


TaskStatus = Literal["To-Do", "In Progress", "Done"]


class TaskBase(BaseModel):
    title: str = Field(min_length=1, max_length=120)
    description: str = Field(min_length=1, max_length=10_000)
    due_date: dt.date
    status: TaskStatus
    blocked_by_id: int | None = None



