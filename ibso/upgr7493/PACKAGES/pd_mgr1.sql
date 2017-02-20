prompt PD_MGR
CREATE OR REPLACE PACKAGE PD_MGR IS
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/pd_mgr1.sql $
 *  $Author: Alexey $
 *  $Revision: 15072 $
 *  $Date:: 2012-03-06 13:41:17 #$
 */
--
  procedure set_meth(p_id varchar2, p_flag pls_integer, p_commit pls_integer default 1);
  procedure set_crit(p_id varchar2, p_flag pls_integer, p_commit pls_integer default 1);
  procedure set_group(p_arr_id "CONSTANT".REFSTRING_TABLE, p_arr_type "CONSTANT".REFSTRING_TABLE,
                     p_flag pls_integer, p_commit pls_integer default 1);

--
END;
/
sho err

