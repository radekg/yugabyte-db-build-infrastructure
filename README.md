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
# for example:
yb-tests.sh java org.yb.pgsql.TestDropTableWithConcurrentTxn
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

## Compatibility

| Tool                      | Intel mac | M2 mac       |
| ------------------------- | --------- | ------------ |
| Clang: first pass build   | 👍        | 👍           |
| Clang: distribution       | 👍 `*`    | 👍 `*`, `**` |
| Clang: rebuild            | 👍        | 👍           |
| Clang: rebuild extensions | 👍        | 👍           |
| Clang: Java tests         | 👍        | 👎           |
| Clang: C++ tests          |           |              |
| Clang: Docker image build |           |              |
| GCC:   first pass build   | 👍        | 👍           |
| GCC:   distribution       | 👍 `*`    | 👎           |
| GCC:   rebuild            | 👍        | 👍           |
| GCC:   rebuild extensions | 👍        | 👍           |
| GCC:   Java tests         | 👍        | 👎           |
| GCC:   C++ tests          | 👍 `***`  |              |
| GCC:   Docker image build |           |              |

- `*`: requires `python/yugabyte/library_packager.py.diff`
- `**`: requires `yugabyted-ui/build.sh.diff`
- `***`: some individual tests fail but tests execute

## Building YugabyteDB with Postgres extensions

The first pass build and rebuild allows extensions compilation together with YugabyteDB.

Such compilations result in distributions with extension libraries already installed in the package and share directories. It is possible to `ybdb-rebuild-[clang|gcc]` with extensions which did not exist in first pass build.

To add extensions to the compilation process, for every extension:

```sh
mkdir -p .tmp/extensions/extension-name
cd .tmp/extensions/extension-name
git clone <extension git repository> .
```

Then execute first pass build or rebuild.

## KNown problems and caveats

### General build infrastructure

#### OpenJDK 11 is used to compile Java bits

Java 8 and Docker do not play nicely. On the M2 mac Java 8 based build hangs at random places. CPU gets pegged at 200% and memory usage goes through the roof. Compiling with Java 11 to Java 8 target works and finishes successfully.

#### `patchelf` is installed in the infrastructure image

During a release build the `yugabyted-ui/build.sh` program uses a system-wide `patchelf` and `ldd`. `ldd` comes preinstalled, `patchelf` needs to be added. An alternative would be to configure the `$PATH` so that _linuxbrew-provided_ binaries are in effect. Preferably the `build.sh` program should be modified to pick up the path from the downloaded _linuxbrew_. In reality, maintaining another patch is a stretch because installing `patchelf` is straightforward. Tracking issue: https://github.com/yugabyte/yugabyte-db/issues/18258.

#### `yugabyted-ui/build.sh` doesn't call `ldd`

Indeed. It's a no-op command printing output to the screen. It's pointless. Furthermore, it is not working on M1/M2 mac:

```
[2023-07-19T19:56:23 build.sh:48 main] Yugabyted UI Binary generated successfully at /tmp/yugabyted-ui/gobin/yugabyted-ui
Running ldd on /tmp/yugabyted-ui/gobin/yugabyted-ui
ldd: exited with unknown exit code (139)
```

Without the call to `ldd`, with the supplied `yugabyted-ui/build.sh.diff` patch applied:

```
[2023-07-19T20:12:36 build.sh:48 main] Yugabyted UI Binary generated successfully at /yb-source/build/release-clang15-linuxbrew-dynamic-ninja/gobin/yugabyted-ui
[2023-07-19T20:12:36 build.sh:57 main] Skipping ldd on generated library because it doesn't work on M1/M2 mac and the command is irrelevant anyway
[2023-07-19T20:12:36 build.sh:61 main] /yb-source/build/release-clang15-linuxbrew-dynamic-ninja/gobin/yugabyted-ui is correctly configured with the shared library interpreter: /lib64/ld-linux-x86-64.so.2
```

Works on M1/M2 mac for Clang build.

### Distribution

#### M2 mac: GCC distribution doesn't work

GCC build doesn't work due to errors in distribution creation, after `yugabyted-ui` build, where `ldd` is used extensively. Errors look like this:

