prompt patch_tool
create or replace package patch_tool as
    /*
     *	$HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/patch_tool1.sql $
     *	$Author: Alexey $
     *  $Revision: 15072 $
     *	$Date:: 2012-03-06 13:41:17 #$
     */

    /**
     * COMPILE\CTLPRINT.SQL
     */
    procedure ctl_print(p_rebuild varchar2, p_delparam varchar2,
                        p_delctls varchar2, p_ignore varchar2);
    /**
     * COMPILE\c_clear.sql
     */
    procedure clear_methods;

    /**
     * U_SOURCE\C_AFTER.SQL
     */
    procedure mv_clr_obj_refcing_to_mtd_mgr;
    /**
     * U_SOURCE\U_CTLS.SQL
     */
    procedure variants_fix;
    /**
     * U_SOURCE\U_SHARE.SQL
     */
    procedure update_share;
    /**
     * U_SOURCE\U_CACHE.SQL
     */
    procedure update_compiler;
    /**
     * U_SOURCE\U_SYS.SQL
     */
    procedure methods_fix;

    /**
     * TOOLS\DBF\C_ALL.SQL
     */
    procedure register_dbf;
    /**
     * TOOLS\CALENDAR\c_undo.sql
     */
    procedure register_calendar;
    /**
     * TOOLS\CALENDAR\c_first.sql
     */
    procedure unregister_calendar;

    /**
     * V5X\VB_CONV.SQL
     */
    procedure update_vbs;

    /**
     * V60\C_ALL.SQL
     */
    procedure update_props;

    /**
     * up.sql
     */
    procedure update_kern_cls_and_meth;

    procedure update_crit_formula;

    -- Конвертация свойств всех контролов
    procedure update_controls_props;

end;
/
show errors

