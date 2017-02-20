set serveroutput on size 1000000

host del getJCVersion.txt
whenever sqlerror exit

var java_version varchar2(100);
begin
select plp2java.get_version into :java_version from dual;
if :java_version is null then
   raise_application_error( -20001, 'insufficient privileges');
end if;
end;
/

spool getJCVersion.txt

print java_version

spool off

exit