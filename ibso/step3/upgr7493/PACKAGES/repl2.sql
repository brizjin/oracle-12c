prompt repl_mgr body
create or replace package body
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/repl2.sql $
 *  $Author: peunova $
 *  $Revision: 126852 $
 *  $Date:: 2016-11-07 11:41:23 #$
 */
repl_mgr as
--
    LF constant varchar2(1) := chr(10);
    TB constant varchar2(1) := chr(9);
    sc_logging  boolean := substr(nvl(stdio.setting('SCRIPTS_LOGGING'),'NO'),1,1) in ('Y','1');
    type names_tbl  is table of varchar2(30)   index by binary_integer;
procedure create_class_trigger(p_class  varchar2, p_bulk_repl boolean default false) is
    s   varchar2(32767);
    ss  varchar2(32767);
    sss  varchar2(32767);
    t   varchar2(30);
    k   varchar2(1);
    p   varchar2(10);
    x   varchar2(30);
    err varchar2(32767);
    type t_sp is table of varchar(30000) index by pls_integer;
    s_p  t_sp;
    s_p2  t_sp;
    s_p3  t_sp;
    i pls_integer;
    i2 pls_integer;
    i3 pls_integer;
    sTmp varchar(2000);
    txt_buf     dbms_sql.varchar2s;
    b_ins_err boolean:=false;
    b_upd_err boolean:=false;
    b_del_err boolean:=false;
    b_collection boolean;
    b_class_id boolean;
    s_class_id varchar2(100);
    s_context varchar2(100);
    l_is_table_have_id number(1) := 1;

    function get_pk_is_rowid(p_class varchar2) return number
      is
      l_cursor integer := 0;
      l_version system_options.version%type;
      l_res number(1) := 1;
      l_status number;
      begin
        select nvl(min(version),'') into l_version from system_options where ID = 'CORE';

        if(l_version is null or
    to_number(replace(inst_info.get_version(),'.','')) *
      to_number('1e'||(case when length(inst_info.get_version()) - length(replace(inst_info.get_version(),'.',''))< 3
         then 3 - (length(inst_info.get_version()) - length(replace(inst_info.get_version(),'.',''))) else  0 end))
      < 7310 *
      to_number('1e'||(case when length(inst_info.get_version()) - length(replace(inst_info.get_version(),'.',''))>= 3
        then (length(inst_info.get_version()) - length(replace(inst_info.get_version(),'.','')))-3 else  0 end))) then
          return 1;
        end if;

        l_cursor := dbms_sql.open_cursor();
        dbms_sql.parse(l_cursor,
                       'begin
                          :res := case lib.pk_is_rowid(:p_class) when FALSE then 1 else 0 end;
                        end;',
                        dbms_sql.native);
        dbms_sql.bind_variable(l_cursor, ':res', l_res);
        dbms_sql.bind_variable(l_cursor, ':p_class', p_class);

        l_status := dbms_sql.execute(l_cursor);

        dbms_sql.variable_value(l_cursor, ':res', l_res);
        dbms_sql.close_cursor(l_cursor);

      return  l_res;
       exception
         when others then
           if(l_cursor > 0) then
              dbms_sql.close_cursor(l_cursor);
              return 1;
           end if;
      end;
