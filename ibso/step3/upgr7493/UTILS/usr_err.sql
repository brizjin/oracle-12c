prompt * creating view user_errors_simple
create or replace view
sys.user_errors_simple(name,type,sequence,line,position,text) as
select o.name,
decode(o.type#, 4, 'VIEW', 7, 'PROCEDURE', 8, 'FUNCTION', 9, 'PACKAGE',
               11, 'PACKAGE BODY', 12, 'TRIGGER', 13, 'TYPE', 14, 'TYPE BODY',
               22, 'LIBRARY', 28, 'JAVA SOURCE', 29, 'JAVA CLASS',
               43, 'DIMENSION', 'UNDEFINED'),
  e.sequence#, e.line, e.position#, e.text
from sys.obj$ o, sys.error$ e
where o.obj# = e.obj#
  and o.type# in (4, 7, 8, 9, 11, 12, 13, 14, 22, 28, 29, 43)
  and o.owner# = userenv('SCHEMAID')
/
sho err view sys.user_errors_simple


