prompt
define OWNER = &&OWNER --accept OWNER char format a30 prompt 'UPGRADE IBSO OWNER [&&OWNER]: ' default &&OWNER
define OWN_VER = &&OWN_VER --accept OWN_VER char format a30 prompt 'IBSO OWNER "&&owner" Version [&&OWN_VER]: ' default &&OWN_VER

set termout off
column xxx new_value owner noprint
select upper('&&owner') xxx from dual;
column xxx new_value TIME noprint
select to_char(sysdate, 'HH24_MI_SS') xxx from dual;
define old_ver=''
define ver33=''
column yyy new_value ver33 noprint
select '3.3' yyy from all_tables where owner='&&owner' and table_name='DIARY';
column yyy new_value old_ver noprint
select value yyy from settings where owner='&&owner' and name='VERSION';
select nvl('&&old_ver',value) yyy from audit_settings where owner='&&owner' and name='VERSION';
select nvl('&&old_ver',nvl('&&ver33','3.4')) yyy from dual;
set termout on

spool up_&&OWNER._&&TIME..log

set termout off
define CHOICE='0'
column xxx new_value CHOICE noprint
select count(*) xxx from settings where owner = '&&OWNER';
column xxx new_value SCRIPT noprint
select decode(trim('&&CHOICE'), '0', 'owner/cr_owner', 'owner/up_owner') xxx from dual;
set termout on

@&&SCRIPT

spool off