```
Traceback (most recent call last):
  File "/yb-source/python/yugabyte/yb_release_core_db.py", line 444, in <module>
    main()
  File "/yb-source/python/yugabyte/yb_release_core_db.py", line 397, in main
    library_packager.package_binaries()
  File "/yb-source/python/yugabyte/library_packager.py", line 463, in package_binaries
    deps = self.find_elf_dependencies(executable)
  File "/yb-source/python/yugabyte/library_packager.py", line 335, in find_elf_dependencies
    raise RuntimeError(ldd_result.error_msg)
RuntimeError: Non-zero exit code 1 from: /usr/bin/ldd /yb-source/build/release-gcc11-dynamic-ninja/bin/ldb ; stdout: '' stderr: 'qemu: uncaught target signal 11 (Segmentation fault) - core dumped
ldd: exited with unknown exit code (139)'
```

Apparently this is due to an upstream qemu issue: https://github.com/docker/for-mac/issues/5123.

### Tests

#### Java test execution slow due to compilation

Run Java tests with `--sj` flag unless you have modified the actual Java class under test. This will skip Java compilation and use previously compiled classes. For example:

```sh
yb-tests.sh raw --sj --java-test org.yb.pgsql.TestDropTableWithConcurrentTxn
```

The test execution speed can be improved further:

```sh
# Skip Java and C++ compilation, this is useful when running a test repetitively, for example benchmarking:
yb-tests.sh raw --sj --scb --java-test org.yb.pgsql.TestDropTableWithConcurrentTxn
```

#### M2 mac: yb-tests.sh doesn't work

C++ and Java tests don't work due to the following precondition failing:

