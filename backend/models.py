from sqlmodel import SQLModel, Field
from typing import Optional
from datetime import datetime, timezone

class Task(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    title: str
    description: str
    due_date: datetime # UTC stored
    status: str = Field(default="To-Do") # "To-Do", "In Progress", "Done"
    blocked_by: Optional[int] = Field(default=None, foreign_key="task.id")
    recurrence: str = Field(default="None") # "None", "Daily", "Weekly"
    priority_order: int = Field(default=0)
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    updated_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
