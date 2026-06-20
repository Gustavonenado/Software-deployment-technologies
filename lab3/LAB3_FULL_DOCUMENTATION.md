# ЛАБОРАТОРНА РОБОТА №3: CI/CD PIPELINE







## АРХІТЕКТУРА

### Потік виконання

```
┌─────────────────────────────────────────────────────────┐
│ Developer pushes code to GitHub                         │
└────────────────────┬────────────────────────────────────┘
                     │
                     ↓
    ┌────────────────────────────────┐
    │  GitHub Actions Workflow Start │
    └────────────────┬───────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
        ↓                         ↓
   ┌─────────────┐        ┌─────────────┐
   │  Code       │        │  PR Check   │
   │  Analysis   │        │  (if PR)    │
   │  - Flake8   │        │             │
   │  - MyPy     │        │ Block merge │
   │  - Hadolint │        │ if fails    │
   │  - Shell    │        │             │
   └─────────────┘        └─────────────┘
        │
        ↓
   ┌─────────────┐
   │  Run Tests  │
   │  - Unit     │
   │  - Coverage │
   │  - >40%     │
   └─────────────┘
        │
        ├─── Success? ───→ ┌─────────────────────┐
        │                  │ Build Docker Image  │
        │                  │ Push to Registry    │
        │                  │ Tag: latest, sha-   │
        │                  └──────────┬──────────┘
        │                             │
        │                    (On Tag Only)
        │                             │
        │                             ↓
        │                    ┌─────────────────┐
        │                    │ Deploy via SSH  │
        │                    │ Pull image from │
        │                    │ Registry        │
        │                    │ docker-compose  │
        │                    │ up -d           │
        │                    └────────┬────────┘
        │                             │
        │                             ↓
        │                    ┌─────────────────┐
        │                    │ Verify Deploy   │
        │                    │ - Health check  │
        │                    │ - API tests     │
        │                    │ - Nginx config  │
        │                    └─────────────────┘
        │
        └─── Fail? ───→ ❌ Build Failed
```

### Компоненти в GitHub

```
GitHub Repository
├── .github/workflows/
│   └── ci-cd.yml              ← Main pipeline definition
│
├── lab1/                       ← Application code
│   ├── app.py                 ← Flask application
│   ├── requirements.txt        ← Dependencies
│   ├── tests/
│   │   └── test_app.py        ← Unit tests
│   └── setup.sh               ← Deployment script
│
├── lab2/                       ← Docker files
│   ├── Dockerfile             ← Image definition
│   └── docker-compose.yml     ← Compose config
│
└── lab3/                       ← CI/CD scripts
    ├── setup-runner.sh        ← Install runner
    ├── setup-target-node.sh   ← Prepare target
    └── verify-deployment.sh   ← Verify deploy
```

---

## КОМПОНЕНТИ

### 1. GitHub Actions Workflow (`.github/workflows/ci-cd.yml`)

Визначає весь pipeline із завданнями:
- **analyze** - статичний аналіз коду
- **test** - запуск тестів з покриттям
- **build** - збірка Docker образу
- **deploy** - розгортання на target node
- **verify** - верифікація розгортання

### 2. Тести (`lab1/tests/test_app.py`)

Набір unit тестів для Flask застосунку:
- ✅ Health check endpoints
- ✅ CRUD операції
- ✅ Error handling
- ✅ Content-Type negotiation
- ✅ Edge cases

**Покриття:** Мінімум 40% (налаштовується)

### 3. Self-Hosted Runner

Ubuntu ВМ зі встановленими:
- Docker
- Docker Compose
- Git
- Node.js
- GitHub Actions runner software

**Запуск:** `setup-runner.sh`

### 4. Target Node

Друга ВМ для розгортання застосунку:
- Docker daemon
- Docker Compose
- Nginx (reverse proxy)
- SSH доступ

**Налаштування:** `setup-target-node.sh`

### 5. Лінтери (Analyzers)

Автоматичні перевірки якості коду:

| Лінтер | Призначення | Застосовується до |
|--------|-----------|---------------|
| **Flake8** | Python style | app.py, test_app.py |
| **MyPy** | Python type checking | app.py |
| **Hadolint** | Dockerfile best practices | Dockerfile |
| **ShellCheck** | Shell script validation | *.sh |
| **YAMLLint** | YAML file validation | docker-compose.yml |

---

## ⚙️ ВСТАНОВЛЕННЯ ТА НАЛАШТУВАННЯ

