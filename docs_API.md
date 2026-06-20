# Task Tracker API Документація

## Огляд

Task Tracker API надає RESTful інтерфейс для управління задачами. Сервіс підтримує як JSON, так і HTML формати відповідей, залежно від заголовка `Accept`.

---

## Базові Інформації

- **Базова адреса:** `http://localhost/` (через Nginx)
- **Внутрішня адреса:** `http://127.0.0.1:8080/` (прямо до застосунку)
- **Версія API:** 1.0
- **Формати:** JSON, HTML

---

## Заголовки Запитів

### Accept 

```
Accept: application/json    
Accept: text/html           
```

Якщо заголовок не вказаний, за замовчуванням повертається JSON.

---

## Ендпоінти

### 1. Кореневий Ендпоінт

**GET** `/`


#### Запит:
```bash
curl http://localhost/
```

#### Відповідь (JSON):
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

#### Відповідь (HTML):
```html
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
        <li><strong>POST /tasks</strong> - Створити нову задачу</li>
        <li><strong>POST /tasks/&lt;id&gt;/done</strong> - Позначити задачу як виконану</li>
    </ul>
</body>
</html>
```

#### HTTP Статус:
- `200 OK` — успішно

---

### 2. Health Check - Alive

**GET** `/health/alive`

Простий тест живого стану сервісу.

#### Запит:
```bash
curl http://localhost/health/alive
```

#### Відповідь:
```
OK
```

#### HTTP Статус:
- `200 OK` — сервіс живий

#### Використання:
- Load balancer health check
- Моніторинг
- Системи оркестрування

---

### 3. Health Check - Ready

**GET** `/health/ready`

Перевірка готовності сервісу. 
#### Запит:
```bash
curl http://localhost/health/ready
```

#### Успішна Відповідь:
```
OK
```

#### Помилкова Відповідь (JSON):
```json
{
  "error": "Database connection failed"
}
```

#### HTTP Статус:
- `200 OK` — сервіс готовий
- `500 Internal Server Error` — проблема з БД або іншою залежністю

#### Використання:
- Kubernetes readiness probe
- Deployment automation
- CI/CD pipeline checks

---

### 4. Отримати Список Задач

**GET** `/tasks`

Отримати список всіх задач з їх базовими деталями.

#### Запит (JSON):
```bash
curl -H "Accept: application/json" http://localhost/tasks
```

#### Запит (HTML):
```bash
curl -H "Accept: text/html" http://localhost/tasks
```

#### Відповідь (JSON):
```json
[
  {
    "id": 1,
    "title": "Купити молоко",
    "status": "pending",
    "created_at": "2024-01-15T10:30:00"
  },
  {
    "id": 2,
    "title": "Написати звіт",
    "status": "done",
    "created_at": "2024-01-14T14:45:00"
  }
]
```

#### Відповідь (HTML):
```html
<html>
<body>
  <h1>Задачи</h1>
  <table border='1'>
    <tr>
      <th>ID</th>
      <th>Назва</th>
      <th>Статус</th>
      <th>Дата</th>
    </tr>
    <tr>
      <td>1</td>
      <td>Купити молоко</td>
      <td>pending</td>
      <td>2024-01-15T10:30:00</td>
    </tr>
    <tr>
      <td>2</td>
      <td>Написати звіт</td>
      <td>done</td>
      <td>2024-01-14T14:45:00</td>
    </tr>
  </table>
</body>
</html>
```

#### Параметри Запиту:
Немає

#### HTTP Статус:
- `200 OK` — успішно
- `500 Internal Server Error` — помилка БД

---

### 5. Створити Нову Задачу

**POST** `/tasks`

Створити нову задачу зі статусом `pending`.

#### Запит (JSON):
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"title":"Купити хліб"}' \
  http://localhost/tasks
```

#### Запит (Form Data):
```bash
curl -X POST \
  -H "Accept: application/json" \
  -d "title=Купити хліб" \
  http://localhost/tasks
```

#### Запит (HTML):
```bash
curl -X POST \
  -d "title=Купити хліб" \
  -H "Accept: text/html" \
  http://localhost/tasks
