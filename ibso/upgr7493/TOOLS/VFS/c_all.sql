prompt installing VFS...

accept tuser prompt 'Tablespace for VFS tables   (T_USR):' default T_USR
accept tindx prompt 'Tablespace for VFS indexes  (I_USR):' default I_USR
accept tlob  prompt 'Tablespace for VFS lob data (T_USR):' default T_USR

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
