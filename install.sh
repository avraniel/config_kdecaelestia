#!/bin/bash

# ✦ C A E L E S T I A   K D E   +   C U S T O M   C O N F I G S ✦
# Consolidated installer for https://github.com/avraniel/config_kdecaelestia

# Set safe options
set -euo pipefail
IFS=$'\n\t'

# ─── Colors ──────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ─── Script Location ────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR=""
LOG_FILE="$HOME/caelestia-install.log"

# ─── Logging ────────────────────────────────────────────────────────

log() {
    echo -e "$1"
    echo -e "$1" | sed 's/\x1b\[[0-9;]*m//g' >> "$LOG_FILE"
}

log_info() {
    log "${BLUE}ℹ $1${NC}"
}

log_success() {
    log "${GREEN}✓ $1${NC}"
}

log_warning() {
    log "${YELLOW}⚠ $1${NC}"
}

log_error() {
    log "${RED}✗ $1${NC}"
}

log_section() {
    log ""
    log "${GREEN}► $1${NC}"
    log ""
}

# ─── Error Handler ──────────────────────────────────────────────────

cleanup() {
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR" 2>/dev/null || true
    fi
}

trap 'cleanup' EXIT INT TERM

handle_error() {
    local line=$1
    local exit_code=$2
    log_error "Error at line $line (exit code: $exit_code)"
    log_warning "Check $LOG_FILE for details"
    
    echo ""
    echo -e "${YELLOW}Options:${NC}"
    echo "  1. Retry"
    echo "  2. Ignore and continue"
    echo "  3. Exit"
    read -p "Choose (1-3): " choice
    
    case $choice in
        1) return 0 ;;
        2) return 1 ;;
        *) log_error "Exiting."; exit $exit_code ;;
    esac
}

err_handler() {
    local exit_code=$?
    local line=$1
    handle_error "$line" "$exit_code" || true
}

trap 'err_handler $LINENO' ERR

# ─── Banner ──────────────────────────────────────────────────────────

log_success "╔════════════════════════════════════════════════════════════╗"
log_success "║     ✦ C A E L E S T I A   K D E   I N S T A L L E R ✦     ║"
log_success "╚════════════════════════════════════════════════════════════╝"
log_info "Config source: $SCRIPT_DIR"
log_info "Log file: $LOG_FILE"
echo ""

# ─── Pre-flight Checks ──────────────────────────────────────────────

log_section "Pre-flight checks"

check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "$1 is not installed"
        return 1
    fi
    return 0
}

if ! check_command git; then
    log_error "Please install git first"
    exit 1
fi

if ! pgrep -x "plasmashell" &> /dev/null; then
    log_warning "KDE Plasma not detected. Requires KDE Plasma 6.0+."
    echo ""
fi

TEMP_DIR="$(mktemp -d)"
log_success "Created temp directory: $TEMP_DIR"

# ─── Package Manager Detection ──────────────────────────────────────

PKG_MANAGER="unknown"
INSTALL_CMD=""
AUR_HELPER=""
AUR_CMD=""

if command -v pacman &> /dev/null; then
    PKG_MANAGER="pacman"
    INSTALL_CMD="sudo pacman -S --needed --noconfirm"
    if command -v yay &> /dev/null; then
        AUR_HELPER="yay"
        AUR_CMD="yay -S --needed --noconfirm"
    elif command -v paru &> /dev/null; then
        AUR_HELPER="paru"
        AUR_CMD="paru -S --needed --noconfirm"
    fi
elif command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
    INSTALL_CMD="sudo dnf install -y"
elif command -v apt &> /dev/null; then
    PKG_MANAGER="apt"
    INSTALL_CMD="sudo apt install -y"
else
    log_warning "Could not detect package manager. Some features will be disabled."
fi

log_success "Package manager: $PKG_MANAGER"
log_success "AUR helper: ${AUR_HELPER:-none}"
echo ""

# ─── Safe Package Installation ──────────────────────────────────────

safe_install() {
    local pkg=$1
    log_info "Installing: $pkg"
    
    case $PKG_MANAGER in
        pacman)
            $INSTALL_CMD "$pkg" 2>&1 | tee -a "$LOG_FILE" || {
                log_warning "Failed to install $pkg"
                return 1
            }
            ;;
        dnf)
            $INSTALL_CMD "$pkg" 2>&1 | tee -a "$LOG_FILE" || {
                log_warning "Failed to install $pkg"
                return 1
            }
            ;;
        apt)
            $INSTALL_CMD "$pkg" 2>&1 | tee -a "$LOG_FILE" || {
                log_warning "Failed to install $pkg"
                return 1
            }
            ;;
        *)
            log_warning "Cannot install $pkg - unsupported package manager"
            return 1
            ;;
    esac
    return 0
}

# ─── Step 1: Install Caelestia KDE ──────────────────────────────────

log_section "Step 1: Installing Caelestia KDE"

CAELESTIA_DIR="$HOME/caelestia-dots-kde"

