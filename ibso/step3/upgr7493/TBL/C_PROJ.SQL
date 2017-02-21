spool c_proj.log

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

spool off

