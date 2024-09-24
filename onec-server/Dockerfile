FROM debian:bookworm-slim

COPY setup-full-8.3.25.1394-x86_64.run /tmp/
COPY docker-entrypoint.sh /

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends locales tzdata gosu apt-utils && \
    localedef -i ru_RU -c -f UTF-8 -A /usr/share/locale/locale.alias ru_RU.UTF-8 && \
    echo "ru_RU.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen && \
    groupadd -r grp1cv8 --gid=999 && \
    useradd -r -g grp1cv8 --uid=999 --home-dir=/home/usr1cv8 --shell=/bin/bash usr1cv8 && \
    mkdir -p /home/usr1cv8/srvinfo /var/log/1C /home/usr1cv8/.1cv8/1C/1cv8/conf && \
    chown -R usr1cv8:grp1cv8 /var/log/1C /home/usr1cv8 && \
    chmod +x /tmp/setup-full-8.3.25.1394-x86_64.run /docker-entrypoint.sh && \
    export LANG=ru_RU.UTF-8 LANGUAGE=ru_RU:ru LC_ALL=ru_RU.UTF-8 && \
    /tmp/setup-full-8.3.25.1394-x86_64.run --mode unattended --enable-components server,ws,liberica_jre,ru && \
    chmod -x /opt/1cv8/x86_64/8.3.25.1394/dbda && \
    rm /tmp/setup-full-8.3.25.1394-x86_64.run %% \
    rm -rf /var/lib/apt/lists/* 

COPY logcfg.xml /home/usr1cv8/.1cv8/1C/1cv8/conf/

ENV LANG=ru_RU.UTF-8 \
    LANGUAGE=ru_RU:ru \
    LC_ALL=ru_RU.UTF-8 \
    TZ=Europe/Moscow

VOLUME ["/home/usr1cv8", "/var/log/1C"]

EXPOSE 1540-1541 1545 1550 1560-1591

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["ragent"]
