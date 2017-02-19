rem **************************************************************************
rem Ликвидированные реквизиты, необходимо перестроить таблицы
rem **************************************************************************

store set defaultenv replace

host md log

spool log\cl_del_columns.log
set feedback off
set heading off
set newpage 0
set pagesize 0
set echo off
set verify off
set serveroutput on size 1000000
set arraysize 1
set trimspool on
set trimout on


prompt _Ликвидированные реквизиты, необходимо перестроить таблицы
prompt;
select rpad(class_id,16) Класс, rpad(qual,20) Реквизит,  rpad(self_class_id,16) Тип_реквизита 
  from class_tab_columns where deleted=1 order by class_id;
prompt;
prompt _Надо перестроить таблицы классов ; 
prompt;
select rpad(class_id,16) Класс from class_tab_columns where deleted=1 group by class_id;
prompt ____________________________________________________________________________;
prompt;
prompt _Реквизит был преобразован в функциональный, необходимо перестроить таблицы
prompt;
select rpad(c_tab_col.class_id,16) Класс, rpad(u_tab_col.column_name,20) Реквизит from class_tab_columns c_tab_col, class_attributes c_attr, user_tab_columns u_tab_col
 where c_attr.REQUIRED = 'A' and c_tab_col.class_id = c_attr.class_id 
    and c_tab_col.qual = c_attr.attr_id and u_tab_col.table_name = c_tab_col.table_name and u_tab_col.column_name = c_tab_col.column_name order by c_tab_col.class_id;
prompt;
prompt _Надо перестроить таблицы классов ; 
prompt;
select distinct rpad(c_tab_col.class_id,16) Класс from class_tab_columns c_tab_col, class_attributes c_attr, user_tab_columns u_tab_col
 where c_attr.REQUIRED = 'A' and c_tab_col.class_id = c_attr.class_id 
    and c_tab_col.qual = c_attr.attr_id and u_tab_col.table_name = c_tab_col.table_name and u_tab_col.column_name = c_tab_col.column_name order by Класс;

spool off

@defaultenv
host del defaultenv.sql
