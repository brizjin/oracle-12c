column xxx new_value oxxx noprint
select user xxx from dual;
prompt ADMIN_MGR
CREATE OR REPLACE PACKAGE ADMIN_MGR IS
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/adm_mgr1.sql $
 *  $Author: tfsservice $
 *  $Revision: 56518 $
 *  $Date:: 2014-11-27 17:42:59 #$
 */

  /* Пакет для создания глобальных ролей */
--
  OWNER      constant varchar2(30):='&&OWNER';
  GOWNER     constant varchar2(30):='&&GOWNER';
  SOWNER     constant varchar2(30):='&oxxx';
--
  NO_PRIVILEGES     exception;
  PRAGMA EXCEPTION_INIT( NO_PRIVILEGES, -1031 );
--
  procedure execute_sql(p_sql_block clob);
  procedure create_roles(p_drop boolean default true);
--
END;
/
sho err
