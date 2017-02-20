exec stdio.enable_buf
set serveroutput on size 1000000
spool ufind4.log
prompt Syntax correction for skipped dot
declare
  C_A pls_integer := ascii('A');
  C_Z pls_integer := ascii('Z');
  C_0 pls_integer := ascii('0');
  C_9 pls_integer := ascii('9');
  C_UNDER pls_integer := ascii('_');
  C_DOLLAR pls_integer := ascii('$');
  C_SHARP pls_integer := ascii('#');
  C_RPAR  pls_integer := ascii(']');
  C_LPAR  pls_integer := ascii('[');
  s1    varchar2(100) := 'PLP-PARSER_ERROR: syntax error';
  cursor cm is
            select id,class_id,short_name  from methods
            where kernel='0' and status='INVALID' and exists
              (select 1 from errors where method_id=id and text=s1)
            order by 2,3;
  cursor cs(m_name sources.name%type) is
            select s.name,s.type,s.line,s.text,e.position
              from sources s,errors e
            where e.method_id=m_name and e.text=s1
                and s.name=e.method_id and s.type=e.type and s.line=e.line
            for update of s.text nowait;
  mid   varchar2(16);
  nam   varchar2(100);
  str   varchar2(2000);
  found boolean;
  pos   pls_integer;
  dot   pls_integer;
  ch    pls_integer;
  n     pls_integer;
  mtd   method.method_ref_tbl_t;
  b boolean;
  procedure skip_word is
  begin
    b := false;
    loop
      ch := ascii(substr(str,pos,1));
      if pos>1 and
        ( ch between C_A and C_Z
       or ch between C_0 and C_9
       or ch in (C_UNDER, C_DOLLAR, C_SHARP) )
      then
        pos := pos-1;
        b := true;
      else
        exit;
      end if;
    end loop;
  end;
begin
  n := 0;
  for m in cm loop
    n := n+1;
    mtd(n).id:= m.id;
    mtd(n).class_id := m.class_id;
    mtd(n).short_name := m.short_name;
  end loop;
  for m in 1..n loop
    mid:=mtd(m).id;
    nam:=mtd(m).class_id||'.'||mtd(m).short_name;
    found:=false;
    begin
    for c in cs(mid) loop
      str := upper(c.text);
      pos := c.position-1;
      if pos>2 then
        skip_word;
        if b and pos>1 and ch=C_RPAR then
          dot := pos;
          pos := pos-1;
          skip_word;
        end if;
        if b and pos>1 and ch=C_LPAR then
          str := substr(c.text,1,dot)||'.'||substr(c.text,dot+1);
          str := str||' -- auto update '||TO_CHAR(SYSDATE,'DD/MM/YY');
          stdio.put_line_buf(rpad(nam,32)||substr(c.type,1,1)||rpad(':'||c.line,5)||c.text);
          stdio.put_line_buf(rpad(nam,32)||'NEW:  '||str);
          update sources set sources.text=str where current of cs;
          found:=true;
        end if;
      end if;
    end loop;
    exception when rtl.resource_busy then
      stdio.put_line_buf('Method '||nam||' locked...');
    end;
    if found then
      update methods set status='UPDATED' where id=mid;
      commit;
    end if;
  end loop;
  commit;
end;
/

spool off

