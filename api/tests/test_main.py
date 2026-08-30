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

def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}
