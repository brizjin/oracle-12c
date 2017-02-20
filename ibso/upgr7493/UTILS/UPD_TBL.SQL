rem UNDEF TUSERS
rem UNDEF TSPACEI

prompt stopping LOCK_INFO
exec lock_info.stop
exec lock_info.stop

set echo on

prompt enabling system constraints
alter table classes enable primary key;
alter table methods enable primary key;
alter table methods enable unique(package_name);
alter table methods enable unique(class_id,short_name);
alter table methods enable constraint fk_methods_class_id;

prompt class_relations constraints
alter table class_relations drop constraint NN_CLS_REL_CHILD_ID;
alter table class_relations drop constraint NN_CLS_REL_PARENT_ID;
alter table class_relations drop constraint NN_CLS_REL_DISTANCE;
alter table class_relations drop constraint UNQ_CLS_REL_CHLD_DIST;
alter table class_relations drop constraint UNQ_CLS_REL_PRNT_DIST_CHILD;
alter table class_relations drop primary key;
drop index PK_CLS_REL_CHILD_PARENT;
drop index UNQ_CLS_REL_CHLD_DIST;
drop index UNQ_CLS_REL_PRNT_DIST_CHILD;
alter table class_relations modify distance constraint NN_CLS_REL_DISTANCE not null;
create unique index PK_CLS_REL_CHILD_PARENT
  on class_relations(child_id,parent_id) tablespace &&TSPACEI;
alter table class_relations
  add constraint PK_CLS_REL_CHILD_PARENT primary key(child_id,parent_id);
create unique index UNQ_CLS_REL_CHLD_DIST
  on class_relations(child_id,distance,parent_id) tablespace &&TSPACEI;
alter table class_relations
  add constraint UNQ_CLS_REL_CHLD_DIST unique(child_id,distance,parent_id)
  using index UNQ_CLS_REL_CHLD_DIST;
create unique index UNQ_CLS_REL_PRNT_DIST_CHILD
  on class_relations(parent_id,distance,child_id) tablespace &&TSPACEI;
alter table class_relations
  add constraint UNQ_CLS_REL_PRNT_DIST_CHILD unique(parent_id,distance,child_id)
  using index UNQ_CLS_REL_PRNT_DIST_CHILD;
  
prompt methods constraints
alter table methods modify (accessibility default '0');

prompt method_parameters constraints
alter table method_parameters add flag varchar2(1) default 'D';
update method_parameters set flag='D' where flag is null;
alter table method_parameters drop constraint chk_mp_direction;
alter table method_parameters drop constraint nn_mp_direction;
alter table method_parameters drop constraint nn_mp_method_id;
alter table method_parameters drop constraint nn_mp_position;
alter table method_parameters
  add constraint chk_mp_direction check(DIRECTION is not null and DIRECTION in ('I','O','B','D'));
alter table method_parameters
  add constraint chk_mp_flag check(FLAG is not null and FLAG in ('D','T','R'));

prompt method_variables constraints
alter table method_variables add flag varchar2(1) default 'D';
update method_variables set flag='D' where flag is null;
alter table method_variables drop constraint nn_meth_var_method_id;
alter table method_variables drop constraint nn_meth_var_position;
alter table method_variables
  add constraint chk_meth_var_flag check(FLAG is not null and FLAG in ('D','T','R'));

prompt messages constraint
alter table messages drop constraint NN_MESSAGES_CODE;
alter table messages drop constraint NN_MESSAGES_TOPIC;
alter table messages drop primary key &&D_DROPINDEX;
alter table messages
  add constraint pk_messages_topic_code primary key(topic,code)
  using index tablespace &&TSPACEI;

SET SERVEROUTPUT ON

prompt dropping tables;
drop table plp$parser_info;
drop table rtl_users;
drop table rtl_locks;
drop table rtl_events;
drop table frm_locks;

prompt creating table plp$parser_info
create table plp$parser_info (
    array   varchar2(10), idx number, value   number
     ) tablespace &&TUSERS ;

