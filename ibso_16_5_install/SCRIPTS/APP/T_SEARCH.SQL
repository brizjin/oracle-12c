rem **************************************************************************
rem Поиск строки в Системе, Лагута О.Н., 29.12.2000
rem **************************************************************************

set ver off
set echo off
set pagesize 9999
set linesize 125

prompt
accept sample char prompt 'Введите для поиска в Системе строку: '
prompt
prompt =========== Строка поиска в теле прикладных пакетов F,FD,FDP,USERLIB ===========
select substr(s.name,1,16) Пакет, s.type Тип, s.line Строка,
       substr(ltrim(translate(s.text,chr(9)||chr(10)||chr(13)||' ',' ')),
              greatest(1,instr(upper(ltrim(s.text)),upper('&sample'))-20),85) Строка
from user_source s
where s.name in ('F','FD','FDP','USERLIB') and upper(s.text) like upper('%&sample%')
order by s.name,s.line;

prompt =========== Строка поиска в формулах отчетов CrystalReports ===========
select m.class_id Класс, m.short_name Представление, substr(m.name,1,20) Наименование,
       substr(ltrim(translate(f.formula,chr(9)||chr(10)||chr(13)||' ',' ')),
              greatest(1,instr(upper(f.formula),upper('%&sample%'))-20),70) Формула
from report_formula f, methods m
where upper(f.formula) like upper('%&sample%') and m.id = f.method_id
order by m.class_id, m.short_name;

rem prompt =========== Строка поиска в теле процедур CrystalReports ===========
rem Отключено из-за медленности
rem select substr(s.name,1,16) Пакет, s.type Тип, s.line Строка,
rem       substr(ltrim(translate(s.text,chr(9)||chr(10)||chr(13)||' ',' ')),
rem              greatest(1,instr(upper(ltrim(s.text)),upper('&sample'))-20),85) Строка
rem from user_source s, procedures p
rem where p.name=s.name and upper(s.text) like upper('%&sample%')
rem order by s.name,s.line;

prompt =========== Строка поиска в условиях представлений ===========
select c.class_id Класс, c.short_name Представление, substr(c.name,1,20) Наименование,
       substr(ltrim(translate(c.condition,chr(9)||chr(10)||chr(13)||' ',' ')),
              greatest(1,instr(upper(c.condition),upper('&sample'))-20),56) Условие
from criteria c
where upper(c.condition) like upper('%&sample%')
order by c.class_id, c.short_name;

prompt =========== Строка поиска в экранных формах представлений ===========
select m.class_id Класс, m.short_name Представление, substr(m.name,1,20) Наименование,
       substr(ltrim(translate(m.body_where,chr(9)||chr(10)||chr(13)||' ',' ')),
              greatest(1,instr(upper(m.body_where),upper('&sample'))-20),70) Условие
from methods m
where upper(m.body_where) like upper('%&sample%')
order by m.class_id, m.short_name;

prompt =========== Строка поиска в колонках представлений ===========
select c.class_id Класс, c.short_name Представление, substr(c.name,1,20) Наименование, substr(l.name,1,20) Колонка,
       substr(ltrim(translate(l.data_source,chr(9)||chr(10)||chr(13)||' ',' ')),
              greatest(1,instr(upper(l.data_source),upper('%&sample%'))-10),35) Источник_данных
from criteria_columns l, criteria c
where upper(l.data_source) like upper('%&sample%') and c.id=l.criteria_id
order by c.class_id, c.short_name, l.position;

prompt =========== Строка поиска в формулах параметров методов ===========
select m.class_id Класс, m.short_name Метод, substr(m.name,1,20) Наименование, substr(p.short_name,1,16) Параметр,
       substr(ltrim(translate(p.crit_formula,chr(9)||chr(10)||chr(13)||' ',' ')),
              greatest(1,instr(upper(p.crit_formula),upper('&sample'))-20),53) Условие
from method_parameters p, methods m
where upper(p.crit_formula) like upper('%&sample%') and m.id=p.method_id
order by m.class_id, m.short_name;

prompt =========== Строка поиска в формулах переменных методов ===========
select m.class_id Класс, m.short_name Метод, substr(m.name,1,20) Наименование, substr(v.short_name,1,16) Переменная,
       substr(ltrim(translate(v.crit_formula,chr(9)||chr(10)||chr(13)||' ',' ')),
              greatest(1,instr(upper(v.crit_formula),upper('&sample'))-20),53) Условие
from method_variables v, methods m
where upper(v.crit_formula) like upper('%&sample%') and m.id=v.method_id
order by m.class_id, m.short_name;

prompt =========== Строка поиска в теле методов ===========
select m.class_id Класс, m.short_name Метод, substr(m.name,1,20) Наименование, substr(m.tag,1,10) Метка, 
       substr(ltrim(translate(s.text,chr(9)||chr(10)||chr(13)||' ',' ')),
              greatest(1,instr(upper(ltrim(s.text)),upper('&sample'))-20),59) Строка
from sources s, methods m
where upper(s.text) like upper('%&sample%') and m.id = s.name
order by m.class_id, m.name, s.line;

rem c_document_user
rem {c_code
rem viewfun.



