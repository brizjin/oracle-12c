set verify off
define sysPassword = 'sys' -- ACCEPT sysPassword CHAR PROMPT 'Enter new password for SYS: ' HIDE
define systemPassword = 'system' -- ACCEPT systemPassword CHAR PROMPT 'Enter new password for SYSTEM: ' HIDE
host $ORACLE_BASE/product/12.1.0/dbhome_1/bin/orapwd file=$ORACLE_BASE/product/12.1.0/dbhome_1/dbs/orapwwork force=y format=12
@$ORACLE_BASE/admin/work/scripts/CreateDB.sql
@$ORACLE_BASE/admin/work/scripts/CreateDBFiles.sql
@$ORACLE_BASE/admin/work/scripts/CreateDBCatalog.sql
@$ORACLE_BASE/admin/work/scripts/JServer.sql
@$ORACLE_BASE/admin/work/scripts/lockAccount.sql
@$ORACLE_BASE/admin/work/scripts/postDBCreation.sql
