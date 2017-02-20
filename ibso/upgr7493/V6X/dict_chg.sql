set echo on

-- Create table
create table DICT_CHANGES
(
  MDATE       DATE,
  OBJ_TYPE    VARCHAR2(30),
  OBJ_ID      VARCHAR2(30),
  CHANGE_TYPE VARCHAR2(30)
)
  tablespace &&TUSERS
  pctfree 5
  pctused 50
  initrans 1
  maxtrans 255
  storage
  (
    initial 256K
    next 256K
    minextents 1
    maxextents unlimited
    pctincrease 0
  );

-- Create/Recreate indexes
create index IDX_DICT_CHANGES_MDATE on DICT_CHANGES (MDATE)
  tablespace &&TSPACEI
  pctfree 5
  initrans 2
  maxtrans 255
  storage
  (
    initial 128K
    next 128K
    minextents 1
    maxextents unlimited
    pctincrease 0
  );

create unique index PK_DICT_CHANGES on DICT_CHANGES (OBJ_TYPE,OBJ_ID,CHANGE_TYPE)
  tablespace &&TSPACEI
  pctfree 5
  initrans 2
  maxtrans 255
  storage
  (
    initial 256K
    next 256K
    minextents 1
    maxextents unlimited
    pctincrease 0
  );

-- Create/Recreate constraints
alter table DICT_CHANGES
  add constraint PK_DICT_CHANGES primary key (OBJ_TYPE,OBJ_ID,CHANGE_TYPE);

alter table DICT_CHANGES
  add constraint NN_DICT_CHANGES_MDATE
  check (MDATE IS NOT NULL);

set echo off
