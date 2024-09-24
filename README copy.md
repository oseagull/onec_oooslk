# 1C:Enterprise Docker Environment

This project provides a Docker-based environment for running 1C:Enterprise server with PostgreSQL databases and additional services.

## Overview

The setup includes:
- 1C:Enterprise server
- Two PostgreSQL databases (small and big configurations)
- Pusk service
- Traefik as a reverse proxy

## Prerequisites

- Docker and Docker Compose
- Access to a Docker registry (specified by DOCKER_REGISTRY_URL)
- 1C:Enterprise account credentials

## Configuration

The project uses environment variables for configuration. Create a `.env` file in the project root with the following variables:

DOCKER_REGISTRY_URL=<local-docker-registry-url>
PG_PASSWORD=<postgres-db-password>
PUSK_PASS=<$(htpasswd -nb username password)>
TZ=<timezone>
DOCKER_LOGIN=<1c-enterprise-username>
DOCKER_PASSWORD=<1c-enterprise-password>
ONEC_USERNAME=<1c-enterprise-username> 
ONEC_PASSWORD=<1c-enterprise-password>
ONEC_VERSION=<1c-enterprise-version> 
