@@dict_chg
@@umenu
--exec patch_tool.update_props;


prompt idx_method_id_acsb_usdrv
create unique index idx_method_id_acsb_usdrv
    on methods (user_driven,accessibility,id)
    tablespace &&tspacei;

prompt users
alter table users modify (os_user varchar2(1000), os_domain varchar2(1000));

prompt creating synonyms for sys views
create synonym dba_role_privs for sys.dba_role_privs_simple;
create synonym dba_jobs for sys.dba_jobs;
create synonym v$lock for sys.v_$lock;
create synonym v$sesstat for sys.v_$sesstat;
create synonym v$session for sys.v_$session;
create synonym v$process for sys.v_$process;
create synonym v$statname for sys.v_$statname;
create synonym v$instance for sys.v_$instance;
create synonym v$parameter for sys.v_$parameter;
create synonym gv$lock for sys.gv_$lock;
create synonym gv$sesstat for sys.gv_$sesstat;
create synonym gv$session for sys.gv_$session;
create synonym gv$process for sys.gv_$process;
create synonym gv$statname for sys.gv_$statname;
create synonym gv$instance for sys.gv_$instance;

