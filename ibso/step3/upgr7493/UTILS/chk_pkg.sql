set echo off
set termout off
set newpage 1
set pagesize 9999
set linesize 200
set trimspool on
set serveroutput on size 500000

spool chk_pkg.log

prompt
prompt Checking kernel packages and compilator dictionary plp$parser_info

declare
  t dbms_sql.varchar2s;
begin
  select distinct name bulk collect into t
    from user_errors where name in
('PLP2PLSQL','AFTER_INSTALL','ATTR_MGR','CACHE_MGR','PLP$CHECK',
'CLASS_MGR','CLASS_UTILS','CONSTANT','PLP$CURSOR','DATA_VIEWS',
'DICT_MGR','EDOC_GEN','EXECUTOR','FORMS_MGR','INDEX_MGR',
'INST_INFO','LIB','LOCK_INFO','MAPEX_MGR','MESSAGE','METHOD_MGR',
'METHOD', 'OPT_MGR','PART_MGR','PLIB','RTL','SECADMIN',
'STDIO','STORAGE_UTILS','STORAGE_MGR','SVIEWS','VALMGR');
  for i in 1..t.count loop
    begin
      execute immediate 'alter package '||t(i)||' compile body';
      dbms_output.put_line(t(i)||': altered');
    exception when others then
      dbms_output.put_line(t(i)||': '||substr(sqlerrm,1,220));
    end;
  end loop;
end;
/

variable err_count number
column xxx new_value err_count noprint

select count(1) xxx from user_errors where name in
('PLP2PLSQL','AFTER_INSTALL','ATTR_MGR','CACHE_MGR','PLP$CHECK',
'CLASS_MGR','CLASS_UTILS','CONSTANT','PLP$CURSOR','DATA_VIEWS',
'DICT_MGR','EDOC_GEN','EXECUTOR','FORMS_MGR','INDEX_MGR',
'INST_INFO','LIB','LOCK_INFO','MAPEX_MGR','MESSAGE','METHOD_MGR',
'METHOD', 'OPT_MGR','PART_MGR','PLIB','RTL','SECADMIN',
'STDIO','STORAGE_UTILS','STORAGE_MGR','SVIEWS','VALMGR')
and rownum=1;
exec :err_count:= &&err_count;


column err_text format A100 WRAPPED TRUNC
break on name
select name, '(' || line || ',' || position || ') ' || rtrim(text,chr(10)) err_text from user_errors where name in
('PLP2PLSQL','AFTER_INSTALL','ATTR_MGR','CACHE_MGR','PLP$CHECK',
'CLASS_MGR','CLASS_UTILS','CONSTANT','PLP$CURSOR','DATA_VIEWS',
'DICT_MGR','EDOC_GEN','EXECUTOR','FORMS_MGR','INDEX_MGR',
'INST_INFO','LIB','LOCK_INFO','MAPEX_MGR','MESSAGE','METHOD_MGR',
'METHOD', 'OPT_MGR','PART_MGR','PLIB','RTL','SECADMIN',
'STDIO','STORAGE_UTILS','STORAGE_MGR','SVIEWS','VALMGR')
order by name,type,sequence;

variable rec_count number
column plp$parser_info_cnt new_value rec_count
select count(1) plp$parser_info_cnt from plp$parser_info;
exec :rec_count:= &&rec_count;

spool off

clear breaks

@@exit_when ':err_count>0 or :rec_count=0'






