prompt package body vfs_mgr
create or replace package body vfs_mgr as
/*
 *	$HeadURL: http://hades.ftc.ru:7382/svn/pltm2/Core/Utils/EXT/vfs_mgr2.sql $
 *	$Author: Alexey $
 *	$Revision: 15082 $
 *	$Date:: 2012-03-06 17:34:34 #$
 */

 BAD_SYMBOLS    constant varchar2(10):= '/\*?%:';

 type T_FILE_INFO is record (
  id integer,
  locator blob,
  open_mode char,
  pos integer,
  path varchar2(4000),
  autonomous boolean,
  charset varchar2(20)
  );
 type T_FILE_TABLE is table of T_FILE_INFO index by HFILE;
 file_list T_FILE_TABLE;

 type T_FOLDER_INFO is record (
  id integer,
  mask varchar2(4000),
  dir_flag pls_integer,
  sort boolean,
  path varchar2(4000),
  type integer,

  cur integer,
  count pls_integer
  );
 type T_FOLDER_TABLE is table of T_FOLDER_INFO index by HFOLDER;
 folder_list T_FOLDER_TABLE;


 type T_ERROR_INFO is record (
  topic messages.topic%type,
  code messages.code%type
  );
 type T_ERROR_TABLE is table of T_ERROR_INFO index by binary_integer;
 error_list T_ERROR_TABLE;
 ep1 varchar2(100);
 ep2 varchar2(100);
 ep3 varchar2(100);

 LOCK_NONE      constant pls_integer :=  vfs_admin.ACCESS_NONE;
 LOCK_READ      constant pls_integer :=  vfs_admin.ACCESS_READ;
 LOCK_WRITE     constant pls_integer :=  vfs_admin.ACCESS_WRITE;
 LOCK_EXCLUSIVE constant pls_integer :=  vfs_admin.ACCESS_EXCLUSIVE;
 LOCK_R         constant pls_integer :=  vfs_admin.ACCESS_R;
 LOCK_W         constant pls_integer :=  vfs_admin.ACCESS_W;
 LOCK_X         constant pls_integer :=  vfs_admin.ACCESS_X;
 LOCK_RW        constant pls_integer :=  vfs_admin.ACCESS_RW;
 LOCK_RX        constant pls_integer :=  vfs_admin.ACCESS_RX;
 LOCK_WX        constant pls_integer :=  vfs_admin.ACCESS_WX;
 LOCK_RWX       constant pls_integer :=  vfs_admin.ACCESS_RWX;
 LOCK_FULL      constant pls_integer :=  vfs_admin.ACCESS_FULL;

 type T_ENV_REC is record (
  name varchar2(30),
  value varchar2(4000)
 );
 type T_ENV_TABLE is table of T_ENV_REC index by binary_integer;
 env_list T_ENV_TABLE;

 INITED boolean := false;

 CUR_USER varchar2(30);
 CUR_CAN_MAKE_DIR boolean;
 CUR_REPLACE_DIR varchar2(4000);
 CUR_HOME_DIR varchar2(4000);
 CUR_ROOT_DIR varchar2(4000);
 CUR_BASE_DIR varchar2(4000);
 CUR_DEBUG_LEVEL pls_integer;
 CUR_LOG_FILE varchar2(4000);


 DEFAULT_PATH_SEPARATOR char := '/';
 DEFAULT_CASE_SENSITIVE boolean := true;
 DEFAULT_SILENT_OVERWRITE boolean := true;
 DEFAULT_CAN_MAKE_DIR boolean := false;
 DEFAULT_DEBUG_LEVEL pls_integer := 0;
 DEFAULT_LOG_FILE varchar2(4000) := 'vfs.log';
 RLF raw(1) := hextoraw('0A');

 CUR_LOG_ID integer;

 writing_log boolean := false;

 ----------------------------------------------------------
 function make_lock_id return varchar2 as
 u rtl.users_info;
 begin
  if not rtl.get_user_info(u) then return null; else return u.id; end if;
 end make_lock_id;
 ----------------------------------------------------------

 ----------------------------------------------------------
 procedure write_log(ainf_type in varchar2, amessage in varchar2, ainf_level in integer) as
 p integer;
 pid integer;
 tmp pls_integer;
 f HFILE;
 begin
  if writing_log or ainf_level > CUR_DEBUG_LEVEL then return; end if;
  writing_log := true;

  if CUR_LOG_ID is null or CUR_LOG_ID <= 0 then
   if CUR_LOG_FILE is null then writing_log := false; return; end if;
   p := instr(CUR_LOG_FILE,PATH_SEPARATOR,-1);
   if p = 0 then pid := null; else pid := get_id_by_name$(substr(CUR_LOG_FILE,1,p - 1)); end if;
   if    pid is null then
    CUR_LOG_ID := create_file$(aname=>CUR_LOG_FILE,adescription=>'VFS log file');
   elsif pid > 0 then
    CUR_LOG_ID := create_file$(aname=>substr(CUR_LOG_FILE,p + 1),aparent_id=>pid,adescription=>'VFS log file');
   else
    return;
   end if;
   if CUR_LOG_ID <= 0 then writing_log := false; return; end if;
  end if;

  f := open$(CUR_LOG_ID,MODE_APPEND);
  if f < ERR_SUCCESS then writing_log := false; return; end if;
  tmp := cwrite_str$(f,
   'VFS ' || ainf_type || ' ' || to_char(sysdate,constant.date_format) || ' ' ||
   inst_info.owner || '.' || CUR_USER || '.' || make_lock_id || ' ' || amessage);
  tmp := close$(f);

  writing_log := false;
 end write_log;
 ----------------------------------------------------------

 ----------------------------------------------------------
 function set_error(acode in pls_integer, aep1 in varchar2 default null, aep2 in varchar2 default null, aep3 in varchar2 default null) return pls_integer as
 begin
  if acode >= ERR_SUCCESS then
   ep1 := null;
   ep2 := null;
   ep3 := null;
  else
   ep1 := aep1;
   ep2 := aep2;
   ep3 := aep3;

   write_log('ERR',error_message(acode),1);
  end if;
  return acode;
 end set_error;
 ----------------------------------------------------------

 ----------------------------------------------------------
 function get_profile(p_user varchar2 default current_user) return varchar2 is
 tmp varchar2(2000);
 i   pls_integer;
 j   pls_integer;
 begin
  check_open;
  tmp := nvl(p_user,current_user);
  select properties into tmp from users where username=tmp;
  i := instr(tmp,'|PROFILE ');
  if i > 0 then
   j := instr(tmp,'|',i+1);
   if j > 0 then
    tmp := substr(tmp,i+9,j-i-9);
   else
    tmp := substr(tmp,i+9);
   end if;
   return nvl(upper(ltrim(rtrim(tmp))),'DEFAULT');
  end if;
  return 'DEFAULT';
 exception when NO_DATA_FOUND then
  return 'DEFAULT';
 end get_profile;
 ----------------------------------------------------------
 function get_resource(p_profile varchar2, p_name varchar2) return varchar2 as
 s varchar2(2000);
 begin
  check_open;
  select /*+ INDEX */ value into s from profiles
  where profile = p_profile and resource_name = p_name;
  return s;
 exception when others then
  return null;
 end get_resource;
 ----------------------------------------------------------

 ----------------------------------------------------------
 function current_user return varchar2 as
 begin
  check_open;
  return CUR_USER;
 end current_user;
 ----------------------------------------------------------
 function default_charset return varchar2 as
 result varchar2(30);
 begin
  select value into result from v$nls_parameters where parameter = 'NLS_CHARACTERSET';
  return result;
 end default_charset;
 ----------------------------------------------------------
 function can_make_dir(asubject_id in varchar2 default current_user) return boolean as
 begin
  check_open;
  if asubject_id = CUR_USER then
   return CUR_CAN_MAKE_DIR;
  end if;
  return get_resource(get_profile(asubject_id),'VFS_MAKE_DIR') = 'YES';
 end can_make_dir;
 ----------------------------------------------------------
 function root_dir return varchar2 as
 begin
  check_open;
  return CUR_ROOT_DIR;
 end root_dir;
 ----------------------------------------------------------
 function home_dir return varchar2 as
 begin
  check_open;
  return CUR_HOME_DIR;
 end home_dir;
 ----------------------------------------------------------
 function replace_dir return varchar2 as
 begin
  check_open;
  return CUR_REPLACE_DIR;
 end replace_dir;
 ----------------------------------------------------------
 function base_dir return varchar2 as
 begin
  check_open;
  return CUR_BASE_DIR;
 end base_dir;
 ----------------------------------------------------------

 ----------------------------------------------------------
 function check_dead_lock(alock_id in integer) return pls_integer as
 pragma autonomous_transaction;
 u rtl.users_info;
 begin
  u.id := alock_id;
  if not rtl.init_user(u) then
   delete from vfs_lock where lock_id = alock_id;
   commit;
   return set_error(ERR_SUCCESS);
  end if;
  commit;
  return set_error(ERR_LOCKED);
 end check_dead_lock;
 ----------------------------------------------------------
 function check_lock(aid in integer, alock_request in pls_integer) return pls_integer as
 tmp integer;
 begin
  savepoint sp;
  begin
   select id into tmp from vfs where id = aid for update;
  exception
   when NO_DATA_FOUND then null;
  end;
  for r in (select lock_mode,lock_id from vfs_lock where vfs_id = aid order by lock_mode desc) loop
   if bitand(alock_request,LOCK_EXCLUSIVE) <> 0 or
      bitand(r.lock_mode,LOCK_EXCLUSIVE) <> 0 or
      (bitand(alock_request,LOCK_WRITE) <> 0 and bitand(r.lock_mode,LOCK_WRITE) <> 0) then
    if    r.lock_id = make_lock_id then
     return set_error(ERR_SUCCESS);
    elsif check_dead_lock(r.lock_id) <> ERR_SUCCESS then
     rollback to savepoint sp;
     return set_error(ERR_LOCKED,aid);
    end if;
   end if;
  end loop;
  return set_error(ERR_SUCCESS);
 end check_lock;
 ----------------------------------------------------------
 function lock_vfs(aid in integer, alock_request in pls_integer, ahandle in pls_integer) return pls_integer as
 pragma autonomous_transaction;
 result pls_integer;
 lid varchar2(100);
 begin
  result := check_lock(aid,alock_request);
  lid := make_lock_id;
  if result <> ERR_SUCCESS then rollback; return result; end if;
  begin
   insert into vfs_lock (vfs_id,lock_id,lock_mode,vfs_handle)
   values (aid,lid,alock_request,ahandle);
  exception
   when DUP_VAL_ON_INDEX then null;
  end;
  commit;
  return set_error(ERR_SUCCESS);
 end lock_vfs;
 ----------------------------------------------------------
 function unlock_vfs(aid in integer, ahandle in pls_integer) return pls_integer as
 pragma autonomous_transaction;
 flock_id varchar2(100);
 begin
  flock_id := make_lock_id;
  delete from vfs_lock
  where lock_id = flock_id and vfs_id = aid and
        (vfs_handle = ahandle or (ahandle is null and vfs_handle is null));
  commit;
  return set_error(ERR_SUCCESS);
 end unlock_vfs;
 ----------------------------------------------------------

 ----------------------------------------------------------
 function user_lock(aid in integer) return pls_integer as
 tmp pls_integer;
 begin
  check_open;
  tmp := vfs_admin.check_access(aid,vfs_admin.ACCESS_READ);
  if tmp <> ERR_SUCCESS then return tmp; end if;

  return lock_vfs(aid,LOCK_READ,null);
 end user_lock;
 ----------------------------------------------------------
 function user_unlock(aid in integer) return pls_integer as
 begin
  check_open;
  return unlock_vfs(aid,null);
 end user_unlock;
 ----------------------------------------------------------
 procedure clear_dead_locks as
 tmp pls_integer;
 begin
  check_open;
  for r in (select distinct lock_id from vfs_lock) loop
   tmp := check_dead_lock(r.lock_id);
  end loop;
 end clear_dead_locks;
 ----------------------------------------------------------

 ----------------------------------------------------------
 function set_modify_info$$(aid in integer) return pls_integer as
 tmp integer;
 usr varchar2(30) := current_user;
 begin
  begin
   select id into tmp from vfs where id = aid for update nowait;
  exception
   when NO_DATA_FOUND then
    return set_error(ERR_INVALID_PARAMETER,aid);
   when E_ORA_RESOURCE_BUSY then
    return set_error(ERR_BUSY);
  end;
  update vfs
  set modify_date = sysdate,
      modify_subj_id = usr
  where id = aid;
  return set_error(ERR_SUCCESS);
 end set_modify_info$$;
 ----------------------------------------------------------
 function set_modify_info$$_auto(aid in integer) return pls_integer as
 pragma autonomous_transaction;
 result pls_integer;
 begin
  result := set_modify_info$$(aid);
  commit;
  return result;
 end set_modify_info$$_auto;
 ----------------------------------------------------------
 procedure size_changed(aid in integer, ad_size in number) as
 begin
  update vfs set data_size = data_size + ad_size
  where id = aid;
 end size_changed;
 ----------------------------------------------------------

 ----------------------------------------------------------
 function check_name(aname in varchar2) return pls_integer as
 begin
  if ltrim(rtrim(aname)) is null /*only spaces*/ or
     instr(translate(aname,BAD_SYMBOLS,rpad('?',length(BAD_SYMBOLS),'?')),'?') <> 0 /*bad symbols*/ then
   return set_error(ERR_INVALID_NAME,aname);
  end if;
  return set_error(ERR_SUCCESS);
 end check_name;
 ----------------------------------------------------------
 function check_name_uniqueness(aname in varchar2, aparent_id in integer, atype in integer) return pls_integer as
 tmp integer;
 nm varchar2(512);
 parent_type integer;
 usr varchar2(30) := current_user;
 begin
  if atype = VFS_FILE and aparent_id is not null then
   --check if parent is temporary folder
   begin
    select type into parent_type from vfs where id = aparent_id;
   exception
    when NO_DATA_FOUND then return set_error(ERR_INVALID_PARAMETER,aparent_id);
   end;
  end if;
  if    atype = VFS_FILE and parent_type > 0 then
   if CASE_SENSITIVE then
    select id into tmp from vfs
    where parent_id = aparent_id and
          name = aname and
          (owner_id = usr or type >= 0);
   else
    select id into tmp from vfs
    where parent_id = aparent_id and
          upper(name) = upper(aname) and
          (owner_id = usr or type >= 0) and
          rownum = 1;
   end if;
  elsif aparent_id is not null then
   if CASE_SENSITIVE then
    select id into tmp from vfs
    where parent_id = aparent_id and
          name = aname;
   else
    select id into tmp from vfs
    where parent_id = aparent_id and
          upper(name) = upper(aname) and
          rownum = 1;
   end if;
  else
   if CASE_SENSITIVE then
    select id into tmp from vfs
    where parent_id is null and
          name = aname;
   else
    select id into tmp from vfs
    where parent_id is null and
          upper(name) = upper(aname) and
          rownum = 1;
   end if;
  end if;
  if atype = VFS_FILE and SILENT_OVERWRITE then
   tmp := remove$(tmp,false,false);
   if tmp <> ERR_SUCCESS then
    return tmp;
   else
    return check_name_uniqueness(aname,aparent_id,atype);
   end if;
  else
   return set_error(ERR_NAME_EXISTS,aname,aparent_id);
  end if;
 exception
  when NO_DATA_FOUND then return set_error(ERR_SUCCESS);
 end;
 ----------------------------------------------------------
 function check_charset(acharset in varchar2) return pls_integer as
 tmp integer;
 begin
  if acharset is null then return set_error(ERR_SUCCESS); end if;
  select 1 into tmp from v$nls_valid_values where parameter = 'CHARACTERSET' and value = acharset;
  return set_error(ERR_SUCCESS);
 exception
  when NO_DATA_FOUND then return set_error(ERR_INVALID_CHARSET,acharset);
 end;
 ----------------------------------------------------------

 ----------------------------------------------------------
 function vfs_add(atype in number, aname in varchar2,
  aparent_id in integer, astorage_id in integer,
  aaccess_mask in pls_integer,
  acharset in varchar2,
  adescription in varchar2) return integer as
 result integer;
 parent_storage_id integer;
 parent_type integer;
 parent_charset varchar2(20);
 tmp pls_integer;
 stor_id integer;
 begin
  if aparent_id is null and astorage_id is null then
   stor_id := vfs_storage_mgr.get_default;
   if stor_id is null then return set_error(ERR_INVALID_PARAMETER); end if;
  else
   stor_id := astorage_id;
  end if;
  --is name correct?
  result := check_name(aname);
  if result <> ERR_SUCCESS then return result; end if;

  result := vfs_admin.check_access(aparent_id,vfs_admin.ACCESS_WRITE);
  if result <> ERR_SUCCESS then return result; end if;

  if aparent_id is not null then
   begin
    select storage_id,type,charset into parent_storage_id,parent_type,parent_charset
    from vfs where id = aparent_id;
   exception
    when NO_DATA_FOUND then return set_error(ERR_INVALID_PARAMETER,aparent_id);
   end;
  end if;

  if atype = VFS_FOLDER and parent_type > 0 then return set_error(ERR_NO_STATIC_FOLDER_IN_TEMP); end if;

  result := check_name_uniqueness(aname,aparent_id,atype);
  if result <> ERR_SUCCESS then return result; end if;

  if acharset is not null then
   tmp := check_charset(acharset);
   if tmp <> ERR_SUCCESS then return result; end if;
  end if;

  --insert header
  insert into vfs (id,storage_id,type,access_mask,name,charset,parent_id,description,owner_id)
  values (vfs_seq.nextval,
          nvl(stor_id,parent_storage_id),
          atype,
          aaccess_mask,
          aname,
          nvl(acharset,nvl(parent_charset,CURRENT_CHARSET)),
          aparent_id,
          adescription,
          current_user)
  returning id into result;

  --insert file data
  if atype = VFS_FILE then
   insert into vfs_data (id,storage_id,data)
   values (result,nvl(stor_id,parent_storage_id),empty_blob());
  end if;

  if aparent_id is not null then
   tmp := set_modify_info$$_auto(aparent_id);
  end if;

  return result;
 end vfs_add;
 ----------------------------------------------------------
 function create_folder$$(aname in varchar2,
  aparent_id in integer, astorage_id in integer,
  aothers_access_mask in pls_integer,
  alifetime in number,
  acharset in varchar2,
  adescription in varchar2) return integer as
 am pls_integer;
 begin
  if not vfs_admin.can_make_dir then return set_error(ERR_NOT_ENOUGH_PRIVILEGE); end if;

  if alifetime < 0 then return set_error(ERR_INVALID_PARAMETER,alifetime); end if;

  if aothers_access_mask = vfs_admin.ACCESS_PARENT then
   begin
    select access_mask into am from vfs where id = aparent_id;
   exception
    when NO_DATA_FOUND then am := vfs_admin.ACCESS_NONE;
   end;
  end if;

  return vfs_add(nvl(alifetime,VFS_FOLDER),aname,aparent_id,astorage_id,am,acharset,adescription);
 end create_folder$$;
 ----------------------------------------------------------
 function create_folder$$_auto(aname in varchar2,
  aparent_id in integer, astorage_id in integer,
  aothers_access_mask in integer,
  alifetime in number,
  acharset in varchar2,
  adescription in varchar2) return integer as
 pragma autonomous_transaction;
 result integer;
 begin
  result := create_folder$$(aname,aparent_id,astorage_id,aothers_access_mask,alifetime,acharset,adescription);
  commit;
  return result;
 end create_folder$$_auto;
 ----------------------------------------------------------
 function create_folder$(aname in varchar2,
  aparent_id in integer default null, astorage_id in integer default null,
  aothers_access_mask in pls_integer default vfs_admin.ACCESS_PARENT,
  alifetime in number default null,
  acharset in varchar2 default null,
  adescription in varchar2 default null,
  aautonomous in boolean default true) return integer as
 begin
  check_open;

  write_log('MSG','create_folder(' ||
   'name=>' || aname || ',' ||
   'parent_id=>' || aparent_id || ',' ||
   'storage_id=>' || astorage_id || ',' ||
   'lifetime=>' || alifetime || ');',2);

  if aautonomous then
   return create_folder$$_auto(aname,aparent_id,astorage_id,aothers_access_mask,alifetime,acharset,adescription);
  else
   return create_folder$$(aname,aparent_id,astorage_id,aothers_access_mask,alifetime,acharset,adescription);
  end if;
 end create_folder$;
 ----------------------------------------------------------
 function create_file$$(aname in varchar2,
  aparent_id in integer, astorage_id in integer,
  aothers_access_mask in pls_integer,
  acharset in varchar2,
  adescription in varchar2) return integer as
 begin
  return vfs_add(vfs_file,aname,aparent_id,astorage_id,aothers_access_mask,acharset,adescription);
 end create_file$$;
 ----------------------------------------------------------
 function create_file$$_auto(aname in varchar2,
  aparent_id in integer, astorage_id in integer,
  aothers_access_mask in pls_integer,
  acharset in varchar2,
  adescription in varchar2) return integer as
 pragma autonomous_transaction;
 result integer;
 begin
  result := create_file$$(aname,aparent_id,astorage_id,aothers_access_mask,acharset,adescription);
  commit;
  return result;
 end create_file$$_auto;
 ----------------------------------------------------------
 function create_file$(aname in varchar2,
  aparent_id in integer default null, astorage_id in integer default null,
  aothers_access_mask in integer default vfs_admin.ACCESS_PARENT,
  acharset in varchar2 default null,
  adescription in varchar2 default null,
  aautonomous in boolean default true) return integer as
 begin
  check_open;

  write_log('MSG','create_file(' ||
   'name=>' || aname || ',' ||
   'parent_id=>' || aparent_id || ',' ||
   'storage_id=>' || astorage_id || ');',2);


  if aautonomous then
   return create_file$$_auto(aname,aparent_id,astorage_id,aothers_access_mask,acharset,adescription);
  else
   return create_file$$(aname,aparent_id,astorage_id,aothers_access_mask,acharset,adescription);
  end if;
 end create_file$;
 ----------------------------------------------------------
 function remove$$(aid in integer, acascade in boolean) return pls_integer as
 f_parent_id integer;
 tmp pls_integer;
 begin
  if not vfs_admin.can_make_dir then
   return set_error(ERR_NOT_ENOUGH_PRIVILEGE);
  end if;

  tmp := vfs_admin.check_access(aid,vfs_admin.ACCESS_WRITE);
  if tmp <> ERR_SUCCESS then return tmp; end if;

  f_parent_id := get_parent$(aid);
  if f_parent_id < ERR_SUCCESS then return f_parent_id; end if;

  tmp := vfs_admin.check_access(f_parent_id,vfs_admin.ACCESS_WRITE);
  if tmp <> ERR_SUCCESS then return tmp; end if;

  savepoint sp;

  tmp := check_lock(aid,LOCK_FULL);
  if tmp <> ERR_SUCCESS then rollback to savepoint sp; return tmp; end if;

  if acascade then
   --first delete all children
   for r in (select id from vfs where parent_id = aid) loop
    tmp := remove$$(r.id,acascade);
    if tmp <> ERR_SUCCESS then rollback to savepoint sp; return tmp; end if;
   end loop;
  end if;

  --try to delete
  --if exception - the item has some children (it is folder and acascade = false)
  begin
   delete from vfs where id = aid;

   if f_parent_id is not null then
    tmp := set_modify_info$$_auto(f_parent_id);
   end if;

   return set_error(ERR_SUCCESS);
  exception
   when E_ORA_CHILD_RECORD then return set_error(ERR_NOT_EMPTY,aid);
  end;
 end remove$$;
 ----------------------------------------------------------
 function remove$$_auto(aid in integer, acascade in boolean) return pls_integer as
 pragma autonomous_transaction;
 result pls_integer;
 begin
  result := remove$$(aid,acascade);
  commit;
  return result;
 end remove$$_auto;
 ----------------------------------------------------------
 function remove$(aid in integer, acascade in boolean default false, aautonomous in boolean default true) return pls_integer as
 begin
  check_open;

  write_log('MSG','remove(' || 'id=>' || aid || ');',2);

  if aautonomous then
   return remove$$_auto(aid,acascade);
  else
   return remove$$(aid,acascade);
  end if;
 end remove$;
 ----------------------------------------------------------
 function move$$(aid in integer, anew_parent_id in integer, anew_name in varchar2) return pls_integer as
 f_parent_id integer;
 f_name varchar2(512);
 f_type integer;
 sz number;
 tmp pls_integer;
 begin
  tmp := vfs_admin.check_access(aid,vfs_admin.ACCESS_FULL);
  if tmp <> ERR_SUCCESS then return tmp; end if;
  tmp := vfs_admin.check_access(anew_parent_id,vfs_admin.ACCESS_WRITE);
  if tmp <> ERR_SUCCESS then return tmp; end if;

  begin
   select parent_id,data_size,name,type into f_parent_id,sz,f_name,f_type from vfs where id = aid;
  exception
   when NO_DATA_FOUND then return set_error(ERR_INVALID_PARAMETER,aid);
  end;

  if f_type <> VFS_FILE then
   if not vfs_admin.can_make_dir then
    return set_error(ERR_NOT_ENOUGH_PRIVILEGE);
   end if;
  end if;

  tmp := vfs_admin.check_access(f_parent_id,vfs_admin.ACCESS_WRITE);
  if tmp <> ERR_SUCCESS then return tmp; end if;

  if anew_name is not null then f_name := anew_name; end if;
  tmp := check_name_uniqueness(f_name,anew_parent_id,f_type);
  if tmp <> ERR_SUCCESS then return tmp; end if;

  savepoint sp;

  tmp := check_lock(aid,LOCK_READ);
  if tmp <> ERR_SUCCESS then rollback to savepoint sp; return tmp; end if;

  update vfs
  set parent_id = anew_parent_id,
      name = f_name
  where id = aid;
  tmp := set_modify_info$$(aid);

  --modify dates of old and new parents
  if f_parent_id is not null then
   tmp := set_modify_info$$_auto(f_parent_id);
  end if;
  if anew_parent_id is not null then
   tmp := set_modify_info$$_auto(anew_parent_id);
  end if;

  return set_error(ERR_SUCCESS);
 end move$$;
 ----------------------------------------------------------
 function move$$_auto(aid in integer, anew_parent_id in integer, anew_name in varchar2) return pls_integer as
 pragma autonomous_transaction;
 result pls_integer;
 begin
  result := move$$(aid,anew_parent_id,anew_name);
  commit;
  return result;
 end move$$_auto;
 ----------------------------------------------------------
 function move$(aid in integer, anew_parent_id in integer, anew_name in varchar2 default null,
  aautonomous in boolean default true) return pls_integer as
 begin
  check_open;

  write_log('MSG','move(' ||
   'id=>' || aid || ',' ||
   'new_parent_id=>' || anew_parent_id || ',' ||
   'new_name=>' || anew_name || ');',2);

  if aautonomous then
   return move$$_auto(aid,anew_parent_id,anew_name);
  else
   return move$$(aid,anew_parent_id,anew_name);
  end if;
 end move$;
 ----------------------------------------------------------
 function store$$(aid in integer, anew_storage_id in integer, acascade in boolean) return pls_integer as
 tmp pls_integer;
 begin
  tmp := vfs_admin.check_access(aid,vfs_admin.ACCESS_WRITE);
  if tmp <> ERR_SUCCESS then return tmp; end if;

  savepoint sp;

  tmp := check_lock(aid,LOCK_FULL);
  if tmp <> ERR_SUCCESS then rollback to savepoint sp; return tmp; end if;

  if acascade then
   for r in (select id from vfs where parent_id = aid) loop
    tmp := store$$(r.id,anew_storage_id,acascade);
    if tmp <> ERR_SUCCESS then rollback to savepoint sp; return tmp; end if;
   end loop;
  end if;

  update vfs set storage_id = anew_storage_id where id = aid;
  update vfs_data set storage_id = anew_storage_id where id = aid;

  return set_error(ERR_SUCCESS);
 end store$$;
 ----------------------------------------------------------
 function store$$_auto(aid in integer, anew_storage_id in integer, acascade in boolean) return pls_integer as
 pragma autonomous_transaction;
 result pls_integer;
 begin
  result := store$$(aid,anew_storage_id,acascade);
  commit;
  return result;
 end store$$_auto;
 ----------------------------------------------------------
 function store$(aid in integer, anew_storage_id in integer, acascade in boolean default false,
  aautonomous in boolean default true) return pls_integer as
 begin
  check_open;

  write_log('MSG','store(' ||
   'id=>' || aid || ',' ||
   'new_storage_id=>' || anew_storage_id || ');',2);

  if aautonomous then
   return store$$_auto(aid,anew_storage_id,acascade);
  else
   return store$$(aid,anew_storage_id,acascade);
  end if;
 end store$;
 ----------------------------------------------------------
 function rename$$(aid in integer, anew_name in varchar2) return pls_integer as
 f_parent_id integer;
 f_type integer;
 tmp pls_integer;
 begin
  tmp := vfs_admin.check_access(aid,vfs_admin.ACCESS_WRITE);
  if tmp <> ERR_SUCCESS then return tmp; end if;

  begin
   select parent_id,type into f_parent_id,f_type from vfs where id = aid;
  exception
   when NO_DATA_FOUND then return set_error(ERR_INVALID_PARAMETER,aid);
  end;

  if f_type <> VFS_FILE then
   if not vfs_admin.can_make_dir then
    return set_error(ERR_NOT_ENOUGH_PRIVILEGE);
   end if;
  end if;

  tmp := vfs_admin.check_access(f_parent_id,vfs_admin.ACCESS_WRITE);
  if tmp <> ERR_SUCCESS then return tmp; end if;

  tmp := check_name(anew_name);
  if tmp <> ERR_SUCCESS then return tmp; end if;
  tmp := check_name_uniqueness(anew_name,f_parent_id,f_type);
  if tmp <> ERR_SUCCESS then return tmp; end if;

  savepoint sp;

  tmp := check_lock(aid,LOCK_READ);
  if tmp <> ERR_SUCCESS then rollback to savepoint sp; return tmp; end if;

  update vfs set name = anew_name where id = aid;

  if f_parent_id is not null then
   tmp := set_modify_info$$_auto(f_parent_id);
  end if;

  return set_error(ERR_SUCCESS);
 end rename$$;
 ----------------------------------------------------------
 function rename$$_auto(aid in integer, anew_name in varchar2) return pls_integer as
 pragma autonomous_transaction;
 result pls_integer;
 begin
  result := rename$$(aid,anew_name);
  commit;
  return result;
 end rename$$_auto;
 ----------------------------------------------------------
 function rename$(aid in integer, anew_name in varchar2, aautonomous in boolean default true) return pls_integer as
 begin
  check_open;

  write_log('MSG','rename(' ||
   'id=>' || aid || ',' ||
   'new_name=>' || anew_name || ');',2);

  if aautonomous then
   return rename$$_auto(aid,anew_name);
  else
   return rename$$(aid,anew_name);
  end if;
 end rename$;
 ----------------------------------------------------------
 function copy$$(aid in integer, aparent_id in integer, aname in varchar2) return integer as
 result integer;
 copy_name varchar2(512);
 copy_storage_id integer;
 copy_type integer;
 copy_description varchar2(4000);
 copy_access_mask integer;
 copy_size number;
 copy_charset varchar2(20);
 tmp pls_integer;
 begin
  tmp := vfs_admin.check_access(aid,vfs_admin.ACCESS_READ);
  if tmp <> ERR_SUCCESS then return tmp; end if;
  tmp := vfs_admin.check_access(aparent_id,vfs_admin.ACCESS_WRITE);
  if tmp <> ERR_SUCCESS then return tmp; end if;

  begin
   select name,storage_id,type,description,access_mask,data_size,charset
   into copy_name,copy_storage_id,copy_type,copy_description,copy_access_mask,copy_size,copy_charset
   from vfs where id = aid;
  exception
   when NO_DATA_FOUND then return set_error(ERR_INVALID_PARAMETER);
  end;

  if copy_type <> VFS_FILE then
   if not vfs_admin.can_make_dir then
   return set_error(ERR_NOT_ENOUGH_PRIVILEGE);
   end if;
  end if;

  savepoint sp;

  tmp := check_lock(aid,LOCK_READ);
  if tmp <> ERR_SUCCESS then rollback to savepoint sp; return tmp; end if;

  --insert new item
  if aname is not null then copy_name := aname; end if;
  result := vfs_add(copy_type,copy_name,aparent_id,copy_storage_id,copy_access_mask,copy_charset,copy_description);
  if result < ERR_SUCCESS then rollback to savepoint sp; return result; end if;


  if copy_type >= vfs_folder then
   --copy children
   for r in (select id from vfs where parent_id = aid) loop
    tmp := copy$(r.id,result);
    if tmp < ERR_SUCCESS then rollback to savepoint sp; return result; end if;
   end loop;
  else
   --copy file data
   update vfs_data set data = (select data from vfs_data where id = aid) where id = result;
   size_changed(result,copy_size);
  end if;

  return copy_size;
 end copy$$;
 ----------------------------------------------------------
 function copy$$_auto(aid in integer, aparent_id in integer, aname in varchar2) return integer as
 pragma autonomous_transaction;
 result integer;
 begin
  result := copy$$(aid,aparent_id,aname);
  commit;
  return result;
 end copy$$_auto;
 ----------------------------------------------------------
 function copy$(aid in integer, aparent_id in integer, aname in varchar2 default null,
  aautonomous in boolean default true) return integer as
 begin
  check_open;

  write_log('MSG','copy(' ||
   'id=>' || aid || ',' ||
   'parent_id=>' || aparent_id || ',' ||
   'name=>' || aname || ');',2);

  if aautonomous then
   return copy$$_auto(aid,aparent_id,aname);
  else
   return copy$$(aid,aparent_id,aname);
  end if;
 end copy$;
 ----------------------------------------------------------
 function set_description$$(aid in integer, adescription in varchar2) return pls_integer as
 tmp pls_integer;
 begin
  tmp := vfs_admin.check_access(aid,vfs_admin.ACCESS_WRITE);
  if tmp <> ERR_SUCCESS then return tmp; end if;

  savepoint sp;

  tmp := check_lock(aid,LOCK_READ);
  if tmp <> ERR_SUCCESS then rollback to savepoint sp; return tmp; end if;

  update vfs set description = adescription where id = aid;

  tmp := set_modify_info$$(aid);

  return set_error(ERR_SUCCESS);
 end set_description$$;
 ----------------------------------------------------------
 function set_description$$_auto(aid in integer, adescription in varchar2) return pls_integer as
 pragma autonomous_transaction;
 result pls_integer;
 begin
  result := set_description$$_auto(aid,adescription);
  commit;
  return result;
 end set_description$$_auto;
 ----------------------------------------------------------
 function set_description$(aid in integer, adescription in varchar2, aautonomous in boolean default true) return pls_integer as
 begin
  check_open;
  if aautonomous then
   return set_description$$_auto(aid,adescription);
  else
   return set_description$$(aid,adescription);
  end if;
 end set_description$;
 ----------------------------------------------------------
 function remove_temporary$(aautonomous in boolean default true) return pls_integer as
 tmp pls_integer;
 begin
  check_open;
  savepoint sp;
  for r in (select v2.id from vfs v1, vfs v2 where v1.type > 0 and v2.parent_id = v1.id and v2.modify_date - sysdate > v1.type) loop
   tmp := remove$(r.id,aautonomous);
   if tmp <> ERR_SUCCESS then rollback to savepoint sp; return tmp; end if;
  end loop;
  return set_error(ERR_SUCCESS);
 end remove_temporary$;
 ----------------------------------------------------------

 ----------------------------------------------------------
 function is_folder$(aid in integer) return boolean as
 tp integer;
 begin
  check_open;
  if aid is null then
   tp := 0;
  else
   select type into tp from vfs where id = aid;
  end if;
  return tp >= vfs_folder;
 exception
  when NO_DATA_FOUND then return false;
 end is_folder$;
 ----------------------------------------------------------
 function get_id_by_name$(apath in varchar2, apath_separator in char default PATH_SEPARATOR) return integer as
 str varchar2(4000) := apath;
 cpos integer;
 ppos integer;
 cid integer;
 pid integer;
 p_type integer;
 cstr varchar2(4000);
 c_user varchar2(30);
 begin
  check_open;
  c_user := current_user;
  if str = apath_separator then return null; end if;
  str := substr(str,2);
  if not CASE_SENSITIVE then str := upper(str); end if;
  cpos := 0;
  cid := null;
  p_type := 0;
  loop
   pid := cid;
   ppos := cpos;
   cpos := instr(str,apath_separator,ppos + 1);
   if cpos = 0 then
    cstr := substr(str,ppos + 1);
   else
    cstr := substr(str,ppos + 1,cpos - ppos - 1);
   end if;
   if pid is null then
    if not CASE_SENSITIVE then
     select id,type into cid,p_type from vfs where parent_id is null and cstr = upper(name) and rownum = 1;
    else
     select id,type into cid,p_type from vfs where parent_id is null and name = cstr;
    end if;
   else
    if p_type = 0 then
     if not CASE_SENSITIVE then
      select id,type into cid,p_type from vfs where parent_id = pid and cstr = upper(name) and rownum = 1;
     else
      select id,type into cid,p_type from vfs where parent_id = pid and name = cstr;
     end if;
    else
     if not CASE_SENSITIVE then
      select id,type into cid,p_type from vfs where parent_id = pid and name = upper(cstr) and (owner_id = c_user or type >= 0) and rownum = 1;
     else
      select id,type into cid,p_type from vfs where parent_id = pid and name = cstr and (owner_id = c_user or type >= 0) and rownum = 1;
     end if;
    end if;
   end if;
   exit when cpos = 0;
  end loop;
  return cid;
 exception
  when NO_DATA_FOUND then return set_error(ERR_INVALID_PATH,apath);
 end get_id_by_name$;
 ----------------------------------------------------------
 function get_name_by_id$(aid in integer, apath_separator in char default PATH_SEPARATOR) return varchar2 as
 result varchar2(4000);
 begin
  check_open;
  for r in (select name from vfs connect by prior parent_id = id start with id = aid) loop
   result := apath_separator || r.name || result;
  end loop;
  return result;
 end get_name_by_id$;
 ----------------------------------------------------------
 function get_parent$(aid in integer) return integer as
 result integer;
 begin
  check_open;
  select parent_id into result from vfs where id = aid;
  return result;
 exception
  when NO_DATA_FOUND then return set_error(ERR_INVALID_PARAMETER,aid);
 end get_parent$;
 ----------------------------------------------------------
 function info$(aid in integer,
  aname out varchar2,
  atype out number,
  aowner out varchar2,
  asize out number,
  aothers_access_mask out pls_integer,
  asubject_access_mask out pls_integer,
  acreate_date out date,
  amodify_date out date,
  acharset out varchar2,
  aparent_id out integer,
  astorage_id out integer,
  adescription out varchar2) return pls_integer as
 begin
  check_open;

  write_log('MSG','info(' ||
   'id=>' || aid || ');',3);

  select name,type,owner_id,data_size,create_date,modify_date,charset,storage_id,parent_id,description
  into aname,atype,aowner,asize,acreate_date,amodify_date,acharset,astorage_id,aparent_id,adescription
  from vfs where id = aid;

  aothers_access_mask := vfs_admin.get_others_access(aid);
  asubject_access_mask := vfs_admin.get_subject_access(aid);

  return set_error(ERR_SUCCESS);
 exception
  when NO_DATA_FOUND then return set_error(ERR_INVALID_HANDLE,aid);
 end info$;
 ----------------------------------------------------------

 ----------------------------------------------------------
 function reset_locator(afile in HFILE, alock in boolean default null) return pls_integer as
 begin
  if not alock or (alock is null and file_list(afile).open_mode = MODE_READ) then
   select data into file_list(afile).locator from vfs_data where id = file_list(afile).id;
  else
   select data into file_list(afile).locator from vfs_data where id = file_list(afile).id for update;
  end if;
  return set_error(ERR_SUCCESS);
 exception
  when NO_DATA_FOUND then return set_error(ERR_INVALID_HANDLE,afile);
 end reset_locator;
 ----------------------------------------------------------
 function open_mode2access_mode(amode in char, aexclusive in boolean) return pls_integer as
 begin
  if    amode = MODE_READ                then if aexclusive then return vfs_admin.ACCESS_RX;
                                                            else return vfs_admin.ACCESS_R;
                                              end if;
  elsif amode = MODE_WRITE               then if aexclusive then return vfs_admin.ACCESS_WX;
                                                            else return vfs_admin.ACCESS_W;
                                              end if;
  elsif amode in (MODE_FULL,MODE_APPEND) then if aexclusive then return vfs_admin.ACCESS_RWX;
                                                            else return vfs_admin.ACCESS_RW;
                                              end if;
  else return set_error(ERR_INVALID_MODE,amode);
  end if;
 end;
 ----------------------------------------------------------
 function is_open$(afile in HFILE) return boolean as
 begin
  check_open;
  return file_list.exists(afile);
 end is_open$;
 ----------------------------------------------------------
 function size$(afile in HFILE) return integer as
 tmp pls_integer;
 begin
  check_open;
  tmp := reset_locator(afile,false);
  if tmp <> ERR_SUCCESS then return tmp; end if;
  return dbms_lob.getlength(file_list(afile).locator);
 exception
  when NO_DATA_FOUND then return set_error(ERR_INVALID_HANDLE,afile);
 end size$;
 ----------------------------------------------------------
 function eof$(afile in integer) return boolean as
 begin
  check_open;
  return file_list(afile).pos > size$(afile);
 exception
  when NO_DATA_FOUND then return false;
 end eof$;
 ----------------------------------------------------------
 procedure clear_data$$(aid in integer) as
 b blob;
 sz integer;
 begin
  select data into b from vfs_data where id = aid for update;
  sz := dbms_lob.getlength(b);
  update vfs_data set data = empty_blob() where id = aid;
  size_changed(aid,-sz);
 end clear_data$$;
 ----------------------------------------------------------
 procedure clear_data$$_auto(aid in integer) as
 pragma autonomous_transaction;
 begin
  clear_data$$(aid);
  commit;
 end clear_data$$_auto;
 ----------------------------------------------------------
 function open$(aid in integer, amode in char default MODE_READ,
  aexclusive in boolean default false,
  aautonomous in boolean default true) return HFILE as
 result HFILE;
 md char;
 am pls_integer;
 tmp pls_integer;
 begin
  check_open;

  write_log('MSG','open(' ||
   'id=>' || aid || ',' || 'mode=>' || amode || ');',3);

  md := upper(amode);

  am := open_mode2access_mode(md,aexclusive);
  if am < ERR_SUCCESS then return am; end if;

  tmp := vfs_admin.check_access(aid,am);
  if tmp <> ERR_SUCCESS then return tmp; end if;

  result := file_list.count + 1;

  tmp := lock_vfs(aid,am,result);
  if tmp <> ERR_SUCCESS then file_list.delete(result); return tmp; end if;

  begin
   file_list(result).id := aid;
   file_list(result).path := get_name_by_id$(aid);
   file_list(result).open_mode := md;
   file_list(result).autonomous := aautonomous;
   select charset into file_list(result).charset from vfs where id = file_list(result).id;

   if file_list(result).open_mode = MODE_WRITE then
    if aautonomous then
     clear_data$$_auto(aid);
    else
     clear_data$$(aid);
    end if;
   end if;

   file_list(result).pos := 0;
  end;

  return result;
 end open$;
 ----------------------------------------------------------
 function close$(afile in HFILE) return pls_integer as
 tmp pls_integer;
 begin
  check_open;

  write_log('MSG','close(' ||
   'file=>' || afile || ');',3);

  tmp := unlock_vfs(file_list(afile).id,afile);
  file_list.delete(afile);
  return set_error(ERR_SUCCESS);
 exception
  when NO_DATA_FOUND then return set_error(ERR_INVALID_HANDLE,afile);
 end close$;
 ----------------------------------------------------------
 procedure close_all$ as
 i HFILE;
 tmp pls_integer;
 begin
  check_open;
  i := file_list.first;
  while i is not null loop
   tmp := close$(i);
   i := file_list.next(i);
  end loop;
 exception
  when NO_DATA_FOUND then null;
 end close_all$;
 ----------------------------------------------------------
 function seek$(afile in HFILE, aoffset in integer, aorigin in integer default SB_BEGIN) return pls_integer as
 sz integer;
 fbase integer;
 newpos integer;
 begin
  check_open;

  write_log('MSG','seek(' ||
   'file=>' || afile || ',' || 'offset=>' || aoffset || ',' || 'origin=>' || aorigin || ');',4);

  sz := size$(afile);
  if sz < ERR_SUCCESS then return sz; end if;
  if    aorigin = SB_BEGIN   then fbase := 0;
  elsif aorigin = SB_CURRENT then fbase := file_list(afile).pos;
  elsif aorigin = SB_END     then fbase := sz;
  else return set_error(ERR_INVALID_PARAMETER,aorigin);
  end if;
  newpos := fbase + aoffset;
  if newpos < 0 then
   return set_error(ERR_INVALID_PARAMETER,aorigin);
  end if;
  file_list(afile).pos := newpos;
  return file_list(afile).pos;
 exception
  when NO_DATA_FOUND then return set_error(ERR_INVALID_HANDLE,afile);
 end seek$;