if [ -d "$CAELESTIA_DIR" ]; then
    log_warning "Directory $CAELESTIA_DIR already exists."
    read -p "Remove and re-clone for fresh install? (y/n) " reinstall
    if [[ $reinstall == "y" || $reinstall == "Y" ]]; then
        rm -rf "$CAELESTIA_DIR" || {
            log_error "Failed to remove $CAELESTIA_DIR"
            exit 1
        }
        log_success "Removed existing directory"
    else
        log_info "Using existing directory"
    fi
fi

if [ ! -d "$CAELESTIA_DIR" ]; then
    log_info "Cloning caelestia-dots-kde..."
    git clone https://github.com/ladybug-me/caelestia-dots-kde "$CAELESTIA_DIR" 2>&1 | tee -a "$LOG_FILE" || {
        log_error "Failed to clone repository"
        exit 1
    }
    log_success "Clone completed"
fi

if [ -d "$CAELESTIA_DIR" ] && [ -f "$CAELESTIA_DIR/setup.sh" ]; then
    cd "$CAELESTIA_DIR"
    log_info "Running Caelestia setup script..."
    log_warning "You may be prompted for your password multiple times."
    echo ""
    
    chmod +x setup.sh
    bash ./setup.sh 2>&1 | tee -a "$LOG_FILE" || {
        log_warning "Caelestia setup encountered issues"
        read -p "Continue anyway? (y/n) " continue_anyway
        if [[ $continue_anyway != "y" && $continue_anyway != "Y" ]]; then
            exit 1
        fi
    }
    cd "$SCRIPT_DIR"
else
    log_error "Caelestia repository incomplete - missing setup.sh"
    exit 1
fi

# ─── Step 2: Apply Custom Configs ──────────────────────────────────

log_section "Step 2: Applying custom configuration files"

safe_copy_config() {
    local src=$1
    local dest=$2
    local name=$3
    
    if [ -d "$src" ]; then
        log_info "Copying $name config..."
        mkdir -p "$dest"
        cp -r "$src/"* "$dest/" 2>/dev/null || true
        if [ -n "$(ls -A "$src" 2>/dev/null)" ]; then
            log_success "  ✓ $name config applied"
        else
            log_warning "  ⚠ $name directory is empty"
        fi
    else
        log_warning "  ⚠ $name directory not found, skipping"
    fi
}

safe_copy_config "$SCRIPT_DIR/fastfetch" "$HOME/.config/fastfetch" "fastfetch"
safe_copy_config "$SCRIPT_DIR/fish" "$HOME/.config/fish" "fish"
safe_copy_config "$SCRIPT_DIR/kitty" "$HOME/.config/kitty" "kitty"

# ─── Step 3: Kitty Terminal ─────────────────────────────────────────

log_section "Step 3: Optional Kitty terminal installation"

read -p "Install Kitty terminal? (y/n) " install_kitty

if [[ $install_kitty == "y" || $install_kitty == "Y" ]]; then
    log_info "Installing Kitty..."
    
    if safe_install "kitty"; then
        if command -v kitty &> /dev/null; then
            log_success "Kitty installed successfully"
        else
            log_warning "Kitty installation may have failed. Please check manually."
        fi
    fi
else
    log_info "Skipping Kitty installation"
fi

echo ""

# ─── Step 4: Neo-Candy-Papirus-Carmine Icons ───────────────────────

log_section "Step 4: Optional Neo-Candy-Papirus-Carmine Icons"

echo -e "${CYAN}This icon theme is a combination of Candy, Papirus, and Carmine icons.${NC}"
echo -e "${CYAN}It will be installed to ~/.local/share/icons/ for your user only.${NC}"
echo ""
read -p "Install neo-candy-papirus-carmine-icons-git? (y/n) " install_icons

install_icons_manually() {
    log_info "Cloning repository from GitHub..."
    local icon_dir="$TEMP_DIR/neo-candy-papirus-carmine-icons"
    
    git clone https://github.com/voidtech/neo-candy-papirus-carmine-icons.git "$icon_dir" 2>&1 | tee -a "$LOG_FILE" || {
        log_error "Failed to clone icon repository"
        return 1
    }
    
    mkdir -p "$HOME/.local/share/icons"
    
    # Find the actual theme folder (could be inside the repo)
    if [ -d "$icon_dir/neo-candy-papirus-carmine-icons" ]; then
        cp -r "$icon_dir/neo-candy-papirus-carmine-icons" "$HOME/.local/share/icons/"
    elif [ -d "$icon_dir/src" ]; then
        cp -r "$icon_dir/src" "$HOME/.local/share/icons/neo-candy-papirus-carmine-icons"
    else
        cp -r "$icon_dir/." "$HOME/.local/share/icons/neo-candy-papirus-carmine-icons/"
    fi
    
    log_success "Icon theme installed manually to ~/.local/share/icons/"
    log_info "You can apply it from: System Settings → Appearance → Icons"
    return 0
}

