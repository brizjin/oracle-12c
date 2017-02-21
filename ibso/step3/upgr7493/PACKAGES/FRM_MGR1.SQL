prompt forms_mgr
CREATE OR REPLACE
package forms_mgr is
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/FRM_MGR1.SQL $
 *  $Author: shelkovnikova $
 *  $Revision: 74943 $
 *  $Date:: 2015-06-24 12:20:16 #$
 */

-- ¬ерси€ пакета forms_mgr
function get_version return varchar2;

procedure FRM_DROP(meth IN varchar2, p_pack boolean default false);

procedure FRM_CREATE(
     gmeth IN varchar2
    ,h in pls_integer
    ,w in pls_integer
    ,capt in varchar2
    ,vld_name in varchar2 default null
    ,prop in varchar2 default null
    );

procedure FRM_APPEND( gmeth IN varchar2, vld_name in varchar2 default null );

procedure CTL_CREATE(
     gmeth in varchar2
    ,pos in pls_integer
    ,t in pls_integer
    ,l in pls_integer
    ,h in pls_integer
    ,w in pls_integer
    ,qual in varchar2
    ,ctl in varchar2
    ,capt in varchar2
    ,contain in pls_integer
    ,tab in pls_integer
    ,prop in varchar2
    ,tips in varchar2
    ,depend in pls_integer
    ,typeid in varchar2
    ,vld_name in varchar2 default null
    ,crit_id in varchar2 default null
    ,crit_alias varchar2 default null
    ,crit_class_id varchar2 default null
    );
procedure TRANSLATE_CTL_CAPTION(meth_id_ varchar2, force varchar2 := '0');
procedure TRANSLATE_CTL_CAPTION;

procedure FRM_AUTO(gmeth in varchar2, p_pack boolean default true, p_include_vars boolean default false);
procedure FRM_TOUCH(meth in varchar2, p_pack boolean default true, p_readonly boolean default false);
procedure FRM_ALL_GENERATE;


function param_sn(qual varchar2) return varchar2 deterministic;

PRAGMA RESTRICT_REFERENCES (param_sn, WNDS, WNPS );

procedure UPDATE_FORM(p_meth_id varchar2, p_pack boolean default true);

function CHECK_PARAMVARS(p_meth_id varchar2, p_correct boolean default false) return varchar2;
function CHECK_CONTROLS (p_meth_id varchar2, p_correct boolean default false) return varchar2;

-- конвертаци€ строки свойств контролов
function conv_controls_prop(p_control varchar2, p_input_mask varchar2,
                            p_properties in out varchar2, p_class_id varchar2 default null) return boolean;
-- конвертаци€ свойств контролов заданной операции
procedure check_properties(p_meth_id varchar2);

end forms_mgr;
/
sho err
