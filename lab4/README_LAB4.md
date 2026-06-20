# Лабораторна Робота №4: IaC, Terraform, Ansible

## Варіант Завдання: N=10

Розгортання Task Tracker Web Application на 2 окремих ВМ з використанням:
- **Terraform** для provisioning інфраструктури (libvirt)
- **Ansible** для управління конфігурацією

---

## Архітектура Системи

```
┌─────────────────────────────────────────┐
│           Client                        │
└────────────────┬────────────────────────┘
                 │ :80 HTTP
                 ▼
┌─────────────────────────────────────────┐
│  VM1 (worker)                           │
│  ┌──────────────────────────────────┐   │
│  │  nginx (reverse proxy)           │   │
│  │  0.0.0.0:80                      │   │
│  └────────────┬─────────────────────┘   │
│               │ :8080
│  ┌────────────▼─────────────────────┐   │
│  │  Flask Application               │   │
│  │  (Task Tracker)                  │   │
│  │  127.0.0.1:8080                  │   │
│  └────────────┬─────────────────────┘   │
└─────────────┬─┼──────────────────────────┘
              │ │ TCP :3306
              │ │  192.168.122.0/24
              │ ▼
┌─────────────────────────────────────────┐
│  VM2 (db)                               │
│  ┌──────────────────────────────────┐   │
│  │  MariaDB                         │   │
│  │  0.0.0.0:3306                    │   │
│  └──────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

---

## 📁 Структура Проекту

```
lab4/
├── terraform/
│   ├── main.tf                  # Основний Terraform конфіг
│   ├── variables.tf             
│   ├── outputs.tf               # Outputs (IP адреси)
│   ├── inventory.tpl            # Шаблон для Ansible inventory
│   └── cloud-init/
│       ├── worker.yml           # Cloud-init для worker ВМ
│       ├── db.yml              # Cloud-init для db ВМ
│       └── network.yml          # Мережева конфіг
│
├── ansible/
│   ├── playbook.yml             # Основний Ansible playbook
│   ├── inventory/
│   │   └── hosts.ini            # Inventory файл
│   └── roles/
│       ├── common/              # Роль для спільних налаштувань
│       │   ├── tasks/main.yml
│       │   ├── templates/sudoers_operator.j2
│       │   └── meta/main.yml
│       ├── db/                  # Роль для DB сервера
│       │   ├── tasks/main.yml
│       │   └── meta/main.yml
│       └── worker/              
│           ├── tasks/main.yml
│           ├── files/           
│           │   ├── app.py
│           │   ├── migrate_db.py
│           │   └── requirements.txt
│           ├── templates/
│           │   ├── mywebapp.service.j2
│           │   └── nginx_config.j2
│           └── meta/main.yml
│
└── README_LAB4.md               
```

---

## Розгортання

### 1. Вимоги

**На хост-машині:**
- Terraform >= 1.0
- Ansible >= 2.9
- libvirt або VirtualBox
- SSH ключі (~/.ssh/id_rsa, ~/.ssh/id_rsa.pub)

**ВМ ресурси:**
- CPU: 2 ядра для кожної ВМ
- RAM: 2 GB для кожної ВМ
- Disk: 20 GB SSD (рекомендується)

### 2. Підготовка SSH ключів

```bash
# Якщо ключів немає:
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""

# Перевірити що ключі існують:
ls -la ~/.ssh/id_rsa*
```

### 3. Налаштування Ubuntu образу для Cloud-init

```bash
# Завантажити образ
mkdir -p ~/libvirt/images
cd ~/libvirt/images

# Ubuntu 20.04 LTS (focal)
wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img

# Або для більш новій версії (jammy):
# wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
```

### 4. Запуск Terraform

```bash
cd lab4/terraform

# Ініціалізація
terraform init

# Перевірити план (опціонально)
terraform plan

# Розгортання інфраструктури
terraform apply

# Виведе IP адреси ВМ:
# worker_ip = 192.168.122.100
# db_ip = 192.168.122.101
```

### 5. Запуск Ansible

```bash
cd lab4/ansible

# Перевірити inventory
ansible-inventory -i inventory/hosts.ini --list

# Перевірити з'єднання до ВМ
ansible all -i inventory/hosts.ini -m ping

# Запустити playbook
ansible-playbook -i inventory/hosts.ini playbook.yml

# Якщо потрібна verbose output:
ansible-playbook -i inventory/hosts.ini playbook.yml -v
```

### 6. Перевірка розгортання

```bash
# SSH на worker
ssh -i ~/.ssh/id_rsa ubuntu@192.168.122.100

# Перевірити systemd сервіс
sudo systemctl status mywebapp
sudo systemctl status nginx

# Тестувати API
curl http://localhost/health/alive
curl http://localhost/tasks

