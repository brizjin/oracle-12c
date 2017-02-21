@init &1 &2

set verify off

-- UPGRADE AUD
@upgrade/upgrade
-- Define settings
@settings/settings
-- UPGRADE IBSO Owner
@up_owner

set verify on

exit