if [[ $install_icons == "y" || $install_icons == "Y" ]]; then
    log_info "Installing icon theme..."
    
    case $PKG_MANAGER in
        pacman)
            if [ -n "$AUR_HELPER" ]; then
                log_info "Installing from AUR using $AUR_HELPER..."
                $AUR_CMD neo-candy-papirus-carmine-icons-git 2>&1 | tee -a "$LOG_FILE" && {
                    log_success "Icon theme installed via AUR"
                } || {
                    log_warning "AUR installation failed, trying manual install..."
                    install_icons_manually
                }
            else
                log_warning "No AUR helper found. Attempting manual installation..."
                install_icons_manually
            fi
            ;;
        *)
            log_info "Attempting manual installation..."
            install_icons_manually
            ;;
    esac
    
    # Set as default icon theme if configured
    if command -v kwriteconfig6 &> /dev/null; then
        log_info "Setting as default icon theme..."
        kwriteconfig6 --file kdeglobals --group Icons --key Theme "neo-candy-papirus-carmine-icons" 2>&1 | tee -a "$LOG_FILE" || {
            log_warning "Could not set as default icon theme. Apply manually in System Settings."
        }
    fi
    
    log_success "Icon theme installation completed"
else
    log_info "Skipping icon theme installation"
fi

echo ""

# ─── Step 5: Wallpaper Cache ────────────────────────────────────────

log_section "Step 5: Installing wallpaper-cache"

WALLPAPER_DIR="$HOME/wallpaper-cache"

if [ -d "$WALLPAPER_DIR" ]; then
    log_warning "Directory $WALLPAPER_DIR already exists."
    read -p "Remove and re-clone for fresh install? (y/n) " reinstall_wallpaper
    if [[ $reinstall_wallpaper == "y" || $reinstall_wallpaper == "Y" ]]; then
        rm -rf "$WALLPAPER_DIR" || true
        log_success "Removed existing directory"
    else
        log_info "Using existing directory"
    fi
fi

if [ ! -d "$WALLPAPER_DIR" ]; then
    log_info "Cloning wallpaper-cache..."
    git clone https://github.com/avraniel/wallpaper-cache.git "$WALLPAPER_DIR" 2>&1 | tee -a "$LOG_FILE" || {
        log_warning "Failed to clone wallpaper-cache"
        log_info "Continuing without wallpapers"
    }
fi

if [ -f "$WALLPAPER_DIR/install_wca" ]; then
    log_info "Running install_wca script..."
    chmod +x "$WALLPAPER_DIR/install_wca"
    cd "$WALLPAPER_DIR"
    bash ./install_wca 2>&1 | tee -a "$LOG_FILE" || {
        log_warning "install_wca script encountered issues"
    }
    cd "$SCRIPT_DIR"
    log_success "wallpaper-cache installed"
else
    log_warning "install_wca script not found in wallpaper-cache"
    log_info "Repository cloned to $WALLPAPER_DIR"
fi

# ─── Step 6: Modern Clock Widget ────────────────────────────────────

log_section "Step 6: Optional Modern Clock widget installation"

echo -e "${CYAN}Modern Clock options:${NC}"
echo "  1. Colorful Digital Clock (color picker + custom separator)"
echo "  2. Nothing OS Digital Clock (pill-style)"
echo "  3. Skip"
echo ""
read -p "Install a Modern Clock widget? (y/n) " install_clock

if [[ $install_clock == "y" || $install_clock == "Y" ]]; then
    echo ""
    read -p "Enter choice (1, 2, or 3): " clock_choice
    
    install_clock_widget() {
        local repo=$1
        local name=$2
        local plasmoid_id=$3
        
        log_info "Installing $name..."
        
        mkdir -p "$HOME/.local/share/plasma/plasmoids"
        
        local clock_dir="$TEMP_DIR/${name// /-}"
        git clone "$repo" "$clock_dir" 2>&1 | tee -a "$LOG_FILE" || {
            log_error "Failed to clone $name"
            return 1
        }
        
        if [ -d "$clock_dir/package" ]; then
            mkdir -p "$HOME/.local/share/plasma/plasmoids/$plasmoid_id"
            cp -r "$clock_dir/package/." "$HOME/.local/share/plasma/plasmoids/$plasmoid_id/"
        elif [ -d "$clock_dir/packages/clock-digital" ]; then
            if command -v kpackagetool6 &> /dev/null; then
                cd "$clock_dir"
                kpackagetool6 --type Plasma/Applet -i packages/clock-digital 2>&1 | tee -a "$LOG_FILE" || true
                cd "$SCRIPT_DIR"
            elif command -v kpackagetool5 &> /dev/null; then
                cd "$clock_dir"
                kpackagetool5 --type Plasma/Applet -i packages/clock-digital 2>&1 | tee -a "$LOG_FILE" || true
                cd "$SCRIPT_DIR"
            else
                cp -r "$clock_dir/packages/clock-digital/"* "$HOME/.local/share/plasma/plasmoids/" 2>/dev/null || true
            fi
        else
            log_error "Could not find package structure for $name"
            return 1
        fi
        
        rm -rf "$clock_dir"
        
        # Restart Plasma safely
        log_info "Restarting Plasma shell..."
        if command -v kquitapp6 &> /dev/null; then
            kquitapp6 plasmashell 2>/dev/null || true
        elif command -v kquitapp5 &> /dev/null; then
            kquitapp5 plasmashell 2>/dev/null || true
        else
            log_warning "Could not restart Plasma shell. Please log out and back in."
            return 0
        fi
        
        sleep 2
        if command -v kstart6 &> /dev/null; then
            kstart6 plasmashell 2>/dev/null || true
        elif command -v kstart5 &> /dev/null; then
            kstart5 plasmashell 2>/dev/null || true
        fi
        
        log_success "$name installed"
        log_info "Add it to your panel: Right-click panel → Add Widgets"
        return 0
    }
    
    case $clock_choice in
        1)
            install_clock_widget \
                "https://github.com/v-n7k/plasma-panel-digital-clock.git" \
                "Colorful Digital Clock" \
                "co.n7k.plasma.digitalclock"
            ;;
        2)
            install_clock_widget \
                "https://github.com/jaxparrow07/nothing-kde-widgets.git" \
                "Nothing Digital Clock" \
                "nothing.clock.digital"
            ;;
        *)
            log_info "Skipping clock installation"
            ;;
    esac
