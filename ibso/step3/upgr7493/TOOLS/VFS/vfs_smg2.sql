prompt package body vfs_storage_mgr
create or replace package body vfs_storage_mgr as
/*
 *	$HeadURL: http://hades.ftc.ru:7382/svn/pltm2/Core/Utils/EXT/vfs_smg2.sql $
 *	$Author: Alexey $
 *	$Revision: 15082 $
 *	$Date:: 2012-03-06 17:34:34 #$
 */

 ----------------------------------------------------------
 function create_storage(apartition_name in varchar2 default null, adescription in varchar2 default null,
  atablespace_name in varchar2 default null,
  --lob parameters
  achunk in integer default null, apctversion in integer default null, alogging in varchar2 default null,
  --storage parameters
  ainitial in integer default null, anext in integer default null, apctincrease in integer default null,
  aminextents in integer default null, amaxextents in integer default null,
  afreelist_groups in integer default null, afreelists in integer default null,
  abuffer_pool in varchar2 default null
  ) return integer as
 pragma autonomous_transaction;
 stmt varchar2(4000);
 cid integer;
 tmp integer;
 pname varchar2(30);
 begin
  cid := vfs_admin.check_storage_access;
  if cid <> vfs_mgr.ERR_SUCCESS then rollback; return cid; end if;
  --prepare sql statement for adding partition
  select vfs_seq.nextval into cid from dual;
  pname := nvl(apartition_name,'VFS_STORAGE_PART#' || cid);
  select
   'ALTER TABLE VFS_DATA ADD PARTITION ' || pname || ' VALUES LESS THAN (' || (cid + 1) || ') ' ||
   decode(atablespace_name,null,null,' TABLESPACE ' || atablespace_name)
  into stmt from dual;
  if atablespace_name is not null or
     ainitial is not null or anext is not null or apctincrease is not null or
     aminextents is not null or amaxextents is not null or
     afreelist_groups is not null or afreelists is not null or abuffer_pool is not null or
     achunk is not null or apctversion is not null or alogging is not null then
   select
    stmt || ' LOB(DATA) STORE AS (' ||
    decode(atablespace_name,null,null,'TABLESPACE ' || atablespace_name || ' ') ||
    decode(achunk,null,null,'CHUNK ' || achunk || ' ') ||
    decode(apctversion,null,null,'PCTVERSION ' || apctversion || ' ') ||
    decode(alogging,null,null,'NOCACHE ' || alogging || ' ')
   into stmt from dual;
   if ainitial is not null or anext is not null or apctincrease is not null or
      aminextents is not null or amaxextents is not null or
      afreelist_groups is not null or afreelists is not null or abuffer_pool is not null then
    select
     stmt || ' STORAGE (' ||
     decode(ainitial,null,null,'INITIAL ' || ainitial || 'K ') ||
     decode(anext,null,null,'NEXT ' || anext || 'K ') ||
     decode(apctincrease,null,null,'PCTINCREASE ' || apctincrease || ' ') ||
     decode(aminextents,null,null,'MINEXTENTS ' || aminextents || ' ') ||
     decode(amaxextents,null,null,'MAXEXTENTS ' || decode(amaxextents,MAXEXTENTS_UNLIMITED,'UNLIMITED',amaxextents) || ' ') ||
     decode(afreelist_groups,null,null,'FREELIST GROUPS ' || afreelist_groups || ' ') ||
     decode(afreelists,null,null,'FREELISTS ' || afreelists || ' ') ||
     decode(abuffer_pool,null,null,'BUFFER_POOL ' || abuffer_pool) ||
     ')'
    into stmt from dual;
   end if;
   stmt := stmt || ')';
  end if;
  --add partition
  dbms_utility.exec_ddl_statement(stmt);
  --insert storage info into vfs_storage
  --if exception - drop partition created
  begin
   insert into vfs_storage (id,data_partition_name,description,def)
   values (cid,pname,adescription,decode(get_default,null,1,0));
  exception
   when others then
    cid := drop_storage(pname);
    raise;
  end;
  commit;
  return cid;
 end create_storage;
 ----------------------------------------------------------
 function get_storage_partition_name(aid in integer default null) return varchar2 as
 result varchar2(30);
 fid integer := nvl(aid,get_default);
 begin
  select data_partition_name into result from vfs_storage where id = fid;
  return result;
 end get_storage_partition_name;
 ----------------------------------------------------------
 function drop_storage(aid in integer default null) return pls_integer as
 begin
  return drop_storage(get_storage_partition_name(aid));
 end drop_storage;
 ----------------------------------------------------------
 function drop_storage(apartition_name in varchar2) return pls_integer as
 pragma autonomous_transaction;
 stmt varchar2(4000);
 tmp pls_integer;
 begin
  tmp := vfs_admin.check_storage_access;
  if tmp <> vfs_mgr.ERR_SUCCESS then rollback; return tmp; end if;
  --try to delete storage info from vfs_storage
  --if exception - there are some objects in that storage - it cannot be dropped
  begin
   delete from vfs_storage where data_partition_name = apartition_name returning def into tmp;
   if sql%rowcount = 0 then rollback; return vfs_mgr.ERR_INVALID_PARAMETER; end if;
   if tmp <> 0 then rollback; return vfs_mgr.ERR_DROP_DEFAULT_STORAGE; end if;
  exception
   when vfs_mgr.E_ORA_CHILD_RECORD then
    rollback;
    return vfs_mgr.ERR_NOT_EMPTY;
  end;
  --drop partition
  stmt := 'ALTER TABLE VFS_DATA DROP PARTITION ' || apartition_name;
  dbms_utility.exec_ddl_statement(stmt);
  commit;
  return vfs_mgr.ERR_SUCCESS;
 end drop_storage;
 ----------------------------------------------------------
 function modify_storage(aid in integer default null,
  apctversion in integer default null, alogging in varchar2 default null,
  anext in integer default null, apctincrease in integer default null,
  amaxextents in integer default null,
  afreelists in integer default null,
  abuffer_pool in varchar2 default null) return pls_integer as
 begin
  return modify_storage(get_storage_partition_name(aid),
   apctversion,alogging,
   anext,apctincrease,
   amaxextents,
   afreelists,
   abuffer_pool);
 end modify_storage;
 ----------------------------------------------------------
 function modify_storage(apartition_name in varchar2,
  apctversion in integer default null, alogging in varchar2 default null,
  anext in integer default null, apctincrease in integer default null,
  amaxextents in integer default null,
  afreelists in integer default null,
  abuffer_pool in varchar2 default null) return pls_integer as
 pragma autonomous_transaction;
 stmt varchar2(4000);
 tmp pls_integer;
 begin
  --if no modifications then exit
  if apctversion is null and alogging is null and
     anext is null and apctincrease is null and
     amaxextents is null and
     afreelists is null and
     abuffer_pool is null then
   commit;
   return vfs_mgr.ERR_SUCCESS;
  end if;
  tmp := vfs_admin.check_storage_access;
  if tmp <> vfs_mgr.ERR_SUCCESS then rollback; return tmp; end if;
  --prepare statement
  stmt := 'ALTER TABLE VFS_DATA MODIFY PARTITION ' || apartition_name || ' LOB(DATA) (';
  select
   stmt ||
   decode(apctversion,null,null,'PCTVERSION ' || apctversion || ' ') ||
   decode(alogging,null,null,'NOCACHE ' || alogging || ' ')
  into stmt from dual;
  if anext is not null or apctincrease is not null or
     amaxextents is not null or
     afreelists is not null or abuffer_pool is not null then
   select
    stmt || ' STORAGE (' ||
    decode(anext,null,null,'NEXT ' || anext || 'K ') ||
    decode(apctincrease,null,null,'PCTINCREASE ' || apctincrease || ' ') ||
    decode(amaxextents,null,null,'MAXEXTENTS ' || decode(amaxextents,MAXEXTENTS_UNLIMITED,'UNLIMITED',amaxextents) || ' ') ||
    decode(afreelists,null,null,'FREELISTS ' || afreelists || ' ') ||
    decode(abuffer_pool,null,null,'BUFFER_POOL ' || abuffer_pool) ||
    ')'
   into stmt from dual;
  end if;
  stmt := stmt || ')';
  --modify partition
  dbms_utility.exec_ddl_statement(stmt);
  commit;
  return vfs_mgr.ERR_SUCCESS;
 end modify_storage;
 ----------------------------------------------------------
 function move_storage(aid in integer default null,
  atablespace_name in varchar2 default null,
  achunk in integer default null, apctversion in integer default null, alogging in varchar2 default null,
  ainitial in integer default null, anext in integer default null, apctincrease in integer default null,
  aminextents in integer default null, amaxextents in integer default null,
  afreelist_groups in integer default null, afreelists in integer default null,
  abuffer_pool in varchar2 default null) return pls_integer as
 begin
  return move_storage(get_storage_partition_name(aid),
   atablespace_name,
   achunk,apctversion,alogging,
   ainitial,anext,apctincrease,
   aminextents,amaxextents,
   afreelist_groups,afreelists,
   abuffer_pool);
 end move_storage;
 ----------------------------------------------------------
 function move_storage(apartition_name in varchar2,
  atablespace_name in varchar2 default null,
  achunk in integer default null, apctversion in integer default null, alogging in varchar2 default null,
  ainitial in integer default null, anext in integer default null, apctincrease in integer default null,
  aminextents in integer default null, amaxextents in integer default null,
  afreelist_groups in integer default null, afreelists in integer default null,
  abuffer_pool in varchar2 default null) return pls_integer as
 pragma autonomous_transaction;
 stmt varchar2(4000);
 tmp pls_integer;
 begin
  if tmp <> vfs_mgr.ERR_SUCCESS then rollback; return tmp; end if;
  --prepare sql statement for adding partition
  select
   'ALTER TABLE VFS_DATA MOVE PARTITION ' || apartition_name ||
   decode(atablespace_name,null,null,' TABLESPACE ' || atablespace_name)
  into stmt from dual;
  if atablespace_name is not null or
     ainitial is not null or anext is not null or apctincrease is not null or
     aminextents is not null or amaxextents is not null or
     afreelist_groups is not null or afreelists is not null or abuffer_pool is not null or
     achunk is not null or apctversion is not null or alogging is not null then
   select
    stmt || ' LOB(DATA) STORE AS (' ||
    decode(atablespace_name,null,null,'TABLESPACE ' || atablespace_name || ' ') ||
    decode(achunk,null,null,'CHUNK ' || achunk || ' ') ||
    decode(apctversion,null,null,'PCTVERSION ' || apctversion || ' ') ||
    decode(alogging,null,null,'NOCACHE ' || alogging || ' ')
   into stmt from dual;
   if ainitial is not null or anext is not null or apctincrease is not null or
      aminextents is not null or amaxextents is not null or
      afreelist_groups is not null or afreelists is not null or abuffer_pool is not null then
    select
     stmt || ' STORAGE (' ||
     decode(ainitial,null,null,'INITIAL ' || ainitial || 'K ') ||
     decode(anext,null,null,'NEXT ' || anext || 'K ') ||
     decode(apctincrease,null,null,'PCTINCREASE ' || apctincrease || ' ') ||
     decode(aminextents,null,null,'MINEXTENTS ' || aminextents || ' ') ||
     decode(amaxextents,null,null,'MAXEXTENTS ' || decode(amaxextents,MAXEXTENTS_UNLIMITED,'UNLIMITED',amaxextents) || ' ') ||
     decode(afreelist_groups,null,null,'FREELIST GROUPS ' || afreelist_groups || ' ') ||
     decode(afreelists,null,null,'FREELISTS ' || afreelists || ' ') ||
     decode(abuffer_pool,null,null,'BUFFER_POOL ' || abuffer_pool) ||
     ')'
    into stmt from dual;
   end if;
   stmt := stmt || ')';
  end if;
  --move partition
  dbms_utility.exec_ddl_statement(stmt);
  commit;
  return vfs_mgr.ERR_SUCCESS;
 end move_storage;
 ----------------------------------------------------------
 function set_storage_description(aid in integer, adescription in varchar2) return pls_integer as
 pragma autonomous_transaction;
 tmp pls_integer;
 begin
  tmp := vfs_admin.check_storage_access;
  if tmp <> vfs_mgr.ERR_SUCCESS then rollback; return tmp; end if;
  update vfs_storage set description = adescription where id = aid;
  commit;
  return vfs_mgr.ERR_SUCCESS;
 end set_storage_description;
 ----------------------------------------------------------
 function set_default(aid in integer) return pls_integer as
 pragma autonomous_transaction;
 tmp pls_integer;
 begin
  tmp := vfs_admin.check_storage_access;
  if tmp <> vfs_mgr.ERR_SUCCESS then rollback; return tmp; end if;
  update vfs_storage set def = 0;
  update vfs_storage set def = 1 where id = aid;
  if sql%rowcount = 0 then rollback; return vfs_mgr.ERR_INVALID_PARAMETER; end if;
  commit;
  return vfs_mgr.ERR_SUCCESS;
 end set_default;
 ----------------------------------------------------------
 function get_default return integer as
 result integer;
 begin
  select id into result from vfs_storage where def <> 0;
  return result;
 exception
  when NO_DATA_FOUND then return null;
 end get_default;
 ----------------------------------------------------------

end;
/
sho err
