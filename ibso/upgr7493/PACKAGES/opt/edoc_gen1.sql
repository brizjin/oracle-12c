prompt edoc_gen
create or replace package edoc_gen as
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/edoc_gen1.sql $
 *  $Author: almakarov $
 *  $Revision: 42440 $
 *  $Date:: 2014-02-25 11:15:23 #$
 */
-- versioning core interface
function get_core_interface return pls_integer;
--
/**
 * for class interface packages
 */
procedure get_procedures(p_class_id varchar2, p_ref_type varchar2,  t in out nocopy dbms_sql.varchar2s,
                        p_vars out varchar2, p_check out varchar2,
                        p_set out varchar2, p_finish out varchar2);
function get_definitions(p_class_id varchar2, p_ref_type varchar2) return varchar2;

end;
/
show err