```
[2246/2246] cd /yb-source/build/debug-gcc11-dynamic-ninja/src/yb/yql/pgwrapper && /usr/bin/cmake -E env YB_BUILD_ROOT=/yb-source/build/debug-gcc11-dynamic-ninja /yb-source/build-support/gen_initial_sys_catalog_snapshot_wrapper
FAILED: src/yb/yql/pgwrapper/CMakeFiles/initial_sys_catalog_snapshot
cd /yb-source/build/debug-gcc11-dynamic-ninja/src/yb/yql/pgwrapper && /usr/bin/cmake -E env YB_BUILD_ROOT=/yb-source/build/debug-gcc11-dynamic-ninja /yb-source/build-support/gen_initial_sys_catalog_snapshot_wrapper
2023-07-19 21:50:01,547 [gen_initial_sys_catalog_snapshot.py:55 INFO] Starting creating initial system catalog snapshot data
2023-07-19 21:50:01,550 [gen_initial_sys_catalog_snapshot.py:56 INFO] Logging to: /yb-source/build/debug-gcc11-dynamic-ninja/create_initial_sys_catalog_snapshot.err

Standard output from external program {{ '/yb-source/build-support/run-test.sh' /yb-source/build/debug-gcc11-dynamic-ninja/tests-pgwrapper/create_initial_sys_catalog_snapshot }} running in '/yb-source/build/debug-gcc11-dynamic-ninja', saving stdout to {{ /yb-source/build/debug-gcc11-dynamic-ninja/create_initial_sys_catalog_snapshot.out }}, stderr to {{ /yb-source/build/debug-gcc11-dynamic-ninja/create_initial_sys_catalog_snapshot.err }}:
Test is running on host 1cd8f50da476, arguments: /yb-source/build/debug-gcc11-dynamic-ninja/tests-pgwrapper/create_initial_sys_catalog_snapshot
I0719 21:50:06.167414 445191 run-with-timeout.cc:133] Running on host 1cd8f50da476
I0719 21:50:06.170686 445191 run-with-timeout.cc:140] PATH environment variable: /yb-source/build/venv/bin:/yb-source/build/venv/bin:/opt/rh/gcc-toolset-11/root/usr/bin:/yb-source/build/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
I0719 21:50:06.171424 445191 run-with-timeout.cc:148] Starting child process with a timeout of 1201 seconds
I0719 21:50:06.181224 445191 run-with-timeout.cc:157] Child process pid: 445209
Note: Google Test filter = CreateInitialSysCatalogSnapshotTest.CreateInitialSysCatalogSnapshot
[==========] Running 1 test from 1 test suite.
[----------] Global test environment set-up.
[----------] 1 test from CreateInitialSysCatalogSnapshotTest
[ RUN      ] CreateInitialSysCatalogSnapshotTest.CreateInitialSysCatalogSnapshot
WARNING: Logging before InitGoogleLogging() is written to STDERR
W0719 21:50:08.390722 445209 env_posix.cc:1224] Create test dir failed: Already present (yb/util/env_posix.cc:1085): /tmp/yb_test.tmp.3879.20967.18980.pid445009: File exists (system error 17)
...
Standard error from external program {{ '/yb-source/build-support/run-test.sh' /yb-source/build/debug-gcc11-dynamic-ninja/tests-pgwrapper/create_initial_sys_catalog_snapshot }} running in '/yb-source/build/debug-gcc11-dynamic-ninja', saving stdout to {{ /yb-source/build/debug-gcc11-dynamic-ninja/create_initial_sys_catalog_snapshot.out }}, stderr to {{ /yb-source/build/debug-gcc11-dynamic-ninja/create_initial_sys_catalog_snapshot.err }}:
Details of third-party dependencies:
    YB_THIRDPARTY_DIR: /opt/yb-build/thirdparty/yugabyte-db-thirdparty-v20230418053213-a675ed2153-almalinux8-x86_64-gcc11 (from environment)
    YB_THIRDPARTY_URL: https://github.com/yugabyte/yugabyte-db-thirdparty/releases/download/v20230418053213-a675ed2153-almalinux8-x86_64-gcc11/yugabyte-db-thirdparty-v20230418053213-a675ed2153-almalinux8-x86_64-gcc11.tar.gz (from environment)
    YB_DOWNLOAD_THIRDPARTY: 1
    NO_REBUILD_THIRDPARTY: 1
+ /yb-source/build/debug-gcc11-dynamic-ninja/bin/run-with-timeout 1201 /yb-source/build/debug-gcc11-dynamic-ninja/tests-pgwrapper/create_initial_sys_catalog_snapshot --initial_sys_catalog_snapshot_dest_path=/yb-source/build/debug-gcc11-dynamic-ninja/share/initial_sys_catalog_snapshot --gtest_output=xml:/yb-source/build/debug-gcc11-dynamic-ninja/yb-test-logs/tests-pgwrapper__create_initial_sys_catalog_snapshot/CreateInitialSysCatalogSnapshotTest_CreateInitialSysCatalogSnapshot.xml --gtest_filter=CreateInitialSysCatalogSnapshotTest.CreateInitialSysCatalogSnapshot
[2023-07-19T22:10:08 common-test-env.sh:1187 did_test_succeed] Test failure reason: exit code: 1
2023-07-19 22:10:08,664 [rewrite_test_log.py:173 INFO] test_host_name = 1cd8f50da476
2023-07-19 22:10:08,668 [rewrite_test_log.py:173 INFO] m1_peer_id = d28ad8144cd94cea9c6b34bfa78a7aad
2023-07-19 22:10:08,668 [rewrite_test_log.py:173 INFO] sys_catalog_tablet_id = 00000000000000000000000000000000
2023-07-19 22:10:08,669 [rewrite_test_log.py:173 INFO] BUILD_ROOT = /yb-source/build/debug-gcc11-dynamic-ninja
2023-07-19 22:10:08,669 [rewrite_test_log.py:173 INFO] YB_SRC_ROOT = /yb-source
2023-07-19 22:10:08,670 [rewrite_test_log.py:173 INFO] TEST_TMPDIR = /tmp/yb_test.tmp.3879.20967.18980.pid445009

TEST FAILURE
Test command: /yb-source/build/debug-gcc11-dynamic-ninja/tests-pgwrapper/create_initial_sys_catalog_snapshot --initial_sys_catalog_snapshot_dest_path=/yb-source/build/debug-gcc11-dynamic-ninja/share/initial_sys_catalog_snapshot --gtest_output=xml:/yb-source/build/debug-gcc11-dynamic-ninja/yb-test-logs/tests-pgwrapper__create_initial_sys_catalog_snapshot/CreateInitialSysCatalogSnapshotTest_CreateInitialSysCatalogSnapshot.xml --gtest_filter=CreateInitialSysCatalogSnapshotTest.CreateInitialSysCatalogSnapshot
Test exit status: 1
Log path: /yb-source/build/debug-gcc11-dynamic-ninja/yb-test-logs/tests-pgwrapper__create_initial_sys_catalog_snapshot/CreateInitialSysCatalogSnapshotTest_CreateInitialSysCatalogSnapshot.log
Found a core file at '/tmp/yb_test.tmp.3879.20967.18980.pid445009/core', backtrace:
+ echo ''
+ gdb -q -n -ex bt -ex 'thread apply all bt' -batch /yb-source/build/debug-gcc11-dynamic-ninja/tests-pgwrapper/create_initial_sys_catalog_snapshot /tmp/yb_test.tmp.3879.20967.18980.pid445009/core
+ grep -Ev '^\[New LWP [0-9]+\]$'
+ /yb-source/python/yugabyte/dedup_thread_stacks.py
+ tee -a /yb-source/build/debug-gcc11-dynamic-ninja/yb-test-logs/tests-pgwrapper__create_initial_sys_catalog_snapshot/CreateInitialSysCatalogSnapshotTest_CreateInitialSysCatalogSnapshot.log

warning: Can't open file /usr/bin/qemu-x86_64 during file-backed mapping note processing

warning: core file may not match specified executable file.

warning: Selected architecture i386:x86-64 is not compatible with reported target architecture aarch64

warning: Architecture rejected target-supplied description

warning: Unexpected size of section `.reg/445209' in core file.

