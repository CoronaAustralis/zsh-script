#!/bin/bash

# Function to check if the current user can use sudo
can_use_sudo() {
    command -v sudo >/dev/null 2>&1 || return 1
    case "$PREFIX" in
        *com.termux*) return 1 ;;
    esac
  ! LANG= sudo -n -v 2>&1 | grep -q "may not run sudo"
}

fmt_error() {
  printf '\033[1m\033[31mError: %s\033[0m\n' "$*"  >&2
}


detect_package_manager() {
    if command -v apt > /dev/null; then
        echo "apt"
    elif command -v yum > /dev/null; then
        echo "yum"
    elif command -v dnf > /dev/null; then
        echo "dnf"
    elif command -v pacman > /dev/null; then
        echo "pacman"
    elif command -v zypper > /dev/null; then
        echo "zypper"
    else
        echo "unsupported"
    fi
}

install_packages() {
    local package_manager=$1

    case $package_manager in
        apt)
            if [ "$(id -u)" -eq 0 ]; then
                apt update && apt install -y zsh git curl wget
            elif can_use_sudo; then
                sudo apt update && sudo apt install -y zsh git curl wget
            else
                echo "You need to be root or have sudo privileges to install packages."
                exit 1
            fi
            ;;
        yum)
            if [ "$(id -u)" -eq 0 ]; then
                yum install -y zsh git curl wget
            elif can_use_sudo; then
                sudo yum install -y zsh git curl wget
            else
                echo "You need to be root or have sudo privileges to install packages."
                exit 1
            fi
            ;;
        dnf)
            if [ "$(id -u)" -eq 0 ]; then
                dnf install -y zsh git curl wget
            elif can_use_sudo; then
                sudo dnf install -y zsh git curl wget
            else
                echo "You need to be root or have sudo privileges to install packages."
                exit 1
            fi
            ;;
        pacman)
            if [ "$(id -u)" -eq 0 ]; then
                pacman -Syu --noconfirm zsh git curl wget
            elif can_use_sudo; then
                sudo pacman -Syu --noconfirm zsh git curl wget
            else
                echo "You need to be root or have sudo privileges to install packages."
                exit 1
            fi
            ;;
        zypper)
            if [ "$(id -u)" -eq 0 ]; then
                zypper install -y zsh git curl wget
            elif can_use_sudo; then
                sudo zypper install -y zsh git curl wget
            else
                echo "You need to be root or have sudo privileges to install packages."
                exit 1
            fi
            ;;
        *)
            fmt_error "Unsupported package manager. Please install zsh, git, curl, and wget manually."
            exit 1
            ;;
    esac
}

# Function to install git and so on
start_install() {
    echo "下载更新git curl等"
    local package_manager=$(detect_package_manager)
    install_packages "$package_manager"
}

start_install

temp_proxy=""
proxy_set() {
    if [[ -n "$http_proxy" ]]; then
        temp_proxy="$http_proxy"
    elif [[ -n "$https_proxy" ]]; then
        temp_proxy="$https_proxy"
    elif [[ -n "$HTTP_PROXY" ]]; then
        temp_proxy="$HTTP_PROXY"
    elif [[ -n "$HTTPS_PROXY" ]]; then
        temp_proxy="$HTTPS_PROXY"
    else
        unset temp_proxy
    fi
}

proxy_set

if [ -n "$temp_proxy" ]; then
    sh -c  "$(wget -O- https://install.ohmyz.sh/  | sed "/exec zsh -l/d" | sed "s|git fetch|git -c http.proxy=$temp_proxy fetch|" | sed "s/read -r opt/opt=y \&\& echo ' '/")"

    if [ $? -ne 0 ]; then
        fmt_error "oh-my-zsh安装失败"
        exit 1
    fi

    git -c http.proxy=$temp_proxy clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions --depth 1

    git -c http.proxy=$temp_proxy clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting --depth 1
else
    sh -c  "$(wget -O- https://install.ohmyz.sh/  | sed '/exec zsh -l/d' | sed "s/read -r opt/opt=y \&\& echo ' '/")"

    if [ $? -ne 0 ]; then
        fmt_error "oh-my-zsh安装失败"
        exit 1
    fi

    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions --depth 1

    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting --depth 1
fi


sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting extract)/' ~/.zshrc
sed -i  "s/^# zstyle ':omz:update' mode disabled/zstyle ':omz:update' mode disabled/" ~/.zshrc


if [[ -n "$http_proxy" || -n "$HTTP_PROXY" ]]; then
    temp_proxy="${http_proxy:-$HTTP_PROXY}"
    echo "#zsh-scrpit http_proxy set" >> ~/.zshrc
    echo "#export http_proxy=$temp_proxy" >> ~/.zshrc
elif [[ -n "$https_proxy" || -n "$HTTPS_PROXY" ]]; then
    temp_proxy="${https_proxy:-$HTTPS_PROXY}"
    echo "#zsh-scrpit https_proxy set" >> ~/.zshrc
    echo "#export http_proxy=$temp_proxy" >> ~/.zshrc
else
    unset temp_proxy
fi

chsh -s /bin/zsh

exec zsh -l