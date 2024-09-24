#!/bin/bash

set -e
set -x

trap 'log "Script is exiting unexpectedly. Last command: $BASH_COMMAND"' EXIT

# Define log file
LOG_FILE="/var/log/postgresql/setup.log"

log() {
    local message="[$(date +'%Y-%m-%d %H:%M:%S')] $*"
    echo "$message"
    echo "$message" >> "$LOG_FILE"
}

# Ensure log directory exists and is writable
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"
chmod 644 "$LOG_FILE"

log "Starting PostgreSQL setup script"

# Ensure the script is run as root
if [ "$(id -u)" != "0" ]; then
    log "This script must be run as root"
    exit 1
fi

initialize_database() {
    log "Entering initialize_database function"
    if [ -z "$PG_PASSWORD" ]; then
        log "ERROR: PG_PASSWORD must be set for database initialization"
        exit 1
    fi
    
    if ! gosu postgres /opt/pgpro/1c-16/bin/initdb -D "$PGDATA" --auth-host=md5 --auth-local=peer; then
        log "Database initialization failed"
        log "initdb exit code: $?"
        exit 1
    fi
    log "initdb completed successfully"

    # Use pg_ctl to set the password without starting the server
    encrypted_pass=$(echo -n "${PG_PASSWORD}postgres" | md5sum | awk '{print "md5" $1}')
    gosu postgres /opt/pgpro/1c-16/bin/pg_ctl -D "$PGDATA" -o "-c config_file=$PGDATA/postgresql.conf" start
    gosu postgres psql -c "ALTER USER postgres WITH PASSWORD '$encrypted_pass';"
    gosu postgres /opt/pgpro/1c-16/bin/pg_ctl -D "$PGDATA" stop

    log "Database initialized with provided password"
    log "Exiting initialize_database function"
}


configure_postgresql() {
    log "Configuring PostgreSQL..."

    log "Current contents of postgresql.conf:"
    cat "$PGDATA/postgresql.conf" >> "$LOG_FILE"

    log "Appending custom settings to postgresql.conf..."
    {
        echo "# Custom settings"
        echo "synchronous_commit = off"
        echo "unix_socket_directories = '/tmp,$PGSOCKET'"
        echo "listen_addresses = '*'"
		echo 

        if [ "${INCLUDE_PGDEFAULT:-no}" = "yes" ] && [ -f /pgdefault.conf ]; then
            echo ""  # Add a newline for clarity
            echo "# Include contents from pgdefault.conf"
            cat /pgdefault.conf
        fi
    } >> "$PGDATA/postgresql.conf"

    log "Updated contents of postgresql.conf:"
    cat "$PGDATA/postgresql.conf" >> "$LOG_FILE"

    log "Current contents of pg_hba.conf:"
    cat "$PGDATA/pg_hba.conf" >> "$LOG_FILE"

    log "Appending to pg_hba.conf..."
    echo "host all all 0.0.0.0/0 md5" >> "$PGDATA/pg_hba.conf"

    log "Updated contents of pg_hba.conf:"
    cat "$PGDATA/pg_hba.conf" >> "$LOG_FILE"

    log "PostgreSQL configuration complete"
}

# Main execution
if [ "$1" = 'postgres' ]; then
    log "PGDATA is set to: $PGDATA"
    log "Contents of PGDATA directory:"
    ls -la "$PGDATA" >> "$LOG_FILE"

    # Ensure PGDATA directory exists and has correct permissions
    mkdir -p "$PGDATA"
    chown postgres:postgres "$PGDATA"
    chmod 700 "$PGDATA"

    if [ ! -s "$PGDATA/PG_VERSION" ]; then
        log "PG_VERSION not found. Initializing database..."
        initialize_database
        log "Database initialized. Configuring PostgreSQL..."
        log "Checking write permissions for $PGDATA"
        if [ -w "$PGDATA" ]; then
            log "$PGDATA is writable"
            configure_postgresql
            log "PostgreSQL configuration completed."
        else
            log "ERROR: $PGDATA is not writable"
            exit 1
        fi
    else
        log "Existing database found. Skipping initialization and configuration."
    fi

    # Ensure PGSOCKET directory exists and has correct permissions
    mkdir -p "$PGSOCKET"
    chown postgres:postgres "$PGSOCKET"
    chmod 775 "$PGSOCKET"

    log "Final check of configuration files:"
    log "postgresql.conf contents:"
    cat "$PGDATA/postgresql.conf" >> "$LOG_FILE"
    log "pg_hba.conf contents:"
    cat "$PGDATA/pg_hba.conf" >> "$LOG_FILE"

    log "Starting PostgreSQL server..."
    exec gosu postgres /opt/pgpro/1c-16/bin/postgres -D "$PGDATA"
else
    log "Executing command: $@"
    exec "$@"
fi
