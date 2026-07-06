#!/bin/bash

# ✦ C A E L E S T I A   K D E   +   C U S T O M   C O N F I G S ✦
# TUI Installer for https://github.com/avraniel/config_kdecaelestia

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

# ─── Check for whiptail ─────────────────────────────────────────────

if ! command -v whiptail &> /dev/null; then
    echo "whiptail is required but not installed."
    echo "Install it with:"
    echo "  - Arch: sudo pacman -S whiptail"
    echo "  - Fedora: sudo dnf install whiptail"
    echo "  - Debian/Ubuntu: sudo apt install whiptail"
    exit 1
fi

# ─── Logging ────────────────────────────────────────────────────────

log() {
    echo -e "$1" | sed 's/\x1b\[[0-9;]*m//g' >> "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}ℹ $1${NC}"
    log "ℹ $1"
}

log_success() {
    echo -e "${GREEN}✓ $1${NC}"
    log "✓ $1"
}

log_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
    log "⚠ $1"
}

log_error() {
    echo -e "${RED}✗ $1${NC}"
    log "✗ $1"
}

log_section() {
    echo ""
    echo -e "${GREEN}► $1${NC}"
    log "► $1"
    echo ""
}

# ─── Error Handler ──────────────────────────────────────────────────

cleanup() {
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR" 2>/dev/null || true
    fi
}

trap 'cleanup' EXIT INT TERM

TEMP_DIR="$(mktemp -d)"

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
fi

# ─── Safe Package Installation ──────────────────────────────────────

safe_install() {
    local pkg=$1
    log_info "Installing: $pkg"
    
    case $PKG_MANAGER in
        pacman)
            $INSTALL_CMD "$pkg" 2>&1 | tee -a "$LOG_FILE" || return 1
            ;;
        dnf)
            $INSTALL_CMD "$pkg" 2>&1 | tee -a "$LOG_FILE" || return 1
            ;;
        apt)
            $INSTALL_CMD "$pkg" 2>&1 | tee -a "$LOG_FILE" || return 1
            ;;
        *)
            log_warning "Cannot install $pkg - unsupported package manager"
            return 1
            ;;
    esac
    return 0
}

# ─── TUI Functions ──────────────────────────────────────────────────

show_menu() {
    local title="✧ Caelestia KDE Installer ✧"
    local msg="Select components to install (Space to toggle, Enter to confirm)"
    
    # Build checklist options
    local options=(
        "caelestia" "Caelestia KDE theme (full setup)" "ON"
        "configs" "Custom configs (fastfetch, fish, kitty)" "ON"
        "kitty" "Kitty terminal" "OFF"
        "icons" "Neo-Candy-Papirus-Carmine icons" "OFF"
        "wallpapers" "Wallpaper-cache" "ON"
        "clock" "Modern Clock widget" "OFF"
        "apps" "Applications (Viber, Signal, Zoom, Thunar, Chrome)" "OFF"
        "niri" "Niri Animation Switcher" "OFF"
        "spicetify" "Spotify + Spicetify" "OFF"
        "fstab" "Fstab configuration (storage drives)" "OFF"
    )
    
    # Use whiptail checklist
    SELECTED=$(whiptail --title "$title" --checklist "$msg" 20 80 10 \
        "${options[@]}" 3>&1 1>&2 2>&3)
    
    # Parse selections
    INSTALL_CAELESTIA="off"
    INSTALL_CONFIGS="off"
    INSTALL_KITTY="off"
    INSTALL_ICONS="off"
    INSTALL_WALLPAPERS="off"
    INSTALL_CLOCK="off"
    INSTALL_APPS="off"
    INSTALL_NIRI="off"
    INSTALL_SPICETIFY="off"
    INSTALL_FSTAB="off"
    
    if [[ "$SELECTED" == *"caelestia"* ]]; then INSTALL_CAELESTIA="on"; fi
    if [[ "$SELECTED" == *"configs"* ]]; then INSTALL_CONFIGS="on"; fi
    if [[ "$SELECTED" == *"kitty"* ]]; then INSTALL_KITTY="on"; fi
    if [[ "$SELECTED" == *"icons"* ]]; then INSTALL_ICONS="on"; fi
    if [[ "$SELECTED" == *"wallpapers"* ]]; then INSTALL_WALLPAPERS="on"; fi
    if [[ "$SELECTED" == *"clock"* ]]; then INSTALL_CLOCK="on"; fi
    if [[ "$SELECTED" == *"apps"* ]]; then INSTALL_APPS="on"; fi
    if [[ "$SELECTED" == *"niri"* ]]; then INSTALL_NIRI="on"; fi
    if [[ "$SELECTED" == *"spicetify"* ]]; then INSTALL_SPICETIFY="on"; fi
    if [[ "$SELECTED" == *"fstab"* ]]; then INSTALL_FSTAB="on"; fi
}

