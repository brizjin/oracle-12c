prompt conv body
create or replace package body
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/AUD/conv2.sql $
 *  $Author: Alexey $
 *  $Revision: 15071 $
 *  $Date:: 2012-03-06 13:38:04 #$
 */
conv is
--
min_keeptime constant date := to_date('01/01/1900', 'DD/MM/YYYY');
cur_owner varchar2(30);
cur_paral pls_integer;
--
procedure check_version(old_version varchar2,  del_data varchar2,
                        cnv in out nocopy varchar2, del in out nocopy boolean) is
  ov  number := to_number(old_version,'999.9');
begin
  del := false;
  if ov<3.4 then
    cnv := '2';
  else
    if ov<5.4 then
      cnv := '1';
    else
      cnv := '3';
    end if;
    if substr(upper(del_data),1,1) in ('Y','1') then
      del := true;
    end if;
  end if;
end;
--
procedure init_pack(p_owner varchar2) is
  v varchar2(100);
begin
  if cur_owner is null then
    execute immediate 'alter session set time_zone=dbtimezone';
  elsif cur_owner = p_owner then
    return;
  end if;
  cur_owner := p_owner;
  cur_paral := utils.force_parallel(p_owner);
  if cur_paral>0 then
    execute immediate 'alter session enable parallel dml';
  end if;
end;
--
procedure get_insert_header(p_ins in out nocopy varchar2) is
begin
  if cur_paral>0 then
    p_ins := 'parallel(t$';
    if cur_paral>1 then
      p_ins := p_ins||','||cur_paral;
    end if;
    p_ins := p_ins||') ';
  else
    p_ins := null;
  end if;
  p_ins := 'insert /*+ '||p_ins||'append */ into ';
end;
--
procedure convert_table(owner varchar2, tab_type pls_integer,
                        start_date date, end_date date,
                        table_name in out varchar2, table_created out boolean,
                        old_fields varchar2 default null) is
  cnt pls_integer;
  v_fields  varchar2(1000);
  v_ins     varchar2(200);
  v_drop    boolean;
begin
  init_pack(owner);
  table_name := utils.table_name(owner, tab_type);
  if utils.tableexists(table_name) then
    v_fields := utils.check_table_columns(owner, tab_type);
    if v_fields is null then
      utils.upgrade_table(owner, tab_type);
    else
      get_insert_header(v_ins);
      utils.drop_indexes(owner, tab_type);
      v_drop := false;
      begin
        utils.create_table(owner, tab_type, start_date, end_date, table_name||'$');
        v_drop := true;
        cnt := utils.execute_sql(v_ins||table_name||'$ t$('||v_fields||') select '||v_fields||' from '||table_name);
        utils.put_line('Converted ' || cnt || ' rows from ' || table_name || ' to ' || table_name||'$');
        utils.execute_sql('drop table '||table_name, 'Dropping table '||table_name);
        v_drop := false;
        utils.execute_sql('alter table '||table_name||'$ rename to '||table_name,
          'Renaming table '||table_name||'$ to '||table_name);
        table_created := true;
      exception when others then
        rollback;
        if v_drop then
          utils.execute_sql('drop table '||table_name||'$', 'Dropping table '||table_name||'$', true);
        end if;
        raise;
      end;
    end if;
  else
    utils.create_table(owner, tab_type, start_date, end_date);
    table_created := true;
  end if;
end;
--
procedure object_state_history(owner varchar2, old_version varchar2, del_data varchar2, keeptime date, start_date date, end_date date, restore_idxs boolean) is
  drop_indexes boolean;
  n integer;
  c varchar2(30);
  w varchar2(200);
  s varchar2(2000);
  v_ins      varchar2(200);
  table_name varchar2(200);
  table_created boolean;
  cnv varchar2(1);
  del boolean;
