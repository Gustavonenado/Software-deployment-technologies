# Інструкція Тестування Task Tracker

Цей документ описує як тестувати розгорнуту систему Task Tracker на ВМ.

---

## 1️ Підготовка до Тестування

### 1.1 Перевірка доступу до ВМ

```bash
# SSH на ВМ 


### 1.2 Перевірка прав користувача

```bash
# Перевірити, хто ви
whoami

# Перевірити groups
groups

# Очікуємо: student sudo
```

### 1.3 Перевірка базових команд

```bash
# curl має бути встановлений
which curl

# jq для JSON parsing (опціонально)
which jq

# Якщо немає, встановити:
sudo apt-get update
sudo apt-get install -y curl jq
```

---

## 2️ Перевірка Системних Компонентів

### 2.1 Перевірка статусу Systemd сервісу

```bash
# Статус застосунку
sudo systemctl status mywebapp.service

# Очікуємо: active (running)

# Якщо не запущений, запустити:
sudo systemctl start mywebapp.service
```

### 2.2 Перевірка статусу Nginx

```bash
# Статус nginx
sudo systemctl status nginx

# Очікуємо: active (running)

# Якщо не запущений, запустити:
sudo systemctl start nginx
```

### 2.3 Перевірка статусу MariaDB

```bash
# Статус БД
sudo systemctl status mariadb

# Очікуємо: active (running)
```

### 2.4 Перевірка прослуховування портів

```bash
# Перевірити які порти слухають
sudo ss -tlnp

# Очікуємо:
# - 80 (nginx)
# - 8080 (застосунок)
# - 3306 (mariadb)

# Або альтернатива:
sudo netstat -tlnp | grep LISTEN
```

### 2.5 Перевірка процесів

```bash
# Перевірити процеси Python (застосунок)
ps aux | grep app.py

# Очікуємо щось на кшталт:
# app  1234  0.5  2.3 123456  45678 ?  Ssl 10:30  0:02 /usr/bin/python3 ...

# Перевірити Nginx процеси
ps aux | grep nginx

# Очікуємо: кілька процесів nginx (master + workers)
```

---

## 3️ Тестування Health Endpoints

### 3.1 Тест живого стану

```bash
# Перевірити, чи сервіс живий
curl http://localhost/health/alive

# Очікуємо: OK
# HTTP Status: 200
```

### 3.2 Тест готовності (Live/Ready)

```bash
# Перевірити, чи сервіс готовий до роботи
curl http://localhost/health/ready

# Очікуємо: OK
# HTTP Status: 200

# Якщо 500, то проблема з БД
# Перевірити логи:
sudo journalctl -u mywebapp -n 50
```

### 3.3 Детальна перевірка з заголовками

```bash
# Показати всі заголовки відповіді
curl -i http://localhost/health/alive

# Очікуємо:
# HTTP/1.1 200 OK
# Content-Type: text/plain
# OK
```

---

## 4️ Тестування Кореневого Ендпоінту

### 4.1 JSON формат

```bash
# Отримати JSON формат
curl -H "Accept: application/json" http://localhost/

# Або якщо немає заголовка (JSON за замовчуванням):
curl http://localhost/
```

**Очікуємо JSON відповідь:**
```json
{
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
}
```

### 4.2 HTML формат

```bash
# Отримати HTML формат
curl -H "Accept: text/html" http://localhost/

# Очікуємо HTML сторінку з описом API
```

### 4.3 Перевірка з jq (JSON pretty-print)

```bash
# Красиво вивести JSON
curl http://localhost/ | jq .

# Перевірити конкретне поле
curl http://localhost/ | jq '.endpoints.health'

# Очікуємо:
# [
#   "/health/alive",
#   "/health/ready"
# ]
```

---

## 5️ Тестування CRUD операцій

### 5.1 Отримати список задач (GET /tasks)

```bash
# JSON формат
curl http://localhost/tasks

# HTML формат
curl -H "Accept: text/html" http://localhost/tasks

# Очікуємо: порожній масив (на початку)
# []
```

### 5.2 Створити першу задачу (POST /tasks)

```bash
# Метод 1: JSON body
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"title":"Купити молоко"}' \
  http://localhost/tasks

# Метод 2: Form data
curl -X POST \
  -d "title=Купити молоко" \
  http://localhost/tasks

