export KAFKA_OPTS="-Djava.security.auth.login.config=/opt/bitnami/kafka/config/kafka_jaas.conf"
bin/kafka-topics.sh --create --bootstrap-server broker1.kafka.cluster:9092 --topic mytopic --partitions 3 --replication-factor 3 --command-config ./config/client-ssl.properties