begin
  check_version(old_version, del_data, cnv, del);
  convert_table(owner, utils.OSH, start_date, end_date, table_name, table_created,
    'id, time, obj_id, state_id, audsid, user_id');
  if cnv in ('1','2') then
    if cnv='1' then
      c := 'id';
      w := 'object_state_history';
      s := w || ' where owner=''' || owner || ''' and';
    else
      c := 'osh_id.nextval';
      w := owner || '.object_state_history';
      s := w || ' where';
    end if;
    n := utils.execute_sql('begin select count(1) into :RES from ' || s || ' rownum<=100000; end;', null, true, '0');
    drop_indexes := (n = 100000);
    if drop_indexes and not nvl(table_created, false) then
        utils.drop_indexes(owner, utils.OSH);
    end if;
    get_insert_header(v_ins);
    s := v_ins|| table_name || ' t$(id, time, obj_id, state_id, user_id, audsid)
    select ' || c || ', time, obj_id, state_id, nvl(substr(user_id,1,instr(user_id,''.'',1,2)-1), user_id),
      decode(instr(user_id,''.'',1,2),0,null,substr(user_id,instr(user_id,''.'',1,2)+1))
    from ' || s || ' obj_id<''A'' and time>=to_date(''' || to_char(nvl(keeptime, min_keeptime), 'DD/MM/YYYY') || ''',''DD/MM/YYYY'')';
    begin
      n:=utils.execute_sql(s);
      commit;
    exception when others then
      rollback;
      n:=-1;
    end;
    utils.put_line('Converted ' || n || ' rows from ' || w || ' to ' || table_name);
    if restore_idxs then
      utils.create_indexes(owner, utils.OSH);
    end if;
    if n >= 0 and del then
      if drop_indexes then
        utils.execute_sql('DROP INDEX IDX_OSH_OBJ_ID','DROP IDX_OSH_OBJ_ID',true);
      end if;
      n:=utils.execute_sql('delete from object_state_history where owner=''' || owner || '''');
      commit;
      utils.put_line('Deleted ' || n || ' rows in ' || w);
    end if;
  elsif cnv = '3' then
    if restore_idxs then
      utils.create_indexes(owner, utils.OSH);
    end if;
  end if;
end;
--
procedure values_history(owner varchar2, old_version varchar2, del_data varchar2, keeptime date, start_date date, end_date date, restore_idxs boolean) is
  drop_indexes boolean;
  n integer;
  w varchar2(200);
  s varchar2(2000);
  v_ins      varchar2(200);
  table_name varchar2(200);
  table_created boolean;
  cnv varchar2(1);
  del boolean;
begin
  check_version(old_version, del_data, cnv, del);
  convert_table(owner, utils.VALSH, start_date, end_date, table_name, table_created,
    'id, time, obj_id, audsid, user_id, qual, base_id, value');
  if cnv in ('1','2') then
    if cnv='1' then
      w := 'values_history';
      s := w || ' where owner=''' || owner || ''' and';
    else
      w := owner || '.values_history';
      s := w || ' where';
    end if;
    n := utils.execute_sql('begin select count(1) into :RES from ' || s || ' rownum<=100000; end;',null,true,'0');
    drop_indexes := n=100000;
    if drop_indexes and not nvl(table_created, false) then
      utils.drop_indexes(owner, utils.VALSH);
    end if;
    get_insert_header(v_ins);
    if cnv='1' then
      s := v_ins || table_name || ' t$(id,time,obj_id,audsid,user_id,qual,base_id,value)
      select id,time,obj_id,substr(user_id,instr(user_id,''.'',1,2)+1),nvl(substr(user_id,1,instr(user_id,''.'',1,2)-1),user_id),qual,base_id,value
      from ' || s || ' obj_id<''A'' and time>=to_date(''' || to_char(nvl(keeptime, min_keeptime), 'DD/MM/YYYY')|| ''',''DD/MM/YYYY'')';
    else
      s := v_ins || table_name || ' t$(id,time,obj_id,audsid,user_id,qual,base_id,value)
      select vals_id.nextval,time,obj_id,null,user_id,qual,
              decode(string_value,null,
                decode(memo_value,null,
                  decode(obj_ref,null,
                    decode(col_ref,null,
                      decode(date_value,null,
                        decode(numeric_value,null,null,''NUMBER''),
                      ''DATE''),
                    ''COLLECTION''),
                  ''REFERENCE''),
                ''MEMO''),
              ''STRING''),
              nvl(string_value,
                nvl(memo_value,
                  nvl(obj_ref,
                    nvl(col_ref,
                      nvl(to_char(date_value,''YYYY-MM-DD HH24:MI:SS''),to_char(numeric_value))
                       )
                     )
                   )
                 )
      from ' || s || ' obj_id<''A'' and time>=to_date(''' || to_char(nvl(keeptime, min_keeptime), 'DD/MM/YYYY')|| ''',''DD/MM/YYYY'')';
    end if;
    begin
      n:=utils.execute_sql(s);
      commit;
    exception when others then
      rollback;
      n:=-1;
    end;
    utils.put_line('Converted ' || n || ' rows from ' || w);
    if restore_idxs then
      utils.create_indexes(owner, utils.VALSH);
    end if;
    if n >= 0 and del then
      if drop_indexes then
        utils.execute_sql('DROP INDEX IDX_VALUES_HISTORY_OBJ_ID','DROP IDX_VALUES_HISTORY_OBJ_ID',true);
      end if;
      n:=utils.execute_sql('delete from values_history where owner=''' || owner || '''');
      commit;
      utils.put_line('Deleted ' || n || ' rows in ' || w);
    end if;
  elsif cnv = '3' then
    if restore_idxs then
      utils.create_indexes(owner, utils.VALSH);
    end if;
  end if;
end;
--
procedure diary_param(owner varchar2, old_version varchar2, del_data varchar2, keeptime date, start_date date, end_date date, restore_idxs boolean, drp in out boolean) is
  n integer;
  i integer;
  b boolean;
  j pls_integer;
  nn integer;
  c1 integer;
  c2 integer;
  c3 integer;
  sid integer;
  mid varchar2(30);
  v_ins      varchar2(200);
  table_dp_name varchar2(200);
  table_dp_created boolean;
  table_d2_name varchar2(200);
  table_d2_created boolean;
  v_type  varchar2(100);
  cnv varchar2(1);
  del boolean;
begin
  check_version(old_version, del_data, cnv, del);
  init_pack(owner);
  table_dp_name := utils.table_name(owner, utils.DP);
  table_d2_name := utils.table_name(owner, utils.DIARY2);
  if utils.table_exists(owner, utils.DP) then
    v_type := utils.get_column_type(table_dp_name,'TIME');
    if (v_type is null or to_number(old_version,'999.9') < 6.1)
        and utils.table_exists(owner, utils.DIARY2)
    then
      utils.drop_indexes(owner, utils.DP);
      b := false;
      begin
        utils.create_table(owner, utils.DP, start_date, end_date, table_dp_name||'$');
        b := true;
        get_insert_header(v_ins);
        n := utils.execute_sql(v_ins||table_dp_name||'$ t$(diary_id, time, qual, text)' ||
          ' select dp.diary_id, d2.time, dp.qual, dp.text from '||table_dp_name||' dp, '||
          table_d2_name||' d2'||' where dp.diary_id = d2.id');
        utils.put_line('Converted '||n||' rows from '||table_dp_name||' to '||table_dp_name||'$');
        utils.execute_sql('drop table '||table_dp_name, 'Dropping table '||table_dp_name);
        b := false;
        utils.execute_sql('alter table '||table_dp_name||'$ rename to '||table_dp_name,
          'Renaming table '||table_dp_name||'$ to '||table_dp_name);
        table_dp_created := true;
      exception when others then
        rollback;
        if b then
          utils.execute_sql('drop table '||table_dp_name||'$', 'Dropping table '||table_dp_name||'$', true);
        end if;
        raise;
      end;
    else
      if v_type is null then
        v_type := 'diary_id, qual, text';
      else
        v_type := null;
      end if;
      convert_table(owner, utils.DP, start_date, end_date, table_dp_name, table_dp_created, v_type);
    end if;
  else
    utils.create_table(owner, utils.DP, start_date, end_date);
    table_dp_created := true;
  end if;
  convert_table(owner, utils.DIARY2, start_date, end_date, table_d2_name, table_d2_created);
  if cnv='1' then
    utils.execute_sql('ALTER TABLE ' || owner || '_DP DROP CONSTRAINT FK_' || owner || '_DP_DIARY_ID','DROP FK_' || owner || '_DP_DIARY_ID',true);
    if drp is null then
      n := utils.execute_sql('begin select count(1) into :RES from diary where owner=''' || owner || ''' and rownum<=100000; end;',null,true,'0');
      drp := (n >= 100000);
    end if;
    if drp and not nvl(table_dp_created, false) then
      utils.drop_indexes(owner, utils.DP);
    end if;
    if drp and not nvl(table_d2_created, false) then
      utils.drop_indexes(owner, utils.DIARY2);
    end if;
    c1:= dbms_sql.open_cursor;
    c2:= dbms_sql.open_cursor;
    dbms_sql.parse(c1,'insert into ' || table_d2_name || '(id,time,audsid,user_id,topic,code) values(:ID,:TIM,:SID,:USR,''P'',:MID)', dbms_sql.native);
    dbms_sql.parse(c2,'insert into ' || table_dp_name || '(diary_id,time,qual,text) select diary_id,:TIM,qual,text from diary_param where diary_id=:ID', dbms_sql.native);
    if del then
      c3:= dbms_sql.open_cursor;
      dbms_sql.parse(c3,'delete from diary_param where diary_id=:ID', dbms_sql.native);
    end if;
    n:=0; nn:=0; b:=true;
    declare
      type ref_cur_t is ref cursor;
      type c_rec_t is record (
        id number,
        time date,
        user_id varchar2 (50),
        text varchar2 (2000)
      );
      cur ref_cur_t;
      c c_rec_t;
    begin
      open cur for 'select id,time,user_id,text from diary where owner=:owner and topic=''P'' and time >= :keeptime' using owner, nvl(keeptime, min_keeptime);
      loop
        fetch cur into c;
        exit when cur%NOTFOUND;
        j := instr(c.text,'.');
        if j>0 then
          sid := substr(c.text,1,j-1);
          mid := substr(c.text,j+1);
        else
          sid := null;
          mid := substr(c.text,1,30);
        end if;
        begin
          dbms_sql.bind_variable (c2,':TIM',c.time);
          dbms_sql.bind_variable (c2,':ID',c.id);
          i := dbms_sql.execute(c2);
          if i>0 then
            dbms_sql.bind_variable (c1,':ID',c.id);
            dbms_sql.bind_variable (c1,':TIM',c.time);
            dbms_sql.bind_variable (c1,':SID',sid);
            dbms_sql.bind_variable (c1,':USR',c.user_id);
            dbms_sql.bind_variable (c1,':MID',mid);
            j := dbms_sql.execute(c1);
            if del then
              dbms_sql.bind_variable (c3,':ID',c.id);
              j := dbms_sql.execute(c3);
            end if;
            commit;
            n := n+1;
            nn:= nn+i;
          end if;
        exception when others then
          rollback;
          b := false;
          utils.put_line('Cannot convert ' ||c.id|| ' in diary:' ||chr(10)||sqlerrm);
        end;
      end loop;
      close cur;
    exception when others then
      if cur%ISOPEN then
        close cur;
      end if;
      raise;
    end;
    utils.put_line('Converted ' || n || ' rows from diary to ' || table_d2_name);
    utils.put_line('Converted ' ||nn|| ' rows from diary_param');
    dbms_sql.close_cursor(c1);
    dbms_sql.close_cursor(c2);
    if restore_idxs then
      utils.create_indexes(owner, utils.DP);
      utils.create_indexes(owner, utils.DIARY2);
    end if;
    if del then
      dbms_sql.close_cursor(c3);
     if b then
      if drp then
        utils.execute_sql('ALTER TABLE DIARY_PARAM DROP CONSTRAINT FK_DIARY_PARAM_DIARY_ID','DROP FK_DIARY_PARAM_DIARY_ID',true);
        utils.execute_sql('ALTER TABLE DIARY DROP CONSTRAINT PK_DIARY_ID','DROP PK_DIARY_ID',true);
        utils.execute_sql('DROP INDEX PK_DIARY_ID',null,true);
      end if;
      n:=utils.execute_sql('delete from diary where owner=''' || owner || ''' and topic=''P''');
      commit;
      utils.put_line('Deleted ' || n || ' rows in diary');
     end if;
    end if;
  elsif cnv = '3' then
    if restore_idxs then
      utils.create_indexes(owner, utils.DP);
      utils.create_indexes(owner, utils.DIARY2);
    end if;
  end if;
