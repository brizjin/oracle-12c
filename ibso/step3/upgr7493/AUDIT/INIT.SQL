set termout off
set serveroutput on size 100000
alter session set nls_numeric_characters='.,';
alter session set sort_area_size=83886080;
alter session set nls_language = english;

def sqlloader='&1'
undef 1

var constr varchar2(200)
exec :constr:='&2'
undef 2

var db_version number

declare
  s1 varchar2(100);
  s2 varchar2(100);
begin
  dbms_utility.db_version(s1,s2);
  :db_version := substr(s1,1,instr(s1,'.')-1);
end;
/

set termout on
set time on

@../settings

define OWNER='&&IBSO_OWNER'
define OWN_VER='7.4'
define D_MIN_INTERVAL=90
define D_USE_TZ=NO
define D_PARALLEL=0
define USEPARTITIONS=Y

column yyy new_value D_TIMESTAMP_FORMAT noprint
select decode(sign(:db_version-8), 1, '''YYYY-MM-DD HH24:MI:SS.FF6''', '''YYYY-MM-DD HH24:MI:SS''') yyy from dual;

column yyy new_value D_TO_TIMESTAMP noprint
select decode(sign(:db_version-8), 1, 'to_timestamp', 'to_date') yyy from dual;

column yyy new_value D_SYSTIMESTAMP noprint
select decode(sign(:db_version-8), 1, 'systimestamp', 'sysdate') yyy from dual;

column yyy new_value D_TIMESTAMP noprint
select decode(sign(:db_version-8),1,'timestamp','date') yyy from dual;

column yyy new_value D_DROPINDEX noprint
select decode(sign(:db_version-9), 1, 'DROP INDEX', '') yyy from dual;

column yyy new_value USEPARTITIONS noprint
select decode(value,'TRUE','YES','NO') yyy from v$option  where PARAMETER='Partitioning';