----------------------------------------------------------
function read$$(afile in HFILE, abuffer out nocopy raw, acount in integer) return pls_integer as
  tmp pls_integer;
begin
  tmp := reset_locator(afile);
  if tmp <> ERR_SUCCESS then
    return tmp;
  end if;
  if acount = 0 or acount is null then
    tmp := dbms_lob.instr(file_list(afile).locator,RLF,file_list(afile).pos + 1);
    if tmp>0 then
      tmp := tmp - file_list(afile).pos;
    else
      tmp := 32767;
    end if;
  else
    tmp := acount;
  end if;
  if tmp>32767 then
    tmp := 32767;
  end if;
  dbms_lob.read(file_list(afile).locator,tmp,file_list(afile).pos + 1,abuffer);
  if tmp>0 then
    file_list(afile).pos := file_list(afile).pos + tmp;
  end if;
  return tmp;
exception
  when NO_DATA_FOUND then return set_error(ERR_SUCCESS);
end read$$;
 ----------------------------------------------------------
 function read$$_auto(afile in HFILE, abuffer out nocopy raw, acount in integer) return pls_integer as
 pragma autonomous_transaction;
 result pls_integer;
 begin
  result := read$$(afile,abuffer,acount);
  commit;
  return result;
 end read$$_auto;
 ----------------------------------------------------------
 function read$(afile in HFILE, abuffer out raw, acount in integer default null) return pls_integer as
 begin
  check_open;

  write_log('MSG','read(' ||
   'file=>' || afile || ',' || 'count=>' || acount || ');',4);

  if file_list(afile).open_mode = MODE_WRITE then return set_error(ERR_NOT_IN_READ_MODE,afile); end if;
  if file_list(afile).autonomous then
   return read$$_auto(afile,abuffer,acount);
  else
   return read$$(afile,abuffer,acount);
  end if;
 exception
  when NO_DATA_FOUND then return set_error(ERR_INVALID_HANDLE,afile);
 end read$;
 ----------------------------------------------------------
 function write$$(afile in HFILE, abuffer in raw, acount in integer) return pls_integer as
 c integer;
 l integer;
 s integer;
 p integer;
 tmp pls_integer;
 begin
  l := utl_raw.length(abuffer);
  s := size$(afile);
  if s < ERR_SUCCESS then return s; end if;
  if acount > l or nvl(acount,0) = 0 then c := l; else c := acount; end if;
  if file_list(afile).open_mode <> MODE_APPEND then
   p := file_list(afile).pos + 1;
  else
   p := s + 1;
  end if;
  tmp := reset_locator(afile);
  if tmp < ERR_SUCCESS then return tmp; end if;
  dbms_lob.write(file_list(afile).locator,c,p,abuffer);
  if file_list(afile).open_mode <> MODE_APPEND then
   file_list(afile).pos := file_list(afile).pos + c;
   if file_list(afile).pos > s then
    size_changed(file_list(afile).id,file_list(afile).pos - s);
   end if;
  else
   size_changed(file_list(afile).id,c - 1);
  end if;
  tmp := set_modify_info$$(file_list(afile).id);
  return c;
 end write$$;
 ----------------------------------------------------------
 function write$$_auto(afile in HFILE, abuffer in raw, acount in integer) return pls_integer as
 pragma autonomous_transaction;
 result pls_integer;
 begin
  result := write$$(afile,abuffer,acount);
  commit;
  return result;
 end write$$_auto;
 ----------------------------------------------------------
 function write$(afile in HFILE, abuffer in raw, acount in integer default null) return pls_integer as
 begin
  check_open;

  write_log('MSG','write(' ||
   'file=>' || afile || ',' || 'count=>' || acount || ');',4);

  if file_list(afile).open_mode = MODE_READ then return set_error(ERR_NOT_IN_WRITE_MODE,afile); end if;
  if file_list(afile).autonomous then
   return write$$_auto(afile,abuffer,acount);
  else
   return write$$(afile,abuffer,acount);
  end if;
 exception
  when NO_DATA_FOUND then return set_error(ERR_INVALID_HANDLE,afile);
 end write$;
 ----------------------------------------------------------
 function get_file_name$(afile in HFILE) return varchar2 as
 begin
  check_open;
  return file_list(afile).path;
 exception
  when NO_DATA_FOUND then return null;
 end get_file_name$;
 ----------------------------------------------------------
 function get_file_id$(afile in HFILE) return integer as
 begin
  check_open;
  return file_list(afile).id;
 exception
  when NO_DATA_FOUND then return set_error(ERR_INVALID_HANDLE,afile);
 end get_file_id$;

