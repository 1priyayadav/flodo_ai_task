from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select
from typing import List
from datetime import datetime, timezone, timedelta
import asyncio

from database import engine
from models import Task
from schemas import TaskCreate, TaskUpdate, TaskResponse

router = APIRouter(prefix="/tasks", tags=["Tasks"])

def get_session():
    with Session(engine) as session:
        yield session

@router.get("", response_model=List[TaskResponse])
def get_all_tasks(session: Session = Depends(get_session)):
    # Sorting Strategy: ORDER BY priority_order ASC, due_date ASC
    query = select(Task).order_by(Task.priority_order.asc(), Task.due_date.asc())
    tasks = session.exec(query).all()
    return tasks

@router.get("/{task_id}", response_model=TaskResponse)
def get_task(task_id: int, session: Session = Depends(get_session)):
    task = session.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    return task

@router.post("", response_model=TaskResponse)
async def create_task(task: TaskCreate, session: Session = Depends(get_session)):
    # Validation logic
    if not task.title.strip():
        raise HTTPException(status_code=400, detail="Title cannot be empty")
    if not task.description.strip():
        raise HTTPException(status_code=400, detail="Description cannot be empty")
    
    # Ensure due date is not in the past (using localized awareness if possible)
    now_utc = datetime.now(timezone.utc)
    task_due = task.due_date.replace(tzinfo=timezone.utc) if task.due_date.tzinfo is None else task.due_date
    if task_due < now_utc:
        raise HTTPException(status_code=400, detail="Due Date cannot be in the past")

    # Simulate 2-second delay
    await asyncio.sleep(2)

    db_task = Task.model_validate(task)
    db_task.due_date = task_due # ensure consistent UTC store
    session.add(db_task)
    session.commit()
    session.refresh(db_task)
    return db_task

@router.put("/{task_id}", response_model=TaskResponse)
async def update_task(task_id: int, task_update: TaskUpdate, session: Session = Depends(get_session)):
    db_task = session.get(Task, task_id)
    if not db_task:
        raise HTTPException(status_code=404, detail="Task not found")

    # Blocking Rules Validation
    if task_update.blocked_by is not None and task_update.blocked_by == task_id:
        raise HTTPException(status_code=400, detail="A task cannot block itself")

    # Prevent circular dependency (a simplistic check: is the task I want to be blocked by already blocked by ME?)
    # A full recursive depth check is ideal, but let's check one level for now.
    if task_update.blocked_by is not None:
        blocking_task = session.get(Task, task_update.blocked_by)
        if blocking_task and blocking_task.blocked_by == task_id:
            raise HTTPException(status_code=400, detail="Circular dependency prevented")

    # Simulate 2-second delay
    await asyncio.sleep(2)

    old_status = db_task.status
    update_data = task_update.model_dump(exclude_unset=True)
    
    for key, value in update_data.items():
        if key == "due_date" and value is not None:
            value = value.replace(tzinfo=timezone.utc) if value.tzinfo is None else value
        setattr(db_task, key, value)
        
    db_task.updated_at = datetime.now(timezone.utc)
    session.add(db_task)
    
    # Recurring Tasks Logic
    if db_task.status == "Done" and old_status != "Done" and db_task.recurrence in ["Daily", "Weekly"]:
        # Duplicate task with advanced due_date, reset status to To-Do, same blocked_by
        days_to_add = 1 if db_task.recurrence == "Daily" else 7
        new_due = db_task.due_date + timedelta(days=days_to_add)
        
        new_task = Task(
            title=db_task.title,
            description=db_task.description,
            due_date=new_due,
            status="To-Do",
            blocked_by=db_task.blocked_by,
            recurrence=db_task.recurrence,
            priority_order=db_task.priority_order
        )
        session.add(new_task)
        
    session.commit()
    session.refresh(db_task)
    return db_task
    
@router.delete("/{task_id}")
async def delete_task(task_id: int, session: Session = Depends(get_session)):
    db_task = session.get(Task, task_id)
    if not db_task:
        raise HTTPException(status_code=404, detail="Task not found")
        
    session.delete(db_task)
    
    # Cascade unblocking
    dependent_tasks = session.exec(select(Task).where(Task.blocked_by == task_id)).all()
    for dt in dependent_tasks:
        dt.blocked_by = None
        dt.updated_at = datetime.now(timezone.utc)
        session.add(dt)
        
    session.commit()
    return {"message": "Task deleted successfully"}
