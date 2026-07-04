#!/bin/bash

# ✦ C A E L E S T I A   K D E   +   C U S T O M   C O N F I G S ✦
# Consolidated installer for https://github.com/avraniel/config_kdecaelestia
# This script installs:
#   - Caelestia KDE theme (from ladybug-me/caelestia-dots-kde)
#   - Custom configs (fastfetch, fish from this repo)
#   - Wallpaper-cache (from avraniel/wallpaper-cache)
#   - Optional apps (Viber, Signal, Zoom, Thunar + plugins)
#   - Optional fstab configuration for storage drives

set -e

# ─── Colors ──────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ─── Script Location ────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Banner ──────────────────────────────────────────────────────────

echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     ✦ C A E L E S T I A   K D E   I N S T A L L E R ✦     ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo -e "${BLUE}Config source: ${SCRIPT_DIR}${NC}"
echo ""

# ─── Error Handler ──────────────────────────────────────────────────

handle_error() {
    echo -e "${RED}✗ Error occurred at line $1${NC}"
    echo -e "${YELLOW}You can retry, ignore, or exit.${NC}"
    read -p "Retry (r), Ignore (i), or Exit (e)? " choice
    case $choice in
        r|R) return 0 ;;
        i|I) return 1 ;;
        *) echo -e "${RED}Exiting.${NC}"; exit 1 ;;
    esac
}

trap 'handle_error $LINENO || true' ERR

# ─── Pre-flight Checks ──────────────────────────────────────────────

echo -e "${YELLOW}► Pre-flight checks...${NC}"

if ! command -v plasmashell &> /dev/null; then
    echo -e "${RED}⚠ Warning: KDE Plasma not detected. Requires KDE Plasma 6.0+.${NC}"
    echo ""
fi

if ! command -v git &> /dev/null; then
    echo -e "${RED}✗ git is not installed. Please install git first.${NC}"
    exit 1
fi

# Detect package manager
if command -v pacman &> /dev/null; then
    PKG_MANAGER="pacman"
    INSTALL_CMD="sudo pacman -S --needed --noconfirm"
    AUR_HELPER=""
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
    PKG_MANAGER="unknown"
    INSTALL_CMD=""
    echo -e "${YELLOW}⚠ Could not detect package manager. Skipping app installation.${NC}"
fi

echo -e "${GREEN}✓ Detected: ${PKG_MANAGER}${NC}"
echo ""

# ─── Step 1: Install Caelestia KDE ─────────────────────────────────

echo -e "${GREEN}► Step 1: Installing Caelestia KDE dotfiles${NC}"
echo ""

CAELESTIA_DIR="$HOME/caelestia-dots-kde"

if [ -d "$CAELESTIA_DIR" ]; then
    echo -e "${YELLOW}Directory ~/caelestia-dots-kde already exists.${NC}"
    read -p "Remove and re-clone for fresh install? (y/n) " reinstall
    if [[ $reinstall == "y" || $reinstall == "Y" ]]; then
        rm -rf "$CAELESTIA_DIR"
    else
        echo -e "${YELLOW}Using existing directory.${NC}"
    fi
fi

if [ ! -d "$CAELESTIA_DIR" ]; then
    echo "Cloning caelestia-dots-kde..."
    git clone https://github.com/ladybug-me/caelestia-dots-kde "$CAELESTIA_DIR"
fi

cd "$CAELESTIA_DIR"
echo -e "${YELLOW}Running Caelestia setup script...${NC}"
echo -e "${BLUE}Note: You may be prompted for your password multiple times.${NC}"
echo ""
chmod +x setup.sh
bash ./setup.sh
cd "$SCRIPT_DIR"

# ─── Step 2: Apply Custom Configs ──────────────────────────────────

echo -e "${GREEN}► Step 2: Applying custom configuration files${NC}"
echo ""

if [ -d "$SCRIPT_DIR/fastfetch" ]; then
    echo "Copying fastfetch config..."
    mkdir -p "$HOME/.config/fastfetch"
    cp -r "$SCRIPT_DIR/fastfetch/"* "$HOME/.config/fastfetch/" 2>/dev/null || true
    echo -e "${GREEN}  ✓ fastfetch config applied${NC}"
else
    echo -e "${YELLOW}  ⚠ fastfetch directory not found, skipping${NC}"
fi

if [ -d "$SCRIPT_DIR/fish" ]; then
    echo "Copying fish config..."
    mkdir -p "$HOME/.config/fish"
    cp -r "$SCRIPT_DIR/fish/"* "$HOME/.config/fish/" 2>/dev/null || true
    echo -e "${GREEN}  ✓ fish config applied${NC}"