warning: Unexpected size of section `.reg2/445209' in core file.
Core was generated by `/usr/bin/qemu-x86_64 /yb-source/build/debug-gcc11-dynamic-ninja/tests-pgwrapper'.
Program terminated with signal SIGQUIT, Quit.

warning: Unexpected size of section `.reg/445209' in core file.

warning: Unexpected size of section `.reg2/445209' in core file.
#0  0x707061727767702d in ?? ()
[Current thread is 1 (LWP 445209)]
#0  0x707061727767702d in ?? ()
Backtrace stopped: Cannot access memory at address 0x3

warning: Unexpected size of section `.reg/445243' in core file.
warning: Unexpected size of section `.reg2/445243' in core file.
#0  0x0000000000f10398 in ?? ()
#1  0x0000000000000000 in ?? ()

warning: Unexpected size of section `.reg/445244' in core file.
warning: Unexpected size of section `.reg2/445244' in core file.
#0  0x0000000000f10398 in ?? ()
#1  0x0000000000000000 in ?? ()

warning: Unexpected size of section `.reg/445245' in core file.
warning: Unexpected size of section `.reg2/445245' in core file.
#0  0x0000000000000008 in ?? ()
Backtrace stopped: Cannot access memory at address 0x0

warning: Unexpected size of section `.reg/445241' in core file.
warning: Unexpected size of section `.reg2/445241' in core file.
#0  0x0000000000f10398 in ?? ()
#1  0x0000000000000000 in ?? ()

warning: Unexpected size of section `.reg/445242' in core file.
warning: Unexpected size of section `.reg2/445242' in core file.
#0  0x0000000000000006 in ?? ()
#1  0x0000000000000000 in ?? ()

warning: Unexpected size of section `.reg/445211' in core file.
warning: Unexpected size of section `.reg2/445211' in core file.
#0  0x0000ffffad7fc2c0 in __kernel_clock_gettime ()
#1  0x00000001ffffffff in ?? ()
#2  0x0000000100000000 in ?? ()
#3  0x0000000000000001 in ?? ()
#4  0x0000000000000000 in ?? ()

Backtrace stopped: Cannot access memory at address 0x3
Thread 1 (LWP 445209)
#0  0x707061727767702d in ?? ()
Thread 2 (LWP 445211), 3 (LWP 445242), 4 (LWP 445241), 5 (LWP 445245), 6 (LWP 445244), 7 (LWP 445243)


