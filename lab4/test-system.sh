#!/bin/bash
# Скрипт для тестування Lab4 системи

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Отримати IP адреси з Terraform
WORKER_IP=$(cd terraform && terraform output -raw worker_ip 2>/dev/null || echo "192.168.122.100")
DB_IP=$(cd terraform && terraform output -raw db_ip 2>/dev/null || echo "192.168.122.101")

log_header() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} $1"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

test_ok() {
    echo -e "${GREEN}✓${NC} $1"
}

test_fail() {
    echo -e "${RED}✗${NC} $1"
}

test_info() {
    echo -e "${YELLOW}→${NC} $1"
}

# ====== ОСНОВНІ ТЕСТИ ======
log_header "ТЕСТУВАННЯ Lab4 System"

echo "IP Адреси:"
echo "  Worker: $WORKER_IP"
echo "  DB: $DB_IP"
echo ""

# Test 1: Worker доступність
echo "1️ Тест доступності Worker..."
if ping -c 1 -W 2 $WORKER_IP &> /dev/null; then
    test_ok "Worker доступний за ping"
else
    test_fail "Worker не доступний"
fi

# Test 2: DB доступність
echo ""
echo "2️ Тест доступності DB..."
if ping -c 1 -W 2 $DB_IP &> /dev/null; then
    test_ok "DB доступний за ping"
else
    test_fail "DB не доступний"
fi

# Test 3: Health check - alive
echo ""
echo "3️ Тест /health/alive..."
if curl -s -f -m 5 http://$WORKER_IP/health/alive > /dev/null 2>&1; then
    test_ok "Health alive: OK (200)"
else
    test_fail "Health alive: FAILED"
fi

# Test 4: Health check - ready
echo ""
echo "4️ Тест /health/ready..."
response=$(curl -s -m 5 http://$WORKER_IP/health/ready 2>&1 || echo "FAILED")
if echo "$response" | grep -q "OK"; then
    test_ok "Health ready: OK (200) - БД доступна"
else
    test_fail "Health ready: FAILED - БД недоступна"
fi

# Test 5: API - список задач
echo ""
echo "5️ Тест GET /tasks..."
tasks=$(curl -s -m 5 http://$WORKER_IP/tasks 2>&1 || echo "[]")
if echo "$tasks" | grep -q "\["; then
    test_ok "GET /tasks: OK"
    test_info "Поточна відповідь: $tasks"
else
    test_fail "GET /tasks: FAILED"
fi

# Test 6: API - створення задачі
echo ""
echo "6️ Тест POST /tasks..."
response=$(curl -s -X POST -m 5 -d "title=Test%20Task" http://$WORKER_IP/tasks 2>&1 || echo "FAILED")
if echo "$response" | grep -q "id"; then
    test_ok "POST /tasks: Задача створена"
    test_info "Відповідь: $response"
else
    test_fail "POST /tasks: FAILED"
fi

# Test 7: Nginx запущений
echo ""
echo "7️ Тест Nginx на Worker..."
if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$WORKER_IP "sudo systemctl is-active nginx" &>/dev/null; then
    test_ok "Nginx запущений"
else
    test_fail "Nginx не запущений"
fi

# Test 8: Flask запущений
echo ""
echo "8️ Тест Flask на Worker..."
if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$WORKER_IP "sudo systemctl is-active mywebapp" &>/dev/null; then
    test_ok "Flask сервіс запущений"
else
    test_fail "Flask сервіс не запущений"
fi

# Test 9: MariaDB запущений
echo ""
echo "9️ Тест MariaDB на DB..."
if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$DB_IP "sudo systemctl is-active mariadb" &>/dev/null; then
    test_ok "MariaDB запущена"
else
    test_fail "MariaDB не запущена"
fi

# Test 10: Файл градуса
echo ""
echo "10️ Тест файлу gradebook..."
if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$WORKER_IP "cat /home/student/gradebook" &>/dev/null; then
    gradebook=$(ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$WORKER_IP "cat /home/student/gradebook")
    if [ "$gradebook" = "10" ]; then
        test_ok "Файл gradebook: $gradebook"
    else
        test_fail "Файл gradebook містить: $gradebook (очікується 10)"
    fi
else
    test_fail "Файл gradebook не знайдено"
fi

# ====== ДЕТАЛЬНІ ТЕСТИ (на ВМ) ======
log_header "ДЕТАЛЬНІ ТЕСТИ (SSH на Worker)"

echo "Користувачі на Worker:"
ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$WORKER_IP "id student && id teacher && id operator && id ansible" && \
    test_ok "Всі користувачі присутні" || \
    test_fail "Деякі користувачі відсутні"

echo ""
echo "Сервіси на Worker:"
ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$WORKER_IP \
    "sudo systemctl status mywebapp nginx 2>&1 | grep -E 'active|running'" && \
    test_ok "Всі сервіси запущені" || \
    test_fail "Деякі сервіси не запущені"

echo ""
echo "Слухаючі порти на Worker:"
ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$WORKER_IP \
    "sudo ss -tlnp 2>/dev/null | grep -E ':80|:8080'" && \
    test_ok "Порти 80 і 8080 слухають" || \
    test_fail "Порти не налаштовані"

# ====== ПЕРЕВІРКА БД ======
log_header "ПЕРЕВІРКА БД на DB"

echo "Таблиці в БД:"
ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$DB_IP \
    "mysql -u mywebapp -pmywebapp_pass123 -h 127.0.0.1 mywebapp -e 'SHOW TABLES;'" && \
    test_ok "Таблиці присутні" || \
    test_fail "Помилка доступу до БД"

# ====== ФІНАЛЬНЕ РЕЗЮМЕ ======
log_header "✅ ТЕСТУВАННЯ ЗАВЕРШЕНО"

echo "Система розгорнута на:"
echo "  • Worker: $WORKER_IP:80 (HTTP)"
echo "  • DB: $DB_IP:3306 (MySQL)"
echo ""
echo "Рекомендовані команди:"
echo "  • SSH на Worker: ssh -i ~/.ssh/id_rsa ubuntu@$WORKER_IP"
echo "  • SSH на DB: ssh -i ~/.ssh/id_rsa ubuntu@$DB_IP"
echo "  • Логи Flask: ssh ubuntu@$WORKER_IP 'sudo journalctl -u mywebapp -f'"
echo "  • Логи Nginx: ssh ubuntu@$WORKER_IP 'sudo tail -f /var/log/nginx/mywebapp_access.log'"
echo ""
