prompt types body
create or replace package body
/*
 *	$HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/TYPES2.SQL $
 *  $Author: Alexey $
 *	$Revision: 15072 $
 *	$Date:: 2012-03-06 13:41:17 #$
 */
types is
------------------------------------------------------------------------------
function getquala(
     p_class_id in varchar2
    ,p_attr_id in varchar2
    ,p_qual    in varchar2 default ' ') return  varchar2 is
    v_class     lib.class_info_t;
begin
  if lib.attr_exist(p_attr_id,v_class,p_class_id) then
    return getqualt(v_class.class_id,p_qual);
  end if;
  return null;
end getquala;
------------------------------------------------------------------------------
function getqualp(
     P_METH_ID in varchar2
    ,P_PARPOS  in varchar2
    ,P_QUAL    in varchar2 default ' ') return  varchar2 is
    v_type varchar2(16);
begin
    select CLASS_ID
    into v_type
    from method_parameters
    where method_id=p_meth_id
    and position=p_parpos;
    return getqualt(v_type,p_qual);
exception
    when no_data_found then
        return null;
end getqualp;
------------------------------------------------------------------------------
procedure qualprop(
		p_class_id	in varchar2,
		p_qual		in varchar2,
		p_elem_class		out nocopy varchar2,
		p_elem_base_class	out nocopy varchar2,
		p_elem_target_class	out nocopy varchar2,
		p_elem_name			in out nocopy varchar2,
        p_separator in varchar2 default ' '
		) is
    v_err  varchar2(2000);
begin
    v_err := lib.qualprop(p_class_id,p_qual,p_elem_class,p_elem_base_class,
             p_elem_target_class,p_elem_name,p_separator);
    if not v_err is null then
      message.raise_(-20999,v_err,true);
    end if;
end qualprop;
--
procedure qual_prop(
		p_class_id	in varchar2,
		p_qual		in varchar2,
		p_elem_class		out varchar2,
		p_elem_base_class	out varchar2,
		p_elem_name			in out nocopy varchar2
		) is
    v_cls       varchar2(100);
begin
    qualprop(p_class_id,p_qual,p_elem_class,p_elem_base_class,v_cls,p_elem_name,'\');
end qual_prop;
--
procedure correct_qual(p_class_id varchar2,p_qual in out nocopy varchar2) is
begin
    lib.correct_qual(p_class_id,p_qual);
end correct_qual;
--
procedure get_qual_name(
		p_class_id	in varchar2,
		p_qual		in varchar2,
		p_qual_name	in out nocopy varchar2,
		p_separator	in varchar2
		) is
    v_name varchar2(4000);
begin
    v_name := lib.qual_name(p_class_id,p_qual,p_separator);
    if v_name is null then
      return;
    end if;
    p_qual_name := p_qual_name||p_separator||v_name;
end get_qual_name;
--
function qual_name(
		p_class_id	in varchar2,
		p_qual		in varchar2,
		p_separator	in varchar2 default ' '
		) return varchar2 is
begin
    return lib.qual_name(p_class_id,p_qual,p_separator);
end qual_name;
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
		) is
    v_class_id      varchar2(16);
    v_qual          varchar2(700);
begin
	v_qual := p_qual;
	if substr(v_qual,1,6) = '%THIS%' then
		v_class_id := p_class_id;
		v_qual := substr(v_qual,7);
	elsif substr(v_qual,1,8) = '%SYSTEM%' then
		v_class_id := 'SYSTEM';
		v_qual := substr(v_qual,9);
	elsif substr(v_qual,1,7) = '%PARAM%' then
		v_qual := substr(v_qual,8);
		declare
			p pls_integer;
            v_par_sn varchar2(30);
		begin
			p := instr(v_qual, '.', 2); if p = 0 then p := length(v_qual) + 1; end if;
			v_par_sn := substr(v_qual, 2, p - 2);
			select /*+ INDEX */ mp.class_id, mp.name
			into v_class_id, p_elem_name
			from method_parameters mp
			where mp.short_name = v_par_sn
			 and mp.method_id = p_method_id;
			v_qual := substr(v_qual, p + 1);
		end;
    elsif substr(v_qual,1,5) = '%VAR%' then
        v_qual := substr(v_qual,6);
		declare
			p pls_integer;
            v_par_sn varchar2(30);
		begin
			p := instr(v_qual, '.', 2); if p = 0 then p := length(v_qual) + 1; end if;
			v_par_sn := substr(v_qual, 2, p - 2);
            select /*+ INDEX */ mv.class_id, mv.name
			into v_class_id, p_elem_name
            from method_variables mv
            where mv.short_name = v_par_sn
              and mv.method_id = p_method_id;
			v_qual := substr(v_qual, p + 1);
        end;
	else
		v_class_id := p_class_id;
	end if;
	qualprop(v_class_id, v_qual, p_elem_class, p_elem_base_class, p_elem_name, p_elem_target_class, p_separator);
end qualprop_ext;
--
procedure qual_prop_ext(
		p_method_id	in varchar2,
		p_class_id	in varchar2,
		p_qual		in varchar2,
		p_elem_class		out varchar2,
		p_elem_base_class	out varchar2,
		p_elem_name			in out nocopy varchar2
		) is
    v_cls      varchar2(100);
begin
    qualprop_ext(p_method_id, p_class_id, p_qual, p_elem_class, p_elem_base_class, v_cls, p_elem_name, '\');
end qual_prop_ext;
--
--  Определяет класс элемента по квалификатору
--
function getqualc(	p_class_id in varchar2,
					p_qual in varchar2) return varchar2 is
    v_class varchar2(16);
    v_qual  varchar2(700);
    i pls_integer;
begin
    v_class := lib.qual_class(p_class_id,nvl(p_qual,' '));
    if v_class is null then
      message.err(-20999,'CLS','BAD_QUALIFIER', p_qual, p_class_id);
    elsif v_class = 'STRUCTURE' then
      return NULL;
	end if;
    return v_class;
end getqualc;
------------------------------------------------------------------------------
--
--  Определяет базовый класс элемента по квалификатору
--
------------------------------------------------------------------------------
function getqualt(	p_class_id in varchar2,
					p_qual in varchar2) return varchar2 is
    v_class varchar2(16);
begin
    v_class := lib.qual_base(p_class_id,nvl(p_qual,' '));
    if v_class is null then
      message.err(-20999,'CLS','BAD_QUALIFIER', p_qual, p_class_id);
    elsif v_class = 'STRUCTURE' then
      return NULL;
	end if;
    return v_class;
end getqualt;
--
--  Определяет базовый класс элемента по квалификатору
--
function obj_qual_class(
					 p_obj_id in varchar2,
					 p_qual	in varchar2
					) return  varchar2 is
    v_class_id varchar2(16);
begin
    v_class_id := rtlobj.get_class(p_obj_id);
	return getqualc(v_class_id,p_qual);
end obj_qual_class;
--
end types;
/
sho err package body types