# Очікуємо:
# {
#   "id": 1,
#   "title": "Купити молоко",
#   "status": "pending"
# }
```

### 5.3 Отримати список (повинна з'явитися нова задача)

```bash
curl http://localhost/tasks

# Очікуємо:
# [
#   {
#     "id": 1,
#     "title": "Купити молоко",
#     "status": "pending",
#     "created_at": "2024-01-15T10:30:00"
#   }
# ]
```

### 5.4 Створити ще кілька задач

```bash
# Задача 2
curl -X POST -d "title=Написати звіт" http://localhost/tasks

# Задача 3
curl -X POST -d "title=Зробити зустріч" http://localhost/tasks

# Задача 4
curl -X POST -d "title=Прочитати статтю" http://localhost/tasks

# Перевірити список
curl http://localhost/tasks | jq '.[] | {id, title, status}'
```

### 5.5 Позначити задачу як виконану (POST /tasks/<id>/done)

```bash
# Позначити першу задачу (id=1) як виконану
curl -X POST http://localhost/tasks/1/done

# Очікуємо:
# {
#   "id": 1,
#   "status": "done"
# }

# Перевірити список
curl http://localhost/tasks | jq '.[] | {id, title, status}'

# Очікуємо: першу задачу тепер status="done"
```

### 5.6 Тестування помилок

```bash
# Спробувати позначити неіснуючу задачу
curl -X POST http://localhost/tasks/999/done

# Очікуємо HTTP 404:
# {
#   "error": "Task not found"
# }

# Спробувати створити задачу без назви
curl -X POST -d "" http://localhost/tasks

# Очікуємо HTTP 400:
# {
#   "error": "Title is required"
# }
```

---

## 6️ Тестування Різних Accept Headers

### 6.1 HTML табличний формат

```bash
# GET /tasks в HTML
curl -H "Accept: text/html" http://localhost/tasks

# Очікуємо HTML таблицю з розділами:
# <table border='1'>
#   <tr><th>ID</th><th>Назва</th><th>Статус</th><th>Дата</th></tr>
#   <tr><td>1</td><td>...</td><td>...</td><td>...</td></tr>
# </table>
```

### 6.2 Створення в HTML

```bash
# POST /tasks з HTML формою
curl -X POST \
  -H "Accept: text/html" \
  -d "title=Нова задача" \
  http://localhost/tasks

# Очікуємо HTML повідомлення про успіх
```

### 6.3 JSON Content-Type

```bash
# POST з JSON
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"title":"JSON задача"}' \
  http://localhost/tasks

# Очікуємо JSON відповідь
```

---

## 7️⃣ Тестування Логів

### 7.1 Логи застосунку

```bash
# Реальний час логи (останні 50 рядків)
sudo journalctl -u mywebapp -f

# За останні N рядків
sudo journalctl -u mywebapp -n 100

# За певний час
sudo journalctl -u mywebapp --since "10 minutes ago"
```

### 7.2 Логи Nginx (access)

```bash
# Логи доступу
sudo tail -50 /var/log/nginx/mywebapp_access.log

# Реальний час
sudo tail -f /var/log/nginx/mywebapp_access.log
```

### 7.3 Логи Nginx (error)

```bash
# Логи помилок
sudo tail -50 /var/log/nginx/mywebapp_error.log
```

### 7.4 Логи MariaDB

```bash
# Системні логи БД
sudo journalctl -u mariadb -n 50
```

---

## 8️ Тестування БД

### 8.1 Входити в MySQL/MariaDB

```bash
# Від користувача mywebapp
mysql -u mywebapp -p -h 127.0.0.1 mywebapp

# При запиті на пароль, введіть пароль від setup.sh
# (або переглянути в /etc/systemd/system/mywebapp.service)
```

### 8.2 SQL запити

```sql
-- Перегляд таблиці
SELECT * FROM tasks;

-- Кількість задач
SELECT COUNT(*) FROM tasks;

-- Задачі за статусом
SELECT * FROM tasks WHERE status='done';

-- Структура таблиці
DESCRIBE tasks;

-- Показати індекси
SHOW INDEXES FROM tasks;
```

### 8.3 Вихід з MySQL

```sql
EXIT;
-- або
QUIT;
```

---

## 9️ Тестування Користувачів та Прав

### 9.1 Перевірка користувачів

```bash
# Перелік користувачів (потрібні права root)
sudo cat /etc/passwd | grep -E "student|teacher|operator|app"