prompt creating table rtl_users
CREATE TABLE rtl_users
 (
    id          number,
    instance    number,
    sid         number,
    os_user     varchar2(30),
    ora_user    varchar2(30),
    username    varchar2(64),
    info        varchar2(128),
    logontime   date,
    userid      number,
    host_sid    varchar2(1024),
    host_name   varchar2(1024)
 )
 TABLESPACE &&TUSERS NOLOGGING;

prompt creating rtl_users constraints
ALTER TABLE rtl_users ADD
    CONSTRAINT pk_rtl_users_id PRIMARY KEY (id)
        USING INDEX TABLESPACE &&TSPACEI;

prompt creating table rtl_locks
CREATE TABLE rtl_locks
 (
    id      number,
    user_id number,
    time    date,
    object  varchar2(128),
    subject varchar2(16),
    info    varchar2(256)
 )
 TABLESPACE &&TUSERS  NOLOGGING;

prompt creating rtl_locks constraints
ALTER TABLE rtl_locks ADD
    CONSTRAINT pk_rtl_locks_id PRIMARY KEY (id)
        USING INDEX TABLESPACE &&TSPACEI NOLOGGING;

CREATE INDEX idx_rtl_locks_user_id ON rtl_locks ( user_id  )
    TABLESPACE &&TSPACEI NOLOGGING;

prompt creating table rtl_events
create table rtl_events
(
    instance  number,
    time      date,
    id        number,
    user_id   number,
    post_id   number,
    post_sid  number,
    event     varchar2(4000)
) tablespace &&tusers NOLOGGING;

prompt creating rtl_events indexes
create index idx_rtl_events_instance_time
    on rtl_events(instance,time) tablespace &&tspacei NOLOGGING;

create index idx_rtl_events_user_id
    on rtl_events(user_id) tablespace &&tspacei NOLOGGING;

prompt creating table frm_locks
CREATE TABLE frm_locks
 (
    obj_id   varchar2(128),
    class_id varchar2(16),
    user_id  number,
    user_sid number,
    obj_scn  number,
    time     date,
    info     varchar2(256),
    einfo    varchar2(512)
 )
 TABLESPACE &&TUSERS NOLOGGING;

prompt creating frm_locks constraints
ALTER TABLE frm_locks ADD
    CONSTRAINT pk_frm_locks_obj_id PRIMARY KEY (obj_id)
        USING INDEX TABLESPACE &&TSPACEI NOLOGGING;

CREATE INDEX idx_frm_locks_user_id ON frm_locks ( user_id  )
    TABLESPACE &&TSPACEI NOLOGGING;

prompt Deleting from rtl_entries
delete from rtl_entries where not exists
  (select 1 from methods where id=method_id);
delete from rtl_entries where id<1001 and id >-1 and method_id<>'STDLIB';
commit;

prompt Deleting from rtl_parameters
delete from rtl_parameters where not exists
  (select 1 from rtl_entries where rtl_id=id);
delete from rtl_parameters where rtl_id<1001 and rtl_id >-1 
   and not exists(select 1 from rtl_entries where id=rtl_id and method_id='STDLIB');
commit;

prompt Updating rtl_parameters

update rtl_parameters
 set flag = 'R',
     class_id = 'USER'
where rtl_id<1001 and rtl_id>-1001 and flag='D' and class_id='USER_REF';

update rtl_parameters
 set flag = 'D'
where flag='R' and class_id like 'BIN%' and rtl_id in
 (select id from rtl_entries where method_id='PL_SQL' and name like 'DBMS_SQL.%');

commit;

prompt Deleting from messages
delete from messages where topic<>'TIP';
commit;

prompt Deleting from project
delete from project where type in ('PACKAGE','SEQUENCE','TABLE','FUNCTION','PROCEDURE');
commit;

