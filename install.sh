#!/bin/bash

# ✦ C A E L E S T I A   K D E   +   C U S T O M   C O N F I G S ✦
# Consolidated installer for https://github.com/avraniel/config_kdecaelestia
# This script installs the main Caelestia KDE theme and applies your custom configs.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     ✦ C A E L E S T I A   K D E   I N S T A L L E R ✦     ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo -e "${BLUE}Config source: ${SCRIPT_DIR}${NC}"
echo ""

# ─── Helper Functions ──────────────────────────────────────────────

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

# ─── Pre-flight Checks ─────────────────────────────────────────────

echo -e "${YELLOW}► Pre-flight checks...${NC}"

# Check for KDE Plasma
if ! command -v plasmashell &> /dev/null; then
    echo -e "${RED}⚠ Warning: KDE Plasma not detected. This setup requires KDE Plasma 6.0+.${NC}"
    echo -e "${YELLOW}Continuing anyway, but the theme may not work correctly.${NC}"
    echo ""
fi

# Check for git
if ! command -v git &> /dev/null; then
    echo -e "${RED}✗ git is not installed. Please install git first.${NC}"
    exit 1
fi

# ─── Step 1: Install Caelestia KDE ────────────────────────────────

echo -e "${GREEN}► Step 1: Installing Caelestia KDE dotfiles${NC}"
echo ""

CAELESTIA_DIR="$HOME/caelestia-dots-kde"

if [ -d "$CAELESTIA_DIR" ]; then
    echo -e "${YELLOW}Directory ~/caelestia-dots-kde already exists.${NC}"
    read -p "Remove and re-clone for fresh install? (y/n) " reinstall
    if [[ $reinstall == "y" || $reinstall == "Y" ]]; then
        echo "Removing existing directory..."
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

# Return to script directory
cd "$SCRIPT_DIR"

# ─── Step 2: Apply Custom Configs ──────────────────────────────────

echo -e "${GREEN}► Step 2: Applying custom configuration files${NC}"
echo ""

# Fastfetch config
if [ -d "$SCRIPT_DIR/fastfetch" ]; then
    echo "Copying fastfetch config..."
    mkdir -p "$HOME/.config/fastfetch"
    cp -r "$SCRIPT_DIR/fastfetch/"* "$HOME/.config/fastfetch/" 2>/dev/null || true
    echo -e "${GREEN}  ✓ fastfetch config applied${NC}"
else
    echo -e "${YELLOW}  ⚠ fastfetch directory not found, skipping${NC}"
fi

# Fish config
if [ -d "$SCRIPT_DIR/fish" ]; then
    echo "Copying fish config..."
    mkdir -p "$HOME/.config/fish"
    cp -r "$SCRIPT_DIR/fish/"* "$HOME/.config/fish/" 2>/dev/null || true
    echo -e "${GREEN}  ✓ fish config applied${NC}"
else
    echo -e "${YELLOW}  ⚠ fish directory not found, skipping${NC}"
fi

# ─── Step 3: Additional Setup ──────────────────────────────────────

echo -e "${GREEN}► Step 3: Finalizing setup${NC}"
echo ""

# Create necessary directories
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.config/autostart"

# Ensure ~/.local/bin is in PATH
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc" 2>/dev/null || true
    echo -e "${YELLOW}  ✓ Added ~/.local/bin to PATH in .bashrc and .zshrc${NC}"
fi

# Check for keyd service (common issue with shortcuts)
if command -v systemctl &> /dev/null; then
    if systemctl --user is-active --quiet keyd 2>/dev/null; then
        echo -e "${GREEN}  ✓ keyd service is running${NC}"
    else
        echo -e "${YELLOW}  ⚠ keyd service not running. If shortcuts don't work, try:${NC}"
        echo -e "    systemctl --user restart keyd"
    fi
fi

# ─── Step 4: Post-installation Guide ──────────────────────────────

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
echo -e "${BLUE}┌─ Uninstall ────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  cd ~/caelestia-dots-kde && bash ./uninstall.sh${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""
echo -e "${GREEN}✧ May your desktop always reflect the stars! ✧${NC}"