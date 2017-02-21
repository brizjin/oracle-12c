create table diary_tables (
    owner varchar2(30),
    diary_type number,
    diary_suffix varchar2(50),
    diary_fields varchar2(500),
    diary_step varchar2(1),
    primary_key_fields varchar2(50),
    tablespace_name varchar2(50),
    idx_tablespace_name varchar2(50),
    storage_initial varchar2(10),
    storage_next varchar2(10),
    storage_freelists varchar2(10)
)
 pctfree    10
 pctused    40
 initrans   1
 maxtrans   255
 tablespace &&TUSER;

create unique index PK_DIARY_TABLES_O_DT on diary_tables(owner, diary_type)
--create unique index UNQ_DIARY_TABLES_O_DT on diary_tables(owner, diary_type)
 pctfree        0
 initrans       2
 maxtrans       255
 tablespace     &&TSPACEI;

alter table diary_tables add constraint PK_DIARY_TABLES_O_DT primary key(owner, diary_type);
--alter table diary_tables add constraint UNQ_DIARY_TABLES_O_DT unique(owner, diary_type);

create table diary_indexes (
    owner varchar2(30),
    diary_type number,
    index_suffix varchar2(50),
    is_unique varchar2(1),
    index_fields varchar2(50),
    storage_initial varchar2(10),
    storage_next varchar2(10)
)
 pctfree    10
 pctused    40
 initrans   1
 maxtrans   255
 tablespace &&TUSER;

drop index IDX_DIARY_INDEXES_O_DT;

create unique index UNQ_DIARY_INDEXES_O_DT_IS on diary_indexes(owner, diary_type, index_suffix)
 pctfree        0
 initrans       2
 maxtrans       255
 tablespace     &&TSPACEI;

alter table diary_indexes add constraint FK_DIARY_INDEXES_O_DT
    foreign key(owner, diary_type) references diary_tables(owner, diary_type) on delete cascade;

create table diary_partitions (
    owner varchar2(30),
    diary_step varchar2(1),
    step_number number,
    tablespace_name varchar2(50),
    idx_tablespace_name varchar2(50)
)
 pctfree    10
 pctused    40
 initrans   1
 maxtrans   255
 tablespace &&TUSER;

create unique index PK_DIARY_PARTITIONS_O_DS_SN on diary_partitions(owner, diary_step, step_number)
 pctfree        0
 initrans       2
 maxtrans       255
 tablespace     &&TSPACEI;

alter table diary_partitions add constraint PK_DIARY_PARTITIONS_O_DS_SN PRIMARY key(owner, diary_step, step_number);

