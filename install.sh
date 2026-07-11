#!/bin/bash
# ✦ C A E L E S T I A   K D E   -   O P T I O N A L   I N S T A L L E R ✦
# Fully modular TUI installer with automatic backups and icon theme setting

set -euo pipefail
IFS=$'\n\t'

# ─── Configuration ──────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR=""
LOG_FILE="$HOME/caelestia-install.log"
DRY_RUN=false
VERBOSE=false

# ─── Backup System ──────────────────────────────────────────────────

BACKUP_ROOT="$HOME/.caelestia-backups"
BACKUP_METADATA="$BACKUP_ROOT/backup_manifest.txt"
CURRENT_BACKUP_DIR=""
BACKUP_COUNT=0

# ─── Colors ──────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ─── Dependency Check ──────────────────────────────────────────────

if ! command -v whiptail &> /dev/null; then
    echo "whiptail is required but not installed."
    echo "Install it with:"
    echo "  - Arch: sudo pacman -S whiptail"
    echo "  - Fedora: sudo dnf install whiptail"
    echo "  - Debian/Ubuntu: sudo apt install whiptail"
    exit 1
fi

# ─── Core Functions ────────────────────────────────────────────────

die() { echo -e "${RED}✗ $1${NC}" >&2; log "✗ $1"; exit 1; }
info() { echo -e "${BLUE}ℹ $1${NC}"; log "ℹ $1"; }
success() { echo -e "${GREEN}✓ $1${NC}"; log "✓ $1"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}"; log "⚠ $1"; }
section() { echo -e "\n${GREEN}► $1${NC}\n"; log "► $1"; }

log() {
    echo -e "$1" | sed 's/\x1b\[[0-9;]*m//g' >> "$LOG_FILE" 2>/dev/null || true
}

cleanup() {
    [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ] && rm -rf "$TEMP_DIR" 2>/dev/null || true
}
trap 'cleanup' EXIT INT TERM
TEMP_DIR="$(mktemp -d)"

# ─── Backup Functions ──────────────────────────────────────────────

init_backup_system() {
    mkdir -p "$BACKUP_ROOT"
    touch "$BACKUP_METADATA"
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    CURRENT_BACKUP_DIR="$BACKUP_ROOT/backup_$timestamp"
    mkdir -p "$CURRENT_BACKUP_DIR"
    
    echo "========================================" >> "$BACKUP_METADATA"
    echo "BACKUP SESSION: $timestamp" >> "$BACKUP_METADATA"
    echo "Started: $(date)" >> "$BACKUP_METADATA"
    echo "========================================" >> "$BACKUP_METADATA"
    
    info "Backup session started: $CURRENT_BACKUP_DIR"
}

backup_file_or_dir() {
    local source="$1"
    local description="$2"
    
    [[ "$DRY_RUN" == "true" ]] && return 0
    [[ ! -e "$source" ]] && return 0
    
    local backup_path="$CURRENT_BACKUP_DIR$(dirname "$source")"
    mkdir -p "$backup_path"
    
    local backup_name="$(basename "$source")"
    local backup_target="$backup_path/$backup_name"
    
    if [[ -d "$source" ]]; then
        cp -r "$source" "$backup_target" 2>/dev/null || {
            warn "Failed to backup directory: $source"
            return 1
        }
    else
        cp "$source" "$backup_target" 2>/dev/null || {
            warn "Failed to backup file: $source"
            return 1
        }
    fi
    
    echo "$source → $backup_target ($description)" >> "$BACKUP_METADATA"
    ((BACKUP_COUNT++))
    
    success "  ✓ Backed up: $source"
    return 0
}

