rem **************************************************************************
rem Перечень ошибок в операциях, связанных с отсутствием реквизитов или 
rem экземпляров в справочниках, Лагута О.Н., 24.01.2001
rem **************************************************************************

set echo off
set newpage 1
set pagesize 9999
set linesize 120
set trimspool on
set serveroutput on size 500000
set arraysize 1

prompt Создание списков классов:
prompt - в которых не найден экземпляр по заданным условиям;
prompt - в которых нет реквизита или операции.
prompt
prompt Списки классов записываются в файл cl_error.txt ...
spool cl_error.txt

set termout off

column today noprint new_value curdate
repheader left sql.user right curdate skip center 'Классы, приводящие к ошибкам'
select to_char(sysdate,'dd.mm.yyyy hh24:mi') today from dual;

declare
type class_type is record ( t integer,
                            str varchar2(100),
                            exm varchar2(100),
                            name varchar2(128) );
type class_table is table of class_type INDEX BY BINARY_INTEGER;
cl class_table;

i integer;
l integer;
n integer:=0;
line_num integer;
position integer;
s_type varchar2(20);
exemplar varchar2(100);
info varchar2(100);
err varchar2(30000);
est varchar2(30000);
sample1 varchar2(100):='Не найден экземпляр, удовлетворяющий заданным условиям';
sample2 varchar2(100):='нет реквизита или операции';
nl varchar2(1):=chr(10);

----------------------------------------------
procedure add_class (t integer, s varchar2, e varchar2 default null) is
i integer;
begin
i:=cl.first;
while i is not null loop
      if cl(i).t=t and cl(i).str=s and (e is null or cl(i).exm=e) then
         exit;
      end if;
      i:=cl.next(i);
end loop;
if i is null then
   n:=n+1;
   cl(n).t:=t;
   cl(n).str:=s;
   cl(n).exm:=e;
end if;
end add_class;
----------------------------------------------

begin
for meth in (select m.id, m.class_id, c.name from methods m, classes c
              where c.id=m.class_id and m.status not in ('VALID') and m.flags not in ('Z','R') and m.kernel='0'
              order by m.class_id) loop
    err:=substr(method.meth_errors(meth.id,false,false),1,30000);
    est:=null; 
    while length(err)>0 loop
        i:=instr(err,':',1,2)+1;
        l:=instr(err,chr(10),i,1);
        info:=substr(err,1,least(100,greatest(1,instr(err,':')-1))); 
        if l>0 then
           est:=rtrim(ltrim(substr(err,i,l-i)));
           err:=substr(err,l+1); 
         else
           est:=rtrim(ltrim(substr(err,i)));
           err:=null;            
        end if;   

        s_type:=null;
        i:=instr(info,'(');
        if i>0 then
           info:=substr(info,i+1);
           i:=instr(info,',');         
           if i>0 then
              line_num:=to_number(substr(info,1,i-1));
              info:=substr(info,i+1);
              i:=instr(info,')');         
              if i>0 then
                 position:=to_number(substr(info,1,i-1));
                 s_type:=substr(info,i+1);
              end if;
           end if;
        end if;

        if instr(est,sample1) > 0 then
           begin           
           select substr(s.text,position,100) into exemplar from sources s
              where s.name=meth.id and s.type=s_type and s.line=line_num;
              i:=instr(exemplar,')');
              if i>0 then 
                 exemplar:=substr(exemplar,1,i);
              end if; 
              i:=instr(exemplar,'(');
              if i>0 then 
                 exemplar:=substr(exemplar,i);
              end if; 
           exception when NO_DATA_FOUND then exemplar:=null;
           end;
           i:=instr(exemplar,'=');
           if i>0 then
              exemplar:=upper(substr(exemplar,1,i))||substr(exemplar,i+1);
           end if;
           add_class(1,substr(est,1,instr(est,' ')-1),translate(exemplar,'*()[] ','*'));

         elsif instr(est,sample2) > 0 and instr(est,'объекта')=0 then
           add_class(2,est);
        end if;
    end loop;    
end loop;

dbms_output.put_line(sample1||' в классах:'||nl);
n:=cl.first;
while n is not null loop
      if cl(n).t=1 then
         select name into cl(n).name from classes where id=cl(n).str;
         dbms_output.put_line(rpad(cl(n).str,17)||rpad(cl(n).exm,35)||' '||rpad(cl(n).name,36));
      end if;
      n:=cl.next(n);
end loop;

dbms_output.put_line(nl||'Классы с отсутствующими реквизитами:'||nl);
n:=cl.first;
while n is not null loop
      if cl(n).t=2 then
         dbms_output.put_line(cl(n).str);
      end if;
      n:=cl.next(n);
end loop;

end;
/
spool off
host notepad cl_error.txt;
exit