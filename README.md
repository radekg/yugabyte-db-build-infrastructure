# YugabyteDB build infrastructure

Build YugabyteDB Docker image from sources, optionally embed additional extensions.

Original build instructions:

- [Extensions requiring installation](https://docs.yugabyte.com/latest/api/ysql/extensions/#extensions-requiring-installation)

## Build infrastructure

There are two build infrastructure versions:

- the clang-based version is preferred for YugabyteDB `v2.11.2` and higher (used by default)
- the GCC-based version is preferred for versions lower than `v2.11.2`

### clang version

```sh
make ybdb-build-infrastructure-clang
```

### GCC version

```sh
make ybdb-build-infrastructure-gcc
```

Configuration:

- `YB_BUILD_INFRASTRUCTURE_GCC_VERSION`: gcc version to install in the image, default `9.4.0`, used for Docker image tag version
- `YB_BUILD_INFRASTRUCTURE_GCC_PARALLELISM`: the `-j` value for gcc `make`, default `32`

## Build YugabyteDB using the infrastructure

All commands below use the pre-built build infrastructure Docker image. Depending on the YugabyteDB version you are working with, prepare the relevant build infrastructure Docker image first. When using `clang12` infrasrtructure, no additional configuration is needed.

When using the GCC-based version, add `USE_BUILD_INFRASTRUCTURE=gcc9.4.0` to your `make` calls, for example:

```sh
make USE_BUILD_INFRASTRUCTURE=gcc9.4.0 \
  YB_SOURCE_VERSION=v2.11.1 \
  ybdb-build-first-pass
```

### First pass build

This target will download the sources from the request repository, check out the requested version and execute a first pass build.

```sh
make ybdb-build-first-pass
```

There are following configuration options available for this target:

- `YB_REPOSITORY`: YugabyteDB source repository to use, default `https://github.com/yugabyte/yugabyte-db.git`
- `YB_SOURCE_VERSION`: YugabyteDB source code version: commit hash, branch name or tag name, default `v2.11.2`

### Rebuild

Recompile YugabyteDB.

```sh
make ybdb-rebuild
```

### Rebuild third-party extensions

Regular rebuild process does not rebuild third-party extensions. To rebuild third-party extensions, run:

```sh
make ybdb-rebuild-extensions
```

This commang implies `clean`, in effect - it's a new build.

### Create a release distribution

This target creates a distribution _tar.gz_ archive from the previous first pass or rebuild result.

```sh
make ybdb-distribution
```

There are following configuration options available for this target:

- `YB_RELEASE_VERSION`: YugabyteDB release version - used for the tar.gz file name, default `2.11.2.0` results in the `yugabyte-2.11.2.0.tar.gz` archive name

### Create the Docker image

This target creates a Docker image using the previously built distribution:

```sh
make ybdb-build-docker
```

There are following configuration options available for this target:

- `YB_RELEASE_DOCKER_ARG_GID`: Docker image gid, default `1000`
- `YB_RELEASE_DOCKER_ARG_UID`: Docker image uid, default `1000`
- `YB_RELEASE_DOCKER_ARG_GROUP`: gid group name in the container, default `yb`
- `YB_RELEASE_DOCKER_ARG_USER`: uid user name in the container, default `yb`
- `YB_RELEASE_VERSION`: must match the version used in `make ybdb-build-docker`
- `YB_RELEASE_DOCKER_TAG`: resulting Docker image tag name, default `local/yugabyte-db`
- `YB_RELEASE_DOCKER_VERSION`: resulting Docker image version, default the value of `YB_RELEASE_VERSION`

- `YB_REPOSITORY`: used as the image label: YugabyteDB source repository to use, default `https://github.com/yugabyte/yugabyte-db.git`
- `YB_SOURCE_VERSION`: used as the image label: YugabyteDB source code version: commit hash, branch name or tag name, default `v2.11.2`

### Running YugabyteDB tests

```sh
make ybdb-tests
```

This will put YugabyteDB sources in the `debug` mode to give more decent tests output. Once you have the shell available, you can run tests like this:

```sh
# all C++ tests, this may take a long time:
yb-tests.sh cpp
# selected C++ test:
yb-tests.sh cxx test [ subtest ]
# all Java tests
yb-tests.sh java
# selected Java test:
yb-tests.sh java test.Class[\#testCase]
# Raw command, passes all options to the test runner, example:
yb-tests.sh raw --sj --scb --java-test test.Class
```

Regarding Java tests, you can pass any valid `yb_build.sh` options to `java` tests at the end of the command, example:

```sh
yb-tests.sh java test.Class --sj --scb
```

Once finished working with tests, to put the YugabyteDB in release mode, use the `ybdb-rebuild` target with relevant arguments.

#### Debugging the debug mode build with gdb

Start the master and TServer in separate terminals (via `docker exec -ti ... /bin/bash`):

```
rm -rf /tmp/yb/master
mkdir -p /tmp/yb/master
/yb-source/build/latest/bin/yb-master --master_addresses=127.0.0.1:7100 --replication_factor=1 --fs_data_dirs=/tmp/yb/master --logtostderr=true
```

```
rm -rf /tmp/yb/tserver
mkdir -p /tmp/yb/tserver
/yb-source/build/latest/bin/yb-tserver --tserver_master_addrs=127.0.0.1:7100 --ysql_enable_auth --fs_data_dirs=/tmp/yb/tserver --logtostderr=true
```

In another terminal, start GDB:

```
set auto-load safe-path /
attach <pid of master, tserver or postgres>
```

Set some breakpoints, for example:

```
break yb::pggate::PgTableDesc::FindColumn(int)
```

## Building YugabyteDB with Postgres extensions

The first pass build and rebuild allows compilation of extensions together with YugabyteDB. Such compilations result in distributions with extension libraries already installed in the package and share directories. It is possible to `ybdb-rebuild` with extensions which did not exist in first pass build. To add extensions to the compilation process, for every extension:

```sh
mkdir -p .tmp/extensions/extension-name
cd .tmp/extensions/extension-name
git clone <extension git repository> .
```

Then simply execute first pass build or rebuild.
