# 📋 СВОДКА ПРОЕКТУ Task Tracker (N=10)

## 📌 Варіант Завдання

```
N = 10

V2 = (10 % 2) + 1 = 1  →  Конфіг через аргументи + MariaDB
V3 = (10 % 3) + 1 = 2  →  Task Tracker (сервіс управління задачами)
V5 = (10 % 5) + 1 = 1  →  Порт 8080
```

---

## 📦 ФАЙЛИ ПРОЕКТУ

### СТАРТОВІ ФАЙЛИ

| Файл | Розмір | Призначення |
|------|--------|-----------|
| **START_HERE.md** | 📄 |  Загальний огляд та навігація |
| **QUICKSTART.md** | 📄 |  запуск |
| **README.md** | 📄 | 📚 ПОВНА детальна документація |

### ПРОГРАМНІ ФАЙЛИ

| Файл | Тип | Розмір | Роль |
|------|-----|--------|------|
| **app.py** | Python | ~4 KB |  Flask веб-застосунок (Task Tracker API) |
| **migrate_db.py** | Python | ~2 KB |  Скрипт міграції MariaDB |
| **setup.sh** | Bash | ~8 KB | ⭐ Автоматизаційний скрипт розгортання |
| **requirements.txt** | Text | ~100 B |  Python залежності |
| **.gitignore** | Config | ~1 KB |  Git конфіг |

### 📚 ДОКУМЕНТАЦІЯ

| Файл | Розмір | Для кого |
|------|--------|----------|
| **docs_API.md** | ~8 KB |  Розробників - детальна API документація |
| **TESTING.md** | ~10 KB | Тестерів - інструкція тестування |

### 🧪 ТЕСТУВАННЯ

| Файл | Розмір | Використання |
|------|--------|-------------|
| **test_api.sh** | ~4 KB |  Автоматичне тестування API |

---

##  РЕКОМЕНДОВАНИЙ ПОРЯДОК ЧИТАННЯ

```
1. START_HERE.md 
       ↓
2. QUICKSTART.md 
       ↓
3. setup.sh запуск 
       ↓
4. test_api.sh або curl 
       ↓
5. README.md 
       ↓
6. docs_API.md 
       ↓
7. TESTING.md 
```

---

## 

### Крок 1️: Завантажити на ВМ

```bash
cd /tmp
git clone <YOUR-REPO> mywebapp  # або скопіювати файли
cd mywebapp
```

### Крок 2️: Запустити setup.sh

```bash
chmod +x setup.sh
sudo bash setup.sh
# Чекати 2-5 хвилин поки скрипт завершиться
```

### Крок 3️: Тестувати

```bash
curl http://localhost/health/alive
curl http://localhost/tasks
```



---

##  АРХІТЕКТУРА

```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │ HTTP :80
       ▼
┌──────────────────────────┐
│  NGINX Reverse Proxy     │
│  Listen: 0.0.0.0:80      │
└──────────┬───────────────┘
           │ :8080 (localhost)
           ▼
┌──────────────────────────┐
│  Flask App (Task Tracker)│
│  Listen: 127.0.0.1:8080  │
└──────────┬───────────────┘
           │ TCP :3306 (localhost)
           ▼
┌──────────────────────────┐
│  MariaDB Database        │
│  DB: mywebapp            │
└──────────────────────────┘
```

---

##  КОРИСТУВАЧІ СИСТЕМИ

| Користувач | Пароль | Права | Що робити |
|-----------|--------|-------|-----------|
| **student** | 12345678 | ✅ sudo admin | Розробник |
| **teacher** | 12345678 | ✅ sudo admin | Викладач/перевіркач |
| **operator** | 12345678 |  обмежені | Керування сервісом |
| **app** | (немає) |  системний | Запуск застосунку |

**Дозволи operator:**
- systemctl start/stop/restart/status mywebapp
- systemctl reload nginx

---

##  ПАПКИ ПРОЕКТУ

```
/opt/mywebapp/              ← Основна папка застосунку
  ├── app.py               ← Flask програма
  ├── migrate_db.py        ← Міграція БД
  └── requirements.txt     ← Python залежності

/var/log/nginx/             ← Логи веб-сервера
  └── mywebapp_access.log  ← Логи запитів

/etc/systemd/system/        ← Systemd конфіги
  └── mywebapp.service     ← Unit файл сервісу

/home/student/
  └── gradebook            ← Файл з номером варіанту (10)
```

---

## 🧪 ТЕСТУВАННЯ В ОДИН РЯДОК

```bash
# Мінімальний тест (проверить жив ли сервис)
curl http://localhost/health/alive

# Получить список задач (пуст спочатку)
curl http://localhost/tasks

# Создать задачу
curl -X POST -d "title=Test" http://localhost/tasks

# Автоматичне тестування (потребує jq)
chmod +x test_api.sh && ./test_api.sh
```

---

## 📚 КОМАНДИ РОЗРОБНИКА

```bash
# Перевірити статус сервісу
sudo systemctl status mywebapp

# Логи в реальному часі
sudo journalctl -u mywebapp -f

# Перезапустити сервіс
sudo systemctl restart mywebapp

# Перевірити, чи слухає порт
sudo ss -tlnp | grep 8080

# Входити в БД
mysql -u mywebapp -p -h 127.0.0.1 mywebapp

# Переглянути конфіг systemd
sudo cat /etc/systemd/system/mywebapp.service

# Переглянути конфіг nginx
sudo cat /etc/nginx/sites-available/mywebapp
```

---

## ❌ ТИПОВІ ПОМИЛКИ

| Помилка | Рішення |
|---------|---------|
| setup.sh: permission denied | `chmod +x setup.sh` |
| ERROR: not running as root | `sudo bash setup.sh` |
| Connection refused | `sudo systemctl start nginx` |
| 502 Bad Gateway | `sudo systemctl restart mywebapp` |
| Database connection failed | `sudo systemctl restart mariadb` |
| Port already in use |  

---

## РОЗВ'ЯЗАННЯ ПРОБЛЕМ

### Проблема: setup.sh завис

```bash
# Скасувати (Ctrl+C)
# Перевірити, який крок завис
sudo journalctl -n 100
```

### Проблема: API не відповідає

```bash
# 1. Перевірити Nginx
sudo systemctl status nginx
curl http://localhost/health/alive

# 2. Перевірити застосунок
sudo systemctl status mywebapp
sudo journalctl -u mywebapp -n 50

# 3. Перевірити БД
sudo systemctl status mariadb
mysql -u root -p -e "SELECT 1"
```

### Проблема: БД не доступна

```bash
# Перезапустити MariaDB
sudo systemctl restart mariadb

# Перевірити з'єднання
mysql -u mywebapp -p -h 127.0.0.1 mywebapp -e "SELECT 1"
```

---







**Версія**: 1.0  
**Дата**: 19.06.2026 
**Студент N**: 10  
Завдання: Лабораторна робота №1

