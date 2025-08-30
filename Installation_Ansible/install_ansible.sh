#!/bin/bash

### ЦВЕТА ###
ESC=$(printf '\033') RESET="${ESC}[0m" MAGENTA="${ESC}[35m" RED="${ESC}[31m" GREEN="${ESC}[32m"

### Функции цветного вывода ###
magentaprint() { echo; printf "${MAGENTA}%s${RESET}\n" "$1"; }
errorprint() { echo; printf "${RED}%s${RESET}\n" "$1"; }
greenprint() { echo; printf "${GREEN}%s${RESET}\n" "$1"; }

# Определение дистрибутива:
OS=$(awk -F= '/^ID=/{gsub(/"/, "", $2); print $2}' /etc/os-release)

BASE="/etc/ansible"           # базовый каталог для Ansible
INFRA="$BASE/infrastructure"  # каталог инфраструктуры Ansible


# -----------------------------------------------------------------------------------------


# Проверка запуска через sudo
if [ -z "$SUDO_USER" ]; then
    errorprint "Пожалуйста, запустите скрипт через sudo."
    exit 1
fi


# Установить Ansible для Ubuntu
install_ansible_ubuntu() {
    magentaprint "Установка Ansible на $OS"
    apt update
    apt install -y software-properties-common
    add-apt-repository --yes --update ppa:ansible/ansible
    apt install -y python3 ansible
}


# Установить Ansible для AlmaLinux
install_ansible_almalinux() {
    magentaprint "Установка epel-release"
    dnf install -y epel-release
    magentaprint "Установка Ansible на $OS"
    dnf install -y python3 ansible
}


# Проверить ОС и установить Ansible
check_os() {
    # Проверить операционную систему и установить Ansible
    if [ "$OS" == "ubuntu" ]; then
        install_ansible_ubuntu
    elif [ "$OS" == "almalinux" ]; then
        install_ansible_almalinux
    else
        errorprint "Скрипт не поддерживает установленную операционную систему: $OS"
        exit 1
    fi
}


# Создать конфигурационный файл Ansible
create_ansible_config() { 
    # Создание каталогов
    rm -rf /etc/ansible/*
    mkdir -p "$INFRA"/{playbooks,roles,inventories/{group_vars,dev/group_vars,prod/group_vars}}
    
    magentaprint "Создание конфигурационного файла /etc/ansible/ansible.cfg"
    tee "$BASE/ansible.cfg" >/dev/null <<'CFG'
[defaults]
inventory = /etc/ansible/infrastructure/inventories/inventory.ini
roles_path = /etc/ansible/infrastructure/roles

# Не спрашивать про SSH key
host_key_checking = False

# Явно использовать Python 3. Чтобы не выводил информацию о python
interpreter_python = /usr/bin/python3

# Не создавать retry-файлы. Отключаем создание файлов с повторными попытками
retry_files_enabled = False

# Вывод в формате YAML
stdout_callback = yaml

# Кол-во параллельных подключений по ssh.
forks = 20
CFG
}


# Создать файл Inventory
create_inventory() {
    magentaprint "Создание Inventory файла $INFRA/inventories/inventory.ini"

    tee "$INFRA/inventories/inventory.ini" > /dev/null <<EOL
[almalinux]
node-vm01
node-vm02

[ubuntu]
node-vm03
node-vm04

[manager]
node-vm05

[myservers]
node-vm[01:05]
EOL
}


# Создать файла group_vars/all.yml (глобальный)
create_group_vars() {
    magentaprint "Создание файла $INFRA/inventories/group_vars/all.yml (глобальный)"

    tee "$INFRA/inventories/group_vars/all.yml" >/dev/null <<'YML'
---
# общие переменные для всех окружений
ansible_user                 : ansible_worker
ansible_ssh_private_key_file : /ansiblectl/.ssh/id_ansible
YML
}


# Завершение и проверка установки Ansible
finish() {
    magentaprint "Версия Ansible:"
    ansible --version

    if ! command -v ansible >/dev/null 2>&1; then
        errorprint "Ansible не установлен или не найден в PATH. Проверьте установку!"
        exit 1
    fi
    greenprint "Ansible успешно установлен и настроен на $OS."
}


# Создание функций main.
main() {
    check_os
    create_ansible_config
    create_inventory
    create_group_vars
    finish
}

# Вызов функции main.
main
