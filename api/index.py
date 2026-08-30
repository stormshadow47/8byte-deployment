from contextlib import asynccontextmanager
from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlmodel import Session, create_engine, select, SQLModel
from typing import Annotated
from settings import DATABASE_URL, CORS_ORIGINS
from models import Todo

def get_engine():
    connection_string = str(DATABASE_URL).replace(
        "postgresql", "postgresql+psycopg2", 1
    )
    return create_engine(connection_string, pool_pre_ping=True)

engine = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    global engine
    if engine is None:
        engine = get_engine()
        SQLModel.metadata.create_all(engine)
    yield


app = FastAPI(lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_credentials=False,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["Content-Type"],
)

def get_session():
    with Session(engine) as session:
        yield session


@app.get("/health")
def health_check():
    return {"status": "healthy"}


@app.post("/api/todos", response_model=Todo)
def create_todo(todo: Todo, session: Annotated[Session, Depends(get_session)]):
    todo.id = None
    session.add(todo)
    session.commit()
    session.refresh(todo)
    return todo


@app.get("/api/todos")
def read_todos():
    with Session(engine) as session:
        todos = session.exec(select(Todo)).all()
        return {"todos": todos}

@app.delete("/api/todos/{todo_id}", response_model=Todo)
def delete_todo(todo_id: int, session: Annotated[Session, Depends(get_session)]):
    db_todo = session.get(Todo, todo_id)
    if not db_todo:
        raise HTTPException(status_code=404, detail="Todo not found")
    session.delete(db_todo)
    session.commit()
    return db_todo


@app.put("/api/todos/{todo_id}", response_model=Todo)
def update_todo(
    todo_id: int, todo: Todo, session: Annotated[Session, Depends(get_session)]
):
    db_todo = session.get(Todo, todo_id)
    if not db_todo:
        raise HTTPException(status_code=404, detail="Todo not found")
    db_todo.completed = todo.completed
    session.commit()
    session.refresh(db_todo)
    return db_todo