# Очікуємо:
# student:x:1000:1000:...
# teacher:x:1001:1001:...
# operator:x:1002:1002:...
# app:x:100:101:...
```

### 9.2 Тестування оператора

```bash
# Переключитися на operator
sudo su - operator

# Пароль: 12345678

# Перевірити, які команди может виконати
sudo -l

# Очікуємо список дозволених команд для systemctl та nginx reload
```

### 9.3 Тестування дозволених команд оператора

```bash
# (Як operator користувач)

# Запустити застосунок
sudo systemctl start mywebapp

# Зупинити
sudo systemctl stop mywebapp

# Перезапустити
sudo systemctl restart mywebapp

# Статус
sudo systemctl status mywebapp

# Reload nginx
sudo systemctl reload nginx

# Спробувати щось, що НЕ дозволено 
sudo systemctl restart mariadb
# Очікуємо: Sorry, user operator may not run ...
```

### 9.4 Файл gradebook

```bash
# Перевірити наявність файлу
cat /home/student/gradebook

# Очікуємо: 10
```

---

## Комплексне Тестування (Сценарій)

### Скрипт для повного тестування

```bash
#!/bin/bash

set -e

API="http://localhost"
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

test_endpoint() {
  local method=$1
  local endpoint=$2
  local data=$3
  local expected_code=$4
  
  if [ -z "$data" ]; then
    response=$(curl -s -w "\n%{http_code}" -X $method "$API$endpoint")
  else
    response=$(curl -s -w "\n%{http_code}" -X $method -d "$data" "$API$endpoint")
  fi
  
  http_code=$(echo "$response" | tail -n1)
  body=$(echo "$response" | sed '$d')
  
  if [ "$http_code" = "$expected_code" ]; then
    echo -e "${GREEN}✓${NC} $method $endpoint ($http_code)"
  else
    echo -e "${RED}✗${NC} $method $endpoint (очікували $expected_code, отримали $http_code)"
    return 1
  fi
}

echo "Тестування Task Tracker..."
echo ""

# Перевірка здоров'я
test_endpoint "GET" "/health/alive" "" "200"
test_endpoint "GET" "/health/ready" "" "200"

# Перевірка API
test_endpoint "GET" "/" "" "200"
test_endpoint "GET" "/tasks" "" "200"

# Тестування CRUD
task_response=$(curl -s -X POST -d "title=Test task" $API/tasks)
task_id=$(echo $task_response | grep -o '"id":[0-9]*' | head -1 | grep -o '[0-9]*')

echo "Създана задача ID: $task_id"

# Позначити задачу
test_endpoint "POST" "/tasks/$task_id/done" "" "200"

# Помилка - неіснуюча задача
test_endpoint "POST" "/tasks/9999/done" "" "404"

echo ""
echo -e "${GREEN}✓ Усі тести пройдені!${NC}"
```

**Запуск скрипту:**
```bash
# Зберігти як test.sh
chmod +x test.sh
./test.sh
```

---

## Розв'язання Проблем під час Тестування

### Проблема: Connection refused на http://localhost

```bash
# Перевірити, чи nginx запущений
sudo systemctl status nginx

# Запустити якщо необхідно
sudo systemctl start nginx

# Перевірити логи
sudo journalctl -u nginx -n 20
```

### Проблема: 502 Bad Gateway

```bash
# Перевірити, чи застосунок запущений
sudo systemctl status mywebapp

# Запустити
sudo systemctl start mywebapp

# Перевірити логи застосунку
sudo journalctl -u mywebapp -n 50
```

### Проблема: Database connection failed

```bash
# Перевірити БД
sudo systemctl status mariadb

# Запустити БД
sudo systemctl start mariadb

# Перевірити, чи можна підключитися
mysql -u mywebapp -p -h 127.0.0.1 mywebapp -e "SELECT 1"
```

### Проблема: /health/ready повертає 500

```bash
# БД недоступна
# Перевірити:
mysql -u mywebapp -p -h 127.0.0.1 mywebapp

# Перевірити credentials в systemd файлі:
sudo cat /etc/systemd/system/mywebapp.service | grep ExecStart
```


---

**Дата**: 19.06.2026
**Версія**: 1.0

