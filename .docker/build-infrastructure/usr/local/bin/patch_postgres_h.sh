#!/usr/bin/env bash
set -eu
# working directory
pushd /yb-source
# reset the postgres.h file
git checkout -- src/postgres/src/include/postgres.h
# make a copy so patch status can be verified:
cp src/postgres/src/include/postgres.h src/postgres/src/include/postgres.h.bak

# Patch postgres.h, define YUGABYTEDB so extensions can distinguish if they need to
# compile for YugabyteDB or regular Postgres.
echo "#ifndef YUGABYTEDB
#define YUGABYTEDB 1
#endif" >> src/postgres/src/include/postgres.h

# done
echo "Patch status: postgres.h. Changes:"
set +e
diff src/postgres/src/include/postgres.h src/postgres/src/include/postgres.h.bak
if (( $? == 0 || $? > 1)); then
    echo "postgres.h: patch failed!"
    popd
    exit 1
else
    echo "postgres.h: patch succeeded"
    popd
fi
