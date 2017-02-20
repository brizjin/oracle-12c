set echo on

insert into users(username,name)
values('%SYSTEM%','System Menu');

alter table FAVORITES add
(
  METHOD_ID     VARCHAR2(16),
  PARENT_ID     VARCHAR2(16),
  POSITION      NUMBER
)
/

create unique index PK_FAVORITES_ID on FAVORITES (ID)
  tablespace &&tspacei
/

create index IDX_FAVORITES_CLASS_ID on FAVORITES (CLASS_ID)
  tablespace &&tspacei
/

create index IDX_FAVORITES_CRITERION_ID on FAVORITES (CRITERION_ID)
  tablespace &&tspacei
/

create index IDX_FAVORITES_METHOD_ID on FAVORITES (METHOD_ID)
  tablespace &&tspacei
/

create index IDX_FAVORITES_PARENT_ID on FAVORITES (PARENT_ID)
  tablespace &&tspacei
/

create index IDX_FAVORITES_USERNAME on FAVORITES (USERNAME)
  tablespace &&tspacei
/

alter table FAVORITES
  add constraint PK_FAVORITES_ID primary key (ID);

alter table FAVORITES
  add constraint FK_FAVORITES_CLASS_ID foreign key (CLASS_ID)
  references CLASSES (ID) on delete cascade;

alter table FAVORITES
  add constraint FK_FAVORITES_CRITERION_ID foreign key (CRITERION_ID)
  references CRITERIA (ID) on delete cascade;

alter table FAVORITES
  add constraint FK_FAVORITES_METHOD_ID foreign key (METHOD_ID)
  references METHODS (ID) on delete cascade;

alter table FAVORITES
  add constraint FK_FAVORITES_PARENT_ID foreign key (PARENT_ID)
  references FAVORITES (ID) on delete cascade;

delete from favorites f where not exists
  (select 1 from users u where u.username=f.username);

alter table FAVORITES
  add constraint FK_FAVORITES_USERNAME foreign key (USERNAME)
  references USERS (USERNAME) on delete cascade;

alter table FAVORITES
  add constraint NN_FAVORITES_NAME
  check (NAME IS NOT NULL);

alter table FAVORITES
  add constraint NN_FAVORITES_USERNAME
  check (USERNAME IS NOT NULL);

alter table METHOD_GROUPS add
(
  PARENT_ID VARCHAR2(16),
  POSITION  NUMBER
)
/

alter table METHOD_GROUP_MEMBERS add
(
  POSITION  NUMBER
)
/

create unique index PK_METHOD_GROUPS_ID on METHOD_GROUPS (ID)
  tablespace &&tspacei
/

create index IDX_METHOD_GROUPS_CLASS_ID on METHOD_GROUPS (CLASS_ID)
  tablespace &&tspacei
/

create index IDX_METHOD_GROUPS_PARENT_ID on METHOD_GROUPS (PARENT_ID)
  tablespace &&tspacei
/

create index IDX_METHOD_GROUPS_USERNAME on METHOD_GROUPS (USERNAME)
  tablespace &&tspacei
/

alter table METHOD_GROUPS
  add constraint PK_METHOD_GROUPS_ID primary key (ID);

alter table METHOD_GROUPS
  add constraint FK_METHOD_GROUPS_PARENT_ID foreign key (PARENT_ID)
  references METHOD_GROUPS (ID) on delete cascade;

alter table METHOD_GROUPS drop constraint FK_METH_GRP_CLASS_ID;

alter table METHOD_GROUPS
  add constraint FK_METHOD_GROUPS_CLASS_ID foreign key (CLASS_ID)
  references CLASSES (ID) on delete cascade;

alter table METHOD_GROUPS drop constraint FK_METH_GRP_USER_NAME;

alter table METHOD_GROUPS
  add constraint FK_METH_GROUPS_USERNAME foreign key (USERNAME)
  references USERS (USERNAME) on delete cascade;

alter table METHOD_GROUPS
  add constraint NN_METHOD_GROUPS_NAME
  check (Name IS NOT NULL);

create table CRITERIA_METHODS
(
  CRITERION_ID VARCHAR2(16),
  METHOD_ID    VARCHAR2(16)
)
  tablespace &&tusers
/

create index IDX_CRITERIA_METHODS_CRIT_ID on CRITERIA_METHODS (CRITERION_ID)
  tablespace &&tspacei
/

create index IDX_CRITERIA_METHODS_METHOD_ID on CRITERIA_METHODS (METHOD_ID)
  tablespace &&tspacei
/

alter table CRITERIA_METHODS
  add constraint FK_CRITERIA_METHODS_CRIT_ID foreign key (CRITERION_ID)
  references CRITERIA (ID) on delete cascade;

alter table CRITERIA_METHODS
  add constraint FK_CRITERIA_METHODS_METHOD_ID foreign key (METHOD_ID)
  references METHODS (ID) on delete cascade;

alter table CRITERIA_METHODS
  add constraint NN_CRITERIA_METHODS_CRIT_ID
  check (CRITERION_ID IS NOT NULL);

alter table CRITERIA_METHODS
  add constraint NN_CRITERIA_METHODS_METHOD_ID
  check (METHOD_ID IS NOT NULL);

set echo off

