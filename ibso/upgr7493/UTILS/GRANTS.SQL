set serveroutput on size 300000

@@alt_sys_enable_restricted_session
exec dbms_session.reset_package
exec rtl.lock_stop
exec rtl.lock_stop
column yyy new_value grants noprint
select decode(upper(substr('&&CRROLES',1,1)),'0','grant2','N','grant2','grant1') yyy from dual;

PROMPT Creating contexts
exec after_install.create_contexts;

PROMPT Initing Users.Userid
var u number
set echo on

exec secadmin.update_subj_equal;
exec :u := secadmin.fill_userid;
commit;
print u

@@&&grants

set echo off

@@plan_tab

@@alt_sys_disable_restricted_session

set echo on

PROMPT Rebuilding diary_views...
exec after_install.create_diarys('1')

PROMPT Initing Rights Context
exec Security.init_rights_context('<ALL>',true);

set echo off

