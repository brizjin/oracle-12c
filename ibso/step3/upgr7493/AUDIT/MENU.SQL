prompt
prompt AUDIT MENU
prompt
prompt [1] Create/Upgrade schema tables (You must do this only once BEFORE all other actions)
prompt [2] Enter diaries parameters (You must do this BEFORE create or upgrade owner)
prompt [3] Upgrade owner
prompt [4] Create owner
prompt [5] Convert diaries
prompt *** Other choices will mean exit ***

define CHOICE='1'
define CHOICE = &&CHOICE --accept CHOICE char format a1 prompt 'Enter choice [&&CHOICE]: ' default &&CHOICE

set termout off
column xxx new_value SCRIPT noprint
select decode('&&CHOICE', '1', 'upgrade\upgrade', '2', 'settings\settings', '3', 'up_owner', '4', 'cr_owner', '5', 'cnv_data') xxx from dual;
column xxx new_value MENU noprint
select decode('&&SCRIPT', '', '', 'menu') xxx from dual;
set termout on

@&&SCRIPT

@&&MENU

exit
