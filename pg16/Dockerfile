FROM docker.io/library/debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Europe/Moscow \
    PGDATA=/var/lib/1c/pgdata \
    PGSOCKET=/tmp/postgresql/socket \
    PATH=/opt/pgpro/1c-16/bin:$PATH

COPY pgpro-repo-add.sh entrypoint.sh pgdefault.conf /

RUN apt-get update && \
    apt-get install -y locales tzdata apt-utils && \
    sed -i -e 's/# ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=ru_RU.UTF-8 LANGUAGE=ru_RU:ru && \
    chmod +x /pgpro-repo-add.sh /entrypoint.sh && \
    /pgpro-repo-add.sh && \
    apt-get -y install \
        postgrespro-1c-16 \
        postgresql-client \
        gosu \
        pgagent && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone && \
    rm /pgpro-repo-add.sh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* && \
    mkdir -p "$PGDATA" "$PGSOCKET" && \
    chown -R postgres:postgres "$PGDATA" "$PGSOCKET" && \
    chmod 700 "$PGDATA" && \
    chmod 775 "$PGSOCKET"

ENV LANG=ru_RU.UTF-8 \
    LANGUAGE=ru_RU:ru \
    LC_ALL=ru_RU.UTF-8

VOLUME ${PGDATA}

EXPOSE 5432/tcp

WORKDIR /

ENTRYPOINT ["/entrypoint.sh"]

CMD ["postgres"]

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD gosu postgres pg_isready -h localhost || exit 1