else
    log_info "Skipping clock widget installation"
fi

echo ""

# ─── Step 7: Optional Applications ──────────────────────────────────

log_section "Step 7: Optional applications"

echo -e "${CYAN}Applications available:${NC}"
echo "  • Viber (messaging)"
echo "  • Signal (secure messaging)"
echo "  • Zoom (video conferencing)"
echo "  • Thunar + plugins (file manager)"
echo ""
read -p "Install these applications? (y/n) " install_apps

if [[ $install_apps == "y" || $install_apps == "Y" ]]; then
    log_info "Installing applications..."
    
    case $PKG_MANAGER in
        pacman)
            log_info "Installing from official repositories..."
            safe_install "thunar" || true
            safe_install "thunar-volman" || true
            safe_install "thunar-shares-plugin" || true
            
            if [ -n "$AUR_HELPER" ]; then
                log_info "Installing from AUR using $AUR_HELPER..."
                $AUR_CMD viber signal-desktop zoom 2>&1 | tee -a "$LOG_FILE" || {
                    log_warning "Some AUR packages failed to install"
                }
            else
                log_warning "No AUR helper found. Skipping AUR packages."
                log_info "You can manually install: viber, signal-desktop, zoom"
                
                read -p "Install yay (AUR helper) now? (y/n) " install_yay
                if [[ $install_yay == "y" || $install_yay == "Y" ]]; then
                    log_info "Installing yay..."
                    safe_install "git" || true
                    safe_install "base-devel" || true
                    git clone https://aur.archlinux.org/yay.git "$TEMP_DIR/yay" 2>&1 | tee -a "$LOG_FILE" || {
                        log_error "Failed to clone yay"
                    }
                    cd "$TEMP_DIR/yay"
                    makepkg -si --noconfirm 2>&1 | tee -a "$LOG_FILE" || {
                        log_warning "yay installation failed"
                    }
                    cd "$SCRIPT_DIR"
                    yay -S --needed --noconfirm viber signal-desktop zoom 2>&1 | tee -a "$LOG_FILE" || {
                        log_warning "AUR packages installation failed"
                    }
                fi
            fi
            ;;

        dnf)
            log_info "Installing for Fedora..."
            
            if ! dnf repolist | grep -q "rpmfusion"; then
                log_info "Enabling RPM Fusion..."
                sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm 2>&1 | tee -a "$LOG_FILE" || true
                sudo dnf install -y https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm 2>&1 | tee -a "$LOG_FILE" || true
            fi
            
            safe_install "thunar" || true
            safe_install "thunar-volman" || true
            log_warning "thunar-shares-plugin may not be available for Fedora"
            
            if command -v flatpak &> /dev/null; then
                log_info "Installing Flatpak versions..."
                flatpak install -y flathub com.viber.Viber 2>&1 | tee -a "$LOG_FILE" || true
                flatpak install -y flathub org.signal.Signal 2>&1 | tee -a "$LOG_FILE" || true
                flatpak install -y flathub us.zoom.Zoom 2>&1 | tee -a "$LOG_FILE" || true
            else
                log_warning "Flatpak not found. Skipping Flatpak installations."
            fi
            ;;

        apt)
            log_info "Installing for Debian/Ubuntu..."
            
            safe_install "thunar" || true
            safe_install "thunar-volman" || true
            safe_install "thunar-shares-plugin" || true
            
            # Signal
            log_info "Adding Signal repository..."
            wget -qO- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > "$TEMP_DIR/signal-desktop-keyring.gpg" 2>/dev/null || true
            sudo mv "$TEMP_DIR/signal-desktop-keyring.gpg" /usr/share/keyrings/ 2>/dev/null || true
            echo "deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main" | sudo tee /etc/apt/sources.list.d/signal-xenial.list 2>/dev/null || true
            sudo apt update 2>&1 | tee -a "$LOG_FILE" || true
            safe_install "signal-desktop" || true
            
            # Viber
            log_info "Downloading Viber..."
            wget -O "$TEMP_DIR/viber.deb" https://download.cdn.viber.com/desktop/Linux/viber.deb 2>&1 | tee -a "$LOG_FILE" || true
            sudo dpkg -i "$TEMP_DIR/viber.deb" 2>&1 | tee -a "$LOG_FILE" || sudo apt install -f -y 2>&1 | tee -a "$LOG_FILE" || true
            
            # Zoom
            log_info "Downloading Zoom..."
            wget -O "$TEMP_DIR/zoom.deb" https://zoom.us/client/latest/zoom_amd64.deb 2>&1 | tee -a "$LOG_FILE" || true
            sudo dpkg -i "$TEMP_DIR/zoom.deb" 2>&1 | tee -a "$LOG_FILE" || sudo apt install -f -y 2>&1 | tee -a "$LOG_FILE" || true
            ;;

        *)
            log_error "Unsupported package manager: $PKG_MANAGER"
            log_info "Please install applications manually"
            ;;
    esac
    
    log_success "Application installation completed"
