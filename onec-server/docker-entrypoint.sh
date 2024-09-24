#!/bin/bash
# Если запуск докера выглядит как "ragent" (по умолчанию) то выполнить чего внутри if, а если что-то другое - то другое
if [ "$1" = "ragent" ]; then
  exec gosu usr1cv8 /opt/1cv8/x86_64/8.3.25.1394/ragent
fi

exec "$@"