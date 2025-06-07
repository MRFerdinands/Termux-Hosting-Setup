#!/data/data/com.termux/files/usr/bin/bash

# Termux Laravel Setup - Path Fix Script
# Run this if you encounter path-related issues

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"; }
warn() { echo -e "${YELLOW}[WARNING] $1${NC}"; }
error() { echo -e "${RED}[ERROR] $1${NC}"; }

# Fix common Termux path issues
fix_termux_paths() {
    log "Fixing Termux-specific path issues..."
    
    # Create required directories that might be missing
    mkdir -p "$HOME/.php_sessions"
    mkdir -p "$HOME/.php-fpm"
    mkdir -p "$HOME/.nginx/logs"
    mkdir -p "$PREFIX/var/run/mysqld"
    mkdir -p "$PREFIX/var/run/php-fpm"
    
    # Set proper permissions
    chmod 755 "$HOME/.php_sessions"
    chmod 755 "$HOME/.php-fpm" 
    chmod 755 "$HOME/.nginx"
    chmod 755 "$HOME/.nginx/logs"
    
    log "Termux paths fixed successfully!"
}

# Update PHP configuration for Termux
fix_php_config() {
    log "Updating PHP configuration for Termux..."
    
    PHP_INI="$PREFIX/etc/php.ini"
    
    if [ -f "$PHP_INI" ]; then
        # Update session path to use Termux-compatible directory
        sed -i "s|session.save_path = \"/tmp\"|session.save_path = \"$HOME/.php_sessions\"|g" "$PHP_INI"
        
        # Update other temp paths
        sed -i "s|upload_tmp_dir = /tmp|upload_tmp_dir = $HOME/.php_temp|g" "$PHP_INI"
        
        # Create temp directory
        mkdir -p "$HOME/.php_temp"
        chmod 755 "$HOME/.php_temp"
        
        log "PHP configuration updated for Termux"
    else
        warn "PHP configuration file not found at $PHP_INI"
    fi
}

# Fix MariaDB socket path
fix_mysql_config() {
    log "Fixing MariaDB configuration..."
    
    # Create MariaDB run directory
    mkdir -p "$PREFIX/var/run/mysqld"
    
    # Update MySQL configuration if it exists
    MYSQL_CNF="$PREFIX/etc/mysql/my.cnf"
    if [ -f "$MYSQL_CNF" ]; then
        # Backup original config
        cp "$MYSQL_CNF" "$MYSQL_CNF.backup"
        
        # Update socket path
        sed -i "s|socket.*=.*tmp/mysqld.sock|socket = $PREFIX/var/run/mysqld/mysqld.sock|g" "$MYSQL_CNF"
        
        log "MariaDB configuration updated"
    fi
}

# Fix Nginx configuration
fix_nginx_config() {
    log "Fixing Nginx configuration..."
    
    NGINX_CONF="$PREFIX/etc/nginx/nginx.conf"
    
    if [ -f "$NGINX_CONF" ]; then
        # Backup original config
        cp "$NGINX_CONF" "$NGINX_CONF.backup"
        
        # Update paths to use Termux-compatible directories
        sed -i "s|/tmp/|$HOME/.nginx/|g" "$NGINX_CONF"
        
        log "Nginx configuration updated"
    fi
}

# Create a simple installation script that works in Termux
create_simple_installer() {
    log "Creating Termux-compatible installer..."
    
    cat > "$HOME/laravel-setup-simple.sh" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

# Simple Laravel Setup for Termux
# This version avoids common path issues

set -e

log() { echo "[$(date +'%H:%M:%S')] $1"; }

log "Starting simple Laravel setup..."

# Update packages
log "Updating packages..."
pkg update -y && pkg upgrade -y

# Install required packages
log "Installing packages..."
pkg install -y php nginx mariadb git curl wget unzip nodejs npm

# Install Composer
log "Installing Composer..."
cd "$HOME"
curl -sS https://getcomposer.org/installer | php
mv composer.phar "$PREFIX/bin/composer"
chmod +x "$PREFIX/bin/composer"

# Create project directory
log "Creating project structure..."
mkdir -p "$HOME/laravel-projects"
cd "$HOME/laravel-projects"

# Install Laravel
log "Installing Laravel..."
composer create-project laravel/laravel default

# Basic Nginx setup
log "Configuring Nginx..."
mkdir -p "$HOME/.nginx/logs"

cat > "$PREFIX/etc/nginx/nginx.conf" << 'NGINX_EOF'
worker_processes 1;
pid /data/data/com.termux/files/home/.nginx/nginx.pid;
error_log /data/data/com.termux/files/home/.nginx/logs/error.log;

events {
    worker_connections 1024;
}

http {
    include /data/data/com.termux/files/usr/etc/nginx/mime.types;
    default_type application/octet-stream;
    
    access_log /data/data/com.termux/files/home/.nginx/logs/access.log;
    
    server {
        listen 8080;
        root /data/data/com.termux/files/home/laravel-projects/default/public;
        index index.php index.html;
        
        location / {
            try_files $uri $uri/ /index.php?$query_string;
        }
        
        location ~ \.php$ {
            include /data/data/com.termux/files/usr/etc/nginx/fastcgi_params;
            fastcgi_pass 127.0.0.1:9000;
            fastcgi_index index.php;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        }
    }
}
NGINX_EOF

# Basic PHP-FPM setup
log "Configuring PHP-FPM..."
mkdir -p "$HOME/.php-fpm"

cat > "$PREFIX/etc/php-fpm.conf" << 'PHP_EOF'
[global]
pid = /data/data/com.termux/files/home/.php-fpm/php-fpm.pid
error_log = /data/data/com.termux/files/home/.php-fpm/php-fpm.log

[www]
user = nobody
group = nobody
listen = 127.0.0.1:9000
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
PHP_EOF

# Initialize MariaDB
log "Setting up MariaDB..."
mysql_install_db

# Create startup script
cat > "$HOME/start-laravel.sh" << 'START_EOF'
#!/data/data/com.termux/files/usr/bin/bash

echo "Starting Laravel services..."

# Start MariaDB
if ! pgrep mysqld > /dev/null; then
    echo "Starting MariaDB..."
    mysqld_safe --datadir="$PREFIX/var/lib/mysql" &
    sleep 3
fi

# Start PHP-FPM
if ! pgrep php-fpm > /dev/null; then
    echo "Starting PHP-FPM..."
    php-fpm -D
    sleep 2
fi

# Start Nginx
if ! pgrep nginx > /dev/null; then
    echo "Starting Nginx..."
    nginx
fi

echo "Laravel environment started!"
echo "Visit: http://localhost:8080"
START_EOF

chmod +x "$HOME/start-laravel.sh"

log "Setup completed!"
log "Run: ~/start-laravel.sh to start services"
log "Visit: http://localhost:8080"
EOF

    chmod +x "$HOME/laravel-setup-simple.sh"
    
    log "Simple installer created at: ~/laravel-setup-simple.sh"
}

# Main function
main() {
    log "Termux Laravel Setup - Path Fix Utility"
    echo
    
    fix_termux_paths
    fix_php_config
    fix_mysql_config
    fix_nginx_config
    create_simple_installer
    
    echo
    log "Path fixes completed!"
    echo
    log "If you're still having issues, try the simple installer:"
    log "  ~/laravel-setup-simple.sh"
    echo
    log "Or run the original setup with Termux-specific paths:"
    log "  curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/laravel-termux-setup/main/setup-laravel.sh | bash"
}

main "$@"