end;
--
procedure diary_debug_exec(owner varchar2, old_version varchar2, del_data varchar2, keeptime date, start_date date, end_date date, restore_idxs boolean, drp in out boolean) is
  n integer;
  n2 integer;
  c varchar2(30);
  w varchar2(200);
  s varchar2(2000);
  v_ins      varchar2(200);
  table_d7_name varchar2(200);
  table_d7_created boolean;
  table_d1_name varchar2(200);
  table_d1_created boolean;
  cnv varchar2(1);
  del boolean;
  b boolean;
begin
  check_version(old_version, del_data, cnv, del);
  if cnv in ('1','2','3') then
    init_pack(owner);
    get_insert_header(v_ins);
  end if;
  if cnv in ('1','2') then
    if drp is null then
      n := utils.execute_sql('begin select count(1) into :RES from diary where owner=''' || owner || ''' and rownum<=100000; end;',null,true,'0');
      drp := (n >= 100000);
    end if;
    convert_table(owner, utils.DIARY7, start_date, end_date, table_d7_name, table_d7_created);
    if cnv='1' then
      c := 'id';
      w := 'diary';
      s := w || ' where owner=''' || owner || ''' and';
    else
      c := 'diary_id.nextval';
      w := owner || '.diary';
      s := w || ' where';
    end if;
    s := v_ins || table_d7_name || ' t$(id,time,audsid,user_id,topic,text)
      select ' || c || ',time,replace(translate(substr(text,1,instr(text,'':'')-1),''ABCDEF'',''******''),''*''),
        user_id,topic,substr(text,instr(text,'':'')+1)
      from ' || s || ' topic=''D'' and time>=to_date(''' || to_char(nvl(keeptime, min_keeptime), 'DD/MM/YYYY')|| ''',''DD/MM/YYYY'')';
    begin
      n:=utils.execute_sql(s);
      commit;
    exception when others then
      rollback;
      n:=-1;
    end;
    utils.put_line('Converted ' || n || ' rows from ' || w || ' to ' || table_d7_name);
    if restore_idxs then
      utils.create_indexes(owner, utils.DIARY7);
    end if;
    if n >= 0 and del then
      if drp then
        utils.execute_sql('ALTER TABLE DIARY_PARAM DROP CONSTRAINT FK_DIARY_PARAM_DIARY_ID','DROP FK_DIARY_PARAM_DIARY_ID',true);
        utils.execute_sql('ALTER TABLE DIARY DROP CONSTRAINT PK_DIARY_ID','DROP PK_DIARY_ID',true);
        utils.execute_sql('DROP INDEX PK_DIARY_ID',null,true);
      end if;
      n:=utils.execute_sql('delete from diary where owner=''' || owner || ''' and topic=''D''');
      commit;
      utils.put_line('Deleted ' || n || ' rows in ' || w);
    end if;
    convert_table(owner, utils.DIARY1, start_date, end_date, table_d1_name, table_d1_created);
    if cnv='1' then
      c := 'id';
      w := 'diary';
      s := w || ' where owner=''' || owner || ''' and';
    else
      c := 'diary_id.nextval';
      w := owner || '.diary';
      s := w || ' where';
    end if;
    s := v_ins || table_d1_name || ' t$(id,time,audsid,user_id,topic,code,text)
      select ' || c || ',time,decode(instr(text,''.'',1,4),0,null,substr(text,instr(text,''.'',1,4)+1)),
        user_id,topic,substr(text,1,instr(text,''.'')-1),
        nvl(substr(text,instr(text,''.'')+1,instr(text,''.'',1,4)-instr(text,''.'')-1),substr(text,instr(text,''.'')+1))
      from ' || s || ' topic=''L'' and time>=to_date(''' || to_char(nvl(keeptime, min_keeptime), 'DD/MM/YYYY')|| ''',''DD/MM/YYYY'')';
    begin
      n:=utils.execute_sql(s);
      commit;
    exception when others then
      rollback;
      n:=-1;
    end;
    utils.put_line('Converted ' || n || ' rows from ' || w || ' to ' || table_d1_name);
    if restore_idxs then
      utils.create_indexes(owner, utils.DIARY1);
    end if;
    if n >= 0 and del then
      if drp then
        utils.execute_sql('ALTER TABLE DIARY_PARAM DROP CONSTRAINT FK_DIARY_PARAM_DIARY_ID','DROP FK_DIARY_PARAM_DIARY_ID',true);
        utils.execute_sql('ALTER TABLE DIARY DROP CONSTRAINT PK_DIARY_ID','DROP PK_DIARY_ID',true);
        utils.execute_sql('DROP INDEX PK_DIARY_ID',null,true);
      end if;
      n:=utils.execute_sql('delete from diary where owner=''' || owner || ''' and topic=''L''');
      commit;
      utils.put_line('Deleted ' || n || ' rows in ' || w);
    end if;
  elsif cnv = '3' then
    convert_table(owner, utils.DIARY7, start_date, end_date, table_d7_name, table_d7_created);
    if utils.table_exists(owner, utils.DIARY1) then
      if table_d7_created or to_number(old_version,'999.9') < 6.1 then
        table_d1_name := utils.table_name(owner, utils.DIARY1);
        utils.drop_indexes(owner, utils.DIARY1);
        b := false;
        begin
          utils.create_table(owner, utils.DIARY1, start_date, end_date, table_d1_name||'$');
          b := true;
          n := utils.execute_sql(v_ins||table_d1_name||'$ t$ select * from '||
               table_d1_name||' where topic <> ''D''');
          n2:= utils.execute_sql(v_ins||table_d7_name||' t$ select * from '||
               table_d1_name||' where topic=''D''');
          utils.put_line('Converted '|| n || ' rows from '||table_d1_name||' to '||table_d1_name||'$');
          utils.put_line('Converted '|| n2|| ' rows from '||table_d1_name||' to '||table_d7_name);
          utils.execute_sql('drop table '||table_d1_name, 'Dropping table '||table_d1_name);
          b := false;
          utils.execute_sql('alter table '||table_d1_name||'$ rename to '||table_d1_name,
            'Renaming table '||table_d1_name||'$ to '||table_d1_name);
          table_d1_created := true;
        exception when others then
          rollback;
          if b then
            utils.execute_sql('drop table '||table_d1_name||'$', 'Dropping table '||table_d1_name||'$', true);
          end if;
          raise;
        end;
      else
        convert_table(owner, utils.DIARY1, start_date, end_date, table_d1_name, table_d1_created);
      end if;
    else
      utils.create_table(owner, utils.DIARY1, start_date, end_date);
    end if;
    if restore_idxs then
      utils.create_indexes(owner, utils.DIARY7);
      utils.create_indexes(owner, utils.DIARY1);
    end if;
  end if;
