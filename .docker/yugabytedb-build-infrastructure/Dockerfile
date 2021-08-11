# 
# YugabyteDB build steps from:
# https://docs.yugabyte.com/latest/contribute/core-database/build-from-src-centos/
# 
FROM centos:7.9.2009

ARG GCC_VERSION=7.3.0
ARG GCC_MAKE_PARALLELISM=32

COPY usr/local/bin/yb-first-pass-build.sh /usr/local/bin/yb-first-pass-build.sh
COPY usr/local/bin/yb-rebuild.sh /usr/local/bin/yb-rebuild.sh
COPY usr/local/bin/yb-release.sh /usr/local/bin/yb-release.sh
COPY usr/local/bin/yb-tests.sh /usr/local/bin/yb-tests.sh

RUN chmod +x /usr/local/bin/yb-first-pass-build.sh \
    && chmod +x /usr/local/bin/yb-rebuild.sh \
    && chmod +x /usr/local/bin/yb-release.sh \
    && chmod +x /usr/local/bin/yb-tests.sh \
    && echo 'YugabyteDB build tooling' \
    && yum -y update \
    && yum -y groupinstall 'Development Tools' \
    && yum install -y ruby perl-Digest epel-release ccache git python2-pip python-devel python3 python3-pip python3-devel which \
    && yum install -y cmake3 ctest3 ninja-build \
    && yum install -y git \
    && yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel \
    && wget https://mirror.netcologne.de/apache.org/maven/maven-3/3.8.1/binaries/apache-maven-3.8.1-bin.tar.gz -P /tmp \
    && tar xf /tmp/apache-maven-3.8.1-bin.tar.gz -C /opt \
    && ln -sfT /opt/apache-maven-3.8.1/bin/mvn /usr/bin/mvn \
    && ln -s /usr/bin/cmake3 /usr/local/bin/cmake \
    && ln -s /usr/bin/ctest3 /usr/local/bin/ctest \
    && echo 'Updated GCC for building extensions later on' \
    && yum install -y wget bzip2 \
    && cd /tmp \
    && wget http://ftp.mirrorservice.org/sites/sourceware.org/pub/gcc/releases/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.gz \
    && tar zxf gcc-${GCC_VERSION}.tar.gz \
    && cd gcc-${GCC_VERSION} \
    && ./contrib/download_prerequisites \
    && ./configure --disable-multilib --enable-languages=c,c++ \
    && make -j ${GCC_MAKE_PARALLELISM} \
    && make install \
    && echo 'Cleanup' \
    && yum clean all -y \
    && rm -rf /tmp/gcc-${GCC_VERSION}

VOLUME /root/.m2
VOLUME /opt/yb-build
VOLUME /yb-source