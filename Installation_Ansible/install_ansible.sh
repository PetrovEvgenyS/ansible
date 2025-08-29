#!/bin/bash

### ЦВЕТА ###
ESC=$(printf '\033') RESET="${ESC}[0m" MAGENTA="${ESC}[35m" RED="${ESC}[31m" GREEN="${ESC}[32m"

### Функции цветного вывода ###
magentaprint() { echo; printf "${MAGENTA}%s${RESET}\n" "$1"; }
errorprint() { echo; printf "${RED}%s${RESET}\n" "$1"; }
greenprint() { echo; printf "${GREEN}%s${RESET}\n" "$1"; }

# Определение дистрибутива:
OS=$(awk -F= '/^ID=/{gsub(/"/, "", $2); print $2}' /etc/os-release)


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


# Создать конфигурационный файл Ansible
create_ansible_config() { 
    magentaprint "Создание конфигурационного файла /etc/ansible/ansible.cfg"
    tee /etc/ansible/ansible.cfg > /dev/null <<EOL
[defaults]
host_key_checking  = false                          # Чтобы не задавал вопросы по поводу отпечатков ssh
inventory          = /etc/ansible/inventory.ini     # Указываем путь до файла инвентори
interpreter_python = /usr/bin/python3               # Чтобы не выводил информацию о python
EOL
}


# Обновить файл /etc/hosts
update_hosts_file() {
    magentaprint "Обновление файла /etc/hosts"
    tee -a /etc/hosts > /dev/null <<EOL
10.100.10.1 node-vm01
10.100.10.2 node-vm02
10.100.10.3 node-vm03
10.100.10.4 node-vm04
10.100.10.5 node-vm05
EOL
}


# Создать файл Inventory
create_inventory() {
    magentaprint "Создание Inventory файла /etc/ansible/inventory.ini"
    tee /etc/ansible/inventory.ini > /dev/null <<EOL
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


# Создать файл переменных для группы хостов [myservers]
create_group_vars() {
    magentaprint "Создание файла переменных для группы хостов [myservers]"
    mkdir -p /etc/ansible/group_vars
    tee /etc/ansible/group_vars/myservers > /dev/null <<EOL
# Переменные для группы myservers
# [myservers:vars]
# Используется УЗ root
# ansible_user : root
# Указываем путь до ssh-ключей, с помощью которых Ansible подключается к группе узлов
# ansible_ssh_private_key_file : /root/.ssh/authorized_keys

---
ansible_user                 : root
ansible_ssh_private_key_file : /root/.ssh/authorized_keys
EOL
}


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
    update_hosts_file
    create_inventory
    create_group_vars
    finish
}

# Вызов функции main.
main
