#!/usr/bin/env bash
set -eu

CN="${CN:-kafka-admin}"
PASSWORD="${PASSWORD:-supersecret}"
TO_GENERATE_PEM="${CITY:-yes}"
VALIDITY_IN_DAYS=3650

CA_WORKING_DIRECTORY="certificate-authority"
TRUSTSTORE_WORKING_DIRECTORY="truststore"
KEYSTORE_WORKING_DIRECTORY="keystore"
PEM_WORKING_DIRECTORY="pem"
CA_KEY_FILE="ca-key"
CA_CERT_FILE="ca-cert"
DEFAULT_TRUSTSTORE_FILE="kafka.truststore.jks"
KEYSTORE_SIGN_REQUEST="cert-file"
KEYSTORE_SIGN_REQUEST_SRL="ca-cert.srl"
KEYSTORE_SIGNED_CERT="cert-signed"
KAFKA_HOSTS_FILE="kafka-hosts.txt"

# Проверяем, что файл существует и не пуст
if [ ! -f "$KAFKA_HOSTS_FILE" ] || [ ! -s "$KAFKA_HOSTS_FILE" ]; then
  echo "Error: '$KAFKA_HOSTS_FILE' is missing or empty. Add hostnames like 'kafka-0'."
  exit 1
fi

echo "Welcome to the Kafka SSL certificate generator script."

# Создаём CA
mkdir -p "$CA_WORKING_DIRECTORY"
if [ ! -f "$CA_WORKING_DIRECTORY/$CA_KEY_FILE" ] || [ ! -f "$CA_WORKING_DIRECTORY/$CA_CERT_FILE" ]; then
  echo "Generating CA..."
  openssl req -new -newkey rsa:4096 -days "$VALIDITY_IN_DAYS" -x509 -subj "/CN=$CN" \
    -keyout "$CA_WORKING_DIRECTORY/$CA_KEY_FILE" -out "$CA_WORKING_DIRECTORY/$CA_CERT_FILE" -nodes
fi

# Генерируем keystore для каждого хоста
mkdir -p "$KEYSTORE_WORKING_DIRECTORY"
while read -r KAFKA_HOST || [ -n "$KAFKA_HOST" ]; do
  # Удаляем \r и пробелы
  KAFKA_HOST=$(echo "$KAFKA_HOST" | tr -d '\r' | xargs)
  if [[ -z "$KAFKA_HOST" ]]; then
    continue
  fi

  KEY_STORE_FILE_NAME="$KAFKA_HOST.server.keystore.jks"
  echo "Generating keystore for $KAFKA_HOST..."
  
  keytool -genkey \
    -keystore "$KEYSTORE_WORKING_DIRECTORY/$KEY_STORE_FILE_NAME" \
    -alias localhost -validity "$VALIDITY_IN_DAYS" -keyalg RSA \
    -noprompt -dname "CN=$KAFKA_HOST" -keypass "$PASSWORD" -storepass "$PASSWORD"

  keytool -certreq \
    -keystore "$KEYSTORE_WORKING_DIRECTORY/$KEY_STORE_FILE_NAME" \
    -alias localhost -file "$KEYSTORE_SIGN_REQUEST" -keypass "$PASSWORD" -storepass "$PASSWORD"

  openssl x509 -req -CA "$CA_WORKING_DIRECTORY/$CA_CERT_FILE" \
    -CAkey "$CA_WORKING_DIRECTORY/$CA_KEY_FILE" \
    -in "$KEYSTORE_SIGN_REQUEST" -out "$KEYSTORE_SIGNED_CERT" \
    -days "$VALIDITY_IN_DAYS" -CAcreateserial

  keytool -import \
    -keystore "$KEYSTORE_WORKING_DIRECTORY/$KEY_STORE_FILE_NAME" \
    -alias CARoot -file "$CA_WORKING_DIRECTORY/$CA_CERT_FILE" \
    -keypass "$PASSWORD" -storepass "$PASSWORD" -noprompt

  keytool -import \
    -keystore "$KEYSTORE_WORKING_DIRECTORY/$KEY_STORE_FILE_NAME" \
    -alias localhost -file "$KEYSTORE_SIGNED_CERT" \
    -keypass "$PASSWORD" -storepass "$PASSWORD"

  rm -f "$CA_WORKING_DIRECTORY/$KEYSTORE_SIGN_REQUEST_SRL" "$KEYSTORE_SIGN_REQUEST" "$KEYSTORE_SIGNED_CERT"
done < "$KAFKA_HOSTS_FILE"

# Генерируем truststore
mkdir -p "$TRUSTSTORE_WORKING_DIRECTORY"
keytool -import \
  -keystore "$TRUSTSTORE_WORKING_DIRECTORY/$DEFAULT_TRUSTSTORE_FILE" \
  -alias CARoot -file "$CA_WORKING_DIRECTORY/$CA_CERT_FILE" \
  -noprompt -dname "CN=$CN" -keypass "$PASSWORD" -storepass "$PASSWORD"

# Генерируем PEM (если нужно)
if [ "$TO_GENERATE_PEM" == "yes" ]; then
  mkdir -p "$PEM_WORKING_DIRECTORY"
  keytool -exportcert \
    -alias CARoot -keystore "$TRUSTSTORE_WORKING_DIRECTORY/$DEFAULT_TRUSTSTORE_FILE" \
    -rfc -file "$PEM_WORKING_DIRECTORY/ca-root.pem" -storepass "$PASSWORD"
fi

echo "Done! Generated files:"
tree "$CA_WORKING_DIRECTORY" "$KEYSTORE_WORKING_DIRECTORY" "$TRUSTSTORE_WORKING_DIRECTORY" "$PEM_WORKING_DIRECTORY"