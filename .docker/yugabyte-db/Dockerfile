ARG BUILD_PLATFORM=
ARG ALMALINUX_VERSION=
ARG ALPINE_VERSION=

FROM --platform=${BUILD_PLATFORM} almalinux:${ALMALINUX_VERSION} as builder
ARG GID=1060
ARG GROUPNAME=yugabyte
ARG UID=1060
ARG USERNAME=yugabyte

ARG YB_REPOSITORY=https://github.com/yugabyte/yugabyte-db.git
ARG YB_SOURCE_VERSION=v2.19.0.0
ARG YB_RELEASE_VERSION=2.19.0.0

COPY yugabyte-${YB_RELEASE_VERSION}.tar.gz /yugabyte-${YB_RELEASE_VERSION}.tar.gz

LABEL YB_REPOSITORY=https://github.com/yugabyte/yugabyte-db.git \
    YB_SOURCE_VERSION=${YB_SOURCE_VERSION} \
    YB_RELEASE_VERSION=${YB_RELEASE_VERSION}

RUN mkdir -p /home/${USERNAME} \
    && tar xvfz /yugabyte-${YB_RELEASE_VERSION}.tar.gz -C /home/${USERNAME} --strip 1 \
    && /home/${USERNAME}/bin/post_install.sh

FROM --platform=${BUILD_PLATFORM} alpine:${ALPINE_VERSION}
ARG GID=1060
ARG GROUPNAME=yugabyte
ARG UID=1060
ARG USERNAME=yugabyte

RUN apk add --no-cache bash gawk sed grep bc coreutils openssl ca-certificates \
    && addgroup -g ${GID} ${GROUPNAME} \
    && adduser -u ${UID} -G ${GROUPNAME} -D -s /bin/bash ${USERNAME}

COPY --from=builder --chown=${USERNAME}:${GROUPNAME} /home/${USERNAME} /home/${USERNAME}

SHELL ["/bin/bash", "-c"]

RUN echo "export PS1='[\u@\h \W]\$ '" >> /home/${USERNAME}/.bashrc \
    && chown ${USERNAME}:${GROUPNAME} /home/${USERNAME}/.bashrc \
    && mkdir -p /mnt/{master,tserver} \
    && chown -R ${USERNAME}:${GROUPNAME} /mnt \
    && ln -s /home/${USERNAME}/bin/yb-admin /usr/local/bin/yb-admin \
    && ln -s /home/${USERNAME}/bin/yb-ts-cli /usr/local/bin/yb-ts-cli \
    && ln -s /home/${USERNAME}/bin/ycqlsh /usr/local/bin/ycqlsh \
    && ln -s /home/${USERNAME}/bin/ysqlsh /usr/local/bin/ysqlsh \
    && ln -s /home/${USERNAME}/bin/yugabyted /usr/local/bin/yugabyted \
    && echo 'Setting up dependencies required for yugabyted' \
    && apk --no-cache add python3 procps

USER ${USERNAME}
