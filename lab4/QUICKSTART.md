# ШВИДКЕ РОЗГОРТАННЯ Lab4

## Передумови

```bash
# Установка Terraform
# Linux: https://www.terraform.io/downloads
# macOS: brew install terraform

# Установка Ansible
pip install ansible

# Перевірити versions
terraform --version
ansible --version
```

## 1️ Підготовка

```bash
# Скопіювати проект на свою машину
git clone Software-deployment-technologies lab4
cd lab4

# Переконатися що SSH ключі існують
ls ~/.ssh/id_rsa

# Якщо немає, створити:
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
```

## 2️ Завантажити Ubuntu образ

```bash
mkdir -p ~/libvirt/images
cd ~/libvirt/images

# Ubuntu 20.04 LTS (focal)
wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img

# Потім повернутись в проект
cd ~/lab4
```

## 3️ Розгортання Terraform

```bash
cd terraform

# Ініціалізація Terraform 
terraform init

# Перевірити план
terraform plan

# Розгортати інфраструктуру
terraform apply

# Отримати IP адреси:
terraform output worker_ip
terraform output db_ip
```

**Очікуємо output:**
```
worker_ip = 192.168.122.100
db_ip = 192.168.122.101
```

## 4️ Запуск Ansible

```bash
cd ../ansible

# Перевірити inventory (потрібно оновити IP якщо інші)
cat inventory/hosts.ini

# Тест з'єднання
ansible all -i inventory/hosts.ini -m ping

# Запустити playbook
ansible-playbook -i inventory/hosts.ini playbook.yml

# Очікуємо завершення без помилок
```

## 5️ Тестування

```bash
# SSH на worker
ssh -i ~/.ssh/id_rsa ubuntu@192.168.122.100

# На worker ВМ:
curl http://localhost/health/alive
curl http://localhost/tasks

# Або зовні:
curl http://192.168.122.100/health/alive
```

## Видалення ВМ

```bash
cd terraform
terraform destroy
```

---

## Швидкий Чек-Ліст

- [ ] SSH ключі існують (~/.ssh/id_rsa)
- [ ] Terraform встановлений
- [ ] Ansible встановлений
- [ ] Ubuntu образ завантажено
- [ ] `terraform apply` виконано успішно
- [ ] `ansible-playbook` виконано без помилок
- [ ] `curl http://localhost/health/alive` повертає OK
- [ ] `/home/student/gradebook` містить "10"

---

## Однорядкові команди

```bash
# Все разом (якщо все вже налаштовано):
cd terraform && terraform init && terraform apply && \
cd ../ansible && ansible-playbook -i inventory/hosts.ini playbook.yml

# Тестування (на worker ВМ):
curl http://localhost/health/alive && \
curl http://localhost/tasks && \
curl http://localhost/health/ready && \
cat /home/student/gradebook
```

---

**Дата**: 20.06.2026
