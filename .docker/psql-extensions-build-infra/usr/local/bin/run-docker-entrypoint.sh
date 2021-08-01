#!/usr/bin/env bash
docker-entrypoint.sh postgres -c shared_preload_libraries=${POSTGRES_EXTENSIONS}
