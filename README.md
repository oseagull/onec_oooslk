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

The project uses environment variables for configuration. Create a `.env` and `.onec.env` files in the project root from the examples:
`.env.example`
`.onec.env.example`

The varible INCLUDE_PGDEFAULT=yes appends the content of pgdefault.conf file to postgresql.conf file. If you want to specify any custom parameters for your PostgreSQL server you can do it there.

## Building the 1C:Enterprise Server Image

Use the `build-server.sh` script to build and push the 1C:Enterprise server image:

Running the Environment

To start the environment:
`docker-compose up -d`

This will start all services defined in the `docker-compose.yml` file.

## Services

- **1C:Enterprise Server**: Runs on ports 1540-1541, 1560-1591, and 1545
- **PostgreSQL Databases**: Two instances (small and big) running internally
- **Pusk Service**: Accessible via Traefik at `http://onec.oooslk.ru`
- **Traefik**: Acts as a reverse proxy and handles basic authentication

## Volumes

The setup uses Docker volumes for persistent storage:

- `srv_data`: 1C:Enterprise server data
- `srv_log`: 1C:Enterprise server logs
- `pusk_data`: Pusk service data
- `pusk_log`: Pusk service logs
- `pg_data_small`: PostgreSQL data for the small instance
- `pg_data_big`: PostgreSQL data for the big instance

## Network

All services are connected to the `onec_net` bridge network.

## Security

- Traefik is configured with basic authentication for accessing the Pusk service.
- Make sure to use strong passwords and keep your `.env` file secure.

## Maintenance

To update the environment:

1. Pull the latest changes from the repository
2. Rebuild the 1C:Enterprise server image if necessary
3. Run `docker-compose up -d` to apply changes

## License

This project is licensed under the MIT License - see the LICENSE.md file for details.
