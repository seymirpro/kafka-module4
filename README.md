# Настройка Kafka кластера с Docker

Этот репозиторий содержит конфигурации и скрипты для настройки защищённого Kafka кластера с использованием Docker, включая управление сертификатами и конфигурации JAAS (Java Authentication and Authorization Service) для защищённой связи.

## Структура каталогов

- **`Screenshots/`**: Содержит скриншоты, демонстрирующие шаги по настройке окружения, выполнение команд и результаты каждого действия.
- **`certificate-authority/`**: Содержит сертификат и ключ центра сертификации (`ca-cert`, `ca-key`).
- **`client.properties`**: Конфигурационный файл для Kafka клиента (в данный момент при открытии возникает ошибка).
- **`command.properties`**: Файл свойств для конфигурации команд.
- **`create-users.sh`**: Скрипт для создания пользователей в системе.
- **`docker-compose.yml`**: Docker Compose файл для настройки сервисов Kafka и Zookeeper.
- **`generate.sh`**: Скрипт для генерации необходимых сертификатов и ключей для защищённой связи Kafka.
- **`jaas_configs/`**: Содержит конфигурационные файлы JAAS, включая `zookeeper_jaas.conf`.
- **`kafka-hosts.txt`**: Файл, содержащий информацию о хостах для Kafka кластера.
- **`kafka_jaas.conf`**: Конфигурационный файл JAAS для Kafka.
- **`keystore/`**: Содержит файлы хранилища ключей (`kafka-0.server.keystore.jks`, `kafka-1.server.keystore.jks`, `kafka-2.server.keystore.jks`) для каждого брокера Kafka.
- **`pem/`**: Содержит корневой сертификат CA (`ca-root.pem`).
- **`run.sh`**: Скрипт для запуска сервисов и настройки.
- **`truststore/`**: Содержит файл хранилища доверенных сертификатов (`kafka.truststore.jks`), используемый для проверки SSL-сертификатов.
- **`zookeeper_jaas.conf`**: Конфигурационный файл JAAS для Zookeeper.

## Цель

Этот проект помогает настроить защищённый Kafka кластер, выполняя следующие действия:
1. Конфигурация необходимых сертификатов (CA, хранилища ключей, хранилища доверенных сертификатов).
2. Генерация и настройка необходимых конфигурационных файлов JAAS для Kafka и Zookeeper.
3. Запуск Kafka кластера в Docker окружении.

## Использование

1. Запустите `docker-compose up` для старта сервисов.
2. Используйте предоставленные скрипты `generate.sh` для генерации сертификатов.
3. Ознакомьтесь с результатами и подтверждением успешной настройки, проверив скриншоты в папке `Screenshots/`.


