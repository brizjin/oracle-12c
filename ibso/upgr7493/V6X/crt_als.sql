prompt Filling Criteria_Complex from Criteria.Properties

declare
    i   pls_integer;
    v   varchar2(200);
    a   varchar2(100);
    procedure get_alias(p_id varchar2,p_typ varchar2) is
        v_id varchar2(16);
    begin
        i := instr(v,'.');
        if i>0 then
            a := substr(v,i+1);
            v := substr(v,1,i-1);
            select id into v_id from criteria where short_name=v;
            for cc in (select position,alias from criteria_columns
                        where criteria_id=v_id
                        order by position)
            loop
                if a=upper(cc.alias) then
                    exit;
                elsif a=data_views.Get_ColName_By_Position(v_id,cc.position) then
                    a := cc.alias; exit;
                end if;
            end loop;
        else
            a := null;
        end if;
        data_views.put_dependence(p_id,v,p_typ,a,false);
    exception when no_data_found then null;
    end;
begin
  if nvl(to_number('&&v_version','999.9'),0)<6.1 then
    for c in (select id,class_id,short_name,name,properties from criteria
               where instr(properties,'|ColView ')>0 or instr(properties,'|RefView ')>0
               order by class_id,short_name
    ) loop
        stdio.put_line_buf('*** '||c.class_id||'.'||c.short_name||' ('||c.name||') '||c.id);
        v := method.extract_property(c.properties,'ColView');
        if v is not null then
            stdio.put_line_buf('--- ColView: '||v);
            get_alias(c.id,constant.COLLECTION);
        end if;
        v := method.extract_property(c.properties,'RefView');
        if v is not null then
            stdio.put_line_buf('--- RefView: '||v);
            get_alias(c.id,constant.REFERENCE);
        end if;
    end loop;
  end if;
end;
/

prompt Correcting Alias Names in criteria_columns
@@errals

prompt Converting field order_by of table criteria
exec Data_Views.Translate_Criterion_Order_By

set echo on

create unique index UNQ_CRIT_COLUMNS_CRIT_ID_ALIAS
    on CRITERIA_COLUMNS(criteria_id,alias)
    tablespace &&tspacei;

drop index IDX_CRIT_COLUMNS_CRITERIA_ID;

set echo off