# YugabyteDB PostgreSQL extensions build infrastructure MVP

This is a minimal setup for [YugabyteDB](https://yugabyte.com) PostgreSQL extensions building. This repository is distilled from the YugabyteDB documentation, mainly:

- [Extensions requiring installation](https://docs.yugabyte.com/latest/api/ysql/extensions/#extensions-requiring-installation)

Comes with a very basic extension which disallows a regular user (no superuser) from:

- creating a table in the _pg\_public_ tablespace
- set _default\_tablespace_ and _temp\_tablespaces_; thus change them

Work originally inspired by the article from _supabase_:

- [Protecting reserved roles with PostgreSQL Hooks](https://supabase.io/blog/2021/07/01/roles-postgres-hooks)

## Create the build infrastructure Docker image

```sh
make ext-infra
```

## Build the extension

```sh
make ext-build
```

Optionally:

```sh
make ext-clean
```

## Run PostgreSQL with the extension

```sh
make ext-run-postgres
```

## Run tests: installcheck

```sh
make ext-installcheck
```

This target will run the regression tests using PostgreSQL regression testing framework.

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