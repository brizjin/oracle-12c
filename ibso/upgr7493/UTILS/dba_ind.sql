prompt view dba_ind_columns_1
create or replace view dba_ind_columns_1 (
  index_owner,
  index_name,
  table_owner,
  table_name,
  column_name,
  column_position,
  column_length,
  char_length,
  descend
) as
select io.name, idx.name, bo.name, base.name, c.name,
       /*decode(bitand(c.property, 1024), 1024,
              (select decode(bitand(tc.property, 1), 1, ac.name, tc.name)
              from sys.col$ tc, attrcol$ ac
              where tc.intcol# = c.intcol#-1
                and tc.obj# = c.obj#
                and tc.obj# = ac.obj#(+)
                and tc.intcol# = ac.intcol#(+)),
              decode(ac.name, null, c.name, ac.name)),*/
       ic.pos#, c.length, c.spare3,
       decode(bitand(c.property, 131072), 131072, 'DESC', 'ASC')
from sys.col$ c, sys.obj$ idx, sys.obj$ base, sys.icol$ ic,
     sys.user$ io, sys.user$ bo, sys.ind$ i--, sys.attrcol$ ac
where ic.bo# = c.obj#
  --and decode(bitand(i.property,1024),0,ic.intcol#,ic.spare2) = c.intcol#
  and ic.intcol# = c.intcol#
  and ic.bo# = base.obj#
  and io.user# = idx.owner#
  and bo.user# = base.owner#
  and ic.obj# = idx.obj#
  and idx.obj# = i.obj#
  and i.type# in (1, 2, 3, 4, 6, 7, 9)
  --and c.obj# = ac.obj#(+)
  --and c.intcol# = ac.intcol#(+)
  and bitand(i.property,1024)=0
/

