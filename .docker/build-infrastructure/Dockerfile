# 
# YugabyteDB build steps from:
# https://docs.yugabyte.com/preview/contribute/core-database/build-from-src-almalinux/
# 

ARG BUILD_PLATFORM=
ARG ALMALINUX_VERSION=

FROM --platform=${BUILD_PLATFORM} almalinux:${ALMALINUX_VERSION}

# Maven 3.9.x apparently has breaking changes,
# end effect is, with 3.9.x, java build doesn't work - build hangs at random places.

ARG GCC_VERSION=11
ARG PYTHON_VERSION=39

COPY usr/local/bin/apply-extensions.sh /usr/local/bin/apply-extensions.sh
COPY usr/local/bin/apply-patches.sh /usr/local/bin/apply-patches.sh
COPY usr/local/bin/patch_postgres_h.sh /usr/local/bin/patch_postgres_h.sh
COPY usr/local/bin/yb-first-pass-build.sh /usr/local/bin/yb-first-pass-build.sh
COPY usr/local/bin/yb-rebuild-extensions.sh /usr/local/bin/yb-rebuild-extensions.sh
COPY usr/local/bin/yb-rebuild.sh /usr/local/bin/yb-rebuild.sh
COPY usr/local/bin/yb-release.sh /usr/local/bin/yb-release.sh
COPY usr/local/bin/yb-tests.sh /usr/local/bin/yb-tests.sh

RUN chmod +x /usr/local/bin/apply-extensions.sh \
    && chmod +x /usr/local/bin/apply-patches.sh \
    && chmod +x /usr/local/bin/patch_postgres_h.sh \
    && chmod +x /usr/local/bin/yb-first-pass-build.sh \
    && chmod +x /usr/local/bin/yb-rebuild-extensions.sh \
    && chmod +x /usr/local/bin/yb-rebuild.sh \
    && chmod +x /usr/local/bin/yb-release.sh \
    && chmod +x /usr/local/bin/yb-tests.sh \
    && echo 'YugabyteDB build tooling' \
    && dnf -y update \
    && dnf -y groupinstall 'Development Tools' \
    && dnf install -y epel-release libatomic rsync \
    && dnf install -y python${PYTHON_VERSION} python${PYTHON_VERSION}-devel \
    && dnf install -y cmake3 \
    && dnf install -y java-11-openjdk java-11-openjdk-devel \
    && echo 'Additional programs' \
    && dnf install -y bzip2 git jq wget which \
    && echo 'Latest Ninja' \
    && export latest_ninja_download=$(curl -Ls "https://api.github.com/repos/ninja-build/ninja/releases/latest" | jq '.assets[] | select(.name == "ninja-linux.zip") | .browser_download_url' -r) \
    && curl -Ls "$latest_ninja_download" | zcat | tee /usr/local/bin/ninja >/dev/null \
    && chmod +x /usr/local/bin/ninja \
    && echo 'Download Maven newer than default 3.0.5:' \
    && export latest_38_maven=$(curl -s -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/apache/maven/tags | jq '[ .[] | select(.name | startswith("maven-3.8")) ] | .[0].name' -r | sed 's/maven-//') \
    && wget https://dlcdn.apache.org/maven/maven-3/${latest_38_maven}/binaries/apache-maven-${latest_38_maven}-bin.tar.gz -P /tmp \
    && tar xf /tmp/apache-maven-${latest_38_maven}-bin.tar.gz -C /opt \
    && ln -s /opt/apache-maven-${latest_38_maven}/bin/mvn /usr/bin/mvn \
    && ln -s /usr/bin/cmake3 /usr/local/bin/cmake \
    && ln -s /usr/bin/ctest3 /usr/local/bin/ctest \
    && echo "Compiler: GCC and libatomic toolset" \
    && dnf install -y gcc-toolset-${GCC_VERSION} gcc-toolset-${GCC_VERSION}-libatomic-devel \
    && echo "Compiler: clang" \
    && dnf install -y clang clang-tools-extra \
    && echo "Enable locale required for tests" \
    && dnf install -y langpacks-en glibc-all-langpacks glibc-langpack-en glibc-locale-source \
    && localedef --no-archive -i en_US -f UTF-8 en_US.UTF-8 \
    && echo "Yugabyted-ui: release support" \
    && dnf install -y npm golang \
    && echo "Yugabyted-ui: install patchelf: https://github.com/yugabyte/yugabyte-db/issues/18258" \
    && mkdir -p /tmp/patchelf && cd /tmp/patchelf && git clone https://github.com/NixOS/patchelf.git . \
    && ./bootstrap.sh && ./configure && make && make install \
    && cd - && rm -rf /tmp/patchelf \
    && echo 'Cleanup' \
    && dnf clean all -y

VOLUME /extensions
VOLUME /patches
VOLUME /root/.m2
VOLUME /opt/yb-build
VOLUME /yb-source
VOLUME /yb-build-cache
