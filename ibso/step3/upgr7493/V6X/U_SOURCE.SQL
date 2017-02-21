exec stdio.enable_buf
set serveroutput on size 1000000
declare
  cursor cm is
            select m.id,m.class_id,m.short_name
              from methods m
            where m.kernel='0' and m.package_name is not null and exists
              (select 1 from sources s where m.id=s.name
                  and s.type<>'VBSCRIPT' and
                  (instr(s.text,'--#')>0 OR instr(s.text,'/*#')>0))
            order by 2,3;
  cursor cs(m_name sources.name%type) is
            select * from sources
            where name=m_name and type<>'VBSCRIPT' and
              (instr(text,'--#')>0 OR instr(text,'/*#')>0)
            for update of text nowait
            ;
  mid   methods.id%type;
  txt   varchar2(2000);
  txt1  varchar2(2000);
  nam   varchar2(100);
  i     pls_integer;
  j     pls_integer;
  k     pls_integer;
  n     pls_integer;
  mtd   method.method_ref_tbl_t;
  found boolean;
begin
if nvl(to_number('&&v_version','999.9'),1)<6.1 then
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
      txt := c.text;
      i := instr(txt,'--#');
      if i=0 then
        i := instr(txt,'/*#');
      end if;
      if i>0 then
        txt1 := upper(ltrim(replace(substr(txt,i+3),chr(9),' ')));
        if ascii(txt1) between ascii('A') and ascii('Z') then
          txt1 := substr(txt,1,i-1);
          k := 0;
          j := 1;
          loop
            j := instr(txt1,'''',j);
            if j>0 then
              k := k+1;
              j := j+1;
            else
              exit;
            end if;
          end loop;
          if k mod 2 = 1 then
            i := 0;
          end if;
        else
          i := 0;
        end if;
      end if;
      if i>0 then
        txt := substr(txt,1,i+1)||'!'||substr(txt,i+3);
        if length(txt)<1976 then
          txt := txt||' -- auto update '||TO_CHAR(SYSDATE,'DD/MM/YY');
        end if;
        stdio.put_line_buf(rpad(nam,32)||substr(c.type,1,1)||rpad(':'||c.line,5)||c.text);
        stdio.put_line_buf(rpad(nam,32)||'NEW:  '||txt);
        update sources set text=txt where current of cs;
        found:=true;
      end if;
    end loop;
    exception when rtl.resource_busy then
      stdio.put_line_buf('Method '||mid||' locked...');
    end;
    if found then
      update methods set status='UPDATED' where id=mid;
      commit;
    end if;
  end loop;
end if;
end;
/

