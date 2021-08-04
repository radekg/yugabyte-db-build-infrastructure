EXTENSION = example
DATA = $(wildcard sql/*--*.sql)

MODULE_big = example
OBJS = src/example.o
YB_VERSION=2.7.2.0-b216

TESTS = $(wildcard test/sql/*.sql)
REGRESS = $(patsubst test/sql/%.sql,%,$(TESTS))
REGRESS_OPTS = --use-existing --inputdir=test

# Tell pg_config to pass us the PostgreSQL extensions makefile(PGXS)
# and include it into our own Makefile through the standard "include" directive.
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

# Custom targets:
CURRENT_DIR=$(dir $(realpath $(firstword $(MAKEFILE_LIST))))

.PHONY: ext-infra
ext-infra:
	cd ${CURRENT_DIR}/.docker/psql-extensions-build-infra \
		&& docker build -t postgres-extensions-builder:11.2 .

.PHONY: ext-clean
ext-clean:
	docker run --rm \
		-v ${CURRENT_DIR}:/extension \
		-e POSTGRES_PASSWORD=ext-builder \
		-ti postgres-extensions-builder:11.2 clean

.PHONY: ext-build
ext-build:
	docker run --rm \
		-v ${CURRENT_DIR}:/extension \
		-e POSTGRES_PASSWORD=ext-builder \
		-ti postgres-extensions-builder:11.2 build

.PHONY: ext-run-postgres
ext-run-postgres:
	docker run --rm \
		-v ${CURRENT_DIR}:/extension \
		-e POSTGRES_PASSWORD=ext-builder \
		-p 5432:5432 \
		-ti postgres-extensions-builder:11.2 run

.PHONY: ext-installcheck
ext-installcheck:
	docker run --rm \
		-v ${CURRENT_DIR}:/extension \
		-e POSTGRES_PASSWORD=ext-builder \
		-ti postgres-extensions-builder:11.2 installcheck

.PHONY: extension-example-prepare
extension-example-prepare:
	mkdir -p ${CURRENT_DIR}/.docker/yugabytedb-with-extensions/extensions/example/extension
	cp ${CURRENT_DIR}/example.so ${CURRENT_DIR}/.docker/yugabytedb-with-extensions/extensions/example/
	cp ${CURRENT_DIR}/example.control ${CURRENT_DIR}/.docker/yugabytedb-with-extensions/extensions/example/extension/
	cp ${CURRENT_DIR}/sql/*.sql ${CURRENT_DIR}/.docker/yugabytedb-with-extensions/extensions/example/extension/

.PHONY: ybdb-build-infrastructure
ybdb-build-infrastructure:
	cd ${CURRENT_DIR}/.docker/yugabytedb-build-infrastructure \
		&& docker build --no-cache --progress=plain -t local/yb-builder-toolchain:latest .

.PHONY: ybdb-build-first-pass
ybdb-build-first-pass:
	rm -rf ${CURRENT_DIR}/.tmp/yb-build \
		&& rm -rf ${CURRENT_DIR}/.tmp/yb-maven \
		&& rm -rf ${CURRENT_DIR}/.tmp/yb-source \
		&& mkdir -p ${CURRENT_DIR}/.tmp/yb-build \
		&& mkdir -p ${CURRENT_DIR}/.tmp/yb-maven \
		&& mkdir -p ${CURRENT_DIR}/.tmp/yb-source \
		&& mkdir -p ${CURRENT_DIR}/.tmp/extensions \
		&& docker run --rm -ti \
			-v ${CURRENT_DIR}/.tmp/yb-maven:/root/.m2 \
    		-v ${CURRENT_DIR}/.tmp/yb-build:/opt/yb-build \
    		-v ${CURRENT_DIR}/.tmp/yb-source:/yb-source \
			-v ${CURRENT_DIR}/.tmp/extensions:/extensions \
    		local/yb-builder-toolchain:latest yb-first-pass-build.sh

.PHONY: ybdb-base
ybdb-base: ext-build extension-example-prepare
	cd ${CURRENT_DIR}/.docker/yugabytedb-with-extensions \
		&& docker build --no-cache --progress=plain --build-arg YB_VERSION=${YB_VERSION} -t local/yugabytedb:${YB_VERSION} .

.PHONY: ybdb-base-nobuild
ybdb-base-nobuild: extension-example-prepare
	cd ${CURRENT_DIR}/.docker/yugabytedb-with-extensions \
		&& docker build --no-cache --progress=plain --build-arg YB_VERSION=${YB_VERSION} -t local/yugabytedb:${YB_VERSION} .

.PHONY: yb-start-masters
yb-start-masters:
	cd ${CURRENT_DIR}/.compose-yb && docker compose -f compose-masters.yaml up

.PHONY: yb-start-tservers
yb-start-tservers:
	cd ${CURRENT_DIR}/.compose-yb && docker compose -f compose-tservers.yaml up

.PHONY: yb-start-traefik
yb-start-traefik:
	cd ${CURRENT_DIR}/.compose-yb && docker compose -f compose-traefik.yaml up

.PHONY: yb-compose-clean
yb-compose-clean:
	cd ${CURRENT_DIR}/.compose-yb \
		&& docker compose -f compose-traefik.yaml -f compose-tservers.yaml -f compose-traefik.yaml rm