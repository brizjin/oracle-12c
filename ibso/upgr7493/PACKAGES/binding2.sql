prompt bindings body
create or replace
package body
/*
 *	$HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/binding2.sql $
 *	$Author: sanja $
 *	$Revision: 62451 $
 *	$Date:: 2014-12-15 15:53:12 #$
 */
bindings is
--
system_id varchar2(128) := valmgr.static('SYSTEM');
--
function get_system_id return varchar2 is
begin
	return system_id;
end get_system_id;
--
function split_qual(p_class_id in varchar2, p_qual in varchar2, p_self_qual out varchar2, p_ref_qual out varchar2) return varchar2 is
	v_class     lib.class_info_t;
    v_class_id  varchar2(16);
    v_qual      varchar2(700);
    v_elem_sn   varchar2(700);
	p1       	integer;
	p2       	integer;
begin
    p_self_qual:= p_qual;
	p_ref_qual := NULL;
    if rtrim(p_qual) is null then return null; end if;
    v_class_id := p_class_id;
    if not lib.class_exist(v_class_id,v_class) then
        message.err(-20999, 'KRNL','CLASS_NOT_FOUND',v_class_id,'SPLIT_QUAL');
    end if;
	v_qual := p_qual || '.'; p1 := 1;
	loop
		p2 := instr(v_qual, '.', p1);
		if p2 = 0 then
            p_self_qual:= p_qual;
            p_ref_qual := null;
            return null;
		end if;
		-- dbms_output.put_line(v_class.id || ',' || v_class.base_class_id || ',' || to_char(p1) || ',' || to_char(p2));
		if v_class.base_class_id = 'STRUCTURE' then
			v_elem_sn := substr(v_qual, p1, p2 - p1);
            if not lib.attr_exist(v_elem_sn,v_class,v_class_id) then
                message.err(-20999, 'CLS','BAD_QUALIFIER',v_elem_sn,v_class_id);
            end if;
            v_class_id := v_class.class_id;
			p1 := p2 + 1;
		else
			if v_class.base_class_id <> 'REFERENCE' and p1 <= length(p_qual) then
                message.err(-20999, 'CLS','BAD_QUALIFIER',substr(p_qual, p1),v_class_id);
			end if;
            p_self_qual:= substr(p_qual, 1, p1 - 2);
            p_ref_qual := substr(p_qual, p1);
			return v_class.class_ref;
		end if;
	end loop;
end split_qual;
--
procedure split_qual(p_class_id in varchar2, p_qual in varchar2, p_self_qual out varchar2, p_ref_qual out varchar2) is
    v_class_id  varchar2(16);
begin
    v_class_id := split_qual(p_class_id, p_qual, p_self_qual, p_ref_qual);
end split_qual;
--
-- p_class_id  нужен для классов, которые не живут в OBJECTS
function attr_value_ext(p_obj_id varchar2, p_qual varchar2, p_class_id varchar2 default null) return varchar2 is
begin
  return valmgr.get_value(p_obj_id,p_qual,p_class_id);
end attr_value_ext;
--
function par_var_value_ext(p_meth_id varchar2, p_qual varchar2, p_idx pls_integer default null) return varchar2 is
	v_result varchar2(32767);
	v_meth_id  methods.id%type;
begin
    v_meth_id := p_meth_id;
    execute immediate 'BEGIN :RESULT:='||method_mgr.get_param_qual(v_meth_id, true)
        ||'(:QUAL,:IDX); END;'
      using out v_result,p_qual,p_idx;
    return v_result;
end par_var_value_ext;
--
function get_value_ext(p_obj_id varchar2, p_xqual varchar2, p_meth_id varchar2 default null,p_class_id varchar2 default null) return varchar2 is
    v_qual     varchar2(700);
    v_obj_id   varchar2(128);
    v_class_id varchar2(16);
begin
	if substr(p_xqual, 1, 7) = '%THIS%.' then
        v_obj_id := p_obj_id;
        v_qual := substr(p_xqual, 8);
        v_class_id := p_class_id;
	elsif substr(p_xqual, 1, 9) = '%SYSTEM%.' then
		v_obj_id := get_system_id;
		v_qual := substr(p_xqual,10);
        v_class_id := 'SYSTEM';
	elsif substr(p_xqual, 1, 8) = '%PARAM%.' then
		return par_var_value_ext(p_meth_id,p_xqual);
	elsif substr(p_xqual, 1, 6) = '%VAR%.' then
		return par_var_value_ext(p_meth_id,p_xqual);
	elsif substr(p_xqual, 1, 6) = '%RTF%.' then
		return null;
	else
		v_obj_id := p_obj_id; v_qual := p_xqual; v_class_id := p_class_id;
	end if;
    return valmgr.get_value(v_obj_id, v_qual, v_class_id);
end get_value_ext;
--
procedure validate(p_meth_id varchar2, p_obj_id number) is
begin
	null;
end validate;
--
function qual2host(p_class_id  in varchar2,
                   p_qual      in varchar2) return varchar2 is
	qual_class_id varchar2(16);
    ref_class_id  varchar2(16);
	host_qual varchar2(1024);
    ref_qual  varchar2(1024);
	self_qual varchar2(1024);
begin
	if instr(p_qual,'->') > 0 then return p_qual; end if;
    ref_class_id := split_qual(p_class_id, p_qual, self_qual, ref_qual);
	host_qual := self_qual;
	qual_class_id := p_class_id;
	while ref_qual is not null loop
        qual_class_id:= ref_class_id;
        ref_class_id := split_qual(qual_class_id, ref_qual, self_qual, ref_qual);
		host_qual := host_qual || '->' || self_qual;
	end loop;
	return host_qual;
end;
--
end bindings;
/
sho err package body bindings

