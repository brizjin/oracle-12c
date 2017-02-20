prompt rtl_types body
create or replace package body 
/**
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/rtl_types2.sql $<br/>
 *  $Author: vasiltsov $<br/>
 *  $Revision: 96491 $<br/>
 *  $Date:: 2016-03-09 12:29:49 #$<br/>
 *  @headcom
 */

rtl_types as 

    VALUE_TYPE_VARCHAR2 constant varchar2(10) := 'VARCHAR2';
    VALUE_TYPE_NVARCHAR2 constant varchar2(10) := 'NVARCHAR2';

    function get_value_type return varchar2 is
    begin
      return VALUE_TYPE_VARCHAR2; -- Поддержка nvarchar2 отключена
      -- return VALUE_TYPE_NVARCHAR2; -- Поддержка nvarchar2 включена
    end;

end rtl_types;
/
show errors package body rtl_types