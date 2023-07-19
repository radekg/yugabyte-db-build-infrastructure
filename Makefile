YB_BUILD_INFRASTRUCTURE_DOCKER_TAG?=docker.io/radekg/yugabyte-db-build-infrastructure
YB_BUILD_INFRASTRUCTURE_DOCKER_VER=$(shell git rev-parse --short HEAD)

# GCC version, GCC needs to be installed explicitly
GCC_VERSION=11
empty=

# Set known defaults
USE_COMPILER_TYPE=${empty}
USE_COMPILER_ARCH?=x86_64
USE_DOCKER_VER=${YB_BUILD_INFRASTRUCTURE_DOCKER_VER}

YB_REPOSITORY?=https://github.com/yugabyte/yugabyte-db.git
YB_SOURCE_VERSION?=v2.19.0.0
YB_RELEASE_VERSION?=2.19.0.0

ifeq (${USE_COMPILER_ARCH},${empty})
TEMP_ARCH=default
else
TEMP_ARCH=${USE_COMPILER_ARCH}
endif

ifeq ($(USE_COMPILER_TYPE),${empty})
TEMP_PREFIX=clang-default-${TEMP_ARCH}-${YB_SOURCE_VERSION}
else
TEMP_PREFIX=${USE_COMPILER_TYPE}-${TEMP_ARCH}-${YB_SOURCE_VERSION}
endif

YB_RELEASE_DOCKER_TAG?=local/yugabyte-db
YB_RELEASE_DOCKER_VERSION?=${YB_RELEASE_VERSION}
YB_RELEASE_DOCKER_ARG_GID?=1000
YB_RELEASE_DOCKER_ARG_GROUP?=yb
YB_RELEASE_DOCKER_ARG_UID?=1000
YB_RELEASE_DOCKER_ARG_USER?=yb

YB_POSTGRES_WITH_ICU?=true

YB_COMPOSE_SHARED_PRELOAD_LIBRARIES?=${empty}

CURRENT_DIR=$(dir $(realpath $(firstword $(MAKEFILE_LIST))))
PLATFORM=$(shell uname -s)

.PHONY: ybdb-build-infrastructure
ybdb-build-infrastructure:
	cd ${CURRENT_DIR}/.docker/build-infrastructure \
		&& docker buildx build --no-cache \
			--build-arg BUILD_PLATFORM=linux/amd64 \
			--build-arg ALMALINUX_VERSION=8.8 \
			--build-arg GCC_VERSION=${GCC_VERSION} \
			--platform linux/amd64 \
			-t ${YB_BUILD_INFRASTRUCTURE_DOCKER_TAG}:${YB_BUILD_INFRASTRUCTURE_DOCKER_VER} . \
		&& docker tag ${YB_BUILD_INFRASTRUCTURE_DOCKER_TAG}:${YB_BUILD_INFRASTRUCTURE_DOCKER_VER} \
			${YB_BUILD_INFRASTRUCTURE_DOCKER_TAG}:latest

# First pass build:
# -----------------

.PHONY: ybdb-build-first-pass-clang
ybdb-build-first-pass-clang:
# Use the default clang version available in the build infrastructure:
	$(MAKE) ybdb-build-first-pass

.PHONY: ybdb-build-first-pass-gcc
ybdb-build-first-pass-gcc:
	$(MAKE) USE_COMPILER_TYPE=gcc${GCC_VERSION} ybdb-build-first-pass

.PHONY: ybdb-build-first-pass
ybdb-build-first-pass:
ifeq ($(PLATFORM),Linux)
	sudo rm -rf ${CURRENT_DIR}/.tmp/${TEMP_PREFIX}/yb-build \
		&& sudo rm -rf ${CURRENT_DIR}/.tmp/${TEMP_PREFIX}/yb-source \
		&& sudo rm -rf ${CURRENT_DIR}/.tmp/${TEMP_PREFIX}/yb-build-cache
else
	rm -rf ${CURRENT_DIR}/.tmp/${TEMP_PREFIX}/yb-build \
		&& rm -rf ${CURRENT_DIR}/.tmp/${TEMP_PREFIX}/yb-source \
		&& rm -rf ${CURRENT_DIR}/.tmp/${TEMP_PREFIX}/yb-build-cache
