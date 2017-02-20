prompt types
create or replace package types as
/*
 *	$HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/TYPES1.SQL $
 *  $Author: Alexey $
 *	$Revision: 15072 $
 *	$Date:: 2012-03-06 13:41:17 #$
 */
--
function getquala(
     p_class_id in varchar2
    ,p_attr_id in varchar2
    ,p_qual    in varchar2 default ' ') return  varchar2 deterministic;
pragma restrict_references ( getquala, wnds, wnps, trust );
--
function getqualp(
     p_meth_id in varchar2
    ,p_parpos  in varchar2
    ,p_qual    in varchar2 default ' ') return  varchar2 deterministic;
pragma restrict_references ( getqualp, wnds, wnps );
--
function getqualt(
     p_class_id in varchar2
    ,p_qual    in varchar2) return  varchar2 deterministic;
pragma restrict_references ( getqualt, wnds, wnps );
--
function getqualc(
     p_class_id in varchar2
    ,p_qual    in varchar2) return  varchar2 deterministic;
pragma restrict_references ( getqualc, wnds, wnps );
--
procedure qualprop(
		p_class_id	in varchar2,
		p_qual		in varchar2,
		p_elem_class		out nocopy varchar2,
		p_elem_base_class	out nocopy varchar2,
		p_elem_target_class	out nocopy varchar2,
		p_elem_name			in out nocopy varchar2,
        p_separator in varchar2 default ' '
		);
PRAGMA RESTRICT_REFERENCES ( qualprop, WNDS, WNPS, TRUST );
--
procedure qual_prop(
		p_class_id	in varchar2,
		p_qual		in varchar2,
		p_elem_class		out varchar2,
		p_elem_base_class	out varchar2,
		p_elem_name			in out nocopy varchar2
		);
pragma restrict_references ( qual_prop, wnds, wnps);
--
procedure get_qual_name(
		p_class_id	in varchar2,
		p_qual		in varchar2,
		p_qual_name	in out nocopy varchar2,
		p_separator	in varchar2
		);
PRAGMA RESTRICT_REFERENCES ( get_qual_name, WNDS, WNPS );

function qual_name(
		p_class_id	in varchar2,
		p_qual		in varchar2,
		p_separator	in varchar2 default ' '
		) return varchar2 deterministic;

PRAGMA RESTRICT_REFERENCES ( qual_name, WNDS, WNPS );
--
procedure qualprop_ext(
		p_method_id	in varchar2,
		p_class_id	in varchar2,
		p_qual		in varchar2,
		p_elem_class		out nocopy varchar2,
		p_elem_base_class	out nocopy varchar2,
		p_elem_target_class	out nocopy varchar2,
		p_elem_name			in out nocopy varchar2,
        p_separator in varchar2 default ' '
		);
pragma restrict_references ( qualprop_ext, wnds, wnps );
--
procedure qual_prop_ext(
		p_method_id	in varchar2,
		p_class_id	in varchar2,
		p_qual		in varchar2,
		p_elem_class		out varchar2,
		p_elem_base_class	out varchar2,
		p_elem_name			in out nocopy varchar2
		);
pragma restrict_references ( qual_prop_ext, wnds, wnps );
--
procedure correct_qual(
		p_class_id	in varchar2,
		p_qual		in out nocopy varchar2
		);
--
function obj_qual_class(
     p_obj_id in varchar2
    ,p_qual   in varchar2) return  varchar2 deterministic;
--
end types;
/
sho err

