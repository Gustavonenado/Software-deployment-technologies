#!/bin/bash

# ===== GitHub Actions Self-Hosted Runner Setup =====
# Використання: bash setup-runner.sh
# Потрібно: Ubuntu 22.04+ та доступ в інтернет

set -e

# Кольори
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Перевірка прав root
if [[ $EUID -ne 0 ]]; then
    log_warn "This script should be run as root"
    exit 1
fi

log_info "Setting up GitHub Actions self-hosted runner..."

# Оновлення систем
log_info "Updating system packages..."
apt-get update
apt-get upgrade -y

# Встановлення необхідних пакетів
log_info "Installing dependencies..."
apt-get install -y \
    curl \
    wget \
    git \
    jq \
    build-essential \
    libssl-dev \
    libffi-dev \
    python3-dev \
    python3-pip \
    docker.io \
    docker-compose

# Встановлення Node.js (для workflow)
log_info "Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Crear користувача для runner
log_info "Creating runner user..."
if ! id "runner" &>/dev/null; then
    useradd -m -s /bin/bash runner
    usermod -aG docker runner
    usermod -aG sudo runner
    echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/runner
    chmod 0440 /etc/sudoers.d/runner
    log_success "Runner user created"
else
    log_warn "Runner user already exists"
fi

# Встановлення Docker daemon як сервісу
log_info "Configuring Docker..."
systemctl enable docker
systemctl start docker

# Завантаження runner software
log_info "Downloading GitHub Actions runner..."
RUNNER_VERSION="2.310.1"
RUNNER_DIR="/home/runner/actions-runner"

mkdir -p "$RUNNER_DIR"
cd "$RUNNER_DIR"

# Завантажити потрібну версію
if [ ! -f "config.sh" ]; then
    DOWNLOAD_URL="https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"
    curl -L "$DOWNLOAD_URL" -o runner.tar.gz
    tar xzf runner.tar.gz
    rm runner.tar.gz
    log_success "Runner downloaded"
else
    log_warn "Runner already installed"
fi

# Установити залежності runner
log_info "Installing runner dependencies..."
"$RUNNER_DIR/bin/installdependencies.sh"

# Встановлення прав
chown -R runner:runner "$RUNNER_DIR"

log_success "Runner installation complete!"

cat << 'EOF'

╔═══════════════════════════════════════════════════════════╗
║  GitHub Actions Self-Hosted Runner Setup Complete        ║
╚═══════════════════════════════════════════════════════════╝

NEXT STEPS (Run as 'runner' user):

1. Login as runner:
   sudo -u runner -H bash

2. Go to runner directory:
   cd /home/runner/actions-runner

3. Configure runner (visit GitHub → Settings → Actions → Runners):
   ./config.sh

4. Start runner:
   ./run.sh

5. (Optional) Register as service:
   sudo ./svc.sh install
   sudo ./svc.sh start

IMPORTANT SECURITY NOTES:

⚠️  NEVER commit the runner token to Git!
⚠️  NEVER share the runner token!
⚠️  Only keep runner online when building!
⚠️  Delete runner after use for security!

For uninstalling:
  sudo ./svc.sh stop
  sudo ./svc.sh uninstall
  sudo userdel -r runner
  sudo rm -rf /home/runner

EOF

log_success "Setup complete! Follow the next steps above."
