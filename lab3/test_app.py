"""
Test suite for Task Tracker Flask application
pytest with coverage
"""

import pytest
import json
import sys
from pathlib import Path

# Додати папку app в sys.path
sys.path.insert(0, str(Path(__file__).parent.parent))

# Mock для марiadb
import unittest.mock as mock


@pytest.fixture
def app():
    """Create and configure a test application."""
    # Імпортуємо app
    from app import app as flask_app
    
    flask_app.config['TESTING'] = True
    return flask_app


@pytest.fixture
def client(app):
    """A test client for the app."""
    return app.test_client()


@pytest.fixture
def mock_db():
    """Mock database connection."""
    with mock.patch('app.get_db_connection') as mock_conn:
        yield mock_conn


# ===== HEALTH CHECK TESTS =====
class TestHealthCheck:
    """Tests for health check endpoints."""
    
    def test_health_alive(self, client):
        """Test /health/alive endpoint."""
        response = client.get('/health/alive')
        assert response.status_code == 200
        assert response.data == b'OK'
    
    def test_health_ready_success(self, client, mock_db):
        """Test /health/ready with successful DB connection."""
        mock_conn = mock.Mock()
        mock_db.return_value = mock_conn
        
        response = client.get('/health/ready')
        assert response.status_code == 200
        assert response.data == b'OK'
    
    def test_health_ready_failure(self, client, mock_db):
        """Test /health/ready with failed DB connection."""
        mock_db.return_value = None
        
        response = client.get('/health/ready')
        assert response.status_code == 500
        assert b'error' in response.data.lower()


# ===== ROOT ENDPOINT TESTS =====
class TestRootEndpoint:
    """Tests for root endpoint."""
    
    def test_root_json(self, client):
        """Test root endpoint returns JSON."""
        response = client.get('/', headers={'Accept': 'application/json'})
        assert response.status_code == 200
        assert response.content_type == 'application/json'
        
        data = json.loads(response.data)
        assert 'name' in data
        assert 'endpoints' in data
        assert data['name'] == 'Task Tracker API'
    
    def test_root_html(self, client):
        """Test root endpoint returns HTML."""
        response = client.get('/', headers={'Accept': 'text/html'})
        assert response.status_code == 200
        assert b'Task Tracker' in response.data


# ===== TASKS ENDPOINT TESTS =====
class TestTasksEndpoint:
    """Tests for /tasks endpoint."""
    
    def test_get_tasks_empty(self, client, mock_db):
        """Test getting empty task list."""
        mock_conn = mock.Mock()
        mock_cursor = mock.Mock()
        mock_conn.cursor.return_value = mock_cursor
        mock_cursor.fetchall.return_value = []
        mock_db.return_value = mock_conn
        
        response = client.get('/tasks', headers={'Accept': 'application/json'})
        assert response.status_code == 200
        assert response.data == b'[]'
    
    def test_get_tasks_with_data(self, client, mock_db):
        """Test getting tasks with data."""
        mock_conn = mock.Mock()
        mock_cursor = mock.Mock()
        mock_conn.cursor.return_value = mock_cursor
        
        tasks_data = [
            {
                'id': 1,
                'title': 'Test task',
                'status': 'pending',
                'created_at': '2024-01-15T10:30:00'
            }
        ]
        mock_cursor.fetchall.return_value = tasks_data
        mock_db.return_value = mock_conn
        
        response = client.get('/tasks', headers={'Accept': 'application/json'})
        assert response.status_code == 200
        
        data = json.loads(response.data)
        assert len(data) == 1
        assert data[0]['title'] == 'Test task'
        assert data[0]['status'] == 'pending'
    
    def test_get_tasks_db_error(self, client, mock_db):
        """Test getting tasks with DB error."""
        mock_db.return_value = None
        
        response = client.get('/tasks')
        assert response.status_code == 500