show_clock_menu() {
    CLOCK_CHOICE=$(whiptail --title "Modern Clock Widget" \
        --radiolist "Select a clock widget to install:" 15 70 3 \
        "1" "Colorful Digital Clock (color picker + custom separator)" ON \
        "2" "Nothing OS Digital Clock (pill-style)" OFF \
        "3" "Skip (install manually later)" OFF \
        3>&1 1>&2 2>&3)
    
    case $CLOCK_CHOICE in
        1) CLOCK_SELECT="colorful" ;;
        2) CLOCK_SELECT="nothing" ;;
        *) CLOCK_SELECT="skip" ;;
    esac
}

show_spicetify_options() {
    SPOTIFY_LAUNCH=$(whiptail --title "Spotify Setup" \
        --radiolist "Spotify needs to be launched at least once before Spicetify works" 15 70 3 \
        "1" "Launch Spotify now (wait for you to log in)" ON \
        "2" "Launch Spotify now (continue in background)" OFF \
        "3" "Skip (launch manually later)" OFF \
        3>&1 1>&2 2>&3)
    
    case $SPOTIFY_LAUNCH in
        1) SPOTIFY_ACTION="wait" ;;
        2) SPOTIFY_ACTION="background" ;;
        *) SPOTIFY_ACTION="skip" ;;
    esac
}

# ─── Installation Functions ─────────────────────────────────────────

install_caelestia() {
    log_section "Installing Caelestia KDE"
    
    CAELESTIA_DIR="$HOME/caelestia-dots-kde"
    
    if [ -d "$CAELESTIA_DIR" ]; then
        if whiptail --title "Caelestia" --yesno "Directory ~/caelestia-dots-kde already exists. Remove and re-clone?" 8 60; then
            rm -rf "$CAELESTIA_DIR"
        else
            log_info "Using existing directory"
        fi
    fi
    
    if [ ! -d "$CAELESTIA_DIR" ]; then
        log_info "Cloning caelestia-dots-kde..."
        git clone https://github.com/ladybug-me/caelestia-dots-kde "$CAELESTIA_DIR" 2>&1 | tee -a "$LOG_FILE"
    fi
    
    if [ -f "$CAELESTIA_DIR/setup.sh" ]; then
        cd "$CAELESTIA_DIR"
        log_info "Running Caelestia setup script..."
        chmod +x setup.sh
        bash ./setup.sh 2>&1 | tee -a "$LOG_FILE" || {
            log_warning "Caelestia setup encountered issues"
            whiptail --title "Warning" --msgbox "Caelestia setup had issues. Check the log file." 8 60
        }
        cd "$SCRIPT_DIR"
    fi
}

install_configs() {
    log_section "Applying custom configuration files"
    
    safe_copy_config() {
        local src=$1
        local dest=$2
        local name=$3
        
        if [ -d "$src" ]; then
            log_info "Copying $name config..."
            mkdir -p "$dest"
            cp -r "$src/"* "$dest/" 2>/dev/null || true
            log_success "  ✓ $name config applied"
        else
            log_warning "  ⚠ $name directory not found, skipping"
        fi
    }
    
    safe_copy_config "$SCRIPT_DIR/fastfetch" "$HOME/.config/fastfetch" "fastfetch"
    safe_copy_config "$SCRIPT_DIR/fish" "$HOME/.config/fish" "fish"
    safe_copy_config "$SCRIPT_DIR/kitty" "$HOME/.config/kitty" "kitty"
}

