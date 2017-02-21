column xxx new_value usrcols noprint
select decode(sign(:db_version-10),-1,'''ERROR'', 0',
       'decode(e.property, 0,''ERROR'', 1, ''WARNING'', ''UNDEFINED''), e.error#') xxx
  from dual;

prompt * creating view dba_errors_simple
create or replace view
sys.dba_errors_simple(owner,name,type,sequence,line,position,text,attribute,message_number) as
select u.name, o.name,
decode(o.type#, 4, 'VIEW', 7, 'PROCEDURE', 8, 'FUNCTION', 9, 'PACKAGE',
               11, 'PACKAGE BODY', 12, 'TRIGGER', 13, 'TYPE', 14, 'TYPE BODY',
               22, 'LIBRARY', 28, 'JAVA SOURCE', 29, 'JAVA CLASS',
               43, 'DIMENSION', 'UNDEFINED'),
  e.sequence#, e.line, e.position#, e.text,
  &&usrcols
from sys.obj$ o, sys.error$ e, sys.user$ u
where o.obj# = e.obj#
  and o.owner# = u.user#
  and o.type# in (4, 7, 8, 9, 11, 12, 13, 14, 22, 28, 29, 43)
/
sho err view sys.dba_errors_simple

