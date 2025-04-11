docker compose up -d

docker compose ps

docker exec -it kafka-0 bash

# Создаем новый топик balanced_topic с 8 партициями и фактором репликации 3
kafka-topics.sh --bootstrap-server localhost:9092 --topic balanced_topic --create --partitions 8 --replication-factor 3 --if-not-exists

# Определяем текущее распределение партиций
kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic balanced_topic

# Создаем JSON-файл reassignment.json для перераспределения партиций.
cd /tmp/

echo '{
  "version": 1,
  "partitions": [
    {"topic": "balanced_topic", "partition": 0, "replicas": [2,0,1], "log_dirs": ["any", "any", "any"]},
    {"topic": "balanced_topic", "partition": 1, "replicas": [0,2,1], "log_dirs": ["any", "any", "any"]},
    {"topic": "balanced_topic", "partition": 2, "replicas": [1,0,2], "log_dirs": ["any", "any", "any"]},
    {"topic": "balanced_topic", "partition": 3, "replicas": [2,0,1], "log_dirs": ["any", "any", "any"]},
    {"topic": "balanced_topic", "partition": 4, "replicas": [0,1,2], "log_dirs": ["any", "any", "any"]},
    {"topic": "balanced_topic", "partition": 5, "replicas": [1,2,0], "log_dirs": ["any", "any", "any"]},
    {"topic": "balanced_topic", "partition": 6, "replicas": [2,1,0], "log_dirs": ["any", "any", "any"]},
    {"topic": "balanced_topic", "partition": 7, "replicas": [0,2,1], "log_dirs": ["any", "any", "any"]}
  ]
}' >> /tmp/reassignment.json

cat /tmp/reassignment.json

# Перераспределяем партиции.

cd /bitnami/kafka

kafka-reassign-partitions.sh --bootstrap-server localhost:9092 --broker-list "1,2,3" --topics-to-move-json-file "/tmp/reassignment.json" --generate

kafka-reassign-partitions.sh --bootstrap-server localhost:9092 --reassignment-json-file /tmp/reassignment.json --execute

# Проверьте статус перераспределения.
# Видим, что конфигурация изменилась.
kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic balanced_topic

# Смоделируем сбой брокера
# Для этого выйдем из терминала брокера 0

exit 

# Остановим контейнер для брокера
docker stop kafka-2

docker compose ps -a

docker exec -it kafka-0 bash

# Проверим состояние топиков после сбоя.
kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic balanced_topic

# Запустим брокер заново 
exit

docker restart kafka-2

docker compose ps 

# Проверяем и видим, что синхронизация реплик восстановилась.

docker exec -it kafka-0 bash

kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic balanced_topic

exit

docker compose down -v