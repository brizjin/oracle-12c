exec stdio.enable_buf
set serveroutput on size 1000000
spool ufind2.log
prompt Sematics correction using STDLIB.USERID - forcing restrict_referencing
declare
  s1    varchar2(100) := 'STDLIB.USERID';
  s2    varchar2(100) := 'PLS-00452:%';
  cursor cm is
            select id,class_id,short_name  from methods m
            where kernel='0' and status='PROCESSED' and exists
              (select 1 from user_errors e where e.name=m.package_name
                  and e.type='PACKAGE BODY' and e.text like s2)
            order by 2,3;
  cursor cs(m_name sources.name%type) is
            select s.name,s.type,s.line,s.text
              from sources s
             where s.name=m_name and type<>'VBSCRIPT' and instr(upper(text),s1)>0
            for update of s.text nowait;
  mid   varchar2(16);
  nam   varchar2(100);
  str   varchar2(2000);
  found boolean;
  pos   pls_integer;
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
      str := upper(c.text);
      pos := instr(str,s1);
      if pos=1 or substr(str,pos-1,1)<>'''' then
        str := rtl.safe_replace(c.text,s1,'STDLIB.USER_ID')
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
  --rollback;
  commit;
end;
/
spool off
