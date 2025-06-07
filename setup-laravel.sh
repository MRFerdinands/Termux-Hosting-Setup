#!/data/data/com.termux/files/usr/bin/bash

# Laravel Multi-Path Hosting Environment Setup for Termux
# This script sets up PHP, Nginx, MySQL, Composer, and Laravel with support for multiple projects

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Check if running in Termux
check_termux() {
    if [ ! -d "/data/data/com.termux" ]; then
        error "This script is designed for Termux environment only!"
        exit 1
    fi
}

# Update packages
update_packages() {
    log "Updating package lists..."
    pkg update -y
    pkg upgrade -y
}

# Install required packages
install_packages() {
    log "Installing required packages..."
    
    # Essential packages
    pkg install -y \
        php \
        php-fpm \
        nginx \
        mariadb \
        nodejs \
        npm \
        git \
        curl \
        wget \
        unzip \
        openssh \
        termux-services \
        coreutils
    
    # PHP extensions
    pkg install -y \
        php-apache \
        php-pgsql \
        php-mysql \
        php-sqlite \
        php-redis \
        php-imagick \
        php-gd \
        php-intl \
        php-zip \
        php-curl \
        php-xml \
        php-mbstring \
        php-json \
        php-bcmath \
        php-tokenizer \
        php-fileinfo \
        php-openssl \
        php-pdo
}

# Install Composer
install_composer() {
    log "Installing Composer..."
    
    cd $HOME
    
    # Download and install Composer
    curl -sS https://getcomposer.org/installer | php
    mv composer.phar $PREFIX/bin/composer
    chmod +x $PREFIX/bin/composer
    
    # Verify installation
    composer --version
    log "Composer installed successfully!"
}

# Configure PHP
configure_php() {
    log "Configuring PHP..."
    
    # PHP configuration file
    PHP_INI="$PREFIX/etc/php.ini"
    
    # Backup original php.ini
    if [ -f "$PHP_INI" ]; then
        cp "$PHP_INI" "$PHP_INI.backup"
    fi
    
    # Update PHP settings
    cat > "$PHP_INI" << 'EOF'
[PHP]
engine = On
short_open_tag = Off
precision = 14
output_buffering = 4096
zlib.output_compression = Off
implicit_flush = Off
unserialize_callback_func =
serialize_precision = -1
disable_functions =
disable_classes =
zend.enable_gc = On
expose_php = Off
max_execution_time = 300
max_input_time = 60
memory_limit = 512M
error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT
display_errors = On
display_startup_errors = On
log_errors = On
log_errors_max_len = 1024
ignore_repeated_errors = Off
ignore_repeated_source = Off
report_memleaks = On
html_errors = On
variables_order = "GPCS"
request_order = "GP"
register_argc_argv = Off
auto_globals_jit = On
post_max_size = 100M
auto_prepend_file =
auto_append_file =
default_mimetype = "text/html"
default_charset = "UTF-8"
doc_root =
user_dir =
enable_dl = Off
file_uploads = On
upload_max_filesize = 100M
max_file_uploads = 20
allow_url_fopen = On
allow_url_include = Off
default_socket_timeout = 60
extension=zip
extension=gd
extension=pdo_mysql
extension=pdo_sqlite
extension=mysqli
extension=curl
extension=mbstring
extension=xml
extension=json
extension=bcmath
extension=tokenizer
extension=fileinfo
extension=openssl
extension=intl

[Date]
date.timezone = Asia/Jakarta

[Session]
session.save_handler = files
session.save_path = "/data/data/com.termux/files/home/.php_sessions"
session.use_strict_mode = 0
session.use_cookies = 1
session.use_only_cookies = 1
session.name = PHPSESSID
session.auto_start = 0
session.cookie_lifetime = 0
session.cookie_path = /
session.cookie_domain =
session.cookie_httponly =
session.serialize_handler = php
session.gc_probability = 0
session.gc_divisor = 1000
session.gc_maxlifetime = 1440
session.referer_check =
session.cache_limiter = nocache
session.cache_expire = 180
session.use_trans_sid = 0
session.hash_function = 0
session.hash_bits_per_character = 5
url_rewriter.tags = "a=href,area=href,frame=src,input=src,form=fakeentry"
EOF

    # Create session directory
    mkdir -p "$HOME/.php_sessions"
    chmod 755 "$HOME/.php_sessions"
    
    log "PHP configured successfully!"
}