else
    echo -e "${YELLOW}  ⚠ fish directory not found, skipping${NC}"
fi

# ─── Step 3: Install Wallpaper Cache ───────────────────────────────

echo -e "${GREEN}► Step 3: Installing wallpaper-cache${NC}"
echo ""

WALLPAPER_DIR="$HOME/wallpaper-cache"

if [ -d "$WALLPAPER_DIR" ]; then
    echo -e "${YELLOW}Directory ~/wallpaper-cache already exists.${NC}"
    read -p "Remove and re-clone for fresh install? (y/n) " reinstall_wallpaper
    if [[ $reinstall_wallpaper == "y" || $reinstall_wallpaper == "Y" ]]; then
        rm -rf "$WALLPAPER_DIR"
    else
        echo -e "${YELLOW}Using existing directory.${NC}"
    fi
fi

if [ ! -d "$WALLPAPER_DIR" ]; then
    echo "Cloning wallpaper-cache..."
    git clone https://github.com/avraniel/wallpaper-cache.git "$WALLPAPER_DIR"
fi

if [ -f "$WALLPAPER_DIR/install_wca" ]; then
    echo "Running install_wca script..."
    chmod +x "$WALLPAPER_DIR/install_wca"
    cd "$WALLPAPER_DIR"
    bash ./install_wca
    cd "$SCRIPT_DIR"
    echo -e "${GREEN}  ✓ wallpaper-cache installed${NC}"
else
    echo -e "${YELLOW}  ⚠ install_wca script not found in wallpaper-cache${NC}"
    echo -e "${YELLOW}  Repository cloned to ~/wallpaper-cache but no installer was executed.${NC}"
fi

# ─── Step 4: Optional Applications ──────────────────────────────────

echo -e "${GREEN}► Step 4: Optional applications${NC}"
echo ""

echo -e "${CYAN}The following applications are available to install:${NC}"
echo "  • Viber (messaging)"
echo "  • Signal (secure messaging)"
echo "  • Zoom (video conferencing)"
echo "  • Thunar + plugins (file manager with volume/shares support)"
echo ""
read -p "Install these applications? (y/n) " install_apps

if [[ $install_apps == "y" || $install_apps == "Y" ]]; then
    echo -e "${YELLOW}Installing additional applications...${NC}"
    echo ""

    case $PKG_MANAGER in
        pacman)
            echo "Installing from official repositories..."
            $INSTALL_CMD thunar thunar-volman thunar-shares-plugin
            
            if [ -n "$AUR_HELPER" ]; then
                echo "Installing from AUR using $AUR_HELPER..."
                $AUR_CMD viber signal-desktop zoom
            else
                echo -e "${YELLOW}⚠ No AUR helper found (yay or paru). Skipping AUR packages.${NC}"
                echo "You can manually install these from AUR:"
                echo "  - viber"
                echo "  - signal-desktop"
                echo "  - zoom"
                
                read -p "Install yay (AUR helper) now? (y/n) " install_yay
                if [[ $install_yay == "y" || $install_yay == "Y" ]]; then
                    echo "Installing yay..."
                    sudo pacman -S --needed --noconfirm git base-devel
                    git clone https://aur.archlinux.org/yay.git /tmp/yay
                    cd /tmp/yay
                    makepkg -si --noconfirm
                    cd "$SCRIPT_DIR"
                    yay -S --needed --noconfirm viber signal-desktop zoom
                fi
            fi
            ;;

        dnf)
            echo "Installing for Fedora..."
            
            if ! dnf repolist | grep -q "rpmfusion"; then
                echo "Enabling RPM Fusion repositories..."
                sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
                sudo dnf install -y https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
            fi
            
            $INSTALL_CMD thunar thunar-volman
            echo -e "${YELLOW}Note: thunar-shares-plugin may not be available in official Fedora repos.${NC}"
            
            if command -v flatpak &> /dev/null; then
                echo "Installing Flatpak versions..."
                flatpak install -y flathub com.viber.Viber
                flatpak install -y flathub org.signal.Signal
                flatpak install -y flathub us.zoom.Zoom
            else
                echo -e "${YELLOW}Flatpak not found. Skipping Flatpak installations.${NC}"
            fi
            ;;

        apt)
            echo "Installing for Debian/Ubuntu..."
            
            $INSTALL_CMD thunar thunar-volman thunar-shares-plugin
            
            echo "Adding Signal repository..."
            wget -qO- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > signal-desktop-keyring.gpg
            sudo mv signal-desktop-keyring.gpg /usr/share/keyrings/
            echo "deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main" | sudo tee /etc/apt/sources.list.d/signal-xenial.list
            sudo apt update
            $INSTALL_CMD signal-desktop
            
            echo "Downloading Viber..."
            wget -O /tmp/viber.deb https://download.cdn.viber.com/desktop/Linux/viber.deb
            sudo dpkg -i /tmp/viber.deb || sudo apt install -f -y
            rm -f /tmp/viber.deb
            
            echo "Downloading Zoom..."
            wget -O /tmp/zoom.deb https://zoom.us/client/latest/zoom_amd64.deb
            sudo dpkg -i /tmp/zoom.deb || sudo apt install -f -y
            rm -f /tmp/zoom.deb
            ;;

        *)
            echo -e "${RED}Unsupported package manager: ${PKG_MANAGER}${NC}"
            echo -e "${YELLOW}Please install these applications manually:${NC}"
            echo "  • Viber: https://www.viber.com/download/"
            echo "  • Signal: https://signal.org/download/"
            echo "  • Zoom: https://zoom.us/download"
            echo "  • Thunar: your distribution's package manager"
            ;;
    esac

    echo -e "${GREEN}✓ Application installation completed${NC}"
