PROMPT CREATE NUMERATORS
create table numerators
  (id varchar2 (30),
   code varchar2 (50),
   name varchar2 (128),
   start_value number,
   step number,
   cache_size number,
   order_flag varchar2 (1),
   cycle_flag varchar2 (1),
   max_value number,
   min_value number,
   restart_on_max varchar2 (1),
   system varchar2 (1),
   properties varchar2 (2000))
 tablespace &&TUSERS;

prompt create primary key
create unique index pk_numerators
  on numerators(id) tablespace &&TSPACEI;
alter table numerators add constraint
  pk_numerators primary key (id);

prompt create not null constraints
alter table numerators modify code constraint nn_numerators_code not null;
alter table numerators modify name constraint nn_numerators_name not null;

prompt create check constraints
alter table numerators add constraint chk_numerators_system check(system in ('Y', 'N'));

prompt create indexes
create unique index unq_numerators_code on numerators (code) tablespace &&TSPACEI;
create unique index idx_numerators_sys on numerators (id, system) tablespace &&TSPACEI;
