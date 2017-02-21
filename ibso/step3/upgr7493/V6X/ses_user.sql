exec stdio.enable_buf
declare
  n number;
  i number;
  b boolean;
  v varchar2(200);
  ok boolean;
  s1 varchar2(30);
  s2 varchar2(30);
begin
  stdio.put_line_buf('Correcting SESSIONS_PER_USER resource in Profiles... ');
  s1 := '2 сессии ';
  s2 := '1 сессия ';
  ok := false;
  for c in (
    select * from profiles
     where resource_name='SESSIONS_PER_USER' and instr(description,s1)>0
  ) loop
    v := nvl(c.value,'UNLIMITED');
    stdio.put_line_buf('Profile '||c.profile||': '||v,false);
    begin
      n := to_number(v);
      b := n>1;
    exception when value_error then
      b := false;
    end;
    if b then
      if c.profile='DEFAULT' then
        select count(1) into i from users
         where instr(properties,'|SESSION')>0
           and (instr(properties,'|PROFILE '||c.profile||'|')>0 or instr(properties,'|PROFILE ')=0)
           and (lock_status is null or lock_status<>'DELETED') and rownum=1;
      else
        select count(1) into i from users
         where instr(properties,'|SESSION')>0
           and instr(properties,'|PROFILE '||c.profile||'|')>0
           and (lock_status is null or lock_status<>'DELETED') and rownum=1;
      end if;
      if i=0 then
        n := trunc(n/2);
        v := to_char(n);
      end if;
      stdio.put_line_buf(' ==> '||v);
    end if;
    if not b then
      stdio.put_line_buf('');
    end if;
    stdio.set_resource(c.profile,'SESSIONS_PER_USER',v,replace(c.description,s1,s2));
    ok := true;
  end loop;
  if ok then
    commit;
  end if;
end;
/

