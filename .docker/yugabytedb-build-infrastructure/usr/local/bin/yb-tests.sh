#!/usr/bin/env bash

usage() {
    echo `basename $0`: ERROR: $* 1>&2
    echo usage: `basename $0` '[cpp | cxx | java-all | java | ysql-java]' 1>&2
    exit 1
}

usage-cxx() {
    echo `basename $0`: ERROR: $* 1>&2
    echo usage: `basename $0` 'cxx test-name [sub-test]' 1>&2
    exit 1
}

usage-java() {
    echo `basename $0`: ERROR: $* 1>&2
    echo usage: `basename $0` 'java test.Class[#selectedTest]' 1>&2
    exit 1
}

usage-java() {
    echo `basename $0`: ERROR: $* 1>&2
    echo usage: `basename $0` 'java test.Class[#selectedTest]' 1>&2
    exit 1
}

usage-ysql-java() {
    echo `basename $0`: ERROR: $* 1>&2
    echo usage: `basename $0` 'java test.Class' 1>&2
    exit 1
}

case "${1}" in
    cpp)
        /yb-source/yb_build.sh release --ctest
        ;;
    cxx)
        if [ "$#" -eq 1 ]; then
            usage-cxx
        else
            if [ "$#" -eq 3 ]; then
                /yb-source/yb_build.sh release --cxx-test "${2}" --gtest_filter "${3}"
            else
                /yb-source/yb_build.sh release --cxx-test "${2}"
            fi
        fi
        ;;
    java-all)
        cd /yb-source
        ./yb_build.sh release --sj --java-tests
        ;;
    java)
        if [ "$#" -eq 1 ]; then
            usage-java
        else
            cd /yb-source
            ./yb_build.sh release --sj --java-test "${2}"
        fi
        ;;
    ysql-java)
        if [ "$#" -eq 1 ]; then
            usage-ysql-java
        else
            cd /yb-source
            ./yb_build.sh --java-test "${2}"
        fi
        ;;
    *)
        usage
        ;;
esac