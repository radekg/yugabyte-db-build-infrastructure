#!/usr/bin/env bash

wait_for_postgres() {
    echo 'Waiting for Postgres...'
    while !</dev/tcp/127.0.0.1/5432; do sleep ${POSTGRES_WAIT_SLEEP_SECS}; done
    echo 'Postgres is running'
}

wait_for_fixtures() {
    echo 'Waiting for Postgres database ready...'
    for (( ; ; )); do
        ## run test fixtures
        psql -U postgres -f ${EXTENSION_WORKDIR}/test/fixtures.sql
        local exit_status=$?
        if [ $exit_status -eq 0 ]; then
            break
        fi
        sleep ${POSTGRES_WAIT_SLEEP_SECS}
    done
    echo 'Applied Postgres fixtures'
}

do_build() {
    cd ${EXTENSION_WORKDIR}
    make
}

do_clean() {
    cd ${EXTENSION_WORKDIR}
    make clean
}

do_run() {
    cd ${EXTENSION_WORKDIR}
    # install the extension
    make clean && make && make install
    # start the database
    supervisord -n -c /etc/supervisor/supervisord-run.conf
}

do_installcheck() {
    cd ${EXTENSION_WORKDIR}
    # install the extension
    make clean && make && make install
    # start the database
    supervisord -c /etc/supervisor/supervisord-installcheck.conf
    # wait for the database to start
    wait_for_postgres

    wait_for_fixtures
    # run the installcheck
    make installcheck
    local exit_status=$?
    if [ $exit_status -ne 0 ]; then
        echo 'ERROR: installcheck failed'
        echo '----------------------------'
        echo 'Postgres instance error log:'
        echo '----------------------------'
        cat /var/log/supervisor/postgres.err
        echo '----------------------------'
        echo 'regression.diffs:'
        echo '----------------------------'
        cat ./regression.diffs
        echo 'regression.out:'
        cat ./regression.out
        echo '----------------------------'
    fi
}

case "$1" in
    build|b)
        do_build
        ;;
    clean|c)
        do_clean
        ;;
    run|s)
        do_run
        ;;
    installcheck|i)
        do_installcheck
        ;;
    *)
        echo "$0: unknown command '$1'"
        exit 1
        ;;
esac