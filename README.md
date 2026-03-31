# Flodo AI Task Management App

## Project Overview

This is a full-stack Task Management application built for the Flodo AI take-home assignment. It implements a robust end-to-end architecture with task blocking rules, client-side caching for dependency resolutions, simulated server delays for resilient UI testing, and a background Recurring Task engine.

**Track Chosen:** Track A (Full-Stack Builder)
**Extra Feature:** Recurring Tasks Logic (Daily/Weekly toggles intelligently duplicating completed tasks while shifting due dates).

## 🎥 1-Minute Demo Video

![Flodo App Demo Recording](flodo_demo.webp)

## Tech Stack

- **Frontend**: Flutter & Dart (Material 3)
- **State Management**: `provider` (Riverpod alternative) + `shared_preferences` for draft persistence.
- **Backend**: FastAPI (Python)
- **Database**: SQLite (managed with SQLModel / SQLAlchemy)

## Setup Instructions

### Backend Server setup
1. Ensure Python 3.9+ is installed.
2. Open a terminal and navigate to the `backend/` directory:
   ```bash
   cd backend
   ```
3. Create a virtual environment and activate it:
   ```bash
   python -m venv venv
   # On Windows:
   .\venv\Scripts\activate
   # On Mac/Linux:
   source venv/bin/activate
   ```
4. Install the dependencies:
   ```bash
   pip install fastapi uvicorn sqlmodel
   ```
5. Run the FastAPI development server:
   ```bash
   uvicorn main:app --reload
   ```
   The backend will start running on `http://127.0.0.1:8000`.

### Flutter Application setup
1. Ensure Flutter is installed and your system path is configured correctly.
2. Open a terminal and navigate to the `frontend/` directory:
   ```bash
   cd frontend
   ```
3. Generate platform-specific directories if they are missing:
   ```bash
   flutter create .
   ```
4. Install dependencies:
   ```bash
   flutter pub get
   ```
5. Run the app on an emulator or connected device:
   ```bash
   flutter run
   ```

## Database Schema

The SQLite database contains a single `task` table with the following schema:
- `id` (INTEGER, Primary Key)
- `title` (VARCHAR)
- `description` (VARCHAR)
- `due_date` (DATETIME) - Stored exclusively in UTC.
- `status` (VARCHAR) - Enumerated: To-Do, In Progress, Done.
- `blocked_by` (INTEGER) - Foreign Key to another `task`'s ID.
- `recurrence` (VARCHAR) - Enumerated: None, Daily, Weekly.
- `priority_order` (INTEGER) - Designed for sorting expandability.
- `created_at` (DATETIME)
- `updated_at` (DATETIME)

## API Endpoints (OpenAPI Schema)

The API is fully documented via Swagger UI which is interactively accessible at [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs) when the backend is running. Below is the endpoint specification derived exactly from the `/openapi.json` schema:

### `GET /tasks`
Retrieves an array of all tasks, ordered by `priority_order` ASC and `due_date` ASC.
- **Response**: `200 OK` - Array of `TaskResponse` objects.

### `GET /tasks/{task_id}`
Retrieves details for a specific task.
- **Parameters**: `task_id` (integer, required)
- **Response**: `200 OK` - `TaskResponse` object.
- **Errors**: `404 Not Found` (Task not found)

### `POST /tasks`
Creates a new task. Includes validation against past dates. Simulates a 2s delay.
- **Request Body**: `TaskCreate` exact schema
- **Response**: `200 OK` - Created `TaskResponse` object.
- **Errors**: `400 Bad Request` (Title/Description empty, or Due Date in past).

### `PUT /tasks/{task_id}`
Updates an existing task. Triggers Recurrence duplication logic if status changes to Done. Prevents self-blocking. Simulates a 2s delay.
- **Parameters**: `task_id` (integer, required)
- **Request Body**: `TaskUpdate` schema (All fields optional drop-in replacements).
- **Response**: `200 OK` - Updated `TaskResponse` object.
- **Errors**: `400 Bad Request` (Circular dependency detected), `404 Not Found`.

### `DELETE /tasks/{task_id}`
Safely deletes a task, and automatically cascades `blocked_by=null` downward to any dependent tasks.
- **Parameters**: `task_id` (integer, required)
- **Response**: `200 OK` - `{"message": "Task deleted successfully"}`
- **Errors**: `404 Not Found`.

### Data Models

**TaskCreate Schema**
```json
{
  "title": "string",
  "description": "string",
  "due_date": "2026-04-02T12:00:00Z",
  "status": "To-Do",
  "blocked_by": null,
  "recurrence": "None",
  "priority_order": 0
}
```

**TaskResponse Schema**
```json
{
  "id": 1,
  "title": "string",
  "description": "string",
  "due_date": "2026-04-02T12:00:00Z",
  "status": "To-Do",
  "blocked_by": null,
  "recurrence": "None",
  "priority_order": 0,
  "created_at": "2026-03-31T09:00:00Z",
  "updated_at": "2026-03-31T09:00:00Z"
}
```

## AI Usage Notes

**LLM Models Used**: Google Gemini 3.1 Pro (High)

**Prompts That Were Highly Effective**:
- I utilized detailed breakdown prompts to structurally implement the Flutter Draft logic (`shared_preferences` debounced to 500ms).
- I asked the model to outline how state management architectures natively approach cyclic circular dependencies inside a local memory cache.

**Instances of Unintended Code execution \/ Corrections**:
- Early iterations missed passing `timezone.utc` to standard Python `datetime.now()` calls. The AI logically caught that SQLite natively stores timezone offsets improperly without explicit `timezone.utc` definitions, leading to a correction via `.replace(tzinfo=timezone.utc)`.

## Known Limitations

1. **Circular Dependency Checking**: The API explicitly checks 1 step downwards to prevent circular dependencies but does not trace the entire n=depth dependency tree.
2. **Localhost IP**: The API base URL points to `127.0.0.1`. If using an Android Emulator, `10.0.2.2` might be required dynamically over the static string!
