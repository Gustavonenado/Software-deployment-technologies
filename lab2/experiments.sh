#!/bin/bash

# ===== EXPERIMENTS SCRIPT =====
# Скрипт для запуску всіх експериментів та вимірювання результатів
# Використання: bash experiments.sh

set -e

# Кольори для вивода
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Логування
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Файл для результатів
RESULTS_FILE="experiment_results.txt"

# Очистити файл результатів
> "$RESULTS_FILE"

echo "===============================================" | tee -a "$RESULTS_FILE"
echo "Docker Image Build Experiments" | tee -a "$RESULTS_FILE"
echo "Date: $(date)" | tee -a "$RESULTS_FILE"
echo "===============================================" | tee -a "$RESULTS_FILE"
echo "" | tee -a "$RESULTS_FILE"

# ===== EXPERIMENT 1: Неоптимізований Debian =====
log_info "EXPERIMENT 1: Unoptimized Debian-based image"

echo "" | tee -a "$RESULTS_FILE"
echo "=== EXPERIMENT 1: Unoptimized Debian ===" | tee -a "$RESULTS_FILE"

docker image rm task-tracker:exp1-debian 2>/dev/null || true

START_TIME=$(date +%s)
log_info "Building Dockerfile.experiment1.debian..."
docker build -f Dockerfile.experiment1.debian -t task-tracker:exp1-debian . 2>&1 | tail -5
END_TIME=$(date +%s)

BUILD_TIME=$((END_TIME - START_TIME))
IMAGE_SIZE=$(docker images task-tracker:exp1-debian --format "{{.Size}}")

echo "Build time: ${BUILD_TIME}s" | tee -a "$RESULTS_FILE"
echo "Image size: ${IMAGE_SIZE}" | tee -a "$RESULTS_FILE"

log_success "EXPERIMENT 1 completed"
echo "" | tee -a "$RESULTS_FILE"

# ===== EXPERIMENT 2: Оптимізований Debian =====
log_info "EXPERIMENT 2: Optimized Debian-based image"

echo "" | tee -a "$RESULTS_FILE"
echo "=== EXPERIMENT 2: Optimized Debian ===" | tee -a "$RESULTS_FILE"

docker image rm task-tracker:exp2-debian-opt 2>/dev/null || true

START_TIME=$(date +%s)
log_info "Building Dockerfile.experiment2.debian-optimized..."
docker build -f Dockerfile.experiment2.debian-optimized -t task-tracker:exp2-debian-opt . 2>&1 | tail -5
END_TIME=$(date +%s)

BUILD_TIME=$((END_TIME - START_TIME))
IMAGE_SIZE=$(docker images task-tracker:exp2-debian-opt --format "{{.Size}}")

echo "Build time: ${BUILD_TIME}s" | tee -a "$RESULTS_FILE"
echo "Image size: ${IMAGE_SIZE}" | tee -a "$RESULTS_FILE"

log_success "EXPERIMENT 2 completed"
echo "" | tee -a "$RESULTS_FILE"

# ===== EXPERIMENT 3: Alpine Multi-stage =====
log_info "EXPERIMENT 3: Optimized Alpine with multi-stage build"

echo "" | tee -a "$RESULTS_FILE"
echo "=== EXPERIMENT 3: Alpine Multi-stage ===" | tee -a "$RESULTS_FILE"

docker image rm task-tracker:exp3-alpine-multi 2>/dev/null || true

START_TIME=$(date +%s)
log_info "Building Dockerfile.experiment3.alpine-multistage..."
docker build -f Dockerfile.experiment3.alpine-multistage -t task-tracker:exp3-alpine-multi . 2>&1 | tail -5
END_TIME=$(date +%s)

BUILD_TIME=$((END_TIME - START_TIME))
IMAGE_SIZE=$(docker images task-tracker:exp3-alpine-multi --format "{{.Size}}")

echo "Build time: ${BUILD_TIME}s" | tee -a "$RESULTS_FILE"
echo "Image size: ${IMAGE_SIZE}" | tee -a "$RESULTS_FILE"

log_success "EXPERIMENT 3 completed"
echo "" | tee -a "$RESULTS_FILE"

# ===== EXPERIMENT 4: Go Multi-stage =====
log_info "EXPERIMENT 4: Go application with multi-stage build"

echo "" | tee -a "$RESULTS_FILE"
echo "=== EXPERIMENT 4: Go Multi-stage (Distroless) ===" | tee -a "$RESULTS_FILE"

docker image rm task-tracker-go:exp4-distroless 2>/dev/null || true

START_TIME=$(date +%s)
log_info "Building Dockerfile.go.multistage..."
docker build -f Dockerfile.go.multistage -t task-tracker-go:exp4-distroless . 2>&1 | tail -5
END_TIME=$(date +%s)

BUILD_TIME=$((END_TIME - START_TIME))
IMAGE_SIZE=$(docker images task-tracker-go:exp4-distroless --format "{{.Size}}")

echo "Build time: ${BUILD_TIME}s" | tee -a "$RESULTS_FILE"
echo "Image size: ${IMAGE_SIZE}" | tee -a "$RESULTS_FILE"

log_success "EXPERIMENT 4 completed"
echo "" | tee -a "$RESULTS_FILE"

# ===== SUMMARY =====
echo "" | tee -a "$RESULTS_FILE"
echo "===============================================" | tee -a "$RESULTS_FILE"
echo "SUMMARY OF ALL IMAGES" | tee -a "$RESULTS_FILE"
echo "===============================================" | tee -a "$RESULTS_FILE"
echo "" | tee -a "$RESULTS_FILE"

docker images | grep "task-tracker" | tee -a "$RESULTS_FILE"

echo "" | tee -a "$RESULTS_FILE"
log_success "All experiments completed! Results saved to $RESULTS_FILE"

# ===== LAYER ANALYSIS =====
log_info "Analyzing image layers..."
echo "" | tee -a "$RESULTS_FILE"
echo "=== LAYER ANALYSIS ===" | tee -a "$RESULTS_FILE"
echo "" | tee -a "$RESULTS_FILE"

echo "Layers in exp1-debian:" | tee -a "$RESULTS_FILE"
docker history task-tracker:exp1-debian | tee -a "$RESULTS_FILE"

echo "" | tee -a "$RESULTS_FILE"
echo "Layers in exp3-alpine-multi:" | tee -a "$RESULTS_FILE"
docker history task-tracker:exp3-alpine-multi | tee -a "$RESULTS_FILE"

echo "" | tee -a "$RESULTS_FILE"
log_success "Experiment script finished!"