install_kitty() {
    log_section "Installing Kitty terminal"
    safe_install "kitty"
}

install_icons() {
    log_section "Installing Neo-Candy-Papirus-Carmine Icons"
    
    if [ -n "$AUR_HELPER" ]; then
        $AUR_CMD neo-candy-papirus-carmine-icons-git 2>&1 | tee -a "$LOG_FILE" || {
            log_warning "AUR installation failed, trying manual install..."
            install_icons_manually
        }
    else
        install_icons_manually
    fi
    
    if command -v kwriteconfig6 &> /dev/null; then
        kwriteconfig6 --file kdeglobals --group Icons --key Theme "neo-candy-papirus-carmine-icons" 2>&1 | tee -a "$LOG_FILE"
    fi
}

install_icons_manually() {
    local icon_dir="$TEMP_DIR/neo-candy-papirus-carmine-icons"
    git clone https://github.com/voidtech/neo-candy-papirus-carmine-icons.git "$icon_dir" 2>&1 | tee -a "$LOG_FILE"
    mkdir -p "$HOME/.local/share/icons"
    
    if [ -d "$icon_dir/neo-candy-papirus-carmine-icons" ]; then
        cp -r "$icon_dir/neo-candy-papirus-carmine-icons" "$HOME/.local/share/icons/"
    else
        cp -r "$icon_dir/." "$HOME/.local/share/icons/neo-candy-papirus-carmine-icons/"
    fi
}

install_wallpapers() {
    log_section "Installing wallpaper-cache"
    
    WALLPAPER_DIR="$HOME/wallpaper-cache"
    
    if [ -d "$WALLPAPER_DIR" ]; then
        if whiptail --title "Wallpaper Cache" --yesno "Directory ~/wallpaper-cache already exists. Remove and re-clone?" 8 60; then
            rm -rf "$WALLPAPER_DIR"
        fi
    fi
    
    if [ ! -d "$WALLPAPER_DIR" ]; then
        git clone https://github.com/avraniel/wallpaper-cache.git "$WALLPAPER_DIR" 2>&1 | tee -a "$LOG_FILE"
    fi
    
    if [ -f "$WALLPAPER_DIR/install_wca" ]; then
        chmod +x "$WALLPAPER_DIR/install_wca"
        cd "$WALLPAPER_DIR"
        bash ./install_wca 2>&1 | tee -a "$LOG_FILE"
        cd "$SCRIPT_DIR"
    fi
}

install_clock() {
    log_section "Installing Modern Clock widget"
    
    local repo=""
    local name=""
    local plasmoid_id=""
    
    if [[ "$CLOCK_SELECT" == "colorful" ]]; then
        repo="https://github.com/v-n7k/plasma-panel-digital-clock.git"
        name="Colorful Digital Clock"
        plasmoid_id="co.n7k.plasma.digitalclock"
    elif [[ "$CLOCK_SELECT" == "nothing" ]]; then
        repo="https://github.com/jaxparrow07/nothing-kde-widgets.git"
        name="Nothing Digital Clock"
        plasmoid_id="nothing.clock.digital"
    else
        return
    fi
    
    mkdir -p "$HOME/.local/share/plasma/plasmoids"
    local clock_dir="$TEMP_DIR/clock-widget"
    git clone "$repo" "$clock_dir" 2>&1 | tee -a "$LOG_FILE"
    
    if [ -d "$clock_dir/package" ]; then
        mkdir -p "$HOME/.local/share/plasma/plasmoids/$plasmoid_id"
        cp -r "$clock_dir/package/." "$HOME/.local/share/plasma/plasmoids/$plasmoid_id/"
    elif [ -d "$clock_dir/packages/clock-digital" ]; then
        if command -v kpackagetool6 &> /dev/null; then
            cd "$clock_dir"
            kpackagetool6 --type Plasma/Applet -i packages/clock-digital 2>&1 | tee -a "$LOG_FILE"
            cd "$SCRIPT_DIR"
        fi
    fi
    
    # Restart Plasma
    kquitapp6 plasmashell 2>/dev/null || true
    sleep 2
    kstart6 plasmashell 2>/dev/null || true
}

