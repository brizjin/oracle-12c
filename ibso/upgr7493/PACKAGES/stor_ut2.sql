prompt storage_utils body
create or replace package body
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/stor_ut2.sql $
 *  $Author: vzhukov $
 *  $Revision: 124343 $
 *  $Date:: 2016-10-13 16:57:33 #$
 */
storage_utils is
--
LF constant varchar2(1) := chr(10);
TB constant varchar2(1) := chr(9);
type ref_cursor is ref cursor;
--
block_size  pls_integer;
tab_tspace  varchar2(30);
idx_tspace  varchar2(30);
tmp_tspace  varchar2(30);
obj_option  varchar2(100);
prc_estim   number;
prt_compr   boolean;
--
procedure WS(msg_str varchar2) is  -- @METAGS WS
begin
  if verbose then
    stdio.put_line_pipe(to_char(sysdate,'HH24:MI:SS') || ' ' || msg_str,pipe_name,0,64000,false);
  end if;
end;
--
function execute_sql ( p_sql_block clob, p_comment varchar2 default null,
                       p_silent boolean default false, p_owner varchar2 default null ) return number is  -- @METAGS execute_sql
    n number;
	len_block number := 32000; -- размер блока для вывода в пайпу
begin
    if not p_comment is null then
        WS(p_comment);
    end if;
    if p_owner is null or p_owner=inst_info.owner then
      execute immediate p_sql_block;
      n := sql%rowcount;
    else
      execute immediate 'begin '||p_owner||'.admin_mgr.execute_sql('''||
        replace(p_sql_block,'''','''''')||'''); :n:=sql%rowcount; end;'
        using out n;
    end if;
    if p_silent is null and not p_comment is null  then
        WS(p_comment||' - OK.');
    end if;
    return n;
  exception when others then
    if not nvl(p_silent,false) then
	  -- Если размер SQL-блока >len_block, выведем его в пайпу "кусочками"
	  for i in 0..trunc(length(p_sql_block)/len_block) loop
		WS(substr(p_sql_block,i*len_block+1,(i+1)*len_block));
	  end loop;
	  WS(SQLERRM);
    end if;
    if sqlcode in(-6508,-4061) then
      raise;
    end if;
    if p_silent is null then
      if sqlcode in(-28,-1033,-1089,-3113) then
        raise;
      end if;
    elsif not p_silent and sqlcode<>-24344 then
      raise;
    end if;
    return 0;
end execute_sql;
--
procedure execute_sql( p_sql_block clob, p_comment varchar2 default null,
                       p_silent boolean default false, p_owner varchar2 default null ) is  -- @METAGS execute_sql
    n number;
begin
    n := execute_sql(p_sql_block,p_comment,p_silent,p_owner);
end execute_sql;
--
procedure drop_column(p_table varchar2,p_column varchar2,p_cascade boolean,p_silent boolean) is
  v_add varchar2(30);
  n number;
begin
  if p_cascade then
    v_add := ' CASCADE CONSTRAINTS';
  end if;
  n := execute_sql('ALTER TABLE '||p_table||' DROP COLUMN '||p_column||v_add,
    message.gettext('EXEC','DELETING_COLUMN',p_column,p_table),false,null);
exception when others then
  if sqlcode=-39726 then
    n := execute_sql('ALTER TABLE '||p_table||' SET UNUSED COLUMN '||p_column||v_add,
      message.gettext('EXEC','DELETING_COLUMN',p_column||' (SET UNUSED)',p_table),p_silent,null);
  elsif p_silent is null then
    if sqlcode in(-28,-1033,-1089,-3113) then
      raise;
    end if;
  elsif not p_silent then
    raise;
  end if;
end;
--
function hash(p_text    varchar2) return pls_integer is
begin
    return dbms_utility.get_hash_value(p_text,0,2147483647);
end;
--
procedure put_text_buf(p_text varchar2,
                       p_buf in out nocopy dbms_sql.varchar2s,
                       p_end boolean := true) is
begin
    lib.put_buf(p_text,p_buf,p_end);
end;
--
function texts_equal(p_buf1 dbms_sql.varchar2s,
                     p_buf2 dbms_sql.varchar2s) return boolean is
begin
    return lib.equal_buf(p_buf1,p_buf2);
end;
--
function build_parallel return pls_integer is
  v_paral varchar2(30);
  paral pls_integer;
begin
  v_paral := upper(nvl(rtl.setting('STORAGE_FORCE_PARALLEL'),'0'));
  if substr(v_paral,1,1)='N' then
    paral := 0;
  elsif substr(v_paral,1,1)='Y' then
    paral := 1;
  else
    paral := v_paral;
    if paral<1 then
      paral := 0;
    end if;
  end if;
  return paral;
exception when others then
  return 0;
end;
--
function build_nologging return varchar2 is
begin
  if upper(substr(nvl(rtl.setting('STORAGE_FORCE_NOLOGGING'),'1'),1,1)) in ('1','Y') then
    return ' NOLOGGING';
  end if;
  return null;
end;
--
function direct_insert_hint return varchar2 is
  v_ins varchar2(200);
begin
  v_ins := nvl(rtl.setting('STORAGE_INSERT_HINT'),'APPEND');
  if v_ins='NOHINT' then
    return null;
  end if;
  return ' /*+ '||v_ins||' */';
end;
--
function build_online return varchar2 is
begin
  if upper(substr(nvl(rtl.setting('STORAGE_FORCE_ONLINE'),'0'),1,1)) in ('1','Y') then
    return ' ONLINE';
  end if;
  return null;
end;
--
function build_novalidate return varchar2 is
begin
  if upper(substr(nvl(rtl.setting('STORAGE_FORCE_NOVALIDATE'),'0'),1,1)) in ('1','Y') then
    return ' NOVALIDATE';
  end if;
  return null;
