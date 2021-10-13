# Overview
This is deployment folder of Kafka Cluster (included SSL protocol security). I am using based docker images on Confluent Platform.

# Introduction
**Step 1: Create development certificates and priv keys**
* If you are using Powershell or Linux bash, please use file `create-certs-without-r.sh` to create certificates.
* If your are using OSX, please use file `create-certs.sh` to create certificates. 
```
cd ./secrets
bash create-certs.sh
# note: type 'yes' on all questions.
```

**Step 2: Stack Kafka Cluster to docker swarm**
```
# use docker commands
docker stack deploy -c docker-compose.yml kafka

# check healthy all of services in stack
docker services list

# You can connect to boostrap servers, if all of them are healthy
```

# References
I wanna say thank to projects:
* [confluentinc/cp-docker-images](https://github.com/confluentinc/cp-docker-images)
* [confluentinc/cp-all-in-one](https://github.com/confluentinc/cp-all-in-one)
