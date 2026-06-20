# Task Tracker Web Application

## 📋 Варіант Завдання

**N = 10**

| Параметр | Значення | Розрахунок |
|----------|----------|-----------|
| V2 | 1 | (10 % 2) + 1 = 1 |
| V3 | 2 | (10 % 3) + 1 = 2 |
| V5 | 1 | (10 % 5) + 1 = 1 |

### Визначені параметри:

- **V2 = 1**: Конфігурація через **аргументи командного рядка**
- **База даних**: **MariaDB** (відповідно V2)
- **V3 = 2**: **Task Tracker** - сервіс для відстеження задач
- **V5 = 1**: Порт **8080**

---

## 📖 Опис Застосунку

**Task Tracker** — простий веб-сервіс для управління та відстеження задач.

### Об'єкт задачі:
- `id` — унікальний ідентифікатор
- `title` — назва задачі
- `status` — статус (pending, done)
- `created_at` — дата/час створення

### API Ендпоінти:

| Метод | Ендпоінт | Опис |
|-------|----------|------|
| GET | `/` | Кореневий ендпоінт (список всіх ендпоінтів) |
| GET | `/health/alive` | Перевірка живого стану |
| GET | `/health/ready` | Перевірка готовності (підключення до БД) |
| GET | `/tasks` | Отримати список всіх задач |
| POST | `/tasks` | Створити нову задачу |
| POST | `/tasks/<id>/done` | Позначити задачу як виконану |

### Accept Headers:

- `Accept: application/json` → JSON відповідь
- `Accept: text/html` → HTML сторінка
- Без заголовка → за замовчуванням JSON

---

## 🏗️ Архітектура Системи

```
┌─────────┐
│ Client  │
└────┬────┘
     │ :80
     ▼
┌─────────────────────┐
│  nginx (reverse     │
│  proxy)             │
│  0.0.0.0:80         │
└────────┬────────────┘
         │ :8080 (localhost)
         ▼
┌──────────────────────────┐
│  Flask Application       │
│  Task Tracker            │
│  127.0.0.1:8080          │
└────────┬─────────────────┘
         │ TCP :3306 (localhost)
         ▼
┌──────────────────────────┐
│  MariaDB                 │
│  Database: mywebapp      │
│  127.0.0.1:3306          │
└──────────────────────────┘
```

### Мережеві обмеження:
- **nginx**: `0.0.0.0:80` — публічний доступ
- **Застосунок**: `127.0.0.1:8080` — локальне підключення тільки
- **MariaDB**: `127.0.0.1:3306` — локальне підключення тільки

---

## Розроблення та Тестування

### Системні вимоги:
- Linux (Ubuntu 20.04+ або CentOS 8+)
- Python 3.8+
- pip3
- MariaDB/MySQL
- Nginx
- Git

### Встановлення локально:

```bash
# 1. Клонування репозиторію
git clone <repo-url>
cd mywebapp

# 2. Встановлення залежностей
pip3 install -r requirements.txt

# 3. Запуск застосунку з аргументами (для тестування)
python3 app.py \
    --host 127.0.0.1 \
    --port 8080 \
    --db-host 127.0.0.1 \
    --db-user root \
    --db-password password \
    --db-name mywebapp_dev

# 4. Тестування
curl http://127.0.0.1:8080/
curl http://127.0.0.1:8080/tasks
```

---

## Розгортання

### Вимоги до Віртуальної Машини:

**Базовий образ:**
- Ubuntu Server 20.04 LTS (офіційний образ)
- Або CentOS 8 Stream (офіційний образ)

**Ресурси:**
- CPU: 2 ядра
- RAM: 2 GB
- Disk: 20 GB (SSD рекомендується)
- Network: 1 з'єднання (NAT або Bridge)

**Подальша конфігурація ОС:**
- SSH включений
- sudo доступний
- Мережа налаштована

### Крок 1: Підготовка ВМ

```bash
# На хост-системі (VM VirtualBox/KVM/AWS)
# Завантажити офіційний образ (наприклад Ubuntu 20.04 LTS)
# https://ubuntu.com/download/server

# Встановити ОС на ВМ, запам'ятати:
# - Користувача та пароль для SSH доступу
# - IP адресу ВМ
```

### Крок 2: Завантаження проекту та запуск Automation

```bash
# SSH на ВМ
ssh user@vm-ip-address

# Завантажити файли проекту (або клонувати Git репо)
cd /tmp
git clone <repo-url> mywebapp
cd mywebapp

# Дати права виконання на setup скрипт
chmod +x setup.sh

# Запустити setup скрипт з правами root
sudo bash setup.sh
```

### Крок 3: Перевірка розгортання

```bash
# Перевірити статус сервісу
systemctl status mywebapp

# Перевірити nginx
systemctl status nginx

# Логи застосунку
journalctl -u mywebapp -f

# Логи nginx
tail -f /var/log/nginx/mywebapp_access.log
```

---

## 🔑 Користувачі Системи

| Користувач | Пароль | Права | Призначення |
|-----------|--------|-------|-----------|
| student | 12345678 | sudo (admin) | Розробник |
| teacher | 12345678 | sudo (admin) | Перевіркач |
| operator | 12345678 | обмежені (see below) | Оператор сервісу |
| app | — | мінімальні | Системний користувач для застосунку |
| root | — | заблокований | — |

### Права operator користувача (sudo):
```
- systemctl start mywebapp
- systemctl stop mywebapp
- systemctl restart mywebapp
- systemctl status mywebapp
- systemctl reload nginx
```

---

## 🧪 Тестування Розгорнутої Системи