else
    echo -e "${YELLOW}⏭ Skipping additional application installation.${NC}"
fi

echo ""

# ─── Step 5: Fstab Configuration ────────────────────────────────────

echo -e "${GREEN}► Step 5: Optional fstab configuration${NC}"
echo ""

echo -e "${CYAN}This step can add entries for your storage drives to /etc/fstab.${NC}"
echo -e "${CYAN}The following entries will be added (with nofail and noatime):${NC}"
echo ""
echo -e "${YELLOW}UUID=dda9fe61-a2b0-4d5c-9076-8fa3cff067b4  /home/niel/DATA          ext4  defaults,noatime,nofail  0  2${NC}"
echo -e "${YELLOW}UUID=e3af8571-cddf-4edc-86f2-5efa6d7fec2e  /run/media/niel/storage  ext4  defaults,noatime,nofail  0  2${NC}"
echo -e "${YELLOW}UUID=b053948d-acab-49d1-bf0e-79986ab1c3f5  /home/niel/Downloads     ext4  defaults,noatime,nofail  0  2${NC}"
echo ""
read -p "Proceed with fstab configuration? (y/n) " run_fstab

if [[ $run_fstab == "y" || $run_fstab == "Y" ]]; then
    echo -e "${YELLOW}Preparing to update /etc/fstab...${NC}"
    
    # Backup current fstab
    sudo cp /etc/fstab /etc/fstab.backup
    echo -e "${GREEN}  ✓ Backup created: /etc/fstab.backup${NC}"
    
    # Define the new lines
    NEW_LINES=(
        "UUID=dda9fe61-a2b0-4d5c-9076-8fa3cff067b4  /home/niel/DATA          ext4  defaults,noatime,nofail  0  2"
        "UUID=e3af8571-cddf-4edc-86f2-5efa6d7fec2e  /run/media/niel/storage  ext4  defaults,noatime,nofail  0  2"
        "UUID=b053948d-acab-49d1-bf0e-79986ab1c3f5  /home/niel/Downloads     ext4  defaults,noatime,nofail  0  2"
    )
    
    # Create a temporary file
    TEMP_FSTAB=$(mktemp)
    
    # Start with the existing fstab, but remove any lines that contain these UUIDs
    # (to avoid duplicates and replace old entries)
    sudo grep -v -E "dda9fe61-a2b0-4d5c-9076-8fa3cff067b4|e3af8571-cddf-4edc-86f2-5efa6d7fec2e|b053948d-acab-49d1-bf0e-79986ab1c3f5" /etc/fstab > "$TEMP_FSTAB"
    
    # Append the new lines
    echo "" >> "$TEMP_FSTAB"
    echo "# storage drives (added by installer)" >> "$TEMP_FSTAB"
    for line in "${NEW_LINES[@]}"; do
        echo "$line" >> "$TEMP_FSTAB"
    done
    
    # Replace the original fstab with the new one
    sudo mv "$TEMP_FSTAB" /etc/fstab
    
    echo -e "${GREEN}  ✓ /etc/fstab updated with new entries.${NC}"
    
    # Test the new fstab
    echo -e "${YELLOW}Testing new fstab with 'sudo mount -a'...${NC}"
    if sudo mount -a 2>&1; then
        echo -e "${GREEN}  ✓ mount -a succeeded. The fstab is valid.${NC}"
    else
        echo -e "${RED}  ✗ mount -a failed. Please check your fstab entries.${NC}"
        echo -e "${YELLOW}  You can restore the backup with: sudo cp /etc/fstab.backup /etc/fstab${NC}"
        read -p "Press Enter to continue anyway, or Ctrl+C to abort."
    fi
    
    # Ensure mount points exist
    echo -e "${YELLOW}Ensuring mount points exist...${NC}"
    sudo mkdir -p /home/niel/DATA /run/media/niel/storage /home/niel/Downloads
    echo -e "${GREEN}  ✓ Mount points created/verified.${NC}"
    
    # Suggest ownership
    echo -e "${BLUE}If you want your user to own these directories, run:${NC}"
    echo -e "${BLUE}  sudo chown -R niel:niel /home/niel/DATA /run/media/niel/storage /home/niel/Downloads${NC}"
    echo ""
    echo -e "${GREEN}✓ Fstab configuration completed.${NC}"
