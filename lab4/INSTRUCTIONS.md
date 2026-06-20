#  Лабораторна Робота №4: IaC з Terraform та Ansible

## ШВИДКИЙ СТАРТ

```bash
# 1. Перейти в директорію
cd lab4

# 2. Зробити скрипти виконуваними
chmod +x *.sh

# 3. Перевірити вимоги
./check-requirements.sh

# 4. Розгортати систему
./deploy.sh

# 5. Тестувати систему
./test-system.sh
```

---

## 📋 ДОСТУПНІ СКРИПТИ

### `check-requirements.sh` 
Перевіряє встановлені програми та файли проекту
```bash
./check-requirements.sh
```

### `deploy.sh`
**Основний скрипт розгортання** - запускає Terraform та Ansible
```bash
./deploy.sh
```

### `test-system.sh`
Тестує розгорнуту систему
```bash
./test-system.sh
```

### `cleanup.sh`
Видаляє ВМ та очищує ресурси
```bash
./cleanup.sh
```

### `init-git.sh`
Ініціалізує Git репозиторій
```bash
./init-git.sh
```

---

## 📚 ДОКУМЕНТАЦІЯ

| Файл | Назва | Для кого |
|------|-------|---------|
| **START_HERE.txt** | 
| **QUICKSTART.md** | 
| **README_LAB4.md** | Повна документація
| **CHECKLIST.md** | 

---

## 🏗️ СТРУКТУРА ПРОЕКТУ

```
lab4/                          ← Головна директорія
│
├── terraform/                 ← Provisioning (2 ВМ)
│   ├── main.tf               
│   ├── variables.tf         
│   ├── outputs.tf            ← IP адреси
│   ├── inventory.tpl         ← Шаблон для Ansible
│   └── cloud-init/          
│
├── ansible/                   ← Configuration Management
│   ├── playbook.yml          ← Основний playbook
│   ├── inventory/
│   │   └── hosts.ini         ← Список ВМ
│   └── roles/
│       ├── common/          
│       ├── db/              ← MariaDB
│       └── worker/          ← Flask, Nginx
│
├── Скрипти для розгортання
│   ├── deploy.sh             ← ОСНОВНИЙ скрипт
│   ├── check-requirements.sh г
│   ├── test-system.sh        ← Тестування
│   ├── cleanup.sh            ← Видалення ВМ
│   └── init-git.sh           ← Git ініціалізація
│
└── Документація
    ├── START_HERE.txt      
    ├── QUICKSTART.md
    ├── README_LAB4.md
    └── CHECKLIST.md
```

---


 ЩО БУЛО РЕАЛІЗОВАНО

✅ **Terraform:**
- Provisioning 2 ВМ (worker + db)
- Cloud-init для базової конфігурації
- Динамічне генерування Ansible inventory

✅ **Ansible:**
- 3 ролі (common, db, worker)
- Динамічні шаблони з IP адресами
- Ідемпотентна конфігурація

✅ **Сервіси:**
- Nginx reverse proxy на worker
- Flask приложение на worker
- MariaDB на db
- systemd для управління сервісами

✅ **Користувачі:**
- ansible (NOPASSWD sudo)
- student, teacher (sudo)
- operator (обмежені права)
- app (системний користувач)

✅ **Моніторинг:**
- /health/alive
- /health/ready (перевіряє БД)
- Логування systemd

✅ **Документація:**



## КОМАНДИ РОЗГОРТАННЯ

### Короткий варіант (якщо все вже налаштовано):
```bash
cd terraform && terraform apply && \
cd ../ansible && ansible-playbook -i inventory/hosts.ini playbook.yml
```

### Довгий варіант (з перевірками):
```bash
# 1. Перевірка
./check-requirements.sh

# 2. Встановлення залежностей (якщо потрібно)
pip install ansible

# 3. Завантажити Ubuntu образ
mkdir -p ~/libvirt/images
cd ~/libvirt/images
wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img

# 4. Розгортання
cd ~/lab4
./deploy.sh

# 5. Тестування
./test-system.sh
```

---

## КОМАНДИ ДЛЯ ТЕСТУВАННЯ

### Після розгортання перевірте:

```bash
# Отримати IP адреси
cd terraform
WORKER=$(terraform output -raw worker_ip)
DB=$(terraform output -raw db_ip)

# Тести з командного рядка
curl http://$WORKER/health/alive
curl http://$WORKER/health/ready
curl http://$WORKER/tasks

# SSH на ВМ
ssh -i ~/.ssh/id_rsa ubuntu@$WORKER
ssh -i ~/.ssh/id_rsa ubuntu@$DB

# На Worker ВМ
sudo systemctl status mywebapp
sudo systemctl status nginx
sudo journalctl -u mywebapp -f

# На DB ВМ
sudo systemctl status mariadb
mysql -u root -e "SHOW DATABASES;"
```

---

## НАЛАШТУВАННЯ (якщо потрібна кастомізація)

### Змінити кількість CPU/RAM
Відредагувати `terraform/variables.tf`:
```hcl
variable "worker_memory" {
  default = 4096  # Замість 2048
}
```

### Змінити мережу
Відредагувати `terraform/main.tf`:
```hcl
addresses = ["10.0.0.0/24"]  # Замість 192.168.122.0/24
```

### Додати користувача
Відредагувати `ansible/roles/common/tasks/main.yml`

---

## РОЗВ'ЯЗАННЯ ПРОБЛЕМ

### Terraform не знаходить образ
```bash
# Завантажити образ в правильне місце
mkdir -p /var/lib/libvirt/images
cd /var/lib/libvirt/images
wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img
```

### Ansible не може підключитися
```bash
# Перевірити SSH доступ
ssh -i ~/.ssh/id_rsa ubuntu@192.168.122.100

# Перевірити inventory
ansible-inventory -i ansible/inventory/hosts.ini --list
```

### ВМ не запускаються
```bash
# Перевірити libvirt
virsh list

# Перевірити логи
journalctl -xe
```



