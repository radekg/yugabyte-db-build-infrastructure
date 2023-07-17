#!/usr/bin/env bash

usage() {
    echo `basename $0`: ERROR: $* 1>&2
    echo usage: `basename $0` '[ cpp | cxx | java ]' 1>&2
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

if [ -z "$(find $HOME/.m2/repository -name surefire-junit4-2.22.0.jar)" ]; then
    echo "Downloading a required Java dependency (https://github.com/yugabyte/yugabyte-db/issues/9416)"
    mvn dependency:get -Dartifact=org.apache.maven.surefire:surefire-junit4:2.22.0
else
    echo "Java dependencies OK"
fi

cd /yb-source
[ -n "${YB_CONFIGURED_COMPILER_TYPE}" ] && export YB_COMPILER_TYPE=${YB_CONFIGURED_COMPILER_TYPE}
[ -n "${YB_CONFIGURED_COMPILER_ARCH}" ] && export YB_TARGET_ARCH=${YB_CONFIGURED_COMPILER_ARCH}
./yb_build.sh debug --sj # don't build java here, we might not need it

case "${1}" in
    cpp)
        ./yb_build.sh debug --ctest
        ;;
    cxx)
        if [ "$#" -eq 1 ]; then
            usage-cxx
        else
            if [ "$#" -eq 3 ]; then
                ./yb_build.sh debug --cxx-test "${2}" --gtest_filter "${3}"
            else
                ./yb_build.sh debug --cxx-test "${2}"
            fi
        fi
        ;;
    java)
        if [ "$#" -eq 1 ]; then
            shift
            ./yb_build.sh debug "$@" --java-tests
        else
            testpath="${2}"
            shift
            shift
            ./yb_build.sh debug "$@" --java-test "${testpath}"
        fi
        ;;
    raw)
        shift
        ./yb_build.sh debug "$@"
        ;;
    *)
        usage
        ;;
esac
