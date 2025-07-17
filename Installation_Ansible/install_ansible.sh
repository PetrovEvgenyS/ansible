#!/bin/bash

# Определение дистрибутива:
OS=$(awk -F= '/^ID=/{gsub(/"/, "", $2); print $2}' /etc/os-release)


# -----------------------------------------------------------------------------------------


# Проверка запуска через sudo
if [ -z "$SUDO_USER" ]; then
    errorprint "Пожалуйста, запустите скрипт через sudo."
    exit 1
fi

# Установить и настроить Ansible для Ubuntu
install_ansible_ubuntu() {
    # Установить Ansible
    sudo apt install -y ansible
}

# Установить и настроить Ansible для AlmaLinux
install_ansible_almalinux() {
    # Установить репозиторий EPEL
    sudo dnf install -y epel-release
    # Установить Ansible
    sudo dnf install -y ansible
}

# Создать конфигурационный файл Ansible
create_ansible_config() { 
    sudo mkdir -p /etc/ansible
    sudo tee /etc/ansible/ansible.cfg > /dev/null <<EOL
[defaults]
# Чтобы не задавал вопросы по поводу отпечатков ssh
host_key_checking  = false
# Указываем путь до файла инвентори
inventory          = /srv/ansible/inventory.ini
# Чтобы не выводил информацию о python
interpreter_python = /usr/bin/python3
EOL
}

# Обновить файл /etc/hosts
update_hosts_file() {
    tee -a /etc/hosts > /dev/null <<EOL
10.100.10.1 node-vm01
10.100.10.2 node-vm02
10.100.10.3 node-vm03
10.100.10.4 node-vm04
10.100.10.5 node-vm05
EOL
}

# Создать директорию ansible и файл Inventory
create_inventory() {
    mkdir -p /srv/ansible
    sudo tee /srv/ansible/inventory.ini > /dev/null <<EOL
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
    mkdir -p /srv/ansible/group_vars
    sudo tee /srv/ansible/group_vars/myservers > /dev/null <<EOL
# Переменные для группы myservers
# [myservers:vars]
# Используется УЗ root
# ansible_user : root
# Указываем путь до ssh-ключей, с помощью которых Ansible подключается к группе узлов
# ansible_ssh_privat_key_file : /root/.ssh/authorized_keys

---
ansible_user                : root
ansible_ssh_privat_key_file : /root/.ssh/authorized_keys
EOL
}

# Проверить операционную систему и установить Ansible
if [ "$OS" == "ubuntu" ]; then
    install_ansible_ubuntu
elif [ "$OS" == "almalinux" ]; then
    install_ansible_almalinux
else
    echo "Скрипт не поддерживает установленную операционную систему: $OS"
    # Выход из скрипта с кодом 1
    exit 1
fi

# Настроить Ansible
create_ansible_config
update_hosts_file
create_inventory
create_group_vars

# Проверить установку Ansible
ansible --version

# Вывести сообщение об успешной установке и настройке
echo "Ansible успешно установлен и настроен на $OS."
