select c.*,decode(sign(cnt-200),1,'!ERROR!','WARNING') from (
select child_id,count(1) cnt
 from class_tab_columns,class_relations
where deleted='0' and class_id=parent_id
group by child_id
union all
select child_id,count(1)
 from class_rec_fields,class_relations
where class_id=parent_id
group by child_id
) c where cnt>150
order by cnt desc
/

