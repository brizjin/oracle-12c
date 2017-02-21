exec stdio.enable_buf
set serveroutput on size 1000000
spool ufind5_&1..log
prompt Semantics correction: Types compatibility of references and collections
declare
  s1    varchar2(100) := 'PLP-TYPES_INCOMPATIBLE:%[ref %]%';
  s2    varchar2(100);
  s3    varchar2(100);
  cursor cm is
            select id,class_id,short_name  from methods
             where kernel='0' and exists
              (select 1 from errors where method_id=id
                  and text like s1 and class='W' and type<>'VIEW')
               --and id='6491217'
             order by 2,3;
  cursor cs(m_name sources.name%type) is
            select s.name,s.text,e.type,e.line,e.position,e.text etxt
              from sources s,errors e
             where e.method_id=m_name and e.text like s1
               and e.class='W' and e.type<>'VIEW'
               and s.name=e.method_id and s.type=e.type and s.line=e.line
             order by 3,4,5
            for update of s.text nowait;
  cursor cd(m_name sources.name%type) is
            select name,type,line,text
              from sources
             where name=m_name --and instr(text,'-- auto update ')=0
               and (upper(text) like s2 or upper(text) like s3)
             order by 2,3,4
            for update of text nowait;
  mid   varchar2(16);
  nam   varchar2(100);
  cls   varchar2(100);
  str   varchar2(2000);
  str1  varchar2(2000);
  sect  varchar2(30);
  found boolean;
  deps  boolean;
  pos   pls_integer;
  pos1  pls_integer;
  line  pls_integer;
  n     pls_integer;
  a     pls_integer;
  aa    pls_integer := ascii('A');
  az    pls_integer := ascii('Z');
  a0    pls_integer := ascii('0');
  a9    pls_integer := ascii('9');
  a#    pls_integer := ascii('#');
  a$    pls_integer := ascii('$');
  a_    pls_integer := ascii('_');
  adot  pls_integer := ascii('.');
  aop   pls_integer := ascii('(');
  acl   pls_integer := ascii(')');
  mtd   method.method_ref_tbl_t;
  procedure get_token is
    op  pls_integer;
  begin
    pos1 := pos;
    loop
      a := ascii(substr(str1,pos1,1));
      if a between aa and az then
        null;
      elsif pos1>pos then
        if a between a0 and a9 or a in (a#,a$,a_,adot) then
          null;
        elsif a=aop and op is null then
          op := pos1;
        elsif a=acl and op>0 then
          op := 0;
        else exit; end if;
      else exit; end if;
      pos1 := pos1+1;
    end loop;
    if op>0 then
      pos1 := op;
      a := aop;
    end if;
  end;
begin
if nvl(to_number('&&v_version','999.9'),1)<6.5 then
  n := 0;
  rtl.set_debug(1);
  for m in cm loop
    n := n+1;
    mtd(n).id:= m.id;
    mtd(n).class_id := m.class_id;
    mtd(n).short_name := m.short_name;
  end loop;
  for m in 1..n loop
    mid:=mtd(m).id;
    nam:=mtd(m).class_id||'.'||mtd(m).short_name;
    found:= false;
    deps := false;
    sect := '?';
    begin
    for c in cs(mid) loop
      if c.type<>sect then
        sect := c.type;
        line := 0;
      end if;
      if c.line>line then
       line:= c.line;
       if instr(c.text,'-- auto update ')>0 then
        stdio.put_line_buf(rpad(nam,32)||'#'||substr(c.type,1,1)||rpad(':'||line,5)||c.text);
       else
        str1:= upper(c.text);
        pos := c.position;
        get_token;
        if pos1>pos and (a is null or a<>adot) then
          stdio.put_line_buf(rpad(nam,32)||'>'||substr(c.type,1,1)||rpad(':'||line,5)||c.text);
          str := substr(str1,pos,pos1-pos);
          pos1:= instr(str,'.');
          if pos1>0 then
            str := substr(str,pos1+1);
          end if;
          pos1:= instr(c.etxt,'[ref ')+5;
          cls := substr(c.etxt,pos1,instr(c.etxt,']',pos1)-pos1);
          s2 := '%'||str||'_%REF_%['||cls||']%';
          s3 := '%'||str||'_%::['||cls||']%';
          for s in cd(mid) loop
           pos := instr(s.text,'-- auto update ');
           if pos>0 and (substr(str,length(str)-1)<>'_2' or instr(s.text,'-- auto update ',pos+10)>0) then
            found := true; exit;
           else
            str1:= upper(s.text);
            pos1:= 1;
            loop
              pos := nvl(instr(str1,str,pos1),0);
              exit when pos=0;
              if pos1=pos then
                get_token;
              else
                a := ascii(substr(str1,pos-1,1));
                if a between aa and az or a between a0 and a9 or a in (a#,a$,a_) then
                  pos1:= pos+1;
                  pos := 0;
                else
                  get_token;
                end if;
              end if;
              if pos1>pos and pos>0 then
                if substr(str1,pos,pos1-pos)=str then
                  pos := pos1; exit;
                end if;
              end if;
            end loop;
            if pos>0 then
              pos1 := instr(str1,'::['||cls||']',pos);
              if pos1>0 then
                pos:= -pos1;
              else
                pos1 := instr(str1,'REF',pos);
                if pos1>0 then
                  a := ascii(substr(str1,pos1-1,1));
                  if a between aa and az or a between a0 and a9 or a in (a#,a$,a_) then
                    pos := 0;
                  else
                    pos := pos1;
                    get_token;
                    if pos1>pos and substr(str1,pos,pos1-pos)='REF' then
                      null;
                    else
                      pos := 0;
                    end if;
                  end if;
                else
                  pos := 0;
                end if;
              end if;
            end if;
            if pos<>0 then
              if pos<0 then
                pos1:= 2;
                pos := -pos;
              else
                pos1:= 4;
              end if;
              str1 := substr(s.text,1,pos-1)||substr(s.text,pos+pos1)||' -- auto update '||TO_CHAR(SYSDATE,'DD/MM/YY');
              stdio.put_line_buf(rpad(nam,32)||substr(s.type,1,2)||rpad(':'||s.line,5)||s.text);
              stdio.put_line_buf(rpad(nam,32)||'NEW:   '||str1);
              update sources set sources.text=str1 where current of cd;
              found := true;
              if s.type='PUBLIC' then
                deps := true;
              end if;
            end if;
           end if;
          end loop;
          if found then
            str1 := c.text||' -- auto update '||TO_CHAR(SYSDATE,'DD/MM/YY')||' check';
            stdio.put_line_buf(rpad(nam,32)||'<'||substr(c.type,1,1)||rpad(':'||line,5)||str1);
            update sources set sources.text=str1 where current of cs;
          end if;
        end if;
       end if;
      end if;
    end loop;
    exception when rtl.resource_busy then
      stdio.put_line_buf('Method '||nam||' locked...');
    end;
    if found then
      if deps then
        method.compile_referencing(mid,p_compile=>false,p_commit=>false);
      else
        update methods set status='UPDATED' where id=mid;
      end if;
      commit;
    end if;
  end loop;
  commit;
  rtl.set_debug(0);
end if;
end;
/
spool off

