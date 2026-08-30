import pytest
from fastapi.testclient import TestClient
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from index import app

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

    create_response = client.post(
        "/api/todos/",
        json={"title": "Test Todo", "completed": False}
    )
    todo_id = create_response.json()["id"]

    response = client.put(
        f"/api/todos/{todo_id}",
        json={"id": todo_id, "title": "Updated Todo", "completed": True}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["title"] == "Updated Todo"
    assert data["completed"] == True

def test_delete_todo():

    create_response = client.post(
        "/api/todos/",
        json={"title": "Test Todo", "completed": False}
    )
    todo_id = create_response.json()["id"]
    

    response = client.delete(f"/api/todos/{todo_id}")
    assert response.status_code == 200
