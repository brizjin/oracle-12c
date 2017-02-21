prompt
define OWNER = &&OWNER --accept OWNER char format a30 prompt 'CREATE IBSO OWNER [&&OWNER]: ' default &&OWNER
define OWN_VER = &&OWN_VER --accept OWN_VER char format a30 prompt 'IBSO OWNER "&&owner" Version [&&OWN_VER]: ' default &&OWN_VER

set termout off
column xxx new_value owner noprint
select upper('&&owner') xxx from dual;
column xxx new_value TIME noprint
select to_char(sysdate, 'HH24_MI_SS') xxx from dual;
set termout on

spool cr_&&OWNER._&&TIME..log

@owner/cr_owner

spool off