# SSH на db
ssh -i ~/.ssh/id_rsa ubuntu@192.168.122.101

# Перевірити MariaDB
sudo systemctl status mariadb
mysql -u root -e "SHOW DATABASES;"
```

---

## Користувачі Системи

| Користувач | Пароль | Права | На яких ВМ |
|-----------|--------|-------|-----------|
| ansible | ansible123 | NOPASSWD sudo | Обидві |
| student | student_password | sudo | Обидві |
| teacher | teacher_password | sudo | Обидві |
| operator | operator_password | обмежені (systemctl) | worker |
| app | (немає) | системний користувач | worker |
| root | (заблокований SSH) | — | — |

### Права operator на worker:
```
- systemctl start/stop/restart/status mywebapp
- systemctl reload nginx
```

---

## Тестування

### Health Checks

```bash
# На worker ВМ
curl http://localhost/health/alive
curl http://localhost/health/ready

# Зовні (якщо доступ до мережі)
curl http://192.168.122.100/health/alive
```

### API тестування

```bash
# Отримати список задач
curl http://localhost/tasks

# Створити задачу
curl -X POST -d "title=Test" http://localhost/tasks

# Позначити як готову
curl -X POST http://localhost/tasks/1/done

# HTML формат
curl -H "Accept: text/html" http://localhost/tasks
```

### Перевірка мережевих обмежень

```bash
# На worker: підключення до DB повинно працювати
mysql -u mywebapp -p -h 192.168.122.101 mywebapp -e "SELECT 1"

# Зовні: пряме підключення до DB повинно бути заблоковане
mysql -u mywebapp -h 192.168.122.101 mywebapp  # Має бути refused
```

### Перевірка користувачів

```bash
# SSH як различні користувачи
ssh -i ~/.ssh/id_rsa ubuntu@192.168.122.100  # Запитує пароль (SSH key auth disabled)

# Як ansible користувач через Ansible
ansible all -i inventory/hosts.ini -u ansible -m "shell" -a "whoami"

# Перевірити sudoers operator
ansible workers -i inventory/hosts.ini -u operator -b -c local -m "command" -a "sudo systemctl status mywebapp"
```

---

## Монітори Системи

### Логи застосунку

```bash
# На worker ВМ
sudo journalctl -u mywebapp -f

# Або через Ansible
ansible workers -i inventory/hosts.ini -m "shell" -a "sudo journalctl -u mywebapp -n 50"
```

### Логи nginx

```bash
sudo tail -f /var/log/nginx/mywebapp_access.log
```

### Логи БД

```bash
# На db ВМ
sudo journalctl -u mariadb -f
```

---

## Ідемпотентність

Повторний запуск Ansible повинен бути ідемпотентним:

```bash
# Перший запуск - зробить змінні
ansible-playbook -i inventory/hosts.ini playbook.yml

# Другий запуск - не повинен змінювати нічого (окрім перевірок)
ansible-playbook -i inventory/hosts.ini playbook.yml

# Перевірити, скільки тасків змінилось:
# "changed=0 failed=0"
```

---

## Файл Градуса

```bash
# На worker ВМ
cat /home/student/gradebook

# Очікуємо: 10
```

---

## ⚙️ Наступні Кроки (Якщо потрібно розширити)

1. **Динамічний Inventory** - використати Terraform output для автоматичного заповнення
2. **Мониторинг** - додати Prometheus + Grafana
3. **Резервні копії** - додати backup сценарії
4. **SSL/TLS** - додати самопідписані сертифікати
5. **Логування** - ELK stack для логів

---

## ❌ Розв'язання Проблем

### Terraform не знаходить образ

```bash
# Перевірити що образ завантажено:
ls -la /var/lib/libvirt/images/

# Або вказати інший шлях у variables.tf
terraform apply -var='ubuntu_image=/path/to/image.img'
```

### Ansible не може підключитися до ВМ

```bash
# Перевірити SSH
ssh -i ~/.ssh/id_rsa ubuntu@192.168.122.100 "echo test"

# Перевірити Ansible конфіг
ansible all -i inventory/hosts.ini -m ping -vvv
```

### Застосунок не запускається

```bash
# На worker ВМ:
sudo systemctl status mywebapp
sudo journalctl -u mywebapp -n 50

# Перевірити конфігурацію:
sudo cat /etc/systemd/system/mywebapp.service

# Перевірити БД підключення:
sudo systemctl status mariadb
```

### БД недоступна з worker

```bash
# На db ВМ:
mysql -u mywebapp -p -e "SELECT user, host FROM mysql.user WHERE user='mywebapp'"

# Перевірити що user існує для 192.168.122.% або 192.168.122.100
```

---



**Дата**: 20.06.2026  
**Версія**: 1.0  
**Студент**: Варіант N=10  
**Завдання**: Лабораторна робота №4
