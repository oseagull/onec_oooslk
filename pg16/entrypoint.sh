#!/bin/bash

set -e

# Define log file
LOG_FILE="/var/lib/1c/pgdata/setup.log"
touch "$LOG_FILE"
chmod 644 "$LOG_FILE"

log() {
    local message="[$(date +'%Y-%m-%d %H:%M:%S')] $*"
    echo "$message"
    echo "$message" >> "$LOG_FILE"
    # # Also log to PostgreSQL log if it exists
    # local pg_log_file=$(find "$PGDATA/log" -name "postgresql-*.log" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)
    # if [ -n "$pg_log_file" ]; then
    #     echo "$message" >> "$pg_log_file"
    # fi
}

log "Starting PostgreSQL setup script"

initialize_database() {
    if [ -z "$PG_PASSWORD" ]; then
        log "ERROR: PG_PASSWORD must be set for database initialization"
        exit 1
    fi
    
    if ! gosu postgres /opt/pgpro/1c-16/bin/initdb -D "$PGDATA" --auth-host=md5 --auth-local=peer; then
        log "Database initialization failed"
        exit 1
    fi

    encrypted_pass=$(echo -n "${PG_PASSWORD}postgres" | md5sum | awk '{print "md5" $1}')
    gosu postgres /opt/pgpro/1c-16/bin/pg_ctl -D "$PGDATA" -o "-c config_file=$PGDATA/postgresql.conf" start
    gosu postgres psql -c "ALTER USER postgres WITH PASSWORD '$encrypted_pass';"
    gosu postgres /opt/pgpro/1c-16/bin/pg_ctl -D "$PGDATA" stop

    log "Database initialized with provided password"
}


configure_postgresql() {
    log "Removing existing custom settings..."
    sed -i '/# Custom settings added by entrypoint script/,$d' "$PGDATA/postgresql.conf"

    log "Adding new custom settings..."
    {
        echo "# Custom settings added by entrypoint script"
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

    sed -i '/host all all 0\.0\.0\.0\/0 md5/d' "$PGDATA/pg_hba.conf"
    echo "host all all 0.0.0.0/0 md5" >> "$PGDATA/pg_hba.conf"

    log "PostgreSQL configuration complete"
}

# Main execution
if [ "$1" = 'postgres' ]; then
    mkdir -p "$PGDATA"
    chown postgres:postgres "$PGDATA"
    chmod 700 "$PGDATA"

    if [ ! -s "$PGDATA/PG_VERSION" ]; then
        log "PG_VERSION not found. Initializing database..."
        initialize_database
        log "Database initialized."
    else
        log "Existing database found. Skipping initialization."
    fi

    log "Configuring PostgreSQL..."
    configure_postgresql
    log "PostgreSQL configuration completed."

    mkdir -p "$PGSOCKET"
    chown postgres:postgres "$PGSOCKET"
    chmod 775 "$PGSOCKET"

    log "Starting PostgreSQL server..."
    exec gosu postgres postgres -D "$PGDATA"

else
    exec "$@"
fi