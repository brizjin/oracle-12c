SET TERMOUT OFF

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

define TSTAB = &&TSTAB --ACCEPT TSTAB    PROMPT 'Default Tablespace for Tables  (&&TSTAB):' default &&TSTAB
define TSIDX = &&TSIDX --ACCEPT TSIDX    PROMPT 'Default Tablespace for Indexes (&&TSIDX):'   default &&TSIDX
define TSLOB = &&TSLOB --ACCEPT TSLOB    PROMPT 'Default Tablespace for Lobs  (&&TSLOB):' default &&TSLOB
define TPART = &&TPART --ACCEPT TPART    PROMPT 'Archive Tablespace for Tables  (&&TPART):'  default &&TPART
define TPARTI = &&TPARTI --ACCEPT TPARTI   PROMPT 'Archive Tablespace for Indexes (&&TPARTI):'  default &&TPARTI
define TUSERS = &&TUSERS --ACCEPT TUSERS   PROMPT 'Tablespace for Dictionary Tables  (&&TUSERS):' default &&TUSERS
define TSPACEI = &&TSPACEI --ACCEPT TSPACEI  PROMPT 'Tablespace for Dictionary Indexes (&&TSPACEI):'   default &&TSPACEI


