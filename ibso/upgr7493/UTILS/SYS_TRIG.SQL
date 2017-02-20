spool sys_trig.log

prompt CREATE OR REPLACE TRIGGER BELONG_GROUPS_INS
CREATE OR REPLACE TRIGGER BELONG_GROUPS_INS
AFTER INSERT ON BELONG_GROUPS
BEGIN
 for xx in (
  select ID from BELONG_GROUPS g where not exists (
   select '1' from BELONG_GROUPS_EQUAL
   where Belong_Id=g.Id
   and Equal_Id=g.Id
  )
 )
 loop
  insert into BELONG_GROUPS_EQUAL (Belong_Id, Equal_Id)
  values (xx.ID, xx.ID);
 end loop;
END;
/
show err

prompt create or replace trigger calendar_changes
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
sho err

prompt create or replace trigger calendars_changes
create or replace trigger calendars_changes
    after insert or delete or update of rule on calendars
begin
  calendar_mgr.update_cache_event('');
end;
/
sho err

prompt create or replace trigger calendar_values_changes
create or replace trigger calendar_values_changes
    after insert or delete on calendar_value
begin
  calendar_mgr.update_cache_event('');
end;
/
sho err

prompt CREATE OR REPLACE TRIGGER classes_after_ins_tab
CREATE OR REPLACE TRIGGER classes_after_ins_tab
AFTER INSERT ON classes
DECLARE
 cursor cls is select id from classes
 where not exists (
  select parent_id from class_relations where parent_id = classes.id
  )
 ;
BEGIN
 for c in cls loop
  dict_mgr.update_class_relations(c.id);
 end loop;
END;
/
show err

prompt CREATE OR REPLACE TRIGGER criteria_prints_before
CREATE OR REPLACE TRIGGER criteria_prints_before
  BEFORE INSERT OR UPDATE OR DELETE ON criteria_prints FOR EACH ROW
DECLARE
    b boolean;
    u varchar2(30);
BEGIN
    b := true;
    u := rtl.USR;
    if u in (inst_info.owner,inst_info.gowner) or dbms_session.is_role_enabled(inst_info.owner||'_ADMIN') then
        b := false;
    elsif dbms_session.is_role_enabled(inst_info.owner||'_USER') then
        begin
            select '1' into u from users where username=u and instr(properties,'|SENIOR')>0;
            b := false;
        exception when no_data_found then null;
        end;
    end if;
    if b then
        Raise_Application_Error(-20999,'Нет прав на модификацию данных');
    end if;
END;
/
show err

prompt create or replace trigger long_data_before
create or replace trigger long_data_before
  before insert or update or delete on long_data for each row
declare
  c varchar2(30);
begin
  if deleting then
    c := :old.class_id;
  else
    c := :new.class_id;
  end if;
  if security.cls_accessible(c, rtl.usr) = '0' then
    raise_application_error(-20999,'Нет прав на модификацию данных');
  end if;
end;
/
show err

prompt CREATE OR REPLACE TRIGGER ins_upd_messages_before
CREATE OR REPLACE TRIGGER ins_upd_messages_before
BEFORE INSERT  OR UPDATE ON messages
FOR EACH ROW
begin
 if :new.code is NULL then
  select to_char(seq_id.nextval)
  into :new.code
  from dual;
 end if;
 :new.text := replace( rtrim(:new.text), '\n', chr(10) );
end;
/

prompt CREATE OR REPLACE TRIGGER orsa_jobs_before_ins_upd
CREATE OR REPLACE TRIGGER orsa_jobs_before_ins_upd
BEFORE INSERT OR UPDATE OF DATE_SCHEDULE,PRIORITY  ON orsa_jobs
FOR EACH ROW
BEGIN
  IF :NEW.DATE_SCHEDULE IS NULL THEN
    :NEW.DATE_SCHEDULE := SYSDATE;
  END IF;
  IF :NEW.PRIORITY IS NULL THEN
    :NEW.PRIORITY := 1;
  END IF;
END;
/
sho err

PROMPT CREATE OR REPLACE TRIGGER PROFILES_BEFORE_INS_UPD
CREATE OR REPLACE TRIGGER PROFILES_BEFORE_INS_UPD
BEFORE INSERT OR UPDATE OF PROFILE,RESOURCE_NAME ON PROFILES
FOR EACH ROW
Begin
  :new.profile := upper(:new.profile);
  :new.resource_name := upper(:new.resource_name);
End;
/
show err

prompt CREATE OR REPLACE TRIGGER ins_proj_before
CREATE OR REPLACE TRIGGER ins_proj_before
BEFORE INSERT ON project
FOR EACH ROW
BEGIN
  if :new.type like 'UPGRADE%' then null; else
    :new.crt_date:=sysdate;
    :new.crt_user:=user;
    :new.mod_date:=sysdate;
    :new.mod_user:=user;
  end if;
END;
/
show err

PROMPT CREATE OR REPLACE TRIGGER SETTINGS_BEFORE_INS_UPD
CREATE OR REPLACE TRIGGER SETTINGS_BEFORE_INS_UPD
BEFORE INSERT OR UPDATE OF NAME ON SETTINGS
FOR EACH ROW
Begin
  :new.name := upper(:new.name);
End;
/
show err

prompt CREATE OR REPLACE TRIGGER transitions_before_ins
CREATE OR REPLACE TRIGGER transitions_before_ins
BEFORE INSERT  OR UPDATE ON transitions
FOR EACH ROW
BEGIN
    IF :NEW.ID IS NULL THEN
      SELECT SEQ_ID.NEXTVAL INTO :NEW.ID FROM DUAL;
    END IF;
END;
/
show err

spool off

