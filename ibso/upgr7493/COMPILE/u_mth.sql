exec dbms_session.reset_package;
exec executor.dummy;
exec stdio.enable_buf;
exec stdio.enable_buf;
exec executor.setnlsparameters
var n number
exec :n:=executor.lock_open;
exec executor.lock_read;

declare
    v_id  number;
    procedure upd$rtl(p_pack varchar2) is
        v_pack varchar2(30) := p_pack||'.%';
        n   pls_integer;
    begin
        select count(1) into n from rtl_entries where method_id=p_pack and rownum<2 and id>0;
        if n>0 then
          begin
            delete rtl_parameters where rtl_id in
              (select id from rtl_entries where method_id='PL_SQL' and name like v_pack and id>0);
            delete rtl_entries where method_id='PL_SQL' and name like v_pack and id>0;
            update rtl_entries set
                method_id = 'PL_SQL',
                name = p_pack||'.'||name
             where method_id=p_pack and id>0;
            commit;
          exception when others then
            rollback;
          end;
        end if;
    end;
    procedure upd_rtl(p_pack varchar2, p_retry boolean) is
        v_pack varchar2(30) := p_pack||'.%';
        n   pls_integer;
    begin
        select count(1) into n from rtl_entries
         where method_id='PL_SQL' and name like v_pack and rownum<2 and id>0;
        if n>0 then
          begin
            delete rtl_parameters where rtl_id in
              (select id from rtl_entries where method_id=p_pack and id>0);
            delete rtl_entries where method_id=p_pack and id>0;
            update rtl_entries set
                method_id = p_pack,
                name = substr(name,instr(name,'.')+1)
             where method_id='PL_SQL' and name like v_pack and id>0;
            commit;
          exception when others then
            rollback;
          end;
        elsif p_retry then
            plib.parse_package(p_pack);
            upd_rtl(p_pack,false);
        end if;
    end;
begin
    if nvl(:mtd_cnt,0)=0 then
        upd$rtl('MESSAGE');
        upd$rtl('RC$INTER');
        upd$rtl('STDIO');
        upd$rtl('UTILS');
        upd$rtl('DBF');
        method.process_plsql(nvl('&&pipe_name','COMPILE$'||USER));
        upd_rtl('MESSAGE',true);
        upd_rtl('RC$INTER',true);
        upd_rtl('STDIO',true);
        upd_rtl('UTILS',true);
        upd_rtl('DBF',true);
        sviews.create_all_sviews;
        select id into v_id from rtl_entries
         where method_id='STDIO' and name='GET_LINE' and type='P' and id>0;
        insert into rtl_parameters (rtl_id,pos,par_name,dir,flag,class_id)
          values (v_id,-2,'GET_LINE$PROCEDURE','O','W','<NEW NAME>');
        commit;
        select id into v_id from rtl_entries
         where method_id='PL_SQL' and name='LIB.QUAL_COLUMN' and type='F' and id>0;
        insert into rtl_parameters (rtl_id,pos,par_name,dir,flag,class_id)
          values (v_id,-2,'QUAL_COLUMN_F','O','W','<NEW NAME>');
        commit;
    end if;
end;
/

exec stdio.disable_buf

declare
/*
    $Author: Alexey $
    Дополнительный скрипт, используется в C_METH.SQL
   (в нем можно модифицировать условие выборки операций - m_cursor)
*/
r_cursor sys_refcursor;
m_cursor method.methods_cursor_t;
c_cursor class_utils.class_cursor_t;
mtd class_utils.id_tab;
n   pls_integer;
j   pls_integer;
cnt pls_integer;
typ pls_integer := nvl(:mtd_cnt,0);
str varchar2(32000);
pipe   varchar2(10000);
    procedure clear_renamed is
    begin
      delete from rtl_parameters
       where pos = -2 and par_name not like 'plp$%' and exists
       (select 1 from rtl_entries where id = rtl_id and method_id not in ('PL_SQL','STDIO')
           and plib.correct_name(substr(name,instr(name,'.')+1))<>par_name);
      commit;
    end;
