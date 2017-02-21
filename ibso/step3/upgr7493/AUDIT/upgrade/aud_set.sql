create sequence diary_id start with 1000 increment by 1 cache 100;
create sequence och_id start with 1000 increment by 1 cache 100;
create sequence osh_id start with 1000 increment by 1 cache 100;
create sequence vals_id start with 1000 increment by 1 cache 100;
create sequence edh_id start with 1000 increment by 1 cache 100;

create table users (
  name varchar2(100),
  username varchar2(30) not null
);

alter table users
    add constraint unq_users_username unique (username)
        using index tablespace &&TSPACEI;

create table settings (
    owner varchar2(30),
    name varchar2(30),
    value varchar2(2000),
    description varchar2(2000)
)
 pctfree    10
 pctused    40
 initrans   1
 maxtrans   255
 tablespace &&TUSER;

alter table settings drop primary key &&D_DROPINDEX;

update settings set name = upper(name) where name != upper(name);

create unique index pk_settings_owner_name
    on settings(owner,name) tablespace &&TSPACEI;

alter table settings add
    constraint pk_settings_owner_name primary key(owner, name);

declare
  sid varchar2(100);
  uid varchar2(100);
  c number;
begin
  select count(*) into c from user_tables where table_name = 'AUDIT_SETTINGS';
  if c >= 1 then
    execute immediate 'insert into settings (owner, name, value, description)
      select owner, name, value, description from audit_settings';
    commit;
    execute immediate 'drop table audit_settings';
  end if;
end;
/

create table owners (
  owner varchar2(30),
  schema_owner varchar2(30)
);

alter table owners add lic_version varchar2(30);

alter table owners
    add constraint pk_owners primary key (owner,schema_owner)
        using index tablespace &&TSPACEI;

insert into owners (owner,schema_owner)
  select distinct owner,owner from settings s
   where not exists (select 1 from owners o where o.owner=s.owner);

update owners
   set lic_version = nvl((select value from settings where owner='&&AUDITOR' and name='LICENSE_VERSION'),'1')
 where lic_version is null and exists
       (select 1 from settings where owner='&&AUDITOR' and name='LICENSE_VERSION');

commit;

create or replace trigger settings_before_ins_upd
    before insert or update of owner,name on settings
    referencing new as new old as old for each row
declare
  n number;
begin
  if inserting or updating('NAME') then
    :new.name:=upper(:new.name);
  end if;
  if inserting then
    select count(1) into n from owners where owner=:new.owner;
    if n=0 then
      insert into owners(owner,schema_owner)
        values(:new.owner,:new.owner);
    end if;
  elsif updating('OWNER') then
    update owners
       set owner = :new.owner,
           schema_owner = decode(schema_owner,:old.owner,:new.owner,schema_owner)
     where owner=:old.owner;
  end if;
end;
/