### Крок 1: GitHub Secrets (обов'язково)

У репозиторії додати secrets для безпечного зберігання:

```
Settings → Secrets and variables → Actions → New repository secret

TARGET_HOST        (IP адреса target ВМ, наприклад: 192.168.1.100)
TARGET_USER        (ім'я користувача, наприклад: deploy)
TARGET_SSH_KEY     (приватний SSH ключ для підключення)
```

**ВАЖЛИВО:** Ніколи не комітити ці значення в код!

### Крок 2: Налаштування Self-Hosted Runner

На окремій ВМ (Ubuntu 22.04+):

```bash
# 1. Завантажити скрипт
wget https://raw.githubusercontent.com/YOUR-USERNAME/repo/main/lab3/setup-runner.sh

# 2. Запустити як root
sudo bash setup-runner.sh

# 3. Запустити конфігурацію
sudo -u runner /home/runner/actions-runner/config.sh

# 4. Ввести:
#    - GitHub URL: https://github.com/YOUR-USERNAME/Software-deployment-technologies
#    - Token: (отримати з Settings → Actions → Runners)
#    - Runner name: (наприклад: deployment-runner)
#    - Groups: (натиснути Enter)
#    - Labels: (наприклад: deployment, production)

# 5. Запустити runner
sudo -u runner /home/runner/actions-runner/run.sh
```

**Або як сервіс:**

```bash
sudo /home/runner/actions-runner/svc.sh install
sudo /home/runner/actions-runner/svc.sh start
```

### Крок 3: Налаштування Target Node

На цільовій ВМ для розгортання:

```bash
# 1. Завантажити скрипт
wget https://raw.githubusercontent.com/YOUR-USERNAME/repo/main/lab3/setup-target-node.sh

# 2. Запустити як root
sudo bash setup-target-node.sh

# 3. Додати публічний SSH ключ runner:
su - deploy
mkdir -p ~/.ssh
chmod 700 ~/.ssh
cat >> ~/.ssh/authorized_keys << 'EOF'
<runner's public SSH key here>
EOF
chmod 600 ~/.ssh/authorized_keys
```

### Крок 4: Тестування SSH доступу

На машині runner:

```bash
# Тест SSH підключення
ssh -i /path/to/key deploy@TARGET_HOST "docker ps"

# Має показати список контейнерів або порожній список
```

---

## GITHUB ACTIONS WORKFLOWS

### Trigger Events

Pipeline запускається на:
- **push в main** - аналіз, тести, збірка
- **pull request в main** - аналіз, тести (блокує merge, якщо не пройдуть)
- **tagged commits (v\*)** - аналіз, тести, збірка, розгортання

### Завдання Pipeline

#### 1. Analyze (Аналіз Коду)

Використовувані лінтери:
- **Flake8** - PEP 8 стиль Python
  ```bash
  flake8 . --max-line-length=120
  ```

- **Hadolint** - Dockerfile найкращі практики
  ```bash
  hadolint lab2/Dockerfile
  ```

- **ShellCheck** - Shell скрипти
  ```bash
  shellcheck lab1/setup.sh
  ```

- **YAMLLint** - YAML конфігурація
  ```bash
  yamllint lab2/docker-compose.yml
  ```

#### 2. Test (Тестування)

```bash
# Встановити залежності
pip install pytest pytest-cov

# Запустити тести з покриттям
pytest lab1/tests/ --cov=lab1 --cov-report=xml --cov-report=html

# Перевірити мінімальне покриття
coverage report --fail-under=40
```

**Результати:**
- 📊 Артефакти зі звітом про покриття
- 📝 Коментар у PR з результатами

#### 3. Build (Збірка Образу)

```bash
# Збірка образу
docker build -f lab2/Dockerfile -t ghcr.io/username/repo:latest .

# Push у GitHub Container Registry
docker push ghcr.io/username/repo:latest
docker push ghcr.io/username/repo:sha-<commit-hash>
```

**Теги:**
- На коміт: `latest`, `sha-<full-hash>`
- На тег: `stable`, `<tag-name>`

#### 4. Deploy (Розгортання)

Запускається лише на **анотовані теги** (v1.0, v2.0, тощо):

