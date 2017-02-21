PROMPT CREATE SEQUENCES
create table sequences
(
  num_id    varchar2(30),
  seq_name  varchar2(30),
  status    varchar2(1),
  group_no  number
)
tablespace &&TUSERS;

prompt create primary key
create unique index pk_sequences
  on sequences(num_id, seq_name) tablespace &&TSPACEI;
alter table sequences add constraint pk_sequences primary key (num_id, seq_name);

prompt create not null constraints
alter table sequences modify status constraint nn_sequences_status not null;

prompt create check constraints
alter table sequences add constraint chk_sequences_status check(status in ('I', 'A', 'N', 'P'));

prompt create indexes
create unique index unq_sequences_status on sequences (num_id, status) tablespace &&TSPACEI;

prompt create foreign keys
alter table sequences add constraint fk_sequences foreign key (num_id)
  referencing numerators(id);