else
    log_info "Skipping application installation"
fi

echo ""

# ─── Step 8: Spotify + Spicetify ────────────────────────────────────

log_section "Step 8: Spotify + Spicetify installation"

echo -e "${CYAN}This step will install:${NC}"
echo -e "  1. Spotify client (if not already installed)"
echo -e "  2. Spicetify (for customization)"
echo -e "  3. Spicetify Marketplace"
echo ""
read -p "Install Spotify and Spicetify? (y/n) " install_spotify_spicetify

if [[ $install_spotify_spicetify == "y" || $install_spotify_spicetify == "Y" ]]; then
    
    # ── Check if Spotify is already installed ──
    SPOTIFY_INSTALLED=false
    SPOTIFY_TYPE=""
    
    if command -v spotify &> /dev/null; then
        SPOTIFY_INSTALLED=true
        SPOTIFY_TYPE="system"
        log_success "Spotify (system) already detected"
    elif flatpak list 2>/dev/null | grep -q "com.spotify.Client"; then
        SPOTIFY_INSTALLED=true
        SPOTIFY_TYPE="flatpak"
        log_success "Spotify (Flatpak) already detected"
    elif command -v pacman &> /dev/null && pacman -Q spotify-launcher 2>/dev/null; then
        SPOTIFY_INSTALLED=true
        SPOTIFY_TYPE="arch-launcher"
        log_success "Spotify (spotify-launcher) already detected"
    else
        log_info "Spotify not detected. Installing now..."
    fi
    
    # ── Install Spotify if not present ──
    if [[ $SPOTIFY_INSTALLED == false ]]; then
        log_info "Installing Spotify..."
        
        case $PKG_MANAGER in
            pacman)
                if safe_install "spotify-launcher"; then
                    SPOTIFY_TYPE="arch-launcher"
                    SPOTIFY_INSTALLED=true
                    log_success "Spotify installed via spotify-launcher"
                elif [ -n "$AUR_HELPER" ]; then
                    log_info "Installing Spotify from AUR..."
                    $AUR_CMD spotify 2>&1 | tee -a "$LOG_FILE" && {
                        SPOTIFY_INSTALLED=true
                        SPOTIFY_TYPE="system"
                        log_success "Spotify installed from AUR"
                    } || {
                        log_warning "Failed to install Spotify from AUR"
                    }
                else
                    log_warning "Could not install Spotify automatically"
                    log_info "Please install manually: spotify-launcher or from AUR"
                fi
                ;;
                
            dnf)
                log_info "Installing Spotify for Fedora..."
                safe_install "lpf-spotify-client" && {
                    log_warning "Run: lpf-spotify-client to complete installation"
                    SPOTIFY_INSTALLED=true
                    SPOTIFY_TYPE="system"
                } || true
                ;;
                
            apt)
                log_info "Installing Spotify for Debian/Ubuntu..."
                wget -qO "$TEMP_DIR/spotify.gpg" https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg 2>&1 | tee -a "$LOG_FILE" || true
                sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg "$TEMP_DIR/spotify.gpg" 2>&1 | tee -a "$LOG_FILE" || true
                echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list 2>&1 | tee -a "$LOG_FILE" || true
                sudo apt update 2>&1 | tee -a "$LOG_FILE" || true
                safe_install "spotify-client" && {
                    SPOTIFY_INSTALLED=true
                    SPOTIFY_TYPE="system"
                } || true
                ;;
                
            *)
                log_warning "Unsupported package manager. Please install Spotify manually:"
                log_info "https://www.spotify.com/download/linux/"
                ;;
        esac
    fi
    
    # ── Verify Spotify installation ──
    if [[ $SPOTIFY_INSTALLED == false ]]; then
        if command -v spotify &> /dev/null; then
            SPOTIFY_INSTALLED=true
            SPOTIFY_TYPE="system"
        elif flatpak list 2>/dev/null | grep -q "com.spotify.Client"; then
            SPOTIFY_INSTALLED=true
            SPOTIFY_TYPE="flatpak"
        fi
    fi
    
    # ── Launch Spotify if installed ──
    if [[ $SPOTIFY_INSTALLED == true ]]; then
        echo ""
        log_warning "Spotify needs to be launched at least once before Spicetify works"
        echo -e "${CYAN}Options:${NC}"
        echo "  1. Launch Spotify now (wait for you to log in)"
        echo "  2. Launch Spotify now (continue in background)"
        echo "  3. Skip (launch manually later)"
        echo ""
        read -p "Choose (1, 2, or 3): " spotify_launch_choice
        
        if [[ $spotify_launch_choice == "1" || $spotify_launch_choice == "2" ]]; then
            log_info "Launching Spotify..."
            
            case $SPOTIFY_TYPE in
                flatpak)
                    flatpak run com.spotify.Client &
                    ;;
                *)
                    spotify &
                    ;;
            esac
            
            SPOTIFY_PID=$!
            log_info "Spotify launched (PID: $SPOTIFY_PID)"
            
            if [[ $spotify_launch_choice == "1" ]]; then
                log_warning "Please log in to Spotify and then come back"
                echo -e "${YELLOW}Press Enter when you're done (or wait 30 seconds)${NC}"
                read -t 30 -p "Press Enter when ready: " || true
            else
                log_info "Waiting 15 seconds for Spotify to initialize..."
                sleep 15
            fi
        else
            log_warning "Please launch Spotify manually and log in before continuing"
            read -p "Press Enter when ready: "
        fi
        
        # ── Detect Spotify path ──
        echo ""
        log_info "Detecting Spotify path for Spicetify..."
        
        SPOTIFY_PATH=""
        PREFS_PATH=""
        
        case $SPOTIFY_TYPE in
            flatpak)
                FLATPAK_SPOTIFY_PATH=$(flatpak info --show-location com.spotify.Client 2>/dev/null)
                if [ -n "$FLATPAK_SPOTIFY_PATH" ]; then
                    if [ -d "$FLATPAK_SPOTIFY_PATH/files/extra/share/spotify" ]; then
                        SPOTIFY_PATH="$FLATPAK_SPOTIFY_PATH/files/extra/share/spotify"
                    elif [ -d "$FLATPAK_SPOTIFY_PATH/files/share/spotify" ]; then
                        SPOTIFY_PATH="$FLATPAK_SPOTIFY_PATH/files/share/spotify"
                    fi
                    PREFS_PATH="$HOME/.var/app/com.spotify.Client/config/spotify/prefs"
                    log_success "Flatpak Spotify detected"
                fi
                ;;
                
            arch-launcher)
                SPOTIFY_PATH="$HOME/.local/share/spotify-launcher/usr/share/spotify"
                PREFS_PATH="$HOME/.config/spotify/prefs"
                log_success "spotify-launcher detected"
                ;;
                
            system)
                if [ -d "/usr/share/spotify" ]; then
                    SPOTIFY_PATH="/usr/share/spotify"
                elif [ -d "/opt/spotify" ]; then
                    SPOTIFY_PATH="/opt/spotify"
                elif [ -d "$HOME/.local/share/spotify" ]; then
                    SPOTIFY_PATH="$HOME/.local/share/spotify"
                elif [ -d "/snap/spotify/current/usr/share/spotify" ]; then
                    SPOTIFY_PATH="/snap/spotify/current/usr/share/spotify"
                    log_warning "Snap Spotify detected - Spicetify may not work with Snap packages"
                else
                    SPOTIFY_PATH=$(find /usr /opt $HOME/.local -type d -name "spotify" 2>/dev/null | head -1)
                fi
                PREFS_PATH="$HOME/.config/spotify/prefs"
                log_success "System Spotify detected"
                ;;
                
            *)
                log_warning "Unknown Spotify type. Trying automatic detection..."
                SPOTIFY_PATH=$(find /usr /opt $HOME/.local -type d -name "spotify" 2>/dev/null | head -1)
                PREFS_PATH="$HOME/.config/spotify/prefs"
                ;;
        esac
        
        # ── Install Spicetify ──
        echo ""
        log_info "Installing Spicetify..."
        
        case $PKG_MANAGER in
            pacman) safe_install "curl" || true; safe_install "unzip" || true ;;
            dnf) safe_install "curl" || true; safe_install "unzip" || true ;;
            apt) safe_install "curl" || true; safe_install "unzip" || true ;;
            *) log_warning "Please ensure curl and unzip are installed" ;;
        esac
        
        curl -fsSL https://raw.githubusercontent.com/spicetify/cli/main/install.sh -o "$TEMP_DIR/install_spicetify.sh" || {
            log_error "Failed to download Spicetify installer"
        }
        
        if [ -f "$TEMP_DIR/install_spicetify.sh" ]; then
            chmod +x "$TEMP_DIR/install_spicetify.sh"
            bash "$TEMP_DIR/install_spicetify.sh" 2>&1 | tee -a "$LOG_FILE" || {
                log_warning "Spicetify installation encountered issues"
            }
        fi
        
        if ! command -v spicetify &> /dev/null && [ -f "$HOME/.spicetify/spicetify" ]; then
            export PATH="$HOME/.spicetify:$PATH"
            echo 'export PATH="$HOME/.spicetify:$PATH"' >> "$HOME/.bashrc" 2>/dev/null || true
            echo 'export PATH="$HOME/.spicetify:$PATH"' >> "$HOME/.zshrc" 2>/dev/null || true
            log_success "Added Spicetify to PATH"
        fi
        
        # ── Configure Spicetify ──
        if command -v spicetify &> /dev/null; then
            echo ""
            log_info "Configuring Spicetify..."
            
            if [ -n "$SPOTIFY_PATH" ] && [ -d "$SPOTIFY_PATH" ]; then
                log_info "Setting Spotify path: $SPOTIFY_PATH"
                spicetify config spotify_path "$SPOTIFY_PATH" 2>&1 | tee -a "$LOG_FILE" || true
            else
                log_warning "Could not automatically detect Spotify path"
                log_info "Set manually: spicetify config spotify_path /path/to/spotify"
            fi
            
            if [ -n "$PREFS_PATH" ]; then
                log_info "Setting prefs path: $PREFS_PATH"
                spicetify config prefs_path "$PREFS_PATH" 2>&1 | tee -a "$LOG_FILE" || true
            fi
            
            if [ -n "$SPOTIFY_PATH" ] && [ -d "$SPOTIFY_PATH" ]; then
                log_info "Fixing permissions..."
                sudo chmod a+wr "$SPOTIFY_PATH" 2>/dev/null || true
                sudo chmod a+wr "$SPOTIFY_PATH/Apps" 2>/dev/null || true
            fi
            
            echo ""
            log_info "Applying Spicetify..."
            
            timeout 60 spicetify backup apply 2>&1 | tee -a "$LOG_FILE" || {
                log_warning "Spicetify apply had issues"
                log_info "Try running: spicetify backup apply"
            }
            
            log_success "Spicetify applied"
            echo ""
            log_info "Spicetify Marketplace should now be available in Spotify"
            log_info "If not, run: spicetify apply"
            log_info "After Spotify updates: spicetify backup apply"
            
        else
            log_error "Spicetify command not found"
            log_warning "You may need to restart your terminal or log out and back in"
        fi
        
    else
        log_warning "Spotify not installed. Skipping Spicetify."
    fi
    