```bash
# 1. Підключитися до target node по SSH
ssh -i key deploy@target.host << 'EOF'

# 2. Завантажити образ
docker pull ghcr.io/username/repo:v1.0

# 3. Зупинити старий контейнер
docker-compose -f /opt/task-tracker/docker-compose.yml down

# 4. Запустити новий
cd /opt/task-tracker
docker-compose up -d

# 5. Зачекати готовності
sleep 10

EOF
```

#### 5. Verify (Верифікація)

Після розгортання перевіряються:

```bash
# 1. Health endpoints доступні
curl http://target:80/health/alive
curl http://target:80/health/ready

# 2. API працює
curl http://target:80/tasks

# 3. Nginx правильно проксує
curl http://target:80/ | grep "Task Tracker"

# 4. Контейнери запущені
docker ps | grep task-tracker
```

---

## 🧪 ТЕСТУВАННЯ

### Структура Тестів

```
lab1/tests/
└── test_app.py
    ├── TestHealthCheck
    │   ├── test_health_alive
    │   ├── test_health_ready_success
    │   └── test_health_ready_failure
    ├── TestRootEndpoint
    │   ├── test_root_json
    │   └── test_root_html
    ├── TestTasksEndpoint
    │   ├── test_get_tasks_empty
    │   ├── test_get_tasks_with_data
    │   └── test_get_tasks_db_error
    ├── TestCreateTask
    │   ├── test_create_task_json
    │   ├── test_create_task_form_data
    │   ├── test_create_task_no_title
    │   └── test_create_task_db_error
    ├── TestMarkTaskDone
    │   ├── test_mark_task_done_success
    │   ├── test_mark_task_done_not_found
    │   └── test_mark_task_done_db_error
    └── TestEdgeCases
        ├── test_invalid_endpoint
        ├── test_invalid_task_id
        └── test_long_title
```

### Запуск Тестів

**Локально:**
```bash
cd lab1
pytest tests/ -v --cov

# або з HTML звітом
pytest tests/ --cov --cov-report=html
# Відкрити htmlcov/index.html
```

**У CI/CD:**
```
GitHub Actions запускає автоматично на:
- Кожен коміт у main
- Кожен PR у main
- Кожен анотований тег
```

### Покриття Коду

**Вимога:** Мінімум 40%

```
Name                      Stmts   Miss  Cover
─────────────────────────────────────────
app.py                       95     12    87%
test_app.py                  150     2    98%
─────────────────────────────────────────
TOTAL                        245     14    94%
```

### Блокування Merge у PR

Якщо не пройдуть:
- ❌ Аналіз коду
- ❌ Тести
- ❌ Покриття < 40%

То PR не може бути merged (захист гілки в GitHub).

---

## РОЗГОРТАННЯ

### Коли відбувається розгортання

Лише на **анотовані теги**:

```bash
# Створити анотований тег
git tag -a v1.0.0 -m "Release version 1.0.0"

# Запушити тег (це запустить pipeline)
git push origin v1.0.0
```

### Процес розгортання

1. **Runner** отримує код тега
2. Запускаються **analyze** та **test**
3. Якщо успішно → **build** Docker образу
4. Образ тегується як `v1.0.0` та `stable`
5. Образ push у GitHub Container Registry
6. **Deploy job** запускається (лише на runner)
7. SSH підключення до target node
8. Завантаження образу на target node
9. `docker-compose up -d` для запуску
10. **Verify** перевіряє, що все працює

### Розгортання вручну

Якщо потрібно розгорнути конкретний образ:

```bash
ssh deploy@target.host << 'EOF'
cd /opt/task-tracker

# Завантажити образ
docker pull ghcr.io/username/repo:v1.0.0

# Оновити docker-compose.yml з новим тегом образу
sed -i 's|image:.*|image: ghcr.io/username/repo:v1.0.0|' docker-compose.yml

# Перезапустити
docker-compose up -d
EOF
```

---

## ✅ ВЕРИФІКАЦІЯ

Після розгортання автоматично запускається:

```bash
bash verify-deployment.sh <target-host>
```

### Перевірки

1. **HTTP Accessibility** - /health/alive доступна
2. **Service Ready** - /health/ready повертає 200
3. **API Endpoints** - /tasks доступна
4. **JSON Format** - Відповіді валідний JSON
5. **Nginx Config** - Reverse proxy працює
6. **Forbidden Routes** - /admin повертає 404
7. **Docker Containers** - Контейнери запущені
8. **Functional Test** - Можна створити задачу
9. **Response Time** - Швидка відповідь (< 5сек)
10. **HTTPS** - SSL сертифікат (якщо налаштований)