install_apps() {
    log_section "Installing applications"
    
    case $PKG_MANAGER in
        pacman)
            safe_install "thunar" || true
            safe_install "thunar-volman" || true
            safe_install "thunar-shares-plugin" || true
            
            if [ -n "$AUR_HELPER" ]; then
                $AUR_CMD google-chrome viber signal-desktop zoom 2>&1 | tee -a "$LOG_FILE" || true
            else
                log_warning "No AUR helper found. Installing from official repos only."
            fi
            ;;
        dnf)
            safe_install "thunar" || true
            safe_install "thunar-volman" || true
            
            # Google Chrome
            sudo dnf install -y fedora-workstation-repositories 2>&1 | tee -a "$LOG_FILE" || true
            sudo dnf config-manager --set-enabled google-chrome 2>&1 | tee -a "$LOG_FILE" || true
            safe_install "google-chrome-stable" || true
            
            if command -v flatpak &> /dev/null; then
                flatpak install -y flathub com.viber.Viber 2>&1 | tee -a "$LOG_FILE" || true
                flatpak install -y flathub org.signal.Signal 2>&1 | tee -a "$LOG_FILE" || true
                flatpak install -y flathub us.zoom.Zoom 2>&1 | tee -a "$LOG_FILE" || true
            fi
            ;;
        apt)
            safe_install "thunar" || true
            safe_install "thunar-volman" || true
            safe_install "thunar-shares-plugin" || true
            
            # Google Chrome
            wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add - 2>&1 | tee -a "$LOG_FILE" || true
            echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list 2>&1 | tee -a "$LOG_FILE" || true
            sudo apt update 2>&1 | tee -a "$LOG_FILE" || true
            safe_install "google-chrome-stable" || true
            
            # Signal
            wget -qO- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > "$TEMP_DIR/signal.gpg" 2>/dev/null || true
            sudo mv "$TEMP_DIR/signal.gpg" /usr/share/keyrings/ 2>/dev/null || true
            echo "deb [arch=amd64 signed-by=/usr/share/keyrings/signal.gpg] https://updates.signal.org/desktop/apt xenial main" | sudo tee /etc/apt/sources.list.d/signal-xenial.list 2>/dev/null || true
            sudo apt update 2>&1 | tee -a "$LOG_FILE" || true
            safe_install "signal-desktop" || true
            
            # Viber
            wget -O "$TEMP_DIR/viber.deb" https://download.cdn.viber.com/desktop/Linux/viber.deb 2>&1 | tee -a "$LOG_FILE" || true
            sudo dpkg -i "$TEMP_DIR/viber.deb" 2>&1 | tee -a "$LOG_FILE" || sudo apt install -f -y 2>&1 | tee -a "$LOG_FILE" || true
            
            # Zoom
            wget -O "$TEMP_DIR/zoom.deb" https://zoom.us/client/latest/zoom_amd64.deb 2>&1 | tee -a "$LOG_FILE" || true
            sudo dpkg -i "$TEMP_DIR/zoom.deb" 2>&1 | tee -a "$LOG_FILE" || sudo apt install -f -y 2>&1 | tee -a "$LOG_FILE" || true
            ;;
    esac
}

install_niri() {
    log_section "Installing Niri Animation Switcher"
    
    # Check for Niri
    if ! command -v niri &> /dev/null; then
        whiptail --title "Warning" --msgbox "Niri compositor not detected. The tool will be installed but may not work." 8 60
    fi
    
    # Install dependencies
    case $PKG_MANAGER in
        pacman)
            safe_install "python" || true
            safe_install "python-gobject" || true
            safe_install "gtk3" || true
            safe_install "git" || true
            ;;
        dnf)
            safe_install "python3" || true
            safe_install "python3-gobject" || true
            safe_install "gtk3" || true
            safe_install "git" || true
            ;;
        apt)
            safe_install "python3" || true
            safe_install "python3-gi" || true
            safe_install "gir1.2-gtk-3.0" || true
            safe_install "git" || true
            ;;
    esac
    
    NIRI_DIR="$HOME/niri-anim-switcher"
    
    if [ -d "$NIRI_DIR" ]; then
        if whiptail --title "Niri" --yesno "Directory ~/niri-anim-switcher already exists. Remove and re-clone?" 8 60; then
            rm -rf "$NIRI_DIR"
        fi
    fi
    
    if [ ! -d "$NIRI_DIR" ]; then
        git clone https://github.com/avraniel/niri-anim-switcher.git "$NIRI_DIR" 2>&1 | tee -a "$LOG_FILE"
    fi
    
    if [ -f "$NIRI_DIR/niri-anim-switcher.py" ]; then
        chmod +x "$NIRI_DIR/niri-anim-switcher.py"
        mkdir -p "$HOME/.local/bin"
        cp "$NIRI_DIR/niri-anim-switcher.py" "$HOME/.local/bin/niri-anim"
        log_success "Niri Animation Switcher installed"
    fi
}

