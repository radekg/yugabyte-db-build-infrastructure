# YugabyteDB build infrastructure

Build YugabyteDB Docker image from sources, optionally embed additional extensions.

Original build instructions:

- [Extensions requiring installation](https://docs.yugabyte.com/latest/api/ysql/extensions/#extensions-requiring-installation)

## Build infrastructure

### Create the build infrastructure Docker image

```sh
make ybdb-build-infrastructure
```

This command creates a base Docker image with all the tools required to build YugabyteDB later on. Configuration:

- `YB_BUILD_INFRASTRUCTURE_DOCKER_TAG`: build infrastructure Docker image tag, default `local/yb-builder-toolchain`
- `YB_BUILD_INFRASTRUCTURE_DOCKER_VERSION`: build infrastructure Docker image version, default `latest`
- `YB_BUILD_INFRASTRUCTURE_GCC_VERSION`: gcc version to install in the image, default `7.3.0`
- `YB_BUILD_INFRASTRUCTURE_GCC_PARALLELISM`: the `-j` value for gcc `make`, default `32`

To build with a different Docker tag, different gcc version and `make -j 4`, call:

```sh
make
    YB_BUILD_INFRASTRUCTURE_DOCKER_TAG=my-build-infrastructure \
    YB_BUILD_INFRASTRUCTURE_DOCKER_VERSION=1.0.0 \
    YB_BUILD_INFRASTRUCTURE_GCC_VERSION=... \
    YB_BUILD_INFRASTRUCTURE_GCC_PARALLELISM=4 \
    ybdb-build-infrastructure
```

Keep the `YB_BUILD_INFRASTRUCTURE_DOCKER_TAG` and `YB_BUILD_INFRASTRUCTURE_DOCKER_VERSION` consistent when using the other targets.

### First pass build

This target will download the sources from the request repository, check out the requested version and execute a first pass build.

```sh
make ybdb-build-first-pass
```

There are following configuration options available for this target:

- `YB_BUILD_INFRASTRUCTURE_DOCKER_TAG`: build infrastructure Docker image tag, default `local/yb-builder-toolchain`
- `YB_BUILD_INFRASTRUCTURE_DOCKER_VERSION`: build infrastructure Docker image version, default `latest`
- `YB_REPOSITORY`: YugabyteDB source repository to use, default `https://github.com/yugabyte/yugabyte-db.git`
- `YB_SOURCE_VERSION`: YugabyteDB source code version: commit hash, branch name or tag name, default `v2.7.2`

### Rebuild

Recompile Yugabyte.

```sh
make ybdb-rebuild
```

There are following configuration options available for this target:

- `YB_BUILD_INFRASTRUCTURE_DOCKER_TAG`: build infrastructure Docker image tag, default `local/yb-builder-toolchain`
- `YB_BUILD_INFRASTRUCTURE_DOCKER_VERSION`: build infrastructure Docker image version, default `latest`

### Create a release distribution

This target creates a distribution _tar.gz_ archive from the previous first pass or rebuild result.

```sh
make ybdb-distribution
```

There are following configuration options available for this target:

- `YB_BUILD_INFRASTRUCTURE_DOCKER_TAG`: build infrastructure Docker image tag, default `local/yb-builder-toolchain`
- `YB_BUILD_INFRASTRUCTURE_DOCKER_VERSION`: build infrastructure Docker image version, default `latest`
- `YB_RELEASE_VERSION`: YugabyteDB release version - used for the tar.gz file name, default `2.7.2.0` results in the `yugabyte-2.7.2.0.tar.gz` archive name

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
- `YB_RELEASE_DOCKER_TAG`: resulting Docker image tag name, default `local/yugabytedb`
- `YB_RELEASE_DOCKER_VERSION`: resulting Docker image version, default the value of `YB_RELEASE_VERSION`

## Building YugabyteDB with Postgres extensions

The first pass build and rebuild allows compilation of the extensions together with YugabyteDB. Such compilations result in distributions with extension libraries already installed in the package and share directories. It is possible to `ybdb-rebuild` with extensions which did not exist in first pass build. To add extensions to the compilation process, for every extension:

```sh
mkdir -p .tmp/extensions/extension-name
cd .tmp/extensions/extension-name
git clone <extension git repository> .
```

Then simply execute first pass build or rebuild.

## Start local YugabyteDB with Docker compose

### Build YugabyteDB Docker image

This image will have the _example_ extension bundled:

```sh
make ybdb-base
```

### Start the compose infrastructure

In three separate terminals:

```sh
make yb-start-masters
```

This may take some time to settle. Wait until you see the `Successfully built ybclient` message.

In the second terminal:

```sh
make yb-start-tservers
```

Finally, in the third terminal, start the reverse proxy:

```sh
make yb-start-traefik
```

Connect to the database:

```sh
psql "host=localhost port=5433 user=yugabyte dbname=yugabyte"
```

Create the extension:

```sql
yugabyte#=> create extension example;
```
```
CREATE EXTENSION
```

List extensions:

```
yugabyte#=> \dx
                                     List of installed extensions
        Name        | Version |   Schema   |                        Description
--------------------+---------+------------+-----------------------------------------------------------
 example            | 0.1.0   | public     | Example library
 pg_stat_statements | 1.6     | pg_catalog | track execution statistics of all SQL statements executed
 plpgsql            | 1.0     | pg_catalog | PL/pgSQL procedural language
(3 rows)

```