prompt installing VFS...
define tuser = T_USR
define tindx = I_USR
define tlob = T_USR

prompt creating VFS tables

spool vfs.log

set echo on

@@vfs_crt.sql

prompt creating VFS packages

set echo off

@@pkgs.sql

prompt VFS installation complete
prompt You can view protocol in vfs.log file

spool off
