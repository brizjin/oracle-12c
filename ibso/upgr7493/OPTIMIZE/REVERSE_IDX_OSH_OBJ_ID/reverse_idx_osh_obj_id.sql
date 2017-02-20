spool reverse_idx_osh_obj_id.log

set serveroutput on size 100000

@..\..\settings

prompt alter index 

declare
    owner varchar2(128):='&&IBSO_OWNER';
    tab_type pls_integer:=utils.OSH;
begin
    utils.drop_indexes(owner,tab_type);
    utils.create_indexes(owner,tab_type);
end;
/

spool off
exit

