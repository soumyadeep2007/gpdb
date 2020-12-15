-- Ensure that our expectation of pg_statistic's schema is up-to-date
\d+ pg_statistic

--------------------------------------------------------------------------------
-- Scenario: Table without hll flag
--------------------------------------------------------------------------------

drop database if exists gpsd_db;
create database gpsd_db;
\c gpsd_db

create table gpsd_foo(a int, s text) partition by range(a);
create table gpsd_foo_1 partition of gpsd_foo for values from (1) to (5);
insert into gpsd_foo values(1, 'something');
analyze gpsd_foo;

set allow_system_table_mods to on;
update pg_statistic set stavalues3='{"hello", "''world''"}'::text[] where starelid='gpsd_foo'::regclass and staattnum=2;

-- start_ignore
\! gpsd gpsd_db > /tmp/gpsd-without-hll.sql
-- end_ignore

\c regression
drop database if exists gpsd_db;
create database gpsd_db;

-- start_ignore
\! psql -f /tmp/gpsd-without-hll.sql gpsd_db
-- end_ignore
\c gpsd_db

select
    staattnum,
    stainherit,
    stanullfrac,
    stawidth,
    stadistinct,
    stakind1,
    stakind2,
    stakind3,
    stakind4,
    stakind5,
    staop1,
    staop2,
    staop3,
    staop4,
    staop5,
    stacoll1,
    stacoll2,
    stacoll3,
    stacoll4,
    stacoll5,
    stanumbers1,
    stanumbers2,
    stanumbers3,
    stanumbers4,
    stanumbers5,
    stavalues1,
    stavalues2,
    stavalues3,
    stavalues4,
    stavalues5
from pg_statistic where starelid IN ('gpsd_foo'::regclass, 'gpsd_foo_1'::regclass);

--------------------------------------------------------------------------------
-- Scenario: Table with hll flag
--------------------------------------------------------------------------------

drop database if exists gpsd_db;
create database gpsd_db;
\c gpsd_db

create table gpsd_foo(a int, s text) partition by range(a);
create table gpsd_foo_1 partition of gpsd_foo for values from (1) to (5);
insert into gpsd_foo values(1, 'something');
analyze gpsd_foo;

set allow_system_table_mods to on;
update pg_statistic set stavalues3='{"hello", "''world''"}'::text[] where starelid='gpsd_foo'::regclass and staattnum=2;

-- start_ignore
\! gpsd gpsd_db --hll > /tmp/gpsd-with-hll.sql
-- end_ignore

\c regression
drop database if exists gpsd_db;
create database gpsd_db;

-- start_ignore
\! psql -f /tmp/gpsd-with-hll.sql gpsd_db
-- end_ignore
\c gpsd_db

select
    staattnum,
    stainherit,
    stanullfrac,
    stawidth,
    stadistinct,
    stakind1,
    stakind2,
    stakind3,
    stakind4,
    stakind5,
    staop1,
    staop2,
    staop3,
    staop4,
    staop5,
    stacoll1,
    stacoll2,
    stacoll3,
    stacoll4,
    stacoll5,
    stanumbers1,
    stanumbers2,
    stanumbers3,
    stanumbers4,
    stanumbers5,
    stavalues1,
    stavalues2,
    stavalues3,
    stavalues4,
    stavalues5
from pg_statistic where starelid IN ('gpsd_foo'::regclass, 'gpsd_foo_1'::regclass);
