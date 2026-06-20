#!/bin/bash

# ===== Target Node Setup =====
# Машина для розгортання Task Tracker
# Использование: sudo bash setup-target-node.sh
# За основу взят скрипт з Лабораторної роботи №1

set -e

# Параметри
DOCKER_VERSION="latest"
COMPOSE_VERSION="latest"

# Кольори
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Перевірка root
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root"
    exit 1
fi

log_info "Setting up target node for Task Tracker..."

# ===== СИСТЕМНІ ПАКЕТИ =====
log_info "Updating system packages..."
apt-get update
apt-get upgrade -y

log_info "Installing required packages..."
apt-get install -y \
    curl \
    wget \
    git \
    vim \
    nano \
    htop \
    openssh-server \
    openssh-client

# ===== DOCKER =====
log_info "Installing Docker..."
apt-get remove -y docker docker.io || true
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Додати Docker GPG ключ
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Додати Docker репо
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Запустити Docker
systemctl enable docker
systemctl start docker

log_success "Docker installed"

# ===== DOCKER COMPOSE =====
log_info "Installing Docker Compose..."
COMPOSE_URL="https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)"
curl -L "$COMPOSE_URL" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

log_success "Docker Compose installed"

# ===== NGINX =====
log_info "Installing Nginx..."
apt-get install -y nginx

systemctl enable nginx
systemctl start nginx

log_success "Nginx installed"

# ===== КОРИСТУВАЧІ =====
log_info "Creating application users..."

# Користувач для контейнерів
if ! id "docker-app" &>/dev/null; then
    useradd -r -s /bin/false docker-app
    log_success "User docker-app created"
fi

# Користувач для розгортання
if ! id "deploy" &>/dev/null; then
    useradd -m -s /bin/bash deploy
    echo "deploy:deploy123" | chpasswd
    usermod -aG docker deploy
    usermod -aG sudo deploy
    
    # Дозволити SSH без пароля для CI/CD
    mkdir -p /home/deploy/.ssh
    chmod 700 /home/deploy/.ssh
    
    log_success "User deploy created"
fi

# ===== ПАПКИ ПРОЕКТУ =====
log_info "Creating project directories..."

DEPLOY_DIR="/opt/task-tracker"
mkdir -p "$DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR/data"
mkdir -p "$DEPLOY_DIR/logs"

chown -R deploy:deploy "$DEPLOY_DIR"
chmod 755 "$DEPLOY_DIR"

log_success "Project directories created"

# ===== DOCKER CREDENTIALS =====
log_info "Configuring Docker credentials..."

mkdir -p /home/deploy/.docker
cat > /home/deploy/.docker/config.json << 'EOF'
{
  "auths": {},
  "credHelpers": {}
}
EOF

chown -R deploy:deploy /home/deploy/.docker
chmod 600 /home/deploy/.docker/config.json

log_success "Docker credentials configured"

# ===== SSH =====
log_info "Configuring SSH..."

# Дозволити SSH для deploy користувача
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

systemctl restart ssh

log_success "SSH configured"

# ===== FIREWALL (опціонально) =====
log_info "Configuring firewall..."

ufw --force enable || true
ufw default deny incoming || true
ufw default allow outgoing || true
ufw allow 22/tcp || true
ufw allow 80/tcp || true
ufw allow 443/tcp || true

log_success "Firewall configured"

# ===== ПЕРЕВІРКА =====
log_info "Verifying installation..."

docker --version || log_error "Docker not installed"
docker-compose --version || log_error "Docker Compose not installed"
nginx -v || log_error "Nginx not installed"

log_success "All components verified"

cat << 'EOF'

╔═════════════════════════════════════════════════════════════╗
║  Target Node Setup Complete!                               ║
╚═════════════════════════════════════════════════════════════╝

DEPLOYED USERS:
  - deploy (for CI/CD automation)
  - docker-app (for running containers)

DIRECTORIES:
  - /opt/task-tracker/ (project directory)
  - /opt/task-tracker/data/ (persistent data)
  - /opt/task-tracker/logs/ (logs)

SERVICES:
  - Docker (enabled)
  - Nginx (enabled)
  - SSH (enabled)

NEXT STEPS:

1. Configure SSH access from runner:
   Add runner's public key to /home/deploy/.ssh/authorized_keys

2. Create docker-compose.yml in /opt/task-tracker/

3. Set up GitHub Secrets:
   - TARGET_HOST: (this machine's IP)
   - TARGET_USER: deploy
   - TARGET_SSH_KEY: (private SSH key)

4. Test SSH access from runner:
   ssh -i deploy_key deploy@<TARGET_HOST> "docker ps"

SECURITY NOTES:

⚠️  Change default passwords!
⚠️  Configure firewall properly
⚠️  Use SSH key authentication
⚠️  Monitor Docker logs regularly
⚠️  Keep Docker and Nginx updated

EOF

log_success "Setup complete!"
