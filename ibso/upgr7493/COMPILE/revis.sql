set pagesize 200
set linesize 250
SET HEADING OFF
SET FEEDBACK OFF
spool revis.log
select s.name pack,
       decode(s.type, 'PACKAGE', null, 'BODY') typ,
       substr(rtrim(replace(substr(s.text,
                                   instr(s.text, 'Revision:'),
                                   instr(s.text,
                                         '$',
                                         instr(s.text, 'Revision:')) -
                                   instr(s.text, 'Revision:')),
                            chr(9))),
              1,
              60)
  from user_source s
 where instr(s.type, 'PACKAGE') = 1
   and instr(s.text, '$Revision: ') > 0
   and s.line < 8
   and s.name not like 'Z$%'
   and s.name not like 'Z#%'
   and s.name not like 'ZZ$%'
   and exists(select 1 from project p where p.name = s.name and p.type = 'PACKAGE')
 order by s.name, s.type
/
spool off