begin
    select table_name into t from class_tables where class_id=p_class;
    -- core version when first appeared ROWID in lib package
    l_is_table_have_id := get_pk_is_rowid(p_class);

    i:=1; i2:=1; i3:=1;
    s_p(i):= null;
    s_p2(i2):= TB||case l_is_table_have_id when 1 then 'n.id := :new.id;' else 'n_rowid := :new.rowid;'end||LF;
    s_p3(i3):= TB||case l_is_table_have_id when 1 then 'o.id := :old.id;' else 'o_rowid := :old.rowid;'end||LF||
               TB||'o.sn:= :old.sn;'||LF;
    sss:=TB||'if :old.sn is not null then w(''$SN$'',''N'',:old.sn); end if;'||LF;
    for c in (select table_name,column_name,qual,base_class_id,self_class_id
                from class_tab_columns
               where class_id=p_class and deleted='0' and base_class_id not in ('TABLE', 'OLE')
                    and not (base_class_id='D' and self_class_id like 'INTERVAL%') -- тип INTERVAL не поддерживается
                    and upper(flags || chr(0)) not like 'A.%'
                    and  upper(flags || chr(0)) not like 'P.%'
               union all
              select table_name,'KEY','SYS$KEY','NUMBER','NUMBER'
                from class_tab_columns
               where  lib.has_partitions(substr(table_name,3))='1' and class_id=p_class and rownum = 1)
    loop
        if t is null then t:=c.table_name; end if;
        if b_collection is null and c.column_name='COLLECTION_ID' then
          b_collection:=true;
        end if;
        if b_class_id is null and c.column_name='CLASS_ID' then
          b_class_id:=true;
        end if;

        k := substr(c.base_class_id,1,1);
        p := null; x := null;
        if k='D' then   -- Date2Char
            if c.self_class_id not like 'TIMESTAMP%' then
              p := 'to_char('; x:=',''YYYYMMDDSSSSS'')';
            else
              if c.self_class_id='TIMESTAMP_TZ' then
                k:= 'Z';
                p := 'to_char('; x:=',''YYYYMMDDSSSSS.FFTZH:TZM'')';
              else
                k:= 'T';
                p := 'to_char('; x:=',''YYYYMMDDSSSSS.FF'')';
              end if;
            end if;
        end if;

        if not b_upd_err then
          begin
            -- формирование триггера на UPDATE без вызова пакета
            if(c.column_name <> 'KEY') then 
              s := s||TB||'p:='||p||':old.'||c.column_name||x||'; v:='||p||':new.'||c.column_name||x
                ||'; if p is null and v is null or p=v then null; else w('''||c.qual||''','''||k||'''); end if;'||LF; 
            else           
              s := s||TB||'p:='||p||':old.'||c.column_name||x||'; v:='||p||':new.'||c.column_name||x
                ||'; w('''||c.qual||''','''||k||'''); '||LF;             
            end if; 
                /*-- CORESAT-227 Журналировать факт апдейта, а не изменения данных
                if sc_logging then
                  s := s||TB||'p:='||p||':old.'||c.column_name||x||'; v:='||p||':new.'||c.column_name||x
                        ||'; if not(UPDATING('''||c.column_name||''')) and (p is null and v is null or p=v) then null; else w('''||c.qual||''','''||k||'''); end if;'||LF;
                else
                  s := s||TB||'p:='||p||':old.'||c.column_name||x||'; v:='||p||':new.'||c.column_name||x
                        ||'; if p is null and v is null or p=v then null; else w('''||c.qual||''','''||k||'''); end if;'||LF;
                end if;*/
          exception when others then
            b_upd_err:= true;
          end;
          if length(s)>31000 then
            b_upd_err:= true;
          end if;
        end if;

        if not b_ins_err then
          begin
            -- формирование триггера на INSERT без вызова пакета
            ss:=ss||TB||'if :new.'||c.column_name||' is not null then w('''||c.qual||''','''||k||''','||p||':new.'||c.column_name||x||'); end if;'||LF;
          exception when others then
            b_ins_err:= true;
          end;
          if length(ss)>31000 then
            b_ins_err:= true;
          end if;
        end if;

        -- для формирования триггера на UPDATE с вызовом пакета
        begin
          sTmp:= TB||'o.'|| c.column_name || ':='||':old.'||c.column_name ||';n.'|| c.column_name || ':='||':new.'||c.column_name ||';'||LF;
          if nvl(length(s_p(i)),0)+length(sTmp)<29900 then
            s_p(i) := s_p(i)||sTmp;
          else
            s_p(i):= TB||case l_is_table_have_id when 1 then 'o.id:=:old.id;n.id:=:new.id;' else 'o_rowid := :old.rowid; n_rowid := :new.rowid;'end|| LF || s_p(i);
            i:= i+1;
            s_p(i):= sTmp;
          end if;
        end;

        -- для формирования триггера на INSERT с вызовом пакета
        begin
          sTmp:= TB||'n.'|| c.column_name || ':='||':new.'||c.column_name ||';'||LF;
          s_p2(i2):= s_p2(i2)||sTmp;
        exception when others then
          i2:= i2+1;
          s_p2(i2):= TB||case l_is_table_have_id when 1 then 'n.id:= :new.id;' else 'n_rowid:= :new.rowid;'end||LF||sTmp;
        end;

        if sc_logging  then
          if not b_del_err then
            begin
              -- формирование триггера на DELETE без вызова пакета
              sss:=sss||TB||'if :old.'||c.column_name||' is not null then w('''||c.qual||''','''||k||''','||p||':old.'||c.column_name||x||'); end if;'||LF;
            exception when others then
              b_del_err:= true;
            end;
            if length(sss)>31000 then
              b_del_err:= true;
            end if;
          end if;
          -- для формирования триггера на DELETE с вызовом пакета
          begin
            sTmp:= TB||'o.'|| c.column_name || ':='||':old.'||c.column_name ||';'||LF;
            s_p3(i3):= s_p3(i3)||sTmp;
          exception when others then
            i3:= i3+1;
            s_p3(i3):= TB||case l_is_table_have_id when 1 then 'o.id:= :old.id;' else 'o_rowid:= :old.rowid;'end||LF||
                       TB||'o.sn:= :old.sn;'||LF||sTmp;
          end;
        end if;

        /*-- CORESAT-227 Журналировать факт апдейта, а не изменения данных
        if sc_logging then
          lib.put_buf(TB||'p:='||p||'old_.'||c.column_name||x||'; v:='||p||'new_.'||c.column_name||x
                      ||'; if not (UPDATING('''||c.column_name||''')) and (p is null and v is null or p=v) then null; else w_('''||c.qual||''','''||k||'''); end if;'||LF,txt_buf);
        else
          lib.put_buf(TB||'p:='||p||'old_.'||c.column_name||x||'; v:='||p||'new_.'||c.column_name||x
                      ||'; if p is null and v is null or p=v then null; else w_('''||c.qual||''','''||k||'''); end if;'||LF,txt_buf);
        end if;*/

        -- сохранение в буфер для создания пакета (заранее неизвестно понадобится или нет)
        if(c.column_name <> 'KEY') then 
          lib.put_buf(TB||'p:='||p||'old_.'||c.column_name||x||'; v:='||p||'new_.'||c.column_name||x
                    ||'; if p is null and v is null or p=v then null; else w_('''||c.qual||''','''||k||'''); end if;'||LF,txt_buf);
        else
          lib.put_buf(TB||'p:='||p||'old_.'||c.column_name||x||'; v:='||p||'new_.'||c.column_name||x
                    ||'; w_('''||c.qual||''','''||k||''');'||LF,txt_buf);
        end if;
    end loop;

    if b_class_id then
      s_class_id:= ':new.class_id';
    else
      s_class_id:= 'c';
    end if;
    s_context:= inst_info.get_version;
    if to_number(substr(s_context,1,instr(s_context,'.',1,2)-1))<7.2 then
      s_context:= 'sys_context('''||INST_INFO.Owner|| '_SYSTEM'',''ID'')';
    else
      s_context:= 'rtl.userid';
    end if;
    if b_upd_err or b_ins_err or b_del_err then
      -- create package
      repl_utils.execute_sql(
        'CREATE OR REPLACE PACKAGE REP$' || t || LF ||
        'as ' || LF ||
        'procedure w(new_ in out nocopy ' || t ||'%rowtype, new_rowid in out varchar2, old_ in out nocopy ' || t || '%rowtype, old_rowid in out varchar2, sEvent in varchar2 default ''U'');' || LF ||
        'end;','Creating package REP$'||t,true);
      -- create package body
      lib.put_buf('end;' || LF || LF || 'end;',txt_buf);
      lib.put_buf('CREATE OR REPLACE PACKAGE BODY REP$' || t || LF ||
                  'as ' || LF ||
                  'procedure w(new_ in out nocopy ' || t ||'%rowtype, new_rowid in out varchar2, old_ in out nocopy ' || t || '%rowtype, old_rowid in out varchar2, sEvent in varchar2 default ''U'') is' ||LF||
                  case when sc_logging and b_collection then
                  'c varchar2(16); o varchar2(128); p varchar2(4000); v varchar2(4000); n number; r rtl.object_rec;'||LF
                  else
                  'c varchar2(16); o varchar2(128); p varchar2(4000); v varchar2(4000); n number;'||LF
                  end||
                  'procedure w_(q varchar2,b varchar2) is'||LF||
                  'begin'||LF||
                    case when sc_logging then
                      TB||'if nvl(sys_context('''||INST_INFO.Owner || '_USER'', ''$SCMGR_RECORD$''),0)<1 and '||LF
                      ||TB||' nvl(sys_context('''||INST_INFO.Owner || '_USER'', ''$SCMGR_PLAY$''),0)<1 and '||LF||
                      case when b_collection then
                        TB||' nvl(sys_context('''||INST_INFO.Owner || '_SCMGR'', ''$PROTECT$''),''0'')=''1'' then '||LF
                      ||TB||TB||'if nvl(sys_context('''||INST_INFO.Owner || '_SCMGR'', old_.COLLECTION_ID),''0'')=''1'' then'||LF
                      ||TB||TB||TB||'r:=rtl.get_parent(old_.COLLECTION_ID,'''||p_class||''');'||LF
                      ||TB||TB||TB||'message.err(-20999,constant.EXEC_ERROR,''OBJ_PROTECTED'',r.id,''Z#''||r.class_id);'||LF
                      ||TB||TB||'elsif nvl(sys_context('''||INST_INFO.Owner || '_SCMGR'', new_.COLLECTION_ID),''0'')=''1'' then'||LF
                      ||TB||TB||TB||'r:=rtl.get_parent(new_.COLLECTION_ID,'''||p_class||''');'||LF
                      ||TB||TB||TB||'message.err(-20999,constant.EXEC_ERROR,''OBJ_PROTECTED'',r.id,''Z#''||r.class_id);'||LF
                      ||TB||TB||'end if;'||LF
                      ||TB||TB||'if nvl(sys_context('''||INST_INFO.Owner || '_SCMGR'','|| case l_is_table_have_id when 1 then 'new_.ID' else 'new_rowid' end||'),''0'')=''1'' then'||LF
                      ||TB||TB||TB||'message.err(-20999,constant.EXEC_ERROR,''OBJ_PROTECTED'','||case l_is_table_have_id when 1 then 'new_.ID' else 'new_rowid' end||','''||t||''');'||LF
                      ||TB||TB||'end if;'||LF
                      ||TB||'end if;'||LF
                      else
                        TB||' nvl(sys_context('''||INST_INFO.Owner || '_SCMGR'', ''$PROTECT$''),''0'')=''1'' and '||LF
                      ||TB||' nvl(sys_context('''||INST_INFO.Owner || '_SCMGR'', '||case l_is_table_have_id when 1 then 'new_.ID' else 'new_rowid'end||'),''0'')=''1'' then'||LF
                      ||TB||TB||'message.err(-20999,constant.EXEC_ERROR,''OBJ_PROTECTED'','||case l_is_table_have_id when 1 then 'new_.ID' else 'new_rowid'end||','''||t||''');'||LF
                      ||TB||'end if;'||LF
                      end
                  end ||
                  case when not p_bulk_repl then
                    TB||'if n is null then'||LF||
                    TB||TB||'select rep_id.nextval into n from dual;'||LF||
                    case when sc_logging then
                      TB||TB||'insert into repl_stack(id,s,num) values(n,dbms_utility.format_call_stack'||
                              ',sys_context('''||INST_INFO.Owner || '_USER'', ''$SCMGR_NUM$''));'||LF
                    end ||
                    TB||'end if;'||LF||
                    case when sc_logging then
                      TB||'insert into replication (id,obj_id,class_id,event,btype,qual,value,old_value,ses) values(n,o,c,sEvent,b,q,v,p' ||
                                    ','||s_context||');'||LF
                    else
                      TB||'insert into replication (id,obj_id,class_id,event,btype,qual,value) values(n,o,c,sEvent,b,q,v);'||LF
                    end
                  else
                    TB||'repl_utils.add(c,o,sEvent,b,q,v,p);'||LF
                  end ||
                  'end;'||LF||
                  'begin n:=null; v:=null; o:=nvl('||case l_is_table_have_id when 1 then 'new_.ID,old_.ID' else 'new_rowid,old_rowid' end||'); c:='''||p_class||''';'||LF,
                   txt_buf,false);
      repl_utils.ws('Creating package body REP$'||t);
      storage_mgr.create_object(txt_buf,null,true);
      err := repl_utils.show_errors('REP$'||t);
      if err is not null then repl_utils.ws(substr(err,1,4000)); end if;
      s_p(i):= TB||case l_is_table_have_id when 1 then 'o.id:=:old.id;n.id:=:new.id;' else 'o_rowid:=:old.rowid;n_rowid:=:new.rowid;'end|| LF || s_p(i);
    end if;
    if s_p.exists(1) and s_p(1) is not null then
      for j in 1..s_p.count loop
        if b_upd_err then
          s:= s_p(j)||TB||'REP$'||t||'.w(n,n_rowid,o,o_rowid);';
        end if;
        s := 'CREATE OR REPLACE TRIGGER REP$'||t||'$UPD'||case when j>1 then '$' ||j end||LF
          || 'AFTER UPDATE ON '||t||' FOR EACH ROW'||LF ||
          case when not b_upd_err then
            case when sc_logging and b_collection then
              'Declare c varchar2(16); o varchar2(128); p varchar2(4000); v varchar2(4000); n number;r rtl.object_rec;'||LF
            else
              'Declare c varchar2(16); o varchar2(128); p varchar2(4000); v varchar2(4000); n number;'||LF
            end
            || 'procedure w(q varchar2,b varchar2) is'||LF
            || 'begin'||LF||
            case when sc_logging then
              TB||'if nvl(sys_context('''||INST_INFO.Owner || '_USER'', ''$SCMGR_RECORD$''),0)<1 and '||LF
              ||TB||' nvl(sys_context('''||INST_INFO.Owner || '_USER'', ''$SCMGR_PLAY$''),0)<1 and '||LF||
              case when b_collection then
                TB||' nvl(sys_context('''||INST_INFO.Owner || '_SCMGR'', ''$PROTECT$''),''0'')=''1'' then '||LF
              ||TB||TB||'if nvl(sys_context('''||INST_INFO.Owner || '_SCMGR'', :old.COLLECTION_ID),''0'')=''1'' then'||LF
              ||TB||TB||TB||'r:=rtl.get_parent(:old.COLLECTION_ID,'''||p_class||''');'||LF
              ||TB||TB||TB||'message.err(-20999,constant.EXEC_ERROR,''OBJ_PROTECTED'',r.id,''Z#''||r.class_id);'||LF
              ||TB||TB||'elsif nvl(sys_context('''||INST_INFO.Owner || '_SCMGR'', :new.COLLECTION_ID),''0'')=''1'' then'||LF
              ||TB||TB||TB||'r:=rtl.get_parent(:new.COLLECTION_ID,'''||p_class||''');'||LF
              ||TB||TB||TB||'message.err(-20999,constant.EXEC_ERROR,''OBJ_PROTECTED'',r.id,''Z#''||r.class_id);'||LF
              ||TB||TB||'end if;'||LF
              ||TB||TB||'if nvl(sys_context('''||INST_INFO.Owner || '_SCMGR'','||case l_is_table_have_id when 1 then ':new.ID' else ':new.ROWID' end||'),''0'')=''1'' then'||LF
              ||TB||TB||TB||'message.err(-20999,constant.EXEC_ERROR,''OBJ_PROTECTED'','||case l_is_table_have_id when 1 then ':new.ID' else ':new.ROWID' end||','''||t||''');'||LF
              ||TB||TB||'end if;'||LF
              ||TB||'end if;'||LF
              else
                TB||' nvl(sys_context('''||INST_INFO.Owner|| '_SCMGR'', ''$PROTECT$''),''0'')=''1'' and '||LF
              ||TB||' nvl(sys_context('''||INST_INFO.Owner|| '_SCMGR'','||case l_is_table_have_id when 1 then ':new.ID' else ':new.ROWID' end||'),''0'')=''1'' then'||LF
              ||TB||TB||'message.err(-20999,constant.EXEC_ERROR,''OBJ_PROTECTED'','||case l_is_table_have_id when 1 then ':new.ID' else ':new.ROWID' end||','''||t||''');'||LF
              ||TB||'end if;'||LF
              end
            end ||
            case when not p_bulk_repl then
              TB||'if n is null then'||LF
              ||TB||TB||'select rep_id.nextval into n from dual;'||LF||
              case when sc_logging then
                TB||TB||'insert into repl_stack(id,s,num) values(n,dbms_utility.format_call_stack'||
                        ',sys_context('''||INST_INFO.Owner||'_USER'', ''$SCMGR_NUM$''));'||LF
              end
              ||TB||'end if;'||LF||
              case when sc_logging then
                TB||'insert into replication (id,obj_id,class_id,event,btype,qual,value,old_value,ses) values(n,o,c,''U'',b,q,v,p' ||
                      ','||s_context||');'||LF
              else
                TB||'insert into replication (id,obj_id,class_id,event,btype,qual,value) values(n,o,c,''U'',b,q,v);'||LF
              end
            else
              TB||'repl_utils.add(c,o,''U'',b,q,v,p);'||LF
            end
            || 'end;'||LF||
            case when sc_logging then
            'begin'||LF||
              TB||'if sys_context('''||INST_INFO.Owner|| '_USER'', ''$SCMGR_PAUSE_REPL$'')=1 then return; end if;'||LF||
              TB||'n:=null; v:=null; o:='||case l_is_table_have_id when 1 then ':new.ID' else ':new.ROWID' end||'; c:='''||p_class||''';'||LF
            else
            'begin n:=null; v:=null; o:='||case l_is_table_have_id when 1 then ':new.ID' else ':new.ROWID' end||'; c:='''||p_class||''';'||LF
            end
          else
            case when sc_logging and b_collection then
              'Declare o '||t||'%rowtype; n '||t||'%rowtype;'||'r rtl.object_rec; o_rowid varchar2(18); n_rowid varchar2(18);'||LF
            else
               'Declare o '||t||'%rowtype; n '||t||'%rowtype; o_rowid varchar2(18); n_rowid varchar2(18);'||LF
            end
            || 'begin '||LF||
            case when sc_logging then
            TB||'if sys_context('''||INST_INFO.Owner|| '_USER'', ''$SCMGR_PAUSE_REPL$'')=1 then return; end if;'||LF
            end
          end
          ||s
          ||LF||'end;';
        repl_utils.execute_sql(s,'Creating trigger REP$'||t||'$UPD',true);
        err := repl_utils.show_errors('REP$'||t||'$UPD');
        if err is not null then repl_utils.ws(substr(err,1,4000)); end if;
      end loop;
    end if;

    for j in 1..s_p2.count loop
      if b_ins_err then
          ss:= s_p2(j) || TB || 'REP$'||t||'.w(n,n_rowid,o_,o_rowid,''I''); '||LF;
      elsif sc_logging and not p_bulk_repl then
          ss:= ss || TB||'insert into repl_stack(id,s,num) values(rep_id.currval,dbms_utility.format_call_stack'||
                          ',sys_context('''||INST_INFO.Owner||'_USER'', ''$SCMGR_NUM$''));'||LF;
      end if;
      s := 'CREATE OR REPLACE TRIGGER REP$'||t||'$INS'||case when j>1 then '$' ||j end||LF
            || 'AFTER INSERT ON '||t||' FOR EACH ROW'||LF||
            case when not b_ins_err then
              case when sc_logging and b_collection then
                 'Declare c varchar2(16); o varchar2(128);'||'r rtl.object_rec;'
              else
                 'Declare c varchar2(16); o varchar2(128);'
              end||
              case when p_bulk_repl then 'n pls_integer;' end||LF
              || 'procedure w(q varchar2,b varchar2,v varchar2) is'||LF
              || 'begin'||LF||
              case when not p_bulk_repl then
                case when sc_logging then
                  TB||'insert into replication (id,obj_id,class_id,event,btype,qual,value,ses) values(rep_id.currval,o,c,''I'',b,q,v'||
                         ','||s_context||');'||LF
                else
                  TB||'insert into replication (id,obj_id,class_id,event,btype,qual,value) values(rep_id.currval,o,c,''I'',b,q,v);'||LF
                end
              else
                TB||'repl_utils.add(c,o,''I'',b,q,v,null);'||LF
              end
              || 'end;'||LF
            else
              case when sc_logging and b_collection then
                 'Declare o_ '||t||'%rowtype; n '||t||'%rowtype; c varchar2(16); o varchar2(128); n_rowid varchar2(18); o_rowid varchar2(18);'||'r rtl.object_rec;'
              else
                 'Declare o_ '||t||'%rowtype; n '||t||'%rowtype; c varchar2(16); o varchar2(128); n_rowid varchar2(18); o_rowid varchar2(18);'
              end||
              case when p_bulk_repl then 'n pls_integer;' end||LF
            end||
            'begin'||LF||
            case when sc_logging then
              TB||'if sys_context('''||INST_INFO.Owner|| '_USER'', ''$SCMGR_PAUSE_REPL$'')=1 then return; end if;'||LF
            end||
            TB||'o:='||case l_is_table_have_id when 1 then ':new.ID' else ':new.ROWID' end||'; c:='''||p_class||''';'||LF||
            case when sc_logging and b_collection then
              TB||'if nvl(sys_context('''||INST_INFO.Owner || '_USER'', ''$SCMGR_RECORD$''),0)<1 and '||LF
              ||TB||TB||'nvl(sys_context('''||INST_INFO.Owner || '_USER'', ''$SCMGR_PLAY$''),0)<1 and '||LF
              ||TB||TB||'nvl(sys_context('''||INST_INFO.Owner || '_SCMGR'', ''$PROTECT$''),''0'')=''1'' and '||LF
              ||TB||TB||'nvl(sys_context('''||INST_INFO.Owner || '_SCMGR'', :new.COLLECTION_ID),''0'')=''1'' then'||LF
              ||TB||TB||TB||'r:=rtl.get_parent(:new.COLLECTION_ID,'''||p_class||''');'||LF
              ||TB||TB||TB||'message.err(-20999,constant.EXEC_ERROR,''OBJ_PROTECTED'',r.id,''Z#''||r.class_id);'||LF
              ||TB||'end if;'||LF
            end ||
            case when not p_bulk_repl then
              case when sc_logging then
                TB||'insert into replication (id,obj_id,class_id,event,btype,qual,value,ses) values(rep_id.nextval,o,'||s_class_id||',''I'',null,null,c'||
                        ','||s_context||');'||LF
              else
                TB||'insert into replication (id,obj_id,class_id,event,btype,qual,value) values(rep_id.nextval,o,c,''I'',null,null,null);'||LF
              end
            else
              TB||'repl_utils.add(c,o,''I'',null,null,'||s_class_id||',null);'||LF
            end
            ||ss
            ||'end;';
      repl_utils.execute_sql(s,'Creating trigger REP$'||t||'$INS',true);
      err := repl_utils.show_errors('REP$'||t||'$INS');
      if err is not null then repl_utils.ws(substr(err,1,4000)); end if;
    end loop;

    for j in 1..s_p3.count loop
      if b_del_err then
          sss:= s_p3(j) || TB || 'REP$'||t||'.w(n,n_rowid,o,o_rowid,''D''); '||LF;
      elsif sc_logging and not p_bulk_repl then
          sss:= sss || TB||'insert into repl_stack(id,s,num) values(rep_id.currval,dbms_utility.format_call_stack'||
                          ',sys_context('''||INST_INFO.Owner||'_USER'', ''$SCMGR_NUM$''));'||LF;
      end if;

      s := 'CREATE OR REPLACE TRIGGER REP$'||t||'$DEL'||case when j>1 then '$' ||j end||LF
            || 'AFTER DELETE ON '||t||' FOR EACH ROW'||LF||
          case when not b_del_err then
            case when sc_logging and b_collection then
              'Declare c varchar2(16);'||'r rtl.object_rec;'
            else
              'Declare c varchar2(16);'
            end||
            case when p_bulk_repl then 'n pls_integer;' end||LF||
            case when sc_logging then
               'procedure w(q varchar2,b varchar2,v varchar2) is'||LF||
               'begin'||LF||
              case when not p_bulk_repl then
                TB||'insert into replication (id,obj_id,class_id,event,btype,qual,old_value,ses) values(rep_id.currval,'||case l_is_table_have_id when 1 then ':old.ID' else ':old.ROWID' end||',c,''D'',b,q,v'||
                     ','||s_context||');'||LF
              else
                TB||'repl_utils.add(c,'||case l_is_table_have_id when 1 then ':old.ID' else ':old.ROWID' end||',''D'',b,q,null,v);'||LF
              end ||
             'end;'||LF
            end
          else
            case when sc_logging and b_collection then
                 'Declare o '||t||'%rowtype; n '||t||'%rowtype; c varchar2(16); '||'r rtl.object_rec; o_rowid varchar2(18); n_rowid varchar2(18);'
            else
                 'Declare o '||t||'%rowtype; n '||t||'%rowtype; c varchar2(16); o_rowid varchar2(18); n_rowid varchar2(18);'
            end||
            case when p_bulk_repl then 'n pls_integer;' end||LF
          end||
          case when sc_logging then
            'begin'||LF
            ||TB||'if sys_context('''||INST_INFO.Owner|| '_USER'', ''$SCMGR_PAUSE_REPL$'')=1 then return; end if;'||LF
            ||TB||'c:='''||p_class||''';'||LF
            ||TB||'if nvl(sys_context('''||INST_INFO.Owner || '_USER'', ''$SCMGR_RECORD$''),0)<1 and '||LF
            ||TB||' nvl(sys_context('''||INST_INFO.Owner || '_USER'', ''$SCMGR_PLAY$''),0)<1 and '||LF||
            case when b_collection then
              TB||' nvl(sys_context('''||INST_INFO.Owner || '_SCMGR'', ''$PROTECT$''),''0'')=''1'' then '||LF
            ||TB||TB||'if nvl(sys_context('''||INST_INFO.Owner || '_SCMGR'', :old.COLLECTION_ID),''0'')=''1'' then'||LF
            ||TB||TB||TB||'r:=rtl.get_parent(:old.COLLECTION_ID,'''||p_class||''');'||LF
            ||TB||TB||TB||'message.err(-20999,constant.EXEC_ERROR,''OBJ_PROTECTED'',r.id,''Z#''||r.class_id);'||LF
            ||TB||TB||'end if;'||LF
            ||TB||TB||'if nvl(sys_context('''||INST_INFO.Owner || '_SCMGR'','||case l_is_table_have_id when 1 then ':old.ID' else ':old.ROWID' end||'),''0'')=''1'' then'||LF
            ||TB||TB||TB||'message.err(-20999,constant.EXEC_ERROR,''OBJ_PROTECTED'','||case l_is_table_have_id when 1 then ':old.ID' else ':old.ROWID' end||','''||t||''');'||LF
            ||TB||TB||'end if;'||LF
            ||TB||'end if;'||LF
            else
              TB||' nvl(sys_context('''||INST_INFO.Owner || '_SCMGR'', ''$PROTECT$''),''0'')=''1'' and '||LF
            ||TB||' nvl(sys_context('''||INST_INFO.Owner || '_SCMGR'','||case l_is_table_have_id when 1 then ':old.ID' else ':old.ROWID' end||'),''0'')=''1'' then'||LF
            ||TB||TB||'message.err(-20999,constant.EXEC_ERROR,''OBJ_PROTECTED'','||case l_is_table_have_id when 1 then ':old.ID' else ':old.ROWID' end||','''||t||''');'||LF
            ||TB||'end if;'||LF
            end||
            case when not p_bulk_repl then
              TB||'insert into replication (id,obj_id,class_id,event,ses) values(rep_id.nextval,'||case l_is_table_have_id when 1 then ':old.ID' else ':old.ROWID' end||',c,''D''' ||
                  ','||s_context||');'||LF
            else
              TB||'repl_utils.add(c,'||case l_is_table_have_id when 1 then ':old.ID' else ':old.ROWID' end||',''D'',null,null,null,null);'||LF
            end
          else
            'begin c:='''||p_class||''';'||LF
            ||TB||'insert into replication (id,obj_id,class_id,event) values(rep_id.nextval,'||case l_is_table_have_id when 1 then ':old.ID' else ':old.ROWID' end||',c,''D'');'||LF
          end
          ||sss
          ||'end;';
      repl_utils.execute_sql(s,'Creating trigger REP$'||t||'$DEL',true);
      err := repl_utils.show_errors('REP$'||t||'$DEL');
      if err is not null then repl_utils.ws(substr(err,1,4000)); end if;

    end loop;

    if p_bulk_repl then

      s :='CREATE OR REPLACE TRIGGER REP$'||t||'$CHANGES'||LF||
          'AFTER UPDATE OR INSERT OR DELETE ON ' ||t ||LF||
          'Declare n number;'||LF||
          'begin'||LF||
          'repl_utils.save('''||p_class||''');'||LF||
          'end;';

      repl_utils.execute_sql(s,'Creating trigger REP$'||t||'$CHANGES',true);
      err := repl_utils.show_errors('REP$'||t||'$CHANGES');
      if err is not null then repl_utils.ws(substr(err,1,4000)); end if;

      s :='CREATE OR REPLACE TRIGGER REP$'||t||'$BEFORE'||LF||
          'BEFORE UPDATE OR INSERT OR DELETE ON ' ||t ||LF||
          'Declare n number;'||LF||
          'begin'||LF||
          'repl_utils.init('''||p_class||''');'||LF||
          'end;';

      repl_utils.execute_sql(s,'Creating trigger REP$'||t||'$BEFORE',true);
      err := repl_utils.show_errors('REP$'||t||'$BEFORE');
      if err is not null then repl_utils.ws(substr(err,1,4000)); end if;

    end if;

end;
--
procedure create_triggers(p_pipe varchar2 default null, p_class  varchar2 default null,
                          p_kernel boolean default false, p_bulk_repl boolean default false)
is
    v_class varchar2(40) := nvl(p_class,'%');
    i   pls_integer;
    t   names_tbl;
    sc_logging_ varchar2(1):=rtl.bool_char(sc_logging);
begin
    if p_pipe is not null then
      repl_utils.verbose := true;
      repl_utils.pipe_name := p_pipe;
    else
      repl_utils.verbose := false;
      repl_utils.pipe_name := null;
    end if;
    i := 0;
    for c in (
      select class_id from class_tables
        where class_id like v_class and table_name like 'Z#%'
              and (storage_mgr.is_temporary(class_id)='0' or sc_logging_='1') -- журналировать изменения временных таблиц все-таки надо 17/06/2010 sasa
        order by class_id)
    loop
        i := i+1;
        t(i) := c.class_id;
    end loop;

    if i>=1 then
      drop_triggers(p_pipe, v_class,p_kernel=>false,p_only_adding=>true);
    end if;

    for j in 1..i  loop
        begin
          create_class_trigger(t(j),p_bulk_repl);
        exception when others then
          if p_pipe is not null and i>1 then
            repl_utils.ws(t(j) || LF || utils.error_stack(true));
          else
            raise;
          end if;
        end;
    end loop;
    if p_kernel then
        repl_utils.execute_sql('CREATE OR REPLACE TRIGGER REP$SETTINGS'||LF
          || 'AFTER INSERT OR UPDATE OR DELETE ON SETTINGS FOR EACH ROW'||LF
          || 'Declare c varchar2(16); e varchar2(1); n number;'||LF
          || 'procedure w(q varchar2,b varchar2,v varchar2) is'||LF
          || 'begin'||LF
          ||TB||'if n is null then select rep_id.nextval into n from dual; end if;'||LF
          ||TB||'insert into replication (id,obj_id,class_id,event,btype,qual,value) values(n,e,c,''X'',b,q,v);'||LF
          || 'end;'||LF
          || 'begin n:=null; c:=''SETTINGS'';'||LF
          ||TB||'if deleting then e:=''D''; w(''NAME'',''P'',:old.name);'||LF
          ||TB||'elsif inserting then e:=''I''; w(''NAME'',''P'',:new.name); w(''VALUE'',''S'',:new.value);'||LF
          ||TB||TB||'if :new.type is not null then w(''TYPE'',''S'',:new.type); end if;'||LF
          ||TB||TB||'if :new.description is not null then w(''DESCRIPTION'',''S'',:new.description); end if;'||LF
          ||TB||'else e:=''U''; w(''NAME'',''P'',:old.name); w(''VALUE'',''S'',:new.value);'||LF
          ||TB||TB||'if nvl(:old.name,''?'')<>nvl(:new.name,''?'') then w(''NAME'',''S'',:new.name); end if;'||LF
          ||TB||TB||'if nvl(:old.type,''?'')<>nvl(:new.type,''?'') then w(''TYPE'',''S'',:new.type); end if;'||LF
          ||TB||TB||'if nvl(:old.description,''?'')<>nvl(:new.description,''?'') then w(''DESCRIPTION'',''S'',:new.description); end if;'||LF
          ||TB||'end if;'||LF
          || 'end;','Creating trigger REP$SETTINGS');
--
        repl_utils.execute_sql('CREATE OR REPLACE TRIGGER REP$OBJ_STATIC'||LF
              || 'AFTER INSERT OR UPDATE OR DELETE ON OBJ_STATIC FOR EACH ROW'||LF
              || 'Declare c varchar2(16); e varchar2(1); n number;'||LF
              || 'procedure w(q varchar2,b varchar2,v varchar2) is'||LF
              || 'begin'||LF
              ||TB||'if n is null then select rep_id.nextval into n from dual; end if;'||LF
              ||TB||'insert into replication (id,obj_id,class_id,event,btype,qual,value) values(n,e,c,''X'',b,q,v);'||LF
              || 'end;'||LF
              || 'begin n:=null; c:=''OBJ_STATIC'';'||LF
              ||TB||'if deleting then e:=''D''; w(''CLASS_ID'',''P'',:old.class_id);'||LF
              ||TB||'else if inserting then e:=''I''; else e:=''U''; end if;'||LF
              ||TB||'w(''CLASS_ID'',''P'',:new.class_id); w(''ID'',''N'',:new.id); end if;'||LF
              || 'end;','Creating trigger REP$OBJ_STATIC');
--
        repl_utils.execute_sql('CREATE OR REPLACE TRIGGER REP$PROFILES'||LF
          || 'AFTER INSERT OR UPDATE OR DELETE ON PROFILES FOR EACH ROW'||LF
          || 'Declare c varchar2(16); e varchar2(1); n number;'||LF
          || 'procedure w(q varchar2,b varchar2,v varchar2) is'||LF
          || 'begin'||LF
          ||TB||'if n is null then select rep_id.nextval into n from dual; end if;'||LF
          ||TB||'insert into replication (id,obj_id,class_id,event,btype,qual,value) values(n,e,c,''X'',b,q,v);'||LF
          || 'end;'||LF
          || 'begin n:=null; c:=''PROFILES'';'||LF
          ||TB||'if deleting then e:=''D''; w(''PROFILE'',''P'',:old.profile);w(''RESOURCE_NAME'',''P'',:old.resource_name);'||LF
          ||TB||'elsif inserting then e:=''I''; w(''PROFILE'',''P'',:new.profile);w(''RESOURCE_NAME'',''P'',:new.resource_name); w(''VALUE'',''S'',:new.value);'||LF
          ||TB||TB||'if :new.description is not null then w(''DESCRIPTION'',''S'',:new.description); end if;'||LF
          ||TB||'else e:=''U''; w(''PROFILE'',''P'',:old.profile);w(''RESOURCE_NAME'',''P'',:old.resource_name); w(''VALUE'',''S'',:new.value);'||LF
          ||TB||TB||'if nvl(:old.profile,''?'')<>nvl(:new.profile,''?'') then w(''PROFILE'',''S'',:new.profile); end if;'||LF
          ||TB||TB||'if nvl(:old.resource_name,''?'')<>nvl(:new.resource_name,''?'') then w(''RESOURCE_NAME'',''S'',:new.resource_name); end if;'||LF
          ||TB||TB||'if nvl(:old.description,''?'')<>nvl(:new.description,''?'') then w(''DESCRIPTION'',''S'',:new.description); end if;'||LF
          ||TB||'end if;'||LF
          || 'end;','Creating trigger REP$PROFILES');
--
        if v_class='%' then  repl_utils.create_kernel_triggers(p_pipe); end if;
    end if;
--
end;
--
procedure drop_triggers(p_pipe varchar2 default null, p_class  varchar2 default null, p_kernel boolean default true, p_only_adding boolean default false) is
    v_class varchar2(40) := nvl(p_class,'%');
    i   pls_integer;
    t   names_tbl;
    v_only_adding varchar2(1):= '0';
begin
    if p_pipe is not null then
      repl_utils.verbose := true;
      repl_utils.pipe_name := p_pipe;
    end if;
    if p_only_adding then
      v_only_adding:= '1';
    end if;
    i := 0;
    for c in (select ut.trigger_name from class_tables ct,user_triggers ut
                where ct.class_id like v_class and ut.table_name=ct.table_name
                      and ut.trigger_name like 'REP$Z#%$%'
                      and (not v_only_adding='1' or substr(ut.trigger_name,-3) not in ('INS','UPD','DEL'))
                order by ct.class_id)
    loop
      i := i+1;
      t(i) := c.trigger_name;
    end loop;
    if p_kernel and not p_only_adding then
        i := i+1;
        t(i) := 'REP$SETTINGS';
        i := i+1;
        t(i) := 'REP$OBJ_STATIC';
        i := i+1;
        t(i) := 'REP$PROFILES';
    end if;
    for j in 1..i  loop
        repl_utils.execute_sql('DROP TRIGGER '||t(j),'Dropping trigger '||t(j),not p_only_adding);
    end loop;
    if p_kernel and v_class='%' then
        repl_utils.drop_kernel_triggers(p_pipe);
    end if;
end;
--
-- Включение режима "только чтение" (запрет изменений в прикладных таблицах)
procedure read_only_mode(p_pipe varchar2 default null) is
begin
    if p_pipe is not null then
      repl_utils.verbose := true;
      repl_utils.pipe_name := p_pipe;
    end if;
    repl_utils.save_sequences;
--
    repl_utils.set_trigger_status('SETTINGS_CHANGES', 'DISABLED');
    stdio.put_setting('PLP_READ_ONLY','YES');
    commit;
--
    repl_utils.ws('Stopping LOCK_INFO...');
    rtl.lock_stop;
    repl_utils.ws('LOCK_INFO is stopped');
--
    repl_utils.set_trigger_status('SETTINGS_CHANGES', 'ENABLED');
end;
-- Остановка режима репликации
procedure stop_repl_mode(p_pipe varchar2 default null) is
begin
    if p_pipe is not null then
      repl_utils.verbose := true;
      repl_utils.pipe_name := p_pipe;
    end if;
    drop_triggers();
    repl_utils.set_trigger_status('SETTINGS_CHANGES', 'DISABLED');
    stdio.put_setting('PLP_READ_ONLY','NO');
    commit;
    repl_utils.set_trigger_status('SETTINGS_CHANGES', 'ENABLED');
end;
--
end;
/
show err package body repl_mgr