endif
	mkdir -p ${CURRENT_DIR}/.tmp/${TEMP_PREFIX}/yb-build \
		&& mkdir -p ${CURRENT_DIR}/.tmp/yb-maven \
		&& mkdir -p ${CURRENT_DIR}/.tmp/${TEMP_PREFIX}/yb-source \
		&& mkdir -p ${CURRENT_DIR}/.tmp/${TEMP_PREFIX}/extensions \
		&& mkdir -p ${CURRENT_DIR}/.tmp/${TEMP_PREFIX}/yb-build-cache \
		&& docker run --rm -ti \
			--platform linux/amd64 \
			-e YB_REPOSITORY=${YB_REPOSITORY} \
			-e YB_SOURCE_VERSION=${YB_SOURCE_VERSION} \
			-e YB_POSTGRES_WITH_ICU=${YB_POSTGRES_WITH_ICU} \
			-e YB_CONFIGURED_COMPILER_TYPE=${USE_COMPILER_TYPE} \
			-e YB_CONFIGURED_COMPILER_ARCH=${USE_COMPILER_ARCH} \
			-e YB_CCACHE_DIR=/yb-build-cache \
			-e LANG=en_US.UTF-8 \
			-v ${CURRENT_DIR}/.tmp/yb-maven:/root/.m2 \
			-v ${CURRENT_DIR}/.tmp/${TEMP_PREFIX}/yb-build:/opt/yb-build \
			-v ${CURRENT_DIR}/.tmp/${TEMP_PREFIX}/yb-source:/yb-source \
			-v ${CURRENT_DIR}/.tmp/${TEMP_PREFIX}/yb-build-cache:/yb-build-cache \
			-v ${CURRENT_DIR}/.tmp/${TEMP_PREFIX}/extensions:/extensions \
			${YB_BUILD_INFRASTRUCTURE_DOCKER_TAG}:${USE_DOCKER_VER} yb-first-pass-build.sh

# Build infrastructure shell:
# ---------------------------

.PHONY: ybdb-infrastructure-shell-clang
ybdb-infrastructure-shell-clang:
	$(MAKE) ybdb-infrastructure-shell

.PHONY: ybdb-infrastructure-shell-gcc
ybdb-infrastructure-shell-gcc:
	$(MAKE) USE_COMPILER_TYPE=gcc${GCC_VERSION} ybdb-infrastructure-shell

.PHONY: ybdb-infrastructure-shell
ybdb-infrastructure-shell:
	docker run --rm -ti \
		--platform linux/amd64 \
		-e YB_REPOSITORY=${YB_REPOSITORY} \
		-e YB_SOURCE_VERSION=${YB_SOURCE_VERSION} \
		-e YB_POSTGRES_WITH_ICU=${YB_POSTGRES_WITH_ICU} \
		-e YB_CONFIGURED_COMPILER_TYPE=${USE_COMPILER_TYPE} \
		-e YB_CONFIGURED_COMPILER_ARCH=${USE_COMPILER_ARCH} \
		-e YB_CCACHE_DIR=/yb-build-cache \
		-e LANG=en_US.UTF-8 \
		-v ${CURRENT_DIR}/.docker/build-infrastructure/patches:/patches \
		-v ${CURRENT_DIR}/.tmp/yb-maven:/root/.m2 \
		-v ${CURRENT_DIR}/.tmp/${TEMP_PREFIX}/yb-build:/opt/yb-build \
		-v ${CURRENT_DIR}/.tmp/${TEMP_PREFIX}/yb-source:/yb-source \
		-v ${CURRENT_DIR}/.tmp/${TEMP_PREFIX}/yb-build-cache:/yb-build-cache \
		-v ${CURRENT_DIR}/.tmp/${TEMP_PREFIX}/extensions:/extensions \
		${YB_BUILD_INFRASTRUCTURE_DOCKER_TAG}:${USE_DOCKER_VER} /bin/bash

# Rebuild extensions:
# -------------------

.PHONY: ybdb-rebuild-extensions-clang
ybdb-rebuild-extensions-clang:
# Use the default clang version available in the build infrastructure:
	$(MAKE) ybdb-rebuild-extensions

.PHONY: ybdb-rebuild-extensions-gcc
ybdb-rebuild-extensions-gcc:
	$(MAKE) USE_COMPILER_TYPE=gcc${GCC_VERSION} ybdb-rebuild-extensions

