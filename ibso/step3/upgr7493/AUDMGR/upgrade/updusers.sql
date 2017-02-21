set serveroutput on size 100000
declare
    v_list  varchar2(100);
    v_str   varchar2(100);
    i   pls_integer;
    l   pls_integer;
    n   pls_integer;
    ii  pls_integer := 1;
begin
  v_list := &&audit..aud_mgr.get_value('OWNERS');
  if v_list is not null then
    l := length(v_list);
    while ii<=l loop
        i := instr(v_list,',',ii);
        if i>ii then
            v_str := ltrim(rtrim(substr(v_list,ii,i-ii)));
        elsif i=0 then
            i := l;
            v_str := ltrim(rtrim(substr(v_list,ii)));
        else
            v_str := null;
        end if;
        if i>1 and v_str is not null then
          begin
            execute immediate 
'update '||v_str||'.users set properties=properties||''|CONTEXT''
  where type=''U'' and instr(properties,''|CONTEXT'')=0 and ltrim(properties,''|'') is not null';
            n := sql%rowcount;
            execute immediate 
'update '||v_str||'.users set properties=''|CONTEXT''
  where type=''U'' and ltrim(properties,''|'') is null';
            n := n+sql%rowcount;
            dbms_output.put_line('Updated '||n||' rows in '||v_str||'.USERS');
            execute immediate 
'update '||v_str||'.criteria set properties=properties||''|Context''
  where flags=''R'' and instr(properties,''|Context'')=0';
            n := sql%rowcount;
            dbms_output.put_line('Updated '||n||' rows in '||v_str||'.CRITERIA');
            commit;
          exception when others then 
            rollback;
          end;
        end if;
        ii := i+1;
    end loop;
  end if;
end;
/

