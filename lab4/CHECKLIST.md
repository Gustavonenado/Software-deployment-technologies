# Перевірка Лабораторної роботи №4

## Варіант: N=10

### Розраховані параметри:
- **V2** = (10 % 2) + 1 = **1** → Конфіг через аргументи командного рядка + MariaDB
- **V3** = (10 % 3) + 1 = **2** → Task Tracker (сервіс управління задачами)
- **V5** = (10 % 5) + 1 = **1** → Порт 8080

---

## ✅ Критерії приймання роботи

### 1. Автоматизація інфраструктури (Terraform)
- [x] 2 ВМ піднімаються однією командою `terraform apply`
- [x] Використаний provайдер libvirt (для KVM/QEMU)
- [x] Cloud-init для базового налаштування
- [x] Створення SSH ключа студента у cloud-init
- [x] Динамічне генерування Ansible inventory з IP адрес

### 2. Управління конфігурацією (Ansible)
- [x] Inventory файл з групами [workers] та [db]
- [x] Розробка ролей:
  - [x] common - користувачі, пакети, ssh
  - [x] db - MariaDB установка та конфіг
  - [x] worker - Flask, nginx, застосунок
- [x] Ansible шаблони для конфігів (nginx, systemd)
- [x] Динамічне підставлення IP адрес
- [x] Одна команда: `ansible-playbook -i inventory/hosts.ini playbook.yml`

### 3. Ідемпотентність
- [x] Повторний запуск Ansible не змінює систему (якщо конфіг однаковий)
- [x] Відсутність прямих shell командах (використовуються Ansible модулі)
- [x] Використання lineinfile, template, systemd модулів

### 4. Розподіленість системи
- [x] worker ВМ підключається до БД на db ВМ
- [x] Доступ до БД обмежено (тільки з worker)
- [x] nginx на worker як reverse proxy (0.0.0.0:80)
- [x] Flask на worker (127.0.0.1:8080)
- [x] MariaDB на db (доступна з worker)

### 5. Користувачі та права
- [x] ansible - адміністративні права, присутній на всіх ВМ
- [x] teacher - адміністративні права, присутній на всіх ВМ
- [x] student - адміністративні права, присутній на всіх ВМ
- [x] operator - обмежені права на сервісах, присутній на worker
- [x] app - системний користувач, запускає застосунок на worker
- [x] Дефолтні користувачі блоковані
- [x] SSH на всіх ВМ через публічні ключі

### 6. Health Checks
- [x] `/health/alive` повертає 200 OK
- [x] `/health/ready` перевіряє БД підключення
- [x] Динамічна IP адреса DB у systemd service

### 7. Файл Градуса
- [x] `/home/student/gradebook` містить число 10

---

## Команди для тестування

### Тест Terraform
```bash
cd terraform
terraform init
terraform plan
terraform apply

# Перевірити IP адреси
terraform output worker_ip
terraform output db_ip
```

### Тест Ansible
```bash
cd ansible

# Перевірити з'єднання
ansible all -i inventory/hosts.ini -m ping

# Запустити playbook
ansible-playbook -i inventory/hosts.ini playbook.yml

# Перевірити ідемпотентність
ansible-playbook -i inventory/hosts.ini playbook.yml  # Не повинно змінювати
```

### Тест системи
```bash
# На worker ВМ
ssh -i ~/.ssh/id_rsa ubuntu@<WORKER_IP>

# Health checks
curl http://localhost/health/alive
curl http://localhost/health/ready

# API
curl http://localhost/tasks
curl -X POST -d "title=Test" http://localhost/tasks

# Перевірити користувачів
id student
id teacher
id operator
id ansible
cat /home/student/gradebook
```

### Тест мережевих обмежень
```bash
# На worker ВМ
mysql -u mywebapp -p -h <DB_IP> mywebapp -e "SELECT 1"

# На db ВМ
mysql -u root -e "SHOW DATABASES;"

# Зовні (має бути forbidden)
mysql -u mywebapp -h <DB_IP> mywebapp  # Should fail
```

---

## Git репозиторій

```bash
cd lab4
git init
git add .
git commit -m "Lab4: IaC with Terraform and Ansible"
git remote add origin https://github.com/your-user/lab4.git
git branch -M main
git push -u origin main
```

---

## Документація

Проект містить:
- **README_LAB4.md** - Повна документація з архітектурою
- **QUICKSTART.md** - Швидкий старт для розгортання
- **deploy.sh** - Автоматичний скрипт розгортання
- Коментарі у Terraform та Ansible файлах

---

## Одна команда для розгортання

```bash
chmod +x deploy.sh
./deploy.sh
```

Скрипт автоматично:
1. Перевірить вимоги (Terraform, Ansible)
2. Завантажить Ubuntu образ (якщо потрібно)
3. Розгорне ВМ через Terraform
4. Оновить Ansible inventory
5. Запустить Ansible playbook

---

**Дата**: 20.06.2026  
**Версія**: 1.0  
**Студент**: Варіант N=10
