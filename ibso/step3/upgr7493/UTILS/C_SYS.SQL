Prompt * Installation FIO/HASH/XML/RUNPROC - ORACLE server
rem ACCEPT OWNER    PROMPT 'FIO/HASH/XML old owner name (IBS):' default IBS
define UNAME = IBS
def owner=&&uname

var s1 varchar2(2000)
var s2 varchar2(2000)
var s4 varchar2(2000)
var s5 varchar2(2000)
begin
  for c in (select library_name, file_spec from dba_libraries
             where owner=upper('&&OWNER') and library_name in ('LIBFIO','LIBHASH','LIBXML','LIBRUNPROC')
  ) loop
      if c.library_name='LIBFIO' then
          :s1 := replace(c.file_spec,'/fio.s','/libfio.s');
      elsif c.library_name='LIBHASH' then
          :s2 := replace(c.file_spec,'/hash.s','/libhash.s');
      elsif c.library_name='LIBXML' then
          :s4 := c.file_spec;
      else
          :s5 := c.file_spec;
      end if;
  end loop;
  :s1 := nvl(:s1,'/u/tools/fio/libfio.so');
  :s2 := nvl(:s2,'/u/tools/hash/libhash.so');
  :s4 := nvl(:s4,'/u/tools/xml/libxml.so');
  :s5 := nvl(:s5,'/u/tools/runproc/librunproc.so');
end;
/

var db_version number

declare
  s1 varchar2(100);
  s2 varchar2(100);
begin
  dbms_utility.db_version(s1,s2);
  :db_version := substr(s1,1,instr(s1,'.')-1);
end;
/

column xxx new_value fiopath noprint
select :s1 xxx from dual;
column xxx new_value hashpath noprint
select :s2 xxx from dual;
column xxx new_value xmlpath noprint
select :s4 xxx from dual;
column xxx new_value runpath noprint
select :s5 xxx from dual;
SET SERVEROUTPUT ON SIZE 10000

spool c_sys.log
define FIOPATH = &&fiopath --ACCEPT FIOPATH  PROMPT 'PATH to fio  library (&&fiopath):'  default &&fiopath
define HASHPATH = &&hashpath --ACCEPT HASHPATH PROMPT 'PATH to hash library (&&hashpath):' default &&hashpath
define XMLPATH = &&xmlpath --ACCEPT XMLPATH  PROMPT 'PATH to xml library (&&xmlpath):' default &&xmlpath
define RUNPATH = &&runpath --ACCEPT RUNPATH  PROMPT 'PATH to runproc library (&&runpath):' default &&runpath
def

Prompt * Stopping jobs
exec &&owner..rtl.lock_stop
exec &&uname..rtl.lock_stop

Prompt * creating library libfio
create or replace library &&uname..libfio as '&&fiopath'
/

Prompt * creating library libhash
create or replace library &&uname..libhash as '&&hashpath'
/

Prompt * creating library libxml
create or replace library &&uname..libxml as '&&xmlpath'
/

Prompt * creating library librunproc
create or replace library &&uname..librunproc as '&&runpath'
/

Prompt * creating index sys.I_USER_ASTATUS_MAP1
create unique index sys.I_USER_ASTATUS_MAP1 on sys.USER_ASTATUS_MAP(STATUS#,STATUS)
/

Prompt * creating view dba_role_privs_simple
create or replace view sys.dba_role_privs_simple as
select u1.name grantee, u2.name GRANTED_ROLE
from sys.sysauth$ sa, sys.user$ u1, sys.user$ u2
where u1.user#=sa.grantee#
  and u2.user#=sa.privilege#
group by u1.name,u2.name
/
sho err view sys.dba_role_privs_simple

grant select on sys.dba_role_privs_simple to &&uname
/

@@dba_nt

grant select on sys.dba_nested_tables_simple to &&uname
/

@@dba_err

grant select on sys.dba_errors_simple to &&uname
/

@@usr_nt

grant select on sys.user_nested_tables_simple to &&uname
/

@@all_syn

grant select on sys.all_synonyms_simple to &&uname
/

@@usr_err

grant select on sys.user_errors_simple to &&uname
/

@@dba_cons

grant select on dba_constraints_1 to &&uname
/
grant select on dba_cons_columns_1 to &&uname
/

@@dba_ind

grant select on dba_ind_columns_1 to &&uname
/


spool off
exit

