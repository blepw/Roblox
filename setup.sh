#!/usr/bin/env bash

set -e

# colors and warnings
BLUE="\e[34m"
GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"
TICK="✓"
WARN="!"
INFO="+"


status_ok() {
    echo -e "${BLUE}[${RESET}${GREEN}${TICK}${RESET}${BLUE}]${RESET} $1"
}

status_warn() {
    echo -e "${BLUE}[${RESET}${RED}${WARN}${RESET}${BLUE}]${RESET} ${RED}$1${RESET}"
}

status_info() {
    echo -e "${BLUE}[${RESET}${INFO}${BLUE}]${RESET} $1"
}


command_exists() {
    command -v "$1" >/dev/null 2>&1
}


banner() {
       echo "${white}
⠀⠀⠀⠀⢀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⡀⢀⡀⠀⠀⠀
⣤⣶⣶⡿⠿⠿⠿⠿⠿⣶⣶⣶⠄⠀⠀⠐⢶⣶⣶⣿⡿⠿⠿⠿⠿⢿⣷⠦⠀
⠙⠏⠁⠀⣤⣶⣶⣶⣶⣒⢳⣆⠀⠀⠀⠀⢠⡞⣒⣲⣶⣖⣶⣦⡀⠀⠉⠛⠁
⠀⠀⠴⢯⣁⣿⣿⣿⣏⣿⡀⠟⠀⠀⠀⠀⠸⠀⣼⣋⣿⣿⣿⣦⣭⠷⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⠟⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡄⠀⢰⠏⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣠⡴⠟⠁⢀⡟⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠸⡗⠶⠶⠶⠶⠶⠖⠚⠛⠛⠋⠉⠀⠀⠀⠀⢸⠁⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠛⠀⠀⠀⠀⠀

${reset}"
}


sudo_check() {
    if [ "${EUID}" -ne 0 ]; then
        echo "${white}[${red}!${white}] ${red}Run this as root"
        exit
    else
        echo "${blue}[${green}*${blue}] Root."
        return 0
    fi
}



internet_connection() {
    ping -c 1 8.8.8.8 > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "${blue}[${green}+${blue}] Connected to the internet ${reset}"
    else
        echo "${white}[${red}!${white}] No internet connection ${reset}"
        exit 1
    fi
}


install_all() {
    status_info "Starting full installation..."

    if ! command_exists flatpak; then
        status_info "Installing Flatpak..."
        sudo apt update
        sudo apt install -y flatpak gnome-software-plugin-flatpak
    else
        status_ok "Flatpak already installed"
    fi

    if ! flatpak remotes | grep -q flathub; then
        status_info "Adding Flathub repository..."
        sudo flatpak remote-add --if-not-exists flathub \
            https://dl.flathub.org/repo/flathub.flatpakrepo
    else
        status_ok "Flathub already exists"
    fi

    if ! dpkg --print-foreign-architectures | grep -q i386; then
        status_info "Enabling i386 architecture..."
        sudo dpkg --add-architecture i386
        sudo apt update
    else
        status_ok "i386 architecture already enabled"
    fi

    if ! dpkg -l | grep -q wine32:i386; then
        status_info "Installing Wine 32-bit..."
        sudo apt install -y wine32:i386
    else
        status_ok "Wine 32-bit already installed"
    fi

    if ! flatpak list | grep -q org.vinegarhq.Vinegar; then
        status_info "Installing Roblox Studio (Vinegar)..."
        flatpak install -y flathub org.vinegarhq.Vinegar
    else
        status_ok "Vinegar already installed"
    fi

    status_ok "Installation complete"
}


run_studio() {
    if flatpak list | grep -q org.vinegarhq.Vinegar; then
        status_info "Launching Roblox Studio..."
        flatpak run org.vinegarhq.Vinegar studio
    else
        status_warn "Roblox Studio is not installed"
    fi
}


run_player() {
    if flatpak list | grep -q org.vinegarhq.Vinegar; then
        status_info "Launching Roblox Player..."
        flatpak run org.vinegarhq.Vinegar player
    else
        status_warn "Roblox Player is not installed"
    fi
}


create_shortcuts() {
    status_info "Creating desktop shortcuts..."

    mkdir -p "$HOME/.local/share/applications"

    cat > "$HOME/.local/share/applications/roblox-studio.desktop" <<EOF
[Desktop Entry]
Name=Roblox Studio
Exec=flatpak run org.vinegarhq.Vinegar studio
Type=Application
Icon=org.vinegarhq.Vinegar
Categories=Game;Development;
EOF

    cat > "$HOME/.local/share/applications/roblox-player.desktop" <<EOF
[Desktop Entry]
Name=Roblox Player
Exec=flatpak run org.vinegarhq.Vinegar player
Type=Application
Icon=org.vinegarhq.Vinegar
Categories=Game;
EOF

    chmod +x "$HOME/.local/share/applications/"*.desktop
    status_ok "Shortcuts created"
}


uninstall_all() {
    status_warn "Uninstalling Roblox Player and Studio..."

    if flatpak list | grep -q org.vinegarhq.Vinegar; then
        flatpak uninstall -y org.vinegarhq.Vinegar
        status_ok "Vinegar removed"
    else
        status_warn "Vinegar not installed"
    fi

    rm -f \
        "$HOME/.local/share/applications/roblox-studio.desktop" \
        "$HOME/.local/share/applications/roblox-player.desktop"

    status_ok "Shortcuts removed"
}


show_menu() {
    while true; do
        echo
        echo "1) Install everything"
        echo "2) Run Roblox Studio"
        echo "3) Run Roblox Player"
        echo "4) Create desktop shortcuts"
        echo "5) Uninstall player and studio"
        echo "6) Exit"
        echo

        read -rp "[!] Select an option [1-6] > " choice

        case "$choice" in
            1) install_all ;;
            2) run_studio ;;
            3) run_player ;;
            4) create_shortcuts ;;
            5) uninstall_all ;;
            6)
              status_ok "Exiting"
              exit 0
              ;;
            *)
              status_warn "Invalid option"
              ;;
        esac
    done
}

# run 
sudo_check
internet_connection
banner 
show_menu
