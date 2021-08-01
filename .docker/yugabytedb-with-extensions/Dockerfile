ARG YB_VERSION=2.7.2.0-b216

FROM yugabytedb/yugabyte:${YB_VERSION}

COPY ./usr/local/bin/install-extensions.sh /usr/local/bin/install-extensions.sh
COPY ./extensions /extensions

RUN chmod +x /usr/local/bin/install-extensions.sh \
    && /usr/local/bin/install-extensions.sh
