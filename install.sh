#!/data/data/com.termux/files/usr/bin/bash

# Laravel Termux Setup - One-line Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/laravel-termux-setup/main/install.sh | bash

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# GitHub repository details (update these)
GITHUB_USER="YOUR_USERNAME"
REPO_NAME="laravel-termux-setup"
SCRIPT_NAME="setup-laravel.sh"

log() { echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"; }
info() { echo -e "${BLUE}[INFO] $1${NC}"; }
warn() { echo -e "${YELLOW}[WARNING] $1${NC}"; }
error() { echo -e "${RED}[ERROR] $1${NC}"; }

banner() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║              Laravel Termux Setup Installer               ║"
    echo "║                                                            ║"
    echo "║  Automated Laravel hosting environment for Termux         ║"
    echo "║  With multi-project support and easy management           ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo
}

check_termux() {
    if [ ! -d "/data/data/com.termux" ]; then
        error "This installer is designed for Termux environment only!"
        error "Please install Termux from F-Droid or Google Play Store"
        exit 1
    fi
}

check_internet() {
    log "Checking internet connection..."
    if ! ping -c 1 google.com &> /dev/null; then
        error "No internet connection detected!"
        error "Please check your network connection and try again"
        exit 1
    fi
}

check_storage() {
    log "Checking available storage..."
    available=$(df /data/data/com.termux/files/home | tail -1 | awk '{print $4}')
    available_mb=$((available / 1024))
    
    if [ $available_mb -lt 1024 ]; then
        warn "Low storage space detected: ${available_mb}MB available"
        warn "At least 1GB is recommended for Laravel installation"
        read -p "Continue anyway? (y/N): " confirm
        if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
            log "Installation cancelled"
            exit 0
        fi
    else
        log "Storage check passed: ${available_mb}MB available"
    fi
}

update_termux() {
    log "Updating Termux packages..."
    if ! pkg update -y && pkg upgrade -y; then
        error "Failed to update Termux packages"
        error "Please run 'pkg update && pkg upgrade' manually and try again"
        exit 1
    fi
}

download_script() {
    log "Downloading Laravel setup script..."
    
    # Create temporary directory
    temp_dir="/tmp/laravel-setup-$$"
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    
    # Download the main script
    script_url="https://raw.githubusercontent.com/${GITHUB_USER}/${REPO_NAME}/main/${SCRIPT_NAME}"
    
    if ! curl -fsSL "$script_url" -o "$SCRIPT_NAME"; then
        error "Failed to download setup script from GitHub"
        error "URL: $script_url"
        error "Please check:"
        error "1. Your internet connection"
        error "2. GitHub repository exists and is public"
        error "3. Script file exists in the repository"
        exit 1
    fi
    
    # Verify download
    if [ ! -f "$SCRIPT_NAME" ] || [ ! -s "$SCRIPT_NAME" ]; then
        error "Downloaded script is empty or corrupted"
        exit 1
    fi
    
    # Make executable
    chmod +x "$SCRIPT_NAME"
    
    log "Script downloaded successfully"
}

run_installation() {
    log "Starting Laravel environment installation..."
    echo
    info "This process will install:"
    info "• PHP 8.x with all required extensions"
    info "• Nginx web server"
    info "• MariaDB database server"  
    info "• Composer package manager"
    info "• Laravel framework"
    info "• Management scripts and shortcuts"
    echo
    
    warn "Installation may take 10-30 minutes depending on your internet speed"
    read -p "Continue with installation? (Y/n): " confirm
    
    if [ "$confirm" = "n" ] || [ "$confirm" = "N" ]; then
        log "Installation cancelled by user"
        exit 0
    fi
    
    # Run the main installation script
    if ! ./"$SCRIPT_NAME"; then
        error "Installation failed!"
        error "Check the error messages above for details"
        exit 1
    fi
}

cleanup() {
    log "Cleaning up temporary files..."
    cd "$HOME"
    rm -rf "/tmp/laravel-setup-$$" 2>/dev/null || true
}

show_completion() {
    echo
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                Installation Completed!                     ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo
    info "🎉 Laravel hosting environment is ready!"
    echo
    info "Quick Start Commands:"
    info "1. Reload terminal: source ~/.bashrc"
    info "2. Start services: laravel-start"
    info "3. Check status: laravel-status"
    info "4. Create project: laravel-project create myapp 8081"
    echo
    info "Default Access:"
    info "• Default site: http://localhost:8080"
    info "• MySQL password: laravel123"
    info "• Database: laravel_default"
    echo
    info "Management Commands:"
    info "• laravel-start    - Start all services"
    info "• laravel-stop     - Stop all services"
    info "• laravel-status   - Show service status"
    info "• laravel-project  - Manage Laravel projects"
    echo
    warn "Remember to start services after device reboot!"
    log "Happy coding! 🚀"
}

main() {
    banner
    check_termux
    check_internet
    check_storage
    update_termux
    download_script
    run_installation
    cleanup
    show_completion
}

# Handle interrupts
trap 'echo; error "Installation interrupted by user"; cleanup; exit 1' INT TERM

# Run main function
main "$@"
