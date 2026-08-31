import pytest
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Set environment variables for testing
os.environ['DATABASE_URL'] = 'sqlite:///test.db'
os.environ['CORS_ORIGINS'] = 'http://localhost:3000'

from index import app, engine
from models import Todo, SQLModel
from fastapi.testclient import TestClient
from sqlmodel import Session

# Initialize database tables
SQLModel.metadata.create_all(engine)

client = TestClient(app)

def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}

def test_create_todo():
    with Session(engine) as session:
        todo = Todo(title="Test Todo", description="Test Description", completed=False)
        session.add(todo)
        session.commit()
        session.refresh(todo)
        assert todo.id is not None
        assert todo.title == "Test Todo"

def test_read_todos():
    with Session(engine) as session:
        # Create a todo
        todo = Todo(title="Read Test", description="Read Description", completed=False)
        session.add(todo)
        session.commit()
        
        # Read all todos
        from sqlmodel import select
        todos = session.exec(select(Todo)).all()
        assert len(todos) > 0

def test_update_todo():
    with Session(engine) as session:
        # Create a todo
        todo = Todo(title="Update Test", description="Update Description", completed=False)
        session.add(todo)
        session.commit()
        session.refresh(todo)
        
        # Update the todo
        todo.title = "Updated Title"
        todo.completed = True
        session.commit()
        session.refresh(todo)
        
        assert todo.title == "Updated Title"
        assert todo.completed == True

def test_delete_todo():
    with Session(engine) as session:
        # Create a todo
        todo = Todo(title="Delete Test", description="Delete Description", completed=False)
        session.add(todo)
        session.commit()
        todo_id = todo.id
        
        # Delete the todo
        session.delete(todo)
        session.commit()
        
        # Verify it's deleted
        from sqlmodel import select
        deleted_todo = session.get(Todo, todo_id)
        assert deleted_todo is None
