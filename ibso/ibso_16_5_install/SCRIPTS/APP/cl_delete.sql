rem **************************************************************************
rem Список таблиц, классы которых удалены из прикладной части
rem Надо не забывать что также надо удалить интерфейсные пакеты этих классов 
rem **************************************************************************

store set defaultenv replace

host md log


set echo off
set termout off
set newpage 1
set heading off



set termout off

spool log\drop_tables_act.sql

select 'prompt _Необходимо удалить следующие Таблички' from dual;

select 'drop table ' || table_name || ';' from user_tables u where table_name like 'Z#%' 
		and not EXISTS (select 1 from classes c where 'Z#'||c.id = u.table_name)
		and not EXISTS (select 1 from class_tables ct where ct.log_table = u.table_name);

spool off 

spool log\drop_packages_act.sql

select 'prompt _Необходимо удалить следующие пакеты' from dual;

select 'drop package ' || object_name  || ';' from obj o where object_type = 'PACKAGE' and object_name like '%#INTERFACE'
        and not EXISTS (select 1 from classes c where 'Z#'||replace(trim(c.id),' ','#')||'#INTERFACE' = o.object_name);
spool off

@defaultenv
host del  defaultenv.sql
