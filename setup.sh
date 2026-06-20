#!/bin/bash
#
# Автоматизаційний скрипт розгортання Task Tracker Web Application
# Запуск з правами root: sudo bash setup.sh
#

set -e

# Параметри
DB_HOST="127.0.0.1"
DB_USER="mywebapp"
DB_PASSWORD="mywebapp_pass_$(date +%s)"
DB_NAME="mywebapp"
APP_NAME="mywebapp"
APP_USER="app"
APP_HOME="/opt/mywebapp"
APP_PORT="8080"
GRADEBOOK="/home/student/gradebook"
GRADEBOOK_NUMBER="10"

# Кольори для вивода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функції
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Цей скрипт повинен запускатися з правами root"
        exit 1
    fi
}

install_packages() {
    log_info "Встановлення необхідних пакетів..."
    apt-get update
    apt-get install -y \
        python3 \
        python3-pip \
        nginx \
        mariadb-server \
        git \
        curl \
        wget \
        vim \
        sudo
    log_info "✓ Пакети встановлені"
}

create_users() {
    log_info "Створення користувачів системи..."
    
    # Користувач для застосунку
    if ! id "$APP_USER" &>/dev/null; then
        useradd -r -s /bin/false "$APP_USER"
        log_info "✓ Користувач $APP_USER створений"
    fi
    
    # Користувач student
    if ! id "student" &>/dev/null; then
        useradd -m -s /bin/bash student
        echo "student:12345678" | chpasswd
        usermod -aG sudo student
        log_info "✓ Користувач student створений (пароль: 12345678)"
    fi
    
    # Користувач teacher
    if ! id "teacher" &>/dev/null; then
        useradd -m -s /bin/bash teacher
        echo "teacher:12345678" | chpasswd
        usermod -aG sudo teacher
        log_info "✓ Користувач teacher створений (пароль: 12345678)"
    fi
    
    # Користувач operator
    if ! id "operator" &>/dev/null; then
        useradd -m -s /bin/bash operator
        echo "operator:12345678" | chpasswd
        log_info "✓ Користувач operator створений (пароль: 12345678)"
    fi
}

configure_sudo() {
    log_info "Налаштування sudo для operator..."
    
    # Видалити попередній sudoers файл для operator якщо існує
    rm -f /etc/sudoers.d/operator
    
    # Створити новий sudoers файл
    cat > /etc/sudoers.d/operator << 'EOF'
operator ALL=(ALL) NOPASSWD: /bin/systemctl start mywebapp.service
operator ALL=(ALL) NOPASSWD: /bin/systemctl stop mywebapp.service
operator ALL=(ALL) NOPASSWD: /bin/systemctl restart mywebapp.service
operator ALL=(ALL) NOPASSWD: /bin/systemctl status mywebapp.service
operator ALL=(ALL) NOPASSWD: /bin/systemctl reload nginx
EOF
    
    chmod 440 /etc/sudoers.d/operator
    log_info "✓ Sudoers для operator налаштовані"
}

setup_database() {
    log_info "Налаштування MariaDB..."
    
    # Запуск MariaDB
    systemctl restart mariadb
    sleep 2
    
    # Створення БД та користувача
    mysql -u root << EOSQL
CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOSQL
    
    log_info "✓ База даних створена"
    log_info "  БД: $DB_NAME"
    log_info "  Користувач: $DB_USER"
}

setup_application() {
    log_info "Встановлення застосунку..."
    
    # Створення директорії застосунку
    mkdir -p "$APP_HOME"
    
    # Копіювання файлів застосунку
    if [ -f "./app.py" ]; then
        cp app.py "$APP_HOME/"
        cp migrate_db.py "$APP_HOME/"
        cp requirements.txt "$APP_HOME/"
        chmod +x "$APP_HOME/app.py"
        chmod +x "$APP_HOME/migrate_db.py"
    else
        log_warn "Файли застосунку не знайдені. Переконайтеся, що ви в правильній директорії"
    fi
    
    # Встановлення Python залежностей
    pip3 install -q -r "$APP_HOME/requirements.txt"
    
    # Встановлення прав доступу
    chown -R "$APP_USER:$APP_USER" "$APP_HOME"
    chmod 750 "$APP_HOME"
    
    log_info "✓ Застосунок встановлений в $APP_HOME"
}

run_migrations() {
    log_info "Запуск міграції бази даних..."
    
    python3 "$APP_HOME/migrate_db.py" \
        --db-host "$DB_HOST" \
        --db-user "$DB_USER" \
        --db-password "$DB_PASSWORD" \
        --db-name "$DB_NAME"
    
    log_info "✓ Міграція завершена"
}