end;
--
procedure diary_errors(owner varchar2, old_version varchar2, del_data varchar2, keeptime date, start_date date, end_date date, restore_idxs boolean, drp in out boolean) is
  n integer;
  c varchar2(30);
  w varchar2(200);
  s varchar2(2000);
  v_ins      varchar2(200);
  table_name varchar2(200);
  table_created boolean;
  cnv varchar2(1);
  del boolean;
begin
  check_version(old_version, del_data, cnv, del);
  convert_table(owner, utils.DIARY3, start_date, end_date, table_name, table_created);
  if cnv in ('1','2') then
    if drp is null then
      n := utils.execute_sql('begin select count(1) into :RES from diary where owner=''' || owner || ''' and rownum<=100000; end;',null,true,'0');
      drp := (n >= 100000);
    end if;
    if cnv='1' then
      c := 'id';
      w := 'diary';
      s := w || ' where owner=''' || owner || ''' and';
    else
      c := 'diary_id.nextval';
      w := owner || '.diary';
      s := w || ' where';
    end if;
    get_insert_header(v_ins);
    s := v_ins || table_name || ' t$(id,time,user_id,topic,code,text)
      select ' || c || ',time,user_id,topic,substr(text,1,instr(text,'':'')-1),ltrim(substr(text,instr(text,'':'')+1))
        from ' || s || ' topic=''E'' and time>=to_date(''' || to_char(nvl(keeptime, min_keeptime), 'DD/MM/YYYY')|| ''',''DD/MM/YYYY'')';
    begin
      n:=utils.execute_sql(s);
      commit;
    exception when others then
      rollback;
      n:=-1;
    end;
    utils.put_line('Converted ' || n || ' rows from ' || w || ' to ' || table_name);
    if restore_idxs then
      utils.create_indexes(owner, utils.DIARY3);
    end if;
    if n >= 0 and del then
      if drp then
        utils.execute_sql('ALTER TABLE DIARY_PARAM DROP CONSTRAINT FK_DIARY_PARAM_DIARY_ID','DROP FK_DIARY_PARAM_DIARY_ID',true);
        utils.execute_sql('ALTER TABLE DIARY DROP CONSTRAINT PK_DIARY_ID','DROP PK_DIARY_ID',true);
        utils.execute_sql('DROP INDEX PK_DIARY_ID',null,true);
      end if;
      n:=utils.execute_sql('delete from diary where owner=''' || owner || ''' and topic=''E''');
      commit;
      utils.put_line('Deleted ' || n || ' rows in ' || w);
    end if;
  elsif cnv = '3' then
    if restore_idxs then
      utils.create_indexes(owner, utils.DIARY3);
    end if;
  end if;
end;
--
procedure diary_uadmin(owner varchar2, old_version varchar2, del_data varchar2, keeptime date, start_date date, end_date date, restore_idxs boolean, drp in out boolean) is
  n integer;
  w varchar2(200);
  s varchar2(2000);
  v_ins      varchar2(200);
  table_name varchar2(200);
  table_created boolean;
  cnv varchar2(1);
  del boolean;