restore_backup() {
    section "Restore from Backup"
    
    local backups=()
    for dir in "$BACKUP_ROOT"/backup_*; do
        if [[ -d "$dir" ]]; then
            local name=$(basename "$dir")
            local date_str=$(echo "$name" | sed 's/backup_//')
            backups+=("$dir" "Backup from $date_str" "OFF")
        fi
    done
    
    if [[ ${#backups[@]} -eq 0 ]]; then
        whiptail --title "Restore" --msgbox "No backups found in $BACKUP_ROOT" 8 60
        return 0
    fi
    
    local selected_backup=$(whiptail --title "Select Backup to Restore" \
        --radiolist "Choose a backup to restore:" 20 80 10 \
        "${backups[@]}" \
        3>&1 1>&2 2>&3) || return 0
    
    if [[ -z "$selected_backup" ]]; then
        return 0
    fi
    
    local files_to_restore=()
    while IFS= read -r line; do
        if [[ "$line" =~ ^/ ]]; then
            local original_file=$(echo "$line" | awk '{print $1}')
            files_to_restore+=("$original_file" "")
        fi
    done < <(grep "^/" "$BACKUP_METADATA" | grep -A 100 "BACKUP SESSION: $(basename "$selected_backup" | sed 's/backup_//')")
    
    local summary="This will restore the following files/directories:\n\n"
    for file in "${files_to_restore[@]}"; do
        summary+="  • $file\n"
    done
    summary+="\nWARNING: This will overwrite current files!"
    
    if ! whiptail --title "Confirm Restore" --yesno "$summary" 20 70; then
        return 0
    fi
    
    local restored_count=0
    while IFS= read -r line; do
        if [[ "$line" =~ ^/ ]]; then
            local original=$(echo "$line" | awk '{print $1}')
            local backup_path="$selected_backup$original"
            
            if [[ -e "$backup_path" ]]; then
                local temp_backup="$CURRENT_BACKUP_DIR/restore_pre_backup$(dirname "$original")"
                mkdir -p "$temp_backup"
                if [[ -e "$original" ]]; then
                    cp -r "$original" "$temp_backup/" 2>/dev/null || true
                fi
                
                rm -rf "$original" 2>/dev/null || true
                if [[ -d "$backup_path" ]]; then
                    cp -r "$backup_path" "$(dirname "$original")/"
                else
                    cp "$backup_path" "$original"
                fi
                
                ((restored_count++))
                success "Restored: $original"
            fi
        fi
    done < <(grep "^/" "$BACKUP_METADATA" | grep -A 100 "BACKUP SESSION: $(basename "$selected_backup" | sed 's/backup_//')")
    
    whiptail --title "Restore Complete" --msgbox "Restored $restored_count files/directories\n\nA pre-restore backup was saved in:\n$CURRENT_BACKUP_DIR" 12 70
}

list_backups() {
    section "Available Backups"
    
    echo "Backups stored in: $BACKUP_ROOT"
    echo ""
    echo "========================================"
    echo "BACKUP SESSIONS:"
    echo "========================================"
    
    for dir in "$BACKUP_ROOT"/backup_*; do
        if [[ -d "$dir" ]]; then
            local name=$(basename "$dir")
            local date_str=$(echo "$name" | sed 's/backup_//')
            local file_count=$(find "$dir" -type f 2>/dev/null | wc -l)
            local dir_count=$(find "$dir" -type d 2>/dev/null | wc -l)
            echo "• $date_str: $file_count files, $dir_count directories"
            echo "  Location: $dir"
            echo ""
        fi
    done
}

# ─── Package Manager Detection ──────────────────────────────────────

detect_package_manager() {
    if command -v pacman &> /dev/null; then
        echo "pacman"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v apt &> /dev/null; then
        echo "apt"
    else
        echo "unknown"
    fi
}

PKG_MANAGER="$(detect_package_manager)"
case $PKG_MANAGER in
    pacman)
        INSTALL_CMD="sudo pacman -S --needed --noconfirm"
        if command -v yay &> /dev/null; then
            AUR_CMD="yay -S --needed --noconfirm"
            AUR_HELPER="yay"
        elif command -v paru &> /dev/null; then
            AUR_CMD="paru -S --needed --noconfirm"
            AUR_HELPER="paru"
        else
            AUR_CMD=""
            AUR_HELPER=""
        fi
        ;;
    dnf)
        INSTALL_CMD="sudo dnf install -y"
        AUR_CMD=""
        AUR_HELPER=""
        ;;
    apt)
        INSTALL_CMD="sudo apt install -y"
        AUR_CMD=""
        AUR_HELPER=""
        ;;
    *)
        INSTALL_CMD=""
        AUR_CMD=""
        AUR_HELPER=""
        warn "Unsupported or unknown package manager"
        ;;
esac

# ─── Safe Package Installation ──────────────────────────────────────

safe_install() {
    local pkg="$1"
    local optional="${2:-false}"
    
    if [[ -z "$INSTALL_CMD" ]]; then
        [[ "$optional" == "true" ]] && return 0 || warn "Cannot install $pkg - no package manager"
        return 1
    fi
    
    info "Installing: $pkg"
    $INSTALL_CMD "$pkg" 2>&1 | tee -a "$LOG_FILE" || {
        [[ "$optional" == "true" ]] && warn "Failed to install $pkg (optional)" || {
            warn "Failed to install $pkg"
            return 1
        }
        return 0
    }
    return 0
}

# ─── Icon Theme Setting Functions ──────────────────────────────────

set_icon_theme() {
    local icon_name="$1"
    
    section "Setting icon theme to: $icon_name"
    
    # Detect KDE version and use appropriate command
    local kwrite_cmd=""
    if command -v kwriteconfig6 &> /dev/null; then
        kwrite_cmd="kwriteconfig6"
    elif command -v kwriteconfig5 &> /dev/null; then
        kwrite_cmd="kwriteconfig5"
    else
        warn "kwriteconfig not found - cannot set icon theme automatically"
        return 1
    fi
    
    # Backup existing kdeglobals
    local kdeglobals="$HOME/.config/kdeglobals"
    [[ -f "$kdeglobals" ]] && backup_file_or_dir "$kdeglobals" "kdeglobals (icon theme)"
    
    # Set the icon theme
    info "Setting icon theme using $kwrite_cmd..."
    $kwrite_cmd --file kdeglobals --group Icons --key Theme "$icon_name" 2>&1 | tee -a "$LOG_FILE"
    
    # Also set for GTK applications
    if command -v gsettings &> /dev/null; then
        info "Setting icon theme for GTK applications..."
        gsettings set org.gnome.desktop.interface icon-theme "$icon_name" 2>&1 | tee -a "$LOG_FILE" || true
    fi
    
    # Create/update GTK settings
    local gtk_settings="$HOME/.config/gtk-3.0/settings.ini"
    if [[ -f "$gtk_settings" ]]; then
        backup_file_or_dir "$gtk_settings" "GTK3 settings"
    fi
    mkdir -p "$(dirname "$gtk_settings")"
    
    # Update GTK settings file
    if ! grep -q "^gtk-icon-theme-name" "$gtk_settings" 2>/dev/null; then
        echo "gtk-icon-theme-name=$icon_name" >> "$gtk_settings"
    else
        sed -i "s/^gtk-icon-theme-name=.*/gtk-icon-theme-name=$icon_name/" "$gtk_settings"
    fi
    
    # Also for GTK4
    local gtk4_settings="$HOME/.config/gtk-4.0/settings.ini"
    if [[ -f "$gtk4_settings" ]]; then
        backup_file_or_dir "$gtk4_settings" "GTK4 settings"
    fi
    mkdir -p "$(dirname "$gtk4_settings")"
    if ! grep -q "^gtk-icon-theme-name" "$gtk4_settings" 2>/dev/null; then
        echo "gtk-icon-theme-name=$icon_name" >> "$gtk4_settings"
    else
        sed -i "s/^gtk-icon-theme-name=.*/gtk-icon-theme-name=$icon_name/" "$gtk4_settings"
    fi
    
    success "Icon theme set to: $icon_name"
    
    # Ask to restart KDE
    if whiptail --title "Apply Changes" --yesno "Icon theme has been set.\n\nRestart Plasma Shell to apply changes immediately?" 10 60; then
        info "Restarting Plasma Shell..."
        if command -v kquitapp6 &> /dev/null; then
            kquitapp6 plasmashell 2>/dev/null || true
            sleep 2
            kstart6 plasmashell 2>/dev/null || true
        elif command -v kquitapp5 &> /dev/null; then
            kquitapp5 plasmashell 2>/dev/null || true
            sleep 2
            kstart5 plasmashell 2>/dev/null || true
        else
            warn "Cannot restart Plasma Shell automatically"
            warn "Please restart KDE manually or run:"
            warn "  plasmashell --replace &"
        fi
        success "Plasma Shell restarted"
    else
        info "Changes will apply after next login or Plasma restart"
        info "You can restart Plasma manually with: plasmashell --replace &"
    fi
}