setup_systemd() {
    log_info "Налаштування systemd unit файлу..."
    
    cat > /etc/systemd/system/mywebapp.service << EOF
[Unit]
Description=MyWebApp Task Tracker Service
After=network.target mariadb.service

[Service]
Type=notify
User=$APP_USER
Group=$APP_USER
WorkingDirectory=$APP_HOME
Environment="PYTHONUNBUFFERED=1"
ExecStartPre=$APP_HOME/migrate_db.py --db-host $DB_HOST --db-user $DB_USER --db-password $DB_PASSWORD --db-name $DB_NAME
ExecStart=/usr/bin/python3 $APP_HOME/app.py --host 127.0.0.1 --port $APP_PORT --db-host $DB_HOST --db-user $DB_USER --db-password $DB_PASSWORD --db-name $DB_NAME
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    log_info "✓ Systemd unit файл налаштований"
}

setup_nginx() {
    log_info "Налаштування nginx reverse proxy..."
    
    # Видалення дефолтної конфігурації
    rm -f /etc/nginx/sites-enabled/default
    
    # Створення конфігурації для застосунку
    cat > /etc/nginx/sites-available/mywebapp << 'EOF'
upstream mywebapp_backend {
    server 127.0.0.1:8080;
}

server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;

    access_log /var/log/nginx/mywebapp_access.log;
    error_log /var/log/nginx/mywebapp_error.log;

    # Кореневий ендпоінт
    location = / {
        proxy_pass http://mywebapp_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # Health endpoints
    location ~ ^/health/(alive|ready)$ {
        proxy_pass http://mywebapp_backend;
        proxy_set_header Host $host;
        access_log off;
    }

    # API endpoints для задач
    location ~ ^/tasks(/|$) {
        proxy_pass http://mywebapp_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Accept $http_accept;
    }

    # Блокування всіх інших запитів
    location ~ ^/(?!health|tasks|$) {
        return 404;
    }
}
EOF
    
    ln -sf /etc/nginx/sites-available/mywebapp /etc/nginx/sites-enabled/mywebapp
    
    # Перевірка конфігурації
    nginx -t
    
    systemctl restart nginx
    log_info "✓ Nginx налаштований"
}

start_service() {
    log_info "Запуск застосунку..."
    
    systemctl enable mywebapp.service
    systemctl start mywebapp.service
    
    # Очікування на запуск
    sleep 3
    
    # Перевірка статусу
    if systemctl is-active --quiet mywebapp.service; then
        log_info "✓ Застосунок запущений"
    else
        log_error "Не вдалося запустити застосунок"
        systemctl status mywebapp.service
        exit 1
    fi
}

disable_default_user() {
    log_info "Блокування дефолтного користувача..."
    
    # Блокування root користувача для SSH
    if [ -f "/root/.ssh/authorized_keys" ]; then
        rm -f /root/.ssh/authorized_keys
    fi
    
    # Блокування дефолтних користувачів якщо вони існують
    for user in ubuntu debian centos fedora; do
        if id "$user" &>/dev/null; then
            usermod -L "$user"
        fi
    done
    
    log_info "✓ Дефолтні користувачі заблоковані"
}

create_gradebook() {
    log_info "Створення файлу градуса (gradebook)..."
    
    mkdir -p /home/student
    echo "$GRADEBOOK_NUMBER" > "$GRADEBOOK"
    chown student:student "$GRADEBOOK"
    chmod 644 "$GRADEBOOK"
    
    log_info "✓ Файл $GRADEBOOK створений з значенням $GRADEBOOK_NUMBER"
}

print_summary() {
    log_info ""
    log_info "╔════════════════════════════════════════════════════════╗"
    log_info "║  РОЗГОРТАННЯ ЗАВЕРШЕНО УСПІШНО                        ║"
    log_info "╚════════════════════════════════════════════════════════╝"
    log_info ""
    log_info "📋 ПАРАМЕТРИ СИСТЕМИ:"
    log_info "  • Застосунок: $APP_NAME"
    log_info "  • Адреса: http://localhost/ (через nginx)"
    log_info "  • Внутрішній порт: $APP_PORT"
    log_info "  • Бази даних: $DB_NAME"
    log_info ""
    log_info "👥 КОРИСТУВАЧІ:"
    log_info "  • student   (пароль: 12345678) - розробник"
    log_info "  • teacher   (пароль: 12345678) - перевіркар"
    log_info "  • operator  (пароль: 12345678) - оператор (обмежені права)"
    log_info "  • app       - системний користувач"
    log_info ""
    log_info "🔐 БАЗА ДАНИХ:"
    log_info "  • БД: $DB_NAME"
    log_info "  • Користувач: $DB_USER"
    log_info "  • Пароль: $DB_PASSWORD"
    log_info ""
    log_info "🔗 КОМАНДИ ДЛЯ ПЕРЕВІРКИ:"
    log_info "  • curl http://localhost/"
    log_info "  • curl http://localhost/tasks"
    log_info "  • curl http://localhost/health/alive"
    log_info "  • systemctl status mywebapp"
    log_info ""
}

# Основна послідовність
main() {
    log_info "Розпочато розгортання Task Tracker..."
    log_info ""
    
    check_root
    install_packages
    create_users
    configure_sudo
    setup_database
    setup_application
    run_migrations
    setup_systemd
    setup_nginx
    start_service
    disable_default_user
    create_gradebook
    print_summary
}

# Запуск
main
