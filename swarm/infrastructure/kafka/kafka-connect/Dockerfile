FROM confluentinc/cp-kafka-connect:6.2.1

RUN confluent-hub install --no-prompt debezium/debezium-connector-postgresql:1.6.0 \
  && confluent-hub install --no-prompt confluentinc/kafka-connect-elasticsearch:11.1.2 \
  && confluent-hub install --no-prompt debezium/debezium-connector-sqlserver:1.6.0
