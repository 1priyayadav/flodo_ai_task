from pydantic import BaseModel, ConfigDict
from datetime import datetime
from typing import Optional

class TaskCreate(BaseModel):
    title: str
    description: str
    due_date: datetime
    status: str = "To-Do"
    blocked_by: Optional[int] = None
    recurrence: str = "None"
    priority_order: int = 0

class TaskUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    due_date: Optional[datetime] = None
    status: Optional[str] = None
    blocked_by: Optional[int] = None
    recurrence: Optional[str] = None
    priority_order: Optional[int] = None

class TaskResponse(BaseModel):
    id: int
    title: str
    description: str
    due_date: datetime
    status: str
    blocked_by: Optional[int]
    recurrence: str
    priority_order: int
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
