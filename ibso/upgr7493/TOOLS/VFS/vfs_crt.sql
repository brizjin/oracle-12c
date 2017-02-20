create sequence vfs_seq start with 11 increment by 1 nocycle nomaxvalue noorder
/
create table vfs_storage (
 id number,
 def number default 0,
 data_partition_name varchar2(30),
 description varchar2(4000)
 )
 tablespace &&tuser
/
create unique index pk_vfs_storage on vfs_storage (id) tablespace &&tindx
/
create unique index unq_vfs_storage_part_name on vfs_storage (data_partition_name) tablespace &&tindx
/
alter table vfs_storage add constraint pk_vfs_storage primary key (id)
/
alter table vfs_storage add constraint unq_vfs_storage_part_name unique (data_partition_name)
/
alter table vfs_storage add constraint nn_vfs_storage_def check (def is not null)
/
alter table vfs_storage add constraint nn_vfs_storage_part_name check (data_partition_name is not null)
/
create table vfs (
 id number,
 storage_id number,
 type number,
 access_mask number default -1,
 data_size number default 0,
 create_date date default sysdate,
 owner_id varchar2(30),
 name varchar2(512),
 charset varchar2(20),
 parent_id number,
 modify_date date,
 modify_subj_id varchar2(30),
 description varchar2(4000)
 )
 tablespace &&tuser
/
create unique index pk_vfs on vfs (id) tablespace &&tindx
/
create unique index unq_vfs_id_storage on vfs (id,storage_id) tablespace &&tindx
/
create index idx_vfs_parent_name on vfs (parent_id,name) tablespace &&tindx
/
alter table vfs add constraint pk_vfs primary key (id)
/
alter table vfs add constraint unq_vfs_id_storage unique (id,storage_id)
/
alter table vfs add constraint fk_vfs_storage_id foreign key (storage_id) references vfs_storage (id)
/
alter table vfs add constraint chk_vfs_access_mask check (access_mask >= 0 or type < 0)
/
alter table vfs add constraint nn_vfs_storage_id check (storage_id is not null)
/
alter table vfs add constraint nn_vfs_type check (type is not null)
/
alter table vfs add constraint fk_vfs_parent_id_id foreign key (parent_id) references vfs (id)
/
create table vfs_data (
 id number,
 storage_id number,
 data blob
 )
 tablespace &&tlob
 partition by range (storage_id) (partition VFS_STORAGE_PART#1 values less than (2))
 enable row movement
/
create unique index pk_vfs_data on vfs_data (id) tablespace &&tindx
/
alter table vfs_data add constraint pk_vfs_data primary key (id)
/
alter table vfs_data add constraint fk_vfs_data_id_storage
 foreign key (id,storage_id) references vfs (id,storage_id) on delete cascade
/
alter table vfs_data add constraint nn_vfs_data_storage_id check (storage_id is not null)
/
create table vfs_storage_access (
 access_mask number default 0,
 subject_id varchar2(30)
 )
 tablespace &&tuser
/
create unique index pk_vfs_storage_access on vfs_storage_access (subject_id) tablespace &&tindx
/
alter table vfs_storage_access add constraint pk_vfs_storage_access primary key (subject_id)
/
alter table vfs_storage_access add constraint fk_vfs_storage_access_subj_id
 foreign key (subject_id) references users (username) on delete cascade
/
create table vfs_access (
 access_mask number default 0,
 include_subfolders number default 0,
 vfs_id number,
 subject_id varchar2(30)
 )
 tablespace &&tuser
/
create unique index pk_vfs_access on vfs_access (vfs_id,subject_id) tablespace &&tindx
/
alter table vfs_access add constraint pk_vfs_access primary key (vfs_id,subject_id)
/
alter table vfs_access add constraint fk_vfs_access_id
 foreign key (vfs_id) references vfs (id) on delete cascade
/
alter table vfs_access add constraint fk_vfs_access_subject_id
 foreign key (subject_id) references users (username) on delete cascade
/
alter table vfs_access add constraint chk_vfs_access_access check (access_mask >= 0)
/
create table vfs_lock (
 vfs_id number,
 lock_mode number,
 lock_id varchar2(100),
 vfs_handle integer
 )
 tablespace &&tuser
/
create unique index unq_vfs_lock on vfs_lock (lock_id,vfs_id,vfs_handle) tablespace &&tindx
/
create index idx_vfs_lock_id on vfs_lock (vfs_id)
/
alter table vfs_lock add constraint unq_vfs_lock unique (lock_id,vfs_id,vfs_handle)
/
alter table vfs_lock add constraint nn_vfs_lock_vfs_id check (vfs_id is not null)
/
alter table vfs_lock add constraint nn_vfs_lock_mode check (lock_mode is not null)
/
alter table vfs_lock add constraint nn_vfs_lock_lock_id check (lock_id is not null)
/
insert into vfs_storage (id,def,data_partition_name,description)
values (1,1,'VFS_STORAGE_PART#1','automatically created storage')
/
commit
/