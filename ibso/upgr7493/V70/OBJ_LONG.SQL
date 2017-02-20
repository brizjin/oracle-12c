-- Table LONG_DATA
alter trigger LONG_DATA_AFTER_UPD disable;

alter table long_data nologging;

alter table long_data add old$obj varchar2(128);

var n number;
var nn number;
begin
  :n := 0;
  update long_data set old$obj=object_id;
  :n := sql%rowcount;
end;
/

print n

drop index idx_long_data_object_id;
alter table long_data drop constraint nn_long_data_object_id;

begin
  :nn := 0;
  if :n>0 then
    update long_data set object_id = null;
    :nn := sql%rowcount;
  end if;
end;
/

print nn

alter table long_data modify object_id varchar2(128);

begin
  :nn := 0;
  if :n>0 then
    update long_data set object_id = old$obj;
    :nn := sql%rowcount;
  end if;
end;
/

print nn

CREATE  INDEX idx_long_data_object_id
 ON long_data( object_id  ) TABLESPACE &&tspacei NOLOGGING;

alter table long_data add constraint nn_long_data_object_id
  CHECK(OBJECT_ID IS NOT NULL);

alter trigger LONG_DATA_AFTER_UPD enable;
alter table long_data logging;
alter index idx_long_data_object_id logging;

