#!/bin/bash

# ===== Deployment Verification Script =====
# Проверка что deployment произошел успешно
# Используется в CI/CD pipeline после развертывания

set -e

# Кольори
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

FAILED=0
PASSED=0

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASSED++))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAILED++))
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Параметри
TARGET_HOST="${1:-localhost}"
TARGET_PORT="${2:-80}"
TIMEOUT=30

log_info "Starting deployment verification for $TARGET_HOST:$TARGET_PORT"
echo ""

# ===== ПЕРЕВІРКА 1: Доступність HTTP =====
log_info "Test 1: HTTP Accessibility"

if timeout $TIMEOUT curl -f -s -o /dev/null "http://$TARGET_HOST/health/alive"; then
    log_pass "HTTP health/alive endpoint is accessible"
else
    log_fail "HTTP health/alive endpoint is NOT accessible"
fi

# ===== ПЕРЕВІРКА 2: Health Ready =====
log_info "Test 2: Service Ready Status"

if timeout $TIMEOUT curl -f -s -o /dev/null "http://$TARGET_HOST/health/ready"; then
    log_pass "Service is ready (health/ready returns 200)"
else
    log_fail "Service is NOT ready (health/ready does not return 200)"
fi

# ===== ПЕРЕВІРКА 3: API доступність =====
log_info "Test 3: API Endpoints"

# GET /tasks
if timeout $TIMEOUT curl -f -s -o /dev/null "http://$TARGET_HOST/tasks"; then
    log_pass "GET /tasks is accessible"
else
    log_fail "GET /tasks is NOT accessible"
fi

# ===== ПЕРЕВІРКА 4: JSON формат =====
log_info "Test 4: JSON Response Format"

RESPONSE=$(timeout $TIMEOUT curl -s -H "Accept: application/json" "http://$TARGET_HOST/tasks")

if echo "$RESPONSE" | jq empty 2>/dev/null; then
    log_pass "Response is valid JSON"
else
    log_fail "Response is NOT valid JSON"
fi

# ===== ПЕРЕВІРКА 5: Nginx конфіг =====
log_info "Test 5: Nginx Configuration"

# Перевірити що root endpoint доступний
if timeout $TIMEOUT curl -f -s -H "Accept: text/html" "http://$TARGET_HOST/" | grep -q "Task Tracker"; then
    log_pass "Nginx correctly proxies to backend"
else
    log_warn "Nginx proxy response may not be correct (but service might still work)"
fi

# ===== ПЕРЕВІРКА 6: Заборонені маршрути =====
log_info "Test 6: Security - Forbidden Routes"

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://$TARGET_HOST/admin")
if [ "$HTTP_CODE" = "404" ]; then
    log_pass "Unauthorized routes return 404"
else
    log_warn "Route /admin returned $HTTP_CODE (expected 404)"
fi

# ===== ПЕРЕВІРКА 7: Docker контейнери =====
log_info "Test 7: Docker Containers Status"

# Це можна запустити локально якщо є доступ до Docker
if command -v docker &> /dev/null; then
    CONTAINERS=$(docker ps -q 2>/dev/null || echo "")
    if [ -n "$CONTAINERS" ]; then
        log_pass "Docker containers are running"
    else
        log_fail "No Docker containers found"
    fi
else
    log_warn "Docker not accessible from this machine (skipping container check)"
fi

# ===== ПЕРЕВІРКА 8: Простий функціональний тест =====
log_info "Test 8: Functional Test - Create Task"

# Спробувати створити задачу
CREATE_RESPONSE=$(timeout $TIMEOUT curl -s -X POST \
    -H "Content-Type: application/json" \
    -d '{"title":"Verification test"}' \
    "http://$TARGET_HOST/tasks")

if echo "$CREATE_RESPONSE" | jq empty 2>/dev/null; then
    if echo "$CREATE_RESPONSE" | jq -e '.id' > /dev/null 2>&1; then
        log_pass "Can create tasks (functional test passed)"
    else
        log_warn "Task creation response invalid"
    fi
else
    log_fail "Task creation failed"
fi

# ===== ПЕРЕВІРКА 9: Response Times =====
log_info "Test 9: Response Time Performance"

START=$(date +%s%N)
timeout $TIMEOUT curl -f -s -o /dev/null "http://$TARGET_HOST/tasks"
END=$(date +%s%N)

ELAPSED=$((($END - $START) / 1000000))  # мілісекунди

if [ $ELAPSED -lt 5000 ]; then
    log_pass "Response time is good: ${ELAPSED}ms"
elif [ $ELAPSED -lt 10000 ]; then
    log_warn "Response time is acceptable: ${ELAPSED}ms"
else
    log_fail "Response time is slow: ${ELAPSED}ms"
fi

# ===== ПЕРЕВІРКА 10: SSL (якщо налаштовано) =====
log_info "Test 10: HTTPS Support"

if timeout $TIMEOUT curl -f -s -k "https://$TARGET_HOST" > /dev/null 2>&1; then
    log_pass "HTTPS is configured"
else
    log_warn "HTTPS is not available (expected for HTTP-only setup)"
fi

# ===== РЕЗЮМЕ =====
echo ""
echo "╔═══════════════════════════════════════════╗"
echo "║     Deployment Verification Summary       ║"
echo "╚═══════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    log_pass "All verification tests PASSED! ✓"
    echo ""
    log_info "Deployment is healthy and ready for use."
    exit 0
else
    log_fail "Some verification tests FAILED!"
    echo ""
    log_warn "Please check the deployment and logs above."
    exit 1
fi
