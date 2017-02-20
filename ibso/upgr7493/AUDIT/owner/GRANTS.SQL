exec utils.create_procedures
exec utils.grants
exec lic_mgr.install
grant execute on lic_mgr to &&owner;

