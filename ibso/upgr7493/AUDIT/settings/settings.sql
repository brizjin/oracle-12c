prompt
accept OWNER char format a30 prompt 'AUDIT SETTINGS FOR IBSO OWNER [&&OWNER]: ' default &&OWNER
column yyy new_value d_parallel noprint
select value yyy from audit_settings where owner='&&owner' and name='FORCE_PARALLEL';
prompt
accept TUSER   char format a30 prompt 'Tablespace for TABLES [&&AUD_TUSERS]: ' default &&AUD_TUSERS
accept TINIT   char format a30 prompt 'Initial Extent for TABLES [10M]: ' default 10M
accept TNEXT   char format a30 prompt 'Next Extent for TABLES [10M]: ' default 10M
accept TSPACEI char format a30 prompt 'Tablespace for INDEXES [&&AUD_TSPACEI]: ' default &&AUD_TSPACEI
accept IINIT   char format a30 prompt 'Initial Extent for INDEXES [5M]: ' default 5M
accept INEXT   char format a30 prompt 'Next Extent for INDEXES [5M]: ' default 5M
accept FREELST char format a30 prompt 'Freelists Parameter [10]: ' default 10
accept D_PARALLEL char format a30 prompt 'Force Degree of Parallelism [&&D_PARALLEL]: ' default &&D_PARALLEL

@../UTILS/chk_tsps '&&TUSER, &&TSPACEI'

prompt
prompt Now you should specify tablespace names for partitions.
prompt
prompt [1] Common tablespace for all partitions
prompt [2] Specify prefixes for partion tablespaces
prompt [3] Specify tablespace for each partiton explicitly
prompt *** Other choices will mean exit to parent menu ***

define CHOICE='1'
accept CHOICE char format a1 prompt 'Enter choice [&&CHOICE]: ' default &&CHOICE

set termout off
column xxx new_value SCRIPT noprint
select decode('&&CHOICE', '1', 'settings\common', '2', 'settings\prefix', '3', 'settings\explicit') xxx from dual;
column xxx new_value TABLES noprint
select decode('&&SCRIPT', '', '', 'settings\tables') xxx from dual;
column xxx new_value INDEXES noprint
select decode('&&SCRIPT', '', '', 'settings\indexes') xxx from dual;
set termout on

@&&TABLES
@&&INDEXES
@&&SCRIPT

@@addon

commit;

