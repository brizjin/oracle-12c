select m.class_id,m.short_name,m.id,d.referenced_id,substr(d.referenced_qual,1,100)
from methods m, dependencies d
where m.id=d.referencing_id and d.referencing_type='M' and d.referenced_type='A'
  and d.referenced_id in ('CLASS_ATTRIBUTES','METHOD','STATES') and d.referenced_qual='%class'
/

select c.class_id,c.short_name,c.id,d.referenced_id,substr(d.referenced_qual,1,100)
from criteria c, dependencies d
where c.id=d.referencing_id and d.referencing_type='V' and d.referenced_type='A'
  and d.referenced_id in ('CLASS_ATTRIBUTES','METHOD','STATES') and d.referenced_qual='%class'
/
