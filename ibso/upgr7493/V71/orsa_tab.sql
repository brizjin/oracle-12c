PROMPT modify orsa tables ...

alter table orsa_jobs modify (state_msg varchar2(4000));

alter table orsa_jobs add (engine varchar2(32));

alter table orsa_jobs drop constraint fk_orsa_jobs_class_id;

alter table orsa_jobs drop constraint fk_orsa_jobs_method_id;

alter table orsa_jobs drop constraint fk_orsa_jobs_username;

drop index idx_orsa_jobs_usename;

create index idx_orsa_jobs_username
  on orsa_jobs (username) tablespace &&tsidx;

create table orsa_par_lob
   (job number,
    pos number,
    name varchar2(32),
    t varchar2(32),
    c clob,
    b blob)
 pctfree    10
 pctused    40
 initrans   1
 maxtrans   255
 tablespace &&TUSERS;

create unique index pk_orsa_par_lob
  on orsa_par_lob(job,pos,name) tablespace &&TSPACEI;

alter table orsa_par_lob add constraint
  pk_orsa_par_lob primary key (job,pos,name);

alter table orsa_par_lob add constraint
  fk_orsa_par_lob foreign key (job,pos)
  referencing orsa_jobs(job,pos) on delete cascade;

grant all on orsa_par_lob to &&owner with grant option;