.PHONY: ybdb-rebuild-extensions
ybdb-rebuild-extensions:
	docker run --rm -ti \
		--platform linux/amd64 \
		-e YB_SOURCE_VERSION=${YB_SOURCE_VERSION} \
		-e YB_POSTGRES_WITH_ICU=${YB_POSTGRES_WITH_ICU} \
		-e YB_CONFIGURED_COMPILER_TYPE=${USE_COMPILER_TYPE} \
		-e YB_CONFIGURED_COMPILER_ARCH=${USE_COMPILER_ARCH} \
		-e YB_CCACHE_DIR=/yb-build-cache \
		-e LANG=en_US.UTF-8 \
		-v ${CURRENT_DIR}/.docker/build-infrastructure/patches:/patches \
		-v ${CURRENT_DIR}/.tmp/yb-maven:/root/.m2 \
		-v ${CURRENT_DIR}/.tmp/${TEMP_PREFIX}/yb-build:/opt/yb-build \
		-v ${CURRENT_DIR}/.tmp/${TEMP_PREFIX}/yb-source:/yb-source \
		-v ${CURRENT_DIR}/.tmp/${TEMP_PREFIX}/yb-build-cache:/yb-build-cache \
		-v ${CURRENT_DIR}/.tmp/${TEMP_PREFIX}/extensions:/extensions \
		${YB_BUILD_INFRASTRUCTURE_DOCKER_TAG}:${USE_DOCKER_VER} yb-rebuild-extensions.sh

# Rebuild:
# --------

.PHONY: ybdb-rebuild-clang
ybdb-rebuild-clang:
# Use the default clang version available in the build infrastructure:
	$(MAKE) ybdb-rebuild

.PHONY: ybdb-rebuild-gcc
ybdb-rebuild-gcc:
	$(MAKE) USE_COMPILER_TYPE=gcc${GCC_VERSION} ybdb-rebuild

.PHONY: ybdb-rebuild
ybdb-rebuild:
	docker run --rm -ti \
		--platform linux/amd64 \
		-e YB_SOURCE_VERSION=${YB_SOURCE_VERSION} \
		-e YB_POSTGRES_WITH_ICU=${YB_POSTGRES_WITH_ICU} \
		-e YB_CONFIGURED_COMPILER_TYPE=${USE_COMPILER_TYPE} \
		-e YB_CONFIGURED_COMPILER_ARCH=${USE_COMPILER_ARCH} \
		-e YB_CCACHE_DIR=/yb-build-cache \
		-e LANG=en_US.UTF-8 \
		-v ${CURRENT_DIR}/.docker/build-infrastructure/patches:/patches \
		-v ${CURRENT_DIR}/.tmp/yb-maven:/root/.m2 \
		-v ${CURRENT_DIR}/.tmp/${TEMP_PREFIX}/yb-build:/opt/yb-build \
		-v ${CURRENT_DIR}/.tmp/${TEMP_PREFIX}/yb-source:/yb-source \
		-v ${CURRENT_DIR}/.tmp/${TEMP_PREFIX}/yb-build-cache:/yb-build-cache \
		-v ${CURRENT_DIR}/.tmp/${TEMP_PREFIX}/extensions:/extensions \
		${YB_BUILD_INFRASTRUCTURE_DOCKER_TAG}:${USE_DOCKER_VER} yb-rebuild.sh

# Build a distribution:
# ---------------------

.PHONY: ybdb-distribution-clang
ybdb-distribution-clang:
# Use the default clang version available in the build infrastructure:
	$(MAKE) ybdb-distribution

.PHONY: ybdb-distribution-gcc
ybdb-distribution-gcc:
	$(MAKE) USE_COMPILER_TYPE=gcc${GCC_VERSION} ybdb-distribution

