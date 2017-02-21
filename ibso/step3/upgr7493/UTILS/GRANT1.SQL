PROMPT Rebuilding roles...

prompt Revoke After_Install
revoke execute on After_Install from &&owner._ADMIN;

prompt Create Roles
exec admin_mgr.create_roles;
exec after_install.grants(null)

prompt Grant After_Install
grant execute on After_Install to &&owner._ADMIN;

prompt Grant Roles
exec after_install.grant_roles(true)

