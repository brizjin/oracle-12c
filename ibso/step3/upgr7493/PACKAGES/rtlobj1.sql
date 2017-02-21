prompt rtlobj
create or replace package rtlobj is
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/rtlobj1.sql $
 *  $Author: Alexey $
 *  $Revision: 15072 $
 *  $Date:: 2012-03-06 13:41:17 #$
 */
--
    function  get_class ( p_object_id IN number ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( get_class , WNDS );
    function  get_class ( p_object_id IN varchar2 ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( get_class , WNDS );
    procedure get_parent ( p_collect number, p_object out varchar2, p_class out varchar2 );
    pragma RESTRICT_REFERENCES ( get_parent, WNDS );
    function  coll2class ( p_collect_id IN number ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( coll2class, WNDS );
--
end rtlobj;
/
sho err

