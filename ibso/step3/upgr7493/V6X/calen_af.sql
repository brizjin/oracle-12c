drop trigger calendar_changes;
drop trigger calendars_changes;

update calendars set rule = rtl.safe_replace(rule, 'z$runtime_calendar.', 'calendar.');
update calendars set rule = rtl.safe_replace(rule, 'calendar.', 'z$runtime_calendar.');

exec patch_tool.unregister_calendar;

create or replace trigger calendar_changes
    before insert or delete or update of rule on calendars
    referencing new as new old as old for each row
begin
  if inserting or
    updating and nvl(:old.rule, '-') <> nvl(:new.rule, '-')
  then
    :new.status := 'NOT COMPILED';
  end if;
  if inserting and :new.id is null then
    select seq_id.nextval into :new.id from dual;
  end if;
end;
/
create or replace trigger calendars_changes
    after insert or delete or update of rule on calendars
begin
  calendar_mgr.update_cache_event('');
end;
/
create or replace trigger calendar_values_changes
    after insert or delete on calendar_value
begin
  calendar_mgr.update_cache_event('');
end;
/

exec calendar_mgr.Build_Calendar_Rules_Iface
begin
  calendar_mgr.Build_Calendar_Rules_Body;
exception when others then
  null;
end;
/