else
    echo -e "${YELLOW}⏭ Skipping fstab configuration.${NC}"
fi

# ─── Step 6: Finalize Setup ────────────────────────────────────────

echo -e "${GREEN}► Step 6: Finalizing setup${NC}"
echo ""

mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.config/autostart"

if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc" 2>/dev/null || true
    echo -e "${GREEN}  ✓ Added ~/.local/bin to PATH${NC}"
fi

if command -v systemctl &> /dev/null; then
    if systemctl --user is-active --quiet keyd 2>/dev/null; then
        echo -e "${GREEN}  ✓ keyd service is running${NC}"
    else
        echo -e "${YELLOW}  ⚠ keyd service not running. If shortcuts don't work, try:${NC}"
        echo -e "    systemctl --user restart keyd"
    fi
fi

# ─── Step 7: Post-installation Guide ───────────────────────────────

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              ✦ I N S T A L L A T I O N   D O N E ✦        ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}┌─ Post-installation steps ──────────────────────────────────┐${NC}"
echo -e "${BLUE}│${NC}"
echo -e "${BLUE}│  1. ${YELLOW}Log out and log back in${NC} to see all changes take effect."
echo -e "${BLUE}│  2. If widgets don't appear, run: ${YELLOW}caelestia shell -d${NC}"
echo -e "${BLUE}│  3. For wallpapers: ${YELLOW}Super+Space → type '>' → Caelestia Tweaks${NC}"
echo -e "${BLUE}│  4. Color scheme: ${YELLOW}System Settings → Colors → Material You Dark/Light${NC}"
echo -e "${BLUE}│"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""
echo -e "${BLUE}┌─ Key Bindings ─────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  ${YELLOW}Super + /     ${NC}│ Show keybind cheatsheet"
echo -e "${BLUE}│  ${YELLOW}Super + Enter ${NC}│ Open terminal (Foot)"
echo -e "${BLUE}│  ${YELLOW}Super + Space ${NC}│ Application launcher (Fuzzel)"
echo -e "${BLUE}│  ${YELLOW}Super + B     ${NC}│ Toggle notification panel"
echo -e "${BLUE}│  ${YELLOW}Super + V     ${NC}│ Open Clipboard History"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""
echo -e "${BLUE}┌─ Installed Components ─────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  ${GREEN}✓ Caelestia KDE theme${NC}"
echo -e "${BLUE}│  ${GREEN}✓ Fastfetch config${NC}"
echo -e "${BLUE}│  ${GREEN}✓ Fish config${NC}"
echo -e "${BLUE}│  ${GREEN}✓ Wallpaper-cache${NC}"
if [[ $install_apps == "y" || $install_apps == "Y" ]]; then
    echo -e "${BLUE}│  ${GREEN}✓ Viber, Signal, Zoom, Thunar + plugins${NC}"
else
    echo -e "${BLUE}│  ${YELLOW}No additional applications installed${NC}"
fi
if [[ $run_fstab == "y" || $run_fstab == "Y" ]]; then
    echo -e "${BLUE}│  ${GREEN}✓ Fstab updated for storage drives${NC}"
else
    echo -e "${BLUE}│  ${YELLOW}No fstab changes${NC}"
fi
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""
echo -e "${BLUE}┌─ Uninstall ────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  cd ~/caelestia-dots-kde && bash ./uninstall.sh${NC}"
echo -e "${BLUE}│  rm -rf ~/wallpaper-cache${NC}"
echo -e "${BLUE}│  To restore fstab: sudo cp /etc/fstab.backup /etc/fstab${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""
echo -e "${GREEN}✧ May your desktop always reflect the stars! ✧${NC}"
