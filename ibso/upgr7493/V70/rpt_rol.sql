PROMPT create table report_roles ...
create table report_roles (
    package_name Varchar2(30),
    role_name varchar2(30)
)
 tablespace &&TUSERS;

create unique index pk_report_roles
    on report_roles(package_name) tablespace &&tspacei;

alter table report_roles
    add constraint pk_report_roles primary key(package_name);

alter table report_objects add grant_user varchar2(1);


