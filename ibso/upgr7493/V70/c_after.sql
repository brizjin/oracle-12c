@@u_cache
@@sesuser
@@set_nls

prompt Clearing OS_DOMAIN\OS_USER in USERS for deleted users
update Users set os_user=null, os_domain=null,
       properties=replace(properties,'|SESSION|','|')
 where lock_status='DELETED' and os_user||os_domain is not null;

commit;

prompt Storage parameters for soft granting/revoking
insert into storage_parameters(param_group,param_name,param_value)
  values('GLOBAL','GRANTS_LIMIT_SESSIONS',500);
insert into storage_parameters(param_group,param_name,param_value)
  values('GLOBAL','GRANTS_LIMIT_ACTIVE_SESSIONS',50);
commit;

prompt COMPRESS_PARTITIONS storage parameter
begin
  if inst_info.db_version>9 then
    storage_mgr.set_storage_parameter('GLOBAL','COMPRESS_PARTITIONS','YES');
  else
    storage_mgr.set_storage_parameter('GLOBAL','COMPRESS_PARTITIONS','NO');
  end if;
end;
/

exec stdio.put_line_buf('Recovering resource groups with addresses...')
exec secadmin.RecoverResourceGroups;

exec storage_utils.verbose := true
exec storage_utils.pipe_name := 'DEBUG'
exec storage_mgr.verbose := true
exec storage_mgr.pipe_name := 'DEBUG'

begin
  if nvl(to_number('&&v_version','999.9'),1)<7.0 and '&&simple'<>'0' then
    stdio.put_line_buf('Creating Col2Obj views (VW_C2O/VW_C2P)...');
    storage_mgr.create_collection_views(true,true);
  end if;
end;
/

