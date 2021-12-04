docker stack deploy -c docker-compose-initialize.yml \
	-c docker-compose-postgres-cluster.yml \
	-c docker-compose-mssql-cluster.yml infrastructure