else
    log_info "Skipping Spotify and Spicetify"
fi

echo ""

# ─── Step 9: Fstab Configuration ────────────────────────────────────

log_section "Step 9: Optional fstab configuration"

echo -e "${CYAN}This will add storage drive entries to /etc/fstab with:${NC}"
echo -e "  • nofail - system boots even if drive is missing"
echo -e "  • noatime - reduces disk writes for performance"
echo ""
echo -e "${YELLOW}UUID=dda9fe61-a2b0-4d5c-9076-8fa3cff067b4  /home/niel/DATA          ext4  defaults,noatime,nofail  0  2${NC}"
echo -e "${YELLOW}UUID=e3af8571-cddf-4edc-86f2-5efa6d7fec2e  /run/media/niel/storage  ext4  defaults,noatime,nofail  0  2${NC}"
echo -e "${YELLOW}UUID=b053948d-acab-49d1-bf0e-79986ab1c3f5  /home/niel/Downloads     ext4  defaults,noatime,nofail  0  2${NC}"
echo ""
read -p "Proceed with fstab configuration? (y/n) " run_fstab

if [[ $run_fstab == "y" || $run_fstab == "Y" ]]; then
    log_info "Preparing to update /etc/fstab..."
    
    if [ ! -f /etc/fstab ]; then
        log_error "/etc/fstab does not exist"
    else
        sudo cp /etc/fstab /etc/fstab.backup
        log_success "Backup created: /etc/fstab.backup"
        
        NEW_LINES=(
            "UUID=dda9fe61-a2b0-4d5c-9076-8fa3cff067b4  /home/niel/DATA          ext4  defaults,noatime,nofail  0  2"
            "UUID=e3af8571-cddf-4edc-86f2-5efa6d7fec2e  /run/media/niel/storage  ext4  defaults,noatime,nofail  0  2"
            "UUID=b053948d-acab-49d1-bf0e-79986ab1c3f5  /home/niel/Downloads     ext4  defaults,noatime,nofail  0  2"
        )
        
        TEMP_FSTAB="$TEMP_DIR/fstab.new"
        
        sudo grep -v -E "dda9fe61-a2b0-4d5c-9076-8fa3cff067b4|e3af8571-cddf-4edc-86f2-5efa6d7fec2e|b053948d-acab-49d1-bf0e-79986ab1c3f5" /etc/fstab > "$TEMP_FSTAB" 2>/dev/null || true
        
        echo "" >> "$TEMP_FSTAB"
        echo "# storage drives (added by installer)" >> "$TEMP_FSTAB"
        for line in "${NEW_LINES[@]}"; do
            echo "$line" >> "$TEMP_FSTAB"
        done
        
        sudo mv "$TEMP_FSTAB" /etc/fstab
        log_success "/etc/fstab updated with new entries"
        
        log_info "Testing new fstab with 'sudo mount -a'..."
        if sudo mount -a 2>&1 | tee -a "$LOG_FILE"; then
            log_success "mount -a succeeded - fstab is valid"
        else
            log_error "mount -a failed. Please check your fstab entries."
            log_warning "Restore backup: sudo cp /etc/fstab.backup /etc/fstab"
            read -p "Press Enter to continue anyway, or Ctrl+C to abort."
        fi
        
        log_info "Ensuring mount points exist..."
        sudo mkdir -p /home/niel/DATA /run/media/niel/storage /home/niel/Downloads
        log_success "Mount points created/verified"
        
        log_info "To set ownership: sudo chown -R niel:niel /home/niel/DATA /run/media/niel/storage /home/niel/Downloads"
        log_success "Fstab configuration completed"
    fi
