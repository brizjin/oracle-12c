prompt user_context
create or replace package user_context is
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/user_context1.sql $
 *  $Author: Alexey $
 *  $Revision: 15072 $
 *  $Date:: 2012-03-06 13:41:17 #$
 */
    procedure set_sys_name;
    procedure set_attribute(p_name varchar2, p_value varchar2);
    procedure clear;

end user_context;
/
sho err