### 1. Базові тести здоров'я:

```bash
# Тест: Живий статус
curl http://localhost/health/alive
# Очікуємо: OK (200)

# Тест: Готовність (підключення до БД)
curl http://localhost/health/ready
# Очікуємо: OK (200)
```

### 2. Тести API (JSON формат):

```bash
# Отримати список задач (порожній спочатку)
curl -H "Accept: application/json" \
  http://localhost/tasks

# Створити нову задачу
curl -X POST -H "Content-Type: application/json" \
  -d '{"title":"Нова задача"}' \
  http://localhost/tasks

# Отримати список знову (повинна з'явитися нова задача)
curl -H "Accept: application/json" \
  http://localhost/tasks

# Позначити задачу 1 як виконану
curl -X POST http://localhost/tasks/1/done

# Перевірити статус
curl -H "Accept: application/json" \
  http://localhost/tasks
```

### 3. Тести HTML формату:

```bash
# Отримати кореневу сторінку (HTML)
curl http://localhost/

# Отримати список задач (HTML таблиця)
curl -H "Accept: text/html" \
  http://localhost/tasks

# Створити задачу (HTML)
curl -X POST \
  -d "title=Тестова задача" \
  http://localhost/tasks
```

### 4. Перевірка Nginx логів:

```bash
# Переглянути логи доступу
tail -50 /var/log/nginx/mywebapp_access.log

# Переглянути логи помилок
tail -50 /var/log/nginx/mywebapp_error.log
```

### 5. Перевірка Застосунку:

```bash
# Статус сервісу
systemctl status mywebapp

# Реальний час логи
journalctl -u mywebapp -f

# Перевірити процес
ps aux | grep app.py
```

### 6. Перевірка БД:

```bash
# Входити в MariaDB
mysql -u mywebapp -p -h 127.0.0.1 mywebapp
# (пароль буде у файлі /etc/mywebapp/config або у 
#  systemd unit файлі, або в setup.sh логах)

# SQL запити
SELECT * FROM tasks;
SELECT COUNT(*) FROM tasks;
DESCRIBE tasks;
```

### 7. Тест з користувачем operator:

```bash
# Увійти як operator
su - operator

# Спробувати перезавантажити nginx (дозволено)
sudo systemctl reload nginx

# Спробувати переглянути статус (дозволено)
sudo systemctl status mywebapp

# Спробувати виконати інше (має бути запрещено)
sudo ls /root
```

---

## Запити

### JSON API:

```bash
# GET все задачі
curl -H "Accept: application/json" \
  http://localhost/tasks

# Відповідь:
[
  {
    "id": 1,
    "title": "Тестова задача",
    "status": "pending",
    "created_at": "2024-01-15T10:30:00"
  }
]

# POST нову задачу
curl -X POST -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{"title": "Нова задача"}' \
  http://localhost/tasks

# Відповідь:
{
  "id": 2,
  "title": "Нова задача",
  "status": "pending"
}

# POST позначити готовою
curl -X POST -H "Accept: application/json" \
  http://localhost/tasks/1/done

# Відповідь:
{
  "id": 1,
  "status": "done"
}
```

### HTML API:

```html
<!-- GET /tasks повертає таблицю -->
<table border='1'>
  <tr>
    <th>ID</th>
    <th>Назва</th>
    <th>Статус</th>
    <th>Дата</th>
  </tr>
  <tr>
    <td>1</td>
    <td>Тестова задача</td>
    <td>done</td>
    <td>2024-01-15T10:30:00</td>
  </tr>
</table>
```

---

## 📂 Структура Проекту

```
mywebapp/
├── app.py                    # Основна Flask програма
├── migrate_db.py            # Скрипт міграції БД
├── setup.sh                 # Основний automation скрипт
├── requirements.txt         # Python залежності
├── README.md                # Це файл
├── docs/                    # Додаткова документація
│   └── API.md              # Детальна документація API
└── .gitignore              # Git ignore файл
```

---

## Конфігурація

### Застосунок:
Конфігурація задається **аргументами командного рядка** при запуску:

```bash
python3 app.py \
  --host 127.0.0.1 \
  --port 8080 \
  --db-host 127.0.0.1 \
  --db-user mywebapp \
  --db-password password \
  --db-name mywebapp
```

### Systemd:
Конфігурація в файлі `/etc/systemd/system/mywebapp.service`

### Nginx:
Конфігурація в файлі `/etc/nginx/sites-available/mywebapp`

---

## Розв'язання Проблем

### Застосунок не запускається:

```bash
# Перевірити логи
journalctl -u mywebapp -n 50 -e

# Перевірити, чи БД доступна
mysql -h 127.0.0.1 -u mywebapp -p mywebapp -e "SELECT 1"

# Перевірити, що порт не зайнятий
netstat -tlnp | grep 8080
```

### Nginx повертає 502 Bad Gateway:

```bash
# Перевірити, що застосунок працює
systemctl status mywebapp

# Перевірити, що порт правильний
ss -tlnp | grep 8080

# Перевірити nginx конфіг
nginx -t
```

### Проблеми з БД:

```bash
# Перевірити статус MariaDB
systemctl status mariadb

# Перевірити логи
journalctl -u mariadb -n 50

# Перевірити користувача
mysql -u root -p -e "SHOW GRANTS FOR 'mywebapp'@'localhost';"
```


## Файл Градуса

Файл `/home/student/gradebook` містить:
```
10
```

Це число використовується для розрахунку варіанту завдання.

---




**Дата розгортання:** 19.06.2026
**Версія:** 1.0

