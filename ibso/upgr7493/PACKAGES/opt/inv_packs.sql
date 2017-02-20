set timi on

alter system flush shared_pool;

prompt Invalidate package bodies
declare
  t dbms_sql.number_table;
  n pls_integer;
begin
  select object_id bulk collect into t from user_objects
   where object_type = 'PACKAGE BODY' and status = 'VALID';
  n := t.count;
  for i in 1 .. n loop
    dbms_utility.invalidate(t(i));
  end loop;
end;
/

alter system flush shared_pool;

prompt Invalidate kernel packages
declare
  t dbms_sql.number_table;
  n pls_integer;
begin
  select object_id bulk collect into t from user_objects
   where object_type='PACKAGE' and status = 'VALID' and object_name not like 'Z%'
     and object_name not in ('CONSTANT','RTL','MESSAGE','VALMGR','LIB','SECURITY','CACHE_MGR','STDIO');
  n := t.count;
  for i in 1 .. n loop
    dbms_utility.invalidate(t(i));
  end loop;
end;
/

prompt Invalidate base kernel packages
declare
  t dbms_sql.number_table;
  n pls_integer;
begin
  select object_id bulk collect into t from user_objects
   where object_type='PACKAGE' and status = 'VALID'
     and object_name in ('MESSAGE','VALMGR','LIB','SECURITY','CACHE_MGR','STDIO');
  n := t.count;
  for i in 1 .. n loop
    dbms_utility.invalidate(t(i));
  end loop;
end;
/

prompt Invalidate rtl/constant
declare
  t dbms_sql.number_table;
  n pls_integer;
begin
  select object_id bulk collect into t from user_objects
   where object_type='PACKAGE' and status = 'VALID'
     and object_name in ('CONSTANT','RTL')
   order by object_name desc;
  n := t.count;
  for i in 1 .. n loop
    dbms_utility.invalidate(t(i));
  end loop;
end;
/

alter system flush shared_pool;


