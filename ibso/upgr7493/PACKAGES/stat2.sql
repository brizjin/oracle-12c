prompt stat_lib body
create or replace package body
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/stat2.sql $
 *  $Author: Alexey $
 *  $Revision: 15072 $
 *  $Date:: 2012-03-06 13:41:17 #$
 */
stat_lib is
--
user_context      constant varchar2(40) := inst_info.owner||'_USER';
current_disabled  boolean;
--
function get_version return varchar2 is
begin
  return '4.3';
end;
--
function  disabled return boolean is
begin
  if current_disabled is null then
    current_disabled := nvl(sys_context(user_context,'STATS_DISABLED'),'0')='1';
  end if;
  return current_disabled;
end;
--
procedure set_statistics(p_disable boolean) is
begin
  if p_disable then
    current_disabled := true;
    executor.set_context('STATS_DISABLED','1')	;
  elsif not rtl.db_readonly then
    current_disabled := false;
    executor.set_context('STATS_DISABLED','0')	;
  end if;
end;
--
function check_run(p_obj_id varchar2, p_obj_type varchar2 default null) return pls_integer is
  i pls_integer;
  s varchar2(100);
begin
  rtl.read(null);
  if disabled or p_obj_id is null then
    return 0;
  end if;
  s := upper(substr(stdio.setting('STATS_COLLECTING'),1,1));
  if s = 'A' then
    if upper(substr(stdio.setting('STATS_COLLECT_WAITS'),1,1)) in ('1','Y') then
      return 5;
    end if;
    return 1;
  elsif s = 'N' then
    return 0;
  end if;
  s := nvl(p_obj_type,'METHOD');
  for c in (
    select c_flags from Z#RUN_STAT_KIND
     where c_obj_id = p_obj_id and c_obj_type = s and c_enabled = '1'
  ) loop
    return c.c_flags;
  end loop;
  return 0;
end;
--
function put_start1 ( p_run   in out nocopy number,
                      p_group in out nocopy number,
                      p_process      varchar2,
                      p_obj_id       varchar2,
                      p_obj_type     varchar2,
                      p_details      varchar2,
                      p_obj_class_id varchar2,
                      p_short_name   varchar2,
                      p_name         varchar2,
                      p_stat pls_integer default null,
                      p_prec varchar2 default null) return varchar2 is
  i pls_integer;
  j pls_integer;
  s varchar2(256);
begin
  if p_stat is null or not p_process is null then
    if upper(substr(stdio.setting('STATS_COLLECT_WAITS'),1,1)) in ('Y','1') then
      i := 5;
    else
      i := 1;
    end if;
    --i := i+2;
  else
    i := p_stat;
  end if;
  if bitand(i,5)>0 then
    s := Z$RUN_SESSIONS_SET_RUN.put_stat(p_run,p_group,null,p_process,p_obj_id,p_obj_type,p_details,p_obj_class_id,p_short_name,p_name,bitand(i,4)>0);
  else
    p_run := null;
  end if;
  if bitand(i,2)>0 then
    if p_group is null then
      p_group := Z$RUN_SESSIONS_SET_RUN.set_group(p_obj_id,p_obj_type,p_details,p_obj_class_id,p_short_name,p_name,true);
    end if;
    Z$RUN_SESSIONS_RLIB.init_handle(0,p_group,upper(substr(stdio.setting('STATS_COLLECT_PRECISE'),1,1)) in ('Y','1'));
    if p_prec='1' then
      i := i+128;
      j := Z$RUN_SESSIONS_RLIB.start_counters(0,p_group);
      if j < 0 then
        s := s||chr(10)||Z$RUN_SESSIONS_RLIB.error_message(j);
      end if;
    end if;
  end if;
  executor.set_context('RUN_STATS_LEVEL',i);
  if bitand(i,8)>0 then
    if p_group is null then
      p_group := Z$RUN_SESSIONS_SET_RUN.set_group(p_obj_id,p_obj_type,p_details,p_obj_class_id,p_short_name,p_name,true);
    end if;
    j := rtl.execute_sql('alter session set tracefile_identifier='''||p_group||'_'||rtl.uid$||'''');
    utils.set_sql_trace(true);
  end if;
  return s;
end;
--
function put_start2 ( p_run in out nocopy number,
                      p_group   number,
                      p_process varchar2,
                      p_stat pls_integer default null,
                      p_prec varchar2 default null) return varchar2 is
  v_group number := p_group;
begin
  return put_start1(p_run,v_group,p_process,null,null,null,null,null,null,p_stat,p_prec);
end;
--
function put_stop(p_run number) return varchar2 is
  v_group number;
  v_run   number;
  i pls_integer;
  s varchar2(128);
begin
  i := sys_context(user_context,'RUN_STATS_LEVEL');
  executor.set_context('RUN_STATS_LEVEL',0);
  if bitand(i,8)>0 then
    utils.set_sql_trace(false);
    v_run := rtl.execute_sql('alter session set tracefile_identifier=''''');
  end if;
  if bitand(i,128)>0 then
    Z$RUN_SESSIONS_RLIB.stop_all_counters;
  end if;
  v_run := p_run;
  if not v_run is null then
    s := Z$RUN_SESSIONS_SET_RUN.put_stat(v_run,v_group,false,null,null,null,null,null,null,null);
    v_run := Z$RUN_SESSIONS_SET_RUN.last_run;
  end if;
  if bitand(i,2)>0 then
    Z$RUN_SESSIONS_RLIB.save_all_counters(v_run);
    Z$RUN_SESSIONS_RLIB.close_all_handles;
  end if;
  return s;
