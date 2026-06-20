# Dockerfile - Task Tracker Web Application
# Multi-stage build для оптимізації розміру образу
# Базовий образ: Python 3.11 на Alpine Linux

# ===== STAGE 1: Builder (збірка залежностей) =====
FROM python:3.11-alpine AS builder

WORKDIR /build

# Встановити залежності для збірки Python пакетів
RUN apk add --no-cache \
    gcc \
    musl-dev \
    linux-headers

# Скопіювати тільки requirements.txt (не код!)
# Це дозволяє кешувати шар залежностей
COPY requirements.txt .

# Створити виконуваний раз для залежностей
RUN pip install --user --no-cache-dir -r requirements.txt

# ===== STAGE 2: Runtime (фінальний образ) =====
FROM python:3.11-alpine

# Метаінформація образу
LABEL maintainer="student@university.edu"
LABEL description="Task Tracker Web Application - REST API for task management"
LABEL version="1.0"

# Встановити невеликі runtime залежности
RUN apk add --no-cache \
    curl \
    ca-certificates

# Створити непривілейованого користувача для запуску застосунку
RUN addgroup -g 1000 appuser && \
    adduser -D -u 1000 -G appuser appuser

WORKDIR /app

# Скопіювати встановлені залежності з builder stage
COPY --from=builder /root/.local /home/appuser/.local

# Скопіювати код застосунку
COPY app.py migrate_db.py ./

# Дати права на файли
RUN chown -R appuser:appuser /app && \
    chmod 755 /app

# Встановити PATH для користувача
ENV PATH=/home/appuser/.local/bin:$PATH \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Переключитися на непривілейованого користувача
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health/alive || exit 1

# Стандартні аргументи запуску
# Можуть бути перевизначені при запуску контейнера
ENV APP_HOST=0.0.0.0 \
    APP_PORT=8080 \
    DB_HOST=mariadb \
    DB_USER=mywebapp \
    DB_PASSWORD=mywebapp_pass \
    DB_NAME=mywebapp

# Запуск застосунку
CMD ["python", "app.py", \
     "--host", "${APP_HOST}", \
     "--port", "${APP_PORT}", \
     "--db-host", "${DB_HOST}", \
     "--db-user", "${DB_USER}", \
     "--db-password", "${DB_PASSWORD}", \
     "--db-name", "${DB_NAME}"]