else
    log_info "Skipping fstab configuration"
fi

# ─── Step 10: Finalize Setup ─────────────────────────────────────────

log_section "Step 10: Finalizing setup"

mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.config/autostart"

if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc" 2>/dev/null || true
    log_success "Added ~/.local/bin to PATH"
fi

if command -v systemctl &> /dev/null; then
    if systemctl --user is-active --quiet keyd 2>/dev/null; then
        log_success "keyd service is running"
    else
        log_warning "keyd service not running. If shortcuts don't work: systemctl --user restart keyd"
    fi
fi

# ─── Step 11: Post-installation Guide ──────────────────────────────

echo ""
log_success "╔════════════════════════════════════════════════════════════╗"
log_success "║              ✦ I N S T A L L A T I O N   D O N E ✦        ║"
log_success "╚════════════════════════════════════════════════════════════╝"
echo ""
log_info "┌─ Post-installation steps ──────────────────────────────────┐"
log_info "│"
log_info "│  1. Log out and log back in to see all changes"
log_info "│  2. If widgets don't appear: caelestia shell -d"
log_info "│  3. For wallpapers: Super+Space → '>' → Caelestia Tweaks"
log_info "│  4. Color scheme: System Settings → Colors → Material You"
log_info "│"
log_info "└────────────────────────────────────────────────────────────┘"
echo ""
log_info "┌─ Key Bindings ─────────────────────────────────────────────┐"
log_info "│  Super + /     │ Show keybind cheatsheet"
log_info "│  Super + Enter │ Open terminal"
log_info "│  Super + Space │ Application launcher"
log_info "│  Super + B     │ Toggle notification panel"
log_info "│  Super + V     │ Open Clipboard History"
log_info "└────────────────────────────────────────────────────────────┘"
echo ""
log_info "┌─ Installed Components ─────────────────────────────────────┐"
log_info "│  ✓ Caelestia KDE theme"
log_info "│  ✓ Fastfetch, Fish, Kitty configs"
if [[ $install_kitty == "y" || $install_kitty == "Y" ]]; then
    log_info "│  ✓ Kitty terminal"
