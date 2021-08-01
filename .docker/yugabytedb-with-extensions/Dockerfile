ARG YB_VERSION=2.7.2.0-b216

FROM yugabytedb/yugabyte:${YB_VERSION}

COPY ./usr/local/bin/install-extensions.sh /usr/local/bin/install-extensions.sh
COPY ./home/yugabyte/bin/post_install.sh /home/yugabyte/bin/post_install.sh
COPY ./extensions /extensions

RUN chmod +x /home/yugabyte/bin/post_install.sh \
    && chmod +x /usr/local/bin/install-extensions.sh \
    && /usr/local/bin/install-extensions.sh
