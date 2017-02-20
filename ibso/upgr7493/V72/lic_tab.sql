PROMPT modify license tables ...

alter table system_options add loc varchar2(1);
alter table system_options add base varchar2(1);
alter table system_options add licensed varchar2(1);


prompt API_REPORTS

create table api_reports
(id number not null,
 dt date)
tablespace &&TUSERS;

create unique index pk_api_reports on api_reports (id) tablespace &&TSPACEI;
alter table api_reports add constraint pk_api_reports primary key (id);
create index idx_dt_api_reports on api_reports(dt) tablespace &&TSPACEI;


prompt API_LIST

create table api_list
(id number not null,
 rep number not null,
 obj_type   Varchar2(30),
 class_id   Varchar2(16),
 short_name Varchar2(30)
 )
tablespace &&TUSERS;

create unique index pk_api_list on api_list (id) tablespace &&TSPACEI;
alter table api_list add constraint pk_api_list primary key (id);
create unique index idx_api_list_id on api_list (rep, class_id, obj_type, short_name) tablespace &&TSPACEI;


alter table api_list
    add constraint fk_api_list_report foreign key (rep)
    references api_reports(id) on delete cascade;


prompt API_OPTIONS

create table api_options
(api number not null,
 option_id Varchar2(28) not null)tablespace &&TUSERS;

create unique index pk_api_options on api_options (api, option_id) tablespace &&TSPACEI;
alter table api_options add constraint pk_api_options primary key (api, option_id);

alter table api_options
    add constraint fk_api_options_api foreign key (api)
    references api_list(id) on delete cascade;


prompt API_USAGE
create table api_usage
(rep number not null,
 api number not null,
 obj_type   Varchar2(30),
 class_id   Varchar2(16),
 short_name Varchar2(30),
 name varchar2(128))
tablespace &&TUSERS;

create unique index pk_api_usage on api_usage (api, class_id, obj_type, short_name) tablespace &&TSPACEI;
alter table api_usage add constraint pk_api_usage primary key (api, class_id, obj_type, short_name);
create index idx_api_usage on api_usage (rep, class_id, obj_type, short_name) tablespace &&TSPACEI;

alter table api_usage
    add constraint fk_api_usage_api foreign key (api)
    references api_list(id) on delete cascade;

alter table api_usage
    add constraint fk_api_usage_rep foreign key (rep)
    references api_reports(id);