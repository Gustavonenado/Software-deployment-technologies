#!/bin/bash
#
# Скрипт для тестування Task Tracker API
# Використання: ./test_api.sh [количество_задач]
#

set -e

API_URL="${1:-http://localhost}"
NUM_TASKS="${2:-5}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
  echo -e "\n${BLUE}╔════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║ $1${NC}"
  echo -e "${BLUE}╚════════════════════════════════════════╝${NC}\n"
}

print_ok() {
  echo -e "${GREEN}✓${NC} $1"
}

print_error() {
  echo -e "${RED}✗${NC} $1"
}

print_info() {
  echo -e "${YELLOW}→${NC} $1"
}

# Перевірка доступності API
check_api() {
  print_header "Перевірка доступності API"
  
  if curl -s -o /dev/null -w "%{http_code}" "$API_URL/health/alive" | grep -q "200"; then
    print_ok "API доступний на $API_URL"
  else
    print_error "API недоступний на $API_URL"
    exit 1
  fi
}

# Тест health endpoints
test_health() {
  print_header "Тестування Health Endpoints"
  
  print_info "Перевірка /health/alive..."
  response=$(curl -s "$API_URL/health/alive")
  if [ "$response" = "OK" ]; then
    print_ok "Health alive: OK"
  else
    print_error "Health alive: FAIL"
  fi
  
  print_info "Перевірка /health/ready..."
  response=$(curl -s "$API_URL/health/ready")
  if [ "$response" = "OK" ]; then
    print_ok "Health ready: OK"
  else
    print_error "Health ready: FAIL"
  fi
}

# Отримати список задач
get_tasks() {
  print_header "Отримання списку задач"
  
  print_info "Запит на $API_URL/tasks..."
  curl -s -H "Accept: application/json" "$API_URL/tasks" | jq . || echo "[]"
}

# Створити задачу
create_task() {
  local title="$1"
  
  print_info "Створення задачі: '$title'"
  
  response=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "{\"title\":\"$title\"}" \
    "$API_URL/tasks")
  
  task_id=$(echo "$response" | jq -r '.id // empty')
  
  if [ -n "$task_id" ] && [ "$task_id" != "null" ]; then
    print_ok "Задача створена (ID: $task_id)"
    echo "$task_id"
  else
    print_error "Не вдалося створити задачу"
    return 1
  fi
}

# Позначити задачу як готову
mark_done() {
  local task_id="$1"
  
  print_info "Позначення задачи $task_id як готової..."
  
  response=$(curl -s -X POST "$API_URL/tasks/$task_id/done")
  status=$(echo "$response" | jq -r '.status // empty')
  
  if [ "$status" = "done" ]; then
    print_ok "Задача $task_id позначена як готова"
  else
    print_error "Не вдалося позначити задачу"
    return 1
  fi
}

# Основна функція
main() {
  print_header "Task Tracker API Тестування"
  
  check_api
  test_health
  
  print_header "Тестування CRUD операцій"
  
  # Очистити попередні задачі (отримати список)
  print_info "Очищення попередніх задач..."
  curl -s -H "Accept: application/json" "$API_URL/tasks" | jq -r '.[] | .id' | while read task_id; do
    if [ -n "$task_id" ] && [ "$task_id" != "null" ]; then
      curl -s -X POST "$API_URL/tasks/$task_id/done" > /dev/null
    fi
  done
  print_ok "Базда очищена"
  
  # Створити тестові задачі
  print_header "Створення $NUM_TASKS тестових задач"
  
  TASK_IDS=()
  for i in $(seq 1 $NUM_TASKS); do
    task_id=$(create_task "Тестова задача #$i")
    TASK_IDS+=("$task_id")
    sleep 0.5
  done
  
  # Отримати список задач
  print_header "Отримання всіх задач"
  curl -s -H "Accept: application/json" "$API_URL/tasks" | jq '.' 
  
  # Позначити непарні задачи як готові
  print_header "Позначення деяких задач як готових"
  
  for i in $(seq 0 $((${#TASK_IDS[@]}-1))); do
    if [ $((i % 2)) -eq 0 ]; then
      mark_done "${TASK_IDS[$i]}"
    fi
  done
  
  # Остаточний список
  print_header "Остаточний список задач"
  curl -s -H "Accept: application/json" "$API_URL/tasks" | jq '.'
  
  # Статистика
  print_header "Статистика"
  total=$(curl -s -H "Accept: application/json" "$API_URL/tasks" | jq 'length')
  done_count=$(curl -s -H "Accept: application/json" "$API_URL/tasks" | jq '[.[] | select(.status=="done")] | length')
  pending_count=$(curl -s -H "Accept: application/json" "$API_URL/tasks" | jq '[.[] | select(.status=="pending")] | length')
  
  echo -e "Всього задач: ${BLUE}$total${NC}"
  echo -e "Готових: ${GREEN}$done_count${NC}"
  echo -e "В очікуванні: ${YELLOW}$pending_count${NC}"
  
  # HTML формат тест
  print_header "Тестування HTML формату"
  print_info "GET /tasks з Accept: text/html..."
  curl -s -H "Accept: text/html" "$API_URL/tasks" | head -10
  
  # Завершення
  print_header "✓ Тестування завершено успішно!"
}

# Запуск
main
