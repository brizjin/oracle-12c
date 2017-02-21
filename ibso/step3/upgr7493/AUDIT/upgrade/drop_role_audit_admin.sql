-- PLATFORM-3603. ¬ св€зи в по€влением в Oracle 12с системной роли с именем 'AUDIT_ADMIN',
-- переименовали прикладную роль в 'AUD_REVISOR' - т.е. создали новую роль с теми же правами, а старую нужно удалить.
-- ѕараметр s - '1' - пересоздаем роль с новым именем, '0' - не пересоздаем.
set verify off
declare
  n number;
  role_name varchar2(20) := 'AUDIT_ADMIN';
  s varchar(1) := &1;
begin 
    select count(username) into n from user_role_privs
     where granted_role = role_name;
    -- ≈сли прикладна€ роль 'AUDIT_ADMIN' существует, то удалим еЄ
    if (n > 0) then
      begin
        execute immediate 'DROP ROLE ' || role_name;
        dbms_output.put_line('DROP ROLE ' || role_name || ' - OK');
      exception when others then 
        dbms_output.put_line('DROP ROLE '||role_Name||' - '||sqlerrm);
      end;
      -- Cоздаем роль 'AUD_REVISOR', раздаем созданную роль
      if (s = '1') then
      	utils.roles;
      end if;
    end if;
end;
/