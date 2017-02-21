SET TERMOUT OFF

column xxx new_value rptkeep noprint
select param_value xxx from storage_parameters where param_group='GLOBAL' and param_name='KEEP_REPORTS';
column xxx new_value tstab noprint
select param_value xxx from storage_parameters where param_group='GLOBAL' and param_name='TAB_TABLESPACE' and param_value is not null;
column xxx new_value tsidx noprint
select param_value xxx from storage_parameters where param_group='GLOBAL' and param_name='IDX_TABLESPACE' and param_value is not null;
column xxx new_value tslob noprint
select param_value xxx from storage_parameters where param_group='GLOBAL' and param_name='LOB_TABLESPACE' and param_value is not null;
column xxx new_value tpart noprint
select param_value xxx from storage_parameters where param_group='GLOBAL' and param_name='PART_TABLESPACE' and param_value is not null;
column xxx new_value tparti noprint
select param_value xxx from storage_parameters where param_group='GLOBAL' and param_name='IDXPART_TABLESPACE' and param_value is not null;
column xxx new_value tusers noprint
select tablespace_name xxx from user_tables  where table_name='RTL_USERS';
column xxx new_value tspacei noprint
select tablespace_name xxx from user_indexes where index_name='PK_RTL_USERS_ID';

SET TERMOUT ON

define V_VERSION = &&v_version --ACCEPT V_VERSION  PROMPT 'Start UPGRADE from Old IBSO Version (&&v_version):' default &&v_version
define TSTAB = &&TSTAB --ACCEPT TSTAB    PROMPT 'Default Tablespace for Tables  (&&TSTAB):' default &&TSTAB
define TSIDX = &&TSIDX --ACCEPT TSIDX    PROMPT 'Default Tablespace for Indexes (&&TSIDX):'   default &&TSIDX
define TSLOB = &&TSLOB --ACCEPT TSLOB    PROMPT 'Default Tablespace for Lobs  (&&TSLOB):' default &&TSLOB
define TPART = &&TPART --ACCEPT TPART    PROMPT 'Archive Tablespace for Tables  (&&TPART):'  default &&TPART
define TPARTI = &&TPARTI --ACCEPT TPARTI   PROMPT 'Archive Tablespace for Indexes (&&TPARTI):'  default &&TPARTI
define TUSERS = &&TUSERS --ACCEPT TUSERS   PROMPT 'Tablespace for Dictionary Tables  (&&TUSERS):' default &&TUSERS
define TSPACEI = &&TSPACEI --ACCEPT TSPACEI  PROMPT 'Tablespace for Dictionary Indexes (&&TSPACEI):'   default &&TSPACEI
define RIGHTS = &&RIGHTS --ACCEPT RIGHTS   PROMPT 'Filling User Rights Context    (&&RIGHTS):' default &&RIGHTS
REM define APPSRV = &&APPSRV --ACCEPT APPSRV   PROMPT 'Create Default Accounts for Application Server (&&APPSRV):' default &&APPSRV
rem ACCEPT IDXDROP  PROMPT 'Dropping indexes (NO):' default NO
define SIMPLE = &&SIMPLE --ACCEPT SIMPLE   PROMPT 'Compilation Only (&&SIMPLE):' default &&SIMPLE
define REPROLES = &&REPROLES --ACCEPT REPROLES PROMPT 'Grant roles for report packages to users (&&REPROLES):' default &&REPROLES
define CRSYN = &&CRSYN --ACCEPT CRSYN    PROMPT 'Create Synonyms in default profile (&&CRSYN):' default &&CRSYN
define CRROLES = &&CRROLES --ACCEPT CRROLES  PROMPT 'Recreate user roles (&&CRROLES):' default &&CRROLES
define RPTKEEP = &&RPTKEEP --ACCEPT RPTKEEP  PROMPT 'Minimum days amount to keep reports in queue (&&RPTKEEP):' default &&RPTKEEP