.PHONY: ybdb-distribution
ybdb-distribution:
	docker run --rm -ti \
		--platform linux/amd64 \
		-e YB_RELEASE_VERSION=${YB_RELEASE_VERSION} \
		-e YB_CONFIGURED_COMPILER_TYPE=${USE_COMPILER_TYPE} \
		-e YB_CONFIGURED_COMPILER_ARCH=${USE_COMPILER_ARCH} \
		-e YB_CCACHE_DIR=/yb-build-cache \
		-e LANG=en_US.UTF-8 \
		-v ${CURRENT_DIR}/.docker/build-infrastructure/patches:/patches \
		-v ${CURRENT_DIR}/.tmp/yb-maven:/root/.m2 \
		-v ${CURRENT_DIR}/.tmp/${TEMP_PREFIX}/yb-build:/opt/yb-build \
		-v ${CURRENT_DIR}/.tmp/${TEMP_PREFIX}/yb-source:/yb-source \
		-v ${CURRENT_DIR}/.tmp/${TEMP_PREFIX}/yb-build-cache:/yb-build-cache \
		-v ${CURRENT_DIR}/.tmp/${TEMP_PREFIX}/extensions:/extensions \
		${YB_BUILD_INFRASTRUCTURE_DOCKER_TAG}:${USE_DOCKER_VER} yb-release.sh

# Build Docker image from a distribution:
# ---------------------------------------

.PHONY: ybdb-build-docker
ybdb-build-docker:
ifeq ($(PLATFORM),Linux)
	sudo chmod 0644 ${CURRENT_DIR}/.tmp/${TEMP_PREFIX}/yb-source/build/yugabyte-*.tar.gz
endif
	mkdir -p ${CURRENT_DIR}/.tmp/${TEMP_PREFIX}/yb-docker-build \
		&& cp -v ${CURRENT_DIR}/.tmp/${TEMP_PREFIX}/yb-source/build/yugabyte-*.tar.gz ${CURRENT_DIR}/.tmp/${TEMP_PREFIX}/yb-docker-build/ \
		&& cp -v ${CURRENT_DIR}/.docker/yugabyte-db/Dockerfile ${CURRENT_DIR}/.tmp/${TEMP_PREFIX}/yb-docker-build/ \
		&& cd ${CURRENT_DIR}/.tmp/${TEMP_PREFIX}/yb-docker-build/ \
		&& docker buildx build \
			--platform linux/amd64 \
			--build-arg GID=${YB_RELEASE_DOCKER_ARG_GID} \
			--build-arg GROUPNAME=${YB_RELEASE_DOCKER_ARG_GROUP} \
			--build-arg UID=${YB_RELEASE_DOCKER_ARG_UID} \
			--build-arg USERNAME=${YB_RELEASE_DOCKER_ARG_USER} \
			--build-arg YB_RELEASE_VERSION=${YB_RELEASE_VERSION} \
			--build-arg YB_SOURCE_VERSION=${YB_SOURCE_VERSION} \
			--build-arg YB_REPOSITORY=${YB_REPOSITORY} \
			-t ${YB_RELEASE_DOCKER_TAG}:${YB_RELEASE_DOCKER_VERSION} .

# Test runner:
# ------------

.PHONY: ybdb-tests-clang
ybdb-tests-clang:
# Use the default clang version available in the build infrastructure:
	$(MAKE) ybdb-tests

.PHONY: ybdb-tests-gcc
ybdb-tests-gcc:
	$(MAKE) USE_COMPILER_TYPE=gcc${GCC_VERSION} ybdb-tests

.PHONY: ybdb-tests
ybdb-tests:
	docker run --rm -ti \
		--platform linux/amd64 \
		--cap-add=SYS_PTRACE \
		-p "5433:5433" \
		-e YB_CONFIGURED_COMPILER_TYPE=${USE_COMPILER_TYPE} \
		-e YB_CONFIGURED_COMPILER_ARCH=${USE_COMPILER_ARCH} \
		-e YB_CCACHE_DIR=/yb-build-cache \
		-e LANG=en_US.UTF-8 \
		-v ${CURRENT_DIR}/.tmp/yb-maven:/root/.m2 \
		-v ${CURRENT_DIR}/.tmp/${TEMP_PREFIX}/yb-build:/opt/yb-build \
		-v ${CURRENT_DIR}/.tmp/${TEMP_PREFIX}/yb-source:/yb-source \
		-v ${CURRENT_DIR}/.tmp/${TEMP_PREFIX}/yb-build-cache:/yb-build-cache \
		${YB_BUILD_INFRASTRUCTURE_DOCKER_TAG}:${USE_DOCKER_VER} /bin/bash -c 'yb-tests.sh; /bin/bash'
