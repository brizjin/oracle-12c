Prompt * Installation RUNPROC - ORACLE server
ACCEPT UNAME    PROMPT 'RUNPROC IBSO owner name (IBS):' default IBS

var s varchar2(2000)
declare
  s varchar2(2000);
begin
  for c in (select library_name, file_spec from dba_libraries
             where owner=upper('&&UNAME') and library_name='LIBRUNPROC'
  ) loop
    s := c.file_spec;
  end loop;
  :s := nvl(s,'/u/tools/runproc/librunproc.so');
end;
/

column xxx new_value runpath noprint
select :s xxx from dual;

ACCEPT RUNPATH PROMPT 'PATH to RUNPROC library (&&runpath):' default &&runpath

declare
  s varchar2(2000);
  x varchar2(1);
begin
  :s := '&&runpath';
  if instr(:s,'\')>0 then
    x := '\';
  else
    x := '/';
  end if;
  for c in (select value from &&UNAME..settings where name='JOBS_RUNPROC_INI') loop
    s := c.value;
  end loop;
  :s := nvl(s,substr(:s,1,instr(:s,x,-1))||'runproc.ini');
end;
/

column xxx new_value runset noprint
select :s xxx from dual;

SET SERVEROUTPUT ON SIZE 10000

spool c_sys.log
def
Prompt * creating library librunproc
create or replace library &&uname..librunproc as '&&runpath'
/

prompt JOBS_RUNPROC_INI
insert into &&UNAME..settings(name,value,description) values('JOBS_RUNPROC_INI','&&runset',
  'Путь к файлу инициализации агента RUNPROC');

commit;

prompt Grant on v$mystat
grant SELECT on SYS.V_$MYSTAT to &&uname with grant option;

spool off
exit

