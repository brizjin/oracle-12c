exec stdio.enable_buf
set serveroutput on size 1000000
spool ufind1_&1..log
prompt Syntax correction: PLP-NOT_OBJECT_REF error
declare
  s1    varchar2(100) := 'PLP-NOT_OBJECT_REF:%';
  cursor cm is
            select id,class_id,short_name  from methods
            where kernel='0' and status='INVALID' and exists
              (select 1 from errors where method_id=id and text like s1)
            order by 2,3;
  cursor cs(m_name sources.name%type) is
            select s.name,s.type,s.line,s.text,e.position
              from sources s,errors e
            where e.method_id=m_name and e.text like s1
                and s.name=e.method_id and s.type=e.type and s.line=e.line
            for update of s.text nowait;
  mid   varchar2(16);
  nam   varchar2(100);
  str   varchar2(2000);
  found boolean;
  pos   binary_integer;
  n     pls_integer;
  mtd   method.method_ref_tbl_t;
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
      str := c.text;
      pos := c.position;
      if substr(str,pos,2)='->' then
        str := substr(str,1,pos-1)||'.'||substr(str,pos+2)
            ||' -- auto update '||TO_CHAR(SYSDATE,'DD/MM/YY');
        stdio.put_line_buf(rpad(nam,32)||substr(c.type,1,1)||rpad(':'||c.line,5)||c.text);
        stdio.put_line_buf(rpad(nam,32)||'NEW:  '||str);
        update sources set sources.text=str where current of cs;
        found:=true;
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
