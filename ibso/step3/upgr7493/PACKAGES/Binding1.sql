prompt bindings
create or replace package bindings as
/*
 *	$HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/Binding1.sql $
 *	$Author: Alexey $
 *	$Revision: 15072 $
 *	$Date:: 2012-03-06 13:41:17 #$
 */
--
    procedure validate(p_meth_id varchar2, p_obj_id number);

    function attr_value_ext(p_obj_id varchar2, p_qual varchar2,p_class_id varchar2 default null) return varchar2;

    function get_value_ext (p_obj_id varchar2, p_xqual varchar2, p_meth_id varchar2 default null,p_class_id varchar2 default null) return varchar2;

    function par_var_value_ext(p_meth_id varchar2, p_qual varchar2, p_idx pls_integer default null) return varchar2;

    function get_system_id return varchar2;
    pragma restrict_references(get_system_id, WNDS, WNPS );

	procedure split_qual(p_class_id		in varchar2,
							p_qual		in varchar2,
							p_self_qual	out varchar2,
							p_ref_qual	out varchar2);

    function  split_qual(p_class_id     in varchar2,
							p_qual		in varchar2,
							p_self_qual	out varchar2,
                            p_ref_qual  out varchar2) return varchar2;

	function qual2host(p_class_id		in varchar2,
							p_qual		in varchar2) return varchar2;

end bindings;
/
sho err