tests-pgwrapper/create_initial_sys_catalog_snapshot failed to produce an XML output file at /yb-source/build/debug-gcc11-dynamic-ninja/yb-test-logs/tests-pgwrapper__create_initial_sys_catalog_snapshot/CreateInitialSysCatalogSnapshotTest_CreateInitialSysCatalogSnapshot.xml
Generating an XML output file using parse_test_failure.py: /yb-source/build/debug-gcc11-dynamic-ninja/yb-test-logs/tests-pgwrapper__create_initial_sys_catalog_snapshot/CreateInitialSysCatalogSnapshotTest_CreateInitialSysCatalogSnapshot.xml
[2023-07-19T22:10:11 common-test-env.sh:806 handle_cxx_test_xml_output] Test failed, updating /yb-source/build/debug-gcc11-dynamic-ninja/yb-test-logs/tests-pgwrapper__create_initial_sys_catalog_snapshot/CreateInitialSysCatalogSnapshotTest_CreateInitialSysCatalogSnapshot.xml
+ /yb-source/python/yugabyte/update_test_result_xml.py --result-xml /yb-source/build/debug-gcc11-dynamic-ninja/yb-test-logs/tests-pgwrapper__create_initial_sys_catalog_snapshot/CreateInitialSysCatalogSnapshotTest_CreateInitialSysCatalogSnapshot.xml --mark-as-failed true
2023-07-19 22:10:11,943 [postprocess_test_result.py:187 INFO] Log path: /yb-source/build/debug-gcc11-dynamic-ninja/yb-test-logs/tests-pgwrapper__create_initial_sys_catalog_snapshot/CreateInitialSysCatalogSnapshotTest_CreateInitialSysCatalogSnapshot.log
2023-07-19 22:10:11,946 [postprocess_test_result.py:188 INFO] JUnit XML path: /yb-source/build/debug-gcc11-dynamic-ninja/yb-test-logs/tests-pgwrapper__create_initial_sys_catalog_snapshot/CreateInitialSysCatalogSnapshotTest_CreateInitialSysCatalogSnapshot.xml
2023-07-19 22:10:14,868 [postprocess_test_result.py:316 INFO] Wrote JSON test report file: /yb-source/build/debug-gcc11-dynamic-ninja/yb-test-logs/tests-pgwrapper__create_initial_sys_catalog_snapshot/CreateInitialSysCatalogSnapshotTest_CreateInitialSysCatalogSnapshot_test_report.json
(end of standard error)
Traceback (most recent call last):
  File "/yb-source/python/yugabyte/gen_initial_sys_catalog_snapshot.py", line 83, in <module>
    main()
  File "/yb-source/python/yugabyte/gen_initial_sys_catalog_snapshot.py", line 74, in main
    raise RuntimeError("initdb failed in %.1f sec" % elapsed_time_sec)
RuntimeError: initdb failed in 1213.4 sec
ninja: build stopped: subcommand failed.

real	160m43.874s
user	777m47.802s
sys	43m12.371s
[2023-07-19T22:10:15 yb_build.sh:589 run_cxx_build] C++ build finished with exit code 1 (build type: debug, compiler: gcc11). Timing information is available above.
```

A similar error appears on any test attempt due to:

```
[7/8] cd /yb-source/build/debug-clang15-dynamic-ninja/src/yb/yql/pgwrapper && /usr/bin/cmake -E env YB_BUILD_ROOT=/yb-source/build/debug-clang15-dynamic-ninja /yb-source/build-support/gen_initial_sys_catalog_snapshot_wrapper
```

Neither C++, nor Java tests are working:

```
TEST FAILURE
Test command: /yb-source/build/debug-gcc11-dynamic-ninja/tests-pgwrapper/create_initial_sys_catalog_snapshot --initial_sys_catalog_snapshot_dest_path=/yb-source/build/debug-gcc11-dynamic-ninja/share/initial_sys_catalog_snapshot --gtest_output=xml:/yb-source/build/debug-gcc11-dynamic-ninja/yb-test-logs/tests-pgwrapper__create_initial_sys_catalog_snapshot/CreateInitialSysCatalogSnapshotTest_CreateInitialSysCatalogSnapshot.xml --gtest_filter=CreateInitialSysCatalogSnapshotTest.CreateInitialSysCatalogSnapshot
Test exit status: 1
Log path: /yb-source/build/debug-gcc11-dynamic-ninja/yb-test-logs/tests-pgwrapper__create_initial_sys_catalog_snapshot/CreateInitialSysCatalogSnapshotTest_CreateInitialSysCatalogSnapshot.log
Found a core file at '/tmp/yb_test.tmp.3879.20967.18980.pid445009/core', backtrace:
+ echo ''
+ gdb -q -n -ex bt -ex 'thread apply all bt' -batch /yb-source/build/debug-gcc11-dynamic-ninja/tests-pgwrapper/create_initial_sys_catalog_snapshot /tmp/yb_test.tmp.3879.20967.18980.pid445009/core
+ grep -Ev '^\[New LWP [0-9]+\]$'
+ /yb-source/python/yugabyte/dedup_thread_stacks.py
+ tee -a /yb-source/build/debug-gcc11-dynamic-ninja/yb-test-logs/tests-pgwrapper__create_initial_sys_catalog_snapshot/CreateInitialSysCatalogSnapshotTest_CreateInitialSysCatalogSnapshot.log

warning: Can't open file /usr/bin/qemu-x86_64 during file-backed mapping note processing

warning: core file may not match specified executable file.

warning: Selected architecture i386:x86-64 is not compatible with reported target architecture aarch64

warning: Architecture rejected target-supplied description

