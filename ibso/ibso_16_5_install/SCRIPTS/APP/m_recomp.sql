rem **************************************************************************
rem Перекомпиляция операций с определенным статусом, Лагута О.Н., 24.01.2001
rem **************************************************************************

set serveroutput on size 100000
set ver off

select status Статус, count(*) Колич_методов from methods where flags not in ('Z','R') group by status;

prompt
prompt Перекомпиляция методов со статусом:
prompt I - INVALID
prompt N - NOT COMPILED
prompt P - PROCESSED
prompt U - UPDATED
prompt или недействительных методов класса: CL=[%]имя_класса[%]
prompt или всех методов класса: +CL=[%]имя_класса[%]
prompt
accept code char prompt 'Введите статус операций (I,N,P,U, любой другой или имя класса):'
prompt
prompt Протокол компиляции записывается в канал COMPILE$ ...
set termout off

declare
c varchar2(30);
i integer;
status varchar2(30);
stemp varchar2(30) := 'FOR_COMPILE';
begin
c:=upper('&&code');
i:=instr(c,'=');
if i>0 and substr(c,1,i) like '%CL=' then   -- Методы класса
   update methods set status=stemp
      where flags!='Z' and class_id like substr(c,i+1) and
            (substr(c,1,1)='+' or status!='VALID');
   c:=stemp;
end if;

if c = 'I' then
   status:='INVALID';
 elsif c = 'N' then
   status:='NOT COMPILED';
 elsif c = 'P' then
   status:='PROCESSED';
 elsif c = 'U' then
   status:='UPDATED';
 else
   status:=c;
end if;
i:=rtl.open;
method.compile_status(status);
end;
/