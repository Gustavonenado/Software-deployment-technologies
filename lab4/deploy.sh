#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Check prerequisites
log_info "Перевіряю вимоги..."

# Check Terraform
if ! command -v terraform &> /dev/null; then
    log_error "Terraform не встановлений. Встановіть: https://www.terraform.io/downloads"
fi
log_info "✓ Terraform: $(terraform --version | head -1)"

# Check Ansible
if ! command -v ansible &> /dev/null; then
    log_error "Ansible не встановлений. Встановіть: pip install ansible"
fi
log_info "✓ Ansible: $(ansible --version | head -1)"

# Check SSH keys
if [ ! -f ~/.ssh/id_rsa ]; then
    log_warn "SSH ключі не знайдені. Створюю..."
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
    log_info "✓ SSH ключі створені"
else
    log_info "✓ SSH ключі існують"
fi

# Check Ubuntu image
UBUNTU_IMAGE="/var/lib/libvirt/images/focal-server-cloudimg-amd64.img"
if [ ! -f "$UBUNTU_IMAGE" ]; then
    log_warn "Ubuntu образ не знайдений. Завантажую..."
    mkdir -p /var/lib/libvirt/images
    cd /var/lib/libvirt/images
    wget -q https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img
    log_info "✓ Ubuntu образ завантажено"
    cd -
else
    log_info "✓ Ubuntu образ існує"
fi

# Deploy with Terraform
log_info ""
log_info "Розгортання інфраструктури Terraform..."
cd terraform

terraform init -input=false -no-color

log_info "Запуск terraform apply..."
terraform apply -auto-approve -no-color

# Get IP addresses
WORKER_IP=$(terraform output -raw worker_ip)
DB_IP=$(terraform output -raw db_ip)

log_info "✓ ВМ розгорнуті"
log_info "  Worker: $WORKER_IP"
log_info "  DB: $DB_IP"

# Update Ansible inventory
log_info ""
log_info "Оновлення Ansible inventory..."
cd ../ansible

cat > inventory/hosts.ini << EOF
[workers]
worker ansible_host=$WORKER_IP ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa

[db]
db ansible_host=$DB_IP ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa

[all:vars]
ansible_python_interpreter=/usr/bin/python3
db_server_ip=$DB_IP
EOF

log_info "✓ Inventory оновлено"

# Test connectivity
log_info ""
log_info "Перевіряю з'єднання до ВМ..."
sleep 10  # Wait for VMs to boot

for i in {1..30}; do
    if ansible all -i inventory/hosts.ini -m ping -q 2>/dev/null; then
        log_info "✓ З'єднання встановлено"
        break
    fi
    if [ $i -eq 30 ]; then
        log_error "Не можу підключитися до ВМ після 5 хвилин"
    fi
    log_info "Спроба $i/30 - очікую ВМ..."
    sleep 10
done

# Run Ansible playbook
log_info ""
log_info "Запуск Ansible playbook..."

ansible-playbook -i inventory/hosts.ini playbook.yml

log_info ""
log_info "╔════════════════════════════════════════════════════════╗"
log_info "║  РОЗГОРТАННЯ ЗАВЕРШЕНО УСПІШНО!                       ║"
log_info "╚════════════════════════════════════════════════════════╝"
log_info ""
log_info "📋 ПАРАМЕТРИ СИСТЕМИ:"
log_info "  Worker IP: $WORKER_IP"
log_info "  DB IP: $DB_IP"
log_info ""
log_info "🔗 КОМАНДИ ДЛЯ ТЕСТУВАННЯ:"
log_info "  SSH на worker:    ssh -i ~/.ssh/id_rsa ubuntu@$WORKER_IP"
log_info "  SSH на db:        ssh -i ~/.ssh/id_rsa ubuntu@$DB_IP"
log_info "  API Health:       curl http://$WORKER_IP/health/alive"
log_info "  API Tasks:        curl http://$WORKER_IP/tasks"
log_info ""
log_info "🧹 ДЛЯ ВИДАЛЕННЯ:"
log_info "  cd terraform && terraform destroy"
log_info ""