warning: Unexpected size of section `.reg/445209' in core file.

warning: Unexpected size of section `.reg2/445209' in core file.
Core was generated by `/usr/bin/qemu-x86_64 /yb-source/build/debug-gcc11-dynamic-ninja/tests-pgwrapper'.
Program terminated with signal SIGQUIT, Quit.

warning: Unexpected size of section `.reg/445209' in core file.

warning: Unexpected size of section `.reg2/445209' in core file.
#0  0x707061727767702d in ?? ()
[Current thread is 1 (LWP 445209)]
#0  0x707061727767702d in ?? ()
Backtrace stopped: Cannot access memory at address 0x3

warning: Unexpected size of section `.reg/445243' in core file.
warning: Unexpected size of section `.reg2/445243' in core file.
#0  0x0000000000f10398 in ?? ()
#1  0x0000000000000000 in ?? ()

warning: Unexpected size of section `.reg/445244' in core file.
warning: Unexpected size of section `.reg2/445244' in core file.
#0  0x0000000000f10398 in ?? ()
#1  0x0000000000000000 in ?? ()

warning: Unexpected size of section `.reg/445245' in core file.
warning: Unexpected size of section `.reg2/445245' in core file.
#0  0x0000000000000008 in ?? ()
Backtrace stopped: Cannot access memory at address 0x0

warning: Unexpected size of section `.reg/445241' in core file.
warning: Unexpected size of section `.reg2/445241' in core file.
#0  0x0000000000f10398 in ?? ()
#1  0x0000000000000000 in ?? ()

warning: Unexpected size of section `.reg/445242' in core file.
warning: Unexpected size of section `.reg2/445242' in core file.
#0  0x0000000000000006 in ?? ()
#1  0x0000000000000000 in ?? ()

warning: Unexpected size of section `.reg/445211' in core file.
warning: Unexpected size of section `.reg2/445211' in core file.
#0  0x0000ffffad7fc2c0 in __kernel_clock_gettime ()
#1  0x00000001ffffffff in ?? ()
#2  0x0000000100000000 in ?? ()
#3  0x0000000000000001 in ?? ()
#4  0x0000000000000000 in ?? ()

Backtrace stopped: Cannot access memory at address 0x3
Thread 1 (LWP 445209)
#0  0x707061727767702d in ?? ()
Thread 2 (LWP 445211), 3 (LWP 445242), 4 (LWP 445241), 5 (LWP 445245), 6 (LWP 445244), 7 (LWP 445243)


tests-pgwrapper/create_initial_sys_catalog_snapshot failed to produce an XML output file at /yb-source/build/debug-gcc11-dynamic-ninja/yb-test-logs/tests-pgwrapper__create_initial_sys_catalog_snapshot/CreateInitialSysCatalogSnapshotTest_CreateInitialSysCatalogSnapshot.xml
Generating an XML output file using parse_test_failure.py: /yb-source/build/debug-gcc11-dynamic-ninja/yb-test-logs/tests-pgwrapper__create_initial_sys_catalog_snapshot/CreateInitialSysCatalogSnapshotTest_CreateInitialSysCatalogSnapshot.xml
[2023-07-19T22:10:11 common-test-env.sh:806 handle_cxx_test_xml_output] Test failed, updating /yb-source/build/debug-gcc11-dynamic-ninja/yb-test-logs/tests-pgwrapper__create_initial_sys_catalog_snapshot/CreateInitialSysCatalogSnapshotTest_CreateInitialSysCatalogSnapshot.xml
+ /yb-source/python/yugabyte/update_test_result_xml.py --result-xml /yb-source/build/debug-gcc11-dynamic-ninja/yb-test-logs/tests-pgwrapper__create_initial_sys_catalog_snapshot/CreateInitialSysCatalogSnapshotTest_CreateInitialSysCatalogSnapshot.xml --mark-as-failed true
2023-07-19 22:10:11,943 [postprocess_test_result.py:187 INFO] Log path: /yb-source/build/debug-gcc11-dynamic-ninja/yb-test-logs/tests-pgwrapper__create_initial_sys_catalog_snapshot/CreateInitialSysCatalogSnapshotTest_CreateInitialSysCatalogSnapshot.log
2023-07-19 22:10:11,946 [postprocess_test_result.py:188 INFO] JUnit XML path: /yb-source/build/debug-gcc11-dynamic-ninja/yb-test-logs/tests-pgwrapper__create_initial_sys_catalog_snapshot/CreateInitialSysCatalogSnapshotTest_CreateInitialSysCatalogSnapshot.xml
2023-07-19 22:10:14,868 [postprocess_test_result.py:316 INFO] Wrote JSON test report file: /yb-source/build/debug-gcc11-dynamic-ninja/yb-test-logs/tests-pgwrapper__create_initial_sys_catalog_snapshot/CreateInitialSysCatalogSnapshotTest_CreateInitialSysCatalogSnapshot_test_report.json
(end of standard error)
Traceback (most recent call last):
  File "/yb-source/python/yugabyte/gen_initial_sys_catalog_snapshot.py", line 83, in <module>
    main()
  File "/yb-source/python/yugabyte/gen_initial_sys_catalog_snapshot.py", line 74, in main
    raise RuntimeError("initdb failed in %.1f sec" % elapsed_time_sec)
RuntimeError: initdb failed in 1213.4 sec
ninja: build stopped: subcommand failed.
```

