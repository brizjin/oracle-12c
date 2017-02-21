alter table class_tab_columns add NOT_CACHED VARCHAR2(1);

create table transition_methods(
    class_id      varchar2(16),
    method_short  varchar2(16),
    method_id     varchar2(16),
    ext_id        varchar2(16),
    belong_group  varchar2(1)
) tablespace &&tusers;

create unique index pk_trn_meths_class_sname
  on transition_methods(class_id,method_short)
  tablespace &&tspacei;

alter table transition_methods add constraint pk_trn_meths_class_sname
  primary key(class_id,method_short);

create index idx_trn_meths_method_id
  on transition_methods(method_id)
  tablespace &&tspacei;

alter table transition_methods add constraint fk_trn_meths_class_id
  foreign key(class_id) references classes(id) on delete cascade;

alter table transition_methods add constraint fk_trn_meths_method_id
  foreign key(method_id) references methods(id) on delete cascade;

alter table transition_methods add constraint fk_trn_meths_ext_id
  foreign key(ext_id) references methods(id) on delete set null;

