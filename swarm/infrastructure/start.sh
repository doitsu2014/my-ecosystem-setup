docker stack deploy -c docker-compose-initialize.yml \
	-c docker-compose-redis-cluster.yml \
	-c docker-compose-minio-cluster.yml \
	-c docker-compose-postgres-cluster.yml \
	-c docker-compose-mssql-cluster.yml \
	-c docker-compose-es-cluster.yml \
	-c docker-compose-kafka-cluster.yml infrastructure