# ─── Create variety.conf content ──────────────────────────────────

create_variety_conf() {
    cat > "$TEMP_DIR/variety.conf" << 'EOF'
[Variety]
show_notifications=true
slideshow_enabled=true
slideshow_interval=600
download_enabled=true
download_sources=wallhaven,unsplash,desktoppr,interfacelift
download_folder=~/Pictures/Wallpapers
download_history_size=50
favorites_folder=~/Pictures/Wallpapers/Favorites
download_interval=120
add_downloaded_to_slideshow=true
randomize=true
display_mode=zoom
show_clock=false
clock_font=DejaVu Sans 24
clock_color=#FFFFFF
clock_position=bottom-right
show_quotes=false
quotes_category=inspirational
show_source=true
transition_effect=fade
transition_duration=1.5
pause_on_fullscreen=true
pause_on_active_fullscreen=true
live_wallpaper_enabled=false
autostart=true
database_folder=~/.local/share/variety
log_level=warning
disable_screensaver=false
pywal_enabled=false
update_xresources=false
sort_order=random
orientation=all
min_resolution=1920x1080
max_resolution=7680x4320
EOF
}

# ─── TUI Functions ──────────────────────────────────────────────────

show_main_menu() {
    local title="✧ Caelestia KDE Installer ✧"
    local msg="Select components to install (Space to toggle, Enter to confirm)"
    
    local options=(
        "caelestia" "Caelestia KDE theme (full KDE setup)" "ON"
        "configs" "Custom configs (fastfetch, fish, kitty)" "ON"
        "variety" "Variety wallpaper config (force install)" "ON"
        "kitty" "Kitty terminal emulator" "OFF"
        "icons" "Neo-Candy-Papirus-Carmine icons + SET THEME" "OFF"
        "wallpapers" "Wallpaper-cache (wallpaper collection)" "ON"
        "clock" "Modern Clock widget (choose variant later)" "OFF"
        "apps" "Applications (Viber, Signal, Zoom, Thunar, Chrome)" "OFF"
        "niri" "Niri Animation Switcher" "OFF"
        "spicetify" "Spotify + Spicetify (music theming)" "OFF"
        "fstab" "Fstab configuration (auto-mount drives)" "OFF"
        "restore" "Restore from previous backup" "OFF"
    )
    
    SELECTED=$(whiptail --title "$title" --checklist "$msg" 22 80 12 \
        "${options[@]}" 3>&1 1>&2 2>&3) || {
        info "Installation cancelled by user"
        exit 0
    }
    
    INSTALL_CAELESTIA="false"; INSTALL_CONFIGS="false"; INSTALL_VARIETY="false"
    INSTALL_KITTY="false"; INSTALL_ICONS="false"; INSTALL_WALLPAPERS="false"
    INSTALL_CLOCK="false"; INSTALL_APPS="false"; INSTALL_NIRI="false"
    INSTALL_SPICETIFY="false"; INSTALL_FSTAB="false"; RESTORE_BACKUP="false"
    
    [[ "$SELECTED" == *"caelestia"* ]] && INSTALL_CAELESTIA="true"
    [[ "$SELECTED" == *"configs"* ]] && INSTALL_CONFIGS="true"
    [[ "$SELECTED" == *"variety"* ]] && INSTALL_VARIETY="true"
    [[ "$SELECTED" == *"kitty"* ]] && INSTALL_KITTY="true"
    [[ "$SELECTED" == *"icons"* ]] && INSTALL_ICONS="true"
    [[ "$SELECTED" == *"wallpapers"* ]] && INSTALL_WALLPAPERS="true"
    [[ "$SELECTED" == *"clock"* ]] && INSTALL_CLOCK="true"
    [[ "$SELECTED" == *"apps"* ]] && INSTALL_APPS="true"
    [[ "$SELECTED" == *"niri"* ]] && INSTALL_NIRI="true"
    [[ "$SELECTED" == *"spicetify"* ]] && INSTALL_SPICETIFY="true"
    [[ "$SELECTED" == *"fstab"* ]] && INSTALL_FSTAB="true"
    [[ "$SELECTED" == *"restore"* ]] && RESTORE_BACKUP="true"
}

show_clock_menu() {
    CLOCK_CHOICE=$(whiptail --title "Modern Clock Widget" \
        --radiolist "Select a clock widget to install:" 15 70 3 \
        "colorful" "Colorful Digital Clock (color picker + custom separator)" ON \
        "nothing" "Nothing OS Digital Clock (pill-style)" OFF \
        "skip" "Skip this widget" OFF \
        3>&1 1>&2 2>&3) || CLOCK_CHOICE="skip"
    
    [[ "$CLOCK_CHOICE" == "skip" ]] && INSTALL_CLOCK="false"
}

show_spicetify_menu() {
    SPOTIFY_ACTION=$(whiptail --title "Spotify Setup" \
        --radiolist "How to handle Spotify launch before Spicetify setup:" 15 70 3 \
        "wait" "Launch Spotify now - wait for you to log in" ON \
        "background" "Launch Spotify now - continue in background" OFF \
        "skip" "Skip - I'll launch Spotify manually later" OFF \
        3>&1 1>&2 2>&3) || SPOTIFY_ACTION="skip"
}

