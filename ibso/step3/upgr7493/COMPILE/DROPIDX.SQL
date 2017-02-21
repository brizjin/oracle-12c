define TSIDX = IDX
define DBSIZE = 8192
define IDXDROP = N
set feedback off
set heading off
set newpage 0
set pagesize 0
set echo off
set termout off
set verify off
set serveroutput on size 500000
set linesize 250
set arraysize 1
set trimspool on
set trimout on
column xxx new_value oxxx noprint
select user xxx from dual;
alter system flush shared_pool;
spool &oxxx..idx
prompt exec storage_utils.verbose:=true
prompt exec storage_utils.pipe_name:='debug2'
prompt exec storage_mgr.verbose:=true
prompt exec storage_mgr.pipe_name:='debug2'
prompt var s varchar2(10)
prompt spool &oxxx._idx.log
prompt select 'Started  creating indexes - '||TO_CHAR(SYSDATE,'DD/MM/YY (HH24:MI:SS)') from dual;;

declare
spi integer;
spn integer;
s1  varchar2(100);
s2  varchar2(100);
procedure get_params(p_size number) is
begin
    select
  decode( sign(999*1024-p_size/1024), -1, 1000*1024,
    decode( sign(2048-p_size/1024), -1, (trunc(p_size/(2048*1024))+1)*2048,
      decode( sign(1024-p_size/1024), -1, 2048,
        decode( sign(512-p_size/1024), -1, 1024,
          decode( sign(256-p_size/1024), -1, 512,
            decode( sign(128-p_size/1024), -1, 256,
              decode( sign(64-p_size/1024) , -1, 128,
                decode( sign(32-p_size/1024) , -1, 64, 32 )
                    )
                  )
                )
              )
            )
          )
        ),
  decode( sign(499*1024-p_size/4096), -1, 500*1024,
    decode( sign(2048-p_size/4096), -1, (trunc(p_size/(2048*4096))+1)*2048,
      decode( sign(1024-p_size/4096), -1, 2048,
        decode( sign(512-p_size/4096), -1, 1024,
          decode( sign(256-p_size/4096), -1, 512,
            decode( sign(128-p_size/4096), -1, 256,
              decode( sign(64-p_size/4096) , -1, 128,
                decode( sign(32-p_size/4096) , -1, 64, 32 )
                    )
                  )
                )
              )
            )
          )
        )
    into spi, spn from dual;
exception when others then
    spi := 64;
    spn := 64;
end;
begin
  storage_mgr.verbose:=true;
  storage_mgr.pipe_name:='DEBUG';
  storage_utils.verbose:=true;
  storage_utils.pipe_name:='DEBUG';
  storage_utils.ws('Dropping user indexes started...');
  dbms_utility.db_version(s1,s2);
  if to_number(substr(s1,1,instr(s1,'.')-1))<10 then
    s1 := null;
  else
    s1 := ' DROP INDEX';
  end if;
  for c in (select ui.index_name,ui.table_name,ui.leaf_blocks,uc.constraint_type
              from user_indexes ui, user_constraints uc, class_indexes ci
             where ui.index_name=ci.name
               and ui.table_name like 'Z#%'
               and uc.constraint_name(+) = ui.index_name
               and uc.table_name(+) = ui.table_name
               and nvl(ci.primary_key,'0')<>'1'
               and not exists (select 1 from class_partitions cp where cp.class_id=ci.class_id)
             order by ui.leaf_blocks desc)
  loop
    get_params(c.leaf_blocks*&&dbsize);
    stdio.put_line_buf('exec :s:=index_mgr.create_index('''||c.index_name||
    ''',false,0.9,''&&tsidx'',p_init_extent=>'||spi||',p_next_extent=>'||spn||')');
    if upper('&&idxdrop')='Y' then
      if c.constraint_type is null then
        storage_utils.execute_sql('DROP INDEX '||c.index_name,'Dropping '||c.index_name,true);
      else
        storage_utils.execute_sql('ALTER TABLE '||c.table_name||'DROP CONSTRAINT '||c.index_name||s1,'Dropping '||c.index_name,true);
      end if;
    end if;
  end loop;
  storage_utils.ws('Dropping user indexes finished...');
end;
/

prompt select 'Finished creating indexes - '||TO_CHAR(SYSDATE,'DD/MM/YY (HH24:MI:SS)') from dual;;
prompt spool off
spool off

set termout on
set feedback on
set heading on
set newpage 1
set pagesize 1000
