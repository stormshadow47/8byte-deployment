import pytest
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Set environment variables for testing
os.environ['DATABASE_URL'] = 'sqlite:///test.db'
os.environ['CORS_ORIGINS'] = 'http://localhost:3000'

from index import app

from fastapi.testclient import TestClient

client = TestClient(app)

def test_read_root():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"message": "Todo API"}

def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}

def test_create_todo():
    response = client.post(
        "/api/todos/",
        json={"title": "Test Todo", "completed": False}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["title"] == "Test Todo"
    assert data["completed"] == False
    assert "id" in data

def test_read_todos():
    response = client.get("/api/todos/")
    assert response.status_code == 200
    assert isinstance(response.json(), list)

def test_read_todo():
    # First create a todo
    create_response = client.post(
        "/api/todos/",
        json={"title": "Test Todo", "completed": False}
    )
    todo_id = create_response.json()["id"]
    
    # Then read it
    response = client.get(f"/api/todos/{todo_id}")
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == todo_id
    assert data["title"] == "Test Todo"

def test_update_todo():
    # First create a todo
    create_response = client.post(
        "/api/todos/",
        json={"title": "Test Todo", "completed": False}
    )
    todo_id = create_response.json()["id"]
    
    # Then update it
    response = client.put(
        f"/api/todos/{todo_id}",
        json={"id": todo_id, "title": "Updated Todo", "completed": True}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["title"] == "Updated Todo"
    assert data["completed"] == True

def test_delete_todo():
    # First create a todo
    create_response = client.post(
        "/api/todos/",
        json={"title": "Test Todo", "completed": False}
    )
    todo_id = create_response.json()["id"]
    
    # Then delete it
    response = client.delete(f"/api/todos/{todo_id}")
    assert response.status_code == 200
