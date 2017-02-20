declare
type meth_tab is table of varchar2(1) index by varchar2(100);
    mtab    meth_tab;
begin
    stdio.enable_buf(1000000);
stdio.put_line_buf('EXEC stdio.enable_buf(100000)');
stdio.put_line_buf('prompt ----'||chr(10));
stdio.put_line_buf('prompt dropping tables'||chr(10));
stdio.put_line_buf('prompt ****'||chr(10));
    for c in (select table_name,owner,log_table,log_owner from class_tables)
    loop
        if c.owner is null then
          c.owner := inst_info.gowner;
        end if;
        mtab(c.owner||'.'||c.table_name) := null;
        if not c.log_table is null then
          if c.log_owner is null then
            c.log_owner := inst_info.gowner;
          end if;
          mtab(c.log_owner||'.'||c.log_table) := null;
        end if;
    end loop;
    for c in (select mirror,mirror_owner from class_partitions where mirror is not null)
    loop
        if c.mirror_owner is null then
          c.mirror_owner := inst_info.gowner;
        end if;
        mtab(c.mirror_owner||'.'||c.mirror) := null;
    end loop;
    for c  in
        (select table_name,owner,num_rows from dba_tables
          where table_name like 'Z#%' and owner in (inst_info.owner,inst_info.gowner,inst_info.downer1,inst_info.downer2))
    loop
        if c.num_rows=0 and not mtab.exists(c.owner||'.'||c.table_name) then
stdio.put_line_buf('prompt dropping '||c.table_name);
stdio.put_line_buf('delete class_tab_columns where table_name='''||c.table_name||''';');
if c.owner=inst_info.owner then
stdio.put_line_buf('DROP table '||c.table_name||' cascade constraints;');
else
stdio.put_line_buf('exec '||c.owner||'.admin_mgr.execute_sql(''DROP table '||c.table_name||' cascade constraints'')');
end if;
--stdio.put_line_buf('prompt ----'||chr(10));
        end if;
    end loop;
    mtab.delete;
stdio.put_line_buf('prompt ----'||chr(10));
stdio.put_line_buf('prompt dropping views'||chr(10));
stdio.put_line_buf('prompt ****'||chr(10));
    for c in (select short_name from criteria)
    loop
        mtab(upper(c.short_name)) := null;
    end loop;
    for c in (select distinct join_id from criteria_complex where join<>'REFERENCE')
    loop
        mtab('VW_COMP_'||c.join_id) := null;
    end loop;
    for c in (select distinct target_class_id from classes where base_class_id='COLLECTION')
    loop
        mtab('VW_C2O_'||c.target_class_id) := null;
        mtab('VW_C2P_'||c.target_class_id) := null;
    end loop;
    for c in (select name from report_views)
    loop
        mtab(upper(c.name)) := null;
    end loop;
    for c in (
      select table_name from class_tables where class_id in
      (select class_id from class_partitions where partition_position is not null)
    ) loop
        mtab(c.table_name||'#PRT') := null;
    end loop;
    for c  in
        (select view_name from user_views
          where view_name like 'VW\_CRIT\_%' escape '\'
             or view_name like 'VW\_COMP\_%' escape '\'
             or view_name like 'VW\_RPT\_%'  escape '\'
             or view_name like 'VW\_C2O\_%'  escape '\'
             or view_name like 'VW\_C2P\_%'  escape '\'
             or view_name like 'VW\_SQL\_%'  escape '\'
             or view_name like 'Z#%#PRT')
    loop
        if not mtab.exists(c.view_name) then
stdio.put_line_buf('prompt dropping '||c.view_name);
stdio.put_line_buf('DROP view '||c.view_name||';');
--stdio.put_line_buf('prompt ----'||chr(10));
        end if;
    end loop;
    mtab.delete;
end;
/

declare
type meth_tab is table of varchar2(1) index by varchar2(100);
    mtab    meth_tab;
    ok      boolean;
    s       varchar2(100);
begin
    stdio.enable_buf(1000000);
stdio.put_line_buf('prompt ----'||chr(10));
stdio.put_line_buf('prompt dropping packages'||chr(10));
stdio.put_line_buf('prompt ****'||chr(10));
    for c in (select id from classes)
    loop
        s := class_mgr.interface_package(c.id);
        mtab(substr(s,1,instr(s,'#',-1))) := null;
    end loop;
    for c  in
        (select object_name from user_objects
          where object_type='PACKAGE' and object_name like 'Z#_%#_%')
    loop
        s := c.object_name;
        if not mtab.exists(substr(s,1,instr(s,'#',-1))) then
stdio.put_line_buf('prompt dropping '||c.object_name);
stdio.put_line_buf('DROP package '||c.object_name||';');
--stdio.put_line_buf('prompt ----'||chr(10));
        end if;
    end loop;
    mtab.delete;
    for c in
        (select id,package_name,flags,kernel,form_id from methods
          where package_name is not null and short_name>='A')
    loop
        ok := c.flags<>'Z' or c.form_id is not null;
        if not ok then
          for m in ( select method_id from method_parameters where method_id=c.id )
          loop
             ok := true; exit;
          end loop;
          if not ok then
            for m in ( select method_id from method_variables where method_id=c.id )
            loop
               ok := true; exit;
            end loop;
          end if;
          if not ok then
            for m in ( select name from sources where name=c.id )
            loop
               ok := true; exit;
            end loop;
          end if;
        end if;
        if ok then
            mtab(c.package_name) := null;
        end if;
        if ok and c.kernel='0' and c.flags not in ('L','T') then
            ok := c.flags='O' or c.form_id is not null;
            if not ok then
              for m in ( select meth_id from controls where meth_id=c.id )
              loop
                ok := true; exit;
              end loop;
            end if;
            if ok then
                mtab(method_mgr.interface_package_name(c.id)) := null;
            end if;
        end if;
    end loop;
    for c  in
        (select object_name from user_objects
          where object_type='PACKAGE' and object_name like 'Z$%')
    loop
        if not mtab.exists(c.object_name) then
stdio.put_line_buf('prompt dropping '||c.object_name);
stdio.put_line_buf('DROP package '||c.object_name||';');
--stdio.put_line_buf('prompt ----'||chr(10));
        end if;
    end loop;
    mtab.delete;
stdio.put_line_buf('prompt ----'||chr(10));
stdio.put_line_buf('prompt dropping package bodies'||chr(10));
stdio.put_line_buf('prompt ****'||chr(10));
    for c  in
        (select object_name from user_objects o1
          where o1.object_type in('PACKAGE BODY','PACKAGE')
          group by o1.object_name
          having count(*)=1 and min(o1.object_type) ='PACKAGE BODY')
    loop
stdio.put_line_buf('prompt dropping body '||c.object_name);
stdio.put_line_buf('DROP package body '||c.object_name||';');
--stdio.put_line_buf('prompt ----'||chr(10));
    end loop;
	dbms_session.free_unused_user_memory;
end;
/

