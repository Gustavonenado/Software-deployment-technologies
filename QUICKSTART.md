#Швидкий старт Task Tracker

Цей файл містить короткі інструкції для розгортання та тестування Task Tracker на Linux ВМ.

---

### Крок 1: Завантажити проект на ВМ

```bash
# SSH на ВМ
ssh student@your-vm-ip

# Завантажити файли (від GitHub або локально)
cd /tmp
git clone https://github.com/your-repo/mywebapp.git
cd mywebapp

# Або скопіювати файли через SCP
scp -r /локальна/папка/* student@vm-ip:/tmp/mywebapp/
```

### Крок 2: Запустити automation скрипт

```bash
# Перейти в папку проекту
cd /tmp/mywebapp

# Дати права на виконання
chmod +x setup.sh

# Запустити з правами root
sudo bash setup.sh


### Крок 3: Тестування

```bash
# Перевірити, чи все працює
curl http://localhost/health/alive

# Отримати список задач (порожній спочатку)
curl http://localhost/tasks

# Створити задачу
curl -X POST -d "title=Тестова задача" http://localhost/tasks

# отримати список
curl http://localhost/tasks
```

---

## Детальна Інструкція

### Передумови

- Linux ВМ (Ubuntu 20.04+ або CentOS 8+)
- SSH доступ з правами sudo
- 2+ GB RAM, 2 cores CPU, 20 GB диск

### Загальний план

1. **Підготовка ВМ** (користувач з sudo правами)
2. **Завантаження проекту**
3. **Запуск setup.sh** (автоматизація)
4. **Тестування**
5. **Перегляд логів при необхідності**

### Крок за кроком

#### 1. Підготовка ВМ

```bash
# Оновити систему (опціонально, але рекомендується)
sudo apt-get update
sudo apt-get upgrade -y

# Встановити базові утиліти
sudo apt-get install -y curl wget git vim
```

#### 2. Завантаження проекту

**Варіант A: Git clone**
```bash
cd /tmp
git clone <URL вашего репо> mywebapp
cd mywebapp
```

**Варіант B: Скачування як ZIP**
```bash
cd /tmp
wget https://github.com/your-user/mywebapp/archive/refs/heads/main.zip
unzip main.zip
cd mywebapp-main
```

**Варіант C: Через SCP (з локальної машини)**
```bash
# На локальній машині
scp -r /path/to/mywebapp student@vm-ip:/tmp/

# На ВМ
cd /tmp/mywebapp
```

#### 3. Запуск Setup Скрипту

```bash
# Перейти в папку проекту
cd /tmp/mywebapp

# Дати права на виконання
chmod +x setup.sh

# Запустити з правами root (скрипт запросить пароль)
sudo bash setup.sh

# Якщо виникла помилка, перевірити логи:
# sudo systemctl status mywebapp
# sudo journalctl -u mywebapp -n 50
```


#### 4. Перевірка розгортання

```bash
# Перевірити, чи системи запущені
sudo systemctl status mywebapp
sudo systemctl status nginx
sudo systemctl status mariadb

# Якщо щось не запущено, запустити:
sudo systemctl start mywebapp
sudo systemctl start nginx
sudo systemctl start mariadb
```

#### 5. Тестування API

```bash
# Health check
curl http://localhost/health/alive

# Отримати кореневу сторінку
curl http://localhost/

# Список задач
curl http://localhost/tasks

# Створити задачу
curl -X POST -d "title=Моя перша задача" http://localhost/tasks

# Перевірити знову
curl http://localhost/tasks | jq .
```

---

## Параметри розгортання

| Компонент | Параметр | Значення |
|-----------|----------|----------|
| **Застосунок** | Назва | mywebapp (Task Tracker) |
| | Порт | 8080 (внутрішньо), 80 (через Nginx) |
| | Конфіг | Аргументи командного рядка |
| **База даних** | Тип | MariaDB |
| | Хост | 127.0.0.1 |
| | Порт | 3306 |
| | БД | mywebapp |
| **Nginx** | Порт | 80 |
| | Логи | /var/log/nginx/mywebapp_access.log |

---

## Користувачі

| Користувач | Пароль | Права |
|-----------|--------|-------|
| student | 12345678 | sudo (admin) |
| teacher | 12345678 | sudo (admin) |
| operator | 12345678 | обмежені (systemctl, nginx) |
| app | — | системний користувач |

---

## Команди для тестування

```bash
# Базові тести здоров'я
curl http://localhost/health/alive
curl http://localhost/health/ready

# Отримати список задач
curl http://localhost/tasks

# Створити задачу
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"title":"Нова задача"}' \
  http://localhost/tasks

# Позначити задачу 1 як готову
curl -X POST http://localhost/tasks/1/done

# HTML формат
curl -H "Accept: text/html" http://localhost/tasks

# З красивим виводом (якщо встановлено jq)
curl http://localhost/tasks | jq .
```

---

## інші команди

```bash
# Статус сервісів
sudo systemctl status mywebapp
sudo systemctl status nginx
sudo systemctl status mariadb

# Запуск/зупинка/перезапуск
sudo systemctl start mywebapp
sudo systemctl stop mywebapp
sudo systemctl restart mywebapp

# Логи в реальному часі
sudo journalctl -u mywebapp -f

# Логи Nginx
sudo tail -f /var/log/nginx/mywebapp_access.log

# Перевірити процеси
ps aux | grep app.py
ps aux | grep nginx

# Перевірити прослуховування портів
sudo ss -tlnp | grep -E "80|8080|3306"
```

---

## Розв'язання проблем

### Проблема: Connection refused

```bash
# Перевірити, чи Nginx запущений
sudo systemctl start nginx

# Перевірити конфіг Nginx
sudo nginx -t
```

### Проблема: 502 Bad Gateway

```bash
# Перевірити, чи застосунок запущений
sudo systemctl restart mywebapp

# Перевірити логи
sudo journalctl -u mywebapp -n 50
```

### Проблема: Database connection failed

```bash
# Перевірити MariaDB
sudo systemctl restart mariadb

# Перевірити логи БД
sudo journalctl -u mariadb -n 50
```

### Перевірити все наразу

```bash
# Скрипт для швидкої діагностики
sudo bash -c '
echo "=== Systemd Services ==="
systemctl status mywebapp nginx mariadb | grep active
echo ""
echo "=== Ports ==="
ss -tlnp | grep -E "80|8080|3306"
echo ""
echo "=== API Health ==="
curl -s http://localhost/health/alive
echo ""
curl -s http://localhost/health/ready
'
```

---

## Документація

- **README.md** - Повна документація проекту
- **docs_API.md** - Детальна документація API
- **TESTING.md** - Інструкція тестування
- **test_api.sh** - Скрипт для автоматичного тестування

```bash
# Запустити автоматичне тестування
chmod +x test_api.sh
./test_api.sh

# Або з параметрами (создати 10 тестових задач)
./test_api.sh http://localhost 10
```


## Примітки

- **Файл gradebook**: `/home/student/gradebook` містить `10` (номер варіанту)
- **Конфіг застосунку**: Через аргументи командного рядка (V2=1)
- **База даних**: MariaDB (V2=1)
- **Порт**: 8080 (V5=1)
- **Тип застосунку**: Task Tracker (V3=2)

---

**Версія**: 1.0  
**Дата**: 19.06.2026  
**Студент**: Варіант N=10

