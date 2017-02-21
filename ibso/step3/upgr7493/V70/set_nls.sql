declare
  s varchar2(2000);
begin
  for c in (
    select profile from profiles where resource_name like 'NLS_%'
    minus
    select profile from profiles where resource_name='NLS_SETTINGS'
  ) loop
    s := 'NLS_LANGUAGE='||nvl(stdio.get_resource(c.profile,'NLS_LANGUAGE'),'RUSSIAN')
    ||' NLS_SORT='||nvl(stdio.get_resource(c.profile,'NLS_SORT'),'BINARY')
    ||' NLS_NUMERIC_CHARACTERS='||nvl(stdio.get_resource(c.profile,'NLS_NUMERIC_CHARACTERS'),'''.,''')
    ||' NLS_TERRITORY='||nvl(stdio.get_resource(c.profile,'NLS_TERRITORY'),'CIS')
    ||' NLS_DATE_FORMAT='||nvl(stdio.get_resource(c.profile,'NLS_DATE_FORMAT'),'''DD/MM/YYYY''');
    stdio.set_resource(c.profile,'NLS_SETTINGS',s,'NLS настройки одним параметром');
    stdio.put_line_buf(c.profile||'.NLS_SETTINGS='||s);
  end loop;
  commit;
end;
/

exec executor.setnlsparameters

