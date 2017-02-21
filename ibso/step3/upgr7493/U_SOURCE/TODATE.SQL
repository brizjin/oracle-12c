exec stdio.enable_buf
set serveroutput on size 1000000
spool todate.log
prompt !!! WARNING: TO_DATE(<DATE>) unreasonable call !!!
declare
  s1    varchar2(100) := 'PLP-PARSER_ERROR: ORA-01460:%';
  v_id  varchar2(16)  := chr(0);
begin
  for c in (
    select m.class_id, m.short_name, e.type, e.line, e.position, e.text, m.id
      from methods m, errors e
     where m.kernel='0' and m.id = e.method_id
       and e.text like s1 and class='W'
     order by 1,2,3,4,5
  ) loop
    if c.id <> v_id then
      stdio.put_line_buf('----');
      stdio.put_line_buf(message.gettext('EXEC', 'ERRORS_FOR_METH', c.id, c.class_id, c.short_name));
      v_id := c.id;
    end if;
    stdio.put_line_buf('W('||to_char(c.line)||','||to_char(c.position)||')'||c.type||': ' ||c.text);
  end loop;
  stdio.put_line_buf('----');
end;
/
spool off

spool specs.log
prompt !!! WARNING: Differences in specifications/implementations of functions !!!
declare
  s1    varchar2(100) := 'PLP-METHOD_NOT_FOUND: %';
  v_id  varchar2(16)  := chr(0);
begin
  for c in (
    select m.class_id, m.short_name, e.class, e.type, e.line, e.position, e.text, m.id
      from methods m, errors e
     where m.kernel='0' and m.id = e.method_id
       and e.text like s1 and instr(e.text,'.')=0
     order by 1,2,3,4,5,6
  ) loop
    if c.id <> v_id then
      stdio.put_line_buf('----');
      stdio.put_line_buf(message.gettext('EXEC', 'ERRORS_FOR_METH', c.id, c.class_id, c.short_name));
      v_id := c.id;
    end if;
    stdio.put_line_buf(c.class||'('||to_char(c.line)||','||to_char(c.position)||')'||c.type||': ' ||c.text);
  end loop;
  stdio.put_line_buf('----');
end;
/
spool off

spool doubt.log
prompt !!! WARNING: uncertain method calls !!!
declare
  s1    varchar2(100) := 'PLP-TOO_MANY_MATCHES: %';
  v_id  varchar2(16)  := chr(0);
begin
  for c in (
    select m.class_id, m.short_name, e.type, e.line, e.position, e.text, m.id
      from methods m, errors e
     where m.kernel='0' and m.id = e.method_id
       and e.text like s1 and class='W'
     order by 1,2,3,4,5
  ) loop
    if c.id <> v_id then
      stdio.put_line_buf('----');
      stdio.put_line_buf(message.gettext('EXEC', 'ERRORS_FOR_METH', c.id, c.class_id, c.short_name));
      v_id := c.id;
    end if;
    stdio.put_line_buf('W('||to_char(c.line)||','||to_char(c.position)||')'||c.type||': ' ||c.text);
  end loop;
  stdio.put_line_buf('----');
end;
/
spool off

spool updates.log
prompt !!! WARNING: subquery updates !!!
declare
  s1    varchar2(100) := 'PLP-DML_QUERY: %';
  v_id  varchar2(16)  := chr(0);
begin
  for c in (
    select m.class_id, m.short_name, e.type, e.line, e.position, e.text, m.id
      from methods m, errors e
     where m.kernel='0' and m.id = e.method_id
       and e.text like s1 and class='W'
     order by 1,2,3,4,5
  ) loop
    if c.id <> v_id then
      stdio.put_line_buf('----');
      stdio.put_line_buf(message.gettext('EXEC', 'ERRORS_FOR_METH', c.id, c.class_id, c.short_name));
      v_id := c.id;
    end if;
    stdio.put_line_buf('W('||to_char(c.line)||','||to_char(c.position)||')'||c.type||': ' ||c.text);
  end loop;
  stdio.put_line_buf('----');
end;
/
spool off

