-- create a test database:
create database contrib_regression;

-- create regular role
create role some_user;

-- create and configure tablespace for the some_user user:
create tablespace ts_some_user owner some_user location '/tablespaces/some_user';
revoke all privileges on tablespace pg_default from some_user;
revoke all privileges on tablespace pg_global from some_user;
grant all on tablespace ts_some_user to some_user with grant option;
alter role some_user set default_tablespace = 'ts_some_user';
alter role some_user set temp_tablespaces = 'ts_some_user';

-- create an extension:
create extension if not exists example;