show_fstab_menu() {
    local username="${USER}"
    local homedir="${HOME}"
    
    FSTAB_ENTRIES=$(whiptail --title "Fstab Configuration" \
        --inputbox "Enter fstab mount entries (one per line):\n\nFormat: UUID=...  /mount/point  ext4  defaults,noatime,nofail  0  2\n\nLeave empty to skip this step." \
        15 70 \
        "UUID=dda9fe61-a2b0-4d5c-9076-8fa3cff067b4  ${homedir}/DATA          ext4  defaults,noatime,nofail  0  2\nUUID=e3af8571-cddf-4edc-86f2-5efa6d7fec2e  ${homedir}/storage  ext4  defaults,noatime,nofail  0  2" \
        3>&1 1>&2 2>&3) || FSTAB_ENTRIES=""
    
    [[ -z "$FSTAB_ENTRIES" ]] && {
        warn "No fstab entries provided - skipping fstab configuration"
        INSTALL_FSTAB="false"
    }
}

# ─── Installation Functions ──────────────────────────────────────────

install_caelestia() {
    section "Installing Caelestia KDE"
    
    local caelestia_dir="$HOME/caelestia-dots-kde"
    
    [[ -d "$caelestia_dir" ]] && backup_file_or_dir "$caelestia_dir" "Caelestia KDE directory"
    
    if [[ -d "$caelestia_dir" ]]; then
        if whiptail --title "Caelestia" --yesno "Directory ~/caelestia-dots-kde already exists.\nRemove and re-clone?" 10 60; then
            rm -rf "$caelestia_dir"
        else
            info "Using existing directory"
            return 0
        fi
    fi
    
    info "Cloning caelestia-dots-kde..."
    git clone https://github.com/ladybug-me/caelestia-dots-kde "$caelestia_dir" 2>&1 | tee -a "$LOG_FILE" || {
        warn "Failed to clone caelestia-dots-kde"
        return 1
    }
    
    if [[ -f "$caelestia_dir/setup.sh" ]]; then
        cd "$caelestia_dir"
        chmod +x setup.sh
        bash ./setup.sh 2>&1 | tee -a "$LOG_FILE" || {
            warn "Caelestia setup encountered issues"
            whiptail --title "Warning" --msgbox "Caelestia setup had issues. Check the log file:\n$LOG_FILE" 10 60
        }
        cd "$SCRIPT_DIR"
    fi
    
    success "Caelestia KDE installation completed"
}

install_configs() {
    section "Applying custom configuration files"
    
    local config_dir="$HOME/.config"
    mkdir -p "$config_dir"
    
    local configs=(
        "fastfetch"
        "fish"
        "kitty"
    )
    
    for conf in "${configs[@]}"; do
        local src="$SCRIPT_DIR/$conf"
        local dest="$config_dir/$conf"
        
        if [[ -d "$src" ]]; then
            [[ -d "$dest" ]] && backup_file_or_dir "$dest" "$conf config"
            
            info "Copying $conf config..."
            mkdir -p "$dest"
            cp -r "$src/"* "$dest/" 2>/dev/null || true
            success "  ✓ $conf config applied"
        else
            warn "  ⚠ $conf directory not found, skipping"
        fi
    done
}

install_variety_config() {
    section "Installing Variety config (FORCE MODE)"
    
    local variety_dir="$HOME/.config/variety"
    local variety_conf="$variety_dir/variety.conf"
    
    [[ -f "$variety_conf" ]] && backup_file_or_dir "$variety_conf" "Variety config"
    
    mkdir -p "$variety_dir"
    create_variety_conf
    
    info "Force copying variety.conf to $variety_conf"
    cp -f "$TEMP_DIR/variety.conf" "$variety_conf"
    
    if [[ -f "$variety_conf" ]]; then
        success "Variety config force-installed to $variety_conf"
    else
        warn "Failed to copy variety.conf"
        return 1
    fi
    
    if pgrep -x "variety" > /dev/null; then
        if whiptail --title "Variety" --yesno "Variety is currently running. Restart it to apply new config?" 8 60; then
            info "Restarting Variety..."
            pkill -x variety 2>/dev/null || true
            sleep 2
            variety &> /dev/null &
            success "Variety restarted"
        fi
    fi
}

install_kitty() {
    section "Installing Kitty terminal"
    safe_install "kitty"
}

install_icons() {
    section "Installing Neo-Candy-Papirus-Carmine Icons"
    
    local icon_name="neo-candy-papirus-carmine-icons"
    local target_dir="$HOME/.local/share/icons"
    local icon_target="$target_dir/$icon_name"
    
    # Backup existing icons
    [[ -d "$icon_target" ]] && backup_file_or_dir "$icon_target" "Icon theme"
    
    # Install icons
    if [[ -n "$AUR_HELPER" ]]; then
        info "Installing from AUR using $AUR_HELPER..."
        $AUR_CMD "${icon_name}-git" 2>&1 | tee -a "$LOG_FILE" || {
            warn "AUR installation failed, trying manual install..."
            install_icons_manually
        }
    else
        install_icons_manually
    fi
    
    # Verify installation
    if [[ -d "$icon_target" ]] || [[ -d "/usr/share/icons/$icon_name" ]] || [[ -d "$HOME/.icons/$icon_name" ]]; then
        success "Icon theme installed successfully"
        
        # ─── SET THE ICON THEME ────────────────────────────────
        if whiptail --title "Set Icon Theme" --yesno "Neo-Candy-Papirus-Carmine icons installed.\n\nSet it as the default icon theme now?" 10 60; then
            set_icon_theme "$icon_name"
        else
            info "Icon theme installed but not set as default"
            info "You can set it later with:"
            info "  kwriteconfig6 --file kdeglobals --group Icons --key Theme $icon_name"
            info "  gsettings set org.gnome.desktop.interface icon-theme $icon_name"
        fi
    else
        warn "Icon theme installation may have failed"
    fi
}

