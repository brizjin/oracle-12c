PROMPT CREATE NUM_ATTRIBUTES
create table num_attributes
(
  class_id  varchar2(16),
  attr_id   varchar2(16),
  num_id    varchar2(30),
  status    varchar2(1)
)
tablespace &&TUSERS;

prompt create primary key
create unique index pk_num_attributes
  on num_attributes(class_id, attr_id) tablespace &&TSPACEI;
alter table num_attributes add constraint pk_num_attributes primary key (class_id, attr_id);

prompt create foreign keys
alter table num_attributes add constraint fk_num_attributes foreign key (num_id)
  referencing numerators(id);

prompt create check constraints
alter table num_attributes add constraint chk_num_attributes_status check(status in ('A', 'D'));


