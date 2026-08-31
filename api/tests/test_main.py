import pytest
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Set environment variables for testing
os.environ['DATABASE_URL'] = 'sqlite:///test.db'
os.environ['CORS_ORIGINS'] = 'http://localhost:3000'

from index import app
from models import Todo

from fastapi.testclient import TestClient

client = TestClient(app)

def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}

def test_create_todo():
    todo_data = {"title": "Test Todo", "description": "Test Description", "completed": False}
    response = client.post("/api/todos", json=todo_data)
    assert response.status_code == 200
    data = response.json()
    assert data["title"] == todo_data["title"]
    assert data["description"] == todo_data["description"]
    assert data["completed"] == todo_data["completed"]
    assert "id" in data

def test_read_todos():
    # First create a todo
    todo_data = {"title": "Read Test", "description": "Read Description", "completed": False}
    client.post("/api/todos", json=todo_data)
    
    # Then read all todos
    response = client.get("/api/todos")
    assert response.status_code == 200
    data = response.json()
    assert "todos" in data
    assert len(data["todos"]) > 0

def test_update_todo():
    # First create a todo
    todo_data = {"title": "Update Test", "description": "Update Description", "completed": False}
    create_response = client.post("/api/todos", json=todo_data)
    todo_id = create_response.json()["id"]
    
    # Then update the todo
    update_data = {"title": "Updated Title", "description": "Updated Description", "completed": True}
    response = client.put(f"/api/todos/{todo_id}", json=update_data)
    assert response.status_code == 200
    data = response.json()
    assert data["title"] == update_data["title"]
    assert data["completed"] == update_data["completed"]

def test_delete_todo():
    # First create a todo
    todo_data = {"title": "Delete Test", "description": "Delete Description", "completed": False}
    create_response = client.post("/api/todos", json=todo_data)
    todo_id = create_response.json()["id"]
    
    # Then delete the todo
    response = client.delete(f"/api/todos/{todo_id}")
    assert response.status_code == 200
    
    # Verify it's deleted
    get_response = client.get("/api/todos")
    todos = get_response.json()["todos"]
    assert not any(todo["id"] == todo_id for todo in todos)

def test_delete_nonexistent_todo():
    response = client.delete("/api/todos/99999")
    assert response.status_code == 404
