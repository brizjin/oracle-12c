declare
  s varchar2(2000);
  q varchar2(4000);
  n number;
  nn number;
  n1 number;
  n2 number;
  up boolean;
begin
  up := false;
  storage_utils.verbose:=true;
  storage_utils.pipe_name:='DEBUG';
  for c in (
    select p.build,p.ord,p.name,ct.class_id, ct.table_name, cp.class_id prt_class, cp.condition, cp.tablespace_name, cp.idx_tablespace,
           p.crt_user, p.mod_user, p.stage, p.notes, p.fname, p.loaddata, p.rowid, ut.object_type
      from user_objects ut, project p, class_partitions cp, class_tables ct
     where ut.object_name=ct.table_name
       and ut.object_type in ('TABLE','SYNONYM')
       and ct.table_name like 'Z#%'
       and cp.class_id(+) = ct.class_id
       and cp.partition_position(+) is null
       and p.name = ct.class_id
       and p.type like 'UPGRADE%'
       --and p.notes is not null and p.fname is null
     order by 1, 2, 3
  ) loop
    storage_utils.ws('');
    storage_utils.ws('------------------------------- '||c.build||'.'||c.ord);
    storage_utils.ws('*** '||c.class_id||' '||c.fname||' ***');
    if c.fname is null then
      if c.prt_class is not null then
        s := null;
        q := 'SELECT COUNT(1) FROM '||c.table_name;
        for cc in (select id from obj_static,class_relations
                    where parent_id=c.class_id and class_id=child_id)
        loop
          s := s||','||cc.id;
        end loop;
        if s is not null then
          s := 'ID NOT IN ('||substr(s,2)||') AND ('||nvl(c.condition,'1=2')||')';
        else
          s := nvl(c.condition,'1=2');
        end if;
        begin
          storage_utils.ws(q);
          execute immediate q into n;
          storage_utils.ws('Result (Total): '||n);
          q := q||' T WHERE ';
          storage_utils.ws(q||s);
          execute immediate q||s into n1;
          storage_utils.ws('Result (Archive): '||n1);
          if n>0 then
            storage_utils.ws('Percentage (Archive/Total): '||to_char(n1*100/n,'990.9999'));
          end if;
          q := q||'NOT ('||s||')';
          storage_utils.ws(q);
          execute immediate q into n2;
          storage_utils.ws('Result (Actual): '||n2);
          if n>0 then
            storage_utils.ws('Percentage of total (Actual/Total): '||to_char(n2*100/n,'990.9999'));
          end if;
          if n1+n2<>n then
            storage_utils.ws('Bad condition: '||n1||' + '||n2||' = '||(n1+n2)||' <> '||n);
          end if;
        exception when others then
          storage_utils.ws('Error: '||sqlerrm);
        end;
      elsif c.notes is not null then
        s := null;
        q := 'SELECT COUNT(1) FROM '||c.table_name;
        for cc in (select id from obj_static,class_relations
                    where parent_id=c.class_id and class_id=child_id)
        loop
          begin
            execute immediate q||' T WHERE T.ID=:b1 AND ('||c.notes||')'
               into n1 using cc.id;
          exception when others then
            n1 := 0;
          end;
          if n1=0 then
            s := s||','||cc.id;
          end if;
        end loop;
        if s is not null then
          s := '(t.ID in ('||substr(s,2)||')) or (';
          if instr(c.notes,s)=1 then
            s := c.notes;
          else
            s := s||c.notes||')';
          end if;
        else
          s := c.notes;
        end if;
        begin
          storage_utils.ws(q);
          execute immediate q into n1;
          storage_utils.ws('Result (Total): '||n1);
          q := q||' T WHERE '||s;
          storage_utils.ws(q);
          execute immediate q into n2;
          storage_utils.ws('Result (Condition): '||n2);
          if n1>0 then
            storage_utils.ws('Percentage (Condition/Total): '||to_char(n2*100/n1,'990.9999'));
          end if;
        exception when others then
          storage_utils.ws('Error: '||sqlerrm);
        end;
        if n1>0 then
          n2 := n2*0.9/n1;
        else
          n2 := 0.9;
        end if;
        if n2<0.001 then
          n2 := 0.001;
        end if;
        n1 := nvl(c.stage,0.9);
        storage_utils.ws('Current Ratio: '||to_char(n1,'0.999'));
        storage_utils.ws('Estimated Ratio: '||to_char(n2,'0.999'));
        if c.notes<>s then
          storage_utils.ws('Old Condition: '||c.notes);
          storage_utils.ws('New Condition: '||s);
          update project set notes=s where rowid=c.rowid;
          up := true;
        end if;
      end if;
      if c.tablespace_name is not null then
        select count(1) into n from user_tablespaces where tablespace_name=upper(c.tablespace_name);
        if n=0 then
          storage_utils.ws('TableSpace does not exist: '||c.tablespace_name);
        end if;
      end if;
      if c.idx_tablespace is not null then
        select count(1) into n from user_tablespaces where tablespace_name=upper(c.idx_tablespace);
        if n=0 then
          storage_utils.ws('TableSpace does not exist: '||c.idx_tablespace);
        end if;
      end if;
      if c.crt_user is not null then
        select count(1) into n from user_tablespaces where tablespace_name=upper(c.crt_user);
        if n=0 then
          storage_utils.ws('TableSpace does not exist: '||c.crt_user);
        end if;
      end if;
    else
      begin
        select base_class_id into s from class_tab_columns
         where class_id=c.class_id and column_name=c.fname;
        if c.object_type='TABLE' then
          select num_rows into nn from user_tables where table_name=c.table_name;
          select num_nulls into n from user_tab_columns
           where table_name=c.table_name and column_name=c.fname;
        else
          select num_rows into nn from all_tables where table_name=c.table_name and rownum=1;
          select num_nulls into n from all_tab_columns
           where table_name=c.table_name and column_name=c.fname and rownum=1;
        end if;
      exception when no_data_found then
        s := null;
      end;
      if s is not null then
        n1 := nvl(c.stage,1);
        n2 := n1;
        storage_utils.ws('Base type of '||c.table_name||'.'||c.fname||' : '||s);
        if s='REFERENCE' then
          if nvl(c.loaddata,'1')<>'0' then
            s := '0';
            storage_utils.ws('Old Loaddata: '||c.loaddata);
            storage_utils.ws('New Loaddata: '||s);
            update project set loaddata=s where rowid=c.rowid;
            up := true;
          end if;
          if nn>0 then
            n2 := (nn-n)/nn;
            if n2<0.0001 then
              n2 := 0.0001;
            end if;
          end if;
        elsif s='COLLECTION' then
          if c.loaddata='0' then
            s := '1';
            storage_utils.ws('Old Loaddata: '||c.loaddata);
            storage_utils.ws('New Loaddata: '||s);
            update project set loaddata=s where rowid=c.rowid;
            up := true;
          end if;
          n2 := 1;
        end if;
        storage_utils.ws('Current Ratio: '||to_char(n1,'0.9999'));
        storage_utils.ws('Estimated Ratio: '||to_char(n2,'0.9999'));
      else
        storage_utils.ws('Column does not exist: '||c.table_name||'.'||c.fname);
      end if;
    end if;
    if c.mod_user is not null then
      select count(1) into n from user_tablespaces where tablespace_name=upper(c.mod_user);
      if n=0 then
        storage_utils.ws('TableSpace does not exist: '||c.mod_user);
      end if;
    end if;
  end loop;
  storage_utils.ws('-------------------------------');
  if up then
    --rollback;
    commit;
  end if;
end;
/


