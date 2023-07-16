# YugabyteDB build infrastructure

Build YugabyteDB Docker image from sources, optionally embed additional extensions.

Original build instructions:

- [Extensions requiring installation](https://docs.yugabyte.com/latest/api/ysql/extensions/#extensions-requiring-installation)

## Build the infrastructure

Build the Docker image with the build infrastructure. The purpose of this image is to provide all required and optional software necessary to build YugabyteDB. This image is mostly based on [instructions from YugabyteDB documentation](https://docs.yugabyte.com/preview/contribute/core-database/build-from-src-almalinux/). This single build infrastructure image supports clang and gcc builds.

```sh
make ybdb-build-infrastructure
```

This target requires Docker with cross-compiling functionality support because it uses `docker buildx build`.

### What's installed

- Python 3.9 with Python 3.9 _devel_ packages,
- CMake 3,
- OpenJDK 1.8.0 with OpenJDK 1.8.0 _devel_ packages,
- Ninja,
- Ccache,
- Latest Maven 3.8.x; Maven 3.9.x breaks the build,
- Clang with Clang extra tools, version from AlmaLinux package repositories, currently 15.x.x,
- GCC 11,
- a bunch of support tools to make working with the build and development process easier.

## Working with the build infrastructure

### Clang or GCC

This single build infrastructure image supports both Clang and GCC builds. Following targets are available:

- Clang:
  - `ybdb-build-first-pass-clang`: first pass build, configure for Clang,
  - `ybdb-infrastructure-shell-clang`: starts the build infrastructure in the shell mode, configure for Clang,
  - `ybdb-rebuild-extensions-clang`: a shorthand command to trigger extensions build, configure for Clang,
  - `ybdb-rebuild-clang`: a shorthand command  to trigger full rebuild, configure for Clang,
  - `ybdb-tests-clang`: a shorthand command to enter a shell configured for running tests, configure for Clang.

- GCC:
  - `ybdb-build-first-pass-gcc`: first pass build, configure for GCC,
  - `ybdb-infrastructure-shell-gcc`: starts the build infrastructure in the shell mode, configure for GCC,
  - `ybdb-rebuild-extensions-gcc`: a shorthand command to trigger extensions build, configure for GCC,
  - `ybdb-rebuild-gcc`: a shorthand command  to trigger full rebuild, configure for GCC,
  - `ybdb-tests-gcc`: a shorthand command to enter a shell configured for running tests, configure for GCC.

### Docker volumes and mount locations

The build infrastructure uses five volumes. For four of those, the base path is `./.tmp/<compiler-type>-<compiler-version>-<architecture>-<yugabytedb-source-version>` (referred further to as `$temp-root`).

- `$temp-root/extensions` mounted at `/extensions`,
- `$temp-root/yb-build` mounted at `/opt/yb-build`,
- `$temp-root/yb-build-cache` mounted at `/yb-build-cache`; Ccache configured to use this location as a build cache,
- `$temp-root/yb-source` mounted at `/yb-source`; stores cloned Git code.

This enables the possibility to work on various configurations with various source code versions without impacting each other.

The fifth location is:

- `./tmp/yb-maven` mounted at `/root/.m2`; caches downloaded Maven artifacts; shared across different builds for efficiency.

### First pass build

This target will download the sources from the requested YugabyteDB git repository, check out the requested version, and execute a first pass build.

```sh
make ybdb-build-first-pass-clang # for Clang
make ybdb-build-first-pass-gcc   # for GCC
```

There are following configuration options available for this target:

- `YB_REPOSITORY`: YugabyteDB source repository to use, default `https://github.com/yugabyte/yugabyte-db.git`
- `YB_SOURCE_VERSION`: YugabyteDB source code version: commit hash, branch name or tag name, default `v2.19.0.0`

This process will take about 3 to 5 hours even on a reasonably powerful laptop. The more CPUs, the better. A server with 40+ cores and 192 GB RAM can turn this around in about 15 minutes.

#### M2 Mac, Docker with 8 cores, 32 GB RAM, 2 GB swap

- Clang build: `real	133m43.645s`, Java compilation: `real	4m51.484s`

### Rebuild

Recompile YugabyteDB.

```sh
make ybdb-rebuild-clang # for Clang
make ybdb-rebuild-gcc   # for GCC
```

### Rebuild third-party extensions

Regular rebuild process does not rebuild third-party extensions. To rebuild third-party extensions, run:

```sh
make ybdb-rebuild-extensions-clang # for Clang
make ybdb-rebuild-extensions-gcc   # for GCC
```

This command implies `clean`, in effect - it's a new build.

### Create a release distribution

This target creates a _tar.gz_ distribution archive from the previous first pass or rebuild result.

```sh
make ybdb-distribution
```

There are following configuration options available for this target:

- `YB_RELEASE_VERSION`: YugabyteDB release version - used for the _tar.gz_ file name, default `2.19.0.0` results in the `yugabyte-2.19.0.0.tar.gz` archive file.

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
- `YB_SOURCE_VERSION`: used as the image label: YugabyteDB source code version: commit hash, branch name or tag name, default `v2.19.0.0`

### Running YugabyteDB tests

```sh
make ybdb-tests-clang
make ybdb-tests-gcc
```

This will run the infrastructure in the shell mode with YugabyteDB reconfigured to the `debug` mode. Once the shell is available, run tests like this:

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

Any valid `yb_build.sh` option can be passed to `java` tests at the end of the command, example:

```sh
yb-tests.sh java test.Class --sj --scb
```

Once finished working with tests, put the YugabyteDB back in release mode using the relevant `ybdb-rebuild-[clang|gcc]` target.

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

The first pass build and rebuild allows extensions compilation together with YugabyteDB.

Such compilations result in distributions with extension libraries already installed in the package and share directories. It is possible to `ybdb-rebuild-[clang|gcc]` with extensions which did not exist in first pass build.

To add extensions to the compilation process, for every extension:

```sh
mkdir -p .tmp/extensions/extension-name
cd .tmp/extensions/extension-name
git clone <extension git repository> .
```

Then simply execute first pass build or rebuild.

## Caveats: additional context

### Why is patchelf installed in the infrastructure image

During a release build the `yugabyted-ui` _build.sh_ program uses a system-wide `patchelf` and `ldd`. `ldd` comes preinstalled and `patchelf` needs to be added. An alternative would be to configure the `$PATH` so that linuxbrew copies are in effect. Preferably the build.sh program should be modified to pick up the path from the downloaded linuxbrew.

Tracking issue: https://github.com/yugabyte/yugabyte-db/issues/18258.