```
[INFO] -------------------------------------------------------
[INFO]  T E S T S
[INFO] -------------------------------------------------------
[INFO] Running org.yb.pgsql.TestDropTableWithConcurrentTxn
[ERROR] Tests run: 2, Failures: 0, Errors: 2, Skipped: 0, Time elapsed: 1,816.954 s <<< FAILURE! - in org.yb.pgsql.TestDropTableWithConcurrentTxn
[ERROR] testDmlTxnDropWithReadCommitted(org.yb.pgsql.TestDropTableWithConcurrentTxn)  Time elapsed: 612.905 s  <<< ERROR!
java.lang.Exception: Operation timed out after 600000ms

[ERROR] testDmlTxnDrop(org.yb.pgsql.TestDropTableWithConcurrentTxn)  Time elapsed: 1,200.09 s  <<< ERROR!
org.junit.runners.model.TestTimedOutException: test timed out after 1200 seconds
	at app//org.yb.pgsql.TestDropTableWithConcurrentTxn.runDmlTxnWithDropOnCurrentResource(TestDropTableWithConcurrentTxn.java:180)
	at app//org.yb.pgsql.TestDropTableWithConcurrentTxn.testDmlTxnDropInternal(TestDropTableWithConcurrentTxn.java:384)
	at app//org.yb.pgsql.TestDropTableWithConcurrentTxn.testDmlTxnDrop(TestDropTableWithConcurrentTxn.java:398)

[INFO]
[INFO] Results:
[INFO]
[ERROR] Errors:
[ERROR]   TestDropTableWithConcurrentTxn.testDmlTxnDrop:398->testDmlTxnDropInternal:384->runDmlTxnWithDropOnCurrentResource:180 » TestTimedOut
[ERROR]   TestDropTableWithConcurrentTxn>BasePgSQLTest.initPostgresBefore:306 »  Operati...
[INFO]
[ERROR] Tests run: 2, Failures: 0, Errors: 2, Skipped: 0
[INFO]
[INFO] ------------------------------------------------------------------------
[INFO] BUILD FAILURE
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  30:34 min
[INFO] Finished at: 2023-07-19T23:05:17Z
[INFO] ------------------------------------------------------------------------
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-surefire-plugin:2.22.2:test (default-cli) on project yb-pgsql: There are test failures.
[ERROR]
[ERROR] Please refer to /yb-source/java/yb-pgsql/target/surefire-reports_org.yb.pgsql.TestDropTableWithConcurrentTxn for the individual test results.
[ERROR] Please refer to dump files (if any exist) [date].dump, [date]-jvmRun[N].dump and [date].dumpstream.
[ERROR] -> [Help 1]
[ERROR]
[ERROR] To see the full stack trace of the errors, re-run Maven with the -e switch.
[ERROR] Re-run Maven using the -X switch to enable full debug logging.
[ERROR]
[ERROR] For more information about the errors and possible solutions, please read the following articles:
[ERROR] [Help 1] http://cwiki.apache.org/confluence/display/MAVEN/MojoFailureException

real	30m39.960s
user	82m14.171s
sys	3m4.636s
[2023-07-19T23:05:17 common-test-env.sh:1661 run_java_test] Maven exited with code 1
[2023-07-19T23:05:20 common-test-env.sh:1691 run_java_test] Filtered JUnit XML file '/yb-source/java/yb-pgsql/target/surefire-reports_org.yb.pgsql.TestDropTableWithConcurrentTxn/TEST-org.yb.pgsql.TestDropTableWithConcurrentTxn.xml' is valid
./build-support/common-test-env.sh: line 1041: TEST_TMPDIR: unbound variable
[2023-07-19T23:05:20 common-test-env.sh:1051 rewrite_test_log] Test log rewrite script failed with exit code 1
2023-07-19 23:05:20,783 [postprocess_test_result.py:187 INFO] Log path: /yb-source/java/yb-pgsql/target/surefire-reports_org.yb.pgsql.TestDropTableWithConcurrentTxn/org.yb.pgsql.TestDropTableWithConcurrentTxn-output.txt
2023-07-19 23:05:20,786 [postprocess_test_result.py:188 INFO] JUnit XML path: /yb-source/java/yb-pgsql/target/surefire-reports_org.yb.pgsql.TestDropTableWithConcurrentTxn/TEST-org.yb.pgsql.TestDropTableWithConcurrentTxn.xml
2023-07-19 23:05:20,788 [postprocess_test_result.py:201 INFO] Externally specified class name: org.yb.pgsql.TestDropTableWithConcurrentTxn
2023-07-19 23:05:27,753 [postprocess_test_result.py:316 INFO] Wrote JSON test report file: /yb-source/java/yb-pgsql/target/surefire-reports_org.yb.pgsql.TestDropTableWithConcurrentTxn/TEST-org.yb.pgsql.TestDropTableWithConcurrentTxn_test_report.json
```