install_icons_manually() {
    local icon_dir="$TEMP_DIR/neo-candy-papirus-carmine-icons"
    local target_dir="$HOME/.local/share/icons"
    
    info "Cloning icon repository..."
    git clone https://github.com/voidtech/neo-candy-papirus-carmine-icons.git "$icon_dir" 2>&1 | tee -a "$LOG_FILE" || {
        warn "Failed to clone icon repository"
        return 1
    }
    
    mkdir -p "$target_dir"
    if [[ -d "$icon_dir/neo-candy-papirus-carmine-icons" ]]; then
        cp -r "$icon_dir/neo-candy-papirus-carmine-icons" "$target_dir/"
    else
        cp -r "$icon_dir/." "$target_dir/neo-candy-papirus-carmine-icons/"
    fi
    
    success "Icons installed manually to $target_dir"
}

install_wallpapers() {
    section "Installing wallpaper-cache"
    
    local wallpaper_dir="$HOME/wallpaper-cache"
    
    [[ -d "$wallpaper_dir" ]] && backup_file_or_dir "$wallpaper_dir" "Wallpaper cache"
    
    if [[ -d "$wallpaper_dir" ]]; then
        if whiptail --title "Wallpaper Cache" --yesno "Directory ~/wallpaper-cache already exists.\nRemove and re-clone?" 10 60; then
            rm -rf "$wallpaper_dir"
        else
            info "Using existing wallpaper cache"
            return 0
        fi
    fi
    
    info "Cloning wallpaper-cache..."
    git clone https://github.com/avraniel/wallpaper-cache.git "$wallpaper_dir" 2>&1 | tee -a "$LOG_FILE" || {
        warn "Failed to clone wallpaper-cache"
        return 1
    }
    
    if [[ -f "$wallpaper_dir/install_wca" ]]; then
        chmod +x "$wallpaper_dir/install_wca"
        cd "$wallpaper_dir"
        bash ./install_wca 2>&1 | tee -a "$LOG_FILE"
        cd "$SCRIPT_DIR"
    fi
    
    success "Wallpapers installed"
}

install_clock() {
    section "Installing Modern Clock widget"
    
    [[ "$CLOCK_CHOICE" == "skip" ]] && { info "Clock installation skipped"; return 0; }
    
    local repo=""
    local name=""
    local plasmoid_id=""
    
    case "$CLOCK_CHOICE" in
        colorful)
            repo="https://github.com/v-n7k/plasma-panel-digital-clock.git"
            name="Colorful Digital Clock"
            plasmoid_id="co.n7k.plasma.digitalclock"
            ;;
        nothing)
            repo="https://github.com/jaxparrow07/nothing-kde-widgets.git"
            name="Nothing Digital Clock"
            plasmoid_id="nothing.clock.digital"
            ;;
        *)
            warn "Unknown clock choice: $CLOCK_CHOICE"
            return 1
            ;;
    esac
    
    info "Installing $name..."
    local clock_dir="$TEMP_DIR/clock-widget"
    git clone "$repo" "$clock_dir" 2>&1 | tee -a "$LOG_FILE" || {
        warn "Failed to clone clock widget repository"
        return 1
    }
    
    local plasmoid_target="$HOME/.local/share/plasma/plasmoids/$plasmoid_id"
    [[ -d "$plasmoid_target" ]] && backup_file_or_dir "$plasmoid_target" "Clock widget"
    
    mkdir -p "$HOME/.local/share/plasma/plasmoids"
    
    if [[ -d "$clock_dir/package" ]]; then
        mkdir -p "$HOME/.local/share/plasma/plasmoids/$plasmoid_id"
        cp -r "$clock_dir/package/." "$HOME/.local/share/plasma/plasmoids/$plasmoid_id/"
    elif [[ -d "$clock_dir/packages/clock-digital" ]] && command -v kpackagetool6 &> /dev/null; then
        cd "$clock_dir"
        kpackagetool6 --type Plasma/Applet -i packages/clock-digital 2>&1 | tee -a "$LOG_FILE"
        cd "$SCRIPT_DIR"
    else
        warn "Could not find installation method for clock widget"
        return 1
    fi
    
    kquitapp6 plasmashell 2>/dev/null || true
    sleep 2
    kstart6 plasmashell 2>/dev/null || true
    
    success "$name installed"
}