# ===== CREATE TASK TESTS =====
class TestCreateTask:
    """Tests for POST /tasks endpoint."""
    
    def test_create_task_json(self, client, mock_db):
        """Test creating a task with JSON."""
        mock_conn = mock.Mock()
        mock_cursor = mock.Mock()
        mock_conn.cursor.return_value = mock_cursor
        mock_cursor.lastrowid = 1
        mock_db.return_value = mock_conn
        
        response = client.post(
            '/tasks',
            data=json.dumps({'title': 'New task'}),
            content_type='application/json',
            headers={'Accept': 'application/json'}
        )
        
        assert response.status_code == 201
        data = json.loads(response.data)
        assert data['id'] == 1
        assert data['title'] == 'New task'
        assert data['status'] == 'pending'
    
    def test_create_task_form_data(self, client, mock_db):
        """Test creating a task with form data."""
        mock_conn = mock.Mock()
        mock_cursor = mock.Mock()
        mock_conn.cursor.return_value = mock_cursor
        mock_cursor.lastrowid = 2
        mock_db.return_value = mock_conn
        
        response = client.post(
            '/tasks',
            data={'title': 'Form task'},
            headers={'Accept': 'application/json'}
        )
        
        assert response.status_code == 201
        data = json.loads(response.data)
        assert data['id'] == 2
    
    def test_create_task_no_title(self, client, mock_db):
        """Test creating a task without title."""
        mock_db.return_value = mock.Mock()
        
        response = client.post(
            '/tasks',
            data=json.dumps({}),
            content_type='application/json',
            headers={'Accept': 'application/json'}
        )
        
        assert response.status_code == 400
        data = json.loads(response.data)
        assert 'error' in data
    
    def test_create_task_db_error(self, client, mock_db):
        """Test creating a task with DB error."""
        mock_db.return_value = None
        
        response = client.post(
            '/tasks',
            data=json.dumps({'title': 'Task'}),
            content_type='application/json'
        )
        
        assert response.status_code == 500


# ===== MARK TASK DONE TESTS =====
class TestMarkTaskDone:
    """Tests for POST /tasks/<id>/done endpoint."""
    
    def test_mark_task_done_success(self, client, mock_db):
        """Test marking a task as done."""
        mock_conn = mock.Mock()
        mock_cursor = mock.Mock()
        mock_conn.cursor.return_value = mock_cursor
        mock_cursor.rowcount = 1
        mock_db.return_value = mock_conn
        
        response = client.post(
            '/tasks/1/done',
            headers={'Accept': 'application/json'}
        )
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['id'] == 1
        assert data['status'] == 'done'
    
    def test_mark_task_done_not_found(self, client, mock_db):
        """Test marking non-existent task as done."""
        mock_conn = mock.Mock()
        mock_cursor = mock.Mock()
        mock_conn.cursor.return_value = mock_cursor
        mock_cursor.rowcount = 0
        mock_db.return_value = mock_conn
        
        response = client.post(
            '/tasks/999/done',
            headers={'Accept': 'application/json'}
        )
        
        assert response.status_code == 404
        data = json.loads(response.data)
        assert 'error' in data
    
    def test_mark_task_done_db_error(self, client, mock_db):
        """Test marking task done with DB error."""
        mock_db.return_value = None
        
        response = client.post('/tasks/1/done')
        assert response.status_code == 500


# ===== CONTENT TYPE TESTS =====
class TestContentTypes:
    """Tests for different content types."""
    
    def test_json_response(self, client, mock_db):
        """Test JSON response format."""
        mock_conn = mock.Mock()
        mock_cursor = mock.Mock()
        mock_conn.cursor.return_value = mock_cursor
        mock_cursor.fetchall.return_value = []
        mock_db.return_value = mock_conn
        
        response = client.get('/tasks', headers={'Accept': 'application/json'})
        assert response.content_type == 'application/json'
    
    def test_html_response(self, client, mock_db):
        """Test HTML response format."""
        mock_conn = mock.Mock()
        mock_cursor = mock.Mock()
        mock_conn.cursor.return_value = mock_cursor
        mock_cursor.fetchall.return_value = []
        mock_db.return_value = mock_conn
        
        response = client.get('/tasks', headers={'Accept': 'text/html'})
        assert b'<table' in response.data or b'table' in response.data.lower()


# ===== EDGE CASES =====
class TestEdgeCases:
    """Tests for edge cases."""
    
    def test_invalid_endpoint(self, client):
        """Test accessing non-existent endpoint."""
        response = client.get('/invalid')
        assert response.status_code == 404
    
    def test_invalid_task_id(self, client):
        """Test accessing task with invalid ID."""
        response = client.get('/tasks/invalid')
        assert response.status_code == 404
    
    def test_long_title(self, client, mock_db):
        """Test creating task with long title."""
        mock_conn = mock.Mock()
        mock_cursor = mock.Mock()
        mock_conn.cursor.return_value = mock_cursor
        mock_cursor.lastrowid = 1
        mock_db.return_value = mock_conn
        
        long_title = 'x' * 300
        response = client.post(
            '/tasks',
            data=json.dumps({'title': long_title}),
            content_type='application/json'
        )
        
        # Повинен пройти або повернути помилку - залежить від реалізації
        assert response.status_code in [201, 400]


if __name__ == '__main__':
    pytest.main([__file__, '-v', '--cov'])
