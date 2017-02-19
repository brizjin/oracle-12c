rem **************************************************************************
rem Перестроение таблиц классов (приведение в соответствие имен колонок таблиц
rem именам реквизитов классов, Лагута О.Н., 04.11.1999
rem **************************************************************************

set serveroutput on size 100000
set ver off
prompt Для перестроения таблиц введите через запятую
accept classes char prompt ' список классов: '
prompt
prompt Протокол записывается в канал RECONCILE ...

declare
i integer;
c varchar2(16);
cl varchar2(200);
begin
cl:=upper(ltrim(rtrim('&&classes')));
i:=rtl.open;
while length(cl)>0 loop
    i:=instr(cl,',');
    if i > 0 then
       c:=substr(cl,1,i-1);
       cl:=substr(cl,i+1); 
     else
       c:=cl;
       cl:='';
    end if;
    select count(*) into i from classes where id=c;
    If i>0 then 
       storage_mgr.reconcile_class_table(c,true,'reconcile');
     else
       dbms_output.put_line('Класс '||c||' Не найден!');
    end if;
end loop;
end;
/