install_apps() {
    section "Installing applications"
    
    case $PKG_MANAGER in
        pacman)
            safe_install "thunar" && safe_install "thunar-volman"
            safe_install "thunar-shares-plugin" true
            
            if [[ -n "$AUR_HELPER" ]]; then
                info "Installing from AUR..."
                $AUR_CMD google-chrome viber signal-desktop zoom 2>&1 | tee -a "$LOG_FILE" || {
                    warn "Some applications failed to install from AUR"
                }
            else
                warn "No AUR helper found. Skipping non-repo applications."
                whiptail --title "Warning" --msgbox "No AUR helper found.\nGoogle Chrome, Viber, Signal, and Zoom will not be installed." 10 60
            fi
            ;;
        dnf)
            safe_install "thunar" && safe_install "thunar-volman"
            
            sudo dnf install -y fedora-workstation-repositories 2>&1 | tee -a "$LOG_FILE" || true
            sudo dnf config-manager --set-enabled google-chrome 2>&1 | tee -a "$LOG_FILE" || true
            safe_install "google-chrome-stable" true
            
            if command -v flatpak &> /dev/null; then
                info "Installing Flatpak applications..."
                flatpak install -y flathub com.viber.Viber 2>&1 | tee -a "$LOG_FILE" || true
                flatpak install -y flathub org.signal.Signal 2>&1 | tee -a "$LOG_FILE" || true
                flatpak install -y flathub us.zoom.Zoom 2>&1 | tee -a "$LOG_FILE" || true
            fi
            ;;
        apt)
            safe_install "thunar" && safe_install "thunar-volman"
            safe_install "thunar-shares-plugin" true
            
            wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add - 2>&1 | tee -a "$LOG_FILE" || true
            echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list 2>&1 | tee -a "$LOG_FILE" || true
            sudo apt update 2>&1 | tee -a "$LOG_FILE" || true
            safe_install "google-chrome-stable" true
            
            wget -qO- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > "$TEMP_DIR/signal.gpg" 2>/dev/null || true
            sudo mv "$TEMP_DIR/signal.gpg" /usr/share/keyrings/ 2>/dev/null || true
            echo "deb [arch=amd64 signed-by=/usr/share/keyrings/signal.gpg] https://updates.signal.org/desktop/apt xenial main" | sudo tee /etc/apt/sources.list.d/signal-xenial.list 2>/dev/null || true
            sudo apt update 2>&1 | tee -a "$LOG_FILE" || true
            safe_install "signal-desktop" true
            
            wget -O "$TEMP_DIR/viber.deb" https://download.cdn.viber.com/desktop/Linux/viber.deb 2>&1 | tee -a "$LOG_FILE" || true
            sudo dpkg -i "$TEMP_DIR/viber.deb" 2>&1 | tee -a "$LOG_FILE" || sudo apt install -f -y 2>&1 | tee -a "$LOG_FILE" || true
            
            wget -O "$TEMP_DIR/zoom.deb" https://zoom.us/client/latest/zoom_amd64.deb 2>&1 | tee -a "$LOG_FILE" || true
            sudo dpkg -i "$TEMP_DIR/zoom.deb" 2>&1 | tee -a "$LOG_FILE" || sudo apt install -f -y 2>&1 | tee -a "$LOG_FILE" || true
            ;;
        *)
            warn "Unsupported package manager. Skipping application installation."
            return 1
            ;;
    esac
    
    success "Application installation completed"
}

install_niri() {
    section "Installing Niri Animation Switcher"
    
    if ! command -v niri &> /dev/null; then
        warn "Niri compositor not detected. The tool will be installed but may not work."
        if ! whiptail --title "Warning" --yesno "Niri compositor not found. Continue anyway?" 8 60; then
            return 0
        fi
    fi
    
    case $PKG_MANAGER in
        pacman)
            safe_install "python" && safe_install "python-gobject"
            safe_install "gtk3" && safe_install "git"
            ;;
        dnf)
            safe_install "python3" && safe_install "python3-gobject"
            safe_install "gtk3" && safe_install "git"
            ;;
        apt)
            safe_install "python3" && safe_install "python3-gi"
            safe_install "gir1.2-gtk-3.0" && safe_install "git"
            ;;
        *)
            warn "Cannot install dependencies - unsupported package manager"
            return 1
            ;;
    esac
    
    local niri_dir="$HOME/niri-anim-switcher"
    
    [[ -d "$niri_dir" ]] && backup_file_or_dir "$niri_dir" "Niri anim switcher"
    
    if [[ -d "$niri_dir" ]]; then
        if whiptail --title "Niri" --yesno "Directory ~/niri-anim-switcher already exists.\nRemove and re-clone?" 10 60; then
            rm -rf "$niri_dir"
        else
            info "Using existing niri-anim-switcher"
            return 0
        fi
    fi
    
    info "Cloning niri-anim-switcher..."
    git clone https://github.com/avraniel/niri-anim-switcher.git "$niri_dir" 2>&1 | tee -a "$LOG_FILE" || {
        warn "Failed to clone niri-anim-switcher"
        return 1
    }
    
    if [[ -f "$niri_dir/niri-anim-switcher.py" ]]; then
        chmod +x "$niri_dir/niri-anim-switcher.py"
        mkdir -p "$HOME/.local/bin"
        local bin_target="$HOME/.local/bin/niri-anim"
        [[ -f "$bin_target" ]] && backup_file_or_dir "$bin_target" "Niri anim binary"
        cp "$niri_dir/niri-anim-switcher.py" "$bin_target"
        success "Niri Animation Switcher installed to ~/.local/bin/niri-anim"
    fi
}