end;
--
function build_ref_constraint_name(p_table_name varchar2, p_postfix varchar2) return varchar2 is
v_constraint_name varchar2(30);
begin
  --Z#FK_ Z#PLATFORM12907_CH _REF 6
  --5 (Z#FK_) + 18 (Z#имя ТБП) + 4 (_REF) = 27 остается 3 на доп идентификатор 
  v_constraint_name := 'Z#FK_' || p_table_name ||'_REF' || p_postfix;
  return v_constraint_name;
end;
--
function build_deferrable return varchar2 is
begin
  if upper(substr(nvl(rtl.setting('STORAGE_FORCE_DEFERRABLE'),'0'),1,1)) in ('1','Y') then
    return ' DEFERRABLE';
  end if;
  return null;
end;
-- PLATFORM-3493 создание ограничений целостности вместе с индексами при партификации таблицы
function build_constr_with_index return boolean is
begin
  return upper(substr(nvl(rtl.setting('STORAGE_CONSTR_WITH_INDEX'),'0'),1,1)) in ('1','Y');
end;
--
procedure execute_sql(p_sql_block dbms_sql.varchar2s, p_ins_nl boolean := false,
                      p_comment varchar2 := null, p_silent boolean := false) is
    c   number;
    i1  pls_integer := p_sql_block.first;
    i2  pls_integer := p_sql_block.last;
begin
    if not p_comment is null then
        WS(p_comment);
    end if;
    if not i1 is null then
        c := dbms_sql.open_cursor;
        dbms_sql.parse(c, p_sql_block, i1, i2, p_ins_nl, dbms_sql.native);
        dbms_sql.close_cursor(c);
    end if;
    if p_silent is null and not p_comment is null  then
        WS(p_comment||' - OK.');
    end if;
exception when others then
    if dbms_sql.is_open(c) then
        dbms_sql.close_cursor(c);
    end if;
    if not nvl(p_silent,false) then
      i2 := least(i2,i1+50);
      while i1<=i2 loop
        WS(p_sql_block(i1));
        i1 := p_sql_block.next(i1);
      end loop;
      WS(SQLERRM);
    end if;
    if sqlcode in(-6508,-4061) then
      raise;
    end if;
    if p_silent is null then
      if sqlcode in(-28,-1033,-1089,-3113) then
        raise;
      end if;
    elsif not p_silent and sqlcode<>-24344 then
      raise;
    end if;
end execute_sql;
--Поиск/удаление мусора в БД - потеряные коллекции и т.д.
procedure lost_collections(act_ varchar2 default 'SHOW',p_verbose boolean default true,p_pipe_name varchar2 default 'DEBUG',p_target varchar2 default null) is
coll_id number;
id_   varchar2(128);
arrs_ ref_cursor;
elem_ ref_cursor;
cur_  number;
cnt_  number;
qc  varchar2(32767);
p   varchar2(300);
tbl varchar2(300);
cls varchar2(30) := nvl(p_target,'%');
del boolean;
chk boolean;
skp boolean;
b   boolean;
cnt number;
cnt_el number;
cnt_del_ok number;
cnt_er number;
cnt_del number;
cnt_all number := 0;
cnt_all_el number := 0;
cnt_errs number := 0;
cnt_all_col number := 0;
cnt_all_del number := 0;
begin
    verbose := p_verbose;
    pipe_name := p_pipe_name;
    ws(message.gettext('KRNL', 'SEARCHING_LOST_COLLECTIONS'));
    --поиск/удаление потеряных коллекций
    p := upper(ltrim(rtrim(act_)));
    del := p like 'DEL%';
    skp := instr(p,'SKIP')>0;
    if del then
      cur_:= dbms_sql.open_cursor;
    end if;
    for cs in (select /*+ RULE */ c.id,c.name,c.target_class_id,
                      ct.table_name,ct.owner,ct.param_group,ct.current_key
                 from dba_tab_columns utc,class_tables ct,classes c,classes c2
                where c.base_class_id = 'COLLECTION'
                  and c.target_class_id like cls
                  and c2.id = c.target_class_id
                  and c2.temp_type is null
                  and ct.class_id = c2.id
                  and utc.table_name = ct.table_name
                  and utc.owner = nvl(ct.owner,inst_info.gowner)
                  and utc.column_name= 'COLLECTION_ID'
    ) loop
        qc := null; cnt := 0; cnt_el := 0; cnt_er := 0; cnt_del := 0; cnt_del_ok:= 0;
        for t in (select ct.table_name, ct.owner, ct.param_group, ct.current_key, ctc.column_name
                    from class_tables ct, class_tab_columns ctc, classes c, class_relations cr
                    where ctc.class_id = ct.class_id
                        and c.id = ct.class_id
                        and nvl(c.kernel,'0') <> '1'
                        and ctc.deleted = '0'
                        and ctc.map_style is null
                        and ctc.base_class_id = 'COLLECTION'
                        and ctc.target_class_id = cr.child_id
                        and cr.parent_id = cs.target_class_id
                        and exists (select /*+ NO_UNNEST */ 1 from dba_tables ut where ut.table_name=ct.table_name and ut.owner=nvl(ct.owner,inst_info.gowner) and ut.temporary='N')
        ) loop
            tbl:=nvl(t.owner,inst_info.gowner)||'.'||t.table_name; p:=null;
            if t.param_group like 'PART%' then
                if t.param_group='PARTVIEW' then
                    tbl := t.table_name||'#PRT';
                end if;
                if t.current_key>0 then
                    p := ' and c.key>='||t.current_key;
                end if;
            end if;
            qc := qc||LF||'and not exists (select 1 from '||tbl||' c where c.'||t.column_name||'=t.collection_id'||p||')';
        end loop;
        --
        chk:=qc is null;
        tbl:=cs.table_name; p:=null;
        if cs.param_group='PARTITION' then
            if Storage_Mgr.Prt_Actual then
                tbl := tbl||' partition('||tbl||'#0)';
                p := 'key=1000 and ';
            elsif cs.current_key>0 then
                p := 'key>='||cs.current_key||' and ';
            end if;
        end if;
        tbl:= nvl(cs.owner,inst_info.gowner)||'.'||tbl||' t where '||p;
        qc := 'select collection_id,count(1) cnt'||LF||
              'from '||tbl||'collection_id<>0'||qc||LF||
              'group by collection_id';
        --ws(LF || qc);
        --
        if del then
            dbms_sql.parse(cur_,'BEGIN '||class_mgr.interface_package(cs.target_class_id)||
                '.DELETE(:OBJ_ID); RTL.LOCK_CLEAR; END;',dbms_sql.native);
            p := 'SELECT ID FROM '||upper(tbl)||'COLLECTION_ID=:COLL';
        else
            p := null;
        end if;
        loop begin
          open arrs_ for qc;
          loop
            fetch arrs_ into coll_id,cnt_;
            exit when arrs_%notfound;
            --WS(coll_id);
            cnt := cnt + 1;
            cnt_el := cnt_el + cnt_;
            if del then --Убиваем коллекции
                b := true;
                open elem_ for p using coll_id;
                loop
                    fetch elem_ into id_;
                    exit when elem_%notfound;
                    --WS('     ' || id_);
                    begin
                        dbms_sql.bind_variable(cur_,':OBJ_ID',id_,128);
                        cnt_ := dbms_sql.execute(cur_);
                        commit;
                        cnt_del := cnt_del + 1;
                    exception when others then
                        if sqlcode in (-6508,-4061) then raise; end if;
                        b := false;
                        cnt_er := cnt_er + 1;
                        WS(message.gettext('KRNL', 'ERROR_WHILE_DELETING', id_, sqlerrm));
                        rollback;
                    end;
                end loop;
                close elem_;
                if b then
                  cnt_del_ok := cnt_del_ok + 1;
                end if;
            end if;
          end loop;
          close arrs_;
          exit;
        exception when rtl.SNAPSHOT_TOO_OLD then
          WS( LF||qc||LF||p||LF||sqlerrm );
          if arrs_%isopen then
              close arrs_;
          end if;
          if elem_%isopen then
              close elem_;
          end if;
        end; end loop;
        --
        if cnt > 0 then
            if chk then
              cnt_all_col := cnt;
            elsif skp then
              cnt_all_col := 0;
            else
              execute immediate 'select count(distinct collection_id) from '||tbl||'collection_id<>0'
                 into cnt_all_col;
              cnt_all_col := cnt_all_col+cnt_del_ok;
            end if;
            ws(LF||message.gettext('KRNL', 'CLASS_COLLECTIONS_REPORT',
                cs.name, cs.id, to_char(cnt_all_col), to_char(cnt),
                to_char(cnt_el), to_char(cnt_del), to_char(cnt_er)));
        end if;
        cnt_all := cnt_all + cnt;
        cnt_all_el := cnt_all_el + cnt_el;
        cnt_all_del:= cnt_all_del+ cnt_del;
        cnt_errs:= cnt_errs + cnt_er;
    end loop;
    if del then
      dbms_sql.close_cursor(cur_);
    end if;
    ws(message.gettext('KRNL', 'CLASS_COLLECTIONS_REPORT_TOTAL',
        to_char(cnt_all), to_char(cnt_all_el), to_char(cnt_all_del), to_char(cnt_errs)));
exception when others then
    if arrs_%isopen then
        close arrs_;
    end if;
    if elem_%isopen then
        close elem_;
    end if;
    if del and dbms_sql.is_open(cur_) then
        dbms_sql.close_cursor(cur_);
    end if;
    rollback;
    raise;
end;
-- Вычисление оптимальных параметров хранени
procedure optimal_params(p_size number, sp_init out varchar2 , sp_next out varchar2) is
begin
    select
  decode( sign(999*1024-p_size/1024), -1, '1000M',
    decode( sign(2048-p_size/1024), -1, to_char((trunc(p_size/(2048*1024))+1)*2)||'M',
      decode( sign(1024-p_size/1024), -1, '2M',
        decode( sign(512-p_size/1024), -1, '1M',
          decode( sign(256-p_size/1024), -1, '512K',
            decode( sign(128-p_size/1024), -1, '256K',
              decode( sign(64-p_size/1024) , -1, '128K',
                decode( sign(32-p_size/1024) , -1, '64K', '32K' )
                    )
                  )
                )
              )
            )
          )
        ),
  decode( sign(499*1024-p_size/4096), -1, '500M',
    decode( sign(2048-p_size/4096), -1, to_char((trunc(p_size/(2048*4096))+1)*2)||'M',
      decode( sign(1024-p_size/4096), -1, '2M',
        decode( sign(512-p_size/4096), -1, '1M',
          decode( sign(256-p_size/4096), -1, '512K',
            decode( sign(128-p_size/4096), -1, '256K',
              decode( sign(64-p_size/4096) , -1, '128K',
                decode( sign(32-p_size/4096) , -1, '64K', '32K' )
                    )
                  )
                )
              )
            )
          )
        )
    into sp_init, sp_next from dual;
exception when others then
    sp_init := '64K';
    sp_next := '64K';
end;
--
function  optimal_param (p_size number, p_initial varchar2 default null) return varchar2 is
    v_init  varchar2(100);
    v_next  varchar2(100);
begin
    optimal_params(p_size,v_init,v_next);
    if nvl(p_initial,'1')='1' then
        return v_init;
    end if;
    return v_next;
end;
--
procedure get_optimal_param(seg_name in varchar2, sp_init out varchar2 , sp_next out varchar2, p_owner varchar2 default null) is
    v_size  number;
    v_owner varchar2(30) := nvl(p_owner,inst_info.gowner);
begin
    select /*+ RULE */ sum(bytes) into v_size from dba_extents
     where segment_name=seg_name and owner=v_owner;
    optimal_params(v_size,sp_init,sp_next);
exception when others then
    sp_init := '100K';
    sp_next := '100K';
end;
--
function  optimal_group (p_size number,p_param varchar2 default null) return varchar2 is
    v_group varchar2(100) := 'SMALL';
    v_param varchar2(100) := nvl(p_param,'INITIAL');
    v_size  number := nvl(p_size,0);
begin
    for c in (select param_group,
                     to_number(decode(substr(upper(param_value),length(param_value)),
                     'K',to_number(substr(param_value,1,length(param_value)-1))*1024,
                     'M',to_number(substr(param_value,1,length(param_value)-1))*1048576,
                     'G',to_number(substr(param_value,1,length(param_value)-1))*1073741824,
                     param_value)) siz
                from storage_parameters
               where param_name=v_param
               order by siz)
    loop
        exit when v_size<c.siz;
        v_group := c.param_group;
    end loop;
    return v_group;
exception when others then
    return 'SMALL';
end;
--
procedure rebuild_refs is
begin
    null;
end;
--
procedure rebuild_col2obj is
begin
    storage_mgr.verbose := verbose;
    storage_mgr.pipe_name := pipe_name;
    storage_mgr.create_collection_views(true,true);
end;
--
procedure rebuild_fkeys is
begin
    --verbose := false;
    for t in (
        select ct.class_id, ct.table_name, c.parent_id
          from class_tables ct, classes c
         where c.id = ct.class_id
           and c.parent_id is not null
           and nvl(c.kernel,'0') <> '1'
           and c.temp_type is null
        )
    loop
        storage_mgr.create_fk_by_objid(t.class_id);
    end loop;
end;
--
procedure analyze_object(p_obj_name varchar2, p_subobject varchar2 default null,
                         p_option   varchar2 default null,
                         p_cascade  boolean  default null,
                         p_degree   pls_integer default null,
                         p_owner    varchar2 default null) is
    v_owner varchar2(30):= nvl(p_owner,inst_info.gowner);
    cursor analyze_list is
    select /*+ RULE */ OBJECT_NAME NAME, SUBOBJECT_NAME SUBNAME, substr(OBJECT_TYPE,1,5) TYPE
      from DBA_OBJECTS
     where OBJECT_NAME = p_obj_name and OWNER = v_owner
       and OBJECT_TYPE in ('TABLE','INDEX','TABLE PARTITION','INDEX PARTITION')
       and (p_subobject is null or SUBOBJECT_NAME=p_subobject)
     union all
    select /*+ RULE */ NULL NAME, TABLE_NAME SUBNAME, 'TABLE' TYPE
      from DBA_NESTED_TABLES
     where PARENT_TABLE_NAME = p_obj_name and OWNER = v_owner
       and (p_subobject is null or TABLE_NAME=p_subobject)
     order by 1 desc,2;
    v_option  varchar2(1000);
    v_mes   varchar2(1000);
    v_paral pls_integer := p_degree;
    v_sub   boolean := false;
    v_del   boolean := false;
    v_prc   number;
    i pls_integer;
begin
    v_option := upper(trim(p_option));
    if v_option is null then
      if obj_option is null then
        obj_option := nvl(storage_mgr.get_storage_parameter('GLOBAL','ANALYZE_OPTION'),'COMPUTE');
      end if;
      v_option := obj_option;
    end if;
    if v_paral is null then
      v_paral := build_parallel;
    end if;
    if v_option like 'ESTIMATE%' then
      if prc_estim is null then
        prc_estim := nvl(storage_mgr.get_storage_parameter('GLOBAL','ESTIMATE_PERCENT'),'10');
      end if;
      v_prc := prc_estim;
    elsif v_option like 'DELETE%' then
      v_del := true;
    end if;
    if v_paral>0 then
      if v_paral=1 then
        select value into v_paral from v$parameter where name='parallel_max_servers';
        v_paral := v_paral/2;
        if v_paral<2 then
          v_paral := null;
        end if;
      end if;
    else
      v_paral:= 1;
    end if;
    i := instr(v_option,'FOR ');
    for o in analyze_list loop
      if o.subname is null or o.name is null then
        exit when v_sub;
        if o.name is null then
          o.name := o.subname;
          o.subname := null;
        end if;
        v_mes := message.gettext('EXEC','ANALYZING',o.name,v_option);
      else
        v_sub := true;
        v_mes := message.gettext('EXEC', 'ANALYZING2',o.name,o.subname,v_option);
      end if;
      ws(v_mes);
      if v_del then
        if o.type = 'INDEX' then
          dbms_stats.delete_index_stats(v_owner,o.name,o.subname,cascade_parts=>nvl(p_cascade,true));
        else
          dbms_stats.delete_table_stats(v_owner,o.name,o.subname,cascade_parts=>nvl(p_cascade,true),
            cascade_columns=>nvl(p_cascade,true),cascade_indexes=>nvl(p_cascade,true));
        end if;
      elsif o.type = 'INDEX' then
        dbms_stats.gather_index_stats(v_owner,o.name,o.subname,v_prc);
      elsif i > 0 then
        dbms_stats.gather_table_stats(v_owner,o.name,o.subname,v_prc,
          method_opt=>substr(v_option,i),degree=>v_paral,cascade=>nvl(p_cascade,true));
      else
        dbms_stats.gather_table_stats(v_owner,o.name,o.subname,v_prc,degree=>v_paral,cascade=>nvl(p_cascade,true));
      end if;
      ws(v_mes||' - OK.');
    end loop;
end;
--
procedure drop_indexes(p_class_id varchar2,p_unused_only boolean,p_position pls_integer) is -- @METAGS drop_indexes
    drop_ boolean;
    n number;
    v_table varchar2(30);
    v_drop  varchar2(20);
    v_unused  boolean := nvl(p_unused_only,true);
begin
    if v_unused then
        ws(message.gettext('EXEC', 'DELETING_UNUSED_INDEXES',p_class_id));
    else
        ws(message.gettext('EXEC', 'DELETING_INDEXES',p_class_id));
    end if;
    loop
     begin
      for i in (
          select --+ RULE
                 ai.index_name,ai.table_name,ai.owner i_owner,ct.table_name c_table_name,ai.table_owner t_owner
            from dba_indexes ai,class_tables ct
           where ct.class_id = p_class_id
             and ai.table_name = ct.table_name
             and ai.table_owner= nvl(ct.owner,inst_info.gowner)
             and ai.index_name like 'Z#I%'
           union all
          select --+ RULE
                 ai.index_name,ai.table_name,ai.owner,ct.table_name c_table_name,ai.table_owner
            from dba_indexes ai, dba_nested_tables nt, class_tables ct
           where ct.class_id = p_class_id
             and nt.parent_table_name = ct.table_name
             and nt.owner = nvl(ct.owner,inst_info.gowner)
             and ai.table_name = nt.table_name and ai.table_owner = nt.owner
             and ai.index_name like 'Z#I%'
      ) loop
        if v_unused then
          if i.table_name=i.c_table_name then
           if i.index_name like '%\_OLDID' escape '\' then
            select --+ RULE
                   count(1) into n from dba_ind_columns aic
             where aic.index_name = i.index_name
               and aic.table_name = i.table_name
               and aic.table_owner= i.t_owner
               and exists (
                 select 1 from class_tables ct
                  where ct.class_id = p_class_id
                    and instr(ct.old_id_source,'.') = 0
                    and ct.old_id_source = aic.column_name
               ) and not exists (
                 select 1 from dba_ind_columns uic
                  where uic.table_name = aic.table_name
                    and uic.table_owner= aic.table_owner
                    and uic.column_name= aic.column_name
                    and uic.column_position = 1
                    and uic.index_name <> aic.index_name
               );
           else
            select --+ RULE
                   count(1) into n from dba_ind_columns aic
             where aic.index_name = i.index_name
               and aic.table_name = i.table_name
               and aic.table_owner= i.t_owner
               and exists (
                 select 1 from class_tab_columns ctc
                  where ctc.class_id = p_class_id
                    and ctc.column_name = aic.column_name
                    and nvl(ctc.indexed,'0') = '0'
                    and nvl(ctc.deleted,'0') = '0' and ctc.flags is null
                    and (ctc.map_style is null
                      and (ctc.base_class_id='COLLECTION' and aic.index_name like 'Z#IX_Z#%_COL%'
                        or ctc.base_class_id='REFERENCE'  and aic.index_name like 'Z#IX_Z#%_REF%')
                      and exists (select 1 from classes cl where cl.id=ctc.target_class_id and cl.kernel='0')
                      or ctc.map_style is not null and ctc.qual='COLLECTION_ID')
               ) and not exists (
                 select 1 from dba_ind_columns uic
                  where uic.table_name = aic.table_name
                    and uic.table_owner= aic.table_owner
                    and uic.column_name= aic.column_name
                    and uic.column_position = 1
                    and uic.index_name <> aic.index_name
               );
           end if;
          else
            select --+ RULE
                   count(1) into n from dba_ind_columns aic
             where aic.index_name = i.index_name
               and aic.table_name = i.table_name
               and aic.table_owner= i.t_owner
               and aic.column_name= 'NESTED_TABLE_ID'
               and exists (
                 select 1 from class_tab_columns ctc
                  where ctc.class_id = p_class_id
                    and ctc.base_class_id = 'TABLE'
                    and ctc.nt_table = aic.table_name
                    and nvl(ctc.indexed,'0') = '0'
                    and nvl(ctc.deleted,'0') = '0'
               ) and not exists (
                 select 1 from dba_ind_columns uic
                  where uic.table_name = aic.table_name
                    and uic.table_owner= aic.table_owner
                    and uic.column_name= aic.column_name
                    and uic.column_position = 1
                    and uic.index_name <> aic.index_name
               );
          end if;
          drop_ := n = 0;
        else
          drop_ := true;
        end if;
        if drop_ then
          execute_sql('DROP INDEX ' || i.index_name,'  '||message.gettext('EXEC','DELETING',i.index_name),null,i.i_owner);
        end if;
      end loop;
      exit;
     exception when rtl.SNAPSHOT_TOO_OLD then null;
     end;
    end loop;
  if not p_position is null and storage_mgr.is_partitioned(p_class_id)!=storage_mgr.PART_NONE then
    v_table := storage_mgr.class2table(p_class_id);
    if v_table is null then return; end if;
    loop
     begin
      for i in (
          select --+ RULE
                 ai.index_name,ai.table_name,ai.owner i_owner,ct.partition_position,ct.mirror,ai.table_owner t_owner
            from dba_indexes ai,class_partitions ct
           where ct.class_id = p_class_id
             and ct.mirror != v_table
             and (p_position=0 or ct.partition_position=p_position)
             and ai.table_name = ct.mirror
             and ai.table_owner = nvl(ct.mirror_owner,inst_info.gowner)
             and ai.index_name like 'Z#I%'
           union all
          select --+ RULE
                 ai.index_name,ai.table_name,ai.owner,ct.partition_position,ct.mirror,ai.table_owner
            from dba_indexes ai, dba_nested_tables nt, class_partitions ct
           where ct.class_id = p_class_id
             and ct.mirror != v_table
             and (p_position=0 or ct.partition_position=p_position)
             and nt.parent_table_name = ct.mirror
             and nt.owner = nvl(ct.mirror_owner,inst_info.gowner)
             and ai.table_name = nt.table_name and ai.table_owner = nt.owner
             and ai.index_name like 'Z#I%'
      ) loop
        if v_unused then
          if i.table_name=i.mirror then
           if i.index_name like '%\_OLDID' escape '\' then
            select --+ RULE
                   count(1) into n from dba_ind_columns aic
             where aic.index_name = i.index_name
               and aic.table_name = i.table_name
               and aic.table_owner= i.t_owner
               and exists (
                 select 1 from class_tables ct, class_partitions cp
                  where cp.class_id = p_class_id
                    and cp.partition_position = i.partition_position
                    and ct.class_id = cp.class_id
                    and instr(ct.old_id_source,'.') = 0
                    and ct.old_id_source = aic.column_name
               ) and not exists (
                 select 1 from dba_ind_columns uic
                  where uic.table_name = aic.table_name
                    and uic.table_owner= aic.table_owner
                    and uic.column_name= aic.column_name
                    and uic.column_position = 1
                    and uic.index_name <> aic.index_name
               );
           else
            select --+ RULE
                   count(1) into n from dba_ind_columns aic
             where aic.index_name = i.index_name
               and aic.table_name = i.table_name
               and aic.table_owner= i.t_owner
               and exists (
                 select 1 from class_part_columns ctc
                  where ctc.class_id = p_class_id
                    and ctc.partition_position = i.partition_position
                    and ctc.column_name = aic.column_name
                    and nvl(ctc.indexed,'0') = '0'
                    and ( (ctc.base_class_id='COLLECTION' and aic.index_name like 'Z#I%_COL%'
                        or ctc.base_class_id='REFERENCE'  and aic.index_name like 'Z#I%_REF%')
                        and exists (select 1 from classes cl where cl.id=ctc.target_class_id and cl.kernel='0')
                      or ctc.qual='COLLECTION_ID')
               ) and not exists (
                 select 1 from dba_ind_columns uic
                  where uic.table_name = aic.table_name
                    and uic.table_owner= aic.table_owner
                    and uic.column_name= aic.column_name
                    and uic.column_position = 1
                    and uic.index_name <> aic.index_name
               );
           end if;
          else
            select --+ RULE
                   count(1) into n from dba_ind_columns aic
             where aic.index_name = i.index_name
               and aic.table_name = i.table_name
               and aic.table_owner= i.t_owner
               and aic.column_name= 'NESTED_TABLE_ID'
               and exists (
                 select 1 from class_part_columns ctc
                  where ctc.class_id = p_class_id
                    and ctc.partition_position = i.partition_position
                    and ctc.base_class_id = 'TABLE'
                    and ctc.nt_table = aic.table_name
                    and nvl(ctc.indexed,'0') = '0'
               ) and not exists (
                 select 1 from dba_ind_columns uic
                  where uic.table_name = aic.table_name
                    and uic.table_owner= aic.table_owner
                    and uic.column_name= aic.column_name
                    and uic.column_position = 1
                    and uic.index_name <> aic.index_name
               );
          end if;
          drop_ := n = 0;
        else
          drop_ := true;
        end if;
        if drop_ then
          execute_sql('DROP INDEX ' || i.index_name,'  '||message.gettext('EXEC','DELETING',i.index_name),null,i.i_owner);
        end if;
      end loop;
      exit;
     exception when rtl.SNAPSHOT_TOO_OLD then null;
     end;
    end loop;
  end if;
  if p_unused_only is null then
    if storage_mgr.v10_flag then
      v_drop := ' DROP INDEX';
    end if;
    loop
      begin
        for c in (
          select --+ RULE
                 ui.table_name, ui.owner, ui.index_name, uc.constraint_type, ui.table_owner
            from dba_constraints uc, dba_indexes ui, class_tables ct
           where ct.class_id=p_class_id and ui.table_name=ct.table_name
             and ui.uniqueness='UNIQUE' and ui.table_owner=nvl(ct.owner,inst_info.gowner)
             and uc.constraint_name(+)=ui.index_name and uc.table_name(+)=ui.table_name and uc.owner(+)=ui.table_owner
        ) loop
          if c.constraint_type is null then
            execute_sql('DROP INDEX '||c.index_name,'  '||message.gettext('EXEC','DELETING',c.index_name),null,c.owner);
          else
            execute_sql('ALTER TABLE '||c.table_name||' DROP CONSTRAINT '||c.index_name||v_drop,
              '  '||message.gettext('EXEC','DELETING',c.index_name),null,c.table_owner);
          end if;
        end loop;
        exit;
      exception when rtl.SNAPSHOT_TOO_OLD then null;
      end;
    end loop;
  end if;
end;
--
procedure create_indexes(p_class_id varchar2,p_retry pls_integer,p_position pls_integer) is -- @METAGS create_indexes
    type stor_par is record (
        sample  number,
        isize   number,
        tnext   number,
        name    varchar2(30),
        stor    varchar2(200),
        tspace  varchar2(50));
    type stor_tbl is table of stor_par index by binary_integer;
    q varchar2(32000);
    pk_name varchar2(30);
    pk_part varchar2(30);
    v_paral varchar2(30);
    v_table varchar2(30);
    v_name  varchar2(30);
    v_owner varchar2(30);
    v_nolog varchar2(30);
    v_online  varchar2(30);
    v_reverse varchar2(30);
    v_temp  varchar2(1);
    pfx_  varchar2(10);
    cols  varchar2(32000);
    exts  varchar2(100);
    retry pls_integer := nvl(p_retry,2);
    part  boolean;
    bnt   boolean;
    v_unq boolean;
    paral pls_integer;
    cnt   number;
    lfs   number;
    stors stor_par;
    pars  stor_tbl;
    v_profile_id   varchar2(16);
    v_second_key   varchar2(32000);
    part_type varchar2(1);
    --
    procedure get_exts(nulls number,ratio number default 0.5) is
      relat number;
    begin
      if stors.stor is null then
          exts := null;
      else
        if nulls is null or bnt then
            relat := stors.tnext*ratio;
        else
            relat:= nvl(stors.sample,nulls);
            if relat<nulls then
                relat:= 0.1*ratio*stors.isize;
            elsif relat>0 then
                relat:= (relat-nulls)*stors.isize*ratio/relat;
            end if;
        end if;
        optimal_params(relat,exts,pk_part);
        exts := ' initial '||exts||' next '||pk_part||')';
      end if;
    end;
    -- Создавать ли партифицированный индекс
    function create_part_index(base_class_id in class_tab_columns.base_class_id%type) return boolean
    is
    begin
      return part_type = storage_mgr.PART_KEY or
            (part_type = storage_mgr.PART_PROF and base_class_id = 'REFERENCE');
    end;
    -- Заполняем список партиций
    procedure fill_partitions(p_table_name in varchar2) is
    begin
      if part then
        pars.delete;
        for t in (select partition_name, partition_position, next_extent
                    from dba_tab_partitions
                   where table_name = p_table_name
                     and table_owner = v_owner
                   order by partition_position desc) loop
          stors.name  := t.partition_name;
          stors.tnext := t.next_extent;
          begin
            if pk_name is null then
              raise no_data_found;
            end if;
            select leaf_blocks, partition_name
              into lfs, pk_part
              from dba_ind_partitions
             where index_name = pk_name
               and index_owner = v_owner
               and partition_position = t.partition_position;
            if lfs is null then
              analyze_object(pk_name, pk_part, p_owner => v_owner);
            end if;
            select ' pctfree ' || pct_free || ' initrans ' || ini_trans ||
                   ' maxtrans ' || max_trans || ' storage (freelists ' ||
                   nvl(freelists, 1) ||
                   ' minextents 1 maxextents unlimited pctincrease 0',
                   ' tablespace ' || tablespace_name,
                   leaf_blocks,
                   distinct_keys
              into stors.stor, stors.tspace, stors.isize, stors.sample
              from dba_ind_partitions
             where index_name = pk_name
               and index_owner = v_owner
               and partition_name = pk_part;
          exception
            when others then
              stors.stor   := null;
              stors.tspace := null;
              if not idx_tspace is null then
                stors.tspace := ' tablespace ' || idx_tspace;
              end if;
          end;
          if bnt then
            exit;
          else
            pars(t.partition_position) := stors;
          end if;
        end loop;
      end if;
    end;
begin
    begin
        select decode(ut.temporary, 'Y', '1', '0'), ut.owner
          into v_temp, v_owner
          from dba_tables ut, class_tables ct
         where ut.table_name = ct.table_name
           and ct.class_id = p_class_id
           and ut.owner = nvl(ct.owner, inst_info.gowner);
    exception when no_data_found then
        return;
    end;

    part_type := storage_mgr.is_partitioned(p_class_id);

    if block_size is null then
        storage_mgr.get_globals(tab_tspace, idx_tspace, tmp_tspace, block_size);
        prt_compr := upper(substr(nvl(storage_mgr.get_storage_parameter('GLOBAL','COMPRESS_PARTITIONS'),'0'),1,1)) in ('1','Y');
    end if;
    if retry<1 then
        retry := 1;
    elsif retry>4 then
        retry := 4;
    end if;
    if v_temp='0' then
      paral := build_parallel;
    else
      paral := 0;
    end if;
    
    v_second_key := 'KEY';
    v_profile_id := partitioning_mgr.get_profile_id(p_class_id);
    
    if v_profile_id is not null then
      v_second_key := partitioning_mgr.get_part_columns(p_class_id, p_add_col_type=>false);
    end if;
    
    v_nolog := build_nologging;
    v_online:= build_online;
    ws(message.gettext('KRNL', 'INDEXES_CREATION',p_class_id));
    loop
     begin
      v_table := 'X';
      for c in (
        select ct.table_name, ac.column_name, ac.column_id, ac.num_nulls, ac.owner,
               cc.base_class_id, ac.table_name i_table_name
          from dba_tab_columns ac, class_tab_columns cc, class_tables ct
         where ct.class_id=p_class_id and cc.class_id=ct.class_id
           and ac.column_name= cc.column_name
           and ac.table_name = ct.table_name
           and ac.owner = nvl(ct.owner,inst_info.gowner)
           and nvl(cc.indexed,'0') = '0'
           and nvl(cc.deleted,'0') = '0' and cc.flags is null
           and (cc.map_style is null
                and (cc.base_class_id='COLLECTION'
                     or v_temp='0' and cc.base_class_id='REFERENCE')
                and exists (select 1 from classes cl where cl.id=cc.target_class_id and cl.kernel='0')
             or cc.map_style is not null and cc.qual='COLLECTION_ID')
           and ac.column_name not in (
             select column_name from dba_ind_columns
              where table_name=ac.table_name and table_owner=ac.owner and column_position=1
           )
         union all
        select ct.table_name, 'NESTED_TABLE_ID', 1000, 0, ac.owner, cc.base_class_id, ac.table_name i_table_name
          from dba_nested_tables ac, class_tab_columns cc, class_tables ct
         where ct.class_id=p_class_id and cc.class_id=ct.class_id
           and ac.parent_table_column = cc.column_name
           and ac.parent_table_name = ct.table_name
           and ac.owner = nvl(ct.owner,inst_info.gowner)
           and nvl(cc.indexed,'0') = '0'
           and nvl(cc.deleted,'0') = '0'
           and cc.map_style is null and cc.base_class_id='TABLE'
           and 'NESTED_TABLE_ID' not in (
             select column_name from dba_ind_columns
              where table_name=ac.table_name and table_owner=ac.owner and column_position=1
           )
         union all
        select ct.table_name, ac.column_name, ac.column_id, ac.num_nulls, ac.owner,
               null, ac.table_name i_table_name
          from dba_tab_columns ac, class_tables ct
         where ct.class_id=p_class_id and instr(ct.old_id_source,'.')=0
           and ac.column_name= ct.old_id_source
           and ac.table_name = ct.table_name
           and ac.owner = nvl(ct.owner,inst_info.gowner)
           and ac.column_name not in (
             select column_name from dba_ind_columns
              where table_name=ac.table_name and table_owner=ac.owner and column_position=1
           )
         union all
        select ct.table_name, 'ID', 1001, 0, ac.owner, 'ARCHIVE', ct.log_table i_table_name
          from dba_tables ac, class_tables ct
         where ct.class_id=p_class_id and ct.log_table is not null
           and ac.table_name = ct.log_table
           and ac.owner = nvl(ct.log_owner,inst_info.gowner)
           and 'ID' not in (
             select column_name from dba_ind_columns
              where table_name=ac.table_name and table_owner=ac.owner and column_position=1
           )
        order by 3
      ) loop
        bnt := c.table_name<>c.i_table_name;
        part := create_part_index(c.base_class_id);
        fill_partitions(c.table_name);
        --
        if v_table<>c.i_table_name then
          v_table := c.i_table_name;
          v_reverse := null;

          if v_temp='1' then
            v_paral := null;
          else
            if bnt and c.column_id=1000 then
              select next_extent, decode(ltrim(degree),'1',' NOPARALLEL','DEFAULT',' PARALLEL',' PARALLEL '||ltrim(degree))
                into cnt, v_paral
                from dba_all_tables where table_name=v_table and owner=c.owner;
            else
              select next_extent, decode(ltrim(degree),'1',' NOPARALLEL','DEFAULT',' PARALLEL',' PARALLEL '||ltrim(degree))
                into cnt, v_paral
                from dba_tables where table_name=v_table and owner=c.owner;
            end if;

            begin
              select constraint_name into pk_name from dba_constraints
               where table_name=c.table_name and owner=v_owner and constraint_type='P';
              select leaf_blocks, index_type into lfs, v_reverse
                from dba_indexes where index_name=pk_name and table_owner=v_owner and table_name=c.table_name;
              if instr(v_reverse,'/REV') > 0 then
                v_reverse := ' REVERSE';
              else
                v_reverse := null;
              end if;
            exception when others then
              pk_name := null;
              v_reverse := null;
            end;

            if part then
              null;
            elsif pk_name is not null then
              stors.tnext := cnt;
              if lfs is null then
                  analyze_object(pk_name,p_owner=>v_owner);
              end if;
              select ' pctfree '||pct_free||' initrans '||ini_trans||
                     ' maxtrans '||max_trans||' storage (freelists '||nvl(freelists,1)||
                     ' minextents 1 maxextents unlimited pctincrease 0',
                     ' tablespace '||tablespace_name,
                     leaf_blocks, distinct_keys
              into stors.stor, stors.tspace, stors.isize, stors.sample
              from dba_indexes where index_name=pk_name and table_owner=v_owner and table_name=c.table_name;
              stors.isize := stors.isize*block_size;
            else
              stors.tnext := cnt;
              stors.stor := null;
              stors.tspace := null;
              if not idx_tspace is null then
                  stors.tspace := ' tablespace '||idx_tspace;
              end if;
            end if;
          end if;
        end if;
       for x in 1..retry loop
        q := 'CREATE ';
        v_unq:= false;
        cols := c.column_name;
        if c.base_class_id is null then
            if part then
              if v_profile_id is not null then
                cols := cols||v_second_key;
              else
                cols := cols||','||v_second_key;
              end if;
            end if;
            q := q || 'UNIQUE ';
            pfx_ := 'OLDID';
            v_unq:= true;
        elsif c.base_class_id = 'COLLECTION' then
            if part then
              if v_profile_id is not null then
                cols := cols||v_second_key;
              else
                cols := cols||','||v_second_key;
              end if;
            end if;
            q := q || 'UNIQUE ';
            pfx_ := 'COL'||to_char(c.column_id);
            v_unq:= true;
        elsif c.base_class_id = 'REFERENCE' then
            pfx_ := 'REF'||to_char(c.column_id);
        elsif c.base_class_id = 'TABLE' then
            pfx_ := 'X';
        elsif c.base_class_id = 'ARCHIVE' then
            pfx_ := cols;
        else
            pfx_ := 'COLL';
        end if;
        v_name := 'Z#IX_'||v_table||'_'|| pfx_;
        q := q|| 'INDEX '||v_name||' ON '||v_table||' ('||cols||')'||LF;
        if part and not bnt then
          q := q||'LOCAL ('||LF;
          for i in 1..pars.last loop
            stors:=pars(i);
            select num_nulls into cnt from dba_part_col_statistics
             where table_name=c.table_name and owner=v_owner and partition_name=stors.name and column_name=c.column_name;
            if c.base_class_id = 'COLLECTION' then
              get_exts(cnt);
            else
              get_exts(cnt,0.4);
            end if;
            if i>1 then
              q := q||',';
            end if;
            q := q||'PARTITION '||stors.name||stors.tspace||stors.stor||exts||LF;
          end loop;
          if prt_compr and not v_unq and part_type != storage_mgr.PART_PROF then
            q := q||'NOCOMPRESS ) COMPRESS';
          else
            q := q||')';
          end if;
        elsif v_temp = '0' then
          get_exts(c.num_nulls);
          q := q||stors.tspace||stors.stor||exts;
        end if;
        begin
          if v_temp='0' then
            if paral>0 and v_paral=' NOPARALLEL' then
              q := q||' PARALLEL';
              if paral>1 then
                q := q||' '||paral;
              end if;
            else
              q := q||v_paral;
            end if;
            if v_unq and v_reverse is not null then
              q := q||v_reverse;
            end if;
            q := q||v_nolog||v_online;
          end if;
          execute_sql(q,'  ' || message.gettext('KRNL','INDEX_FOR',v_name,c.column_name),false,c.owner);
          if not (v_paral is null or paral=0 and v_nolog is null) then
            execute_sql('ALTER INDEX '||v_name||v_paral||' LOGGING',
              '  ' || message.gettext('EXEC','INDEX',v_name||v_paral||' LOGGING'),false,c.owner);
          end if;
          exit;
        exception when others then
          if sqlcode in (-1658,-1688) then
            if part and not bnt then
              for i in 1..pars.last loop
                pars(i).isize := pars(i).isize*0.5;
                pars(i).tnext := pars(i).tnext*0.5;
              end loop;
            else
              stors.isize := stors.isize*0.5;
              stors.tnext := stors.tnext*0.5;
            end if;
          else exit; end if;
        end;
       end loop;
      end loop;
      exit;
     exception when rtl.SNAPSHOT_TOO_OLD then null;
     end;
    end loop;

    pars.delete;
  if not p_position is null and part_type != storage_mgr.PART_NONE then
    loop
      begin
      v_table := 'X';
      for c in (
        select cc.table_name, ac.column_name, ac.column_id, ac.num_nulls, ac.owner, ac.table_name i_table_name,
               cc.base_class_id, cc.partition_position
          from dba_tab_columns ac, class_part_columns cc, class_partitions ct
         where ct.class_id = p_class_id and ct.mirror is not null
           and (p_position=0 or ct.partition_position=p_position)
           and cc.class_id = ct.class_id
           and cc.partition_position = ct.partition_position
           and ac.column_name= cc.column_name
           and ac.table_name = ct.mirror
           and ac.owner = nvl(ct.mirror_owner,inst_info.gowner)
           and nvl(cc.indexed,'0') = '0'
           and (cc.base_class_id in ('REFERENCE','COLLECTION')
                and exists (select 1 from classes cl where cl.id=cc.target_class_id and cl.kernel='0')
             or cc.qual='COLLECTION_ID')
           and ac.column_name not in (
             select column_name from dba_ind_columns
              where table_name=ac.table_name and table_owner=ac.owner and column_position=1
           )
         union all
        select cc.table_name, 'NESTED_TABLE_ID', 1000, 0, ac.owner, ac.table_name i_table_name,
               cc.base_class_id, cc.partition_position
          from dba_nested_tables ac, class_part_columns cc, class_partitions ct
         where ct.class_id = p_class_id and ct.mirror is not null
           and (p_position=0 or ct.partition_position=p_position)
           and cc.class_id=p_class_id
           and cc.partition_position = ct.partition_position
           and ac.parent_table_column = cc.column_name
           and ac.parent_table_name = ct.mirror
           and ac.owner = nvl(ct.mirror_owner,inst_info.gowner)
           and nvl(cc.indexed,'0') = '0'
           and cc.base_class_id='TABLE'
           and 'NESTED_TABLE_ID' not in (
             select column_name from dba_ind_columns
              where table_name=ac.table_name and table_owner=ac.owner and column_position=1
           )
         union all
        select cc.mirror, ac.column_name, ac.column_id, ac.num_nulls, ac.owner, ac.table_name i_table_name,
               null, cc.partition_position
          from dba_tab_columns ac, class_partitions cc, class_tables ct
         where ct.class_id=p_class_id and instr(ct.old_id_source,'.')=0
           and cc.class_id=ct.class_id and cc.mirror<>ct.table_name
           and (p_position=0 or cc.partition_position=p_position)
           and ac.column_name= ct.old_id_source
           and ac.table_name = cc.mirror
           and ac.owner = nvl(cc.mirror_owner,inst_info.gowner)
           and ac.column_name not in (
             select column_name from dba_ind_columns
              where table_name=ac.table_name and table_owner=ac.owner and column_position=1
           )
         order by 1,3
      ) loop
        bnt := c.table_name<>c.i_table_name;
        if v_table<>c.table_name then
          v_table := c.table_name;
          if bnt and c.column_id=1000 then
            select next_extent, decode(ltrim(degree),'1',' NOPARALLEL','DEFAULT',' PARALLEL',' PARALLEL '||ltrim(degree))
              into cnt, v_paral
              from dba_all_tables where table_name=v_table and owner=c.owner;
          else
            select next_extent, decode(ltrim(degree),'1',' NOPARALLEL','DEFAULT',' PARALLEL',' PARALLEL '||ltrim(degree))
              into cnt, v_paral
              from dba_tables where table_name=v_table and owner=c.owner;
          end if;
          stors.tnext := cnt;
          begin
            select constraint_name into pk_name from dba_constraints
             where table_name=v_table and constraint_type='P' and owner=c.owner;
            select leaf_blocks, index_type into lfs, v_reverse
              from dba_indexes where index_name=pk_name and table_name=v_table and table_owner=c.owner;
            if instr(v_reverse,'/REV') > 0 then
              v_reverse := ' REVERSE';
            else
              v_reverse := null;
            end if;
            if lfs is null then
                analyze_object(pk_name,p_owner=>c.owner);
            end if;
            select ' pctfree '||pct_free||' initrans '||ini_trans||
                   ' maxtrans '||max_trans||' storage (freelists '||nvl(freelists,1)||
                   ' minextents 1 maxextents unlimited pctincrease 0',
                   ' tablespace '||tablespace_name,
                   leaf_blocks, distinct_keys
            into stors.stor, stors.tspace, stors.isize, stors.sample
            from dba_indexes where index_name=pk_name and table_name=v_table and table_owner=c.owner;
            stors.isize := stors.isize*block_size;
          exception when others then
            v_reverse := null;
            stors.stor:= null;
            stors.tspace := null;
            if not idx_tspace is null then
                stors.tspace := ' tablespace '||idx_tspace;
            end if;
          end;
        end if;
       for x in 1..retry loop
        q := 'CREATE ';
        cols := c.column_name;
        if c.base_class_id is null then
            if part then
              if v_profile_id is not null then
                cols := cols||v_second_key;
              else
                cols := cols||','||v_second_key;
              end if;
            end if;
            q := q || 'UNIQUE ';
            pfx_ := 'OLDID';
            v_unq:= true;
        elsif c.base_class_id = 'COLLECTION' then
            if part then
              if v_profile_id is not null then
                cols := cols||v_second_key;
              else
                cols := cols||','||v_second_key;
              end if;
            end if;
            q := q || 'UNIQUE ';
            pfx_ := 'COL'||to_char(c.column_id);
            v_unq:= true;
        elsif c.base_class_id = 'REFERENCE' then
            pfx_ := 'REF'||to_char(c.column_id);
        elsif c.base_class_id = 'TABLE' then
            pfx_ := 'X';
        else
            pfx_ := 'COLL';
        end if;
        get_exts(c.num_nulls);
        v_name := 'Z#I'||lpad(to_char(c.partition_position),3,'0')||substr(c.i_table_name,7)||'_'||pfx_;
        q := q||'INDEX '||v_name||' ON '||c.i_table_name||' ('||cols||')'||LF
          || stors.tspace||stors.stor||exts;
        if prt_compr and not v_unq and part_type!=storage_mgr.PART_PROF then
          q := q||' COMPRESS';
        end if;
        begin
          if paral>0 and v_paral=' NOPARALLEL' then
            q := q||' PARALLEL';
            if paral>1 then
              q := q||' '||paral;
            end if;
          else
            q := q||v_paral;
          end if;
          if v_unq and v_reverse is not null then
            q := q||v_reverse;
          end if;
          execute_sql(q||v_nolog||v_online,
            '  ' || message.gettext('KRNL','INDEX_FOR',v_name,c.i_table_name||'.'||c.column_name),false,c.owner);
          if not (paral=0 and v_nolog is null) then
            execute_sql('ALTER INDEX '||v_name||v_paral||' LOGGING',
              '  ' || message.gettext('EXEC','INDEX',v_name||v_paral||' LOGGING'),false,c.owner);
          end if;
          exit;
        exception when others then
          if sqlcode in (-1658,-1688) then
            stors.isize := stors.isize*0.5;
            stors.tnext := stors.tnext*0.5;
          else exit; end if;
        end;
       end loop;
      end loop;
      exit;
     exception when rtl.SNAPSHOT_TOO_OLD then null;
     end;
    end loop;
  end if;
end;
--
procedure drop_constraints(p_class_id varchar2,p_unused_only boolean,p_position pls_integer) is
    drop_ boolean;
    n number;
    base_ varchar2(30);
    targ_ varchar2(30);
    v_col varchar2(30);
    v_prt varchar2(1);
begin
    if p_unused_only then
        ws(message.gettext('EXEC', 'DELETING_UNUSED_CONSTRAINTS',p_class_id));
    else
        ws(message.gettext('EXEC', 'DELETING_CONSTRAINTS',p_class_id));
    end if;
    v_prt := storage_mgr.is_partitioned(p_class_id);
    loop
     begin
      for c in (
          select --+ RULE
                 ac.constraint_name, ac.table_name, ac.owner, ac.constraint_type, ac.r_constraint_name,
                 substr(ac.generated,1,1) gen, ct.param_group
            from dba_constraints ac,class_tables ct
           where ct.class_id = p_class_id
             and ac.table_name = ct.table_name
             and ac.owner = nvl(ct.owner,inst_info.gowner)
             and (ac.constraint_type='R' and ac.constraint_name like 'Z#FK_'||ac.table_name||'_REF%'
                  or ac.constraint_type='C' and
                     (ac.constraint_name like 'Z#NN_'||ac.table_name||'_COL%' or ac.generated='GENERATED NAME'))
      ) loop
        drop_ := true;
        select column_name into v_col from dba_cons_columns
         where table_name=c.table_name and owner=c.owner and constraint_name=c.constraint_name and nvl(position,1)=1 and rownum=1;
        if p_unused_only then
          targ_ := null;
          if c.constraint_type = 'C' then
            base_ := 'COLLECTION';
          elsif c.param_group = 'PARTITION' then
            drop_ := false;
          elsif c.constraint_type = 'R' then
            targ_ := c.r_constraint_name;
            targ_ := substr(targ_,4,instr(targ_,'_',-1)-4);
            begin
              select class_id into targ_ from class_tables
               where table_name=targ_ and nvl(param_group,'X')<>'PARTITION';
            exception when no_data_found then
              drop_ := false;
            end;
            base_ := 'REFERENCE';
          end if;
          if drop_ then
            select --+ FIRST_ROWS
                   count(1) into n from class_tab_columns ctc
             where ctc.class_id=p_class_id and ctc.column_name=v_col
               and nvl(ctc.deleted,'0')='0' and nvl(ctc.indexed,'0')='0'
               and ctc.map_style is null and ctc.base_class_id=base_ and ctc.flags is null
               and exists (select 1 from classes cl where cl.id=ctc.target_class_id and cl.kernel='0')
               and (targ_ is null or ctc.target_class_id=targ_);--если вдруг изменился тип с Ref|Coll на другое
            if n>0 then
              drop_ := false;
              if base_='COLLECTION' and c.gen='U' then
                drop_ := null;
              end if;
            end if;
          else
            drop_ := true;
          end if;
        end if;
        if nvl(drop_,true) then
          execute_sql('ALTER TABLE ' || c.table_name || ' DROP CONSTRAINT ' || c.constraint_name,
            '  '||message.gettext('EXEC','DELETING',c.constraint_name||' ('||c.table_name||'.'||v_col||')'),null,c.owner);
          if drop_ is null then
            execute_sql('ALTER TABLE '||c.table_name ||' MODIFY '||v_col||' NOT NULL',
            '  '||message.gettext('EXEC','ALTERING_TABLE',c.table_name ||' MODIFY '||v_col||' NOT NULL'),null,c.owner);
          end if;
        end if;
      end loop;
      exit;
     exception when rtl.SNAPSHOT_TOO_OLD then null;
     end;
    end loop;
  if not p_position is null and v_prt!=storage_mgr.PART_NONE then
   base_ := storage_mgr.class2table(p_class_id);
   if not base_ is null then
    loop
     begin
      for c in (
          select ac.constraint_name, ac.table_name, ac.owner, ct.partition_position, substr(ac.generated,1,1) gen
            from dba_constraints ac, class_partitions ct
           where ct.class_id = p_class_id
             and ct.mirror != base_
             and (p_position=0 or ct.partition_position=p_position)
             and ac.table_name = ct.mirror
             and ac.owner = nvl(ct.mirror_owner,inst_info.gowner)
             and ac.constraint_type='C'
             and (ac.constraint_name like 'Z#N%_COL%' or ac.generated='GENERATED NAME')
      ) loop
        drop_ := true;
        select column_name into v_col from dba_cons_columns
         where table_name=c.table_name and owner=c.owner and constraint_name=c.constraint_name and rownum=1;
        if p_unused_only then
          select --+ FIRST_ROWS
                 count(1) into n from class_part_columns ctc
           where ctc.class_id=p_class_id and ctc.column_name=v_col
             and nvl(ctc.indexed,'0')='0' and ctc.base_class_id='COLLECTION'
             and partition_position = c.partition_position
             and exists (select 1 from classes cl where cl.id=ctc.target_class_id and cl.kernel='0');
          if n>0 then
            drop_ := false;
            if base_='COLLECTION' and c.gen='U' then
              drop_ := null;
            end if;
          end if;
        end if;
        if nvl(drop_,true) then
          execute_sql('ALTER TABLE ' || c.table_name || ' DROP CONSTRAINT ' || c.constraint_name,
            '  '||message.gettext('EXEC','DELETING',c.constraint_name||' ('||c.table_name||'.'||v_col||')'),null,c.owner);
          if drop_ is null then
            if v_prt=storage_mgr.PART_VIEW then
              base_ := ' NOVALIDATE';
            else
              base_ := null;
            end if;
            execute_sql('ALTER TABLE '||c.table_name ||' MODIFY '||v_col||' NOT NULL'||base_,
            '  '||message.gettext('EXEC','ALTERING_TABLE',c.table_name ||' MODIFY '||v_col||' NOT NULL'||base_),null,c.owner);
          end if;
        end if;
      end loop;
      exit;
     exception when rtl.SNAPSHOT_TOO_OLD then null;
     end;
    end loop;
   end if;
  end if;
  if v_prt in (storage_mgr.PART_KEY,storage_mgr.PART_PROF) then
    create_triggers(p_class_id,null);
    if not p_unused_only then
      drop_triggers(p_class_id);
    end if;
  end if;
  if p_unused_only is null then
    begin
      select uc.table_name, uc.constraint_name, uc.owner
        into targ_, base_, v_col from dba_constraints uc, class_tables ct
       where ct.class_id=p_class_id and uc.owner = nvl(ct.owner,inst_info.gowner)
         and uc.table_name=ct.table_name and uc.constraint_type='P';
    exception when no_data_found then
      base_ := null;
    end;
    if not base_ is null then
      loop
        begin
          for c in (
            select table_name, constraint_name, owner
              from dba_constraints where constraint_type='R' and r_constraint_name=base_ and r_owner=v_col
             union all
            select table_name, constraint_name, owner
              from dba_constraints where constraint_type='R' and table_name=targ_ and owner=v_col
          ) loop
            execute_sql('ALTER TABLE ' || c.table_name || ' DROP CONSTRAINT ' || c.constraint_name,
              '  '||message.gettext('EXEC','DELETING',c.constraint_name),null,c.owner);
          end loop;
          exit;
        exception when rtl.SNAPSHOT_TOO_OLD then null;
        end;
      end loop;
    end if;
  end if;
end;
--
procedure create_constraints(p_class_id varchar2, p_refs boolean, p_position pls_integer, p_force pls_integer,
                             p_delayed_actions_mode  boolean default false -- Признак включенного режима отложенных действий
                             ) is  -- @METAGS create_constraints
v_trig  varchar2(1);
v_owner varchar2(30);
v_table varchar2(30);
v_targ  varchar2(30);
v_own   varchar2(30);
v_val   varchar2(30);
v_defer varchar2(30);
v_retry varchar2(1);
v_temp  varchar2(1);
v_part  boolean;
v_add   boolean;
q   varchar2(300);
qq  varchar2(16000);
v_is_partitioned varchar2(1);
begin
  ws(message.gettext('EXEC', 'CREATING_CONSTRAINTS',p_class_id));
  v_trig := storage_mgr.is_partitioned(p_class_id);
  v_part := v_trig in (storage_mgr.PART_KEY,storage_mgr.PART_PROF);
  v_temp := storage_mgr.is_temporary(p_class_id);
  if p_refs is null then
    v_val:= ' NOVALIDATE';
  else
    v_val:= build_novalidate;
  end if;
  v_defer:= build_deferrable;
  v_retry:= '1';
  loop
    begin
      for c in (
          select --+ RULE
                 ct.table_name,ctc.column_name,ctc.target_class_id,utc.column_id,utc.owner,ctc.base_class_id,ctc.qual,
                 (
                  select un.constraint_name||'.'||un.status||'.'||un.deferrable||'.'||un.validated
                    from dba_cons_columns unc, dba_constraints un
                   where unc.table_name = ct.table_name
                     and un.table_name= ct.table_name
                     and unc.owner = utc.owner and un.owner = utc.owner
                     and un.constraint_name = unc.constraint_name
                     and un.constraint_type = decode(ctc.base_class_id,'REFERENCE','R','COLLECTION','C')
                     and unc.column_name = utc.column_name
                     and nvl(unc.position,1) = 1 and rownum = 1
                 ) cons_props
            from dba_tab_columns utc,class_tab_columns ctc, class_tables ct
           where ct.class_id = p_class_id and ctc.class_id = ct.class_id
             and (ctc.base_class_id='COLLECTION'
               or ctc.base_class_id='REFERENCE' and v_retry='1' and v_trig in ('0','2','3') and v_temp='0')
             and ctc.deleted = '0' and ctc.indexed='0'
             and ctc.map_style is null and ctc.flags is null
             and utc.table_name = ct.table_name
             and utc.column_name = ctc.column_name
             and utc.owner = nvl(ct.owner,inst_info.gowner)
             and exists (select 1 from classes cl where cl.id=ctc.target_class_id and cl.kernel='0')
      ) loop
       v_table := c.table_name;
       v_owner := c.owner;
       v_add := false;
       if c.cons_props is null then
        v_add := true;
       elsif p_force > 0 then
        if instr(c.cons_props,'.DISABLED.') > 0 or c.base_class_id = 'REFERENCE' and
           ( bitand(p_force,1)>0 and instr(c.cons_props,'.'||nvl(ltrim(v_defer),'NOT DEFERRABLE')||'.')=0
             or bitand(p_force,2)>0 and v_val is null and instr(c.cons_props,'.VALIDATED')=0 )
        then
          q := substr(c.cons_props,1,instr(c.cons_props,'.')-1);
          execute_sql('ALTER TABLE ' || v_table || ' DROP CONSTRAINT ' || q,
            '  '||message.gettext('EXEC','DELETING',q),null,v_owner);
          v_add := true;
        end if;
       end if;
       if v_add then
        -- Для создаваемых коллекций не будем создавать NOT NULL в режиме отложенных действий
        if c.base_class_id = 'COLLECTION' then
          -- Если констрейнта нет и включен режим отложенных действий
          if c.cons_props is null and p_delayed_actions_mode then
            -- Создадим отложенное действие по созданию констрейнта NOT_NULL
            delayed_action_mgr.add_delayed_action(
                        p_action_group => delayed_action_mgr.GROUP_FILL_SYSTEM_COLUMNS,    -- Группа действий
                        p_action_type  => delayed_action_mgr.SET_NOT_NULL,                 -- Тип действия
                        p_priority     => delayed_action_mgr.PRIOR_COLLECTION_SET_NOT_NULL,-- Приоритет
                        p_class_id     => p_class_id,  -- Короткое имя ТБП
                        p_class_column_qual => c.qual, -- Квалификатор колонки ТБП
                        p_index_name   => null         -- Наименование индекса
            );
          else
            q := c.column_name || ' NOT NULL';
            if v_retry = '1' then
              if qq is null then
                qq := q;
              else
                qq := qq || ',' || LF || q;
              end if;
            else
              q := v_table || ' MODIFY ' || q || qq;
              begin
                execute_sql('ALTER TABLE '||q,'  '||message.gettext('EXEC','ALTERING_TABLE',q),false,v_owner);
                ws('  '||message.gettext('EXEC','ALTERING_TABLE',q)||' - OK.');
              exception when others then
                if qq is null and sqlcode = -2296 then
                  q := q||' NOVALIDATE';
                  execute_sql('ALTER TABLE '||q,'  '||message.gettext('EXEC','ALTERING_TABLE',q),null,v_owner);
                end if;
              end;
            end if;
            -- Удалим запись из журнала отложенных действий
            delayed_action_mgr.delete_delayed_action(
                          p_action_type  => delayed_action_mgr.SET_NOT_NULL, -- Тип действия
                          p_class_id     => p_class_id,  -- Короткое имя ТБП
                          p_class_column_qual => c.qual, -- Квалификатор колонки ТБП
                          p_index_name   => null         -- Наименование индекса
            );
          end if;
        elsif v_trig in ('0','2','3') and v_temp = '0' then
          v_is_partitioned := storage_mgr.is_partitioned(c.target_class_id);
          if storage_mgr.is_temporary(c.target_class_id)='1' then
            null;
          elsif v_is_partitioned = storage_mgr.PART_KEY then
            v_part := true;
          else
            if v_is_partitioned = storage_mgr.PART_PROF then
              v_part := true;
            end if;
            begin
              select /*+ RULE */ ut.owner,ut.table_name into v_own,v_targ
                from dba_tables ut,class_tables ct
               where ct.class_id=c.target_class_id and ut.table_name=ct.table_name
                 and ut.owner = nvl(ct.owner,inst_info.gowner);
              q := 'ALTER TABLE ' || v_table || ' ADD CONSTRAINT Z#FK_' || v_table ||'_REF' || c.column_id || LF ||
                   'FOREIGN KEY (' || c.column_name || ')' || ' REFERENCES '||v_own||'.'||v_targ||'(ID)'||v_defer||v_val;
              for i in 1..2 loop
                begin
                  execute_sql(q,'  ' || message.gettext('EXEC', 'REFERENCE_ON', v_table||'.'||c.column_name, v_own||'.'||v_targ||'.ID'||v_defer||v_val),false,v_owner);
                  exit;
                exception when others then
                  if i=1 and sqlcode in (-942,-1031) then
                    execute_sql('GRANT REFERENCES ON '||v_targ||' TO '||v_owner,'  GRANT REFERENCES ON '||v_targ,false,v_own);
                  else
                    raise;
                  end if;
                end;
              end loop;
              ws('  '||message.gettext('EXEC','REFERENCE_ON',v_table||'.'||c.column_name,v_own||'.'||v_targ||'.ID')||' - OK.');
            exception when others then
              if v_val is null and sqlcode = -2298 then
                execute_sql(q||' NOVALIDATE','  ' || message.gettext('EXEC', 'REFERENCE_ON', v_table||'.'||c.column_name, v_own||'.'||v_targ||'.ID'||v_defer||' NOVALIDATE'),null,v_owner);
              end if;
            end;
          end if;
        end if;
       end if;
      end loop;
      exit when qq is null or v_retry <> '1';
      v_retry := '0';
      if instr(qq,LF) = 0 then
        qq:= v_table || ' MODIFY ' || qq;
        q := qq;
      else
        qq:= v_table || ' MODIFY (' || qq || ')';
        q := v_table || ' - NOT NULL';
      end if;
      begin
        execute_sql('ALTER TABLE '||qq,'  '||message.gettext('EXEC','ALTERING_TABLE',qq),false,v_owner);
        ws('  '||message.gettext('EXEC','ALTERING_TABLE',q)||' - OK.');
        exit;
      exception when others then
        if sqlcode = -2296 and instr(qq,LF) = 0 then
          q := q||' NOVALIDATE';
          execute_sql('ALTER TABLE '||q,'  '||message.gettext('EXEC','ALTERING_TABLE',q),null,v_owner);
          exit;
        end if;
      end;
      qq := v_val;
    exception when rtl.SNAPSHOT_TOO_OLD then
      if v_retry = '1' then
        qq := null;
      else
        qq := v_val;
      end if;
    end;
  end loop;
if not p_position is null and v_trig!='0' then
  if v_val is null and v_trig = '2' then
    v_val := ' NOVALIDATE';
  end if;
  for m in (
    select mirror,mirror_owner,partition_position
      from class_partitions
     where class_id = p_class_id and mirror is not null
       and (p_position = 0 or partition_position = p_position)
  ) loop
    v_table := m.mirror;
    v_owner := nvl(m.mirror_owner,inst_info.gowner);
    v_retry := '1';
    qq := null;
    loop
      begin
        for c in (
          select --+ RULE
                 ctc.column_name,utc.column_id
            from dba_tab_columns utc,class_part_columns ctc
           where ctc.class_id = p_class_id and ctc.partition_position = m.partition_position
             and ctc.base_class_id = 'COLLECTION' and ctc.indexed = '0'
             and utc.column_name = ctc.column_name and utc.table_name = v_table and utc.owner = v_owner
             and exists (select 1 from classes cl where cl.id=ctc.target_class_id and cl.kernel='0')
             and not exists (
               select 1 from dba_cons_columns unc, dba_constraints un
                where unc.table_name = v_table and un.table_name = v_table
                  and unc.owner = v_owner and un.owner = v_owner
                  and un.constraint_name = unc.constraint_name and un.constraint_type = 'C'
                  and unc.column_name = utc.column_name and nvl(unc.position,1) = 1
             )
        ) loop
          q := c.column_name || ' NOT NULL';
          if v_retry = '1' then
            if qq is null then
              qq := q;
            else
              qq := qq || ',' || LF || q;
            end if;
          else
            q := v_table || ' MODIFY ' || q || qq;
            begin
              execute_sql('ALTER TABLE '||q,'  '||message.gettext('EXEC','ALTERING_TABLE',q),false,v_owner);
              ws('  '||message.gettext('EXEC','ALTERING_TABLE',q)||' - OK.');
            exception when others then
              if qq is null and sqlcode = -2296 then
                q := q||' NOVALIDATE';
                execute_sql('ALTER TABLE '||q,'  '||message.gettext('EXEC','ALTERING_TABLE',q),null,v_owner);
              end if;
            end;
          end if;
        end loop;
        exit when qq is null or v_retry <> '1';
        v_retry := '0';
        if instr(qq,LF) = 0 then
          qq:= v_table || ' MODIFY ' || qq;
          q := qq;
        else
          qq:= v_table || ' MODIFY (' || qq || ')';
          q := v_table || ' - NOT NULL';
        end if;
        begin
          execute_sql('ALTER TABLE '||qq,'  '||message.gettext('EXEC','ALTERING_TABLE',qq),false,v_owner);
          ws('  '||message.gettext('EXEC','ALTERING_TABLE',q)||' - OK.');
          exit;
        exception when others then
          if sqlcode = -2296 and instr(qq,LF) = 0 then
            q := q||' NOVALIDATE';
            execute_sql('ALTER TABLE '||q,'  '||message.gettext('EXEC','ALTERING_TABLE',q),null,v_owner);
            exit;
          end if;
        end;
        qq := v_val;
      exception when rtl.SNAPSHOT_TOO_OLD then
        if v_retry = '1' then
          qq := null;
        else
          qq := v_val;
        end if;
      end;
    end loop;
  end loop;
end if;
if v_temp = '0' then
  if p_refs or v_part then
      v_part := true;
  else
      select count(1) into v_targ from class_tab_columns ctc
       where rownum<2 and ctc.target_class_id=p_class_id
         and ctc.deleted='0' and ctc.indexed='0' and ctc.flags is null
         and ctc.map_style is null and ctc.base_class_id='REFERENCE'
         and exists(select 1 from class_tables ct
           where ct.class_id=ctc.class_id and ct.param_group='PARTITION');
      if v_targ='0' then
          select count(1) into v_targ from class_tables ct, class_relations cr
           where rownum<2 and ct.param_group='PARTITION'
             and cr.parent_id= p_class_id
             and cr.distance = 1
             and ct.class_id = cr.child_id;
      end if;
      v_part := v_targ<>'0';
  end if;
  if v_part then
      create_triggers(p_class_id,case when p_refs then true else null end);
  end if;
elsif p_refs then
  drop_triggers(p_class_id);
end if;
end;
--
procedure update_refced_triggers(p_class_id varchar2) is
begin
  for c in(
    select t.class_id as class_id, t.param_group
      from class_attributes a, classes c, class_tables t
     where a.class_id = p_class_id
       and a.self_class_id = c.id
       and c.base_class_id = 'REFERENCE'
       and c.target_class_id = t.class_id)
     loop
       ws(message.gettext('KRNL', 'REFERENCES_ON', c.class_id, p_class_id));
       create_refced_triggers(c.class_id, c.param_group='PARTITION');
     end loop;
end;
--
procedure create_refcing_triggers(p_class_id varchar2, p_ref_part boolean default false, p_refs boolean default false) is
  cursor refcing is
    select ctc.qual, ctc.column_name, ct.class_id, ct.table_name, ct.param_group, ct.owner, c.short_name
      from class_tables ct, class_tab_columns ctc, classes c
     where ctc.class_id = p_class_id
       and ctc.deleted = '0' and ctc.indexed='0'
       and ctc.map_style is null and ctc.flags is null
       and ctc.base_class_id='REFERENCE'
       and nvl(c.kernel, '0')='0'
       and c.temp_type is null
       and ct.class_id = ctc.target_class_id
       and c.id = ctc.target_class_id
     union all
    select 'ID', 'ID', ct.class_id, ct.table_name, ct.param_group, ct.owner, c.short_name
      from class_tables ct, class_relations cr, classes c
     where cr.child_id = p_class_id
       and cr.distance = 1
       and c.temp_type is null
       and ct.class_id = cr.parent_id
       and c.id = cr.parent_id;
    refced  "CONSTANT".refstring_table;
    flags   "CONSTANT".boolean_table;
    class_table_name_  varchar2(30);
    v_owner varchar2(32);
    part    varchar2(100);
    tbl     varchar2(100);
    key     varchar2(20);
    rlist   varchar2(30000);
    slist   varchar2(30000);
    v_part  varchar2(1);
    refs    dbms_sql.varchar2s;
    v_prt   boolean;
    i   pls_integer;
begin
  begin
    select table_name,owner into class_table_name_,v_owner
      from class_tables where class_id = p_class_id;
  exception when no_data_found then
    return;
  end;
  v_owner := nvl(v_owner,inst_info.gowner)||'.';
  ws(message.gettext('KRNL', 'CREATING_REFERENCE_TRIGGERS',p_class_id));
  for c in refcing loop
    i := null;
    v_prt := c.param_group='PARTITION';
  if p_ref_part or v_prt then
    rlist:= rlist||', '||c.column_name;
    tbl := c.table_name;
    part:= null;
    if tbl=class_table_name_ then
     if v_prt then
      slist:= slist||', '||c.column_name;
      v_part := nvl(substr(c.short_name,26,1),'0');
      if v_part = '0' and storage_mgr.prt_actual or v_part = '1' then
        tbl := tbl||' partition('||tbl||'#0)';
        key := 'key=1000 and ';
      else
        part:= 'k:=valmgr.get_key('''||p_class_id||'''); ';
        key := 'key>=k and ';
      end if;
      class_mgr.put_text_buf(
         'if not :new.'||c.column_name||' is null then if inserting then'||LF
         ||TB||part||'select count(1) into n from '||v_owner||tbl||' where '||key||'id=:new.'||c.column_name||';'||LF
         ||TB||'if n=0 then message.err(-20999,''ORA'',''02291'','''
         ||p_class_id||''','''||c.qual||'''); end if;'||LF
         ||'elsif :new.'||c.column_name||'!=nvl(:old.'||c.column_name||',0) then'||LF
         ||TB||'part_mgr.obj_update(:new.'||c.column_name||','''||c.qual||''');'||LF
         ||'end if; end if;'||LF,
         refs);
     end if;
    else
      key := null;
      if v_prt then
        part := nvl(substr(c.short_name,26,1),'0');
        if part = '0' and storage_mgr.prt_actual or part = '1' then
          tbl := tbl||' partition('||tbl||'#0)';
          key := 'key=1000 and ';
          part:= null;
        else
          part:= 'k:=valmgr.get_key('''||c.class_id||'''); ';
          key := 'key>=k and ';
        end if;
      end if;
      class_mgr.put_text_buf(
         'if not :new.'||c.column_name||' is null and :new.'
         ||c.column_name||'!=nvl(:old.'||c.column_name||',0) then'||LF
         ||TB||part||'select count(1) into n from '||nvl(c.owner,inst_info.gowner)||'.'||tbl||' where '||key||'id=:new.'||c.column_name||';'||LF
         ||TB||'if n=0 then message.err(-20999,''ORA'',''02291'','''
         ||p_class_id||''','''||c.qual||'''); end if;'||LF
         ||'end if;'||LF,
         refs);
    end if;
    if nvl(p_refs,true) then
      i := hash(c.class_id);
    end if;
  elsif p_refs then
      i := hash(c.class_id);
  end if;
    if i is not null then
      refced(i):= c.class_id;
      flags(i) := v_prt;
    end if;
  end loop;
  begin
    if rlist is null then
      execute_sql('DROP TRIGGER Z#REF_'||class_table_name_,
          '   ' || message.gettext('EXEC', 'DELETING_REFERENCING_TRIGGER',p_class_id),true);
    else
      class_mgr.put_text_buf(
        'CREATE OR REPLACE TRIGGER Z#REF_'||class_table_name_||LF
        ||'BEFORE INSERT OR UPDATE OF'||substr(rlist,2)||LF
        ||'ON '||v_owner||class_table_name_||' FOR EACH ROW'||LF
        ||'declare n number; k number;'||LF
        ||'begin'||LF,
        refs,false);
      class_mgr.put_text_buf('end;',refs);
      execute_sql(refs,false,'   ' || message.gettext('EXEC', 'CREATING_REFERENCING_TRIGGER',p_class_id));
    end if;
    if slist is null then
      execute_sql('DROP TRIGGER Z#SREF_'||class_table_name_,
          '   '||message.gettext('EXEC', 'DELETING_SELF_REFCING_TRIGGER',p_class_id),true);
    else
      tbl := class_table_name_;
      if storage_mgr.is_kernel(p_class_id)='2' then
        part := 'varchar2('||constant.REF_PREC||');';
      else
        part := 'number;';
      end if;
      if v_part = '0' and storage_mgr.prt_actual or v_part = '1' then
        tbl := tbl||' partition('||tbl||'#0)';
        key := '=1000;';
      else
        part:= part||' k number:=valmgr.get_key('''||p_class_id||''');';
        key := '>=k;';
      end if;
      execute_sql('CREATE OR REPLACE TRIGGER Z#SREF_'||class_table_name_||LF
        ||'AFTER UPDATE OF'||substr(slist,2)||LF
        ||'ON '||v_owner||class_table_name_||LF
        ||'declare n number; q varchar2(700); id_ '||part||LF
        ||'begin loop id_:=part_mgr.get_update(q); exit when id_ is null;'||LF
        ||TB||'select count(1) into n from '||v_owner||tbl||' where id=id_ and key'||key||LF
        ||TB||'if n=0 then part_mgr.clear_obj_upd('''||p_class_id||''',q); end if;'||LF
        ||'end loop; end;',
          '   '||message.gettext('EXEC', 'CREATING_SELF_REFCING_TRIGGER',p_class_id));
    end if;
  exception when others then
    if sqlcode in (-6508,-4061) then raise; end if;
  end;
  if refced.count > 0 then
    i := refced.first;
    while not i is null loop
        ws(message.gettext('KRNL', 'REFERENCES_ON', refced(i),p_class_id));
        create_refced_triggers(refced(i),flags(i));
        i := refced.next(i);
    end loop;
    refced.delete;
    flags.delete;
  end if;
end;
--
procedure create_refced_triggers(p_class_id varchar2, p_ref_part boolean default false, p_refs boolean default false) is
  cursor refced is
    select ctc.qual, ctc.column_name, ct.class_id, ct.table_name, ct.param_group, ct.owner, ct.part_profile_id, c.short_name
      from class_tables ct, class_tab_columns ctc, classes c
     where ctc.target_class_id = p_class_id
       and ctc.deleted = '0' and ctc.indexed='0'
       and ctc.map_style is null and ctc.flags is null
       and ctc.base_class_id='REFERENCE'
       and nvl(c.kernel, '0')='0'
       and c.temp_type is null
       and ct.class_id=ctc.class_id
       and c.id=ctc.class_id
     union all
    select 'ID', 'ID', ct.class_id, ct.table_name, ct.param_group, ct.owner, ct.part_profile_id, c.short_name
      from class_tables ct, class_relations cr, classes c
     where cr.parent_id= p_class_id
       and cr.distance = 1
       and c.temp_type is null
       and ct.class_id = cr.child_id
       and c.id=cr.child_id
     order by 3;
    refcing "CONSTANT".refstring_table;
    flags   "CONSTANT".boolean_table;
    class_table_name_  varchar2(30);
    v_owner varchar2(32);
    refs    dbms_sql.varchar2s;
    self    varchar2(32000);
    part    varchar2(100);
    tbl     varchar2(100);
    key     varchar2(20);
    cls     varchar2(20);
    v_part  varchar2(1);
    v_prt   boolean;
    i   pls_integer;
    cnt pls_integer := 0;
begin
  begin
    select table_name,owner into class_table_name_,v_owner
      from class_tables where class_id = p_class_id;
  exception when no_data_found then
    return;
  end;
  v_owner := nvl(v_owner,inst_info.gowner)||'.';
  ws(message.gettext('KRNL', 'CREATING_REV_REFERENCE_TRIGGS',p_class_id));
  cls := chr(1);
  for c in refced loop
    i := null;
    v_prt := c.param_group='PARTITION';
  if (p_ref_part or v_prt) and c.part_profile_id is null then
    tbl := c.table_name;
    part:= null;
    if tbl=class_table_name_ then
     if v_prt then
      if self is null then
        class_mgr.put_text_buf(TB||'part_mgr.obj_delete(:old.id);'||LF,refs);
      end if;
      v_part := nvl(substr(c.short_name,26,1),'0');
      if v_part = '0' and storage_mgr.prt_actual or v_part = '1' then
        tbl := tbl||' partition('||tbl||'#0)';
        key := null;
      else
        key := 'key>=k and ';
      end if;
      self := self
         ||TB||'select count(1) into n from '||v_owner||tbl||' where '||key||c.column_name||'=id_ and rownum<2;'||LF
         ||TB||'if n>0 then part_mgr.clear_obj_del('''||p_class_id||''','''||c.qual||'''); end if;'||LF;
     end if;
    else
      key := null;
      if v_prt then
        part := nvl(substr(c.short_name,26,1),'0');
        if part = '0' and storage_mgr.prt_actual or part = '1' then
          tbl := tbl||' partition('||tbl||'#0)';
          if c.qual='ID' then
            key := 'key=1000 and ';
          end if;
          part:= null;
        else
          part:= null;
          if cls <> c.class_id then
            cls := c.class_id;
            part:= 'k:=valmgr.get_key('''||cls||'''); ';
          end if;
          key := 'key>=k and ';
        end if;
      end if;
      class_mgr.put_text_buf(
           TB||part||'select count(1) into n from '||nvl(c.owner,inst_info.gowner)||'.'||tbl||' where '||key||c.column_name||'=:old.ID and rownum<2;'||LF
         ||TB||'if n>0 then message.err(-20999,''ORA'',''02292'','''||c.class_id||''','''||c.qual||'''); end if;'||LF,
         refs);
    end if;
    if nvl(p_refs,true) then
      i := hash(c.class_id);
    end if;
  elsif p_refs then
      i := hash(c.class_id);
  end if;
    if i is not null then
      refcing(i):= c.class_id;
      flags(i)  := v_prt;
    end if;
  end loop;
  begin
    if refs.count=0 then
      execute_sql('DROP TRIGGER Z#DEL_'||class_table_name_,
          '   '||message.gettext('EXEC', 'DELETING_REFERENCED_TRIGGER',p_class_id),true);
    else
      class_mgr.put_text_buf(
        'CREATE OR REPLACE TRIGGER Z#DEL_'||class_table_name_||LF
        ||'BEFORE DELETE ON '||v_owner||class_table_name_||' FOR EACH ROW'||LF
        ||'declare n number; k number;'||LF||'begin'||LF,
        refs,false);
      class_mgr.put_text_buf('end;',refs);
      execute_sql(refs,false,'   '||message.gettext('EXEC', 'CREATING_REFERENCED_TRIGGER',p_class_id));
    end if;
    if self is null then
      execute_sql('DROP TRIGGER Z#SDEL_'||class_table_name_,
          '   '||message.gettext('EXEC', 'DELETING_SELF_REFCED_TRIGGER',p_class_id),true);
    else
      if storage_mgr.is_kernel(p_class_id)='2' then
        part := 'varchar2('||constant.REF_PREC||');';
      else
        part := 'number;';
      end if;
      if v_part = '0' and storage_mgr.prt_actual or v_part = '1' then null;
      else
        part:= part||' k number:=valmgr.get_key('''||p_class_id||''');';
      end if;
      execute_sql('CREATE OR REPLACE TRIGGER Z#SDEL_'||class_table_name_||LF
        ||'AFTER DELETE ON '||v_owner||class_table_name_||LF
        ||'declare n number; id_ '||part||LF
        ||'begin loop id_:=part_mgr.get_delete; exit when id_ is null;'||LF
        ||self||'end loop; end;',
          '   '||message.gettext('EXEC', 'CREATING_SELF_REFCED_TRIGGER',p_class_id));
    end if;
  exception when others then
    if sqlcode in (-6508,-4061) then raise; end if;
  end;
  if refcing.count > 0 then
    i := refcing.first;
    while not i is null loop
        ws(message.gettext('KRNL', 'REFERENCES_FROM', refcing(i),p_class_id));
        create_refcing_triggers(refcing(i),flags(i));
        i := refcing.next(i);
    end loop;
    refcing.delete;
    flags.delete;
  end if;
end;
--
procedure create_unique_trigger(p_class_id varchar2) is
begin
    null;
end;
--
procedure create_triggers(p_class_id varchar2, p_refs boolean default false) is
    v_part  boolean;
begin
    v_part := storage_mgr.is_partitioned(p_class_id) = storage_mgr.PART_KEY;
    ws(message.gettext('KRNL', 'CREATING_CONSISTENCY_TRIGGERS', p_class_id));
    create_refcing_triggers(p_class_id, v_part, p_refs);
    ws(message.gettext('KRNL', 'CREATING_CONSISTENCY_TRIGGERS', p_class_id));
    create_refced_triggers (p_class_id, v_part, nvl(p_refs,false) );
end;
--
procedure drop_triggers(p_class_id varchar2,p_type varchar2 default null) is
    v_type varchar2(30) := nvl(p_type,'Z#%');
    cursor trigs is
    select /*+ RULE */ trigger_name
      from user_triggers ut, class_tables ct
     where ct.class_id = p_class_id
       and ut.table_name = ct.table_name
       and ut.table_owner = nvl(ct.owner,inst_info.gowner)
       and ut.trigger_name like v_type;
begin
    ws(message.gettext('KRNL', 'DELETING_CONSISTENCY_TRIGGERS', v_type));
    for c in trigs loop
        execute_sql('DROP TRIGGER '||c.trigger_name,
             '   '||message.gettext('EXEC', 'DELETING', c.trigger_name),null);
    end loop;
end;
--
procedure delete_stuff(p_parent boolean default false,p_class varchar2 default null) is
    n   number;
    p   varchar2(30);
    pp  varchar2(30);
    tt  varchar2(70);
    tp  varchar2(70);
    cls varchar2(30) := nvl(p_class,'%');
    cl  varchar2(4000);
begin
    --verbose := false;
    for t in (
        select cr.distance, cr.child_id, cr.parent_id,
               ct.table_name, ct.param_group, ct.current_key, ct.owner,
               cp.table_name parent_table, cp.param_group parent_group, cp.current_key parent_key, cp.owner parent_owner
          from class_tables cp, class_tables ct, class_relations cr
         where ct.class_id = cr.child_id
           and cp.class_id = cr.parent_id
           and cp.class_id like cls
           and cr.distance > 0
           and exists (select /*+ NO_UNNEST */ 1 from dba_tables ut where ut.table_name=ct.table_name and ut.owner=nvl(ct.owner,inst_info.gowner) and ut.temporary='N')
           and exists (select /*+ NO_UNNEST */ 1 from dba_tables ut where ut.table_name=cp.table_name and ut.owner=nvl(cp.owner,inst_info.gowner) and ut.temporary='N')
         order by 1
        )
    loop
      begin
        p:=null; pp:=null;
        tt := nvl(t.owner,inst_info.gowner)||'.'||t.table_name;
        tp := nvl(t.parent_owner,inst_info.gowner)||'.'||t.parent_table;
        if p_parent then
          if t.parent_group='PARTITION' and t.parent_key>0 then
              pp:= ' AND P.KEY>='||t.parent_key;
          end if;
          if t.param_group like 'PART%' then
              if t.param_group='PARTVIEW' then
                  tt:= t.table_name||'#PRT';
              end if;
              if t.current_key>0 then
                  p := ' AND T.KEY>='||t.current_key;
              end if;
          end if;
          n := execute_sql('DELETE FROM '||tp||' P WHERE P.CLASS_ID='''||t.child_id||''' AND NOT EXISTS(SELECT 1 FROM '||tt||' T WHERE T.ID=P.ID'||p||')'||pp,
                           'Deleting '||tp||' through '||tt||' ('||t.distance||')');
        else
          if t.param_group='PARTITION' and t.current_key>0 then
              p := ' AND T.KEY>='||t.current_key;
          end if;
          if t.parent_group like 'PART%' then
              if t.parent_group='PARTVIEW' then
                  tp:= t.parent_table||'#PRT';
              end if;
              if t.parent_key>0 then
                  pp:= ' AND P.KEY>='||t.parent_key;
              end if;
          end if;
          n := execute_sql('DELETE FROM '||tt||' T WHERE NOT EXISTS(SELECT 1 FROM '||tp||' P WHERE P.ID=T.ID'||pp||')'||p,
                           'Deleting '||tt||' through '||tp||' ('||t.distance||')');
        end if;
        commit;
      exception when others then
        rollback;
        n := 0;
      end;
      ws('Deleted '||n||' records.');
    end loop;
  if p_parent then
    for t in (
        select ct.class_id, ct.table_name, ct.param_group, ct.current_key, ct.owner
          from class_tables ct
         where ct.class_id like cls
           and exists (select 1 from class_relations cr where cr.parent_id=ct.class_id and cr.distance>0)
           and exists (select /*+ NO_UNNEST */ 1 from dba_tables ut where ut.table_name=ct.table_name and ut.owner=nvl(ct.owner,inst_info.gowner) and ut.temporary='N')
         order by 1
        )
    loop
      begin
        p := null;
        tt:= nvl(t.owner,inst_info.gowner)||'.'||t.table_name;
        if t.param_group='PARTITION' and t.current_key>0 then
            p := ' AND KEY>='||t.current_key;
        end if;
        cl := '.';
        for c in (select child_id from class_relations where parent_id=t.class_id) loop
          cl := cl||c.child_id||'.';
        end loop;
        n := execute_sql('DELETE FROM '||tt||' WHERE INSTR('''||cl||''',''.''||CLASS_ID||''.'')=0'||p,
                         'Deleting '||tt||' through non-existing childs...');
        commit;
      exception when others then
        rollback;
        n := 0;
      end;
      ws('Deleted '||n||' records.');
    end loop;
  end if;
end;
--
procedure add_missing_records(p_parent boolean default false,p_class varchar2 default null) is
    q           varchar2(8000);
    s           varchar2(1000);
    p           varchar2(30);
    pp          varchar2(30);
    cls         varchar2(30) := nvl(p_class,'%');
    sel_table   varchar2(70);
    ins_table   varchar2(70);
    sel_class   varchar2(16);
    ins_class   varchar2(16);
    v_interface varchar2(31);
    v_type      varchar2(61);
    v_count     number;
    v_state     boolean;
    v_coll      boolean;
    v_class     boolean;
begin
    --verbose := false;
    for t in (
        select cr.distance, cr.child_id, cr.parent_id,
               ct.table_name, ct.param_group, ct.current_key, ct.owner,
               cp.table_name parent_table, cp.param_group parent_group, cp.current_key parent_key, cp.owner parent_owner
          from class_tables cp, class_tables ct, class_relations cr
         where ct.class_id = cr.child_id
           and cp.class_id = cr.parent_id
           and cp.class_id like cls
           and cr.distance > 0
           and exists (select /*+ NO_UNNEST */ 1 from dba_tables ut where ut.table_name=ct.table_name and ut.owner=nvl(ct.owner,inst_info.gowner) and ut.temporary='N')
           and exists (select /*+ NO_UNNEST */ 1 from dba_tables ut where ut.table_name=cp.table_name and ut.owner=nvl(cp.owner,inst_info.gowner) and ut.temporary='N')
         order by 1
        )
    loop
        p:=null; pp:=null;
        if p_parent then
            sel_table := nvl(t.owner,inst_info.gowner)||'.'||t.table_name;
            ins_table := nvl(t.parent_owner,inst_info.gowner)||'.'||t.parent_table;
            sel_class := t.child_id; ins_class := t.parent_id;
            if t.param_group like 'PART%' then
                if t.param_group='PARTVIEW' then
                    sel_table:= t.table_name||'#PRT';
                end if;
                if t.current_key>0 then
                    p := ' and t.key>='||t.current_key;
                end if;
            end if;
            if t.parent_group='PARTITION' and t.parent_key>0 then
                pp:= ' and p.key>='||t.parent_key;
            end if;
        else
            sel_table := nvl(t.parent_owner,inst_info.gowner)||'.'||t.parent_table;
            ins_table := nvl(t.owner,inst_info.gowner)||'.'||t.table_name;
            sel_class := t.parent_id; ins_class := t.child_id;
            if t.parent_group like 'PART%' then
                if t.parent_group='PARTVIEW' then
                    sel_table:= t.parent_table||'#PRT';
                end if;
                if t.parent_key>0 then
                    p := ' and t.key>='||t.parent_key;
                end if;
            end if;
            if t.param_group='PARTITION' and t.current_key>0 then
                pp:= ' and p.key>='||t.current_key;
            end if;
        end if;
        v_interface := class_mgr.interface_package(ins_class)||'.';
        v_type := storage_mgr.global_host_type(ins_class,true);
        v_class := false; v_coll := false; v_state := false;
        for c in (
            select class_id, column_name
              from class_tab_columns
             where class_id=sel_class and deleted='0'
               and map_style is not null and mapped_from='OBJECT'
                 )
        loop
          if    c.column_name='CLASS_ID' then v_class:=true;
          elsif c.column_name='STATE_ID' then v_state:=true;
          elsif c.column_name='COLLECTION_ID' then v_coll:=true; end if;
        end loop;
        s := null;
        if v_class then
            q := 'o.class_id:=c.class_id;'; s:=', class_id';
        else
            q := 'o.class_id:='''||t.child_id||''';';
        end if;
        if v_state then
            q := q||' o.state_id:=c.state_id;'; s:=s||', state_id';
        else
            q := q||' o.state_id:=state_;';
        end if;
        if v_coll then
            q := q||' o.collection_id:=c.collection_id;'; s:=s||', collection_id';
        else
            q := q||' o.collection_id:=null;';
        end if;
        q := '    o.id:=c.id; '||q;
        s := 'select id'||s||' from '||sel_table||' t where not exists (select 1 from '||ins_table||
             ' p where p.id=t.id'||pp||')'||p;
        if not p_parent then
            s := s||' and t.class_id='''||ins_class||'''';
        end if;
        q := 'declare o rtl.object_rec; state_ varchar2(16); n number:=0;'||LF||
             'rec '||v_type||'; rec_ '||v_type||';'||LF||
             'begin select init_state_id into state_ from classes where id='''||t.child_id||''';'||LF||
             '  for c in ('||s||') loop'||LF||q||LF||
             '    rec:=rec_; '||v_interface||'init(rec,false); '||
             v_interface||'insert$(rec,o,false,true,false); n:=n+1;'||LF||
             '  end loop; :cnt:=n; commit;'||LF||
             'end;';
        ws('Inserting '||ins_table||' through '||sel_table);
        --ws(q);
        begin
          execute immediate q using out v_count;
        exception when others then
          WS(q); WS(SQLERRM);
          rollback;
          v_count := 0;
        end;
        ws('Inserted '||v_count||' records.');
    end loop;
end;
-- Инициализирует пустые collection_id
procedure update_empty_collections (p_table varchar2 default NULL, p_column varchar2 default null,
                                    p_class varchar2 default NULL, p_once   boolean  default false,
                                    p_position pls_integer default null) is
    i   number;
    n   number;
    cnt number;
    p   varchar2(30);
    m   varchar2(30);
    o   varchar2(30);
    tab varchar2(30) := nvl(p_table, chr(1));
    col varchar2(30) := nvl(p_column,chr(1));
    cls varchar2(30) := nvl(p_class,'%');
    cursor c_colls is
        select ct.table_name,ctc.column_name,c.id,ct.param_group,ct.owner,ctc.target_class_id
          from class_tables ct, class_tab_columns ctc, classes c
         where c.id like cls
           and nvl(c.kernel,'0') <> '1'
           and ct.class_id = c.id
           and ctc.class_id= ct.class_id
           and ctc.deleted = '0'
           and ctc.map_style is null
           and ctc.base_class_id = 'COLLECTION'
           and exists (select /*+ NO_UNNEST */ 1 from dba_tables ut where ut.table_name=ct.table_name and ut.owner=nvl(ct.owner,inst_info.gowner) and ut.temporary='N')
           and (ct.table_name>tab
                or ct.table_name=tab and ctc.column_name>col)
         order by 1,2;
  t   c_colls%rowtype;
begin
  ws(message.gettext('EXEC', 'INITING_EMPTY_COLLS_START'));
  n := length(col);
  if p_once and n>1 then
      -- Перещелкиваем последний символ на предыдущий по алфавиту.
      -- Для последующего корректного запроса в курсоре в конце добавляем max символ из возможных и добиваем пробелами до 30 символов
      col := rpad(substr(col,1,n-1)||chr(ascii(substr(col,n,1))-1) || chr(127),30);
  end if;
  loop
    t.table_name := null;
    for tt in c_colls loop
      t := tt; exit;
    end loop;
    exit when t.table_name is null;
    tab:=t.table_name; col:=t.column_name; cnt:=0;
      --Если это ссылка на метакласс НИЧЕГО НЕ ДЕЛАТЬ!!!!
    select count(*) into n from classes where id=t.target_class_id and (nvl(kernel,'0')='1' or entity_id='KERNEL');
    if n = 0 then
      if t.owner is null then
        t.owner := inst_info.gowner;
      end if;
      if t.param_group like 'PART%' then
        i:=0;
        loop
          n:=null;
          for c in (select partition_name,mirror,partition_position,mirror_owner
                      from class_partitions
                     where class_id=t.id and partition_position>i
                     order by partition_position)
          loop
            n:=c.partition_position;
            p:=c.partition_name;
            m:=c.mirror;
            o:=c.mirror_owner;
            exit;
          end loop;
          exit when n is null;
          i:=n;
          if m = p then null;
          else
            begin
              n:=execute_sql(
               'UPDATE '||t.owner||'.'||tab||' PARTITION ('||p||') SET '||col||'=SEQ_ID.NEXTVAL'||LF||
               'WHERE ' ||col||' IS NULL', message.gettext('EXEC', 'COLLECTION', p||'.'||col));
              commit;
              cnt:=cnt+n;
            exception when others then
              rollback;
            end;
          end if;
          if m <> tab and (p_position = 0 or i = p_position) then
            begin
              if o is null then
                o := inst_info.gowner;
              end if;
              n:=execute_sql(
               'UPDATE '||o||'.'||m||' SET '||col||'=SEQ_ID.NEXTVAL'||LF||
               'WHERE ' ||col||' IS NULL', message.gettext('EXEC', 'COLLECTION', m||'.'||col));
              commit;
              cnt:=cnt+n;
            exception when others then
              rollback;
            end;
          end if;
        end loop;
      end if;
      if nvl(t.param_group,'X') <> 'PARTITION' then
        begin
          n:=execute_sql(
           'UPDATE '||t.owner||'.'||tab||' SET '||col||'=SEQ_ID.NEXTVAL'||LF||
           'WHERE ' ||col||' IS NULL', message.gettext('EXEC', 'COLLECTION', tab||'.'||col));
          commit;
          cnt:=cnt+n;
        exception when others then
          rollback;
        end;
      end if;
      ws(message.gettext('EXEC', 'COLLECTIONS_WERE_UPDATED', to_char(cnt)));
    else
      ws(message.gettext('EXEC', 'MISSING_METCLASS_COLLECTION', tab||'.'|| col, t.target_class_id));
    end if;
    exit when p_once;
  end loop;
  ws(message.gettext('EXEC', 'INITING_EMPTY_COLLS_FINISH'));
end;
--
function get_project_owner(p_object varchar2, p_type varchar2) return varchar2 is
begin
  for c in (select owner from project where name=p_object and type=p_type)
  loop
    return c.owner;
  end loop;
  return null;
end;
--
-- Обнуляет несуществующие ссылки
procedure update_invalid_references(p_table varchar2 default NULL, p_column varchar2 default null,
                                    p_class varchar2 default NULL, p_once   boolean  default false,
                                    p_ole boolean default false, p_position pls_integer default null) is
    i   number;
    n   number;
    cnt number;
    w   varchar2(100);
    p   varchar2(30);
    m   varchar2(30);
    o   varchar2(30);
    bcl varchar2(16);
    tab varchar2(30) := nvl(p_table, chr(1));
    col varchar2(30) := nvl(p_column,chr(1));
    cls varchar2(30) := nvl(p_class,'%');
    ref_table   varchar2(70);
    cursor c_refs is
        select ct.table_name,ctc.column_name,c.id,ct.param_group,ct.owner,ctc.target_class_id
          from class_tables ct, class_tab_columns ctc, classes c
         where c.id like cls
           and nvl(c.kernel,'0') <> '1'
           and ct.class_id = c.id
           and ctc.class_id= ct.class_id
           and ctc.deleted = '0'
           and ctc.indexed = '0'
           and ctc.map_style is null and ctc.flags is null
           and ctc.base_class_id = bcl
           and exists (select /*+ NO_UNNEST */ 1 from dba_tables ut where ut.table_name=ct.table_name and ut.owner=nvl(ct.owner,inst_info.gowner) and ut.temporary='N')
           and (ct.table_name>tab
                or ct.table_name=tab and ctc.column_name>col)
         order by 1,2;
  t   c_refs%rowtype;
begin
  if p_ole then
    ref_table := 'LONG_DATA';
    o := get_project_owner(ref_table,'TABLE');
    if o is null then
      o := nvl(get_object_schema(ref_table,'TABLE','1'),inst_info.gowner);
    end if;
    ref_table := o||'.'||ref_table;
    w  := ' AND R.OBJECT_ID=T.ID';
    bcl:= 'OLE';
  else
    bcl:= 'REFERENCE';
  end if;
  ws(message.gettext('EXEC', 'CLEARING_INVALID_'||bcl||'S'));
  n := length(col);
  if p_once and n>1 then
      -- Перещелкиваем последний символ на предыдущий по алфавиту.
      -- Для последующего корректного запроса в курсоре в конце добавляем max символ из возможных и добиваем пробелами до 30
      col := rpad(substr(col,1,n-1)||chr(ascii(substr(col,n,1))-1) || chr(127),30);
  end if;
  loop
    t.table_name := null;
    for tt in c_refs loop
      t := tt; exit;
    end loop;
    exit when t.table_name is null;
    tab:=t.table_name; col:=t.column_name;
    if t.owner is null then
      t.owner := inst_info.gowner;
    end if;
    if p_ole then null;
    else
      ref_table:=null; w:=null;
      select count(*) into n from classes where id = t.target_class_id and (nvl(kernel,'0') = '1'  or entity_id = 'KERNEL');
        --Если это ссылка на метакласс НИЧЕГО НЕ ДЕЛАТЬ!!!!
      if n = 0 then
        for r in (select table_name,param_group,current_key,owner
                    from class_tables ct
                   where class_id = t.target_class_id
                     and exists (select /*+ NO_UNNEST */ 1 from dba_tables ut where ut.table_name=ct.table_name and ut.owner=nvl(ct.owner,inst_info.gowner) and ut.temporary='N')
        ) loop
          ref_table := nvl(r.owner,inst_info.gowner)||'.'||r.table_name;
          if r.param_group like 'PART%' then
            if r.param_group='PARTVIEW' then
              ref_table := r.table_name||'#PRT';
            end if;
            if r.current_key>0 then
              w:=' AND R.KEY>='||r.current_key;
            end if;
          end if;
          exit;
        end loop;
      else
        ws(message.gettext('EXEC', 'MISSING_METCLASS_REFERENCE', tab||'.'|| col, t.target_class_id));
      end if;
    end if;
    if not ref_table is null then
      cnt:=0;
      if t.param_group like 'PART%' then
        i:=0;
        loop
          n:=null;
          for c in (select partition_name,mirror,partition_position,mirror_owner
                      from class_partitions
                     where class_id=t.id and partition_position>i
                     order by partition_position)
          loop
            n:=c.partition_position;
            p:=c.partition_name;
            m:=c.mirror;
            o:=c.mirror_owner;
            exit;
          end loop;
          exit when n is null;
          i:=n;
          if m = p then null;
          else
            begin
              n:=execute_sql(
               'UPDATE '||t.owner||'.'||tab||' PARTITION ('|| p || ') T SET T.' || col || '=NULL' || LF ||
               'WHERE T.'|| col || ' IS NOT NULL AND NOT EXISTS'|| LF ||
               '(SELECT 1 FROM '||ref_table||' R WHERE R.ID=T.' || col||w|| ')',
               bcl||' '||p||'.'||col);
              commit;
              cnt:=cnt+n;
            exception when others then
              rollback;
            end;
          end if;
          if m<>tab and (p_position = 0 or i = p_position) then
            begin
              if o is null then
                o := inst_info.gowner;
              end if;
              n:=execute_sql(
                 'UPDATE '||o||'.'||m||' T SET T.' || col || '=NULL' || LF ||
                 'WHERE T.'|| col || ' IS NOT NULL AND NOT EXISTS' || LF ||
                 '(SELECT 1 FROM '||ref_table ||' R WHERE R.ID=T.' || col||w|| ')',
                 message.gettext('EXEC', bcl, m||'.'||col));
              commit;
              cnt:=cnt+n;
            exception when others then
              rollback;
            end;
          end if;
        end loop;
      end if;
      if nvl(t.param_group,'X') <> 'PARTITION' then
        begin
          n:=execute_sql(
             'UPDATE '||t.owner||'.'||tab||' T SET T.' || col || '=NULL' || LF ||
             'WHERE T.'|| col || ' IS NOT NULL AND NOT EXISTS' || LF ||
             '(SELECT 1 FROM '||ref_table ||' R WHERE R.ID=T.' || col||w|| ')',
             message.gettext('EXEC', bcl, tab||'.'||col));
          commit;
          cnt:=cnt+n;
        exception when others then
          rollback;
        end;
      end if;
      ws(message.gettext('EXEC', 'CLEARED_VALUES', to_char(cnt)));
    end if;
    exit when p_once;
  end loop;
  ws(message.gettext('EXEC', 'CLRING_INVALID_'||bcl||'S_FIN'));
end;
--
procedure get_tbl_info(p_table in out nocopy varchar2, p_owner in out nocopy varchar2,
                       p_group in out nocopy varchar2, p_class varchar2) is
  i pls_integer;
begin
  i := instr(p_class,'.');
  if i=0 then
    begin
      select table_name, param_group, owner into p_table, p_group, p_owner
        from class_tables where class_id=p_class;
    exception when no_data_found then null;
    end;
  end if;
  if p_table is null then
    p_table := p_class;
    if i>0 then
      p_owner := substr(p_table,1,i-1);
      p_table := substr(p_table,i+1);
    else
      p_owner := get_object_schema(p_table,'TABLE','0');
    end if;
  end if;
  if p_owner is null then
    p_owner := inst_info.gowner;
  end if;
end;
--
procedure get_tbl_info(p_table in out nocopy varchar2, p_owner in out nocopy varchar2) is
  i pls_integer;
begin
  i := instr(p_table,'.');
  if i>0 then
    p_owner := substr(p_table,1,i-1);
    p_table := substr(p_table,i+1);
  else
    p_table := p_table;
    p_owner := nvl(p_owner,inst_info.gowner);
  end if;
end;
--
procedure clear_column (p_class varchar2, p_column varchar2, p_value varchar2 default null,
                        p_where varchar2 default null, p_position pls_integer default null) is
    i   number;
    n   number;
    cnt number := 0;
    p   varchar2(30);
    m   varchar2(30);
    o   varchar2(30);
    v_table varchar2(70);
    v_owner varchar2(30);
    v_group varchar2(30);
    v_where varchar2(2000);
    v_value varchar2(4000);
begin
    get_tbl_info(v_table,v_owner,v_group,p_class);
    if p_value is null then
        v_value := '=NULL';
    else
        v_value := '='||p_value;
    end if;
    if p_where is null then
        if p_value is null then
            v_where := ' IS NOT NULL';
        else
            v_where := ' IS NULL';
        end if;
        v_where := 'WHERE '||p_column||v_where;
    else
        v_where := 'WHERE '||p_where;
    end if;
    if v_group like 'PART%' then
        i:=0;
        loop
          n:=null;
          for c in (select partition_name,mirror,partition_position,mirror_owner
                      from class_partitions
                     where class_id=p_class and partition_position>i
                     order by partition_position)
          loop
            n:=c.partition_position;
            p:=c.partition_name;
            m:=c.mirror;
            o:=c.mirror_owner;
            exit;
          end loop;
          exit when n is null;
          i:=n;
          if m = p then null;
          else
            begin
              n:=execute_sql(
               'UPDATE '||v_owner||'.'||v_table ||' PARTITION ('||p||') T SET '||p_column||v_value||LF||v_where,
               message.gettext('EXEC', 'UPDATING', p||'.'||p_column||v_value));
              commit;
              cnt:=cnt+n;
            exception when others then
              rollback;
            end;
          end if;
          if m<>v_table and (p_position = 0 or i = p_position) then
            begin
              if o is null then
                o := inst_info.gowner;
              end if;
              n:=execute_sql(
               'UPDATE '||o||'.'||m||' T SET '||p_column||v_value||LF||v_where,
               message.gettext('EXEC', 'UPDATING', m||'.'||p_column||v_value));
              commit;
              cnt:=cnt+n;
            exception when others then
              rollback;
            end;
          end if;
        end loop;
    end if;
    if nvl(v_group,'X') <> 'PARTITION' then
        begin
          n:=execute_sql(
             'UPDATE '||v_owner||'.'||v_table ||' T SET '||p_column||v_value||LF||v_where,
             message.gettext('EXEC', 'UPDATING', v_table||'.'||p_column||v_value));
          commit;
          cnt:=cnt+n;
        exception when others then
          rollback;
        end;
    end if;
    ws(message.gettext('EXEC', 'COLUMN_VALUES_WERE_UPDATED', to_char(cnt)));
end;
--
procedure move_collection(p_class varchar2, p_column varchar2, p_updcol varchar2, p_conv varchar2) is
  i   pls_integer;
  cnt number := 0;
  p   varchar2(30);
  q   varchar2(4000);
  v_class varchar2(16);
  v_table varchar2(120);
  v_owner varchar2(30);
  v_group varchar2(30);
begin
  get_tbl_info(v_table,v_owner,v_group,p_class);
  if v_group='PARTITION' then
    v_table := v_table||' partition('||v_table||'#0)';
  end if;
  v_table := v_owner||'.'||v_table;
  i := instr(p_conv,'.');
  v_class := substr(p_conv,i+1);
  p := class_mgr.interface_package(v_class);
  q :=
'declare cnt pls_integer := 0;
  t1 '||p||'.'||class_mgr.make_record_tables(v_class)||';';
  if substr(p_conv,1,i-1)='TABLE' then
    q := q||'
  t2 '||inst_info.gowner||'.'||class_mgr.make_otype_table(v_class)||';
begin
  for c in (select rowid,'||p_column||' col from '||v_table||' where '||p_column||' is not null and '||p_updcol||' is null) loop
    if '||p||'.get_col$tbl(t1,c.col)>0 then
      t2:=null; '||p||'.set$rectblrow(t2,t1);
      --storage_utils.WS(t1.id.count||'' ''||t2.count);
      update '||v_table||' set '||p_updcol||' = t2 where rowid=c.rowid;';
  else
    q := q||'
  n pls_integer;
begin
  for c in (select rowid,'||p_column||' tbl,seq_id.nextval col from '||v_table||' where '||p_column||' is not null and '||p_updcol||' is null) loop
    if c.tbl.count>0 then
      '||p||'.clear$rectbl(t1);
      '||p||'.set$rowrectbl(t1,c.tbl);
      n:='||p||'.copy$rectbl(t1,c.col);
      --storage_utils.WS(c.tbl.count||'' ''||t1.id.count||'' ''||n);
      update '||v_table||' set '||p_updcol||' = c.col where rowid=c.rowid;';
  end if;
  q := q||'
      cnt := cnt+1;
    end if;
  end loop;
  storage_utils.WS(message.gettext(''EXEC'', ''CONVERTED_COLUMN_VALUES'', cnt));
end;';
  execute_sql(q);
end;
--
procedure cons_indexes(p_table varchar2,p_column varchar2,p_drop boolean,p_cascade boolean,p_owner varchar2 default null) is
  v_add varchar2(100);
  v_new varchar2(100);
  v_col varchar2(100) := p_column;
  v_own varchar2(100) := nvl(p_owner,inst_info.gowner);
  v_lst "CONSTANT".REFSTRING_TABLE;
  v_iown "CONSTANT".REFSTRING_TABLE;
  i pls_integer;
begin
  i := instr(v_col,'.');
  if i>0 then
    if p_drop is not null then
      v_new := substr(v_col,1,i-1);
    end if;
    v_col := substr(v_col,i+1);
  end if;
  if p_drop then
    if p_cascade is null then
      v_add := 'ENABLED';
    end if;
    if v_col is null then
      select /*+ RULE */ constraint_type||constraint_name bulk collect into v_lst
        from dba_constraints uc
       where table_name=p_table and owner=v_own and (v_add is null or status=v_add);
    else
      select /*+ RULE */ constraint_type||constraint_name bulk collect into v_lst
        from dba_constraints uc
       where table_name=p_table and owner=v_own and (v_add is null or status=v_add) and exists
        (select 1 from dba_cons_columns ucc
          where ucc.table_name=p_table and owner=v_own and ucc.column_name=v_col
            and ucc.constraint_name=uc.constraint_name );
    end if;
    for i in 1..v_lst.count loop
      v_add := null;
      if p_cascade is null then
        v_add := ' DISABLE';
        if storage_mgr.v10_flag and substr(v_lst(i),1,1) in ('P','U') then
          v_add := v_add||' KEEP INDEX';
        end if;
        execute_sql('ALTER TABLE '||p_table||' MODIFY CONSTRAINT '||substr(v_lst(i),2)||v_add,
          message.gettext('EXEC','DELETING_CONSTRAINT',substr(v_lst(i),2)),true,v_own);
      else
        if substr(v_lst(i),1,1) in ('P','U') then
          if p_cascade then
            v_add := ' CASCADE';
          end if;
          if storage_mgr.v10_flag then
            v_add := v_add||' DROP INDEX';
          end if;
        end if;
        execute_sql('ALTER TABLE '||p_table||' DROP CONSTRAINT '||substr(v_lst(i),2)||v_add,
          message.gettext('EXEC','DELETING',substr(v_lst(i),2)),true,v_own);
      end if;
    end loop;
    if p_cascade is null then
      v_add := build_nologging;
    else
      v_add := '1';
    end if;
    if not v_add is null then
      if v_col is null then
        select /*+ RULE */ index_name, owner bulk collect into v_lst, v_iown
          from dba_indexes ui
         where table_name=p_table and table_owner=v_own;
      else
        select /*+ RULE */ index_name, owner bulk collect into v_lst, v_iown
          from dba_indexes ui
         where table_name=p_table and table_owner=v_own and exists
          (select 1 from dba_ind_columns uic
            where uic.table_name=p_table and table_owner=v_own and uic.column_name=v_col
              and uic.index_name=ui.index_name );
      end if;
      for i in 1..v_lst.count loop
        if p_cascade is null then
          execute_sql('ALTER INDEX '||v_lst(i)||' NOLOGGING',message.gettext('EXEC','INDEX',v_lst(i)||' NOLOGGING'),true,v_iown(i));
        else
          execute_sql('DROP INDEX '||v_lst(i),message.gettext('EXEC','DELETING',v_lst(i)),true,v_iown(i));
        end if;
      end loop;
    end if;
    if p_cascade then
      v_add := null;
    else
      v_add := 'ENABLED';
    end if;
    if v_col is null then
      select /*+ RULE */ trigger_name bulk collect into v_lst from user_triggers ut
       where table_name=p_table and table_owner=v_own and (v_add is null or status=v_add);
    else
      select /*+ RULE */ trigger_name bulk collect into v_lst from user_triggers ut
       where table_name=p_table and table_owner=v_own and (v_add is null or status=v_add) and exists
        (select 1 from user_trigger_cols utc
          where utc.table_name=p_table and utc.table_owner=v_own
            and utc.column_name=v_col and utc.trigger_name=ut.trigger_name );
    end if;
    for i in 1..v_lst.count loop
      if p_cascade then
        execute_sql('DROP TRIGGER '||v_lst(i),message.gettext('EXEC','DELETING',v_lst(i)),true);
      else
        execute_sql('ALTER TRIGGER '||v_lst(i)||' DISABLE',message.gettext('EXEC','DELETING_CONSTRAINT',v_lst(i)),true);
      end if;
    end loop;
  else
    if v_col is null then
      select /*+ RULE */ trigger_name bulk collect into v_lst from user_triggers ut
       where table_name=p_table and table_owner=v_own and status='DISABLED';
    else
      select /*+ RULE */ trigger_name bulk collect into v_lst from user_triggers ut
       where table_name=p_table and table_owner=v_own and status='DISABLED' and exists
        (select 1 from user_trigger_cols utc
          where utc.table_name=p_table and utc.table_owner=v_own
            and utc.column_name=v_col and utc.trigger_name=ut.trigger_name );
    end if;
    for i in 1..v_lst.count loop
      if p_cascade is null and v_new is not null then
        if v_lst(i) not like 'USR%' then
          execute_sql('DROP TRIGGER '||v_lst(i),message.gettext('EXEC','DELETING',v_lst(i)),true);
        end if;
      else
        execute_sql('ALTER TRIGGER '||v_lst(i)||' ENABLE',message.gettext('EXEC','RESTORING',v_lst(i)),true);
      end if;
    end loop;
    if p_cascade is null or p_drop is null then
      if p_drop is null then
        if v_col is null then
          select /*+ RULE */ index_name, owner bulk collect into v_lst, v_iown
            from dba_indexes ui
           where table_name=p_table and table_owner=v_own and nvl(logging,'NO')='NO';
        else
          select /*+ RULE */ index_name, owner bulk collect into v_lst, v_iown
            from dba_indexes ui
           where table_name=p_table and table_owner=v_own and nvl(logging,'NO')='NO' and exists
            (select 1 from dba_ind_columns uic
              where uic.table_name=p_table and uic.table_owner=v_own and uic.column_name=v_col
                and uic.index_name=ui.index_name );
        end if;
      elsif v_col is null then
        select /*+ RULE */ index_name, owner bulk collect into v_lst, v_iown
          from dba_indexes ui
         where table_name=p_table and table_owner=v_own;
      else
        select /*+ RULE */ index_name, owner bulk collect into v_lst, v_iown
          from dba_indexes ui
         where table_name=p_table and table_owner=v_own and exists
          (select 1 from dba_ind_columns uic
            where uic.table_name=p_table and uic.table_owner=v_own and uic.column_name=v_col
              and uic.index_name=ui.index_name );
      end if;
      for i in 1..v_lst.count loop
        if v_new is null then
          execute_sql('ALTER INDEX '||v_lst(i)||' LOGGING',message.gettext('EXEC','INDEX',v_lst(i)||' LOGGING'),true,v_iown(i));
        else
          execute_sql('DROP INDEX '||v_lst(i),message.gettext('EXEC','DELETING',v_lst(i)),true,v_iown(i));
        end if;
      end loop;
      if p_drop is null then
        if v_col is null then
          select /*+ RULE */ constraint_name bulk collect into v_lst
            from dba_constraints uc
           where table_name=p_table and owner=v_own and (status='DISABLED' or validated<>'VALIDATED');
        else
          select /*+ RULE */ constraint_name bulk collect into v_lst
            from dba_constraints uc
           where table_name=p_table and owner=v_own and (status='DISABLED' or validated<>'VALIDATED') and exists
            (select 1 from dba_cons_columns ucc
              where ucc.table_name=p_table and owner=v_own and ucc.column_name=v_col
                and ucc.constraint_name=uc.constraint_name );
        end if;
        v_add := ' VALIDATE';
      else
        if v_col is null then
          select /*+ RULE */ constraint_name bulk collect into v_lst
            from dba_constraints uc
           where table_name=p_table and owner=v_own and status='DISABLED';
        else
          select /*+ RULE */ constraint_name bulk collect into v_lst
            from dba_constraints uc
           where table_name=p_table and owner=v_own and status='DISABLED' and exists
            (select 1 from dba_cons_columns ucc
              where ucc.table_name=p_table and owner=v_own and ucc.column_name=v_col
                and ucc.constraint_name=uc.constraint_name );
        end if;
        if v_new is null then
          v_add := build_novalidate;
        else
          v_add := null;
        end if;
      end if;
      for i in 1..v_lst.count loop
        if v_new is null then
          begin
            execute_sql('ALTER TABLE '||p_table||' MODIFY CONSTRAINT '||v_lst(i)||' ENABLE'||v_add,message.gettext('EXEC','RESTORING',v_lst(i)||v_add),false,v_own);
          exception when others then
            if v_add is null and sqlcode in (-2293,-2296,-2298,-2437) then
              execute_sql('ALTER TABLE '||p_table||' MODIFY CONSTRAINT '||v_lst(i)||' ENABLE NOVALIDATE',message.gettext('EXEC','RESTORING',v_lst(i)||' NOVALIDATE'),false,v_own);
            end if;
          end;
        else
          if v_lst(i) not like 'CHK%' then
            execute_sql('ALTER TABLE '||p_table||' DROP CONSTRAINT '||v_lst(i),message.gettext('EXEC','DELETING',v_lst(i)),true,v_own);
          end if;
        end if;
      end loop;
    end if;
  end if;
end;
--
function get_sql_type(p_type varchar2,p_size pls_integer,p_prec pls_integer,p_scale pls_integer) return varchar2 is
begin
    if p_prec is null then
      if p_size>0 and p_type in ('RAW','CHAR','VARCHAR','VARCHAR2') then
        return p_type||'('||p_size||')';
      else
        return p_type;
      end if;
    elsif p_scale<>0 then
        return p_type||'('||p_prec||','||p_scale||')';
    else
        return p_type||'('||p_prec||')';
    end if;
end;
--
function get_column_props(p_table varchar2,p_column varchar2,
          col_type  in out nocopy varchar2,
          col_len   in out nocopy pls_integer,
          col_prec  in out nocopy pls_integer,
          col_scale in out nocopy pls_integer,
          col_not_null in out nocopy varchar2,
          p_owner varchar2 default null ) return boolean is
  v_owner varchar2(30);
  v_table varchar2(30);
begin
  v_owner := p_owner;
  v_table := p_table;
  get_tbl_info(v_table,v_owner);
  select /*+ RULE */  data_type, data_type_owner, data_length, data_precision, data_scale, decode(nullable, 'Y', '0', '1')
    into col_type, v_owner, col_len, col_prec, col_scale, col_not_null
    from dba_tab_columns
   where column_name=p_column and table_name=v_table and owner=v_owner;
  if not v_owner is null then
    col_type := v_owner||'.'||col_type;
  end if;
  return true;
exception when no_data_found then
  return false;
end;
--
function get_column_type(p_table varchar2,p_column varchar2,p_prec varchar2,p_owner varchar2 default null) return varchar2 is
  v_typ varchar2(200);
  v_len pls_integer;
  v_prc pls_integer;
  v_scl pls_integer;
  v_nn  varchar2(10);
begin
  if get_column_props(p_table,p_column,v_typ,v_len,v_prc,v_scl,v_nn,p_owner) then
    if p_prec='1' then
      return get_sql_type(v_typ,v_len,v_prc,v_scl);
    end if;
    return v_typ;
  end if;
  return null;
end;
--
function get_object_schema(p_object varchar2, p_type varchar2, p_all varchar2 default null) return varchar2 is
begin
  for c in (
    select owner,object_type from dba_objects
     where object_name=p_object and (object_type=p_type or p_all='1' and object_type='SYNONYM')
       and (p_all='1' or owner in (inst_info.owner,inst_info.gowner,inst_info.downer1,inst_info.downer2))
     order by decode(owner,inst_info.owner,1,inst_info.downer1,2,inst_info.downer2,2,inst_info.gowner,3,4)
  ) loop
    if p_all='1' and c.object_type='SYNONYM' and c.owner=inst_info.owner then
      for s in (select table_owner from dba_synonyms
                 where owner=inst_info.owner and synonym_name=p_object and table_name=p_object and db_link is null)
      loop
        return s.table_owner;
      end loop;
    else
      return c.owner;
    end if;
  end loop;
  return null;
end;
--
function find_id_column(p_class varchar2,p_attr in out nocopy varchar2,p_owner in out nocopy varchar2,p_column in out nocopy varchar2) return varchar2 is
  tmp varchar2(100);
  j pls_integer;
begin
  select old_id_source,key_attr into tmp,p_attr
    from class_tables,classes
   where id=p_class and class_id=id and old_id_source is not null;
  j := instr(tmp,'.',-1);
  if j>0 then
    tmp := substr(tmp,j+1);
  end if;
  if p_attr is null then
    if j>0 then
      select class_id,column_name into p_owner,p_column
        from class_tab_columns, class_relations
       where class_id=parent_id and column_name=tmp and child_id=p_class;
    elsif tmp='OLD$ID' then
      select class_id,old_id_source into p_owner,p_column
        from class_tables, class_relations
       where class_id=parent_id and instr(old_id_source,'.')=0 and old_id_source<>tmp and child_id=p_class;
    else
      p_owner := p_class;
      p_column:= tmp;
    end if;
  else
    select class_id,column_name into p_owner,p_column
      from class_tab_columns, class_relations
     where class_id=parent_id and qual=p_attr and child_id=p_class;
  end if;
  return tmp;
exception when no_data_found then
  return null;
end;
--
function  conv_ref_table(p_class varchar2,p_column varchar2,
                         p_context boolean default null,p_mirror varchar2 default null) return varchar2 is
    v_table varchar2(100);
    v_group varchar2(30);
    v_col   varchar2(100);
    v_add   varchar2(10000);
    v_src   varchar2(30);
    v_own   varchar2(30);
    v_cls   varchar2(30);
    v_key   number;
    b boolean;
    i pls_integer;
begin
    select ct.table_name,ct.param_group,ct.current_key,ct.old_id_source,c.key_attr,ct.owner
      into v_table,v_group,v_key,v_col,v_src,v_own
      from class_tables ct, classes c where ct.class_id=c.id and c.id=p_class;
    if v_col is null then return null; end if;
    b := true;
    i := instr(v_col,'.');
    if i>0 then
      v_own := null;
      v_group := null;
      v_table := substr(v_col,1,i-1);
      v_col := substr(v_col,i+1);
      i := instr(v_col,'.');
      if i>0 then
        v_own := v_table;
        v_table := substr(v_col,1,i-1);
        v_col := substr(v_col,i+1);
      end if;
      if not v_src is null and v_col<>'OLD$ID' and v_table like '%#OLD' then
        select ct.class_id,ct.param_group,ct.current_key into v_cls,v_group,v_key
          from class_tables ct,class_attributes ca,class_relations cr
         where cr.child_id=p_class and ct.class_id=ca.class_id and ca.class_id=cr.parent_id and ca.attr_id=v_src;
        b := false;
      else
        select class_id,param_group,current_key,owner into v_cls,v_group,v_key,v_own
          from class_tables where table_name=v_table;
      end if;
    else
      v_cls := p_class;
    end if;
    if v_own is null then
      v_own := inst_info.gowner;
    end if;
    v_src := get_column_type(v_table,v_col,'0',v_own);
    if v_src is null then
      return null;
    end if;
    if b then
      if v_group like 'PART%' then
        if p_context is null then
          if not p_mirror is null or get_column_type(v_table||'#PRT',v_col,'0',inst_info.owner) is null or not class_mgr.package_errors(v_table||'#PRT') is null then
            if v_group='PARTVIEW' then v_key:=0; end if;
          else
            v_own := null;
            v_table := v_table||'#PRT';
          end if;
          if v_key>0 then
            v_add := ' AND R.KEY>='||v_key;
          end if;
        elsif storage_mgr.Prt_Actual then
          if v_group='PARTITION' then
            v_table := v_table||' PARTITION('||v_table||'#0)';
            v_add := ' AND R.KEY=1000';
          end if;
        else
          if v_group='PARTVIEW' then
            if not p_mirror is null or get_column_type(v_table||'#PRT',v_col,'0',inst_info.owner) is null or not class_mgr.package_errors(v_table||'#PRT') is null then
              v_key := null;
            else
              v_own := null;
              v_table := v_table||'#PRT';
            end if;
          end if;
          if not v_key is null then
            if p_context then
              v_add := ' AND KEY>=SYS_CONTEXT('''||inst_info.owner||'_KEYS'','''||v_cls||'.KEY'')';
            else
              v_add := ' AND KEY>=VALMGR.GET_KEY('''||v_cls||''')';
            end if;
          end if;
        end if;
      end if;
      if not p_mirror is null then
        v_group := get_column_type(p_mirror,v_col,'0');
        if p_context is null or v_group=v_src then
          v_add := v_add||LF||'UNION ALL SELECT R.ID FROM '||p_mirror||' R WHERE R.'||v_col||'=T.'||p_column;
        elsif not v_group is null then
          v_add := v_add||LF||'UNION ALL SELECT R.'||v_col||' FROM '||p_mirror||' R WHERE R.ID=T.'||p_column;
        end if;
      end if;
      if not v_own is null then
        v_table := v_own||'.'||v_table;
      end if;
      return '(SELECT R.ID FROM '||v_table||' R WHERE R.'||v_col||'=T.'||p_column||v_add||')';
    end if;
    if v_group like 'PART%' and (p_context is null or not p_mirror is null) then
      b := true;
      for c in (
        select mirror,partition_name,mirror_owner from class_partitions
         where class_id=v_cls and partition_key>=v_key and mirror is not null
         order by partition_position desc
      ) loop
        if b and c.mirror=c.partition_name then null;
        else
          v_group := null;
          if c.mirror_owner is null then
            c.mirror_owner := inst_info.gowner;
          end if;
          if get_column_type(c.mirror,v_col,'0',c.mirror_owner)=v_src then
            v_group := c.mirror;
          else
            c.mirror_owner := get_object_schema(c.mirror||'#OLD','TABLE','0');
            if not c.mirror_owner is null and get_column_type(c.mirror||'#OLD',v_col,'0',c.mirror_owner)=v_src then
              v_group := c.mirror||'#OLD';
            end if;
          end if;
          if not v_group is null then
            v_add := v_add||LF||'UNION ALL SELECT R.'||v_col||' FROM '||c.mirror_owner||'.'||v_group||' R WHERE R.ID=T.'||p_column;
          end if;
        end if;
        b := false;
      end loop;
    end if;
    if not v_own is null then
      v_table := v_own||'.'||v_table;
    end if;
    return '(SELECT R.'||v_col||' FROM '||v_table||' R WHERE R.ID=T.'||p_column||v_add||')';
exception when no_data_found then
    return null;
end;
--
function get_conv(base1 varchar2, base2 varchar2, type1 varchar2, type2 varchar2, col varchar2, len number) return varchar2 is
    conv varchar2(2000);
begin
    if base1 in ('STRING','MEMO') then
        -- PLATFORM-9550
        -- так как в общем случае конвертация NVARCHAR2 в VARCHAR2 ведет к потере данных, то это должно контролироваться разработчиком самостоятельно.
        -- мы просто подменяем автоприведение типов на явное использование to_char
        if type2 = 'NVARCHAR2' or type2 = 'NUMBER' or type2 like 'BINARY%' then
            conv := 'TO_CHAR(' || col || ')';
        elsif type2 = 'DATE' then
            conv := 'TO_CHAR(' || col || ',''' || constant.DATE_FORMAT || ''')';
        elsif type2 like 'TIMESTAMP%' then
            conv := 'TO_CHAR(' || col || ',''' || constant.TIMESTAMP_FORMAT || ''')';
        elsif type2 = 'RAW' then
            conv := 'UTL_RAW.CAST_TO_VARCHAR2(' || col || ')';
        elsif type2<>'VARCHAR2' or base1<>base2 then
            conv := col;
        end if;
        if not (conv is null or len is null) then
            conv := 'SUBSTR(' || conv || ', 1, ' || len || ')';
        end if;
    elsif base1 in ('NSTRING','NMEMO') then
        if type2 = 'VARCHAR2' or type2 = 'NUMBER' or type2 like 'BINARY%' then
            conv := 'TO_NCHAR(' || col || ')';
        elsif type2 = 'DATE' then
            conv := 'TO_NCHAR(' || col || ',''' || constant.DATE_FORMAT || ''')';
        elsif type2 like 'TIMESTAMP%' then
            conv := 'TO_NCHAR(' || col || ',''' || constant.TIMESTAMP_FORMAT || ''')';
        elsif type2 = 'RAW' then
            conv := 'UTL_RAW.CAST_TO_NVARCHAR2(' || col || ')';
        elsif type2<>'NVARCHAR2' or base1<>base2 then
            conv := col;
        end if;
        if not (conv is null or len is null) then
            conv := 'SUBSTRC(' || conv || ', 1, ' || len || ')';
        end if;
    elsif base1 = 'NUMBER' then
        if type2 = 'DATE' then
            conv := 'TO_CHAR('||col||',''J'')+TO_CHAR('||col||',''SSSSS'')/86400.0';
        elsif type2 like 'TIMESTAMP%' then
            conv := 'TO_CHAR('||col||',''J'')+TO_CHAR('||col||',''SSSSS.FF9'')/86400.0';
        elsif type2 like 'INTERVAL%' then
          if instr(type2,'YEAR') > 0 then
            conv := 'TO_CHAR(TO_TIMESTAMP(''1'',''J'')+'||col||',''J'')-1.0';
          else
            conv := 'TO_CHAR(TO_TIMESTAMP(''1'',''J'')+'||col||',''J'')+TO_CHAR(TO_TIMESTAMP(''1'',''J'')+'||col||',''SSSSS.FF9'')/86400.0-1.0';
          end if;
        elsif type2 <> 'NUMBER' and type1<>type2 then
          if type1 like 'BINARY%' then
            conv := 'TO_'||type1||'(' || col || ')';
          else
            conv := 'TO_NUMBER(' || col || ')';
          end if;
        end if;
    elsif base1 = 'DATE' then
        conv := 'NULL';
        if type1 = 'DATE' then
          if type2 in ('VARCHAR2', 'NVARCHAR2') then
            conv := 'TO_DATE(' || col || ',''' || constant.DATE_FORMAT || ''')';
          elsif type2 like 'TIMESTAMP%' then
            conv := col;
          elsif type2 = 'NUMBER' or type2 like 'BINARY%' then
            conv := 'TO_DATE(''1'',''J'')+('||col||'-1.0)';
          end if;
        elsif type1 like 'TIMESTAMP%' then
          if type2 = 'VARCHAR2' then
            conv := 'TO_TIMESTAMP(' || col || ',''' || constant.TIMESTAMP_FORMAT || ''')';
          elsif type2 = 'DATE' or type2 like 'TIMESTAMP%' then
            conv := col;
          elsif type2 = 'NUMBER' or type2 like 'BINARY%' then
            conv := 'TO_TIMESTAMP(''1'',''J'')+NUMTODSINTERVAL(('||col||'-1.0),''DAY'')';
          end if;
        elsif type1 like 'INTERVAL%' then
          if type2 = 'VARCHAR2' or substr(type1,1,12) = substr(type2,1,12) then
            conv := col;
          elsif type2 = 'NUMBER' or type2 like 'BINARY%' then
            if instr(type1,'YEAR') > 0 then
              conv := '((TO_TIMESTAMP(''1'',''J'')+NUMTODSINTERVAL(('||col||'-1.0),''DAY''))-TO_TIMESTAMP(''1'',''J''))YEAR(9) TO MONTH';
            else
              conv := 'NUMTODSINTERVAL('||col||',''DAY'')';
            end if;
          elsif type2 like 'INTERVAL%' then
            conv := '(TO_TIMESTAMP(''1'',''J'')+'||col||')-TO_TIMESTAMP(''1'',''J'')';
            if instr(type1,'YEAR') > 0 then
              conv := '('||conv||')YEAR(9) TO MONTH';
            end if;
          end if;
        end if;
    elsif base1 = 'BOOLEAN' then
        if type2 in ('VARCHAR2','NUMBER','NVARCHAR2') or type2 like 'BINARY%' then
            if type2 = 'VARCHAR2' then
              conv := col;
            elsif type2 = 'NVARCHAR2' then
              conv := 'TO_CHAR('||col||')';
            else
              conv := 'TO_CHAR(ROUND('||col||'))';
            end if;
            conv := 'DECODE('||conv||',''0'',''0'',''1'',''1'','''')';
        else
            conv := 'NULL';
        end if;
    else
      conv := 'NULL';
      if base1=base2 or base2 in ('STRING','MEMO','NSTRING','NMEMO','NUMBER') then
        if type1=type2 then
          conv := null;
        elsif type2 in ('VARCHAR2', 'NVARCHAR2') then
          if type1 = 'NUMBER' then
            conv := 'TO_NUMBER(' || col || ')';
          elsif type1 = 'RAW' then
            conv := 'UTL_RAW.CAST_TO_RAW(' || col || ')';
          elsif base1 = 'REFERENCE' then
            if type2 = 'VARCHAR2' then
               conv := 'SUBSTR(' || col || ',1,'||constant.REF_PREC||')';
            -- PLATFORM-9550
            -- Пока не введены ID типа NVARCHAR2 будем конвертировать к VARCHAR2
            elsif type2 = 'NVARCHAR2' then
               conv := 'SUBSTR(TO_CHAR(' || col || '),1,'||constant.REF_PREC||')';
            end if;
          else
            conv := col;
          end if;
        elsif type2 = 'NUMBER' or type2 like 'BINARY%' then
          if type1 = 'VARCHAR2' then
            conv := 'TO_CHAR(' || col || ')';
          elsif type1 = 'NVARCHAR2' then
            conv := 'TO_NCHAR(' || col || ')';
          elsif type1 = 'RAW' then
            conv := 'UTL_RAW.CAST_TO_RAW(' || col || ')';
          end if;
        end if;
      end if;
    end if;
    return conv;
end;
--
procedure convert_id_column(p_class varchar2,p_column varchar2,p_col_owner varchar2,p_qual varchar2) is
  v_sel varchar2(10000);
  v_typ varchar2(100);
  v_col varchar2(100);
  v_dst varchar2(100);
  v_own varchar2(100);
  v_key pls_integer;
  v_table varchar2(30);
  v_group varchar2(30);
  v_idtyp varchar2(30);
  v_prec  varchar2(10);
  v_owner varchar2(20);
  v_tbown varchar2(30);
  v_tbnam varchar2(60);
  v_self  boolean;
  v_tonum boolean;
  v_upd   boolean;
  i pls_integer;
begin
  i := instr(p_col_owner,'.');
  if i=0 then
    v_owner:= p_col_owner;
    v_self := p_class=p_col_owner;
  else
    v_owner:= substr(p_col_owner,i+1);
    v_self := false;
  end if;
  v_tonum:= p_qual is null;
  v_col := p_column;
  i := instr(v_col,'.');
  if i>0 then
    v_tbown := substr(v_col,1,i-1);
    v_col := substr(v_col,i+1);
    i := instr(v_col,'.');
    if i>0 then
      v_table := substr(v_col,1,i-1);
      v_col := substr(v_col,i+1);
    else
      v_table := v_tbown;
      v_tbown := inst_info.gowner;
    end if;
    v_upd := false;
  else
    storage_mgr.class2table(v_table,v_tbown,p_class,null);
    v_upd := true;
  end if;
  if v_table is null then
    message.error('EXEC','CLASS_HAS_NO_TABLE',p_class);
  end if;
  v_tbnam := v_tbown||'.'||v_table;
  ws(message.gettext('EXEC','UPDATING_STORAGE_START',v_table||'.ID'));
  if v_tonum then
    v_idtyp := 'NUMBER';
    v_dst := v_col;
    v_col := 'OLD$ID';
  else
    v_idtyp := 'VARCHAR2';
    v_prec:= '('||constant.REF_PREC||')';
    v_dst := 'OLD$ID';
  end if;
  if v_self then
    v_typ := get_column_type(v_table,v_col,'1',v_tbown);
    if instr(v_typ,v_idtyp)=1 then
      if not v_tonum then
        cons_indexes(v_table,v_col,true,true,v_tbown);
        clear_column(v_tbnam,v_col,'SEQ_ID.NEXTVAL');
      end if;
    elsif v_tonum then
      if not v_typ is null then
        v_typ := '1';
      end if;
    else
      message.error('PLP','TYPES_INCOMPATIBLE',v_typ,v_idtyp||v_prec);
    end if;
    if not get_column_type(v_table,v_dst,'0',v_tbown) is null then
      drop_column(v_tbnam,v_dst,true,false);
    end if;
    cons_indexes(v_table,'ID',true,true,v_tbown);
    execute_sql('ALTER TABLE '||v_tbnam||' RENAME COLUMN ID TO '||v_dst,
      message.gettext('EXEC','MOVING3',null,'ID',v_dst));
    if v_typ='1' then
      drop_column(v_tbnam,v_col,true,false);
      v_typ := null;
    end if;
    if v_typ is null then
      execute_sql('ALTER TABLE '||v_tbnam||' ADD ID '||v_idtyp||v_prec,
        message.gettext('EXEC','CREATING',v_table||'.ID'));
    else
      cons_indexes(v_table,v_col,true,true,v_tbown);
      execute_sql('ALTER TABLE '||v_tbnam||' RENAME COLUMN '||v_col||' TO ID',
        message.gettext('EXEC','MOVING3',null,v_col,'ID'));
    end if;
    if v_tonum then
      if v_typ is null then v_typ:='1=1'; else v_typ:=null; end if;
      clear_column(v_tbnam,'ID','SEQ_ID.NEXTVAL',v_typ);
    elsif v_typ<>v_idtyp||v_prec then
      execute_sql('ALTER TABLE '||v_tbnam||' MODIFY ID '||v_idtyp||v_prec,
        message.gettext('EXEC','ALTERING_TABLE',v_table));
    end if;
  else
    begin
      select table_name,owner,param_group,current_key,old_id_source
        into v_typ,v_own,v_group,v_key,v_col from class_tables where class_id=v_owner;
      if v_own is null then
        v_own := inst_info.gowner;
      end if;
    exception when no_data_found then
      message.error('EXEC','CLASS_HAS_NO_TABLE',v_owner);
    end;
    if v_col is null or nvl(get_column_type(v_typ,'ID','0',v_own),'X')<>v_idtyp then
      message.error('EXEC','PARENT_ID_NOT_CONVERTED',v_owner);
    end if;
    i := instr(v_col,'.');
    if i>0 then
      v_typ := substr(v_col,1,i-1);
      v_col := substr(v_col,i+1);
      i := instr(v_col,'.');
      if i>0 then
        v_own := v_typ;
        v_typ := substr(v_col,1,i-1);
        v_col := substr(v_col,i+1);
      else
        v_own := inst_info.gowner;
      end if;
      v_group := null;
      i := 1;
    end if;
    if v_group like 'PART%' then
      v_typ := v_typ||'#PRT';
      if storage_utils.get_column_type(v_typ,v_col,'0',inst_info.owner) is null or not class_mgr.package_errors(v_typ) is null then
        message.error('PLP','NO_TABLE_COLUMN',v_col,v_typ);
      end if;
      if v_key>0 then
        v_group := ' AND R.KEY>='||v_key;
      else
        v_group := null;
      end if;
    else
      if get_column_type(v_typ,v_col,'0',v_own) is null then
        message.error('PLP','NO_TABLE_COLUMN',v_col,v_owner);
      end if;
      v_typ := v_own||'.'||v_typ;
      v_group := null;
    end if;
    if v_tonum or i=0 then
      v_sel := '(SELECT R.ID FROM '||v_typ||' R WHERE R.'||v_col||'=T.OLD$ID'||v_group||')';
    else
      v_sel := '(SELECT R.'||v_col||' FROM '||v_typ||' R WHERE R.ID=T.OLD$ID';
      if not v_key is null then
        for c in (
          select mirror,partition_name,mirror_owner from class_partitions
           where class_id=v_owner and partition_key>=v_key and mirror is not null
           order by partition_position desc
        ) loop
          if v_group is null and c.mirror=c.partition_name then null;
          else
            if c.mirror_owner is null then
              c.mirror_owner := inst_info.gowner;
            end if;
            if get_column_type(c.mirror,v_col,'0',c.mirror_owner)=v_idtyp then
              v_group := c.mirror;
            else
              v_group := c.mirror||'#OLD';
              c.mirror_owner := get_object_schema(v_group,'TABLE','0');
              if c.mirror_owner is null or nvl(get_column_type(v_group,v_col,'0',c.mirror_owner),'!')<>v_idtyp then
                v_group := null;
              end if;
            end if;
            if not v_group is null then
              v_sel := v_sel||LF||'UNION ALL SELECT R.'||v_col||' FROM '||c.mirror_owner||'.'||v_group||' R WHERE R.ID=T.OLD$ID';
            end if;
          end if;
          v_group := '1';
        end loop;
      end if;
      v_sel := v_sel||')';
    end if;
    v_dst := 'OLD$ID';
    if not get_column_type(v_table,v_dst,'0',v_tbown) is null then
      drop_column(v_tbnam,v_dst,true,false);
    end if;
    cons_indexes(v_table,'ID',true,true,v_tbown);
    execute_sql('ALTER TABLE '||v_tbnam||' RENAME COLUMN ID TO '||v_dst,
      message.gettext('EXEC','MOVING3',null,'ID',v_dst));
    execute_sql('ALTER TABLE '||v_tbnam||' ADD ID '||v_idtyp||v_prec,
      message.gettext('EXEC','CREATING',v_table||'.ID'));
    clear_column(v_tbnam,'ID',v_sel,'1=1');
  end if;
  if v_upd then
    update class_tables set old_id_source=v_dst where class_id=p_class;
    update classes set key_attr = p_qual where id = p_class;
    if v_self then
      if v_tonum then
        v_typ := null;
      else
        v_typ := constant.PRIMARY_ATTR||'.'||p_qual;
      end if;
      update class_tab_columns set flags=v_typ where class_id=p_class and qual=p_qual;
    end if;
    insert into dependencies (referencing_id,referencing_type,referenced_id,referenced_type)
    ( select p_class,constant.CLASS_REF_TYPE,ctc.class_id,constant.CLASS_REF_TYPE
        from class_tab_columns ctc, classes c
       where ctc.target_class_id=p_class and ctc.class_id<>p_class
         and ctc.deleted='0' and ctc.indexed='0'
         and ctc.map_style is null
         and ctc.base_class_id='REFERENCE'
         and c.id=ctc.class_id
         and nvl(c.kernel,'0')='0'
         and c.temp_type is null);
    commit;
  end if;
  ws(message.gettext('EXEC','UPDATING_STORAGE_FINISH',v_table||'.ID'));
end;
--
procedure convert_obj_id(p_class varchar2,p_set_rights boolean default true) is
  v_conv  varchar2(10000);
  v_st    varchar2(128);
  v_id    varchar2(128);
  v_usr   "CONSTANT".refstring_table;
begin
  v_conv := conv_ref_table(p_class,'OBJ_ID');
  if v_conv is null then return; end if;
  begin
    select class_id into v_st from object_rights_list
     where class_id=p_class and rownum=1;
    clear_column(inst_info.owner||'.OBJECT_RIGHTS_LIST','OBJ_ID',v_conv,'EXISTS '||v_conv);
  exception when no_data_found then null;
  end;
  begin
    select class_id into v_st from object_rights_ex
     where class_id=p_class and rownum=1;
    clear_column(inst_info.owner||'.OBJECT_RIGHTS_EX','OBJ_ID',v_conv,'EXISTS '||v_conv);
  exception when no_data_found then null;
  end;
  v_conv := replace(v_conv,'T.OBJ_ID','T.OBJECT_ID');
  begin
    select class_id into v_st from long_data
     where class_id=p_class and rownum=1;
    v_id := get_project_owner('LONG_DATA','TABLE');
    if v_id is null then
      v_id := nvl(get_object_schema('LONG_DATA','TABLE','1'),inst_info.gowner);
    end if;
    clear_column(v_id||'.LONG_DATA','OBJECT_ID',v_conv,'EXISTS '||v_conv);
  exception when no_data_found then null;
  end;
  v_st := valmgr.static(p_class);
  if v_st<>'0' then
    v_conv := replace(v_conv,'T.OBJECT_ID',':ID');
    ws(message.gettext('EXEC', 'UPDATING','OBJ_STATIC.ID='||v_conv));
    begin
      execute immediate v_conv into v_id using v_st;
    exception
      when no_data_found then
        v_id := v_st;
      when others then
        ws(v_conv);
        ws(sqlerrm);
        v_id := v_st;
    end;
    if v_id<>v_st then
      valmgr.del_static(p_class);
      valmgr.put_static(p_class,v_id);
      ws(message.gettext('EXEC', 'COLUMN_VALUES_WERE_UPDATED',v_st||'->'||v_id));
    end if;
  end if;
  if p_set_rights then
    rules.Set_Subj_Class_Rights(null,p_class);
  end if;
end;
--
procedure move_column (p_class varchar2, p_column varchar2, p_updcol varchar2,
                       p_conv  varchar2, p_position pls_integer default null) is
begin
  WS(message.gettext('EXEC', 'CONVERTING_TO', p_class||'.'||p_column, p_class||'.'||p_updcol));
  if p_conv like 'TABLE.%' or p_conv like 'COLLECTION.%' then
    move_collection(p_class,p_column,p_updcol,p_conv);
  else
    clear_column(p_class,p_updcol,p_conv,p_column||' IS NOT NULL AND '||p_updcol||' IS NULL',p_position);
  end if;
end;
--
procedure init_class_id (p_class varchar2, p_clear boolean default false,
                         p_position pls_integer default null) is
    i   number;
    n   number;
    cnt number;
    p   varchar2(30);
    m   varchar2(30);
    o   varchar2(30);
    t   varchar2(70);
    w   varchar2(100);
    v_table varchar2(30);
    v_group varchar2(30);
    v_owner varchar2(30);
    v_list  varchar2(10000);
    j   pls_integer := 0;
    cls "CONSTANT".refstring_table;
    tbl "CONSTANT".string_table;
begin
    select table_name, param_group, owner into v_table, v_group, v_owner
      from class_tables where class_id=p_class;
    if p_clear then
        clear_column(p_class,'CLASS_ID', null, null, p_position);
    end if;
    if v_owner is null then
        v_owner := inst_info.gowner;
    end if;
    for c in (
        select class_id,table_name,param_group,current_key,owner
          from class_relations cr, class_tables ct
         where parent_id=p_class and distance>0 and class_id=child_id
           and exists (select /*+ NO_UNNEST */ 1 from dba_tables ut where ut.table_name=ct.table_name and ut.owner=nvl(ct.owner,inst_info.gowner) and ut.temporary='N')
         order by distance desc
    ) loop
        v_list := v_list||','''||c.class_id||'''';
        w := null;
        j := j+1;
        t := nvl(c.owner,inst_info.gowner)||'.'||c.table_name;
        if c.param_group like 'PART%' then
          if c.param_group='PARTVIEW' then
            t := c.table_name||'#PRT';
          end if;
          if c.current_key>0 then
            w := ' AND S.KEY>='||c.current_key;
          end if;
        end if;
        cls(j) := c.class_id;
        tbl(j) := ' D SET CLASS_ID='''||c.class_id||''''||LF||
          'WHERE (CLASS_ID IS NULL OR CLASS_ID NOT IN ('||substr(v_list,2)||'))'||LF||
          'AND EXISTS (SELECT 1 FROM '||t||' S WHERE S.ID=D.ID'||w||')';
    end loop;
    v_list := ''''||p_class||''''||v_list;
    j := j+1;
    cls(j) := p_class;
    tbl(j) := ' D SET CLASS_ID='''||p_class||''''||LF||
          'WHERE CLASS_ID IS NULL OR CLASS_ID NOT IN ('||v_list||')';
    if v_group like 'PART%' then
        i:=0;
        loop
          n:=null;
          for c in (select partition_name,mirror,partition_position,mirror_owner
                      from class_partitions
                     where class_id=p_class and partition_position>i
                     order by partition_position)
          loop
            n:=c.partition_position;
            p:=c.partition_name;
            m:=c.mirror;
            o:=c.mirror_owner;
            exit;
          end loop;
          exit when n is null;
          i:=n;
          if m = p then null;
          else
            for t in 1..j loop
              begin
                cnt:=execute_sql('UPDATE '||v_owner||'.'||v_table||' PARTITION ('||p||')'||tbl(t),
                    message.gettext('EXEC', 'UPDATING_CLASS_ID', v_table||'.'||p, cls(t)));
                ws(message.gettext('EXEC', 'ROWS_WERE_UPDATED5', cnt, v_table||'.'||p, cls(t)));
                commit;
              exception when others then
                rollback;
              end;
            end loop;
          end if;
          if m<>v_table and (p_position = 0 or i = p_position) then
              if o is null then
                o := inst_info.gowner;
              end if;
              for t in 1..j loop
                begin
                  cnt:=execute_sql('UPDATE '||o||'.'||m||tbl(t),
                        message.gettext('EXEC', 'UPDATING_CLASS_ID', m, cls(t)));
                  ws(message.gettext('EXEC', 'ROWS_WERE_UPDATED5', cnt, m, cls(t)));
                  commit;
                exception when others then
                  rollback;
                end;
              end loop;
          end if;
        end loop;
    end if;
    if nvl(v_group,'X')<>'PARTITION' then
        for t in 1..j loop
          begin
            cnt:=execute_sql('UPDATE '||v_owner||'.'||v_table||tbl(t),
                message.gettext('EXEC', 'UPDATING_CLASS_ID', v_table, cls(t)));
            ws(message.gettext('EXEC', 'ROWS_WERE_UPDATED5', cnt, v_table, cls(t)));
            commit;
          exception when others then
            rollback;
          end;
        end loop;
    end if;
    cls.delete;
    tbl.delete;
end;
--Поиск/удаление мусора в БД - потеряные OLE-объекты
procedure lost_oles(act_ varchar2 default 'SHOW',p_verbose boolean default true,p_pipe_name varchar2 default 'DEBUG') is
    qc varchar2(32767);
    p  varchar2(200);
    tt varchar2(70);
    del boolean := upper(ltrim(rtrim(act_))) like 'DEL%';
    cnt number;
    cnt_ole number;
    cnt_del number;
    cnt_all number := 0;
    cnt_all_del number := 0;
    t   "CONSTANT".refstring_table;
    i   number := 0;
begin
    verbose := p_verbose;
    pipe_name := p_pipe_name;
    ws(message.gettext('KRNL', 'SEARCHING_LOST_OLES'));
    for c in (select distinct class_id from long_data) loop
        i := i+1;
        t(i) := c.class_id;
    end loop;
    for j in 1..i loop
        select count(1) into cnt_ole from long_data where class_id=t(j);
        qc := null; cnt := 0; cnt_del := 0;
        for c in (select ct.table_name, ct.param_group, ct.owner, ct.current_key, ctc.column_name
                    from class_tables ct, class_tab_columns ctc, class_relations cr
                   where cr.child_id = t(j)
                     and ct.class_id = cr.parent_id
                     and ctc.class_id= ct.class_id
                     and ctc.deleted = '0'
                     and ctc.map_style is null
                     and ctc.base_class_id = 'OLE'
                     and exists (select /*+ NO_UNNEST */ 1 from dba_tables ut where ut.table_name=ct.table_name and ut.owner=nvl(ct.owner,inst_info.gowner) and ut.temporary='N')
        ) loop
            tt:=nvl(c.owner,inst_info.gowner)||'.'||c.table_name; p:=null;
            if c.param_group like 'PART%' then
              if c.param_group='PARTVIEW' then
                tt:= c.table_name||'#PRT';
              end if;
              if c.current_key>0 then
                p := ' and T.KEY>='||c.current_key;
              end if;
            end if;
            qc := qc||LF||'and not exists (select 1 from '||tt||' T where T.'||c.column_name||'=R.ID and T.ID=R.OBJECT_ID'||p||')';
        end loop;
        --
        begin
          if qc is null then
            cnt:= cnt_ole;
            if del then
                delete long_data where class_id=t(j);
                cnt_del := sql%rowcount;
                commit;
            end if;
          else
            qc := 'LONG_DATA R where R.CLASS_ID='''||t(j)||''''||qc;
            execute immediate 'select count(1) from '||qc into cnt;
            if del then
                execute immediate 'delete '||qc;
                cnt_del := sql%rowcount;
                commit;
            end if;
          end if;
        exception when others then
          if del then
            rollback;
          end if;
        end;
        --
        if cnt > 0 then
            ws(LF||message.gettext('KRNL', 'CLASS_OLES_REPORT',
                t(j), to_char(cnt_ole), to_char(cnt), to_char(cnt_del)));
        end if;
        cnt_all := cnt_all + cnt;
        cnt_all_del:= cnt_all_del + cnt_del;
    end loop;
    t.delete;
    ws(message.gettext('KRNL', 'CLASS_OLES_REPORT_TOTAL',
        to_char(cnt_all), to_char(cnt_all_del)));
end;
--Поиск/удаление мусора в БД - потеряные права на экземпляры
procedure lost_rights(act_ varchar2 default 'SHOW',p_verbose boolean default true,p_pipe_name varchar2 default 'DEBUG') is
    qc varchar2(32767);
    p  varchar2(200);
    tb varchar2(20);
    tt varchar2(70);
    del boolean := upper(ltrim(rtrim(act_))) like 'DEL%';
    cnt number;
    cnt_elm number;
    cnt_del number;
    cnt_all number;
    cnt_all_del number;
    cur ref_cursor;
    t   "CONSTANT".refstring_table;
    i   number := 0;
begin
  verbose := p_verbose;
  pipe_name := p_pipe_name;
  ws(message.gettext('KRNL', 'SEARCHING_LOST_RIGHTS'));
  for r in 1..3 loop
    if r=1 then
        open cur for select distinct class_id from object_rights;
        tb := 'OBJECT_RIGHTS';
        ws(message.gettext('KRNL', 'OBJECT_RIGHTS', tb));
    elsif r=2 then
        open cur for select distinct class_id from object_rights_list;
        tb := 'OBJECT_RIGHTS_LIST';
        ws(message.gettext('KRNL', 'OBJECT_RIGHTS_LIST', tb));
    elsif r=3 then
        open cur for select distinct class_id from object_rights_ex;
        tb := 'OBJECT_RIGHTS_EX';
        ws(message.gettext('KRNL', 'OBJECT_RIGHTS_EX', tb));
    end if;
    t.delete; i:=0;
    loop
        fetch cur into p;
        exit when cur%notfound;
        i := i+1;
        t(i) := p;
    end loop;
    close cur;
    cnt_all := 0; cnt_all_del := 0;
    for j in 1..i loop
        if r=1 then
            select count(1) into cnt_elm from object_rights where class_id=t(j);
        elsif r=2 then
            select count(1) into cnt_elm from object_rights_list where class_id=t(j);
        elsif r=3 then
            select count(1) into cnt_elm from object_rights_ex where class_id=t(j);
        end if;
        qc := null; cnt := 0; cnt_del := 0;
        for c in (select ct.table_name, ct.param_group, ct.current_key, ct.owner
                    from class_tables ct
                   where ct.class_id = t(j) and exists
                     (select /*+ NO_UNNEST */ 1 from dba_tables ut where ut.table_name=ct.table_name and ut.owner=nvl(ct.owner,inst_info.gowner) and ut.temporary='N')
        ) loop
            tt:=nvl(c.owner,inst_info.gowner)||'.'||c.table_name; p:=null;
            if c.param_group like 'PART%' then
              if c.param_group='PARTVIEW' then
                tt:= c.table_name||'#PRT';
              end if;
              if c.current_key>0 then
                p := ' and T.KEY>='||c.current_key;
              end if;
            end if;
            qc := LF||'and not exists (select 1 from '||tt||' T where T.ID=R.OBJ_ID'||p||')';
        end loop;
        --
        begin
          if qc is null then
            cnt:= cnt_elm;
            if del then
                if r=1 then
                    delete object_rights where class_id=t(j);
                elsif r=2 then
                    delete object_rights_list where class_id=t(j);
                elsif r=3 then
                    delete object_rights_ex where class_id=t(j);
                end if;
                cnt_del := sql%rowcount;
                commit;
            end if;
          else
            qc := tb||' R where R.CLASS_ID='''||t(j)||''''||qc;
            execute immediate 'select count(1) from '||qc into cnt;
            if del then
                execute immediate 'delete '||qc;
                cnt_del := sql%rowcount;
                commit;
            end if;
          end if;
        exception when others then
          if del then
            rollback;
          end if;
        end;
        --
        if cnt > 0 then
            ws(LF||message.gettext('KRNL', 'OBJECT_RIGHTS_REPORT',
                t(j), to_char(cnt_elm), to_char(cnt), to_char(cnt_del)));
        end if;
        cnt_all := cnt_all + cnt;
        cnt_all_del:= cnt_all_del + cnt_del;
    end loop;
    t.delete;
    ws(message.gettext('KRNL', 'OBJECT_RIGHTS_REPORT_TOTAL',
        tb, to_char(cnt_all), to_char(cnt_all_del), tb));
  end loop;
  ws(message.gettext('KRNL', 'SEARCHING_IS_COMPLETED'));
end;
--
procedure clear_diarys is
begin
    null;
end;
--
function has_table(table_name varchar2) return boolean is
  hasTable number;
begin
  select count(*) into hasTable from user_objects uo where uo.OBJECT_NAME=table_name;
  if hasTable = 1 then
    return true;
  else
    return false;
  end if;
end;
--
-- Поиск констрейнтов столбца таблицы по шаблону текста 
-- Возвращает количество найденных констрейнтов
function search_column_constraints(p_table varchar2, p_column varchar2, p_condition_pattern varchar2, p_constraint_name out varchar2, p_owner varchar2 default null) return pls_integer is
v_owner varchar2(30);
v_table varchar2(30);
v_result pls_integer;
begin
    v_result := 0;
    p_constraint_name := null;
    if p_condition_pattern is null then
        return v_result;
    end if;
    v_table := p_table;
    get_tbl_info(v_table,v_owner);
    for x in ( select t1.constraint_name, t1.search_condition
                      from user_constraints t1, user_cons_columns t2
                      where t1.owner=t2.owner
                      and t1.table_name=t2.table_name
                      and t1.constraint_name=t2.constraint_name
                      and t1.constraint_type='C'
                      and t2.table_name=v_table
                      and t2.owner=v_owner
                      and t2.column_name=p_column
             ) loop
        if x.search_condition like p_condition_pattern then
            v_result := v_result + 1;
            if v_result > 1 then
                p_constraint_name := p_constraint_name || ';';
            end if;
            p_constraint_name := x.constraint_name;
        end if;
    end loop;
    return v_result;  
end;

-- Получает значение свойства NULLABLE у колонки реквизита
function get_column_nullable(p_table varchar2, p_column varchar2, p_owner varchar2 default null) return boolean is
v_owner varchar2(30);
v_table varchar2(30);
i pls_integer;
v_nullable varchar2(1);
v_constraint_names varchar2(32000);
begin
    v_table := p_table;
    get_tbl_info(v_table,v_owner);
    
    begin
        select decode(nullable, 'Y', '1', '0')
            into v_nullable 
            from dba_tab_columns
            where owner=v_owner
            and table_name=v_table
            and column_name=p_column;
        -- Проверим, есть ли констрейнт NOT NULL на столбец 
        -- Проверяет только констрейнты, добавленные командой NOT NULL, пользовательские игнорирует ()
        if v_nullable= '1' then
            if search_column_constraints(v_table, p_column, '"'||upper(p_column)||'" IS NOT NULL', v_constraint_names) > 0 then
                v_nullable := '0';
            end if;
        end if;
    exception 
        when NO_DATA_FOUND then 
            return null; -- Не нашли столбец в таблице - вернем null
    end;
    return rtl.char_bool(v_nullable);
end;
--
-- Выставляет значение свойства NULLABLE у колонки реквизита
procedure set_column_nullable(p_table varchar2, p_column varchar2, p_class varchar2, p_qual varchar2, p_nullable boolean) is
v_nullable     varchar2(1);
v_col_nullable boolean;
v_command      varchar2(1000);
v_column_info  class_utils.COLUMN_DEFINITION;
begin
    v_col_nullable := get_column_nullable(p_table, p_column);
    if p_nullable and not v_col_nullable then
        v_command := 'NULL';
        v_nullable := '1';
    elsif not p_nullable and v_col_nullable then
        if class_utils.get_column_info(p_class, p_qual, v_column_info) then
            if v_column_info.base = 'COLLECTION' then
                -- Для реквизита-массива делаем NOVALIDATE
                v_command := 'NOT NULL NOVALIDATE';
            else
                -- Для остальных - VALIDATE
                v_command := 'NOT NULL VALIDATE';
            end if;    
            v_nullable := '0';
        end if;
    end if;
    if v_command is not null then
        update CLASS_TAB_COLUMNS t set t.nullable=v_nullable where class_id=p_class and qual=p_qual;
        execute_sql('ALTER TABLE '||p_table||' MODIFY '||p_column||' '||v_command);
    end if;
end;
--
-- Переименование констрейнта
procedure rename_constraint(p_table varchar2, p_constraint_name_old varchar2, p_constraint_name_new varchar2) is
  v_res number;
  v_sql varchar2(32767);
begin
  v_sql := utils.str_format('ALTER TABLE {1} RENAME CONSTRAINT {2} to {3}', p_table, p_constraint_name_old, p_constraint_name_new);
  v_res := execute_sql(v_sql, message.gettext('EXEC','RENAMING_CONSTRAINT',p_table, p_constraint_name_old, p_constraint_name_new),true,null);
exception when others then
  null;
end;
--
end;
/
show err package body storage_utils
