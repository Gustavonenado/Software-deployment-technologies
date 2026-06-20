#!/bin/bash
# Перевірка всіх вимог перед розгортанням

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Перевірка вимог для Lab4                 ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
echo ""

PASSED=0
FAILED=0

check_command() {
    local cmd=$1
    local name=$2
    
    if command -v $cmd &> /dev/null; then
        version=$($cmd --version 2>&1 | head -1)
        echo -e "${GREEN}✓${NC} $name - OK"
        echo "  $version"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} $name - НЕ ВСТАНОВЛЕНО"
        ((FAILED++))
    fi
}

check_file() {
    local file=$1
    local name=$2
    
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $name - OK"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} $name - НЕ ЗНАЙДЕНО"
        ((FAILED++))
    fi
}

check_directory() {
    local dir=$1
    local name=$2
    
    if [ -d "$dir" ]; then
        echo -e "${GREEN}✓${NC} $name - OK"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} $name - НЕ ЗНАЙДЕНО"
        ((FAILED++))
    fi
}

echo "🔍 Перевірка встановлених програм:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
check_command terraform "Terraform"
check_command ansible "Ansible"
check_command ssh "OpenSSH"
check_command git "Git"
echo ""

echo "📁 Перевірка файлів проекту:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
check_directory "terraform" "Terraform директорія"
check_directory "ansible" "Ansible директорія"
check_file "terraform/main.tf" "Terraform конфіг"
check_file "ansible/playbook.yml" "Ansible playbook"
check_file "ansible/inventory/hosts.ini" "Ansible inventory"
echo ""

echo "🔐 Перевірка SSH ключів:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
check_file "~/.ssh/id_rsa" "Приватний ключ"
check_file "~/.ssh/id_rsa.pub" "Публічний ключ"
echo ""

echo "📊 РЕЗУЛЬТАТИ:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "Пройдено: ${GREEN}${PASSED}${NC}"
echo -e "Помилок: ${RED}${FAILED}${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ ВСІ ВИМОГИ ВИКОНАНІ!${NC}"
    echo ""
    echo "🚀 Можете запустити: ./deploy.sh"
    exit 0
else
    echo -e "${RED}✗ ВСТАНОВІТЬ ВІДСУТНІ КОМПОНЕНТИ${NC}"
    echo ""
    echo "Потрібні команди встановлення:"
    
    if ! command -v terraform &> /dev/null; then
        echo "  • Terraform: https://www.terraform.io/downloads"
    fi
    
    if ! command -v ansible &> /dev/null; then
        echo "  • Ansible: pip install ansible"
    fi
    
    if [ ! -f ~/.ssh/id_rsa ]; then
        echo "  • SSH ключі: ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N \"\""
    fi
    
    exit 1
fi
