set feedback off

@settings
@@patch_settings

ACCEPT OWNER PROMPT 'Enter IBSO OWNER schema name (&&IBSO_OWNER): '  default &&IBSO_OWNER

var uVersion varchar2(2000);
var lVersion varchar2(100);
exec :uVersion := '&&UPGRADED_VERSION'; 
exec :lVersion := &&OWNER..inst_info.Get_Version;

@@check_version

var msg varchar2(1000)
exec :msg := 'Current version of IB System Object is '||:lVersion;

print msg
prompt

@@UTILS\exit_when ':can_run_patch = 0'

ACCEPT AUD_USER PROMPT 'Enter AUDIT schema name (&&AUD_OWNER): ' default &&AUD_OWNER

exec :uVersion := '&&UPGRADED_VERSION'; 
exec :lVersion := &&AUD_USER..clear.full_version;

@@check_version

var msg varchar2(1000)
exec :msg := 'Current version of Auditor Schema is '||:lVersion;

print msg
prompt

@@UTILS\exit_when ':can_run_patch = 0'

exit