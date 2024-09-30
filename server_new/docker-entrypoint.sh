#!/bin/bash

# Set default values
setup_defaults() {
    DEFAULT_PORT=1540
    DEFAULT_REGPORT=1541
    DEFAULT_RANGE=1560:1591
    DEFAULT_SECLEVEL=0
    DEFAULT_PINGPERIOD=1000
    DEFAULT_PINGTIMEOUT=5000
    DEFAULT_RAS_PORT=1545
}

# Setup ragent command
setup_ragent_cmd() {
    RAGENT_CMD="gosu usr1cv8 /opt/1cv8/current/ragent"
    RAGENT_CMD+=" /port ${PORT:-$DEFAULT_PORT}"
    RAGENT_CMD+=" /regport ${REGPORT:-$DEFAULT_REGPORT}"
    RAGENT_CMD+=" /range ${RANGE:-$DEFAULT_RANGE}"
    RAGENT_CMD+=" /seclev ${SECLEVEL:-$DEFAULT_SECLEVEL}"
    RAGENT_CMD+=" /d ${D:-/home/usr1cv8/.1cv8}"
    RAGENT_CMD+=" /pingPeriod ${PINGPERIOD:-$DEFAULT_PINGPERIOD}"
    RAGENT_CMD+=" /pingTimeout ${PINGTIMEOUT:-$DEFAULT_PINGTIMEOUT}"
}

# Setup ras command
setup_ras_cmd() {
    RAS_CMD="gosu usr1cv8 /opt/1cv8/current/ras cluster --daemon"
    RAS_CMD+=" --port ${RAS_PORT:-$DEFAULT_RAS_PORT}"
    RAS_CMD+=" localhost:${PORT:-$DEFAULT_PORT}"
}

# Change directory permissions
change_directory_permissions() {
    chown -R usr1cv8:grp1cv8 /home/usr1cv8
}

# Publish 1C infobases
publish_1c_infobases() {
    if [ -n "$INFOBASE_NAMES" ]; then
        IFS=',' read -ra INFOBASES <<< "$INFOBASE_NAMES"
        for db_name in "${INFOBASES[@]}"; do
            echo "Setting up 1C database: $db_name"
            mkdir -p "/var/www/1c/$db_name"
            /opt/1cv8/current/webinst -apache24 -wsdir "$db_name" -dir "/var/www/1c/$db_name" -connstr "Srvr=\"onec-docker\";Ref=\"$db_name\";"
        done
    else
        echo "No infobases specified in INFOBASE_NAMES. Skipping infobase setup."
    fi
}

# Start Apache
start_apache() {
    echo "Starting Apache..."
    apache2ctl -D FOREGROUND &
}

# New function to handle signals
handle_signal() {
    echo "Received shutdown signal. Shutting down gracefully..."
    
    # Stop Apache
    echo "Stopping Apache..."
    apache2ctl stop
    
    # Stop RAS
    echo "Stopping RAS..."
    pkill -f "/opt/1cv8/current/ras"
    
    # Stop ragent (this will also end the script due to 'exec')
    echo "Stopping ragent..."
    pkill -f "/opt/1cv8/current/ragent"
    
    exit 0
}

# Modified main function
main() {
    setup_defaults
    change_directory_permissions

    if [ "$1" = "ragent" ]; then
        setup_ragent_cmd
        setup_ras_cmd
        publish_1c_infobases
        
        # Set up signal handling
        trap 'handle_signal' SIGTERM SIGINT

        start_apache

        echo "Starting ras with required parameters"
        echo "Command: $RAS_CMD"
        $RAS_CMD 2>&1 &

        echo "Starting ragent with required parameters"
        echo "Command: $RAGENT_CMD"
        
        # Run ragent in the foreground, but don't use 'exec'
        $RAGENT_CMD 2>&1 &
        
        # Wait for any signal
        wait
    else
        exec "$@"
    fi
}

# Call the main function
main "$@"
