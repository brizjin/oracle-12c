Prompt * creating view user_nested_tables_simple
create or replace view sys.user_nested_tables_simple
(table_name, table_type_owner, table_type_name, parent_table_name, parent_table_column, storage_spec, return_type, element_substitutable)
as
select o.name,
       nvl2(ct.synobj#, (select u.name from user$ u, obj$ o
            where o.owner#=u.user# and o.obj#=ct.synobj#), ut.name),
       nvl2(ct.synobj#, (select o.name from obj$ o
            where o.obj#=ct.synobj#), ot.name),
       op.name, c.name,
       lpad(decode(bitand(ct.flags, 64), 64, 'USER_SPECIFIED', 'DEFAULT'), 30),
       lpad(decode(bitand(ct.flags, 32), 32, 'LOCATOR', 'VALUE'), 20),
       lpad((case when bitand(ct.flags, 5120)=0 and bitand(t.properties, 8)= 8
       then 'Y' else 'N' end), 25)
from sys.ntab$ n, sys.obj$ o, sys.obj$ op, sys.obj$ ot,
  sys.col$ c, sys.coltype$ ct, sys.user$ ut, sys.type$ t, sys.collection$ cl
where o.owner# = userenv('SCHEMAID')
  and op.owner#= userenv('SCHEMAID')
  and n.obj# = op.obj#
  and n.ntab# = o.obj#
  and c.obj# = op.obj#
  and n.intcol# = c.intcol#
  and bitand(c.property,1)=0
  and op.obj# = ct.obj#
  and ct.toid = ot.oid$
  and ct.intcol#=n.intcol#
  and ot.owner# = ut.user#
  and ct.toid=cl.toid
  and cl.elem_toid=t.tvoid
  and bitand(ct.flags,4)=4
  and bitand(c.property,32768) != 32768
/
sho err view sys.user_nested_tables_simple

