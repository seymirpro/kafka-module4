# Для начала нужно создать конфигурацию корневого CA
# В нашем случае это файл ca.cnf

touch ca.cnf
################################################################################################
# Создадим корневой сертификат (Root CA) с использованием ca.cnf
# Создаем новый сертификатный запрос без шифрования приватного ключа
openssl req -new -nodes \
   -x509 \
   -days 365 \
   -newkey rsa:2048 \
   -keyout ca.key \
   -out ca.crt \
   -config ca.cnf

cat ca.crt ca.key > ca.pem

# На выходе получаем - сертификат CA в ca.crt и приватный ключ CA в ca.key
################################################################################################
# Создадим файлы конфигурации для брокеров - 0, 1, 2
# Создадим новый конфигурационный файл kafka-0-creds/kafka-0.cnf 
# Создадим новый конфигурационный файл kafka-1-creds/kafka-1.cnf
# Создадим новый конфигурационный файл kafka-2-creds/kafka-2.cnf
###############################################################################################
# Создадим приватный ключ и запрос на сертификат (CSR) для каждого брокера
openssl req -new \
    -newkey rsa:2048 \
    -keyout kafka-0-creds/kafka-0.key \
    -out kafka-0-creds/kafka-0.csr \
    -config kafka-0-creds/kafka-0.cnf \
    -nodes

openssl req -new \
    -newkey rsa:2048 \
    -keyout kafka-1-creds/kafka-1.key \
    -out kafka-1-creds/kafka-1.csr \
    -config kafka-1-creds/kafka-1.cnf \
    -nodes


openssl req -new \
    -newkey rsa:2048 \
    -keyout kafka-2-creds/kafka-2.key \
    -out kafka-2-creds/kafka-2.csr \
    -config kafka-2-creds/kafka-2.cnf \
    -nodes

########################################################################################################################
# Создадим сертификат для каждого брокера, подписанный CA
openssl x509 -req \
    -days 3650 \
    -in kafka-0-creds/kafka-0.csr \
    -CA ca.crt \
    -CAkey ca.key \
    -CAcreateserial \
    -out kafka-0-creds/kafka-0.crt \
    -extfile kafka-0-creds/kafka-0.cnf \
    -extensions v3_req

openssl x509 -req \
    -days 3650 \
    -in kafka-1-creds/kafka-1.csr \
    -CA ca.crt \
    -CAkey ca.key \
    -CAcreateserial \
    -out kafka-1-creds/kafka-1.crt \
    -extfile kafka-1-creds/kafka-1.cnf \
    -extensions v3_req

openssl x509 -req \
    -days 3650 \
    -in kafka-2-creds/kafka-2.csr \
    -CA ca.crt \
    -CAkey ca.key \
    -CAcreateserial \
    -out kafka-2-creds/kafka-2.crt \
    -extfile kafka-2-creds/kafka-2.cnf \
    -extensions v3_req

###############################################################################################################
# Создадим PKCS12-хранилище
# Создадим PKCS12-хранилище с сертификатом для каждого брокера
openssl pkcs12 -export \
    -in kafka-0-creds/kafka-0.crt \
    -inkey kafka-0-creds/kafka-0.key \
    -chain \
    -CAfile ca.pem \
    -name kafka-0 \
    -out kafka-0-creds/kafka-0.p12 \
    -password pass:your-password

openssl pkcs12 -export \
    -in kafka-1-creds/kafka-1.crt \
    -inkey kafka-1-creds/kafka-1.key \
    -chain \
    -CAfile ca.pem \
    -name kafka-1 \
    -out kafka-1-creds/kafka-1.p12 \
    -password pass:your-password

openssl pkcs12 -export \
    -in kafka-2-creds/kafka-2.crt \
    -inkey kafka-2-creds/kafka-2.key \
    -chain \
    -CAfile ca.pem \
    -name kafka-2 \
    -out kafka-2-creds/kafka-2.p12 \
    -password pass:your-password


#####################################################################################################################
# Создадим keystore для Kafka на уровне каждого брокера
"/mnt/c/Program Files/Amazon Corretto/jdk11.0.18_10/bin/keytool.exe" -importkeystore \
    -deststorepass your-password \
    -destkeystore kafka-0-creds/kafka.kafka-0.keystore.pkcs12 \
    -srckeystore kafka-0-creds/kafka-0.p12 \
    -deststoretype PKCS12  \
    -srcstoretype PKCS12 \
    -noprompt \
    -srcstorepass your-password

"/mnt/c/Program Files/Amazon Corretto/jdk11.0.18_10/bin/keytool.exe" -importkeystore \
    -deststorepass your-password \
    -destkeystore kafka-1-creds/kafka.kafka-1.keystore.pkcs12 \
    -srckeystore kafka-1-creds/kafka-1.p12 \
    -deststoretype PKCS12  \
    -srcstoretype PKCS12 \
    -noprompt \
    -srcstorepass your-password

"/mnt/c/Program Files/Amazon Corretto/jdk11.0.18_10/bin/keytool.exe" -importkeystore \
    -deststorepass your-password \
    -destkeystore kafka-2-creds/kafka.kafka-2.keystore.pkcs12 \
    -srckeystore kafka-2-creds/kafka-2.p12 \
    -deststoretype PKCS12  \
    -srcstoretype PKCS12 \
    -noprompt \
    -srcstorepass your-password

##############################################################################################################
# Создадим truststore для Kafka

"/mnt/c/Program Files/Amazon Corretto/jdk11.0.18_10/bin/keytool.exe" -import \
    -file ca.crt \
    -alias ca \
    -keystore kafka-0-creds/kafka.kafka-0.truststore.jks \
    -storepass your-password \
     -noprompt

"/mnt/c/Program Files/Amazon Corretto/jdk11.0.18_10/bin/keytool.exe" -import \
    -file ca.crt \
    -alias ca \
    -keystore kafka-1-creds/kafka.kafka-1.truststore.jks \
    -storepass your-password \
     -noprompt

"/mnt/c/Program Files/Amazon Corretto/jdk11.0.18_10/bin/keytool.exe" -import \
    -file ca.crt \
    -alias ca \
    -keystore kafka-2-creds/kafka.kafka-2.truststore.jks \
    -storepass your-password \
     -noprompt


#########################################################################################################
# Сохраним пароли
# Создадим файлы с паролями, которые указывали в предыдущих командах на уровне каждого брокера

echo "your-password" > kafka-0-creds/kafka-0_sslkey_creds
echo "your-password" > kafka-0-creds/kafka-0_keystore_creds
echo "your-password" > kafka-0-creds/kafka-0_truststore_creds

echo "your-password" > kafka-1-creds/kafka-1_sslkey_creds
echo "your-password" > kafka-1-creds/kafka-1_keystore_creds
echo "your-password" > kafka-1-creds/kafka-1_truststore_creds


echo "your-password" > kafka-2-creds/kafka-2_sslkey_creds
echo "your-password" > kafka-2-creds/kafka-2_keystore_creds
echo "your-password" > kafka-2-creds/kafka-2_truststore_creds