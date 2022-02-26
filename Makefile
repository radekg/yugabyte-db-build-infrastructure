YB_BUILD_INFRASTRUCTURE_DOCKER_TAG?=local/yugabyte-db-build-infrastructure

# clang build infrastructure
YB_BUILD_INFRASTRUCTURE_CLANG_TAG?=clang
YB_BUILD_INFRASTRUCTURE_CLANG_VERSION?=12

# GCC build infrastructure
YB_BUILD_INFRASTRUCTURE_GCC_TAG?=gcc
YB_BUILD_INFRASTRUCTURE_GCC_VERSION?=9.4.0
YB_BUILD_INFRASTRUCTURE_GCC_MAKE_PARALLELISM?=32

# By default, use clang-12 build 
USE_BUILD_INFRASTRUCTURE?=clang12

YB_REPOSITORY?=https://github.com/yugabyte/yugabyte-db.git
YB_SOURCE_VERSION?=v2.11.2

YB_RELEASE_VERSION?=2.11.2.0

YB_RELEASE_DOCKER_TAG?=local/yugabyte-db
YB_RELEASE_DOCKER_VERSION?=${YB_RELEASE_VERSION}
YB_RELEASE_DOCKER_ARG_GID?=1000
YB_RELEASE_DOCKER_ARG_GROUP?=yb
YB_RELEASE_DOCKER_ARG_UID?=1000
YB_RELEASE_DOCKER_ARG_USER?=yb

YB_POSTGRES_WITH_ICU?=true

empty=
YB_COMPOSE_SHARED_PRELOAD_LIBRARIES?=${empty}

CURRENT_DIR=$(dir $(realpath $(firstword $(MAKEFILE_LIST))))
PLATFORM=$(shell uname -s)

.PHONY: ybdb-build-infrastructure-clang
ybdb-build-infrastructure-clang:
	cd ${CURRENT_DIR}/.docker/build-infrastructure-clang \
		&& docker build --no-cache \
			-t ${YB_BUILD_INFRASTRUCTURE_DOCKER_TAG}:${YB_BUILD_INFRASTRUCTURE_CLANG_TAG}${YB_BUILD_INFRASTRUCTURE_CLANG_VERSION} . \
		&& docker tag ${YB_BUILD_INFRASTRUCTURE_DOCKER_TAG}:${YB_BUILD_INFRASTRUCTURE_CLANG_TAG}${YB_BUILD_INFRASTRUCTURE_CLANG_VERSION} \
					  ${YB_BUILD_INFRASTRUCTURE_DOCKER_TAG}:${YB_BUILD_INFRASTRUCTURE_CLANG_TAG}-latest

.PHONY: ybdb-build-infrastructure-gcc
ybdb-build-infrastructure-gcc:
	cd ${CURRENT_DIR}/.docker/build-infrastructure-gcc \
		&& docker build --no-cache \
			--build-arg GCC_VERSION=${YB_BUILD_INFRASTRUCTURE_GCC_VERSION} \
			--build-arg GCC_MAKE_PARALLELISM=${YB_BUILD_INFRASTRUCTURE_GCC_MAKE_PARALLELISM} \
			-t ${YB_BUILD_INFRASTRUCTURE_DOCKER_TAG}:${YB_BUILD_INFRASTRUCTURE_GCC_TAG}${YB_BUILD_INFRASTRUCTURE_GCC_VERSION} . \
		&& docker tag ${YB_BUILD_INFRASTRUCTURE_DOCKER_TAG}:${YB_BUILD_INFRASTRUCTURE_GCC_TAG}${YB_BUILD_INFRASTRUCTURE_GCC_VERSION} \
					  ${YB_BUILD_INFRASTRUCTURE_DOCKER_TAG}:${YB_BUILD_INFRASTRUCTURE_GCC_TAG}-latest

.PHONY: ybdb-build-first-pass
ybdb-build-first-pass:
ifeq ($(PLATFORM),Linux)
	sudo rm -rf ${CURRENT_DIR}/.tmp/yb-build \
		&& sudo rm -rf ${CURRENT_DIR}/.tmp/yb-maven \
		&& sudo rm -rf ${CURRENT_DIR}/.tmp/yb-source
else
	rm -rf ${CURRENT_DIR}/.tmp/yb-build \
		&& sudo rm -rf ${CURRENT_DIR}/.tmp/yb-maven \
		&& sudo rm -rf ${CURRENT_DIR}/.tmp/yb-source
endif
	mkdir -p ${CURRENT_DIR}/.tmp/yb-build \
		&& mkdir -p ${CURRENT_DIR}/.tmp/yb-maven \
		&& mkdir -p ${CURRENT_DIR}/.tmp/yb-source \
		&& mkdir -p ${CURRENT_DIR}/.tmp/extensions \
		&& docker run --rm -ti \
			-e YB_REPOSITORY=${YB_REPOSITORY} \
			-e YB_SOURCE_VERSION=${YB_SOURCE_VERSION} \
			-e YB_POSTGRES_WITH_ICU=${YB_POSTGRES_WITH_ICU} \
			-v ${CURRENT_DIR}/.tmp/yb-maven:/root/.m2 \
			-v ${CURRENT_DIR}/.tmp/yb-build:/opt/yb-build \
			-v ${CURRENT_DIR}/.tmp/yb-source:/yb-source \
			-v ${CURRENT_DIR}/.tmp/extensions:/extensions \
			${YB_BUILD_INFRASTRUCTURE_DOCKER_TAG}:${USE_BUILD_INFRASTRUCTURE} yb-first-pass-build.sh