begin
  check_version(old_version, del_data, cnv, del);
  convert_table(owner, utils.DIARY3, start_date, end_date, table_name, table_created);
  if cnv in ('1','2') then
    if drp is null then
      n := utils.execute_sql('begin select count(1) into :RES from diary where owner=''' || owner || ''' and rownum<=100000; end;',null,true,'0');
      drp := (n >= 100000);
    end if;
    get_insert_header(v_ins);
    if cnv='1' then
      w := 'diary';
      s := v_ins || table_name || ' t$(id,time,user_id,topic,text)
        select id,time,user_id,topic,text from diary
          where topic=''U'' and owner=''' || owner || ''' and time>=to_date(''' || to_char(nvl(keeptime, min_keeptime), 'DD/MM/YYYY')|| ''',''DD/MM/YYYY'')';
    else
      w := owner || '.diary_uadmin';
      s := v_ins || table_name || ' t$(id,time,user_id,topic,text)
        select diary_id.nextval,time,user_id,''U'',
          substr(Subj_Id|| '': '' ||Obj_Type|| '' - '' ||Class_Id|| '', '' ||Obj_Id|| '' ('' ||Accessible|| '') '' ||Text,1,2000)
          from ' || owner || '.diary_uadmin where time>=to_date(''' || to_char(nvl(keeptime, min_keeptime), 'DD/MM/YYYY')|| ''',''DD/MM/YYYY'')';
    end if;
    begin
      n:=utils.execute_sql(s);
      commit;
    exception when others then
      rollback;
      n:=-1;
    end;
    utils.put_line('Converted ' || n || ' rows from ' || w || ' to ' || table_name);
    if n >= 0 and del then
      if drp then
        utils.execute_sql('ALTER TABLE DIARY_PARAM DROP CONSTRAINT FK_DIARY_PARAM_DIARY_ID','DROP FK_DIARY_PARAM_DIARY_ID',true);
        utils.execute_sql('ALTER TABLE DIARY DROP CONSTRAINT PK_DIARY_ID','DROP PK_DIARY_ID',true);
        utils.execute_sql('DROP INDEX PK_DIARY_ID',null,true);
      end if;
      n:=utils.execute_sql('delete from diary where owner=''' || owner || ''' and topic=''U''');
      commit;
      utils.put_line('Deleted ' || n || ' rows in ' || w);
    end if;
  end if;
end;
--
procedure diary_sessions(owner varchar2, old_version varchar2, del_data varchar2, keeptime date, start_date date, end_date date, restore_idxs boolean, drp in out boolean) is
  n integer;
  w varchar2(200);
  s varchar2(2000);
  v_ins      varchar2(200);
  table_name varchar2(200);
  table_created boolean;
  cnv varchar2(1);
  del boolean;
begin
  check_version(old_version, del_data, cnv, del);
  convert_table(owner, utils.DIARY5, start_date, end_date, table_name, table_created);
  if cnv in ('1','2') then
    if drp is null then
      n := utils.execute_sql('begin select count(1) into :RES from diary where owner=''' || owner || ''' and rownum<=100000; end;',null,true,'0');
      drp := (n >= 100000);
    end if;
    if drp and not nvl(table_created, false) then
        utils.drop_indexes(owner, utils.DIARY5);
    end if;
    get_insert_header(v_ins);
    if cnv='1' then
      w := 'diary';
      s := v_ins || table_name || ' t$(id,time,audsid,user_id,topic,code,text)
        select id,time,
          decode(instr(text,''ORA-''),0,decode(sign(ascii(substr(text,instr(text,'' '',-1)+1))-58),-1,substr(text,instr(text,'' '',-1)+1),''0''),''0''),
          decode(substr(text,10,1),'':'',nvl(substr(text,instr(text,'' - '',1,2)+3,instr(text,'') '')-instr(text,'' - '',1,2)-3),user_id),user_id),
          decode(substr(text,10,1),'':'',''I'',''J''),
          decode(instr(text,''ORA-''),0,substr(upper(rtrim(rtrim(substr(text,instr(text,'') '')+2,instr(text,'' '',instr(text,'') '')+2,2)-instr(text,'') '')-2),'' :''),'' -'')),1,30),''ERROR''),
          nvl(decode(substr(text,10,1),'':'',substr(text,12,instr(text,'' : '',-1)-12),substr(text,11,instr(text,'' - '',-1)-11)),substr(text,11))
        from diary where owner=''' || owner || ''' and topic=''S'' and text like ''LOCK_INFO%''';
    else
      w := owner || '.diary';
      s := v_ins || table_name || ' t$(id,time,user_id,audsid,topic,code,text)
        select diary_id.nextval,time,user_id,
          decode(instr(text,''ORA-''),0,decode(sign(ascii(substr(text,instr(text,'' '',-1)+1))-58),-1,substr(text,instr(text,'' '',-1)+1),''0''),''0''),
          decode(substr(text,10,1),'':'',''I'',''J''),
          decode(instr(text,''ORA-''),0,substr(upper(rtrim(rtrim(substr(text,instr(text,'') '')+2,instr(text,'' '',instr(text,'') '')+2,2)-instr(text,'') '')-2),'' :''),'' -'')),1,30),''ERROR''),
          nvl(decode(substr(text,10,1),'':'',substr(text,12,instr(text,'' : '',-1)-12),substr(text,11,instr(text,'' - '',-1)-11)),substr(text,11))
        from ' || owner || '.diary where topic=''S'' and text like ''LOCK_INFO%''';
    end if;
    begin
      n:=utils.execute_sql(s);
      commit;
    exception when others then
      rollback;
      n:=-1;
    end;
    utils.put_line('Converted ' || n || ' rows from ' || w || ' to ' || table_name);
    if restore_idxs then
      utils.create_indexes(owner, utils.DIARY5);
    end if;
    if n >= 0 and del then
      if drp then
        utils.execute_sql('ALTER TABLE DIARY_PARAM DROP CONSTRAINT FK_DIARY_PARAM_DIARY_ID','DROP FK_DIARY_PARAM_DIARY_ID',true);
        utils.execute_sql('ALTER TABLE DIARY DROP CONSTRAINT PK_DIARY_ID','DROP PK_DIARY_ID',true);
        utils.execute_sql('DROP INDEX PK_DIARY_ID',null,true);
      end if;
      n:=utils.execute_sql('delete from diary where owner=''' || owner || ''' and topic=''S'' and text like ''LOCK_INFO%''');
      commit;
      utils.put_line('Deleted ' || n || ' rows in ' || w);
    end if;
  elsif cnv = '3' then
    if restore_idxs then
      utils.create_indexes(owner, utils.DIARY5);
    end if;
  end if;
