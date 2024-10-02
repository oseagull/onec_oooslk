#!/bin/bash
cd ./pg16/
docker build -t $DOCKER_REGISTRY_URL/pgpro16:latest .
docker push $DOCKER_REGISTRY_URL/pgpro16:latest