alter table report_roles add subj_id varchar2(30);

alter table report_roles add constraint FK_REPORT_ROLES_SUBJ_ID
  foreign key(subj_id) references users(username) on delete cascade;

alter table report_roles drop constraint PK_REPORT_ROLES;

drop index PK_REPORT_ROLES;

alter table report_roles add constraint PK_REPORT_ROLES
  primary key(package_name,role_name) using index tablespace &&tspacei;

create index IDX_REPORT_ROLES_ROLE_NAME on report_roles(role_name)
  tablespace &&tspacei;

create index IDX_REPORT_ROLES_SUBJ_ID on report_roles(subj_id)
  tablespace &&tspacei;

