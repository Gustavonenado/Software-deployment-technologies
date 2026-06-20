#  DOCKER COMPOSE - TASK TRACKER

Це інструкція для запуску Task Tracker застосунку через Docker Compose.

---

## Передумови

- Docker встановлений та запущений
- Docker Compose встановлений (версія 3.9+)
- 2+ GB вільної памяті
- Порти 80 та 3306 вільні

---

## СТАРТ

### Крок 1: Запустити всі сервіси

```bash
# В папці з docker-compose.yml
docker-compose up -d

# Логування в реальному часі
docker-compose logs -f

# Для конкретного сервісу
docker-compose logs -f web
docker-compose logs -f mariadb
docker-compose logs -f nginx
```

### Крок 2: Перевірити статус

```bash
# Статус всіх контейнерів
docker-compose ps

# Очікуємо: всі сервіси "healthy" або "running"
```

### Крок 3: Тестувати API

```bash
# Health check
curl http://localhost/health/alive

# Отримати список задач
curl http://localhost/tasks

# Створити задачу
curl -X POST -d "title=Test task" http://localhost/tasks

# JSON формат
curl -H "Accept: application/json" http://localhost/tasks
```

### Крок 4: Зупинити сервіси

```bash
# Зупинити без видалення контейнерів
docker-compose stop

# Видалити контейнери (дані БД зберігаються!)
docker-compose down

# Видалити все включаючи томи
docker-compose down -v
```

---

##  СТРУКТУРА ФАЙЛІВ

```
mywebapp/
├── docker-compose.yml          ← Основний файл
├── Dockerfile                   ← Конфіг для app контейнера
├── nginx.conf                   ← Конфіг для nginx
├── app.py                       ← Flask застосунок
├── migrate_db.py                ← Міграція БД
├── requirements.txt             ← Python залежности
│
├── .docker/                     ← Дані (автоматично створюється)
│   └── mariadb/                 ← Дані БД (зберігаються на диску)
│
└── logs/                        ← Логи (автоматично створюється)
    ├── app/
    └── nginx/
```

---

##  КОНФІГУРАЦІЯ

### Змінні оточення

Можна встановити в `.env` файлі:

```bash
# .env
MARIADB_ROOT_PASSWORD=root_password_123
MARIADB_DATABASE=mywebapp
MARIADB_USER=mywebapp
MARIADB_PASSWORD=mywebapp_pass

APP_HOST=0.0.0.0
APP_PORT=8080

DB_HOST=mariadb
DB_NAME=mywebapp
DB_USER=mywebapp
DB_PASSWORD=mywebapp_pass

MARIADB_DATA_PATH=./.docker/mariadb
```

Потім запустити:
```bash
docker-compose up -d
```

### Зміна портів

Відредагувати `docker-compose.yml`:

```yaml
services:
  nginx:
    ports:
      - "8000:80"  # Змінити з 80 на 8000
```

Тоді доступ буде на `http://localhost:8000`

---

## 🔍 ДІАГНОСТИКА

### Перевірити логи

```bash
# Весь логи
docker-compose logs

# Останні N рядків
docker-compose logs --tail=50

# Логи конкретного сервісу
docker-compose logs web
docker-compose logs mariadb
docker-compose logs nginx

# В реальному часі
docker-compose logs -f
```

### Перевірити мережу

```bash
# Список мереж
docker network ls

# Деталі мережі
docker network inspect task-tracker-network
```

### Перевірити томи

```bash
# Список томів
docker volume ls | grep task-tracker

# Деталі тому
docker volume inspect Software-deployment-technologies_mariadb_data

# Переглядити дані (якщо на Linux)
ls -la /var/lib/docker/volumes/.../_data/
```

### Входити в контейнер

```bash
# Bash в web контейнері
docker-compose exec web bash

# Bash в mariadb контейнері
docker-compose exec mariadb bash

# SQL консоль
docker-compose exec mariadb mysql -u mywebapp -pmywebapp_pass mywebapp
```

---

# РОЗВ'ЯЗАННЯ ПРОБЛЕМ

### Проблема: "Port 80 is already in use"

```bash
# Знайти який процес займає порт
sudo lsof -i :80

# Зупинити старі контейнери
docker-compose down

# Або змінити порт в docker-compose.yml
ports:
  - "8080:80"
```