----------------------------------------------------------
function cread$(afile in HFILE, abuffer out varchar2, acount in integer default null) return pls_integer as
  r raw(32767);
  result pls_integer;
begin
  result := read$(afile,r,acount);
  if result > ERR_SUCCESS then
    if file_list(afile).charset=CURRENT_CHARSET then
      abuffer := utl_raw.cast_to_varchar2(r);
    else
      abuffer := convert(utl_raw.cast_to_varchar2(r),file_list(afile).charset,CURRENT_CHARSET);
    end if;
  end if;
  return result;
exception
  when NO_DATA_FOUND then return set_error(ERR_INVALID_HANDLE,afile);
end cread$;
----------------------------------------------------------
function cwrite$(afile in HFILE, abuffer in varchar2, acount in integer default null) return pls_integer as
  cnt pls_integer;
begin
  if acount > 0 then cnt := acount; else cnt := length(abuffer); end if;
  if file_list(afile).charset=CURRENT_CHARSET then
    return write$(afile,utl_raw.cast_to_raw(abuffer),cnt);
  else
    return write$(afile,utl_raw.cast_to_raw(convert(abuffer,CURRENT_CHARSET,file_list(afile).charset)),cnt);
  end if;
exception
  when NO_DATA_FOUND then return set_error(ERR_INVALID_HANDLE,afile);