prompt saving rtl_entries, rtl_parameters
drop table rtl$parameters;
drop table rtl$entries;
create table rtl$entries nologging as select * from rtl_entries where 1=2;
create table rtl$parameters nologging as select * from rtl_parameters where 1=2;
insert /*+ APPEND */ into rtl$entries select * from rtl_entries;
insert /*+ APPEND */ into rtl$parameters select * from rtl_parameters;
drop table rtl_parameters;
drop table rtl_entries;

prompt creating table rtl_entries
CREATE TABLE rtl_entries
 (
  id                         NUMBER,
  method_id                  VARCHAR2(16),
  name                       VARCHAR2(100),
  type                       VARCHAR2(1),
  params                     NUMBER DEFAULT 0,
  features                   VARCHAR2(10)
 ) NOLOGGING
 TABLESPACE &&TUSERS;
COMMENT ON TABLE rtl_entries IS 'Entry points for PL/PLUS visibility';

prompt creating table rtl_parameters
CREATE TABLE rtl_parameters
 (
  rtl_id                     NUMBER,
  pos                        NUMBER,
  par_name                   VARCHAR2(100),
  dir                        VARCHAR2(1),
  flag                       VARCHAR2(1),
  class_id                   VARCHAR2(30),
  siz                        NUMBER,
  prec                       NUMBER
 ) NOLOGGING
 TABLESPACE &&TUSERS;
COMMENT ON TABLE rtl_parameters IS 'Parameters definitions for RTL_ENTRIES';

prompt restoring rtl_entries, rtl_parameters
insert /*+ APPEND */ into rtl_entries select * from rtl$entries;
insert /*+ APPEND */ into rtl_parameters select * from rtl$parameters;
drop table rtl$entries;
drop table rtl$parameters;

prompt creating rtl_entries constraints
ALTER TABLE rtl_entries LOGGING;
ALTER TABLE rtl_entries ADD
    CONSTRAINT pk_rtl_entries_id PRIMARY KEY (id)
        USING INDEX TABLESPACE &&TSPACEI NOLOGGING;
ALTER INDEX pk_rtl_entries_id LOGGING;
ALTER TABLE rtl_entries MODIFY method_id
    CONSTRAINT nn_rtl_entries_method_id NOT NULL;
ALTER TABLE rtl_entries MODIFY name
    CONSTRAINT nn_rtl_entries_name NOT NULL;

prompt index idx_rtl_entries_method_id_name
CREATE INDEX idx_rtl_entries_method_id_name ON rtl_entries ( method_id, name )
    TABLESPACE &&TSPACEI NOLOGGING;
ALTER INDEX idx_rtl_entries_method_id_name LOGGING;

prompt creating rtl_parameters constraints
ALTER TABLE rtl_parameters LOGGING;
ALTER TABLE rtl_parameters ADD
    CONSTRAINT pk_rtl_params_rtl_id_pos PRIMARY KEY(rtl_id,pos)
        USING INDEX TABLESPACE &&TSPACEI NOLOGGING;
ALTER INDEX pk_rtl_params_rtl_id_pos LOGGING;


prompt creating table update_journal
prompt 
begin
execute immediate 
'CREATE TABLE update_journal
 (
  id			NUMBER,
  is_before		VARCHAR2(1),
  priority		NUMBER,
  type_error		VARCHAR2(1),
  status		VARCHAR2(1),
  run_date		DATE,
  version		VARCHAR2(24),
  action_name		VARCHAR2(100),
  script		VARCHAR2(4000)
 ) NOLOGGING
 TABLESPACE &&TUSERS';
exception when others then
	if SQLCODE <> -955 then	
    	raise; 
	end if;
end;
/

prompt creating update_journal constraints
prompt 
begin
execute immediate 
'ALTER TABLE update_journal ADD 
	CONSTRAINT pk_update_journal_id PRIMARY KEY (id)
		USING INDEX TABLESPACE &&TSPACEI NOLOGGING';
exception when others then
	if SQLCODE <> -2260 then
		raise; 
	end if;
end;
/

set echo off
rem UNDEF TUSERS
rem UNDEF TSPACEI

