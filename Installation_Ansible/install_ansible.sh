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
    apt install -y ansible
}


# Установить Ansible для AlmaLinux
install_ansible_almalinux() {
    magentaprint "Установка epel-release"
    dnf install -y epel-release
    magentaprint "Установка Ansible на $OS"
    dnf install -y ansible
}


# Создать конфигурационный файл Ansible
create_ansible_config() { 
    magentaprint "Создание конфигурационного файла /etc/ansible/ansible.cfg"
    mkdir -p /etc/ansible
    tee /etc/ansible/ansible.cfg > /dev/null <<EOL
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
    magentaprint "Обновление файла /etc/hosts"
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
    magentaprint "Создание Inventory файла /srv/ansible/inventory.ini"
    mkdir -p /srv/ansible
    tee /srv/ansible/inventory.ini > /dev/null <<EOL
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
    mkdir -p /srv/ansible/group_vars
    tee /srv/ansible/group_vars/myservers > /dev/null <<EOL
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
    errorprint "Скрипт не поддерживает установленную операционную систему: $OS"
    exit 1
fi


# Настроить Ansible
create_ansible_config
update_hosts_file
create_inventory
create_group_vars

# Команда добавляет Python 3 как альтернативу для команды python, устанавливая при этом его приоритет равным 2.
# После выполнения этой команды, если ввести python в терминале, будет вызываться Python 3
update-alternatives --install /usr/bin/python python /usr/bin/python3 2

magentaprint "Версия Ansible:"
ansible --version


# Вывести сообщение об успешной установке и настройке
greenprint "Ansible успешно установлен и настроен на $OS."