install_spicetify() {
    log_section "Installing Spotify + Spicetify"
    
    # Check if Spotify is installed
    SPOTIFY_INSTALLED=false
    SPOTIFY_TYPE=""
    
    if command -v spotify &> /dev/null; then
        SPOTIFY_INSTALLED=true
        SPOTIFY_TYPE="system"
    elif flatpak list 2>/dev/null | grep -q "com.spotify.Client"; then
        SPOTIFY_INSTALLED=true
        SPOTIFY_TYPE="flatpak"
    elif command -v pacman &> /dev/null && pacman -Q spotify-launcher 2>/dev/null; then
        SPOTIFY_INSTALLED=true
        SPOTIFY_TYPE="arch-launcher"
    fi
    
    if [[ $SPOTIFY_INSTALLED == false ]]; then
        log_info "Installing Spotify..."
        case $PKG_MANAGER in
            pacman)
                safe_install "spotify-launcher" && { SPOTIFY_INSTALLED=true; SPOTIFY_TYPE="arch-launcher"; } || true
                ;;
            dnf)
                safe_install "lpf-spotify-client" && { SPOTIFY_INSTALLED=true; SPOTIFY_TYPE="system"; } || true
                ;;
            apt)
                wget -qO "$TEMP_DIR/spotify.gpg" https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg 2>&1 | tee -a "$LOG_FILE" || true
                sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg "$TEMP_DIR/spotify.gpg" 2>&1 | tee -a "$LOG_FILE" || true
                echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list 2>&1 | tee -a "$LOG_FILE" || true
                sudo apt update 2>&1 | tee -a "$LOG_FILE" || true
                safe_install "spotify-client" && { SPOTIFY_INSTALLED=true; SPOTIFY_TYPE="system"; } || true
                ;;
        esac
    fi
    
    if [[ $SPOTIFY_INSTALLED == true ]]; then
        # Launch Spotify based on user choice
        if [[ "$SPOTIFY_ACTION" == "wait" || "$SPOTIFY_ACTION" == "background" ]]; then
            log_info "Launching Spotify..."
            spotify &
            sleep 5
            
            if [[ "$SPOTIFY_ACTION" == "wait" ]]; then
                whiptail --title "Spotify" --msgbox "Please log in to Spotify, then press OK to continue." 8 60
            else
                sleep 15
            fi
        fi
        
        # Install Spicetify
        log_info "Installing Spicetify..."
        case $PKG_MANAGER in
            pacman) safe_install "curl" || true; safe_install "unzip" || true ;;
            dnf) safe_install "curl" || true; safe_install "unzip" || true ;;
            apt) safe_install "curl" || true; safe_install "unzip" || true ;;
        esac
        
        curl -fsSL https://raw.githubusercontent.com/spicetify/cli/main/install.sh -o "$TEMP_DIR/install_spicetify.sh"
        chmod +x "$TEMP_DIR/install_spicetify.sh"
        bash "$TEMP_DIR/install_spicetify.sh" 2>&1 | tee -a "$LOG_FILE"
        
        if ! command -v spicetify &> /dev/null && [ -f "$HOME/.spicetify/spicetify" ]; then
            export PATH="$HOME/.spicetify:$PATH"
            echo 'export PATH="$HOME/.spicetify:$PATH"' >> "$HOME/.bashrc"
        fi
        
        if command -v spicetify &> /dev/null; then
            spicetify backup apply 2>&1 | tee -a "$LOG_FILE" || true
            log_success "Spicetify installed and applied"
        fi
    fi
}

