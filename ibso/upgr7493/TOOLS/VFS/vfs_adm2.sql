prompt package body vfs_admin
create or replace package body vfs_admin as
/*
 *	$HeadURL: http://hades.ftc.ru:7382/svn/pltm2/Core/Utils/EXT/vfs_adm2.sql $
 *	$Author: Alexey $
 *	$Revision: 15082 $
 *	$Date:: 2012-03-06 17:34:34 #$
 */

 ----------------------------------------------------------
 function bit_or(a pls_integer, b pls_integer) return pls_integer as
 begin
  return rawtohex(utl_raw.bit_or(hextoraw(a),hextoraw(b)));
 end bit_or;
 ----------------------------------------------------------
 function bit_xor(a pls_integer, b pls_integer) return pls_integer as
 begin
  return rawtohex(utl_raw.bit_xor(hextoraw(a),hextoraw(b)));
 end bit_xor;
 ----------------------------------------------------------
 function current_user return varchar2 as
 begin
  return vfs_mgr.current_user;
 end current_user;
 ----------------------------------------------------------
 function is_admin(asubject_id in varchar2 default current_user) return boolean as
 tmp integer;
 begin
  if asubject_id = inst_info.owner then return true; end if;
  begin
   select 1 into tmp from subj_equal
   where subj_id = asubject_id and equal_id = 'ADMIN_GRP';
   return true;
  exception
   when NO_DATA_FOUND then return false;
  end;
 end is_admin;
 ----------------------------------------------------------
 function is_owner(aid in integer, asubject_id in varchar2 default current_user) return boolean as
 f_owner_id varchar2(30);
 begin
  begin
   select owner_id into f_owner_id from vfs where id = aid;
  exception
   when NO_DATA_FOUND then return false;
  end;
  if asubject_id = f_owner_id then return true; end if;
  begin
   select '1' into f_owner_id from subj_equal where subj_id = asubject_id and equal_id = f_owner_id;
   return true;
  exception
   when NO_DATA_FOUND then return false;
  end;
 end is_owner;
 ----------------------------------------------------------
 function get_storage_access(asubject_id in varchar2 default current_user) return pls_integer as
 result pls_integer;
 begin
  if is_admin then return ACCESS_FULL; end if;
  begin
   select ACCESS_FULL into result from vfs_storage_access sa, subj_equal se
   where se.subj_id = asubject_id and sa.subject_id = se.equal_id;
   return ACCESS_FULL;
  exception
   when NO_DATA_FOUND then return ACCESS_NONE;
  end;
 end get_storage_access;
 ----------------------------------------------------------
 function check_storage_access(asubject_id in varchar2 default current_user) return pls_integer as
 tmp pls_integer;
 begin
  tmp := get_storage_access(asubject_id);
  if    tmp > ACCESS_NONE then
   return vfs_mgr.ERR_SUCCESS;
  elsif tmp = ACCESS_NONE then
   return vfs_mgr.ERR_NOT_ENOUGH_PRIVILEGE;
  else
   return tmp;
  end if;
 end check_storage_access;
 ----------------------------------------------------------
 function set_storage_access(asubject_id in varchar2, aaccess_mask in pls_integer default ACCESS_FULL) return pls_integer as
 begin
  if get_storage_access = ACCESS_NONE then return vfs_mgr.ERR_NOT_ENOUGH_PRIVILEGE; end if;
  if aaccess_mask = ACCESS_NONE then
   delete from vfs_storage_access where subject_id = asubject_id;
  else
   begin
    insert into vfs_storage_access (access_mask,subject_id) values (ACCESS_FULL,asubject_id);
   exception
    when DUP_VAL_ON_INDEX then null;
   end;
  end if;
  return vfs_mgr.ERR_SUCCESS;
 end set_storage_access;
 ----------------------------------------------------------
 function get_owner_access(aid in integer, asubject_id in varchar2 default current_user) return pls_integer as
 begin
  if is_admin or is_owner(aid) then return ACCESS_FULL; else return ACCESS_NONE; end if;
 end get_owner_access;
 ----------------------------------------------------------
 function get_others_access_vfs(aid in integer) return pls_integer as
 am pls_integer;
 pid integer;
 begin
  begin
   select access_mask,parent_id into am,pid from vfs where id = aid;
  exception
   when NO_DATA_FOUND then return vfs_mgr.ERR_INVALID_PARAMETER;
  end;
  while am = ACCESS_PARENT and pid is not null loop
   begin
    select access_mask,parent_id into am,pid from vfs where id = pid;
   exception
    when NO_DATA_FOUND then exit;
   end;
  end loop;
  return am;
 end get_others_access_vfs;
 ----------------------------------------------------------
 function get_prf_access(aid in integer, aprf_str in varchar2) return pls_integer as

 fprf_str varchar2(4000);
 fpath varchar2(4000);
 fn varchar2(4000);

 cpos integer := 0;
 ppos integer := 0;
 cdir varchar2(4000);

 tmp integer;

  procedure next as
  incl boolean;
  begin
   ppos := cpos;
   cpos := instr(fprf_str,';',ppos + 1,1);
   if cpos = 0 then
    cdir := substr(fprf_str,ppos + 1);
   else
    cdir := substr(fprf_str,ppos + 1,cpos - 1);
   end if;
   if cdir is null then return; end if;
   tmp := length(cdir);
   incl := substr(cdir,tmp) = vfs_mgr.PATH_SEPARATOR;
   if incl then cdir := substr(cdir,1,tmp - 1); end if;
   if incl then cdir := cdir || '%'; end if;
  end;

 begin
  if aprf_str is null then return ACCESS_NONE; end if;
  fprf_str := replace(aprf_str,'/\',vfs_mgr.PATH_SEPARATOR || vfs_mgr.PATH_SEPARATOR);

  fpath := vfs_mgr.get_name_by_id$(aid);
  if not vfs_mgr.is_folder$(aid) then
   tmp := instr(fpath,vfs_mgr.PATH_SEPARATOR,-1,1);
   if tmp > 0 then
    fpath := substr(fpath,1,tmp - 1);
    fn := substr(fpath,tmp + 1);
   else
    return ACCESS_NONE;
   end if;
  end if;

  if not vfs_mgr.CASE_SENSITIVE then
   fprf_str := upper(fprf_str);
   fpath := upper(fpath);
  end if;

  loop
   next;
   if cdir is null then return ACCESS_NONE; end if;
   if fpath like cdir then
    if fn is null then
     --its a folder
     return ACCESS_FULL;
    else
     return get_others_access_vfs(aid);
    end if;
   end if;
   if cpos = 0 then exit; end if;
  end loop;

  return ACCESS_NONE;
 end get_prf_access;
 ----------------------------------------------------------
 function get_others_access_prf(aid in integer) return pls_integer as
 begin
  return get_prf_access(aid,vfs_mgr.base_dir);
 end get_others_access_prf;
 ----------------------------------------------------------
 function get_others_access(aid in integer) return pls_integer as
 begin
  if vfs_mgr.base_dir is null then
   return get_others_access_vfs(aid);
  else
   return get_others_access_prf(aid);
  end if;
 end get_others_access;
 ----------------------------------------------------------
 function get_subject_access$(aid in integer, asubject_id in varchar2 default current_user) return pls_integer as
 result pls_integer;
 pid integer;
 sub integer;
 begin
  pid := aid;
  loop
   begin
    select access_mask,include_subfolders into result,sub
    from vfs_access where vfs_id = pid and subject_id = asubject_id;
    if pid = aid or sub <> 0 then null; else result := ACCESS_NONE; end if;
    exit;
   exception
    when NO_DATA_FOUND then null;
   end;
   if pid is not null then
    begin
     select parent_id into pid from vfs where id = pid;
    exception
     when NO_DATA_FOUND then result := vfs_mgr.ERR_INVALID_PARAMETER; exit;
    end;
   else
    result := ACCESS_NONE; exit;
   end if;
  end loop;
  return result;
 end get_subject_access$;
 ----------------------------------------------------------
 function get_subject_access_prf(aid in integer, asubject_id in varchar2) return pls_integer as
 prf varchar2(30);
 begin
  prf := vfs_mgr.get_profile(asubject_id);
  if prf = 'DEFAULT' then return ACCESS_NONE; end if;
  return get_prf_access(aid,vfs_mgr.base_dir);
 end get_subject_access_prf;
 ----------------------------------------------------------
 function get_subject_access_vfs(aid in integer, asubject_id in varchar2) return pls_integer as
 tmp pls_integer;
 result pls_integer;
 begin
  result := ACCESS_NONE;
  for r in (select equal_id from subj_equal where subj_id = asubject_id) loop
   tmp := get_subject_access$(aid,r.equal_id);
   if tmp < 0 then return tmp; end if;
   result := bit_or(result,tmp);
   if result = ACCESS_FULL then return ACCESS_FULL; end if;
  end loop;
  return result;
 end get_subject_access_vfs;
 ----------------------------------------------------------
 function get_subject_access(aid in integer, asubject_id in varchar2 default current_user) return pls_integer as
 begin
  if vfs_mgr.base_dir is null then
   return get_subject_access_vfs(aid,asubject_id);
  else
   return get_subject_access_prf(aid,asubject_id);
  end if;
 end get_subject_access;
 ----------------------------------------------------------
 function check_subject_access_prf(aid in integer, aaccess_request in pls_integer, asubject_id in varchar2) return pls_integer as
 begin
  for r in (select equal_id from subj_equal where subj_id = asubject_id) loop
   if get_subject_access_prf(aid,r.equal_id) > ACCESS_NONE then return vfs_mgr.ERR_SUCCESS; end if;
  end loop;
  return vfs_mgr.ERR_NOT_ENOUGH_PRIVILEGE;
 end check_subject_access_prf;
 ----------------------------------------------------------
 function check_subject_access_vfs(aid in integer, aaccess_request in pls_integer, asubject_id in varchar2) return pls_integer as
 tmp pls_integer;
 am pls_integer;
 begin
  am := ACCESS_NONE;
  for r in (select equal_id from subj_equal where subj_id = asubject_id) loop
   tmp := get_subject_access$(aid,r.equal_id);
   if tmp < 0 then return tmp; end if;
   am := bit_or(am,tmp);
   if bitand(am,aaccess_request) = aaccess_request then return vfs_mgr.ERR_SUCCESS; end if;
  end loop;
  return vfs_mgr.ERR_NOT_ENOUGH_PRIVILEGE;
 end check_subject_access_vfs;
 ----------------------------------------------------------
 function check_subject_access(aid in integer, aaccess_request in pls_integer, asubject_id in varchar2 default current_user) return pls_integer as
 begin
  if vfs_mgr.base_dir is null then
   return check_subject_access_vfs(aid,aaccess_request,asubject_id);
  else
   return check_subject_access_prf(aid,aaccess_request,asubject_id);
  end if;
 end check_subject_access;
 ----------------------------------------------------------
 function check_access(aid in integer, aaccess_request in pls_integer, asubject_id in varchar2 default current_user) return pls_integer as
 tmp pls_integer;
 begin
  tmp := get_owner_access(aid,asubject_id);
  if    tmp > ACCESS_NONE then
   return vfs_mgr.ERR_SUCCESS;
  elsif tmp < ACCESS_NONE then
   return tmp;
  end if;

  tmp := get_others_access(aid);
  if    tmp < vfs_mgr.ERR_SUCCESS then
   return tmp;
  else
   tmp := bitand(tmp,aaccess_request);
   if tmp = aaccess_request then return vfs_mgr.ERR_SUCCESS; end if;
   if tmp <> 0 then tmp := bit_xor(aaccess_request,tmp); else tmp := aaccess_request; end if;
  end if;

  return check_subject_access(aid,tmp,asubject_id);
 end check_access;
 ----------------------------------------------------------
 function is_accessible(aid in integer, asubject_id in varchar2 default current_user) return boolean as
 begin
  if get_owner_access(aid,asubject_id) > ACCESS_NONE then return true; end if;
  if get_others_access(aid) > ACCESS_NONE then return true; end if;
  for r in (select equal_id from subj_equal where subj_id = asubject_id) loop
   if get_subject_access$(aid,asubject_id) > ACCESS_NONE then return true; end if;
  end loop;
  return false;
 end is_accessible;
 ----------------------------------------------------------
 function set_others_access(aid in integer, aaccess_mask in pls_integer default ACCESS_PARENT) return pls_integer as
 am pls_integer;
 begin
  if get_owner_access(aid) = ACCESS_NONE then return vfs_mgr.ERR_NOT_ENOUGH_PRIVILEGE; end if;
  if aaccess_mask = ACCESS_PARENT and vfs_mgr.is_folder$(aid) then
   am := get_others_access(vfs_mgr.get_parent$(aid));
  else
   am := aaccess_mask;
  end if;
  update vfs set access_mask = am where id = aid;
  if sql%rowcount = 0 then return vfs_mgr.ERR_INVALID_PARAMETER; end if;
  return vfs_mgr.ERR_SUCCESS;
 end set_others_access;
 ----------------------------------------------------------
 function set_subject_access(aid in integer, asubject_id in varchar2,
  aaccess_mask in pls_integer default ACCESS_PARENT, ainclude_subfolders in integer default 0) return pls_integer as
 am pls_integer;
 begin
  if not vfs_mgr.is_folder$(aid) then return vfs_mgr.ERR_INVALID_PARAMETER; end if;
  if get_owner_access(aid) = ACCESS_NONE then return vfs_mgr.ERR_NOT_ENOUGH_PRIVILEGE; end if;
  if aaccess_mask = ACCESS_PARENT then
   am := get_subject_access$(aid,asubject_id);
  else
   am := aaccess_mask;
  end if;
  update vfs_access set access_mask = am, include_subfolders = ainclude_subfolders
  where vfs_id = aid and subject_id = asubject_id;
  if sql%rowcount = 0 then
   insert into vfs_access (vfs_id,subject_id,access_mask,include_subfolders)
   values (aid,asubject_id,am,ainclude_subfolders);
  end if;
  return vfs_mgr.ERR_SUCCESS;
 end set_subject_access;
 ----------------------------------------------------------
 function set_owner(aid in integer, anew_owner_id in varchar2) return pls_integer as
 begin
  if get_owner_access(aid) = ACCESS_NONE then return vfs_mgr.ERR_NOT_ENOUGH_PRIVILEGE; end if;
  update vfs set owner_id = upper(ltrim(rtrim(anew_owner_id))) where id = aid;
  if sql%rowcount = 0 then return vfs_mgr.ERR_INVALID_PARAMETER; end if;
  return vfs_mgr.ERR_SUCCESS;
 end set_owner;
 ----------------------------------------------------------

 ----------------------------------------------------------
 function can_make_dir(asubject_id in varchar2 default current_user) return boolean as
 begin
  return is_admin or vfs_mgr.can_make_dir(asubject_id);
 end can_make_dir;
 ----------------------------------------------------------

end;
/
sho err