This problem also applies to Clang based builds:

```
tests-pgwrapper/create_initial_sys_catalog_snapshot failed to produce an XML output file at /yb-source/build/debug-clang15-dynamic-ninja/yb-test-logs/tests-pgwrapper__create_initial_sys_catalog_snapshot/CreateInitialSysCatalogSnapshotTest_CreateInitialSysCatalogSnapshot.xml
Generating an XML output file using parse_test_failure.py: /yb-source/build/debug-clang15-dynamic-ninja/yb-test-logs/tests-pgwrapper__create_initial_sys_catalog_snapshot/CreateInitialSysCatalogSnapshotTest_CreateInitialSysCatalogSnapshot.xml
[2023-07-20T01:36:34 common-test-env.sh:806 handle_cxx_test_xml_output] Test failed, updating /yb-source/build/debug-clang15-dynamic-ninja/yb-test-logs/tests-pgwrapper__create_initial_sys_catalog_snapshot/CreateInitialSysCatalogSnapshotTest_CreateInitialSysCatalogSnapshot.xml
+ /yb-source/python/yugabyte/update_test_result_xml.py --result-xml /yb-source/build/debug-clang15-dynamic-ninja/yb-test-logs/tests-pgwrapper__create_initial_sys_catalog_snapshot/CreateInitialSysCatalogSnapshotTest_CreateInitialSysCatalogSnapshot.xml --mark-as-failed true
2023-07-20 01:36:35,181 [postprocess_test_result.py:187 INFO] Log path: /yb-source/build/debug-clang15-dynamic-ninja/yb-test-logs/tests-pgwrapper__create_initial_sys_catalog_snapshot/CreateInitialSysCatalogSnapshotTest_CreateInitialSysCatalogSnapshot.log
2023-07-20 01:36:35,184 [postprocess_test_result.py:188 INFO] JUnit XML path: /yb-source/build/debug-clang15-dynamic-ninja/yb-test-logs/tests-pgwrapper__create_initial_sys_catalog_snapshot/CreateInitialSysCatalogSnapshotTest_CreateInitialSysCatalogSnapshot.xml
2023-07-20 01:36:38,127 [postprocess_test_result.py:316 INFO] Wrote JSON test report file: /yb-source/build/debug-clang15-dynamic-ninja/yb-test-logs/tests-pgwrapper__create_initial_sys_catalog_snapshot/CreateInitialSysCatalogSnapshotTest_CreateInitialSysCatalogSnapshot_test_report.json
(end of standard error)
Traceback (most recent call last):
  File "/yb-source/python/yugabyte/gen_initial_sys_catalog_snapshot.py", line 83, in <module>
    main()
  File "/yb-source/python/yugabyte/gen_initial_sys_catalog_snapshot.py", line 74, in main
    raise RuntimeError("initdb failed in %.1f sec" % elapsed_time_sec)
RuntimeError: initdb failed in 1212.1 sec
ninja: build stopped: subcommand failed.

real	128m18.551s
user	681m26.286s
sys	31m2.172s
[2023-07-20T01:36:38 yb_build.sh:589 run_cxx_build] C++ build finished with exit code 1 (build type: debug, compiler: clang15). Timing information is available above.
```
