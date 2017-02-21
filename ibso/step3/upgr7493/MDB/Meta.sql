prompt views, которые нужно проверить на предмет обращения к VW_STATES.ID
select ud.NAME from user_dependencies ud where ud.REFERENCED_NAME = 'VW_STATES' and ud.TYPE = 'VIEW'
union
select c.short_name from CRITERIA_TRIES ct, criteria c where ct.CRITERIA_ID = c.id and ct.SHORT = 'STATES'
minus
select c.short_name from dependencies d, criteria c where d.REFERENCING_ID = c.id and (d.REFERENCED_ID = 'STATE_REF' or d.REFERENCED_ID = 'STATES') and d.REFERENCING_TYPE = 'V';

prompt пакеты (операции), которые нужно проверить на предмет обращения к VW_STATES.ID
select p.name, m.class_id, m.short_name from (
  select distinct ud.NAME name from user_dependencies ud where ud.REFERENCED_NAME = 'VW_STATES' and ud.TYPE like 'PACKAGE%'
  minus
  select distinct m.package_name name from dependencies d, methods m where d.REFERENCING_ID = m.id and (d.REFERENCED_ID = 'STATE_REF' or d.REFERENCED_ID = 'STATES') and d.REFERENCING_TYPE = 'M'
  minus
  select 'Z#STATES#INTERFACE' from dual
) p, methods m where p.name = m.package_name(+) order by p.name, m.class_id, m.short_name;

prompt views, которые нужно проверить на предмет обращения к STATES%id
select c.short_name from dependencies d, criteria c where d.REFERENCING_ID = c.id and d.REFERENCED_ID = 'STATES' and d.REFERENCING_TYPE = 'V' and REFERENCED_QUAL = '%id';

prompt операции, которые нужно проверить на предмет обращения к STATES%id
select m.package_name name, m.class_id, m.short_name from dependencies d, methods m where d.REFERENCING_ID = m.id and d.REFERENCED_ID = 'STATES' and d.REFERENCING_TYPE = 'M' and REFERENCED_QUAL = '%id' order by m.class_id, m.short_name;

prompt views, которые нужно проверить на предмет использования STATE_REF
select c.short_name from dependencies d, criteria c where d.REFERENCING_ID = c.id and d.REFERENCED_ID = 'STATE_REF' and d.REFERENCING_TYPE = 'V';

prompt операции, которые нужно проверить на предмет использования STATE_REF
select m.package_name name, m.class_id, m.short_name from dependencies d, methods m where d.REFERENCING_ID = m.id and d.REFERENCED_ID = 'STATE_REF' and d.REFERENCING_TYPE = 'M' order by m.class_id, m.short_name;

prompt ссылки на STATES - их нужно преобразовать...
select class_id, table_name, column_name from class_tab_columns where target_class_id = 'STATES';