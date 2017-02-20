alter table dict_changes drop constraint FK_DICT_CHANGES;
drop trigger DICT_CHANGES_CHANGES;
drop table signed_levels;


Create table license_data (
    id Varchar2(128),
    type Varchar2(16),
    date_begin Date,
    date_end Date,
    description Varchar2(2000),
    status Varchar2(16),
    data Blob
)
 pctfree    10
 pctused    40
 initrans   1
 maxtrans   255
 tablespace &&tusers;

create unique index pk_license_data
    on license_data(id) tablespace &&TSPACEI;

alter table license_data
    add constraint pk_license_data primary key(id);


prompt creating table system_options
Create table system_options (
    id Varchar2(28),
    parent_id Varchar2(28),
    name Varchar2(2000),
    type Varchar2(16),
    check_type Varchar2(16),
    get_sql Varchar2(2000),
    exec_sql Varchar2(4000),
    crc_exec number,
    crc_row number,
    crc_tree number,
    crc_obj number,
    check_time Date,
    required varchar2(1),
    version Varchar2(16),
    ver_sql Varchar2(2000),
    value Varchar2(2000),
    bound_value Varchar2(2000),
    status Varchar2(16)
)
 pctfree    10
 pctused    40
 initrans   1
 maxtrans   255
 tablespace &&tusers;

create unique index pk_system_options
    on system_options(id) tablespace &&TSPACEI;

alter table system_options
    add constraint pk_system_options primary key(id);

alter table system_options
    add constraint fk_system_options_par_id foreign key (parent_id)
    references system_options(id);


prompt creating table objects_options
Create table objects_options (
        obj_type   Varchar2(30),
        class_id   Varchar2(16),
        short_name Varchar2(30),
        option_id Varchar2(28)
)
 pctfree    10
 pctused    40
 initrans   1
 maxtrans   255
 tablespace &&tusers;


create unique index pk_objects_options
    on objects_options (class_id, obj_type, short_name, option_id) tablespace &&TSPACEI;

alter table objects_options
    add constraint pk_objects_options primary key  (class_id, obj_type, short_name, option_id);

alter index objects_options_idx_option rename to idx_objects_options_option;

create index idx_objects_options_option
    on objects_options (option_id)  tablespace &&TSPACEI;

alter table objects_options
    add constraint fk_objects_options_option foreign key (option_id)
    references system_options(id) on delete cascade;

prompt create global context
create or replace context &&owner._OPTIONS using opt_mgr ACCESSED GLOBALLY;