else
    log_info "│  ${YELLOW}No Kitty installation${NC}"
fi
if [[ $install_icons == "y" || $install_icons == "Y" ]]; then
    log_info "│  ✓ Neo-Candy-Papirus-Carmine icons"
else
    log_info "│  ${YELLOW}No icon theme installed${NC}"
fi
log_info "│  ✓ Wallpaper-cache"
if [[ $install_clock == "y" || $install_clock == "Y" ]] && [[ $clock_choice == "1" || $clock_choice == "2" ]]; then
    log_info "│  ✓ Modern Clock widget"
else
    log_info "│  ${YELLOW}No clock widget installed${NC}"
fi
if [[ $install_apps == "y" || $install_apps == "Y" ]]; then
    log_info "│  ✓ Viber, Signal, Zoom, Thunar"
else
    log_info "│  ${YELLOW}No additional applications installed${NC}"
fi
if [[ $install_spotify_spicetify == "y" || $install_spotify_spicetify == "Y" ]]; then
    log_info "│  ✓ Spotify + Spicetify"
else
    log_info "│  ${YELLOW}No Spotify/Spicetify installation${NC}"
fi
if [[ $run_fstab == "y" || $run_fstab == "Y" ]]; then
    log_info "│  ✓ Fstab updated for storage drives"
else
    log_info "│  ${YELLOW}No fstab changes${NC}"
fi
log_info "└────────────────────────────────────────────────────────────┘"
echo ""
log_info "┌─ Uninstall ────────────────────────────────────────────────┐"
log_info "│  cd ~/caelestia-dots-kde && bash ./uninstall.sh"
log_info "│  rm -rf ~/wallpaper-cache"
log_info "│  sudo cp /etc/fstab.backup /etc/fstab  (if needed)"
log_info "└────────────────────────────────────────────────────────────┘"
echo ""
log_success "✧ May your desktop always reflect the stars! ✧"
log_success "Installation log saved to: $LOG_FILE"

exit 0
