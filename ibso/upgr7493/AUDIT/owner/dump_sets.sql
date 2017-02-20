set pagesize 1000
set echo off
set verify off
set numwidth 9
set linesize 130
set arraysize 1
set trimspool on
set trimout on

set termout off

column INDEX_SUFFIX format a20
column INDEX_FIELDS format a20

column OWNER format a10
column DIARY_SUFFIX format a10
column DIARY_FIELDS format a20
column PRIMARY_KEY_FIELDS format a10
column TABLESPACE_NAME format a10
column IDX_TABLESPACE_NAME format a10

prompt diary_partitions:
select * from diary_partitions where owner = '&&OWNER';
prompt diary_indexes:
select * from diary_indexes where owner = '&&OWNER';
prompt diary_tables:
select * from diary_tables where owner = '&&OWNER';

set termout on
