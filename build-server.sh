#!/bin/bash
cd ./server_new/
docker build -t $DOCKER_REGISTRY_URL/onec-server:$ONEC_VERSION .
docker push $DOCKER_REGISTRY_URL/onec-server:$ONEC_VERSION
docker push $DOCKER_REGISTRY_URL/onec-server:$ONEC_VERSION