install_spicetify() {
    section "Installing Spotify + Spicetify"
    
    local spotify_installed="false"
    local spotify_type=""
    
    if command -v spotify &> /dev/null; then
        spotify_installed="true"
        spotify_type="system"
    elif flatpak list 2>/dev/null | grep -q "com.spotify.Client"; then
        spotify_installed="true"
        spotify_type="flatpak"
    elif command -v pacman &> /dev/null && pacman -Q spotify-launcher 2>/dev/null; then
        spotify_installed="true"
        spotify_type="arch-launcher"
    fi
    
    if [[ "$spotify_installed" == "false" ]]; then
        info "Installing Spotify..."
        case $PKG_MANAGER in
            pacman)
                safe_install "spotify-launcher" && {
                    spotify_installed="true"
                    spotify_type="arch-launcher"
                } || true
                ;;
            dnf)
                safe_install "lpf-spotify-client" && {
                    spotify_installed="true"
                    spotify_type="system"
                } || true
                ;;
            apt)
                wget -qO "$TEMP_DIR/spotify.gpg" https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg 2>&1 | tee -a "$LOG_FILE" || true
                sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg "$TEMP_DIR/spotify.gpg" 2>&1 | tee -a "$LOG_FILE" || true
                echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list 2>&1 | tee -a "$LOG_FILE" || true
                sudo apt update 2>&1 | tee -a "$LOG_FILE" || true
                safe_install "spotify-client" && {
                    spotify_installed="true"
                    spotify_type="system"
                } || true
                ;;
            *)
                warn "Cannot install Spotify - unsupported package manager"
                return 1
                ;;
        esac
    fi
    
    [[ "$spotify_installed" == "false" ]] && {
        warn "Spotify not installed. Skipping Spicetify setup."
        return 1
    }
    
    if [[ "$SPOTIFY_ACTION" == "wait" || "$SPOTIFY_ACTION" == "background" ]]; then
        info "Launching Spotify..."
        spotify &
        sleep 5
        
        if [[ "$SPOTIFY_ACTION" == "wait" ]]; then
            whiptail --title "Spotify" --msgbox "Please log in to Spotify, then press OK to continue." 10 60
        else
            sleep 15
        fi
    fi
    
    info "Installing Spicetify..."
    
    case $PKG_MANAGER in
        pacman|dnf|apt)
            safe_install "curl" && safe_install "unzip"
            ;;
    esac
    
    [[ -d "$HOME/.spicetify" ]] && backup_file_or_dir "$HOME/.spicetify" "Spicetify config"
    
    curl -fsSL https://raw.githubusercontent.com/spicetify/cli/main/install.sh -o "$TEMP_DIR/install_spicetify.sh"
    chmod +x "$TEMP_DIR/install_spicetify.sh"
    bash "$TEMP_DIR/install_spicetify.sh" 2>&1 | tee -a "$LOG_FILE" || {
        warn "Spicetify installation failed"
        return 1
    }
    
    if ! command -v spicetify &> /dev/null && [[ -f "$HOME/.spicetify/spicetify" ]]; then
        export PATH="$HOME/.spicetify:$PATH"
        local bashrc="$HOME/.bashrc"
        local zshrc="$HOME/.zshrc"
        [[ -f "$bashrc" ]] && backup_file_or_dir "$bashrc" ".bashrc"
        [[ -f "$zshrc" ]] && backup_file_or_dir "$zshrc" ".zshrc"
        echo 'export PATH="$HOME/.spicetify:$PATH"' >> "$bashrc"
        echo 'export PATH="$HOME/.spicetify:$PATH"' >> "$zshrc" 2>/dev/null || true
    fi
    
    if command -v spicetify &> /dev/null; then
        spicetify backup apply 2>&1 | tee -a "$LOG_FILE" || true
        success "Spicetify installed and applied"
    else
        warn "Spicetify not found in PATH"
    fi
}

install_fstab() {
    section "Configuring fstab"
    
    [[ -z "$FSTAB_ENTRIES" ]] && {
        info "No fstab entries provided - skipping"
        return 0
    }
    
    if [[ ! -f /etc/fstab ]]; then
        warn "/etc/fstab does not exist - cannot configure"
        return 1
    fi
    
    local fstab_backup="/etc/fstab.backup.$(date +%Y%m%d_%H%M%S)"
    sudo cp /etc/fstab "$fstab_backup"
    success "Backup created: $fstab_backup"
    log "Fstab backup: $fstab_backup"
    
    local temp_fstab="$TEMP_DIR/fstab.new"
    local uuids=()
    
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local uuid=$(echo "$line" | awk '{print $1}')
        [[ -n "$uuid" ]] && uuids+=("$uuid")
    done <<< "$FSTAB_ENTRIES"
    
    sudo grep -v -F -f <(printf "%s\n" "${uuids[@]}") /etc/fstab > "$temp_fstab" 2>/dev/null || true
    
    echo "" >> "$temp_fstab"
    echo "# Storage drives (added by Caelestia installer on $(date))" >> "$temp_fstab"
    echo "$FSTAB_ENTRIES" >> "$temp_fstab"
    
    sudo mv "$temp_fstab" /etc/fstab
    success "/etc/fstab updated"
    
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local mount_point=$(echo "$line" | awk '{print $2}')
        if [[ -n "$mount_point" ]]; then
            sudo mkdir -p "$mount_point"
            info "Created mount point: $mount_point"
        fi
    done <<< "$FSTAB_ENTRIES"
    
    if sudo mount -a 2>&1 | tee -a "$LOG_FILE"; then
        success "All drives mounted successfully"
    else
        warn "mount -a failed. Check the log and restore backup if needed:"
        warn "  sudo cp $fstab_backup /etc/fstab"
    fi
}

# ─── Summary and Confirmation ──────────────────────────────────────

show_summary() {
    local summary="Ready to install:\n\n"
    summary+="  Caelestia KDE:      $INSTALL_CAELESTIA\n"
    summary+="  Custom configs:     $INSTALL_CONFIGS\n"
    summary+="  Variety config:     $INSTALL_VARIETY (FORCE MODE)\n"
    summary+="  Kitty terminal:     $INSTALL_KITTY\n"
    summary+="  Icons:              $INSTALL_ICONS + SET THEME\n"
    summary+="  Wallpapers:         $INSTALL_WALLPAPERS\n"
    summary+="  Clock:              $INSTALL_CLOCK (${CLOCK_CHOICE:-none})\n"
    summary+="  Apps:               $INSTALL_APPS\n"
    summary+="  Niri Anim Switcher: $INSTALL_NIRI\n"
    summary+="  Spotify+Spicetify:  $INSTALL_SPICETIFY\n"
    summary+="  Fstab:              $INSTALL_FSTAB\n"
    summary+="  Restore:            $RESTORE_BACKUP\n\n"
    summary+="Backup location: $BACKUP_ROOT\n"
    summary+="Log file: $LOG_FILE"
    
    if ! whiptail --title "Installation Summary" --yesno "$summary" 24 70; then
        info "Installation cancelled by user"
        exit 0
    fi
}

# ─── Main Script ─────────────────────────────────────────────────────

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run) DRY_RUN=true; shift ;;
            --verbose) VERBOSE=true; shift ;;
            --list-backups) 
                init_backup_system
                list_backups
                exit 0
                ;;
            --restore)
                init_backup_system
                restore_backup
                exit 0
                ;;
            --help)
                cat << EOF
Usage: $0 [OPTIONS]

A fully optional TUI installer for Caelestia KDE configuration with automatic backups.

