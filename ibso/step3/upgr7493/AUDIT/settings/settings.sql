prompt
define OWNER = &&OWNER --accept OWNER char format a30 prompt 'AUDIT SETTINGS FOR IBSO OWNER [&&OWNER]: ' default &&OWNER
column yyy new_value d_parallel noprint
select value yyy from audit_settings where owner='&&owner' and name='FORCE_PARALLEL';
prompt
define TUSER = &&AUD_TUSERS --accept TUSER   char format a30 prompt 'Tablespace for TABLES [&&AUD_TUSERS]: ' default &&AUD_TUSERS
define TINIT = 10M
define TNEXT = 10M
define TSPACEI = &&AUD_TSPACEI --accept TSPACEI char format a30 prompt 'Tablespace for INDEXES [&&AUD_TSPACEI]: ' default &&AUD_TSPACEI
define IINIT = 5M
define INEXT = 5M
define FREELST = 10
define D_PARALLEL = &&D_PARALLEL --accept D_PARALLEL char format a30 prompt 'Force Degree of Parallelism [&&D_PARALLEL]: ' default &&D_PARALLEL

@../UTILS/chk_tsps '&&TUSER, &&TSPACEI'

prompt
prompt Now you should specify tablespace names for partitions.
prompt
prompt [1] Common tablespace for all partitions
prompt [2] Specify prefixes for partion tablespaces
prompt [3] Specify tablespace for each partiton explicitly
prompt *** Other choices will mean exit to parent menu ***

define CHOICE='1'
define CHOICE = &&CHOICE --accept CHOICE char format a1 prompt 'Enter choice [&&CHOICE]: ' default &&CHOICE

set termout off
column xxx new_value SCRIPT noprint
select decode('&&CHOICE', '1', 'settings/common', '2', 'settings/prefix', '3', 'settings/explicit') xxx from dual;
column xxx new_value TABLES noprint
select decode('&&SCRIPT', '', '', 'settings/tables') xxx from dual;
column xxx new_value INDEXES noprint
select decode('&&SCRIPT', '', '', 'settings/indexes') xxx from dual;
set termout on

@&&TABLES
@&&INDEXES
@&&SCRIPT

@@addon

commit;

