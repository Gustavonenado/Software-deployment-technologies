#!/usr/bin/env python3
"""
Task Tracker Web Application
Простий сервіс для відстеження задач
"""

import os
import sys
import argparse
import logging
from datetime import datetime
from flask import Flask, jsonify, request, render_template_string
import mysql.connector
from mysql.connector import Error as MySQLError

# Логування
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Глобальні змінні для підключення до БД
db_connection = None
db_host = None
db_user = None
db_password = None
db_name = None

# HTML шаблон для коренево ендпоінту
ROOT_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>Task Tracker API</title>
</head>
<body>
    <h1>Task Tracker API</h1>
    <p>Сервіс для управління задачами</p>
    <h2>Доступні ендпоінти:</h2>
    <ul>
        <li><strong>GET /health/alive</strong> - Перевірка живого стану</li>
        <li><strong>GET /health/ready</strong> - Перевірка готовності до роботи</li>
        <li><strong>GET /tasks</strong> - Отримати список усіх задач</li>
        <li><strong>POST /tasks</strong> - Створити нову задачу (параметр: title)</li>
        <li><strong>POST /tasks/&lt;id&gt;/done</strong> - Позначити задачу як виконану</li>
    </ul>
</body>
</html>
"""

def get_db_connection():
    """Отримати підключення до бази даних"""
    try:
        conn = mysql.connector.connect(
            host=db_host,
            user=db_user,
            password=db_password,
            database=db_name
        )
        return conn
    except MySQLError as e:
        logger.error(f"Помилка підключення до БД: {e}")
        return None

@app.route('/', methods=['GET'])
def root():
    """Кореневий ендпоінт"""
    if request.accept_mimetypes.best == 'application/json':
        return jsonify({
            "name": "Task Tracker API",
            "version": "1.0",
            "endpoints": {
                "health": ["/health/alive", "/health/ready"],
                "tasks": [
                    "GET /tasks",
                    "POST /tasks",
                    "POST /tasks/<id>/done"
                ]
            }
        })
    return render_template_string(ROOT_TEMPLATE)

@app.route('/health/alive', methods=['GET'])
def health_alive():
    """Перевірка живого стану"""
    return "OK", 200

@app.route('/health/ready', methods=['GET'])
def health_ready():
    """Перевірка готовності (підключення до БД)"""
    try:
        conn = get_db_connection()
        if conn is None:
            return jsonify({"error": "Database connection failed"}), 500
        conn.close()
        return "OK", 200
    except Exception as e:
        logger.error(f"Помилка ready check: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/tasks', methods=['GET'])
def get_tasks():
    """Отримати список усіх задач"""
    try:
        conn = get_db_connection()
        if conn is None:
            return jsonify({"error": "Database connection failed"}), 500
        
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT id, title, status, created_at FROM tasks ORDER BY created_at DESC")
        tasks = cursor.fetchall()
        cursor.close()
        conn.close()
        
        # Форматування дат для JSON
        for task in tasks:
            if isinstance(task['created_at'], datetime):
                task['created_at'] = task['created_at'].isoformat()
        
        if request.accept_mimetypes.best == 'application/json':
            return jsonify(tasks)
        
        # HTML формат
        html = "<html><body><h1>Задачи</h1><table border='1'><tr><th>ID</th><th>Назва</th><th>Статус</th><th>Дата</th></tr>"
        for task in tasks:
            html += f"<tr><td>{task['id']}</td><td>{task['title']}</td><td>{task['status']}</td><td>{task['created_at']}</td></tr>"
        html += "</table></body></html>"
        return html, 200, {'Content-Type': 'text/html'}
        
    except Exception as e:
        logger.error(f"Помилка при отриманні задач: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/tasks', methods=['POST'])
def create_task():
    """Створити нову задачу"""
    try:
        data = request.get_json() if request.is_json else request.form
        title = data.get('title')
        
        if not title:
            return jsonify({"error": "Title is required"}), 400
        
        conn = get_db_connection()
        if conn is None:
            return jsonify({"error": "Database connection failed"}), 500
        
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO tasks (title, status, created_at) VALUES (%s, %s, NOW())",
            (title, 'pending')
        )
        conn.commit()
        task_id = cursor.lastrowid
        cursor.close()
        conn.close()
        
        if request.accept_mimetypes.best == 'application/json':
            return jsonify({"id": task_id, "title": title, "status": "pending"}), 201
        
        html = f"<html><body><h1>Задача створена</h1><p>ID: {task_id}</p><p>Назва: {title}</p></body></html>"
        return html, 201, {'Content-Type': 'text/html'}
        
    except Exception as e:
        logger.error(f"Помилка при створенні задачі: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/tasks/<int:task_id>/done', methods=['POST'])
def mark_task_done(task_id):
    """Позначити задачу як виконану"""
    try:
        conn = get_db_connection()
        if conn is None:
            return jsonify({"error": "Database connection failed"}), 500
        
        cursor = conn.cursor()
        cursor.execute("UPDATE tasks SET status = %s WHERE id = %s", ('done', task_id))
        conn.commit()
        
        if cursor.rowcount == 0:
            cursor.close()
            conn.close()
            return jsonify({"error": "Task not found"}), 404
        
        cursor.close()
        conn.close()
        
        if request.accept_mimetypes.best == 'application/json':
            return jsonify({"id": task_id, "status": "done"}), 200
        
        html = f"<html><body><h1>Задача оновлена</h1><p>ID: {task_id}</p><p>Статус: done</p></body></html>"
        return html, 200, {'Content-Type': 'text/html'}
        
    except Exception as e:
        logger.error(f"Помилка при оновленні задачі: {e}")
        return jsonify({"error": str(e)}), 500

def parse_arguments():
    """Парсинг аргументів командного рядка"""
    parser = argparse.ArgumentParser(description='Task Tracker Web Application')
    parser.add_argument('--host', type=str, default='127.0.0.1',
                        help='IP адреса для слухання (default: 127.0.0.1)')
    parser.add_argument('--port', type=int, default=8080,
                        help='Порт для слухання (default: 8080)')
    parser.add_argument('--db-host', type=str, required=True,
                        help='Хост бази даних')
    parser.add_argument('--db-user', type=str, required=True,
                        help='Користувач бази даних')
    parser.add_argument('--db-password', type=str, required=True,
                        help='Пароль бази даних')
    parser.add_argument('--db-name', type=str, required=True,
                        help='Назва бази даних')
    
    return parser.parse_args()

if __name__ == '__main__':
    args = parse_arguments()
    
    # Зберігаємо параметри БД
    db_host = args.db_host
    db_user = args.db_user
    db_password = args.db_password
    db_name = args.db_name
    
    logger.info(f"Запуск Task Tracker на {args.host}:{args.port}")
    logger.info(f"Підключення до БД: {db_host}/{db_name}")
    
    # Запуск Flask
    app.run(host=args.host, port=args.port, debug=False)