```

#### Параметри:
- `title` (обов'язковий) — текст задачі, рядок до 255 символів

#### Відповідь (JSON):
```json
{
  "id": 3,
  "title": "Купити хліб",
  "status": "pending"
}
```

#### Відповідь (HTML):
```html
<html>
<body>
  <h1>Задача створена</h1>
  <p>ID: 3</p>
  <p>Назва: Купити хліб</p>
</body>
</html>
```

#### HTTP Статус:
- `201 Created` — задача успішно створена
- `400 Bad Request` — відсутній параметр `title`
- `500 Internal Server Error` — помилка БД

---

### 6. Позначити Задачу як Виконану

**POST** `/tasks/<id>/done`

Змінити статус задачі з `pending` на `done`.

#### Запит (JSON):
```bash
curl -X POST \
  -H "Accept: application/json" \
  http://localhost/tasks/1/done
```

#### Запит (HTML):
```bash
curl -X POST \
  -H "Accept: text/html" \
  http://localhost/tasks/1/done
```

#### Параметри URL:
- `<id>` (обов'язковий) — ID задачі, ціле число

#### Відповідь (JSON):
```json
{
  "id": 1,
  "status": "done"
}
```

#### Відповідь (HTML):
```html
<html>
<body>
  <h1>Задача оновлена</h1>
  <p>ID: 1</p>
  <p>Статус: done</p>
</body>
</html>
```

#### HTTP Статус:
- `200 OK` — статус успішно змінено
- `404 Not Found` — задача з вказаним ID не знайдена
- `500 Internal Server Error` — помилка БД

---

## Об'єкт Задачі

```json
{
  "id": 1,
  "title": "Купити молоко",
  "status": "pending",
  "created_at": "2024-01-15T10:30:00"
}
```

### Поля:

| Поле | Тип | Опис |
|------|-----|------|
| `id` | integer | Унікальний ідентифікатор (автогенерований) |
| `title` | string | Текст задачі (1-255 символів) |
| `status` | string | Статус: `pending` або `done` |
| `created_at` | string (ISO 8601) | Дата/час створення в форматі ISO 8601 |

---

## Коди Помилок

| Код | Опис |
|-----|------|
| 200 | OK — запит успішно виконаний |
| 201 | Created — ресурс успішно створений |
| 400 | Bad Request — невірні параметри запиту |
| 404 | Not Found — ресурс не знайдений |
| 500 | Internal Server Error — помилка сервера |

### Приклад помилки (JSON):
```json
{
  "error": "Database connection failed"
}
```

---

## Приклади Використання

### Сценарій: Управління покупками

```bash
#!/bin/bash

API="http://localhost"

echo "1. Отримати список задач"
curl -H "Accept: application/json" $API/tasks
echo -e "\n"

echo "2. Додати нову покупку"
RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"title":"Молоко"}' \
  $API/tasks)
echo $RESPONSE
TASK_ID=$(echo $RESPONSE | grep -o '"id":[0-9]*' | head -1 | grep -o '[0-9]*')
echo -e "\n"

echo "3. Додати ще одну покупку"
curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '{"title":"Хліб"}' \
  $API/tasks | jq .
echo -e "\n"

echo "4. Переглянути всі покупки"
curl -s -H "Accept: application/json" $API/tasks | jq .
echo -e "\n"

echo "5. Позначити першу покупку як готову"
curl -s -X POST \
  -H "Accept: application/json" \
  $API/tasks/$TASK_ID/done | jq .
echo -e "\n"

echo "6. Остаточний список"
curl -s -H "Accept: application/json" $API/tasks | jq .
```

### Сценарій: Моніторинг здоров'я

```bash
#!/bin/bash

API="http://localhost"

# Перевірка живого стану
echo "Перевірка живого стану..."
if curl -s $API/health/alive | grep -q "OK"; then
  echo "✓ Сервіс живий"
else
  echo "✗ Сервіс не відповідає"
  exit 1
fi

# Перевірка готовності
echo "Перевірка готовності..."
if curl -s $API/health/ready | grep -q "OK"; then
  echo "✓ Сервіс готовий"
else
  echo "✗ Сервіс не готовий (проблема з БД?)"
  exit 1
fi

echo "✓ Всі тести пройдені"
```

---


## Версійність API

Поточна версія: **1.0**

---


---

