set echo on

CREATE GLOBAL TEMPORARY TABLE LCONV (R ROWID, B BLOB, C CLOB)
    ON COMMIT DELETE ROWS;

CREATE UNIQUE INDEX UNQ_LCONV_R ON LCONV(R);


ALTER TABLE LONG_DATA DROP CONSTRAINT FK_LONG_DATA_CLASS_ID;

alter table lraw add bdata blob;
alter table &&downer1..long_data add bdata blob;
alter table &&downer1..orsa_jobs_out add bdata blob;

set echo  off

var mes varchar2(2000)

begin
  :mes := null;
  for c in (
    select trigger_name from user_triggers
     where table_name in ('LRAW','LONG_DATA','ORSA_JOBS_OUT')
  ) loop
    begin
      execute immediate 'drop trigger '||c.trigger_name;
      :mes := :mes||'Trigger '||c.trigger_name||' dropped.'||chr(10);
    exception when others then
      :mes := :mes||'Drop '||c.trigger_name||' error: '||substr(sqlerrm,1,150)||chr(10);
    end;
  end loop;
end;
/

print mes


