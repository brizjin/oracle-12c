set echo on

-- Create table
create table PRINTER_TYPES
(
  ID             VARCHAR2(16),
  DRIVER_NAME    VARCHAR2(128),
  DESCRIPTION    VARCHAR2(2000)
)
  tablespace &&TUSERS
  pctfree 5
  pctused 50
  initrans 1
  maxtrans 255
  storage
  (
    initial 128K
    next 128K
    minextents 1
    maxextents unlimited
    pctincrease 0
  );

create unique index PK_PRINTER_TYPES on PRINTER_TYPES (ID)
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

create unique index UNQ_PRINTER_TYPES_NAME on PRINTER_TYPES (DRIVER_NAME)
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

alter table PRINTER_TYPES
  add constraint PK_PRINTER_TYPES primary key (ID);

create table PRINTER_MACROS
(
  ID             VARCHAR2(16),
  MACRO_NAME     VARCHAR2(128),
  DESCRIPTION    VARCHAR2(2000)
)
  tablespace &&TUSERS
  pctfree 5
  pctused 50
  initrans 1
  maxtrans 255
  storage
  (
    initial 128K
    next 128K
    minextents 1
    maxextents unlimited
    pctincrease 0
  );

create unique index PK_PRINTER_MACROS on PRINTER_MACROS (ID)
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

create unique index UNQ_PRINTER_MACROS_NAME on PRINTER_MACROS (MACRO_NAME)
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

alter table PRINTER_MACROS
  add constraint PK_PRINTER_MACROS primary key (ID);

create table MACRO_VALUES
(
  DRIVER_ID    VARCHAR2(16),
  MACRO_ID     VARCHAR2(16),
  VALUE          VARCHAR2(2000)
)
  tablespace &&TUSERS
  pctfree 5
  pctused 50
  initrans 1
  maxtrans 255
  storage
  (
    initial 128K
    next 128K
    minextents 1
    maxextents unlimited
    pctincrease 0
  );

create unique index PK_MACRO_VALUES on MACRO_VALUES (DRIVER_ID,MACRO_ID)
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

create index IDX_MACRO_VALUES_MACRO_ID on MACRO_VALUES (MACRO_ID)
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

alter table MACRO_VALUES
  add constraint PK_MACRO_VALUES primary key (DRIVER_ID,MACRO_ID);

alter table MACRO_VALUES
  add constraint FK_MACRO_VALUES_DRIVER_ID foreign key (DRIVER_ID)
  references PRINTER_TYPES(ID) on delete cascade;

alter table MACRO_VALUES
  add constraint FK_MACRO_VALUES_MACRO_ID foreign key (MACRO_ID)
  references PRINTER_MACROS(ID) on delete cascade;

set echo off

column xxx new_value oxxx noprint
select user xxx from dual;

prompt Additional Grants for Roles

grant all on PRINTER_TYPES to &&oxxx._ADMIN;
grant all on PRINTER_MACROS to &&oxxx._ADMIN;
grant all on MACRO_VALUES to &&oxxx._ADMIN;

grant select on PRINTER_TYPES to &&oxxx._USER;
grant select on PRINTER_MACROS to &&oxxx._USER;
grant select on MACRO_VALUES to &&oxxx._USER;