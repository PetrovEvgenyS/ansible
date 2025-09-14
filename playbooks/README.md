# Ansible Playbooks

В этом каталоге находятся Ansible playbook'и для автоматизации задач на серверах.

## Оглавление
- [install_apache.yml](#installapacheyml)
- [ping.yml](#pingyml)

## install_apache.yml

Устанавливает и настраивает веб-сервер Apache на целевых хостах. Автоматически определяет ОС (RedHat или Debian) и использует соответствующие пакеты и сервисы. Включает обновление apt-кэша для Debian.

[Посмотреть playbook](./install_apache.yml)

## ping.yml

Проверяет доступность серверов с помощью модуля `ping`. Используется для тестирования соединения с целевыми хостами.

[Посмотреть playbook](./ping.yml)

