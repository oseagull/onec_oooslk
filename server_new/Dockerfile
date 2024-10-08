FROM debian:bookworm-slim

COPY ./debian.sources /etc/apt/sources.list.d/debian.sources
COPY ./gosu-amd64 /bin/gosu

# Установка зависимостей и шрифтов, настройка локали
RUN apt-get update && \
      DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      procps \
      tzdata \
      debconf-utils \
      curl \
      unixodbc \
      libgsf-1-114 \
      keyboard-configuration \    
      locales \
      iproute2 \
      imagemagick \
      fontconfig \
      ca-certificates \
      ttf-mscorefonts-installer \
      geoclue-2.0 && \
  rm -rf /var/lib/apt/lists/* /var/cache/debconf && \
  localedef -i ru_RU -c -f UTF-8 -A /usr/share/locale/locale.alias ru_RU.UTF-8 && \
  fc-cache -f -v && \
  chmod +x /bin/gosu

ENV LANG ru_RU.UTF-8

# Установка платформы 1С
COPY ./setup-full-8.3.25.1394-x86_64.run /tmp/setup-full-8.3.25.1394-x86_64.run
RUN chmod +x /tmp/setup-full-8.3.25.1394-x86_64.run && \
  /tmp/setup-full-8.3.25.1394-x86_64.run --mode unattended --enable-components server,ws,server_admin,liberica_jre,ru && \
  rm /tmp/setup-full-8.3.25.1394-x86_64.run

# Создание символической ссылки на текущую директорию 1C
COPY ./create-symlink-to-current-1cv8.sh /create-symlink-to-current-1cv8.sh
RUN chmod +x /create-symlink-to-current-1cv8.sh && \
  /create-symlink-to-current-1cv8.sh && \
  rm /create-symlink-to-current-1cv8.sh

# Настройка группы и пользователя
RUN mkdir -p /var/log/1C /home/usr1cv8/.1cv8/1C/1cv8/conf /opt/1cv8/current/conf && \
  chown -R usr1cv8:grp1cv8 /var/log/1C /home/usr1cv8

ENV PATH="/opt/1cv8/current/jre/bin:${PATH}"

VOLUME /home/usr1cv8/.1cv8 /var/log/1C

# Копирование конфигурационных файлов
COPY ./logcfg.xml /home/usr1cv8/.1cv8/1C/1cv8/conf
COPY ./logcfg.xml /opt/1cv8/current/conf

# Установка точки входа и выполнение дополнительных настроек
RUN apt-get update && apt-get install -y apache2 && \
  rm -rf /var/lib/apt/lists/* /var/cache/debconf
COPY ./docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN ln -s usr/local/bin/docker-entrypoint.sh / 
RUN chmod +x /usr/local/bin/docker-entrypoint.sh /opt/1cv8/current/ragent

# Настройка точки входа и экспонирование портов
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
EXPOSE 1540 1541 1545 1560-1591 80
CMD ["ragent"]
