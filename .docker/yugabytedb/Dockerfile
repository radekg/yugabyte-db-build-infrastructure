FROM centos:7.9.2009 as builder
ARG GID=1060
ARG GROUPNAME=myybuser
ARG UID=1060
ARG USERNAME=myybuser

ARG YB_REPOSITORY=https://github.com/yugabyte/yugabyte-db.git
ARG YB_SOURCE_VERSION=v2.7.2
ARG YB_RELEASE_VERSION=2.7.2.0

COPY yugabyte-${YB_VERSION}.tar.gz /home/${USERNAME}/yugabyte-${YB_VERSION}.tar.gz

LABEL YB_REPOSITORY=https://github.com/yugabyte/yugabyte-db.git \
    YB_SOURCE_VERSION=${YB_SOURCE_VERSION} \
    YB_RELEASE_VERSION=${YB_RELEASE_VERSION}

RUN groupadd -g ${GID} ${GROUPNAME} \
    && useradd -m -d /home/${USERNAME} -g ${GID} -u ${UID} -s /bin/bash ${USERNAME} \
    && tar xvfz /home/${USERNAME}/yugabyte-${YB_RELEASE_VERSION}.tar.gz -C /home/${USERNAME} --strip 1 \
    && /home/${USERNAME}/bin/post_install.sh \
    && chown -R ${USERNAME}:${GROUPNAME} /home/${USERNAME} \
    && ln -s /home/${USERNAME}/bin/yb-admin /usr/local/bin/yb-admin \
    && ln -s /home/${USERNAME}/bin/yb-ts-cli /usr/local/bin/yb-ts-cli \
    && ln -s /home/${USERNAME}/bin/ycqlsh /usr/local/bin/ycqlsh \
    && ln -s /home/${USERNAME}/bin/ysqlsh /usr/local/bin/ysqlsh \
    && ln -s /home/${USERNAME}/bin/yugabyted /usr/local/bin/yugabyted \
    && chown -R ${USERNAME}:${GROUPNAME} /usr/local/bin

USER ${USERNAME}

