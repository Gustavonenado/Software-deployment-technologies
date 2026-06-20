#!/usr/bin/env python3
"""
Database Migration Script для Task Tracker
Створює необхідні таблиці та індекси
"""

import sys
import argparse
import logging
import mysql.connector
from mysql.connector import Error as MySQLError

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def migrate_database(host, user, password, database):
    """Виконати міграцію БД"""
    try:
        logger.info(f"Підключення до БД: {host}/{database}")
        conn = mysql.connector.connect(
            host=host,
            user=user,
            password=password,
            database=database
        )
        
        cursor = conn.cursor()
        
        # SQL для створення таблиці задач
        create_table_sql = """
        CREATE TABLE IF NOT EXISTS tasks (
            id INT AUTO_INCREMENT PRIMARY KEY,
            title VARCHAR(255) NOT NULL,
            status VARCHAR(50) NOT NULL DEFAULT 'pending',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_status (status),
            INDEX idx_created_at (created_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        """
        
        logger.info("Створення таблиці tasks...")
        cursor.execute(create_table_sql)
        conn.commit()
        logger.info("✓ Таблиця tasks успішно створена")
        
        # Перевірка структури таблиці
        cursor.execute("DESCRIBE tasks")
        columns = cursor.fetchall()
        logger.info(f"Колонки таблиці: {[col[0] for col in columns]}")
        
        cursor.close()
        conn.close()
        logger.info("✓ Міграція БД завершена успішно")
        return True
        
    except MySQLError as e:
        logger.error(f"✗ Помилка БД: {e}")
        return False
    except Exception as e:
        logger.error(f"✗ Непередбачена помилка: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(description='Database Migration Script')
    parser.add_argument('--db-host', type=str, required=True,
                        help='Хост бази даних')
    parser.add_argument('--db-user', type=str, required=True,
                        help='Користувач бази даних')
    parser.add_argument('--db-password', type=str, required=True,
                        help='Пароль бази даних')
    parser.add_argument('--db-name', type=str, required=True,
                        help='Назва бази даних')
    
    args = parser.parse_args()
    
    success = migrate_database(
        args.db_host,
        args.db_user,
        args.db_password,
        args.db_name
    )
    
    sys.exit(0 if success else 1)

if __name__ == '__main__':
    main()