end;
--
function get_group_id( p_obj_id       varchar2,
                       p_obj_type     varchar2,
                       p_details      varchar2) return number is
begin
  return Z$RUN_SESSIONS_SET_RUN.get_group(p_obj_id,p_obj_type,p_details);
end;
--
function set_group_id( p_obj_id       varchar2,
                       p_obj_type     varchar2,
                       p_details      varchar2,
                       p_obj_class_id varchar2,
                       p_short_name   varchar2,
                       p_name         varchar2) return number is
  pragma autonomous_transaction;
  v_ref number;
begin
  if not rtl.info_open then
    v_ref := rtl.open;
  end if;
  v_ref := Z$RUN_SESSIONS_SET_RUN.set_group(p_obj_id,p_obj_type,p_details,p_obj_class_id,p_short_name,p_name,true);
  commit;
  return v_ref;
end;
--
function set_dict_object(
			p_obj_id	varchar2,	
			p_obj_type	varchar2,
			p_enable	boolean default null,
			p_flags		pls_integer	default null,
			p_add 		boolean default null
		) return number is
begin
  return Z$RUN_SESSIONS_SET_RUN.set_dict_object(p_obj_id,p_obj_type,p_enable,p_flags,p_add);
end;
--
function start_prec(p_group number) return varchar2 is
  i pls_integer;
begin
  i := Z$RUN_SESSIONS_RLIB.start_counters(0,p_group);
  if i<0 then
    return Z$RUN_SESSIONS_RLIB.error_message(i);
  end if;
  return null;
end;
--
procedure stop_prec is
begin
  Z$RUN_SESSIONS_RLIB.stop_all_counters;
  if bitand(sys_context(user_context,'RUN_STATS_LEVEL'),2) > 0 then null;
  else
    Z$RUN_SESSIONS_RLIB.close_all_handles;
  end if;
end;
--
procedure start_report_job(p_job number,p_pos number) is
  pragma autonomous_transaction;
  v_props varchar2(4000);
  v_obj   varchar2(16);
  v_cls   varchar2(16);
  v_sn    varchar2(16);
  v_str   varchar2(100);
  v_id    number;
  v_grp   number;
  b boolean;
  i pls_integer;
begin
  if not rtl.info_open then
    return;
  end if;
  rtl.read(null);
  v_str:= inst_info.owner||'_SYSTEM';
  select method_id, properties into v_obj, v_props
    from orsa_jobs where job=p_job and pos=p_pos and to_number(sys_context(v_str,'ID'))<-1073741823
     for update nowait;
  v_grp := method.extract_property(v_props,'GROUPID');
  i := method.extract_property(v_props,'STATS');
  if v_grp is null then
    select class_id, short_name, name into v_cls, v_sn, v_str
      from methods where id=v_obj;
    b := put_start1(v_id,v_grp,null,v_obj,'METHOD','REPORT',v_cls,v_sn,v_str,i,'1') is null;
  else
    b := put_start2(v_id,v_grp,null,i,'1') is null;
  end if;
  if b then
    method.put_property(v_props,'RUNID',v_id);
    method.put_property(v_props,'GROUPID',v_grp);
    update orsa_jobs set properties=v_props where job=p_job and pos=p_pos;
  end if;
  rtl.lock_clear;
  commit;
exception when NO_DATA_FOUND or rtl.RESOURCE_BUSY then
  rollback;
end;
--
procedure stop_report_job (p_job number,p_pos number) is
  pragma autonomous_transaction;
  v_props varchar2(4000);
  v_id    number;
  v_code  number;
begin
  if not rtl.info_open then
    v_id := rtl.open;
  end if;
  select properties, state_code into v_props, v_code
    from orsa_jobs where job=p_job and pos=p_pos
     for update nowait;
  v_id := method.extract_property(v_props,'RUNID');
  if v_id is null then
    raise no_data_found;
  end if;
  rtl.read(null);
  if v_code=2 then
    rtl.destructor(v_id,'RUN_SESSIONS','RUN_SESSIONS');
  else
    method.put_property(v_props,'RUNSTAT',put_stop(v_id));
  end if;
  method.put_property(v_props,'RUNID',null);
  update orsa_jobs set properties=v_props where job=p_job and pos=p_pos;
  rtl.lock_clear;
  commit;
exception when NO_DATA_FOUND or rtl.RESOURCE_BUSY then
  rollback;
end;
--
begin
  if rtl.db_readonly then
    set_statistics(true);
  end if;
end stat_lib;
/
show errors package body stat_lib

