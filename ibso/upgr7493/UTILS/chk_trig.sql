set serveroutput on
declare
  procedure check_trigger(p_name varchar2) is
    s varchar2(100);
  begin
    select status into s from user_objects where object_name=p_name;
    if s<>'VALID' then
      dbms_output.put_line(p_name||' - '||s);
      begin
        execute immediate 'alter trigger '||p_name||' compile';
      exception when others then null;
      end;
      select status into s from user_objects where object_name=p_name;
    end if;
    if s='VALID' then
      dbms_output.put_line(p_name||' - OK');
    else
      begin
        execute immediate 'drop trigger '||p_name;
        dbms_output.put_line(p_name||' - dropped');
      exception when others then null;
      end;
    end if;
  exception when no_data_found then null;
  end;
begin
  check_trigger('SETTINGS_CHANGES');
  check_trigger('PROFILES_CHANGES');
end;
/

