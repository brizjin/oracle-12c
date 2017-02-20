exec stdio.put_line_buf('Updating compiler property...')
begin
  if nvl(to_number('&&v_version','999.9'),1)<6.5 then
    patch_tool.update_compiler;
    commit;
  end if;
end;
/

exec stdio.put_line_buf('Checking hash values for classes...')
declare
  v varchar2(10);
begin
  if lib.v9_flag='0' then
    v := 'NO';
    for c in (
      select dbms_utility.get_hash_value(id,0,2147483647),count(1) from classes
       group by dbms_utility.get_hash_value(id,0,2147483647)
       having count(1)>1
    ) loop
      v := 'YES';  exit;
    end loop;
    stdio.put_setting('PLP_CACHE_CHECK',v,'Признак проверки кэша словаря в пакете LIB');
  end if;
end;
/

prompt Updating Not_Cached flag for System Columns
update class_tab_columns set not_cached='0'
 where mapped_from='OBJECT' and nvl(not_cached,'1')<>'0';
commit;

exec stdio.put_line_buf('Updating controls properties...')
begin
  if nvl(to_number('&&v_version','999.9'),1)<6.6 then
    patch_tool.update_controls_props;
    commit;
  end if;
end;
/

