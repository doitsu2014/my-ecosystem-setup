docker stack deploy -c docker-compose-initialize.yml \
	-c docker-compose-es-cluster.yml \
	-c docker-compose-postgres.yml \
	-c docker-compose-kafka-cluster.yml infrastructure