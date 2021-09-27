FROM confluentinc/cp-kafka-connect-base:6.2.0

RUN echo 'rest.extension.classes=org.apache.kafka.connect.rest.basic.auth.extension.BasicAuthSecurityRestExtension' >> /etc/kafka/connect-distributed.properties

RUN confluent-hub install --no-prompt debezium/debezium-connector-postgresql:1.6.0 \
  && confluent-hub install --no-prompt confluentinc/kafka-connect-elasticsearch:11.1.2 \
  && confluent-hub install --no-prompt debezium/debezium-connector-sqlserver:1.6.0