### Результат

```
╔═══════════════════════════════════════════╗
║     Deployment Verification Summary       ║
╚═══════════════════════════════════════════╝

Passed: 10
Failed: 0

✓ All verification tests PASSED!
```

---

## БЕЗПЕКА

### Best Practices

1. **GitHub Secrets**
   - Ніколи не комітити secrets
   - Використовувати лише для sensitive даних
   - Ротувати ключі регулярно

2. **SSH Keys**
   - Генерувати окремі ключі для CI/CD
   - Обмежити права ключів (chmod 600)
   - Видалити ключі після використання

3. **Self-Hosted Runner**
   - Використовувати лише в приватних репо (якщо можливо)
   - Видаляти runner після використання
   - Не зберігати sensitive дані на runner
   - Обмежити доступ до машини runner

4. **Target Node**
   - Не запускати runner на target node (ЗАБОРОНЕНО!)
   - Використовувати окремого користувача для deploy
   - Обмежити SSH доступ
   - Увімкнути firewall
   - Регулярно оновлювати Docker

### Перевірка Безпеки

```bash
# Переконатися, що runner видалений після роботи
# На машині runner:
sudo userdel -r runner
sudo rm -rf /home/runner/actions-runner

# Видалити старі ключі SSH
rm ~/.ssh/deploy_key

# На target node перевірити логи
journalctl -u docker -n 50
tail -50 /var/log/auth.log
```

---

## ДЕМОНСТРАЦІЯ

Для демонстрації роботи потрібно:

### 1. Успішний PR (Merged)

PR, який був успішно merged:
- ✅ Code analysis пройдено
- ✅ Усі тести пройдені
- ✅ Coverage >= 40%
- ✅ Можна merge

Логи знаходяться в: **Actions → PR → Build**

### 2. Невдалий PR (Blocked)

PR, який не може бути merged:
- ❌ Аналіз коду не пройдено (lint error)
- ❌ Тести не пройдені (test failure)
- ❌ Coverage < 40%
- ❌ Merge заблоковано

Логи знаходяться в: **Actions → PR → Build**

### 3. Успішне Розгортання

Tag push, який призвів до успішного deploy:
- ✅ Аналіз успішний
- ✅ Тести успішні
- ✅ Образ зібрано
- ✅ Розгорнуто на target node
- ✅ Верифікація успішна

Логи знаходяться в: **Actions → Push → Deploy**

### 4. Невдале Розгортання

Deploy, який не пройшов верифікацію:
- ✅ Аналіз успішний
- ✅ Тести успішні
- ✅ Образ зібрано
- ✅ Розгорнуто
- ❌ Верифікація не пройдена (service not responding)

Логи знаходяться в: **Actions → Push → Verify**



## ПІДСУМКОВА СТРУКТУРА

```
Software-deployment-technologies/
├── lab1/                       (Застосунок + тести)
│   ├── app.py
│   ├── tests/
│   │   └── test_app.py         ← Unit тести
│   └── setup.sh
│
├── lab2/                       (Docker конфіги)
│   ├── Dockerfile
│   └── docker-compose.yml
│
├── lab3/                       (CI/CD скрипти)
│   ├── setup-runner.sh         ← Install runner
│   ├── setup-target-node.sh    ← Prepare target
│   └── verify-deployment.sh    ← Verify deploy
│
├── .github/workflows/
│   └── ci-cd.yml               ← Main pipeline
│
└── README.md                   (Головна документація)
```

---



## ВИРІШЕННЯ ПРОБЛЕМ

### Pipeline зависає на Deploy

```bash
# Перевірити доступність target node
ping <TARGET_HOST>
ssh deploy@<TARGET_HOST> "docker ps"

# Перевірити SSH ключ
ssh-keyscan <TARGET_HOST> >> ~/.ssh/known_hosts
```

### Тести не проходять локально

```bash
cd lab1
pip install pytest pytest-cov
pytest tests/ -v
```

### Runner не реєструється

```bash
# Перевірити токен (токен діє лише 1 годину!)
# Отримати новий токен з Settings → Actions → Runners

sudo -u runner /home/runner/actions-runner/config.sh
```

### Образ не завантажується в registry

```bash
# Перевірити GitHub token у Docker
docker login ghcr.io
# Використовувати: username + GitHub PAT токен
```

---

**Версія:** 1.0  
**Дата:** 19.06.2026  