.PHONY: ybdb-rebuild-extensions
ybdb-rebuild-extensions:
	docker run --rm -ti \
		-e YB_SOURCE_VERSION=${YB_SOURCE_VERSION} \
		-e YB_POSTGRES_WITH_ICU=${YB_POSTGRES_WITH_ICU} \
		-v ${CURRENT_DIR}/.tmp/yb-maven:/root/.m2 \
		-v ${CURRENT_DIR}/.tmp/yb-build:/opt/yb-build \
		-v ${CURRENT_DIR}/.tmp/yb-source:/yb-source \
		-v ${CURRENT_DIR}/.tmp/extensions:/extensions \
		${YB_BUILD_INFRASTRUCTURE_DOCKER_TAG}:${USE_BUILD_INFRASTRUCTURE} yb-rebuild-extensions.sh

.PHONY: ybdb-rebuild
ybdb-rebuild:
	docker run --rm -ti \
		-e YB_SOURCE_VERSION=${YB_SOURCE_VERSION} \
		-e YB_POSTGRES_WITH_ICU=${YB_POSTGRES_WITH_ICU} \
		-v ${CURRENT_DIR}/.tmp/yb-maven:/root/.m2 \
		-v ${CURRENT_DIR}/.tmp/yb-build:/opt/yb-build \
		-v ${CURRENT_DIR}/.tmp/yb-source:/yb-source \
		-v ${CURRENT_DIR}/.tmp/extensions:/extensions \
		${YB_BUILD_INFRASTRUCTURE_DOCKER_TAG}:${USE_BUILD_INFRASTRUCTURE} yb-rebuild.sh

.PHONY: ybdb-distribution
ybdb-distribution:
	docker run --rm -ti \
		-e YB_RELEASE_VERSION=${YB_RELEASE_VERSION} \
		-v ${CURRENT_DIR}/.tmp/yb-maven:/root/.m2 \
		-v ${CURRENT_DIR}/.tmp/yb-build:/opt/yb-build \
		-v ${CURRENT_DIR}/.tmp/yb-source:/yb-source \
		-v ${CURRENT_DIR}/.tmp/extensions:/extensions \
		${YB_BUILD_INFRASTRUCTURE_DOCKER_TAG}:${USE_BUILD_INFRASTRUCTURE} yb-release.sh

.PHONY: ybdb-build-docker
ybdb-build-docker:
ifeq ($(PLATFORM),Linux)
	sudo chmod 0644 ${CURRENT_DIR}/.tmp/yb-source/build/yugabyte-*.tar.gz
endif
	mkdir -p ${CURRENT_DIR}/.tmp/yb-docker-build \
		&& cp -v ${CURRENT_DIR}/.tmp/yb-source/build/yugabyte-*.tar.gz ${CURRENT_DIR}/.tmp/yb-docker-build/ \
		&& cp -v ${CURRENT_DIR}/.docker/yugabyte-db/Dockerfile ${CURRENT_DIR}/.tmp/yb-docker-build/ \
		&& cd ${CURRENT_DIR}/.tmp/yb-docker-build/ \
		&& docker build \
			--build-arg GID=${YB_RELEASE_DOCKER_ARG_GID} \
			--build-arg GROUPNAME=${YB_RELEASE_DOCKER_ARG_GROUP} \
			--build-arg UID=${YB_RELEASE_DOCKER_ARG_UID} \
			--build-arg USERNAME=${YB_RELEASE_DOCKER_ARG_USER} \
			--build-arg YB_RELEASE_VERSION=${YB_RELEASE_VERSION} \
			--build-arg YB_SOURCE_VERSION=${YB_SOURCE_VERSION} \
			--build-arg YB_REPOSITORY=${YB_REPOSITORY} \
			-t ${YB_RELEASE_DOCKER_TAG}:${YB_RELEASE_DOCKER_VERSION} .

.PHONY: ybdb-tests
ybdb-tests:
	docker run --rm -ti \
		--cap-add=SYS_PTRACE \
		-p "5433:5433" \
		-v ${CURRENT_DIR}/.tmp/yb-maven:/root/.m2 \
		-v ${CURRENT_DIR}/.tmp/yb-build:/opt/yb-build \
		-v ${CURRENT_DIR}/.tmp/yb-source:/yb-source \
		${YB_BUILD_INFRASTRUCTURE_DOCKER_TAG}:${USE_BUILD_INFRASTRUCTURE} /bin/bash -c 'yb-tests.sh; /bin/bash'
