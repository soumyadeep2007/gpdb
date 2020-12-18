-- Ensure that our expectation of pg_statistic's schema is up-to-date
\d+ pg_statistic

--------------------------------------------------------------------------------
-- Scenario: User table without hll flag
--------------------------------------------------------------------------------

create table minirepro_foo(a int) partition by range(a);
create table minirepro_foo_1 partition of minirepro_foo for values from (1) to (5);
insert into minirepro_foo values(1);
analyze minirepro_foo;

-- Generate minirepro

-- start_ignore
\! echo "select * from minirepro_foo;" > /tmp/minirepro_q.sql
\! minirepro regression -q /tmp/minirepro_q.sql -f /tmp/minirepro.sql
-- end_ignore

-- Run minirepro
drop table minirepro_foo; -- this will also delete the pg_statistic tuples for minirepro_foo and minirepro_foo_1
\! psql -f /tmp/minirepro.sql regression

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
from pg_statistic where starelid IN ('minirepro_foo'::regclass, 'minirepro_foo_1'::regclass);

-- Cleanup
drop table minirepro_foo;

--------------------------------------------------------------------------------
-- Scenario: User table with hll flag
--------------------------------------------------------------------------------

create table minirepro_foo(a int) partition by range(a);
create table minirepro_foo_1 partition of minirepro_foo for values from (1) to (5);
insert into minirepro_foo values(1);
analyze minirepro_foo;

-- Generate minirepro

-- start_ignore
\! echo "select * from minirepro_foo;" > /tmp/minirepro_q.sql
\! minirepro regression -q /tmp/minirepro_q.sql -f /tmp/minirepro.sql --hll
-- end_ignore

-- Run minirepro
drop table minirepro_foo; -- this will also delete the pg_statistic tuples for minirepro_foo and minirepro_foo_1
\! psql -f /tmp/minirepro.sql regression

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
from pg_statistic where starelid IN ('minirepro_foo'::regclass, 'minirepro_foo_1'::regclass);

-- Cleanup
drop table minirepro_foo;

--------------------------------------------------------------------------------
-- Scenario: User table with escape-worthy characters in stavaluesN
--------------------------------------------------------------------------------

create table minirepro_foo(a text);
insert into minirepro_foo values('1');
analyze minirepro_foo;
set allow_system_table_mods to on;
update pg_statistic set stavalues3='{"hello", "''world''"}'::text[] where starelid='minirepro_foo'::regclass;

-- Generate minirepro

-- start_ignore
\! echo "select * from minirepro_foo;" > /tmp/minirepro_q.sql
\! minirepro regression -q /tmp/minirepro_q.sql -f /tmp/minirepro.sql
-- end_ignore

-- Run minirepro
drop table minirepro_foo; -- this should also delete the pg_statistic tuple for minirepro_foo
\! psql -f /tmp/minirepro.sql regression

select stavalues3 from pg_statistic where starelid='minirepro_foo'::regclass;

-- Cleanup
drop table minirepro_foo;

--------------------------------------------------------------------------------
-- Scenario: Catalog table without hll flag
--------------------------------------------------------------------------------

-- Generate minirepro

-- start_ignore
\! echo "select oid from pg_tablespace;" > /tmp/minirepro_q.sql
\! minirepro regression -q /tmp/minirepro_q.sql -f /tmp/minirepro.sql
-- end_ignore

-- Run minirepro
-- Caution: The following operation will remove the pg_statistic tuple
-- corresponding to pg_tablespace before it re-inserts it, which may lead to
-- corrupted stats for pg_tablespace. But, that shouldn't matter too much?
\! psql -f /tmp/minirepro.sql regression

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
from pg_statistic where starelid='pg_tablespace'::regclass;

--------------------------------------------------------------------------------
-- Scenario: User table with extended statistics
--------------------------------------------------------------------------------
create table minirepro_foo(i int, j int, k int);
insert into minirepro_foo values (1, 2, 3),(1, 2, 2),(1, 2, 2);
create statistics foo_nd1 (ndistinct) on i, j from minirepro_foo;
create statistics foo_nd2 (ndistinct) on i, k from minirepro_foo;
create statistics foo_depends (dependencies) on i, k from minirepro_foo;
create statistics foo_mcv (mcv) on j, k from minirepro_foo;
analyze minirepro_foo;

-- Display extended statistics for minirepro_foo
select
    e.stxname,
    e.stxnamespace,
    e.stxkeys,
    e.stxkind,
    ed.stxdndistinct,
    ed.stxddependencies,
    ed.stxdmcv
from
    pg_statistic_ext e
        join pg_statistic_ext_data ed on e.oid = ed.stxoid
where
        e.stxrelid = 'minirepro_foo'::regclass;

-- Generate minirepro

-- start_ignore
\! echo "select * from minirepro_foo;" > /tmp/minirepro_q.sql
\! minirepro regression -q /tmp/minirepro_q.sql -f /tmp/minirepro.sql
-- end_ignore

drop table minirepro_foo;
-- The above drop should also drop associated extended statistics tuples.
-- Ensure that this is the case.
select count(*) from pg_statistic_ext where stxname='foo_nd';

-- Run minirepro
\! psql -f /tmp/minirepro.sql regression

-- Display extended statistics for minirepro_foo after running the minirepro
-- script. This should produce the same result as before.
select
    e.stxname,
    e.stxnamespace,
    e.stxkeys,
    e.stxkind,
    ed.stxdndistinct,
    ed.stxddependencies,
    ed.stxdmcv
from
    pg_statistic_ext e
        join pg_statistic_ext_data ed on e.oid = ed.stxoid
where
        e.stxrelid = 'minirepro_foo'::regclass;

