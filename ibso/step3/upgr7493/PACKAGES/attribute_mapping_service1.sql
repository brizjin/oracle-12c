prompt attribute_mapping_service
create or replace
package attribute_mapping_service is
/**
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/attribute_mapping_service1.sql $<br/>
 *  $Author: Alexey $<br/>
 *  $Revision: 15072 $<br/>
 *  $Date:: 2012-03-06 13:41:17 #$<br/>
 *  @headcom
 */
    function get_version return varchar2;

    procedure enable;
    procedure disable;
    function is_enabled return boolean;
end;
/
show errors