begin
    pipe := nvl('&&pipe_name','COMPILE$'||USER);
    stdio.disable_buf;
    if typ>9 then -- classes
        open c_cursor for
          select id,name,base_class_id,target_class_id,parent_id
            from classes
           order by id
        ;
        class_utils.compile_classes(c_cursor,pipe,null);
        class_utils.get_class_buf(mtd);
    else
      if typ=1 then -- invalid methods
        open m_cursor for
          select id,class_id,short_name
            from methods m
           where kernel='0' and
                 ( m.status<>'VALID'
                   or not exists
                      (select 1 from all_objects o
                        where o.OWNER = USER
						  and o.object_name = m.package_name
                          and o.object_type = 'PACKAGE BODY' and rownum=1)
                   or exists
                      (select 1 from user_errors e where e.name = m.package_name and rownum=1)
                 )
           order by class_id,short_name
        ;
      elsif typ=2 then -- all method interfaces
        open m_cursor for
          select id,class_id,short_name
            from methods m
           where kernel='0' and
                 ( flags = 'O'
                   or ext_id  is not null
                   or form_id is not null
                   or flags not in ('A','L','T') and
                      ( exists (select 1 from controls where meth_id = m.id)
                        or src_id is not null and
                           (exists (select 1 from controls where meth_id = src_id)
                           or (select form_id from methods where id=m.src_id) is not null)
                      )
                 )
           order by class_id,short_name
        ;
      elsif typ=3 then -- invalid method interfaces
        open m_cursor for
          select id,class_id,short_name
            from methods m
           where kernel='0' and ext_id is null and
                 ( flags = 'O'
                   or form_id is not null
                   or flags not in ('A','L','T') and
                     ( exists (select 1 from controls where meth_id = m.id)
                       or src_id is not null and
                          (exists (select 1 from controls where meth_id = src_id)
                           or (select form_id from methods where id=m.src_id) is not null)
                   )
                 ) and
                 ( not exists
                      (select 1 from all_objects o
					    where o.OWNER = USER
                          and o.object_name = 'Z$U$'||m.id
                          and o.object_type = 'PACKAGE BODY' and rownum=1)
                   or exists
                      (select 1 from user_errors e where e.name = 'Z$U$'||m.id and rownum=1)
             )
           order by class_id,short_name
        ;
      elsif typ=4 then -- all views
        open m_cursor for
          select id,'V.'||class_id,short_name from criteria
           where src_id is null
           order by class_id,short_name
        ;
      elsif typ=5 then -- invalid views
        open /*+ RULE */  m_cursor for
          select id,'V.'||class_id,short_name
            from criteria c
           where src_id is null and
                 exists (select 1 from user_errors e where e.name=c.short_name and rownum=1)
              or not exists (select 1 from user_views v where v.view_name=c.short_name and rownum=1)
           order by class_id,short_name
        ;
      elsif typ=6 then -- all methods for java
        clear_renamed;
        if method.get_obj_status('HOST_SOURCES','TABLE') is null then
          str := null;
        else
          str := ' and exists (select 1 from host_sources h where h.id=m.id)';
        end if;
        open r_cursor for
          'select --+ first_rows
                 id,class_id,short_name
            from methods m
           where kernel=''0'''||str||'
           order by class_id,short_name'
        ;
        m_cursor := r_cursor;
      elsif typ=7 then -- invalid methods for java
        clear_renamed;
        if method.get_obj_status('HOST_SOURCES','TABLE') is null then
          str := null;
        else
          str := ' and exists (select 1 from host_sources h where h.id=m.id and h.code is null)';
        end if;
        open r_cursor for
          'select --+ first_rows
                 id,class_id,short_name
            from methods m
           where kernel=''0'''||str||'
           order by class_id,short_name'
        ;
        m_cursor := r_cursor;
      elsif typ=8 then -- initial set for eclipse
        clear_renamed;
        open m_cursor for
          select id,class_id,short_name
            from methods m
           where kernel='0' and status<>'INVALID'
             and class_id not in ('MIGR','CONV_57','CONV_81','CONV_55','CONV_56','CONV_56_57','VND_UNUSED','VND_INVALID')
             and class_id not like 'DWO%' and class_id not like 'DW0%' and class_id not like 'VND_MEGA_COD%'
           order by method.extract_property(properties,'SYNONYM'),class_id,short_name
        ;
      else -- all methods
        open m_cursor for
          select id,flags||'.'||class_id,short_name
            from methods m
           where kernel='0'
           order by class_id,short_name
        ;
      end if;
      method.compile_methods(m_cursor,pipe,null,typ<2);
      method.get_method_buf(mtd);
    end if;
    pipe := 'BUFFER$'||dbms_session.unique_session_id;
    n := dbms_pipe.remove_pipe(pipe);
    dbms_pipe.reset_buffer;
    n := mtd.first; cnt := 0;
    while n is not null loop
      cnt := cnt+1;
      str := mtd(n).id||'.'||mtd(n).name||' - '||cnt||'/'||mtd.count;
      dbms_pipe.pack_message(str);
      j := dbms_pipe.send_message(pipe,1,50000000);
      if j<>0 then
        dbms_pipe.reset_buffer;
        dbms_pipe.pack_message(str);
        j := dbms_pipe.send_message(pipe,1,50000000);
      end if;
      n := mtd.next(n);
    end loop;
    rtl.set_debug(0,rtl.DEBUG2BUF,10000000);
    :mtd_cnt := cnt;
end;
/

exec stdio.enable_buf(10000000);
exec stdio.enable_buf(10000000);

