#  ІНТЕГРАЦІЯ РОБІТ №1 ТА №2

---

##  СТРУКТУРА РЕПОЗИТОРІЮ

```
Software-deployment-technologies/
│
├── README.md                      ← Оновлений (додати Docker розділ)
├── QUICKSTART.md                  ← Швидкий старт (загальний)
├── TESTING.md                     ← Тестування Роботи №1
│
├── РОБОТА №1: TRADITIONAL DEPLOYMENT
│   ├── app.py                        ← Flask застосунок
│   ├── migrate_db.py                 ← Міграція БД
│   ├── setup.sh                      ← Automation скрипт для ВМ
│   ├── requirements.txt               ← Python залежности
│   ├── test_api.sh                   ← Тестування
│   ├── README.md                      ← Робота №1 документація (залишити)
│   ├── QUICKSTART.md                  ← Робота №1 швидкий старт
│   ├── docs_API.md                    ← API документація
│   └── .gitignore
│
├──РОБОТА №2: CONTAINERIZATION
│   ├── Production Docker Files
│   │   ├── Dockerfile                ← Production-ready (multi-stage)
│   │   ├── docker-compose.yml        ← Всі 3 сервіси (app, nginx, mariadb)
│   │   ├── nginx.conf                ← Nginx конфіг для контейнера
│   │   ├── .dockerignore             ← Docker build exclusions
│   │   └── .env.example              ← Змінні оточення
│   │
│   ├──Research & Experiments
│   │   ├── Dockerfile.experiment1.debian
│   │   ├── Dockerfile.experiment2.debian-optimized
│   │   ├── Dockerfile.experiment3.alpine-multistage
│   │   ├── Dockerfile.go.multistage
│   │   ├── main.go                   ← Go приклад для distroless
│   │   ├── go.mod                    ← Go модуль
│   │   └── experiments.sh            ← Скрипт вимірювання
│   │
│   ├──Documentation
│   │   ├── DOCKER_RESEARCH_REPORT.md ← Основний звіт (⭐ важлива)
│   │   ├── DOCKER_COMPOSE.md         ← Інструкція запуску
│   │   └── LAB2_INSTRUCTIONS.md      ← Інструкція роботи №2
│   │
│   └──.docker/                   ← Дані (автоматично)
│       ├── mariadb/                  ← БД дані (зберігаються на диску)
│       └── logs/                     ← Логи контейнерів
│
├──Git файли
│   ├── .gitignore                    ← Оновлений для Docker
│   └── .github/workflows/            ← CI/CD (опціонально)
│
└──Кореневий README.md            ← НОВИЙ (об'єднаний)
```


### Крок 1: Завантажте нові файли на свій ПК

```bash
# На вашому комп'ютері
cd ~/Software-deployment-technologies

# Перенести файли в папку проекту:
# - Dockerfile
# - docker-compose.yml
# - nginx.conf
# - .dockerignore
# - .env.example
# - Dockerfile.experiment*
# - main.go
# - go.mod
# - experiments.sh
# - DOCKER_RESEARCH_REPORT.md
# - DOCKER_COMPOSE.md
# - LAB2_INSTRUCTIONS.md
```



## РОБОТА №2: КОНТЕЙНЕРИЗАЦІЯ (DOCKER)

### Запуск через Docker Compose

**Найшвидше:** Все працює в контейнерах з одною командою!

```bash
docker-compose up -d
curl http://localhost/health/alive
```

### Структура

- **Dockerfile** - Production-ready multi-stage build образ
- **docker-compose.yml** - Запуск app + nginx + mariadb в одній мережі
- **DOCKER_RESEARCH_REPORT.md** - Звіт дослідження (експерименти, порівняння)
- **DOCKER_COMPOSE.md** - Детальна інструкція

### Основні файли

- `Dockerfile` - Production образ (280 MB)
- `docker-compose.yml` - Конфіг для запуску
- `nginx.conf` - Nginx конфіг для контейнера

### Дослідження

Звіт містить аналіз 4 підходів до контейнеризації:

| Образ | Розмір | Базовий OS |
|-------|--------|-----------|
| Debian неоптимізований | 1200 MB | Debian |
| Debian оптимізований | 950 MB | Debian |
| Alpine multi-stage | 280 MB | Alpine ✓ |
| Go distroless | 12 MB | Distroless ✓ |

**Висновок:** Alpine з multi-stage build дає 77% поліпшення розміру!

### Запуск локально

```bash
# Запустити
docker-compose up -d

# Логи
docker-compose logs -f

# Тестувати
curl http://localhost/tasks
curl -X POST -d "title=My task" http://localhost/tasks

# Зупинити
docker-compose down
```

### Розгортання на ВМ

```bash
# На Linux ВМ
git clone https://github.com/YOUR-USERNAME/Software-deployment-technologies.git
cd Software-deployment-technologies
docker-compose up -d
```

### Дебагування

```bash
# Перевірити статус
docker-compose ps

# Логи
docker-compose logs web    # Логи app
docker-compose logs nginx  # Логи nginx
docker-compose logs mariadb # Логи БД

# Входити в контейнер
docker-compose exec web bash
docker-compose exec mariadb mysql -u mywebapp -pmywebapp_pass mywebapp
```

Див. повну документацію в [DOCKER_COMPOSE.md](DOCKER_COMPOSE.md)

---
```

### Крок 3: Оновите .gitignore

Додайте до archivo `.gitignore`:

```
# Docker
.docker/
.dockerignore
.env
.env.local

# Docker Compose
docker-compose.override.yml

# Build artifacts
Dockerfile.*
experiment_results.txt

# Logs
logs/
*.log

# Go
go.sum
```


### Спосіб 1: Традиційний (Робота №1)

```bash
# На Linux ВМ
sudo bash setup.sh
# Результат: система працює на ВМ
```

### Спосіб 2: Docker Compose (Робота №2)

```bash
# На будь-якій машині з Docker
docker-compose up -d
# Результат: система працює в контейнерах
```



**Версія:** 1.0  
**Дата:** 19.06.2026  


