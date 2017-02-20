exec dbms_session.reset_package
exec executor.setnlsparameters
exec storage_mgr.verbose:=true
exec storage_mgr.pipe_name:='&&pipe_name'
exec storage_utils.verbose := true
exec storage_utils.pipe_name := '&&pipe_name'

prompt rebuilding partition views
declare
    n   pls_integer;
    t   "CONSTANT".refstring_table;
begin
    n := 0;
    for c in (
        select class_id from class_partitions where partition_position is not null
        union
        select class_id from class_tables where param_group like 'PART%' or current_key is not null
        union
        select id from classes where storage_group like 'PART%'
    ) loop
        n := n+1;
        t(n) := c.class_id;
    end loop;
    for i in 1..n loop
        storage_utils.ws('Refreshing description of '||t(i));
        part_mgr.refresh_description(t(i));
        part_mgr.create_partition_views(t(i));
    end loop;
end;
/

prompt rebuilding objects,col2obj,collections views
exec storage_mgr.create_objects_view(true)
exec storage_mgr.create_collection_views(true,true)
alter package rtlobj compile body;

rem prompt filling information about indexes
rem exec index_mgr.retrofit;

