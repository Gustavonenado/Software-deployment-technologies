# ІНСТРУКЦІЯ ПОЧАТКУ РОБОТИ

---

##  Структура Файлів

```
mywebapp/
│
├── 📄 app.py                 # Основна Flask програма (Task Tracker API)
├── 📄 migrate_db.py          # Скрипт для міграції MariaDB
├── 📄 requirements.txt       # Python залежності
├── 📄 setup.sh               # ⭐ ОСНОВНИЙ СКРИПТ РОЗГОРТАННЯ
│
├── 📝 README.md              #  ПОВНА ДОКУМЕНТАЦІЯ
├── 📝 QUICKSTART.md          #  СТАРТ 
├── 📝 TESTING.md             #  ІНСТРУКЦІЯ ТЕСТУВАННЯ
│
├── 📁 docs/
│   └── 📝 API.md             #  Детальна документація API
│
├── 📄 test_api.sh            # Скрипт для автоматичного тестування
└── 📄 .gitignore             # Git конфіг

```

---

### 

1. **QUICKSTART.md** 
2. Запустити **setup.sh** на ВМ
3. Тестувати через **curl** або **test_api.sh**


###


---

## 📋 Варіант Завдання

**N = 10**

| Параметр | Значення |
|----------|----------|
| V2 | 1 (Аргументи командного рядка, MariaDB) |
| V3 | 2 (Task Tracker) |
| V5 | 1 (Порт 8080) |

---

## ЗАПУСК 

```bash
# 1. Завантажити на ВМ та перейти в папку
cd /tmp && git clone <YOUR-REPO> mywebapp && cd mywebapp

# 2. Запустити автоматизацію
sudo bash setup.sh

# 3. Тестувати
curl http://localhost/health/alive
curl http://localhost/tasks
```

**Готово!**

---

## ФАЙЛИ

### **app.py** 
Основна Flask програма Task Tracker API

**запустити:**
```bash
python3 app.py --host 127.0.0.1 --port 8080 \
  --db-host 127.0.0.1 --db-user mywebapp \
  --db-password password --db-name mywebapp
```

### **migrate_db.py** 
Скрипт для створення таблиць у MariaDB

**Запуск:**
```bash
python3 migrate_db.py --db-host 127.0.0.1 \
  --db-user mywebapp --db-password password --db-name mywebapp
```

### **setup.sh** ⭐ 

**Запуск:**
```bash
sudo bash setup.sh
```

### **requirements.txt** 
Python залежності:
- Flask
- mysql-connector-python
- Werkzeug

### **test_api.sh** 
Скрипт для автоматичного тестування API

**Запуск:**
```bash
chmod +x test_api.sh
./test_api.sh
```

### **README.md** 
**ПОВНА ДОКУМЕНТАЦІЯ** 

Містить:
- Варіант завдання (розрахунки)
- Опис застосунку
- Архітектуру системи
- Розгортання
- Користувачів
- Тестування
- Розв'язання проблем

### **QUICKSTART.md**
**ШВИДКИЙ СТАРТ** - 


### **TESTING.md** 
**ІНСТРУКЦІЯ ТЕСТУВАННЯ** - як тестувати систему

- Health checks
- CRUD операції
- HTML та JSON формати
- Логи та дебагінг
- Сценарії тестування

### **docs_API.md** 
**Детальна API ДОКУМЕНТАЦІЯ**

- Всі ендпоінти
- Параметри запитів
- Приклади відповідей
- Коди помилок
- Сценарії використання

### **.gitignore** 
Git конфіг для пропуску непотрбних файлів

---


###використовується у проекті

- **Flask** - мініатюрний веб-фреймворк Python
- **MariaDB** - реляційна база даних
- **Nginx** - веб-сервер та reverse proxy
- **systemd** - система управління сервісами Linux
- **Bash** - скриптування



## РОЗВ'ЯЗАННЯ ПРОБЛЕМ

### Проблема: setup.sh не запускається
```bash
# Перевірити права
ls -la setup.sh

# Дати права на виконання
chmod +x setup.sh

# Запустити
sudo bash setup.sh
```

### Проблема: Помилка при запуску сервісу
```bash
# Перевірити статус
sudo systemctl status mywebapp

# Переглянути логи
sudo journalctl -u mywebapp -n 50

# Перезапустити
sudo systemctl restart mywebapp
```

### Проблема: БД не доступна
```bash
# Перевірити MariaDB
sudo systemctl status mariadb

# Запустити БД
sudo systemctl start mariadb

# Перевірити з'єднання
mysql -u mywebapp -p -h 127.0.0.1 mywebapp
```

### Проблема: Nginx повертає 502
```bash
# Перевірити застосунок
sudo systemctl status mywebapp

# Перевірити логи Nginx
sudo tail -30 /var/log/nginx/mywebapp_error.log

# Перевірити логи застосунку
sudo journalctl -u mywebapp -n 50
```

---

## ТЕСТУВАННЯ

### Мінімальний тест 
```bash
curl http://localhost/health/alive
# Очікуємо: OK
```

### Повний тест 
```bash
chmod +x test_api.sh
./test_api.sh
```

### Вручну з curl

```bash
# 1. Отримати список задач
curl http://localhost/tasks

# 2. Створити задачу
curl -X POST -d "title=Тест" http://localhost/tasks

# 3. Позначити як готову
curl -X POST http://localhost/tasks/1/done

# 4. Перевірити HTML формат
curl -H "Accept: text/html" http://localhost/tasks
```

запуск:

```bash
sudo bash setup.sh
```

І система буде готова до роботи 

---

**Версія**: 1.0  
**Дата**: 19.06.2026 
**Автор**: Студент (N=10)  
**Завдання**: Лабораторна робота №1 - Task Tracker