### Проблема: "Connection refused" при з'єднанні з БД

```bash
# Перевірити що mariadb здоровий
docker-compose logs mariadb

# Перевірити health check
docker-compose ps
# Ждемо доки mariadb буде "healthy"

# Чекати 30 секунд для ініціалізації БД
sleep 30
curl http://localhost/tasks
```

### Проблема: "No such file or directory" для nginx.conf

```bash
# Переконатися що nginx.conf в тій же папці що docker-compose.yml
ls -la nginx.conf

# Або вказати повний шлях в docker-compose.yml
volumes:
  - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
  - /full/path/nginx.conf:/etc/nginx/conf.d/default.conf:ro
```

### Проблема: БД не ініціалізужться

```bash
# Видалити дані
docker-compose down -v
rm -rf ./.docker/mariadb

# Запустити знову
docker-compose up -d

# Чекати логи
docker-compose logs -f mariadb
```


### Переглядити використання

```bash
# Статистика контейнерів
docker stats

# За конкретним контейнером
docker stats task-tracker-app
```

### Оптимізація

```bash
# Очистити невикористані образи
docker image prune -a

# Очистити невикористані томи
docker volume prune

# Очистити невикористані мережи
docker network prune
```

---

## БЕЗПЕКА

### Змінити паролі

1. Відредагувати `docker-compose.yml`
2. Змінити `MYSQL_ROOT_PASSWORD`, `MYSQL_PASSWORD`
3. Видалити старі дані: `docker-compose down -v`
4. Запустити знову: `docker-compose up -d`

### Ліміти ресурсів

Додати в `docker-compose.yml`:

```yaml
services:
  web:
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
```

---

## МАСШТАБУВАННЯ

### Збільшити кількість web контейнерів

```bash
# Запустити 3 копії web сервісу
docker-compose up -d --scale web=3
```

**Примітка:** Потребує облікового балансування через nginx!

---

##  ОНОВЛЕННЯ КОДУ

### Якщо змінили app.py

```bash
# Перебудувати образ
docker-compose build web

# Перезапустити web контейнер
docker-compose up -d web

# Або одна команда
docker-compose up -d --build web
```

### Якщо змінили nginx.conf

```bash
# Просто перезагрузити nginx (без перебудови)
docker-compose exec nginx nginx -s reload

# Або перезапустити
docker-compose restart nginx
```

---

## РЕЗЕРВНА КОПІЯ БД

### Експортувати дані

```bash
# SQL дамп
docker-compose exec mariadb mysqldump -u mywebapp -pmywebapp_pass mywebapp > backup.sql

# Архів томів
docker run --rm -v task-tracker-mariadb_data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/mariadb-backup.tar.gz -C /data .
```

### Відновити дані

```bash
# З SQL файлу
docker-compose exec -T mariadb mysql -u mywebapp -pmywebapp_pass mywebapp < backup.sql

# З архіву томів
docker volume rm task-tracker-mariadb_data
docker volume create task-tracker-mariadb_data
docker run --rm -v task-tracker-mariadb_data:/data \
  -v $(pwd):/backup \
  alpine tar xzf /backup/mariadb-backup.tar.gz -C /data
```

---

##  КОРИСНІ КОМАНДИ

```bash
# Перевірити синтаксис docker-compose.yml
docker-compose config

# Валідація
docker-compose validate

# Запустити одноразову команду
docker-compose run web python migrate_db.py ...

# Видалити контейнер та його дані
docker-compose rm -f web

# Переглядити змінні оточення у контейнері
docker-compose exec web env
```

---

##  ПРИКЛАДИ

### Запустити та отримати логи

```bash
docker-compose up -d && docker-compose logs -f
```

### Запустити, протестувати, зупинити

```bash
docker-compose up -d
sleep 10  # Чекати ініціалізації
curl http://localhost/health/alive
curl -X POST -d "title=Test" http://localhost/tasks
docker-compose down
```

### Повна очистка та перезапуск

```bash
docker-compose down -v
docker image rm task-tracker:latest
docker-compose up -d --build
```

---



**Версія**: 1.0  
**Дата**: 19.06.2026  