install_fstab() {
    log_section "Configuring fstab"
    
    if [ ! -f /etc/fstab ]; then
        log_error "/etc/fstab does not exist"
        return
    fi
    
    whiptail --title "Fstab Configuration" --yesno "This will add storage drive entries to /etc/fstab with nofail and noatime.\n\nUUID=dda9fe61...  /home/niel/DATA\nUUID=e3af8571...  /run/media/niel/storage\nUUID=b053948d...  /home/niel/Downloads\n\nProceed?" 15 70 || return
    
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
    log_success "/etc/fstab updated"
    
    if sudo mount -a 2>&1 | tee -a "$LOG_FILE"; then
        log_success "mount -a succeeded"
    else
        log_error "mount -a failed. Restore backup: sudo cp /etc/fstab.backup /etc/fstab"
    fi
    
    sudo mkdir -p /home/niel/DATA /run/media/niel/storage /home/niel/Downloads
    log_success "Mount points created"
}

# ─── Main Script ────────────────────────────────────────────────────

show_menu

# Show clock menu if selected
if [[ "$INSTALL_CLOCK" == "on" ]]; then
    show_clock_menu
fi

# Show Spicetify options if selected
if [[ "$INSTALL_SPICETIFY" == "on" ]]; then
    show_spicetify_options
fi

# Show summary
whiptail --title "Installation Summary" --yesno "Ready to install:\n\n  Caelestia KDE: ${INSTALL_CAELESTIA}\n  Custom configs: ${INSTALL_CONFIGS}\n  Kitty terminal: ${INSTALL_KITTY}\n  Icons: ${INSTALL_ICONS}\n  Wallpapers: ${INSTALL_WALLPAPERS}\n  Clock: ${INSTALL_CLOCK}\n  Apps: ${INSTALL_APPS}\n  Niri Anim Switcher: ${INSTALL_NIRI}\n  Spotify+Spicetify: ${INSTALL_SPICETIFY}\n  Fstab: ${INSTALL_FSTAB}\n\nProceed with installation?" 18 70 || exit

# Run installations
if [[ "$INSTALL_CAELESTIA" == "on" ]]; then install_caelestia; fi
if [[ "$INSTALL_CONFIGS" == "on" ]]; then install_configs; fi
if [[ "$INSTALL_KITTY" == "on" ]]; then install_kitty; fi
if [[ "$INSTALL_ICONS" == "on" ]]; then install_icons; fi
if [[ "$INSTALL_WALLPAPERS" == "on" ]]; then install_wallpapers; fi
if [[ "$INSTALL_CLOCK" == "on" ]]; then install_clock; fi
if [[ "$INSTALL_APPS" == "on" ]]; then install_apps; fi
if [[ "$INSTALL_NIRI" == "on" ]]; then install_niri; fi
if [[ "$INSTALL_SPICETIFY" == "on" ]]; then install_spicetify; fi
if [[ "$INSTALL_FSTAB" == "on" ]]; then install_fstab; fi

# Finalize
mkdir -p "$HOME/.local/bin"

if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc" 2>/dev/null || true
fi

# ─── Completion ─────────────────────────────────────────────────────

whiptail --title "Installation Complete" --msgbox "✦ Installation Complete! ✦\n\nComponents installed:\n  Caelestia: ${INSTALL_CAELESTIA}\n  Configs: ${INSTALL_CONFIGS}\n  Kitty: ${INSTALL_KITTY}\n  Icons: ${INSTALL_ICONS}\n  Wallpapers: ${INSTALL_WALLPAPERS}\n  Clock: ${INSTALL_CLOCK}\n  Apps: ${INSTALL_APPS}\n  Niri: ${INSTALL_NIRI}\n  Spotify: ${INSTALL_SPICETIFY}\n  Fstab: ${INSTALL_FSTAB}\n\nLog saved to: $LOG_FILE\n\nMay your desktop always reflect the stars! ✧" 20 70

log_success "Installation completed"
exit 0
