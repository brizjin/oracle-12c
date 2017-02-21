drop table bk_obj_static;

alter table obj_static drop constraint pk_obj_static &&D_DROPINDEX;
alter table obj_static drop constraint fk_obj_static_class_id;

rename obj_static to bk_obj_static;

create table obj_static (class_id varchar2(16),id varchar2(128))
  tablespace &&tusers;

insert into obj_static(id,class_id) (select id,class_id from bk_obj_static);

create unique index pk_obj_static
  on obj_static(class_id) tablespace &&tspacei;
alter table obj_static add constraint pk_obj_static
  primary key(class_id);
alter table obj_static add constraint fk_obj_static_class_id
  foreign key(class_id) referencing classes(id);


