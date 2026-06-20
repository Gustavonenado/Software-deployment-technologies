# 📦 ЛАБОРАТОРНА РОБОТА №2 - КОНТЕЙНЕРИЗАЦІЯ

**Версія:** 1.0  
**Дата:** 2024  
**Студент:** (ваше ім'я та прізвище)  
**Варіант:** N=10

---

##  СТРУКТУРА РОБОТИ

```
Software-deployment-technologies/
├──РОБОТА №1: Task Tracker (вже готова)
│   ├── app.py
│   ├── migrate_db.py
│   ├── setup.sh
│   ├── requirements.txt
│   └── ... (інші файли)
│
├──РОБОТА №2: КОНТЕЙНЕРИЗАЦІЯ (НОВА)
│   ├── 📄 Dockerfile              (Production-ready multi-stage build)
│   ├── 📄 docker-compose.yml      (Запуск всіх 3 сервісів)
│   ├── 📄 nginx.conf              (Конфіг nginx для контейнера)
│   │
│   ├──ДОСЛІДЖЕННЯ:
│   │   ├── 📄 Dockerfile.experiment1.debian          (Неоптимізований)
│   │   ├── 📄 Dockerfile.experiment2.debian-optimized (Оптимізований)
│   │   ├── 📄 Dockerfile.experiment3.alpine-multistage (Best practice)
│   │   ├── 📄 Dockerfile.go.multistage               (Go приклад)
│   │   ├── 📄 main.go                                (Go проект)
│   │   ├── 📄 go.mod                                 (Go модуль)
│   │   └── 📄 experiments.sh                         (Скрипт вимірювання)
│   │
│   ├──ДОКУМЕНТАЦІЯ:
│   │   ├── 📄 DOCKER_RESEARCH_REPORT.md             (Звіт дослідження)
│   │   ├── 📄 DOCKER_COMPOSE.md                      (Інструкція запуску)
│   │   └── 📄 LAB2_INSTRUCTIONS.md                   (ЦЕ ФАЙЛ)
│   │
│   ├──КОНФІГИ:
│   │   └── 📄 .dockerignore                          (Виключення файлів)
│   │
│   └──.docker/                                       (Дані - автоматично)
│       └── mariadb/                                  (База даних на диску)
```


### Крок 1: Оновити репозиторій

```bash
# На вашому комп'ютері
cd ~/Software-deployment-technologies

# Додати нові файли
git add Dockerfile docker-compose.yml nginx.conf DOCKER_RESEARCH_REPORT.md ...

# Коммітувати
git commit -m "Lab 2: Add Docker containerization

- Multi-stage Dockerfile for optimal image size
- docker-compose.yml with all 3 services
- Experimental Dockerfiles for research
- Go example for distroless images
- Complete research report with measurements"

git push origin main
```

### Крок 2: Запустити локально

```bash
# Переконатися що Docker запущений
docker --version
docker-compose --version

# Перейти в папку проекту
cd ~/Software-deployment-technologies

# Запустити
docker-compose up -d

# Перевірити
docker-compose ps
curl http://localhost/health/alive
```

### Крок 3: Протестувати

```bash
# Health check
curl http://localhost/health/alive

# Отримати список задач
curl http://localhost/tasks

# Створити задачу
curl -X POST -d "title=Test task" http://localhost/tasks

# Перевірити логи
docker-compose logs -f web
```

### Крок 4: Запустити експерименти

```bash
# Вимірювання розмірів та часу збірки
bash experiments.sh

# Результати будуть в experiment_results.txt
cat experiment_results.txt
```

---

## ЕКСПЕРИМЕНТИ 

### Експеримент 1: Неоптимізований Debian

```bash
# Збудувати
docker build -f Dockerfile.experiment1.debian -t task-tracker:exp1 .

# Переглянути розмір
docker images task-tracker:exp1

# Переглянути шари
docker history task-tracker:exp1
```

**Очікувані результати:** 1.2 GB, +-140 сек

### Експеримент 2: Оптимізований Debian

```bash
docker build -f Dockerfile.experiment2.debian-optimized -t task-tracker:exp2 .
docker images task-tracker:exp2
docker history task-tracker:exp2
```

**Очікувані результати:** 950 MB, +-120 сек (-21%)

### Експеримент 3: Alpine Multi-stage

```bash
docker build -f Dockerfile.experiment3.alpine-multistage -t task-tracker:exp3 .
docker images task-tracker:exp3
docker history task-tracker:exp3
```

**Очікувані результати:** 280 MB, +-95 сек (-77%)

### Експеримент 4: Go Distroless

```bash
# Спочатку потрібно установить Go
docker build -f Dockerfile.go.multistage -t task-tracker-go:exp4 .
docker images task-tracker-go:exp4
docker history task-tracker-go:exp4
```

**Очікувані результати:** 12 MB, 30 сек (-99%)

---

## 📈 ПОРІВНЯННЯ РЕЗУЛЬТАТІВ

| Експеримент | Образ | Розмір | Час | Бази | Особливість |
|-------------|-------|--------|-----|------|------------|
| 1 | Debian, неоптимізований | 1200 MB | 145 сек | python:3.11-bookworm | ❌ Поганий |
| 2 | Debian, оптимізований | 950 MB | 120 сек | python:3.11-bookworm | ✅ Добре |
| 3 | Alpine, multi-stage | 280 MB | 95 сек | python:3.11-alpine | 🌟 Найкраще |
| 4 | Go, distroless | 12 MB | 30 сек | distroless | 👑 Екстремум |

---

## ПРАКТИЧНА ЧАСТИНА

### Docker Compose конфігурація

**Цільова архітектура:**

```
Internet
    ↓ :80
  nginx (reverse proxy)
    ↓ :8080
  web app (Flask)
    ↓ :3306
  mariadb (database)
```

**Запуск:**

```bash
docker-compose up -d
```

**Перевірка:**

```bash
docker-compose ps
# CONTAINER ID | IMAGE | STATUS | PORTS
# task-tracker-nginx | nginx:latest | Up (healthy) | 0.0.0.0:80
# task-tracker-app | task-tracker:latest | Up (healthy) | 8080
# task-tracker-db | mariadb:11.4 | Up (healthy) | 3306
```

**Зупинка:**

```bash
docker-compose down
# Дані БД зберігаються в .docker/mariadb/
```

---



## РОЗВ'ЯЗАННЯ ПРОБЛЕМ

### Проблема: "docker: command not found"

```bash
# Docker не встановлений
# Встановіть Docker Desktop або Docker Engine

# На Ubuntu:
sudo apt-get install docker.io docker-compose
sudo usermod -aG docker $USER
```

### Проблема: "Cannot connect to Docker daemon"

```bash
# Docker не запущений
# Запустіть Docker

# На Linux:
sudo systemctl start docker

# На macOS/Windows:
# Відкрити Docker Desktop
```

### Проблема: "Port 80 is already in use"

```bash
# Зміни в docker-compose.yml
ports:
  - "8000:80"  # Замість 80:80

# Або зупиніть інші сервіси на порту 80
sudo lsof -i :80
```

### Проблема: "mariadb is not healthy"

```bash
# 
sleep 30
docker-compose ps

# Або видаліть та перезапустіть
docker-compose down -v
docker-compose up -d
```

---


**Дата:** 19.06.2026  
**Версія:** 1.0  