end;
--
procedure diary_methods(owner varchar2, old_version varchar2, del_data varchar2, keeptime date, start_date date, end_date date, restore_idxs boolean, drp in out boolean) is
  n integer;
  c varchar2(30);
  w varchar2(200);
  s varchar2(2000);
  v_ins      varchar2(200);
  table_name varchar2(200);
  table_created boolean;
  cnv varchar2(1);
  del boolean;
begin
  check_version(old_version, del_data, cnv, del);
  convert_table(owner, utils.DIARY4, start_date, end_date, table_name, table_created);
  if cnv in ('1','2') then
    if drp is null then
      n := utils.execute_sql('begin select count(1) into :RES from diary where owner=''' || owner || ''' and rownum<=100000; end;',null,true,'0');
      drp := (n >= 100000);
    end if;
    if drp and not nvl(table_created, false) then
      utils.drop_indexes(owner, utils.DIARY4);
    end if;
    if cnv='1' then
      c := 'id';
      w := 'diary';
      s := w || ' where owner=''' || owner || ''' and';
    else
      c := 'diary_id.nextval';
      w := owner || '.diary';
      s := w || ' where';
    end if;
    get_insert_header(v_ins);
    s := v_ins || table_name || ' t$(id,time,audsid,user_id,topic,code,text)
      select ' || c || ',time,
        substr(text,instr(text,''('')+1,instr(text,'')'')-instr(text,''('')-1),
        user_id|| ''.'' ||substr(text,instr(text,'' - '')+3,instr(text,''('')-instr(text,'' - '')-3),
        decode(substr(text,1,4),''CRIT'',''C'',''M''),
        substr(text,instr(text,'':'')+2,instr(text,'':'',1,2)-instr(text,'':'')-2),
        decode(instr(text,''DROP:''),0,decode(instr(text,''ERROR:''),0,''COMPILE'',''ERROR''),''DROP'')||substr(text,instr(text,'':'',1,2),instr(text,'' - '')-instr(text,'':'',1,2))||substr(text,instr(text,'')'')+1)
      from ' || s || ' topic=''S'' and (text like ''GENERATE%'' or text like ''DROP%'' or text like ''CRITERIA%'')';
    begin
      n:=utils.execute_sql(s);
      commit;
    exception when others then
      rollback;
      n:=-1;
    end;
    utils.put_line('Converted ' || n || ' rows from ' || w || ' to ' || table_name);
    if restore_idxs then
      utils.create_indexes(owner, utils.DIARY4);
    end if;
    if n >= 0 and del then
      if drp then
        utils.execute_sql('ALTER TABLE DIARY_PARAM DROP CONSTRAINT FK_DIARY_PARAM_DIARY_ID','DROP FK_DIARY_PARAM_DIARY_ID',true);
        utils.execute_sql('ALTER TABLE DIARY DROP CONSTRAINT PK_DIARY_ID','DROP PK_DIARY_ID',true);
        utils.execute_sql('DROP INDEX PK_DIARY_ID',null,true);
      end if;
      n:=utils.execute_sql(
      'delete from diary where owner=''' || owner || ''' and topic=''S''
        and (text like ''GENERATE%'' or text like ''DROP%'' or text like ''CRITERIA%'')');
      commit;
      utils.put_line('Deleted ' || n || ' rows in ' || w);
    end if;
  elsif cnv = '3' then
    if restore_idxs then
      utils.create_indexes(owner, utils.DIARY4);
    end if;
  end if;
end;
--
procedure diary_storage(owner varchar2, old_version varchar2, del_data varchar2, keeptime date, start_date date, end_date date, restore_idxs boolean, drp in out boolean) is
  n integer;
  s varchar2(2000);
  v_ins      varchar2(200);
  table_name varchar2(200);
  table_created boolean;
  cnv varchar2(1);
  del boolean;
begin
  check_version(old_version, del_data, cnv, del);
  convert_table(owner, utils.DIARY4, start_date, end_date, table_name, table_created);
  if cnv='1' then
    if drp is null then
      n := utils.execute_sql('begin select count(1) into :RES from diary where owner=''' || owner || ''' and rownum<=100000; end;',null,true,'0');
      drp := (n >= 100000);
    end if;
    if drp and not nvl(table_created, false) then
      utils.drop_indexes(owner, utils.DIARY4);
    end if;
    get_insert_header(v_ins);
    s := v_ins || table_name || ' t$(id,time,audsid,user_id,topic,code,text)
      select id,time,
        substr(text,instr(text,''('',-1)+1,instr(text,'')'',-1)-instr(text,''('',-1)-1),
        user_id|| ''.'' ||substr(text,instr(text,'' - '',-1)+3,instr(text,''('',-1)-instr(text,'' - '',-1)-3),
        ''B'',
        substr(text,instr(text,'':'')+2,instr(text,'':'',1,2)-instr(text,'':'')-2),
        decode(instr(text,'': RECONCILE_CLASS_TABLE - ''),0,decode(instr(text,'': DELETE_CLASS - ''),0,decode(instr(text,'': DELETE_CLASS_ENTIRELY - ''),0,decode(instr(text,'': Renamed [''),0,
        ''UPDATED'' ||substr(text,instr(text,'':'',1,2),instr(text,'' - '',-1)-instr(text,'':'',1,2)),''RENAMED '' ||substr(text,instr(text,''[''),instr(text,'']'')-instr(text,''['')+1)|| '':''),''DROPPED:''),''REMOVED:''),''REBUILDED:'')
      from diary where owner=''' || owner || ''' and topic=''S'' and text like ''STORAGE: %''';
    begin
      n:=utils.execute_sql(s);
      commit;
    exception when others then
      rollback;
      n:=-1;
    end;
    utils.put_line('Converted ' || n || ' rows from diary to ' || table_name);
    if restore_idxs then
      utils.create_indexes(owner, utils.DIARY4);
    end if;
    if n >= 0 and del then
      if drp then
        utils.execute_sql('ALTER TABLE DIARY_PARAM DROP CONSTRAINT FK_DIARY_PARAM_DIARY_ID','DROP FK_DIARY_PARAM_DIARY_ID',true);
        utils.execute_sql('ALTER TABLE DIARY DROP CONSTRAINT PK_DIARY_ID','DROP PK_DIARY_ID',true);
        utils.execute_sql('DROP INDEX PK_DIARY_ID',null,true);
      end if;
      n:=utils.execute_sql('delete from diary where owner=''' || owner || ''' and topic=''S'' and text like ''STORAGE: %''');
      commit;
      utils.put_line('Deleted ' || n || ' rows in diary');
    end if;
  elsif cnv in ('2', '3') then
    if restore_idxs then
      utils.create_indexes(owner, utils.DIARY4);
    end if;
  end if;
end;
--
procedure diary_attrs(owner varchar2, old_version varchar2, del_data varchar2, keeptime date, start_date date, end_date date, restore_idxs boolean, drp in out boolean) is
  n integer;
  s varchar2(2000);
  v_ins      varchar2(200);
  table_name varchar2(200);
  table_created boolean;
  cnv varchar2(1);
  del boolean;
begin
  check_version(old_version, del_data, cnv, del);
  convert_table(owner, utils.DIARY4, start_date, end_date, table_name, table_created);
  if cnv='1' then
    if drp is null then
      n := utils.execute_sql('begin select count(1) into :RES from diary where owner=''' || owner || ''' and rownum<=100000; end;',null,true,'0');
      drp := (n >= 100000);
    end if;
    if drp and not nvl(table_created, false) then
      utils.drop_indexes(owner, utils.DIARY4);
    end if;
    get_insert_header(v_ins);
    s := v_ins || table_name || ' t$(id,time,audsid,user_id,topic,code,text)
    select id,time,
      substr(text,instr(text,''.'',-1)+1),
      user_id|| ''.'' ||substr(text,instr(text,''.'',-1,2)+1,instr(text,''.'',-1)-instr(text,''.'',-1,2)-1),
      decode(substr(text,1,3),''PAR'',''R'',''VAR'',''V'',''STA'',''S'',''TRA'',''T'',''A''),
      decode(substr(text,2,1),''A'',substr(text,instr(text,'':'')+2,instr(text,'':'',1,2)-instr(text,'':'')-2),substr(text,instr(text,'':'')+2,instr(text,''.'')-instr(text,'':'')-2)),
      substr(text,instr(text,'' '')+1,instr(text,'':'')-instr(text,'' '')+1)||decode(substr(text,2,1),''A'',
      substr(text,instr(text,'':'',1,2)+2,instr(text,'' : '',-1)-instr(text,'':'',1,2)-2),substr(text,instr(text,''.'')+1,instr(text,'' : '',-1)-instr(text,''.'')-1))
    from diary where owner=''' || owner || ''' and topic=''S'' and (text like ''PARAMETER %'' or text like ''VARIABLE %'' or text like ''STATE %'' or text like ''TRANSITION %'' or text like ''ATTRIBUTE %'')';
    begin
      n:=utils.execute_sql(s);
      commit;
    exception when others then
      rollback;
      n:=-1;
    end;
    utils.put_line('Converted ' || n || ' rows from diary to ' || table_name);
    if restore_idxs then
      utils.create_indexes(owner, utils.DIARY4);
    end if;
    if n >= 0 and del then
      if drp then
        utils.execute_sql('ALTER TABLE DIARY_PARAM DROP CONSTRAINT FK_DIARY_PARAM_DIARY_ID','DROP FK_DIARY_PARAM_DIARY_ID',true);
        utils.execute_sql('ALTER TABLE DIARY DROP CONSTRAINT PK_DIARY_ID','DROP PK_DIARY_ID',true);
        utils.execute_sql('DROP INDEX PK_DIARY_ID',null,true);
      end if;
      n:=utils.execute_sql(
      'delete from diary where owner=''' || owner || ''' and topic=''S''
        and (text like ''PARAMETER %'' or text like ''VARIABLE %'' or text like ''STATE %'' or text like ''TRANSITION %'' or text like ''ATTRIBUTE %'')');
      commit;
      utils.put_line('Deleted ' || n || ' rows in diary');
    end if;
  elsif cnv in ('2', '3') then
    if restore_idxs then
      utils.create_indexes(owner, utils.DIARY4);
    end if;
  end if;
end;
--
procedure diary_UNKNOWN(owner varchar2, old_version varchar2, del_data varchar2, keeptime date, start_date date, end_date date, restore_idxs boolean) is
  n integer;
  s varchar2(2000);
  v_ins      varchar2(200);
  table_name varchar2(200);
  table_created boolean;
  cnv varchar2(1);
  del boolean;
begin
  check_version(old_version, del_data, cnv, del);
  convert_table(owner, utils.DIARY4, start_date, end_date, table_name, table_created);
  if cnv='2' then
    get_insert_header(v_ins);
    s := v_ins || table_name || ' t$(id,time,user_id,topic,code,text)
      select diary_id.nextval,modified,action_user,''A'',class_id,
        ''DELETED: '' ||attr_id|| '' - '' ||name|| '' - '' ||self_class_id|| '' : '' ||action_module
      from ' || owner || '.class_attrs_history';
    begin
      n:=utils.execute_sql(s);
      commit;
    exception when others then
      rollback;
      n:=-1;
    end;
    utils.put_line('Converted ' || n || ' rows from ' || owner || '.class_attrs_history to ' || table_name);
    s := v_ins || table_name || ' t$(id,time,user_id,topic,code,text)
      select diary_id.nextval,modified,action_user,''R'',method_id,
        ''DELETED: '' ||short_name|| '' [UNKNOWN] - '' ||name|| '' : '' ||action_module
      from ' || owner || '.method_params_history';
    begin
      n:=utils.execute_sql(s);
      commit;
    exception when others then
      rollback;
      n:=-1;
    end;
    utils.put_line('Converted ' || n || ' rows from ' || owner || '.method_params_history to ' || table_name);
  end if;
  if restore_idxs then
    utils.create_indexes(owner, utils.DIARY4);
  end if;
end;
--
procedure diary_info(owner varchar2, old_version varchar2, del_data varchar2, keeptime date, start_date date, end_date date, restore_idxs boolean, drp in out boolean) is
  n integer;
  c varchar2(30);
  w varchar2(200);
  s varchar2(2000);
  v_ins      varchar2(200);
  table_name varchar2(200);
  table_created boolean;
  cnv varchar2(1);
  del boolean;
begin
  check_version(old_version, del_data, cnv, del);
  convert_table(owner, utils.DIARY4, start_date, end_date, table_name, table_created);
  if cnv in ('1','2') then
    if drp is null then
      n := utils.execute_sql('begin select count(1) into :RES from diary where owner=''' || owner || ''' and rownum<=100000; end;',null,true,'0');
      drp := (n >= 100000);
    end if;
    if drp and not nvl(table_created, false) then
      utils.drop_indexes(owner, utils.DIARY4);
    end if;
    if cnv='1' then
      c := 'id';
      w := 'diary';
      s := w || ' where owner=''' || owner || ''' and';
    else
      c := 'diary_id.nextval';
      w := owner || '.diary';
      s := w || ' where';
    end if;
    get_insert_header(v_ins);
    s := v_ins || table_name || ' t$(id,time,audsid,user_id,topic,code,text)
      select ' || c || ',time,
        substr(text,instr(text,''('')+1,instr(text,'')'')-instr(text,''('')-1),
        user_id|| ''.'' ||substr(text,instr(text,'': '')+2,instr(text,''('')-instr(text,'': '')-3),
        ''G'',
        upper(substr(text,instr(text,'')'')+2,instr(text,'':'',1,2)-instr(text,'')'')-2)),
        substr(text,instr(text,''('',-1)+1,instr(text,'')'',-1)-instr(text,''('',-1)-1)
      from ' || s || ' topic=''S'' and text like ''SYSINFO: %''';
    begin
      n:=utils.execute_sql(s);
      commit;
    exception when others then
      rollback;
      n:=-1;
    end;
    utils.put_line('Converted ' || n || ' rows from ' || w || ' to ' || table_name);
    if restore_idxs then
      utils.create_indexes(owner, utils.DIARY4);
    end if;
    if n >= 0 and del then
      if drp then
        utils.execute_sql('ALTER TABLE DIARY_PARAM DROP CONSTRAINT FK_DIARY_PARAM_DIARY_ID','DROP FK_DIARY_PARAM_DIARY_ID',true);
        utils.execute_sql('ALTER TABLE DIARY DROP CONSTRAINT PK_DIARY_ID','DROP PK_DIARY_ID',true);
        utils.execute_sql('DROP INDEX PK_DIARY_ID',null,true);
      end if;
      n:=utils.execute_sql('delete from diary where owner=''' || owner || ''' and topic=''S'' and text like ''SYSINFO: %''');
      commit;
      utils.put_line('Deleted ' || n || ' rows in ' || w);
    end if;
  elsif cnv = '3' then
    if restore_idxs then
      utils.create_indexes(owner, utils.DIARY4);
    end if;
  end if;
end;
--
procedure diary_others(owner varchar2, old_version varchar2, del_data varchar2, keeptime date, start_date date, end_date date, restore_idxs boolean, drp in out boolean) is
  n integer;
  c varchar2(30);
  w varchar2(200);
  s varchar2(2000);
  v_ins      varchar2(200);
  table_name varchar2(200);
  table_created boolean;
  cnv varchar2(1);
  del boolean;
begin
  check_version(old_version, del_data, cnv, del);
  convert_table(owner, utils.DIARY4, start_date, end_date, table_name, table_created);
  if cnv in ('1','2') then
    if drp is null then
      n := utils.execute_sql('begin select count(1) into :RES from diary where owner=''' || owner || ''' and rownum<=100000; end;',null,true,'0');
      drp := (n >= 100000);
    end if;

    if drp and not nvl(table_created, false) then
      utils.drop_indexes(owner, utils.DIARY4);
    end if;
    if cnv='1' then
      c := 'id';
      w := 'diary';
      s := w || ' where owner=''' || owner || ''' and';
    else
      c := 'diary_id.nextval';
      w := owner || '.diary';
      s := w || ' where';
    end if;
    get_insert_header(v_ins);
    s := s|| ' not (text like ''LOCK_INFO%'' or text like ''SYSINFO: %'' or text like ''STORAGE: %''
        or text like ''GENERATE%'' or text like ''DROP%'' or text like ''CRITERIA%'' or text like ''ATTRIBUTE %''
        or text like ''PARAMETER %'' or text like ''VARIABLE %'' or text like ''STATE %'' or text like ''TRANSITION %'') and';
    s := v_ins || table_name || ' t$(id,time,user_id,topic,code,text)
      select ' || c || ',time,user_id,''O'',ltrim(rtrim(upper(substr(text,1,instr(text,'':'')-1)))),ltrim(substr(text,instr(text,'':'')+1))
      from ' || s || ' topic=''S''';
    begin
      n:=utils.execute_sql(s);
      commit;
    exception when others then
      rollback;
      n:=-1;
    end;
    utils.put_line('Converted ' || n || ' rows from ' || w || ' to ' || table_name);
    if n >= 0 and del then
      if drp then
        utils.execute_sql('ALTER TABLE DIARY_PARAM DROP CONSTRAINT FK_DIARY_PARAM_DIARY_ID','DROP FK_DIARY_PARAM_DIARY_ID',true);
        utils.execute_sql('ALTER TABLE DIARY DROP CONSTRAINT PK_DIARY_ID','DROP PK_DIARY_ID',true);
        utils.execute_sql('DROP INDEX PK_DIARY_ID',null,true);
      end if;
      n:=utils.execute_sql('delete from diary where owner=''' || owner || ''' and topic=''S''');
      commit;
      utils.put_line('Deleted ' || n || ' rows in diary.');
    end if;
    if restore_idxs then
      utils.create_indexes(owner, utils.DIARY4);
    end if;
  elsif cnv = '3' then
    if restore_idxs then
      utils.create_indexes(owner, utils.DIARY4);
    end if;
  end if;
end;
--
procedure object_collection_history(owner varchar2, old_version varchar2, del_data varchar2, keeptime date, start_date date, end_date date, restore_idxs boolean) is
  n integer;
  c varchar2(30);
  w varchar2(200);
  s varchar2(2000);
  table_name varchar2(200);
  table_created boolean;
  cnv varchar2(1);
  del boolean;
begin
  check_version(old_version, del_data, cnv, del);
  convert_table(owner, utils.OCH, start_date, end_date, table_name, table_created,
    'id, time, obj_id, collection_id, audsid, user_id');
  if restore_idxs then
    utils.create_indexes(owner, utils.OCH);
  end if;
end;
--
procedure edoc_history(owner varchar2, old_version varchar2, del_data varchar2, keeptime date, start_date date, end_date date, restore_idxs boolean) is
  n integer;
  c varchar2(30);
  w varchar2(200);
  s varchar2(2000);
  table_name varchar2(200);
  table_created boolean;
  cnv varchar2(1);
  del boolean;
begin
  check_version(old_version, del_data, cnv, del);
  convert_table(owner, utils.EDH, start_date, end_date, table_name, table_created);
  if restore_idxs then
    utils.create_indexes(owner, utils.EDH);
  end if;
end;
--
procedure system_events(owner varchar2, old_version varchar2, del_data varchar2, keeptime date, start_date date, end_date date, restore_idxs boolean) is
  n integer;
  c varchar2(30);
  w varchar2(200);
  s varchar2(2000);
  table_name varchar2(200);
  table_created boolean;
  cnv varchar2(1);
  del boolean;
begin
  check_version(old_version, del_data, cnv, del);
  convert_table(owner, utils.DIARY6, start_date, end_date, table_name, table_created);
  if restore_idxs then
    utils.create_indexes(owner, utils.DIARY6);
  end if;
end;
--
end;
/
show err package body conv

