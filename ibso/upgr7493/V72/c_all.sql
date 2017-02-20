set echo on

@@c_tab
@@lic_tab
@@repl
@@rep_roles

prompt creating new global contexts
create or replace context &&owner._SETTS  using rtl accessed globally;
create or replace context &&owner._USERS  using rtl accessed globally;
create or replace context &&owner._RIGHTS using secadmin accessed globally;

set echo off

