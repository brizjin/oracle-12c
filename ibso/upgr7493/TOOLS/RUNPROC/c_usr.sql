Prompt * создание пользователя RUNPROC

def rpath=runproc.ini
column xxx new_value rpath noprint
select value xxx from settings where name='JOBS_RUNPROC_INI';

column xxx new_value oxxx noprint
select user xxx from dual;

ACCEPT RNAME PROMPT 'RUNPROC connecting account name (RUNPROC):' default RUNPROC
ACCEPT RPASS PROMPT 'RUNPROC connecting account password (RUNPROC):' default RUNPROC
ACCEPT RPATH PROMPT 'RUNPROC ini file path (&&rpath):' default &&RPATH

def

prompt JOBS_RUNPROC_USER setting
exec sysinfo.setvalue('JOBS_RUNPROC_USER',upper('&&RNAME'),'Имя пользователя агента RUNPROC очереди заданий');
exec sysinfo.setvalue('JOBS_RUNPROC_USER',upper('&&RNAME'),'Имя пользователя агента RUNPROC очереди заданий');
prompt JOBS_RUNPROC_INI setting
exec sysinfo.setvalue('JOBS_RUNPROC_INI','&&RPATH','Путь к файлу инициализации агента RUNPROC');

exec storage_utils.verbose := true
exec storage_utils.pipe_name := 'DEBUG'

declare
    n   pls_integer;
    TSDef   varchar2(30);
    TSTmp   varchar2(30);
    usr varchar2(30);
    pwd varchar2(30);
begin
    usr := upper('&&Rname');
    pwd := upper('&&Rpass');
    storage_utils.verbose := true;
    storage_utils.pipe_name := 'DEBUG';
    if usr<>'&&oxxx' then
        select param_value into TSDef from user_tablespaces, storage_parameters
         where param_group='GLOBAL' and param_name='TAB_TABLESPACE' and tablespace_name=param_value;
        select param_value into TSTmp from user_tablespaces, storage_parameters
         where param_group='GLOBAL' and param_name='TMP_TABLESPACE' and tablespace_name=param_value;
        select count(1) into n from users where username=USR;
        if n=0 then
          storage_utils.ws('Creating '||USR);
          insert into users(username,name,properties) values (usr,'RUNPROC agent account','|LOCK|');
          select count(1) into n from subj_equal where subj_id=USR and equal_id=USR and owner_id=USR;
          if n=0 then
            insert into subj_equal(subj_id,equal_id,owner_id) values (usr,usr,usr);
          end if;
          commit;
        end if;
        select count(1) into n from all_users where username=usr;
        if n=0 then
          storage_utils.execute_sql('CREATE USER '||USR||' IDENTIFIED BY "'||PWD||'" DEFAULT TABLESPACE '
                                    ||TSDef||' TEMPORARY TABLESPACE '||TSTmp,
                                    'Creating Oracle Account for '||USR);
          storage_utils.execute_sql('GRANT CONNECT TO '||USR,'Granting CONNECT Role TO '||USR);
        end if;
        storage_utils.execute_sql('GRANT EXECUTE ON RUNPROC_PKG TO '||USR,'Granting RUNPROC_PKG TO '||USR);
    end if;
end;
/

var u number
exec secadmin.update_subj_equal;
exec :u := secadmin.fill_userid;
commit;
print u

