prompt rtlobj body
create or replace package body
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/rtlobj2.sql $
 *  $Author: Alexey $
 *  $Revision: 15072 $
 *  $Date:: 2012-03-06 13:41:17 #$
 */
rtlobj is
--
function get_class ( p_object_id IN number ) return varchar2 is
    v_class varchar2(16);
begin
    select class_id into v_class from objects where id = p_object_id and rownum = 1;
    return v_class;
end;
--
function get_class ( p_object_id IN varchar2 ) return varchar2 is
  v_class varchar2(16);
  v_obj   number;
begin
  select class_id into v_class from objectss where id = p_object_id and rownum = 1;
  return v_class;
exception when no_data_found then
  begin
    v_obj := p_object_id;
  exception when others then
    raise no_data_found;
  end;
  select class_id into v_class from objects where id = v_obj and rownum = 1;
  return v_class;
end;
--
procedure get_parent ( p_collect number, p_object out varchar2, p_class out varchar2 ) is
begin
    select object_id, class_id into p_object, p_class
      from col2obj where collection_id = p_collect and rownum = 1;
end;
--
function coll2class ( p_collect_id IN number ) return varchar2 is
    v_class_id varchar2(16);
begin
    select class_id into  v_class_id
      from collections where id = p_collect_id and rownum = 1;
	return v_class_id;
exception when NO_DATA_FOUND then
	return NULL;
end;
--
end rtlobj;
/
sho err package body rtlobj

