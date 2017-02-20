create table license_settings (
    owner varchar2(30),
    id varchar2(28),
    limit varchar2(2000),
    usage varchar2(1),
    usage_date date,
    warning_value varchar2(2000),
    status varchar2(16),
    check_time date,
    crc_row number
)
 pctfree    10
 pctused    40
 initrans   1
 maxtrans   255
 tablespace &&TUSER;


create unique index pk_license_settings
    on license_settings(owner,id) tablespace &&TSPACEI;

alter table license_settings
    add constraint pk_license_settings primary key(owner, id);

alter table license_settings add api_check varchar2(1);

create table license_report (
    owner Varchar2(30),
    sensor_id Varchar2(28),
    value Varchar2(2000),
    limit Varchar2(2000),
    version Varchar2(16),
    status Varchar2(16),
    check_date Date,
    crc_row Number
)
 pctfree    10
 pctused    40
 initrans   1
 maxtrans   255
 tablespace &&TUSER;

create unique index pk_license_report
    on license_report(owner, check_date, sensor_id) tablespace &&TSPACEI;

alter table license_report
    add constraint pk_license_report primary key(owner, check_date, sensor_id);


