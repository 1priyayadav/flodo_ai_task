from sqlmodel import create_engine, SQLModel
from sqlmodel.pool import StaticPool

sqlite_file_name = "database.db"
sqlite_url = f"sqlite:///{sqlite_file_name}"

# Using StaticPool to allow multi-threading in SQLite for dev purposes, 
# although actual deployment would typically use PostgreSQL.
engine = create_engine(
    sqlite_url, 
    connect_args={"check_same_thread": False}, 
    poolclass=StaticPool
)

def create_db_and_tables():
    SQLModel.metadata.create_all(engine)