# Configure PHP-FPM
configure_php_fpm() {
    log "Configuring PHP-FPM..."
    
    # Create PHP-FPM configuration directory
    mkdir -p "$PREFIX/etc/php-fpm.d"
    
    # Main PHP-FPM configuration
    cat > "$PREFIX/etc/php-fpm.conf" << 'EOF'
[global]
pid = /data/data/com.termux/files/home/.php-fpm/php-fpm.pid
error_log = /data/data/com.termux/files/home/.php-fpm/php-fpm.log
log_level = notice
emergency_restart_threshold = 10
emergency_restart_interval = 1m
process_control_timeout = 10s
daemonize = yes

include=/data/data/com.termux/files/usr/etc/php-fpm.d/*.conf
EOF

    # Pool configuration
    cat > "$PREFIX/etc/php-fpm.d/www.conf" << 'EOF'
[www]
user = nobody
group = nobody
listen = 127.0.0.1:9000
listen.owner = nobody
listen.group = nobody
listen.mode = 0660
pm = dynamic
pm.max_children = 20
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
pm.max_requests = 500
request_terminate_timeout = 300s
rlimit_files = 1024
rlimit_core = 0
catch_workers_output = yes
security.limit_extensions = .php .php3 .php4 .php5 .php7 .php8
php_admin_value[sendmail_path] = /data/data/com.termux/files/usr/sbin/sendmail -t -i -f www@my.domain.com
php_flag[display_errors] = on
php_admin_value[error_log] = /data/data/com.termux/files/home/.php-fpm/www-error.log
php_admin_flag[log_errors] = on
php_admin_value[memory_limit] = 512M
php_admin_value[upload_max_filesize] = 100M
php_admin_value[post_max_size] = 100M
php_admin_value[max_execution_time] = 300
EOF

    # Create PHP-FPM directories
    mkdir -p "$HOME/.php-fpm"
    
    log "PHP-FPM configured successfully!"
}

# Configure Nginx
configure_nginx() {
    log "Configuring Nginx..."
    
    # Create necessary directories
    mkdir -p "$HOME/laravel-projects"
    mkdir -p "$PREFIX/etc/nginx/sites-available"
    mkdir -p "$PREFIX/etc/nginx/sites-enabled"
    mkdir -p "$HOME/.nginx/logs"
    
    # Main Nginx configuration
    cat > "$PREFIX/etc/nginx/nginx.conf" << 'EOF'
worker_processes auto;
pid /data/data/com.termux/files/home/.nginx/nginx.pid;
error_log /data/data/com.termux/files/home/.nginx/logs/error.log;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    include       /data/data/com.termux/files/usr/etc/nginx/mime.types;
    default_type  application/octet-stream;

    # Logging Settings
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /data/data/com.termux/files/home/.nginx/logs/access.log main;

    # Basic Settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;
    client_max_body_size 100M;

    # Gzip Settings
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;

    # Include site configurations
    include /data/data/com.termux/files/usr/etc/nginx/sites-enabled/*;
}
EOF

    # Default server configuration (will be used as template)
    cat > "$PREFIX/etc/nginx/sites-available/default" << 'EOF'
server {
    listen 8080 default_server;
    listen [::]:8080 default_server;
    
    root /data/data/com.termux/files/home/laravel-projects/default/public;
    index index.php index.html index.htm;
    
    server_name _;

    # Laravel routes
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    # PHP-FPM Configuration
    location ~ \.php$ {
        include /data/data/com.termux/files/usr/etc/nginx/fastcgi_params;
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
        fastcgi_param PATH_TRANSLATED $document_root$fastcgi_path_info;
        fastcgi_param HTTPS off;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_read_timeout 300;
        fastcgi_buffer_size 128k;
        fastcgi_buffers 4 256k;
        fastcgi_busy_buffers_size 256k;
    }

    # Security headers
    location ~ /\.ht {
        deny all;
    }
    
    location ~ /\.(?!well-known).* {
        deny all;
    }
    
    # Static files caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|pdf|txt)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

    # Enable default site
    ln -sf "$PREFIX/etc/nginx/sites-available/default" "$PREFIX/etc/nginx/sites-enabled/"
    
    log "Nginx configured successfully!"
}

# Configure MySQL/MariaDB
configure_mysql() {
    log "Configuring MariaDB..."
    
    # Initialize database
    mysql_install_db
    
    # Start MariaDB temporarily for initial setup
    mysqld_safe --datadir="$PREFIX/var/lib/mysql" --socket="$PREFIX/var/run/mysqld/mysqld.sock" &
    MYSQL_PID=$!
    
    # Wait for MySQL to start
    sleep 10
    
    # Secure installation
    mysql -u root << 'EOF'
UPDATE mysql.user SET Password=PASSWORD('laravel123') WHERE User='root';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
CREATE DATABASE laravel_default CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
FLUSH PRIVILEGES;
EOF

    # Stop temporary MySQL instance
    kill $MYSQL_PID 2>/dev/null || true
    sleep 5
    
    log "MariaDB configured successfully!"
    log "Root password set to: laravel123"
    log "Default database created: laravel_default"
}

# Install Laravel
install_laravel() {
    log "Installing Laravel..."
    
    # Install Laravel installer globally
    composer global require laravel/installer
    
    # Add Composer global bin to PATH if not already added
    if ! grep -q 'composer/vendor/bin' ~/.bashrc; then
        echo 'export PATH="$HOME/.config/composer/vendor/bin:$PATH"' >> ~/.bashrc
    fi
    
    # Create default Laravel project
    cd "$HOME/laravel-projects"
    composer create-project laravel/laravel default
    
    # Set proper permissions
    cd default
    chmod -R 755 storage bootstrap/cache
    
    # Create environment file
    cp .env.example .env
    
    # Generate application key
    php artisan key:generate
    
    # Configure database in .env
    sed -i 's/DB_CONNECTION=sqlite/DB_CONNECTION=mysql/' .env
    sed -i 's/DB_HOST=127.0.0.1/DB_HOST=127.0.0.1/' .env
    sed -i 's/DB_PORT=3306/DB_PORT=3306/' .env
    sed -i 's/DB_DATABASE=laravel/DB_DATABASE=laravel_default/' .env
    sed -i 's/DB_USERNAME=root/DB_USERNAME=root/' .env
    sed -i 's/DB_PASSWORD=/DB_PASSWORD=laravel123/' .env
    
    log "Default Laravel project created successfully!"
}

# Create management scripts
create_scripts() {
    log "Creating management scripts..."
    
    # Laravel project manager script
    cat > "$HOME/laravel-manager.sh" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

# Laravel Multi-Project Manager
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PROJECTS_DIR="$HOME/laravel-projects"
NGINX_SITES_AVAILABLE="$PREFIX/etc/nginx/sites-available"
NGINX_SITES_ENABLED="$PREFIX/etc/nginx/sites-enabled"

log() { echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"; }
warn() { echo -e "${YELLOW}[WARNING] $1${NC}"; }
error() { echo -e "${RED}[ERROR] $1${NC}"; }

create_project() {
    local project_name="$1"
    local port="$2"
    
    if [ -z "$project_name" ]; then
        error "Project name is required!"
        exit 1
    fi
    
    if [ -z "$port" ]; then
        port=8080
    fi
    
    log "Creating Laravel project: $project_name on port $port"
    
    # Create project directory
    cd "$PROJECTS_DIR"
    composer create-project laravel/laravel "$project_name"
    
    # Configure project
    cd "$project_name"
    cp .env.example .env
    php artisan key:generate
    
    # Create database
    mysql -u root -plaravel123 -e "CREATE DATABASE laravel_${project_name} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    
    # Update .env file
    sed -i "s/DB_DATABASE=laravel/DB_DATABASE=laravel_${project_name}/" .env
    sed -i 's/DB_USERNAME=root/DB_USERNAME=root/' .env
    sed -i 's/DB_PASSWORD=/DB_PASSWORD=laravel123/' .env
    
    # Set permissions
    chmod -R 755 storage bootstrap/cache
    
    # Create Nginx configuration
    cat > "$NGINX_SITES_AVAILABLE/$project_name" << EOL
server {
    listen $port;
    listen [::]:$port;
    
    root $PROJECTS_DIR/$project_name/public;
    index index.php index.html index.htm;
    
    server_name localhost;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include $PREFIX/etc/nginx/fastcgi_params;
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
        fastcgi_param PATH_TRANSLATED \$document_root\$fastcgi_path_info;
        fastcgi_param HTTPS off;
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_read_timeout 300;
        fastcgi_buffer_size 128k;
        fastcgi_buffers 4 256k;
        fastcgi_busy_buffers_size 256k;
    }

    location ~ /\.ht {
        deny all;
    }
    
    location ~ /\.(?!well-known).* {
        deny all;
    }
    
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|pdf|txt)\$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOL
    
    # Enable site
    ln -sf "$NGINX_SITES_AVAILABLE/$project_name" "$NGINX_SITES_ENABLED/"
    
    # Reload Nginx
    nginx -s reload 2>/dev/null || true
    
    log "Project '$project_name' created successfully!"
    log "Access it at: http://localhost:$port"
    log "Database: laravel_${project_name}"
}

remove_project() {
    local project_name="$1"
    
    if [ -z "$project_name" ]; then
        error "Project name is required!"
        exit 1
    fi
    
    warn "This will permanently delete the project '$project_name'. Are you sure? (y/N)"
    read -r confirm
    
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        log "Operation cancelled."
        exit 0
    fi
    
    # Remove project directory
    rm -rf "$PROJECTS_DIR/$project_name"
    
    # Remove Nginx configuration
    rm -f "$NGINX_SITES_AVAILABLE/$project_name"
    rm -f "$NGINX_SITES_ENABLED/$project_name"
    
    # Drop database
    mysql -u root -plaravel123 -e "DROP DATABASE IF EXISTS laravel_${project_name};" 2>/dev/null || true
    
    # Reload Nginx
    nginx -s reload 2>/dev/null || true
    
    log "Project '$project_name' removed successfully!"
}

list_projects() {
    log "Available Laravel projects:"
    echo
    
    if [ -d "$PROJECTS_DIR" ]; then
        for project in "$PROJECTS_DIR"/*; do
            if [ -d "$project" ] && [ -f "$project/artisan" ]; then
                project_name=$(basename "$project")
                if [ -f "$NGINX_SITES_ENABLED/$project_name" ]; then
                    port=$(grep -o 'listen [0-9]*' "$NGINX_SITES_ENABLED/$project_name" | head -1 | awk '{print $2}')
                    echo "  ✓ $project_name (http://localhost:$port)"
                else
                    echo "  ✗ $project_name (not enabled)"
                fi
            fi
        done
    fi
    echo
}

show_help() {
    echo "Laravel Multi-Project Manager"
    echo
    echo "Usage: $0 [command] [options]"
    echo
    echo "Commands:"
    echo "  create <name> [port]  Create a new Laravel project"
    echo "  remove <name>         Remove a Laravel project"
    echo "  list                  List all projects"
    echo "  help                  Show this help"
    echo
    echo "Examples:"
    echo "  $0 create myapp 8081"
    echo "  $0 create blog"
    echo "  $0 remove myapp"
    echo "  $0 list"
}

case "${1:-help}" in
    create)
        create_project "$2" "$3"
        ;;
    remove)
        remove_project "$2"
        ;;
    list)
        list_projects
        ;;
    help|*)
        show_help
        ;;
esac
EOF

    chmod +x "$HOME/laravel-manager.sh"
    
    # Server management script
    cat > "$HOME/laravel-server.sh" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

# Laravel Server Manager
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"; }
warn() { echo -e "${YELLOW}[WARNING] $1${NC}"; }
error() { echo -e "${RED}[ERROR] $1${NC}"; }

start_services() {
    log "Starting Laravel hosting services..."
    
    # Start MariaDB
    if ! pgrep mysqld > /dev/null; then
        log "Starting MariaDB..."
        mysqld_safe --datadir="$PREFIX/var/lib/mysql" --socket="$PREFIX/var/run/mysqld/mysqld.sock" &
        sleep 3
    else
        log "MariaDB is already running"
    fi
    
    # Start PHP-FPM
    if ! pgrep php-fpm > /dev/null; then
        log "Starting PHP-FPM..."
        php-fpm -D
        sleep 2
    else
        log "PHP-FPM is already running"
    fi
    
    # Start Nginx
    if ! pgrep nginx > /dev/null; then
        log "Starting Nginx..."
        nginx
        sleep 2
    else
        log "Nginx is already running"
    fi
    
    log "All services started successfully!"
    log "Default site: http://localhost:8080"
}

stop_services() {
    log "Stopping Laravel hosting services..."
    
    # Stop Nginx
    if pgrep nginx > /dev/null; then
        nginx -s quit
        log "Nginx stopped"
    fi
    
    # Stop PHP-FPM
    if pgrep php-fpm > /dev/null; then
        pkill php-fpm
        log "PHP-FPM stopped"
    fi
    
    # Stop MariaDB
    if pgrep mysqld > /dev/null; then
        mysqladmin -u root -plaravel123 shutdown
        log "MariaDB stopped"
    fi
    
    log "All services stopped"
}

restart_services() {
    log "Restarting services..."
    stop_services
    sleep 3
    start_services
}

status_services() {
    log "Service Status:"
    echo
    
    if pgrep mysqld > /dev/null; then
        echo "  ✓ MariaDB: Running"
    else
        echo "  ✗ MariaDB: Stopped"
    fi
    
    if pgrep php-fpm > /dev/null; then
        echo "  ✓ PHP-FPM: Running"
    else
        echo "  ✗ PHP-FPM: Stopped"
    fi
    
    if pgrep nginx > /dev/null; then
        echo "  ✓ Nginx: Running"
    else
        echo "  ✗ Nginx: Stopped"
    fi
    echo
}

show_help() {
    echo "Laravel Server Manager"
    echo
    echo "Usage: $0 [command]"
    echo
    echo "Commands:"
    echo "  start     Start all services"
    echo "  stop      Stop all services"
    echo "  restart   Restart all services"
    echo "  status    Show service status"
    echo "  help      Show this help"
}

case "${1:-help}" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    status)
        status_services
        ;;
    help|*)
        show_help
        ;;
esac
EOF

    chmod +x "$HOME/laravel-server.sh"
    
    log "Management scripts created successfully!"
}

# Create shortcuts
create_shortcuts() {
    log "Creating command shortcuts..."
    
    # Add aliases to .bashrc
    cat >> ~/.bashrc << 'EOF'

# Laravel Development Shortcuts
alias laravel-server='~/laravel-server.sh'
alias laravel-project='~/laravel-manager.sh'
alias laravel-start='~/laravel-server.sh start'
alias laravel-stop='~/laravel-server.sh stop'
alias laravel-status='~/laravel-server.sh status'
alias laravel-restart='~/laravel-server.sh restart'
EOF

    log "Shortcuts added to .bashrc"
    log "Reload terminal or run: source ~/.bashrc"
}

# Main installation function
main() {
    log "Starting Laravel Multi-Path Hosting Environment Setup..."
    
    check_termux
    update_packages
    install_packages
    install_composer
    configure_php
    configure_php_fpm
    configure_nginx
    configure_mysql
    install_laravel
    create_scripts
    create_shortcuts
    
    log "Setup completed successfully!"
    echo
    info "=== Setup Summary ==="
    info "✓ PHP 8.x with extensions installed"
    info "✓ Nginx web server configured"
    info "✓ MariaDB database server configured"
    info "✓ Composer installed globally"
    info "✓ Laravel installed with default project"
    info "✓ Management scripts created"
    echo
    info "=== Default Credentials ==="
    info "MySQL Root Password: laravel123"
    info "Default Database: laravel_default" 
    info "Default Site: http://localhost:8080"
    echo
    info "=== Management Commands ==="
    info "Start services: laravel-start"
    info "Stop services: laravel-stop"
    info "Service status: laravel-status"
    info "Manage projects: laravel-project"
    echo
    info "=== Quick Start ==="
    info "1. Reload terminal: source ~/.bashrc"
    info "2. Start services: laravel-start"
    info "3. Create new project: laravel-project create myapp 8081"
    info "4. Visit: http://localhost:8080 (default) or http://localhost:8081 (new project)"
    echo
    warn "Remember to start services after device reboot!"
    log "Happy coding! 🚀"
}

# Run main function
main "$@"
