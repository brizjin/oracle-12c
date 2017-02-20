spool segment_tables.log

set serveroutput on size 100000

@..\..\settings

def TUSERS='&&UP_TUSERS'
def TSPACEI='&&UP_TSPACEI'

prompt dropping tables;
drop table rtl_locks;
drop table frm_locks;
drop table rtl_users;

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
 SEGMENT CREATION IMMEDIATE NOCOMPRESS NOLOGGING
 TABLESPACE &&TUSERS
 partition by list (instance)
(
partition inst_0 values (0),
partition inst_1 values (1),
partition inst_2 values (2),
partition inst_3 values (3)
);

prompt creating rtl_users constraints
ALTER TABLE rtl_users ADD
    CONSTRAINT pk_rtl_users_id PRIMARY KEY (id)
        USING INDEX TABLESPACE &&TSPACEI;


prompt creating table frm_locks
CREATE TABLE frm_locks
 (
    obj_id   varchar2(128),
    class_id varchar2(16),
    user_id  number  not null,
    user_sid number,
    obj_scn  number,
    time     date,
    info     varchar2(256),
    einfo    varchar2(512),
    CONSTRAINT FKP_frm_locks_id FOREIGN KEY (USER_ID) REFERENCES IBS.RTL_USERS(ID)
 )
 SEGMENT CREATION IMMEDIATE NOCOMPRESS LOGGING
 TABLESPACE &&TUSERS CACHE 
    partition by reference (FKP_frm_locks_id);


prompt creating frm_locks.user_id index
CREATE INDEX idx_frm_locks_user_id ON frm_locks ( user_id  ) 
	TABLESPACE &&TSPACEI pctfree 50 initrans 20 maxtrans 255;

prompt creating frm_locks constraints
ALTER TABLE frm_locks ADD
    CONSTRAINT pk_frm_locks_obj_id PRIMARY KEY (obj_id)
        USING INDEX TABLESPACE &&TSPACEI reverse
	pctfree 50 initrans 20 maxtrans 255;

prompt alter table frm_locks enable row movement
ALTER TABLE FRM_LOCKS ENABLE ROW MOVEMENT;


prompt creating table rtl_locks
CREATE TABLE rtl_locks
 (
    id      number,
    user_id number not null,
    time    date,
    object  varchar2(128),
    subject varchar2(16),
    info    varchar2(256),
    CONSTRAINT FKP_rtl_locks_id FOREIGN KEY (USER_ID) REFERENCES IBS.RTL_USERS(ID)
 )
 SEGMENT CREATION IMMEDIATE NOCOMPRESS LOGGING
 TABLESPACE &&TUSERS CACHE 
    partition by reference (FKP_rtl_locks_id);

prompt creating rtl_locks constraints
ALTER TABLE rtl_locks ADD
    CONSTRAINT pk_rtl_locks_id PRIMARY KEY (id)
        USING INDEX TABLESPACE &&TSPACEI reverse
	pctfree 50 initrans 20 maxtrans 255;

prompt creating rtl_locks.user_id index
CREATE INDEX idx_rtl_locks_user_id ON ibs.rtl_locks (user_id) 
	TABLESPACE &&TSPACEI pctfree 50 initrans 20 maxtrans 255;


spool off
exit
