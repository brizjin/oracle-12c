--

create table SECURITY_DOMAINS (
    ID varchar2(32),
    PARENT_ID varchar2(32),
    APP_ID varchar2(32),
    NAME varchar2(100),
    REVISOR_GROUP varchar2(30)
)
TABLESPACE &&TUSERS;

alter table SECURITY_DOMAINS add REVISOR_GROUP varchar2(30);

create unique index PK_SECURITY_DOMAINS
    on SECURITY_DOMAINS
        ( ID )
    TABLESPACE &&TSPACEI;

create unique index UNQ_SECURITY_DOMAINS_APP_ID
    on SECURITY_DOMAINS
        ( APP_ID )
    TABLESPACE &&TSPACEI;

create index IDX_SECURITY_DOMAINS_PAR_ID
    on SECURITY_DOMAINS
        ( PARENT_ID )
    TABLESPACE &&TSPACEI;

create index IDX_SECURITY_DOMAINS_REV_GRP
    on SECURITY_DOMAINS
        ( REVISOR_GROUP )
    TABLESPACE &&TSPACEI;

alter table SECURITY_DOMAINS
    add constraint PK_SECURITY_DOMAINS primary key (ID);

alter table SECURITY_DOMAINS
    add constraint UNQ_SECURITY_DOMAINS_APP_ID unique (APP_ID);

alter table SECURITY_DOMAINS
    add constraint FK_SECURITY_DOMAINS_PAR_ID foreign key (PARENT_ID)
    references SECURITY_DOMAINS(ID) on delete cascade deferrable;

alter table SECURITY_DOMAINS
    add constraint FK_SECURITY_DOMAINS_REV_GRP foreign key (REVISOR_GROUP)
    references USERS(USERNAME);

--

create table SEC_DOMAIN_EQUALS (
    PARENT_ID varchar2(32),
    CHILD_ID varchar2(32)
)
TABLESPACE &&TUSERS;

create unique index PK_SEC_DOMAIN_EQUALS
    on SEC_DOMAIN_EQUALS
        ( PARENT_ID, CHILD_ID )
    TABLESPACE &&TSPACEI;

create unique index IDX_SDE_CHILD_PARENT
    on SEC_DOMAIN_EQUALS
        ( CHILD_ID, PARENT_ID )
    TABLESPACE &&TSPACEI;

alter table SEC_DOMAIN_EQUALS
    add constraint PK_SEC_DOMAIN_EQUALS primary key (PARENT_ID, CHILD_ID);

alter table SEC_DOMAIN_EQUALS
    add constraint FK_SEC_DOMAIN_EQUALS_PAR_ID foreign key (PARENT_ID)
    references SECURITY_DOMAINS(ID) on delete cascade deferrable;

alter table SEC_DOMAIN_EQUALS
    add constraint FK_SEC_DOMAIN_EQUALS_CHLD_ID foreign key (CHILD_ID)
    references SECURITY_DOMAINS(ID) on delete cascade deferrable;

--

create table SEC_DOMAIN_ENTRIES (
    USER_ID varchar2(30),
    DOMAIN_ID varchar2(32),
    UADMIN_PROPERTIES varchar2(2000)
)
TABLESPACE &&TUSERS;

create unique index PK_SEC_DOMAIN_ENTRIES
    on SEC_DOMAIN_ENTRIES
        ( USER_ID, DOMAIN_ID )
    TABLESPACE &&TSPACEI;

create unique index IDX_SDE_DOMAIN_USER
    on SEC_DOMAIN_ENTRIES
        ( DOMAIN_ID, USER_ID )
    TABLESPACE &&TSPACEI;

alter table SEC_DOMAIN_ENTRIES
    add constraint PK_SEC_DOMAIN_ENTRIES primary key (USER_ID, DOMAIN_ID);

alter table SEC_DOMAIN_ENTRIES
    add constraint FK_SEC_DOMAIN_ENTRIES_USR_ID foreign key (USER_ID)
    references USERS(USERNAME) on delete cascade;

alter table SEC_DOMAIN_ENTRIES
    add constraint FK_SEC_DOMAIN_ENTRIES_DOM_ID foreign key (DOMAIN_ID)
    references SECURITY_DOMAINS(ID) on delete cascade deferrable;

--

create table SECURITY_JOBS (
    USER_ID varchar2(30),
    USER_CREATED varchar2(30),
    EXECUTE date,
    EXECUTED date,
    DATA varchar2(2000)
)
TABLESPACE &&TUSERS;

create unique index PK_SECURITY_JOBS
    on SECURITY_JOBS
        ( USER_ID )
    TABLESPACE &&TSPACEI;

create index IDX_SECURITY_JOBS
    on SECURITY_JOBS
        ( EXECUTE, EXECUTED )
    TABLESPACE &&TSPACEI;

alter table SECURITY_JOBS
    add constraint PK_SECURITY_JOBS primary key (USER_ID);

--

