drop trigger calendar_changes;
drop trigger calendars_changes;

alter table calendars add id number;
alter table calendars add status varchar2(16);

update calendars set id = seq_id.nextval;
update calendars set status = 'NOT COMPILED';

alter table calendars modify id null;
alter table calendars modify status null;

alter table calendars modify id constraint nn_calendars_id not null;
alter table calendars modify status constraint nn_calendars_status not null;

alter table calendars
add constraint unq_calendars_id unique (id)
using index
  pctfree     10
  initrans    2
  maxtrans    255
  tablespace &&TSPACEI
/

drop INDEX idx_calendar_value_name;
drop INDEX idx_calendar_value_all;
CREATE INDEX idx_calendar_value_all
 ON calendar_value
  ( calendar_name, value, type )
  PCTFREE    10
  INITRANS   2
  MAXTRANS   255
  tablespace &&TSPACEI
/

drop package calendar;