end cwrite$;
 ----------------------------------------------------------
 function cread_str$(afile in HFILE, abuffer out varchar2, aeoln in varchar2 default EOLN) return pls_integer as
 c integer;
 buf varchar2(4000);
 tmp pls_integer;
 begin
  tmp := cread$(afile,buf,4000);
  c := instr(buf,aeoln);
  if c = 0 then
   abuffer := buf;
   c := tmp;
  else
   c := c + length(aeoln) - 1;
   abuffer := substr(buf,1,c);
   --move current position back
   tmp := seek$(afile,c - tmp,SB_CURRENT);
  end if;
  return c;
 exception
  when NO_DATA_FOUND then return set_error(ERR_INVALID_HANDLE,afile);
 end cread_str$;
 ----------------------------------------------------------
 function cwrite_str$(afile in HFILE, abuffer in varchar2, aeoln in varchar2 default EOLN) return pls_integer as
 begin
  return cwrite$(afile,abuffer=>abuffer||aeoln);
 end cwrite_str$;
 ----------------------------------------------------------

 ----------------------------------------------------------
 function get_file_list(aid in integer, amask in varchar2 default null,
  adir_flag in pls_integer default 0, asort in boolean default null) return varchar2 as
 result varchar2(4000);
 tmp pls_integer;
 begin
  tmp := process_error(get_file_list(result,aid,amask,adir_flag,asort));
  return result;
 end get_file_list;
 ----------------------------------------------------------
 function get_file_list(alist out varchar2, aid in integer, amask in varchar2 default null,
  adir_flag in pls_integer default 0, asort in boolean default null) return pls_integer as
 tmp pls_integer;
 f_name varchar2(512);
 f_id integer;
 cnt pls_integer;
 f HFOLDER;
 begin
  f := open_folder(aid,amask,adir_flag,asort);
  if f < ERR_SUCCESS then alist := null; return f; end if;

  alist := null;
  cnt := 0;
  loop
   tmp := read_folder(f,f_id,f_name);
   exit when tmp <= ERR_SUCCESS;
   alist := alist || f_name || LF;
   cnt:= cnt + 1;
  end loop;

  f := close_folder(f);

  if tmp < ERR_SUCCESS then alist := null; return tmp; end if;

  return cnt;
 end get_file_list;
 ----------------------------------------------------------
 function out_file_list(aid in integer, amask in varchar2 default null,
  adir_flag in pls_integer default 0, asort in boolean default null) return pls_integer as
 tmp pls_integer;
 flist varchar2(4000);
 begin
  tmp := get_file_list(flist,aid,amask,adir_flag,asort);
  if tmp > ERR_SUCCESS then dbms_output.put_line(flist); end if;
  return tmp;
 end out_file_list;
 ----------------------------------------------------------
 function make_cur(afolder in HFOLDER) return pls_integer as
 stmt varchar2(4000);
 msk varchar2(4000);
 begin
  if folder_list(afolder).mask is not null then
   msk := replace(folder_list(afolder).mask,'%','\%');
   msk := replace(msk,'_','\_');
   msk := translate(msk,'*?','%_');
  end if;

  stmt := 'select id,name,type,data_size,owner_id,create_date,modify_date,description,charset,storage_id,parent_id from vfs where ';

  if folder_list(afolder).id is null then stmt := stmt || 'parent_id is null ';
                                     else stmt := stmt || 'parent_id = :aid ';
  end if;

  if    bitand(folder_list(afolder).dir_flag,DF_FILE) <> 0 and bitand(folder_list(afolder).dir_flag,DF_FOLDER) <> 0 then
   null;
  elsif bitand(folder_list(afolder).dir_flag,DF_FILE) <> 0 then
   stmt := stmt || ' and type < 0 ';
  elsif bitand(folder_list(afolder).dir_flag,DF_FOLDER) <> 0 then
   stmt := stmt || ' and type >= 0 ';
  end if;

  if msk is not null then
   if CASE_SENSITIVE then
    stmt := stmt || ' and name like :amask escape ''\''';
   else
    stmt := stmt || ' and upper(name) like upper(:amask) escape ''\''';
   end if;
  end if;

  if folder_list(afolder).type > 0 then
   stmt := stmt || ' and (owner_id = ''' || current_user || ''' or type >= 0)';
  end if;

  if folder_list(afolder).sort is null then
   null;
  else
   if CASE_SENSITIVE then
    stmt := stmt || ' order by name';
   else
    stmt := stmt || ' order by upper(name)';
   end if;
   if folder_list(afolder).sort then
    stmt := stmt || ' asc';
   else
    stmt := stmt || ' desc';
   end if;
  end if;

  folder_list(afolder).cur := dbms_sql.open_cursor;
  dbms_sql.parse(folder_list(afolder).cur,stmt,dbms_sql.native);
  if folder_list(afolder).id is not null then
   dbms_sql.bind_variable(folder_list(afolder).cur,'aid',folder_list(afolder).id);
  end if;
  if msk is not null then
   dbms_sql.bind_variable(folder_list(afolder).cur,'amask',msk);
  end if;
  dbms_sql.define_column(folder_list(afolder).cur, 1, 1);--id
  dbms_sql.define_column(folder_list(afolder).cur, 2,'name',512);--name
  dbms_sql.define_column(folder_list(afolder).cur, 3, 3);--type
  dbms_sql.define_column(folder_list(afolder).cur, 4, 4);--data_size
  dbms_sql.define_column(folder_list(afolder).cur, 5,'owner_id',30);--owner_id
  dbms_sql.define_column(folder_list(afolder).cur, 6, sysdate);--create_date
  dbms_sql.define_column(folder_list(afolder).cur, 7, sysdate);--modify_date
  dbms_sql.define_column(folder_list(afolder).cur, 8,'description',4000);--description
  dbms_sql.define_column(folder_list(afolder).cur, 9,'charset',20);--charset
  dbms_sql.define_column(folder_list(afolder).cur,10,10);--storage_id
  dbms_sql.define_column(folder_list(afolder).cur,11,11);--parent_id

  return set_error(ERR_SUCCESS);
 end;
 ----------------------------------------------------------
 function open_folder(aid in integer, amask in varchar2 default null,
  adir_flag in pls_integer default 0, asort in boolean default null) return HFOLDER as
 result pls_integer;
 tmp pls_integer;
 begin
  check_open;

  write_log('MSG','open_folder(' ||
   'id=>' || aid || ',' || 'mask=>' || amask || ',' || 'dirflag=>' || adir_flag || ');',3);

  tmp := vfs_admin.check_access(aid,vfs_admin.ACCESS_READ);
  if tmp <> ERR_SUCCESS then return tmp; end if;

  result := file_list.count + 1;

  savepoint sp;

  if aid is not null then
   tmp := lock_vfs(aid,vfs_admin.ACCESS_READ,result);
   if tmp <> ERR_SUCCESS then
    rollback to savepoint sp;
    result := unlock_vfs(aid,result);
    return tmp;
   end if;
  end if;

  folder_list(result).id := aid;
  folder_list(result).mask := amask;
  folder_list(result).dir_flag := adir_flag;
  folder_list(result).sort := asort;
  folder_list(result).path := get_name_by_id$(aid);
  select type into tmp from vfs where id = aid;
  folder_list(result).type := tmp;

  tmp := make_cur(result);
  if tmp <> ERR_SUCCESS then
   rollback to savepoint sp;
   if aid is not null then result := unlock_vfs(folder_list(result).id,result); end if;
   folder_list.delete(result);
   return tmp;
  end if;

  tmp := reset_folder(result);
  if tmp <> ERR_SUCCESS then
   rollback to savepoint sp;
   if aid is not null then result := unlock_vfs(folder_list(result).id,result); end if;
   folder_list.delete(result);
   return tmp;
  end if;

  return result;
 end open_folder;
 ----------------------------------------------------------
 function get_folder_name(afolder in HFOLDER) return varchar2 as
 begin
  check_open;
  return folder_list(afolder).path;
 exception
  when NO_DATA_FOUND then return null;
 end get_folder_name;
 ----------------------------------------------------------
 function read_folder(afolder in HFOLDER,
  aid out integer,
  aname out varchar2,
  atype out number,
  aowner out varchar2,
  asize out number,
  aothers_access_mask out pls_integer,
  asubject_access_mask out pls_integer,
  acreate_date out date,
  amodify_date out date,
  acharset out varchar2,
  aparent_id out integer,
  astorage_id out integer,
  adescription out varchar2) return pls_integer as
 result pls_integer;
 begin
  result := read_folder(afolder,aid,aname);
  if result < ERR_SUCCESS then return result; end if;

  atype := null;
  aowner := null;
  asize := null;
  aothers_access_mask := null;
  asubject_access_mask := null;
  acreate_date := null;
  amodify_date := null;
  acharset := null;
  astorage_id := null;
  adescription := null;

  dbms_sql.column_value(folder_list(afolder).cur, 3,atype);
  dbms_sql.column_value(folder_list(afolder).cur, 4,asize);
  dbms_sql.column_value(folder_list(afolder).cur, 5,aowner);
  dbms_sql.column_value(folder_list(afolder).cur, 6,acreate_date);
  dbms_sql.column_value(folder_list(afolder).cur, 7,amodify_date);
  dbms_sql.column_value(folder_list(afolder).cur, 8,adescription);
  dbms_sql.column_value(folder_list(afolder).cur, 9,acharset);
  dbms_sql.column_value(folder_list(afolder).cur,10,astorage_id);
  dbms_sql.column_value(folder_list(afolder).cur,11,aparent_id);

  aothers_access_mask := vfs_admin.get_others_access(aid);
  asubject_access_mask := vfs_admin.get_subject_access(aid);

  return result;
 end read_folder /*full*/;
 ----------------------------------------------------------
 function read_folder(afolder in HFOLDER,
  aid out integer,
  aname out varchar2) return pls_integer as
 tmp integer;
 begin
  check_open;

  write_log('MSG','read_folder(' ||
   'folder=>' || afolder || ');',3);

  aid := null;
  aname := null;
  loop
   begin
    tmp := dbms_sql.fetch_rows(folder_list(afolder).cur);
   exception
    when E_ORA_FETCH_OUT_OF_SEQUENCE then return set_error(ERR_SUCCESS);
   end;
   if tmp <= 0 then return set_error(ERR_SUCCESS); end if;
   dbms_sql.column_value(folder_list(afolder).cur, 1,tmp);
   if bitand(folder_list(afolder).dir_flag,DF_ACCESSIBLE) = 0 or vfs_admin.is_accessible(tmp) then exit; end if;
  end loop;

  aid := tmp;
  dbms_sql.column_value(folder_list(afolder).cur, 2,aname);
  folder_list(afolder).count := folder_list(afolder).count + 1;

  return folder_list(afolder).count;
 exception
  when NO_DATA_FOUND then return set_error(ERR_INVALID_HANDLE,afolder);
 end read_folder /*short*/;
 ----------------------------------------------------------
 function reset_folder(afolder in HFOLDER) return pls_integer as
 c integer;
 begin
  check_open;

  write_log('MSG','reset_folder(' ||
   'folder=>' || afolder || ');',3);

  c := dbms_sql.execute(folder_list(afolder).cur);
  folder_list(afolder).count := 0;
  return set_error(ERR_SUCCESS);
 exception
  when NO_DATA_FOUND then return set_error(ERR_INVALID_HANDLE,afolder);
 end reset_folder;
 ----------------------------------------------------------
 function close_folder(afolder in HFOLDER) return pls_integer as
 tmp pls_integer;
 begin
  check_open;

  write_log('MSG','close_folder(' ||
   'folder=>' || afolder || ');',3);

  tmp := unlock_vfs(folder_list(afolder).id,afolder);
  dbms_sql.close_cursor(folder_list(afolder).cur);
  folder_list.delete(afolder);
  return set_error(ERR_SUCCESS);
 exception
  when NO_DATA_FOUND then return set_error(ERR_INVALID_HANDLE,afolder);
 end close_folder;
 ----------------------------------------------------------
 procedure close_all_folders as
 i HFOLDER;
 tmp pls_integer;
 begin
  check_open;
  i := folder_list.first;
  while i is not null loop
   tmp := close_folder(i);
   i := folder_list.next(i);
  end loop;
 exception
  when NO_DATA_FOUND then null;
 end close_all_folders;
 ----------------------------------------------------------

 ----------------------------------------------------------
 function find_env(aname in varchar2) return pls_integer as
 tmp pls_integer;
 nm varchar2(30);
 begin
  if CASE_SENSITIVE then nm := upper(aname); else nm := aname; end if;
  tmp := env_list.first;
  while tmp is not null loop
   if env_list(tmp).name = nm then return tmp; end if;
   tmp := env_list.next(tmp);
  end loop;
  return set_error(ERR_NO_DATA);
 end find_env;
 ----------------------------------------------------------
 function get_env(aname in varchar2) return varchar2 as
 tmp pls_integer;
 begin
  check_open;
  tmp := find_env(aname);
  if tmp < ERR_SUCCESS then return null; end if;
  return env_list(tmp).value;
 end get_env;
 ----------------------------------------------------------
 function put_env(aname in varchar2, avalue in varchar2) return number as
 tmp pls_integer;
 nm varchar2(30);
 begin
  check_open;
  if CASE_SENSITIVE then nm := upper(aname); else nm := aname; end if;
  tmp := find_env(aname);
  if tmp < ERR_SUCCESS then
   tmp := env_list.count + 1;
   env_list(tmp).name := nm;
   env_list(tmp).value := avalue;
  else
   env_list(tmp).value := avalue;
  end if;
  return set_error(ERR_SUCCESS);
 end put_env;
 ----------------------------------------------------------
 procedure clear_env as
 begin
  env_list.delete;
 end clear_env;
 ----------------------------------------------------------
 function make_dir_list(asource in varchar2, ahomedir in varchar2, arootdir in varchar2, areplacedir in varchar2) return varchar2 as
 cpos integer;
 ppos integer;
 cdir varchar2(4000);
 rd_l integer := nvl(length(areplacedir),0);
 chk varchar2(12) := '<CHECK_ROOT>';
 chk_l integer := 12;
 result varchar2(4000);
 begin
  if asource is null then return null; end if;
  cpos := 0;
  loop
   ppos := cpos;
   cpos := instr(asource,';',ppos + 1);
   if cpos = 0 then
    cdir := substr(asource,ppos + 1);
   else
    cdir := substr(asource,ppos + 1,cpos);
   end if;
   if cdir is not null then
    if cdir like chk || '%' then cdir := arootdir || substr(cdir,chk_l + 1) || PATH_SEPARATOR; end if;
    if rd_l > 0 and cdir like areplacedir || '%' then
     cdir := ahomedir || substr(cdir,rd_l + 1);
    end if;
    result := result || cdir;
   end if;
   exit when cpos = 0;
  end loop;
  return result;
 end make_dir_list;
 ----------------------------------------------------------
 procedure load_env as
 prof varchar2(30);
 v varchar2(4000);
 tmp pls_integer;
 begin
  prof := get_profile;
  for r in (select resource_name,value from profiles where profile = prof and resource_name like 'VFS%') loop
   tmp := put_env(r.resource_name,r.value);
  end loop;
  if prof <> 'DEFAULT' then
   for r in (select resource_name,value from profiles p1
             where profile = 'DEFAULT' and resource_name like 'VFS%' and
                   not exists(select resource_name from profiles p2
                              where p2.profile = prof and p2.resource_name = p1.resource_name)) loop
    tmp := put_env(r.resource_name,r.value);
   end loop;
  end if;

  PATH_SEPARATOR := nvl(substr(get_env('VFS_PATH_SEPARATOR'),1,1),DEFAULT_PATH_SEPARATOR);
  v := get_env('VFS_CASE_SENSITIVE');
  if v is not null then
   CASE_SENSITIVE := v = 'YES';
  else
   CASE_SENSITIVE := DEFAULT_CASE_SENSITIVE;
  end if;
  CURRENT_CHARSET := nvl(get_env('VFS_CHARSET'),default_charset);
  CUR_REPLACE_DIR := get_env('VFS_REPLACE_DIR');
  CUR_HOME_DIR := get_env('VFS_HOME_DIR');
  CUR_ROOT_DIR := CUR_HOME_DIR || get_env('VFS_ROOT_DIR');
  CUR_BASE_DIR := get_env('VFS_BASE_DIR');
  if CUR_BASE_DIR is not null and prof <> 'DEFAULT' then
   CUR_BASE_DIR := CUR_BASE_DIR || get_resource('DEFAULT','VFS_BASE_DIR');
  end if;
  CUR_BASE_DIR := make_dir_list(CUR_BASE_DIR,CUR_HOME_DIR,CUR_ROOT_DIR,CUR_REPLACE_DIR);
  v := get_env('VFS_SILENT_OVERWRITE');
  if v is not null then
   SILENT_OVERWRITE := v = 'YES';
  else
   SILENT_OVERWRITE := DEFAULT_SILENT_OVERWRITE;
  end if;
  v := get_env('VFS_MAKE_DIR');
  if v is not null then
   CUR_CAN_MAKE_DIR := v = 'YES';
  else
   CUR_CAN_MAKE_DIR := DEFAULT_CAN_MAKE_DIR;
  end if;
  CUR_DEBUG_LEVEL := nvl(get_env('VFS_DEBUG_LEVEL'),DEFAULT_DEBUG_LEVEL);
  CUR_LOG_FILE := nvl(get_env('VFS_LOG_FILE'),CUR_HOME_DIR || CUR_ROOT_DIR || PATH_SEPARATOR || DEFAULT_LOG_FILE);
  CUR_LOG_ID := get_id_by_name$(CUR_LOG_FILE);
 end load_env;
 ----------------------------------------------------------

 ----------------------------------------------------------
 procedure vfs_open as
 usr rtl.users_info;
 begin
  if INITED then vfs_close; end if;
  INITED := null;
  clear_dead_locks;
  load_env;
  if rtl.get_user_info(usr) then CUR_USER := usr.ora_user; end if;
  INITED := true;

  write_log('MSG','open',1);
 end vfs_open;
 ----------------------------------------------------------
 procedure vfs_close as
 tmp pls_integer;
 begin
  write_log('MSG','close',1);

  close_all$;
  close_all_folders;
  clear_env;
  tmp := set_error(ERR_SUCCESS);
  CUR_USER := null;
  CUR_CAN_MAKE_DIR := null;
  CASE_SENSITIVE := null;
  PATH_SEPARATOR := null;
  CURRENT_CHARSET := null;
  CUR_REPLACE_DIR := null;
  CUR_HOME_DIR := null;
  CUR_BASE_DIR := null;
  CUR_ROOT_DIR := null;
  SILENT_OVERWRITE := null;
  CUR_DEBUG_LEVEL := null;
  CUR_LOG_FILE := null;
  CUR_LOG_ID := null;
  INITED := false;
 end vfs_close;
 ----------------------------------------------------------
 procedure check_open as
 begin
  if    INITED is null then
   null;
  elsif not INITED then
   vfs_open;
  end if;
 end check_open;
 ----------------------------------------------------------

 ----------------------------------------------------------
 function error_message(acode in pls_integer) return varchar2 as
 begin
  check_open;
  return 'VFS' || acode || ': ' || message.gettext(error_list(acode).topic,error_list(acode).code,ep1,ep2,ep3);
 exception
  when NO_DATA_FOUND then return null;
 end error_message;
 ----------------------------------------------------------
 function process_error(acode in pls_integer, araising in boolean default false) return pls_integer as
 begin
  check_open;
  if acode >= ERR_SUCCESS then return acode; end if;
  if not araising then
   message.app_error(message.ERROR_NUMBER,error_message(acode));
  else
   if    acode = ERR_INVALID_PATH             then raise E_INVALID_PATH;
   elsif acode = ERR_INVALID_HANDLE           then raise E_INVALID_HANDLE;
   elsif acode = ERR_NOT_ENOUGH_PRIVILEGE     then raise E_NOT_ENOUGH_PRIVILEGE;
   elsif acode = ERR_LOCKED                   then raise E_LOCKED;
   elsif acode = ERR_NAME_EXISTS              then raise E_NAME_EXISTS;
   elsif acode = ERR_INVALID_MODE             then raise E_INVALID_MODE;
   elsif acode = ERR_UNKNOWN                  then raise E_UNKNOWN;
   elsif acode = ERR_NOT_EMPTY                then raise E_NOT_EMPTY;
   elsif acode = ERR_INVALID_NAME             then raise E_INVALID_NAME;
   elsif acode = ERR_NO_STATIC_FOLDER_IN_TEMP then raise E_NO_STATIC_FOLDER_IN_TEMP;
   elsif acode = ERR_INVALID_PARAMETER        then raise E_INVALID_PARAMETER;
   elsif acode = ERR_NOT_IN_READ_MODE         then raise E_NOT_IN_READ_MODE;
   elsif acode = ERR_NOT_IN_WRITE_MODE        then raise E_NOT_IN_WRITE_MODE;
   elsif acode = ERR_NOT_IN_READWRITE_MODE    then raise E_NOT_IN_READWRITE_MODE;
   elsif acode = ERR_BUSY                     then raise E_BUSY;
   elsif acode = ERR_INVALID_CHARSET          then raise E_INVALID_CHARSET;
   elsif acode = ERR_NO_DATA                  then raise E_NO_DATA;
   elsif acode = ERR_DROP_DEFAULT_STORAGE     then raise E_DROP_DEFAULT_STORAGE;
   elsif acode = ERR_NOT_SUPPORTED            then raise E_NOT_SUPPORTED;
   end if;
  end if;
 end process_error;
 ----------------------------------------------------------

begin
 error_list(ERR_INVALID_PATH).topic              := constant.EXEC_ERROR;
 error_list(ERR_INVALID_PATH).code               := 'FILEPATH';
 error_list(ERR_INVALID_HANDLE).topic            := constant.EXEC_ERROR;
 error_list(ERR_INVALID_HANDLE).code             := 'FILEHANDLE';
 error_list(ERR_NOT_ENOUGH_PRIVILEGE).topic      := constant.EXEC_ERROR;
 error_list(ERR_NOT_ENOUGH_PRIVILEGE).code       := 'VFS_NOT_ENOUGH_PRIVILEGE';
 error_list(ERR_LOCKED).topic                    := constant.EXEC_ERROR;
 error_list(ERR_LOCKED).code                     := 'VFS_LOCKED';
 error_list(ERR_NAME_EXISTS).topic               := constant.EXEC_ERROR;
 error_list(ERR_NAME_EXISTS).code                := 'VFS_NAME_EXISTS';
 error_list(ERR_INVALID_MODE).topic              := constant.EXEC_ERROR;
 error_list(ERR_INVALID_MODE).code               := 'FILEMODE';
 error_list(ERR_UNKNOWN).topic                   := constant.EXEC_ERROR;
 error_list(ERR_UNKNOWN).code                    := 'VFS_UNKNOWN';
 error_list(ERR_NOT_EMPTY).topic                 := constant.EXEC_ERROR;
 error_list(ERR_NOT_EMPTY).code                  := 'VFS_NOT_EMPTY';
 error_list(ERR_INVALID_NAME).topic              := constant.EXEC_ERROR;
 error_list(ERR_INVALID_NAME).code               := 'VFS_INVALID_NAME';
 error_list(ERR_NO_STATIC_FOLDER_IN_TEMP).topic  := constant.EXEC_ERROR;
 error_list(ERR_NO_STATIC_FOLDER_IN_TEMP).code   := 'VFS_NO_STATIC_FOLDER_IN_TEMP';
 error_list(ERR_INVALID_PARAMETER).topic         := constant.EXEC_ERROR;
 error_list(ERR_INVALID_PARAMETER).code          := 'VFS_INVALID_PARAMETER';
 error_list(ERR_NOT_IN_READ_MODE).topic          := constant.EXEC_ERROR;
 error_list(ERR_NOT_IN_READ_MODE).code           := 'VFS_NOT_IN_READ_MODE';
 error_list(ERR_NOT_IN_WRITE_MODE).topic         := constant.EXEC_ERROR;
 error_list(ERR_NOT_IN_WRITE_MODE).code          := 'VFS_NOT_IN_WRITE_MODE';
 error_list(ERR_NOT_IN_READWRITE_MODE).topic     := constant.EXEC_ERROR;
 error_list(ERR_NOT_IN_READWRITE_MODE).code      := 'VFS_NOT_IN_READWRITE_MODE';
 error_list(ERR_BUSY).topic                      := constant.EXEC_ERROR;
 error_list(ERR_BUSY).code                       := 'VFS_BUSY';
 error_list(ERR_INVALID_CHARSET).topic           := constant.EXEC_ERROR;
 error_list(ERR_INVALID_CHARSET).code            := 'VFS_INVALID_CHARSET';
 error_list(ERR_NO_DATA).topic                   := constant.EXEC_ERROR;
 error_list(ERR_NO_DATA).code                    := 'VFS_NO_DATA';
 error_list(ERR_DROP_DEFAULT_STORAGE).topic      := constant.EXEC_ERROR;
 error_list(ERR_DROP_DEFAULT_STORAGE).code       := 'VFS_DROP_DEFAULT_STORAGE';
 error_list(ERR_NOT_SUPPORTED).topic             := constant.EXEC_ERROR;
 error_list(ERR_NOT_SUPPORTED).code              := 'VFS_NOT_SUPPORTED';

end;
/
sho err
