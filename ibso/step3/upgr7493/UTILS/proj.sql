prompt updating project
update project set owner='&&owner' where type in ('TABLE','PACKAGE','PROCEDURE','FUNCTION');
update project set owner='&&gowner' where type='SEQUENCE';
update project set owner='&&downer1'  where type='TABLE' and loaddata='S';
commit;