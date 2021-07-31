FROM postgres:11.2

COPY etc/supervisor/supervisord-installcheck.conf /etc/supervisor/supervisord-installcheck.conf
COPY etc/supervisor/supervisord-run.conf /etc/supervisor/supervisord-run.conf
COPY usr/local/bin/make-entrypoint.sh /usr/local/bin/make-entrypoint.sh
COPY usr/local/bin/run-docker-entrypoint.sh /usr/local/bin/run-docker-entrypoint.sh

ENV PGDATA=/pgdata \
    PGUSER=postgres \
    POSTGRES_EXTENSIONS=example \
    EXTENSION_WORKDIR=/extension \
    POSTGRES_WAIT_SLEEP_SECS=5

RUN apt-get update -y \
    && echo 'Install Postgres development environment and other dependencies' \
        && apt-get install -y build-essential \
            libpq5=11.12-1.pgdg90+1 \
            libpq-dev=11.12-1.pgdg90+1 \
            postgresql-server-dev-11 \
            python3 python3-pip \
    && echo 'Prepare tablespaces support' \
        && mkdir -p /tablespaces/some_user \
        && chown -R ${PGUSER} /tablespaces \
    && echo 'Prepare the installcheck' \
        && chmod +x /usr/local/bin/make-entrypoint.sh \
        && chown 0744 /usr/local/bin/make-entrypoint.sh \
        && chmod +x /usr/local/bin/run-docker-entrypoint.sh \
        && chown 0744 /usr/local/bin/run-docker-entrypoint.sh \
        && mkdir -p ${PGDATA} \
        && chown -R ${PGUSER} ${PGDATA} \
    && echo 'Setup supervisor so regression tests can be executed' \
        && pip3 install supervisor \
        && chown -R ${PGUSER} /etc/supervisor \
        && mkdir -p /var/run/supervisor \
        && chown -R ${PGUSER} /var/run/supervisor \
        && mkdir -p /var/log/supervisor \
        && chown -R ${PGUSER} /var/log/supervisor \
    && echo 'Cleanup' \
        && apt-get clean

VOLUME /extension
ENTRYPOINT [ "/usr/local/bin/make-entrypoint.sh" ]
