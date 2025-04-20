docker compose run -d

# Подключитесь к одному из брокеров (например, kafka-0):
docker exec -it kafka-0 bash

cd /opt/bitnami/kafka/bin/

# Регистрируем admin SCRAM креды напрямую из ZooKeeper
# Скриншот 1
kafka-configs.sh \
  --zookeeper zookeeper:2181 \
  --alter \
  --add-config 'SCRAM-SHA-256=[password=password]' \
  --entity-type users \
  --entity-name admin


# Создаем пользователя для производителей
# Скриншот 2
kafka-configs.sh --bootstrap-server kafka-0:9094 --alter \
  --add-config 'SCRAM-SHA-256=[password=producer-pass]' \
  --entity-type users --entity-name producer \
  --command-config /opt/bitnami/kafka/config/command.properties

# Создаем пользователя для потребителей
# Скриншот 3
kafka-configs.sh --zookeeper zookeeper:2181 --alter \
  --add-config 'SCRAM-SHA-256=[password=consumer-pass]' \
  --entity-type users --entity-name consumer \
  --command-config /opt/bitnami/kafka/config/command.properties


# Создаем topic-1
# Скриншот 4
kafka-topics.sh --create --bootstrap-server kafka-0:9094 \
  --topic topic-1 --partitions 3 --replication-factor 3 \
  --command-config /opt/bitnami/kafka/config/command.properties

# Создаем topic-2
# Скриншот 5
kafka-topics.sh --create --bootstrap-server kafka-0:9094 \
  --topic topic-2 --partitions 3 --replication-factor 3 \
  --command-config /opt/bitnami/kafka/config/command.properties

# Для topic-1: разрешаем чтение и запись
# Скриншот 6
kafka-acls.sh --authorizer-properties zookeeper.connect=zookeeper:2181 \
  --add --allow-principal User:producer --operation Write --topic topic-1

# Скриншот 7
kafka-acls.sh --authorizer-properties zookeeper.connect=zookeeper:2181 \
  --add --allow-principal User:consumer --operation Read --topic topic-1 

# Для topic-2: разрешаем только запись
# Скриншот 8
kafka-acls.sh --authorizer-properties zookeeper.connect=zookeeper:2181 \
  --add --allow-principal User:producer --operation Write --topic topic-2 

# Явно запрещаем чтение для topic-2
# Скриншот 9
kafka-acls.sh --authorizer-properties zookeeper.connect=zookeeper:2181 \
  --add --deny-principal User:consumer --operation Read --topic topic-2 

# Отправка сообщения в topic-1 (должно работать)
cat <<EOF > /tmp/producer.config
security.protocol=SASL_SSL
sasl.mechanism=SCRAM-SHA-256
ssl.truststore.location=/opt/bitnami/kafka/config/certs/kafka.truststore.jks
ssl.truststore.password=supersecret
ssl.endpoint.identification.algorithm=
sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required \
  username="producer" \
  password="producer-pass";
EOF



# Скриншот 10
KAFKA_OPTS="-Djava.security.auth.login.config=/tmp/producer.config" \
kafka-console-producer.sh \
  --broker-list kafka-0:9094 \
  --topic topic-1 \
  --producer.config /tmp/producer.config

# Отправка сообщения в topic-2 (должно работать)

cat <<EOF > /tmp/consumer.config
security.protocol=SASL_SSL
sasl.mechanism=SCRAM-SHA-256
ssl.truststore.location=/opt/bitnami/kafka/config/certs/kafka.truststore.jks
ssl.truststore.password=supersecret
ssl.endpoint.identification.algorithm=
sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required \
  username="consumer" \
  password="consumer-pass";
EOF


# Скриншот 11
# Проверка 

KAFKA_OPTS="-Djava.security.auth.login.config=/tmp/consumer.config" \
kafka-console-consumer.sh \
  --bootstrap-server kafka-0:9094 \
  --topic topic-2 \
  --consumer.config /tmp/consumer.config

KAFKA_OPTS="-Djava.security.auth.login.config=/tmp/consumer.config" \
kafka-console-producer.sh \
  --broker-list kafka-0:9094 \
  --topic topic-2 \
  --producer.config /tmp/consumer.config