OPTIONS:
    --dry-run       Simulate installation without making changes
    --verbose       Show more detailed output
    --list-backups  List all available backups
    --restore       Restore from a previous backup
    --help          Show this help message

All components are optional and can be toggled in the TUI menu.
Backups are automatically created before any file/directory is modified.
EOF
                exit 0
                ;;
            *) die "Unknown option: $1";;
        esac
    done
    
    init_backup_system
    show_main_menu
    
    if [[ "$RESTORE_BACKUP" == "true" ]]; then
        restore_backup
        if [[ "$INSTALL_CAELESTIA" == "false" && "$INSTALL_CONFIGS" == "false" && \
              "$INSTALL_VARIETY" == "false" && "$INSTALL_KITTY" == "false" && \
              "$INSTALL_ICONS" == "false" && "$INSTALL_WALLPAPERS" == "false" && \
              "$INSTALL_CLOCK" == "false" && "$INSTALL_APPS" == "false" && \
              "$INSTALL_NIRI" == "false" && "$INSTALL_SPICETIFY" == "false" && \
              "$INSTALL_FSTAB" == "false" ]]; then
            exit 0
        fi
    fi
    
    [[ "$INSTALL_CLOCK" == "true" ]] && show_clock_menu
    [[ "$INSTALL_SPICETIFY" == "true" ]] && show_spicetify_menu
    [[ "$INSTALL_FSTAB" == "true" ]] && show_fstab_menu
    
    show_summary
    
    if [[ "$DRY_RUN" == "true" ]]; then
        info "DRY RUN MODE - No changes will be made"
        info "Would install:"
        [[ "$INSTALL_CAELESTIA" == "true" ]] && echo "  - Caelestia KDE"
        [[ "$INSTALL_CONFIGS" == "true" ]] && echo "  - Custom configs"
        [[ "$INSTALL_VARIETY" == "true" ]] && echo "  - Variety config (FORCE MODE)"
        [[ "$INSTALL_KITTY" == "true" ]] && echo "  - Kitty terminal"
        [[ "$INSTALL_ICONS" == "true" ]] && echo "  - Icons + SET THEME"
        [[ "$INSTALL_WALLPAPERS" == "true" ]] && echo "  - Wallpapers"
        [[ "$INSTALL_CLOCK" == "true" ]] && echo "  - Clock widget ($CLOCK_CHOICE)"
        [[ "$INSTALL_APPS" == "true" ]] && echo "  - Applications"
        [[ "$INSTALL_NIRI" == "true" ]] && echo "  - Niri Animation Switcher"
        [[ "$INSTALL_SPICETIFY" == "true" ]] && echo "  - Spotify + Spicetify"
        [[ "$INSTALL_FSTAB" == "true" ]] && echo "  - Fstab configuration"
        info "Backups would be created in: $CURRENT_BACKUP_DIR"
        exit 0
    fi
    
    [[ "$INSTALL_CAELESTIA" == "true" ]] && install_caelestia
    [[ "$INSTALL_CONFIGS" == "true" ]] && install_configs
    [[ "$INSTALL_VARIETY" == "true" ]] && install_variety_config
    [[ "$INSTALL_KITTY" == "true" ]] && install_kitty
    [[ "$INSTALL_ICONS" == "true" ]] && install_icons
    [[ "$INSTALL_WALLPAPERS" == "true" ]] && install_wallpapers
    [[ "$INSTALL_CLOCK" == "true" ]] && install_clock
    [[ "$INSTALL_APPS" == "true" ]] && install_apps
    [[ "$INSTALL_NIRI" == "true" ]] && install_niri
    [[ "$INSTALL_SPICETIFY" == "true" ]] && install_spicetify
    [[ "$INSTALL_FSTAB" == "true" ]] && install_fstab
    
    mkdir -p "$HOME/.local/bin"
    if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
        local bashrc="$HOME/.bashrc"
        local zshrc="$HOME/.zshrc"
        [[ -f "$bashrc" ]] && backup_file_or_dir "$bashrc" ".bashrc" 2>/dev/null || true
        [[ -f "$zshrc" ]] && backup_file_or_dir "$zshrc" ".zshrc" 2>/dev/null || true
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$bashrc"
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$zshrc" 2>/dev/null || true
        info "Added ~/.local/bin to PATH in .bashrc and .zshrc"
    fi
    
    local summary="✦ Installation Complete! ✦\n\n"
    summary+="Components installed:\n"
    summary+="  Caelestia:      $INSTALL_CAELESTIA\n"
    summary+="  Configs:        $INSTALL_CONFIGS\n"
    summary+="  Variety:        $INSTALL_VARIETY (FORCED)\n"
    summary+="  Kitty:          $INSTALL_KITTY\n"
    summary+="  Icons:          $INSTALL_ICONS\n"
    summary+="  Wallpapers:     $INSTALL_WALLPAPERS\n"
    summary+="  Clock:          $INSTALL_CLOCK (${CLOCK_CHOICE:-none})\n"
    summary+="  Apps:           $INSTALL_APPS\n"
    summary+="  Niri:           $INSTALL_NIRI\n"
    summary+="  Spotify:        $INSTALL_SPICETIFY\n"
    summary+="  Fstab:          $INSTALL_FSTAB\n\n"
    summary+="Backups created: $BACKUP_COUNT files/directories\n"
    summary+="Backup location: $CURRENT_BACKUP_DIR\n\n"
    summary+="To restore: ./$0 --restore\n"
    summary+="To list backups: ./$0 --list-backups\n\n"
    summary+="May your desktop always reflect the stars! ✧"
    
    whiptail --title "Installation Complete" --msgbox "$summary" 24 75
    
    info "Backup saved to: $CURRENT_BACKUP_DIR"
    info "Use './$0 --restore' to revert to this state"
    
    success "Installation completed"
}

# ─── Run ────────────────────────────────────────────────────────────

main "$@"
