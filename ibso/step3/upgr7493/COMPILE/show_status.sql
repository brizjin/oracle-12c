prompt methods status
select status,count(1) from methods
 group by rollup(status) order by 1;

prompt criteria non-existent
select count(1) from criteria where not exists
    (select /*+ NO_UNNEST */ 1 from user_views where view_name=short_name);

prompt user_objects status
select object_type,status,count(1) from user_objects
 group by rollup(object_type,status)
 order by 1,2;
select constraint_type,count(1) from user_constraints
 group by rollup(constraint_type)
 order by 1;

