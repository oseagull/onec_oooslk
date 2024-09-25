#!/bin/bash

# Установка значений по умолчанию
setup_defaults() {
  DEFAULT_PORT=1540
  DEFAULT_REGPORT=1541
  DEFAULT_RANGE=1560:1591
  DEFAULT_SECLEVEL=0
  DEFAULT_PINGPERIOD=1000
  DEFAULT_PINGTIMEOUT=5000
  DEFAULT_DEBUG=-tcp
  DEFAULT_DEBUGSERVERPORT=1550
  DEFAULT_RAS_PORT=1545
}

# Настройка команды запуска ragent
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

# Настройка команды запуска ras
setup_ras_cmd() {
  RAS_CMD="gosu usr1cv8 /opt/1cv8/current/ras cluster --daemon"
  RAS_CMD+=" --port ${RAS_PORT:-$DEFAULT_RAS_PORT}"
  RAS_CMD+=" localhost:${PORT:-$DEFAULT_PORT}"
}

# Изменение прав доступа к директории пользователя
change_directory_permissions() {
  chown -R usr1cv8:grp1cv8 /home/usr1cv8
}

# Function to read and process .webinst.env file
process_webinst_env() {
  if [ -f "/usr/local/bin/.webinst.env" ]; then
    source /usr/local/bin/.webinst.env
    
    if [ -z "$WWW_ROOT" ] || [ -z "$WEBINST_PATH" ] || [ -z "$DATABASES" ]; then
      echo "Error: .webinst.env file is missing required variables."
      return 1
    fi

    # Create WWW root directory if it doesn't exist
    mkdir -p "$WWW_ROOT"

    # Process each database
    for DB_NAME in $DATABASES; do
      DB_DIR="$WWW_ROOT/$DB_NAME"
      
      # Create directory for the database
      mkdir -p "$DB_DIR"
      
      # Run webinst command
      WEBINST_CMD="$WEBINST_PATH -apache24 -wsdir $DB_NAME -dir '$DB_DIR' -connstr 'Srvr=\"onec-docker\";Ref=\"$DB_NAME\";'"
      echo "Running webinst for $DB_NAME"
      echo "Command: $WEBINST_CMD"
      eval "$WEBINST_CMD"
    done
  else
    echo "Warning: .webinst.env file not found. Skipping webinst processing."
  fi
}

# Function to check for changes and apply them
check_and_apply_changes() {
  local last_md5sum=""
  while true; do
    current_md5sum=$(md5sum /usr/local/bin/.webinst.env | awk '{print $1}')
    if [ "$current_md5sum" != "$last_md5sum" ]; then
      echo "Configuration changed. Applying updates..."
      process_webinst_env
      echo "Restarting Apache..."
      apachectl graceful  # Gracefully restart Apache
      last_md5sum=$current_md5sum
    fi
    sleep 600
  done
}

# Главная функция скрипта
main() {
  setup_defaults
  change_directory_permissions
  process_webinst_env

  if [ "$1" = "ragent" ]; then
    setup_ragent_cmd
    setup_ras_cmd

    echo "Запускаем ras с необходимыми параметрами"
    echo "Выполняемая команда: $RAS_CMD"
    $RAS_CMD 2>&1 &  # Запуск ras в фоновом режиме

    echo "Запускаем ragent с необходимыми параметрами"
    echo "Выполняемая команда: $RAGENT_CMD"
    exec $RAGENT_CMD 2>&1

    # Start Apache
    echo "Starting Apache..."
    apachectl start

    # Start the change detection loop
    check_and_apply_changes &
    # Wait for all background processes
    wait
  else
    # Если первый аргумент не 'ragent', выполняем команду, переданную в аргументах
    "$@"
  fi
}

# Вызов главной функции
main "$@"
