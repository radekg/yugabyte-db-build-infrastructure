# 
# YugabyteDB build.
# These steps are roughly based on:
# https://docs.yugabyte.com/latest/contribute/core-database/build-from-src-centos/
# 
FROM almalinux:8.5

ARG MVN_VERSION=3.8.4

COPY usr/local/bin/patch_postgres_h.sh /usr/local/bin/patch_postgres_h.sh
COPY usr/local/bin/yb-first-pass-build.sh /usr/local/bin/yb-first-pass-build.sh
COPY usr/local/bin/yb-rebuild-extensions.sh /usr/local/bin/yb-rebuild-extensions.sh
COPY usr/local/bin/yb-rebuild.sh /usr/local/bin/yb-rebuild.sh
COPY usr/local/bin/yb-release.sh /usr/local/bin/yb-release.sh
COPY usr/local/bin/yb-tests.sh /usr/local/bin/yb-tests.sh

RUN chmod +x /usr/local/bin/yb-first-pass-build.sh \
    && chmod +x /usr/local/bin/yb-rebuild-extensions.sh \
    && chmod +x /usr/local/bin/yb-rebuild.sh \
    && chmod +x /usr/local/bin/yb-release.sh \
    && chmod +x /usr/local/bin/yb-tests.sh \
    && chmod +x /usr/local/bin/ypatch_postgres_h.sh \
    && echo 'YugabyteDB build tooling' \
    && dnf update -y \
    && dnf group install "Development Tools" -y \
    && dnf install bzip2 clang cmake curl java-1.8.0-openjdk java-1.8.0-openjdk-devel libatomic python3 python3-pip python3-devel rsync wget -y \
    && wget https://dlcdn.apache.org/maven/maven-3/${MVN_VERSION}/binaries/apache-maven-${MVN_VERSION}-bin.tar.gz -P /tmp \
    && tar xf /tmp/apache-maven-${MVN_VERSION}-bin.tar.gz -C /opt \
    && ln -s /opt/apache-maven-${MVN_VERSION}/bin/mvn /usr/bin/mvn

VOLUME /root/.m2
VOLUME /opt/yb-build
VOLUME /yb-source
