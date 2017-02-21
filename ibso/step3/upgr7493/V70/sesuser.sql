exec stdio.enable_buf
declare
  n number;
  i number;
  b boolean;
  d varchar2(2000);
begin
if nvl(to_number('&&v_version','999.9'),1)<6.5 then
  stdio.put_line_buf('Correcting SESSIONS_PER_USER resource through DEFAULT Profile... ');
  select description into d from profiles
   where profile='DEFAULT' and resource_name='SESSIONS_PER_USER' and value<>'UNLIMITED';
  b := false;
  for c in (
    select distinct profile from profiles p
     where profile<>'DEFAULT' and not exists
        (select 1 from profiles p1 where p1.profile=p.profile and resource_name='SESSIONS_PER_USER')
  ) loop
    insert into profiles (profile,resource_name,value,description)
      values (c.profile,'SESSIONS_PER_USER','UNLIMITED',d);
    stdio.put_line_buf('Profile '||c.profile||' resource SESSIONS_PER_USER : UNLIMITED');
    b := true;
  end loop;
  if b then
    --null;
    commit;
  else
    stdio.put_line_buf('No profiles found to be corrected.');
  end if;
end if;
exception when no_data_found then
  stdio.put_line_buf('DEFAULT.SESSIONS_PER_USER is not limited - No corrections made.');
end;
/

