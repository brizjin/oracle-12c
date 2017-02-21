prompt lib body
create or replace package body
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/lib2.sql $
 *  $Author: zikov $
 *  $Revision: 129618 $
 *  $Date:: 2016-12-01 17:56:50 #$
 */
lib is
--
ZERO    constant pls_integer := ascii('0');
PROC    constant pls_integer := ascii('%');
CTRL_C  constant varchar2(1) := chr(3);
NL      constant varchar2(1) := chr(10);
DLM constant varchar2(1) := '|'; -- properties delimiter
asc_dlm     pls_integer := ascii(DLM);
--
NCHARSET	varchar2(40);
--
class_types  class_info_tbl_s;
classtables  table_info_tbl_s;
attr_types   attr_info_tbl_t;
attr_dist    integer_tbl_s;
attr_idxs    integer_tbl_s;
class_attrs  string_tbl_s;
col_types    column_info_tbl_t;
col_idxs     index_tbl_s;
class_cols   string_tbl_s;
classparent  defstring_tbl_s;
class_parts  defstring_tbl_s;
--
init_flag   boolean := true;
type_with_rowid_exists boolean := false;
--
procedure init is
  generic_type   class_info_t;
begin
  generic_type.class_id       :=  constant.GENERIC_INTEGER;
  generic_type.name           :=  'Integer number';
  generic_type.parent_id      :=  constant.OBJECT;
  generic_type.entity_id      :=  'TYPE';
  generic_type.base_id        :=  constant.GENERIC_INTEGER;
  generic_type.base_class_id  :=  constant.GENERIC_NUMBER;
  generic_type.has_instances  :=  constant.NO;
  generic_type.is_array       :=  FALSE;
  generic_type.interface      :=  'PLS_INTEGER';
  generic_type.class_ref      :=  NULL;
  generic_type.data_size      :=  4;
  generic_type.data_precision :=  NULL;
  generic_type.kernel         :=  TRUE;
  generic_type.has_type       :=  FALSE;
  generic_type.temp_type      :=  NULL;
  generic_type.flags          :=  rpad('0',30,'0');
  class_types(generic_type.class_id) := generic_type;
--
  generic_type.class_id       :=  'BINARY_FLOAT';
  generic_type.name           :=  'Numeric type - Binary_Float';
  generic_type.base_id        :=  constant.GENERIC_NUMBER;
  generic_type.interface      :=  'BINARY_FLOAT';
  class_types(generic_type.class_id) := generic_type;
--
  generic_type.class_id       :=  'BINARY_DOUBLE';
  generic_type.name           :=  'Numeric type - Binary_Double';
  generic_type.interface      :=  'BINARY_DOUBLE';
  generic_type.data_size      :=  8;
  class_types(generic_type.class_id) := generic_type;
--
  generic_type.class_id       :=  constant.GENERIC_NULL;
  generic_type.name           :=  'Scalar class';
  generic_type.base_id        :=  constant.GENERIC_NULL;
  generic_type.base_class_id  :=  constant.GENERIC_STRING;
  generic_type.interface      :=  'VARCHAR2';
  generic_type.data_size      :=  constant.REF_PREC;
  class_types(generic_type.class_id) := generic_type;
--
  generic_type.class_id       :=  constant.GENERIC_EXCEPTION;
  generic_type.name           :=  'Exception class';
  generic_type.base_id        :=  constant.GENERIC_EXCEPTION;
  generic_type.base_class_id  :=  constant.GENERIC_BOOLEAN;
  generic_type.interface      :=  'EXCEPTION';
  generic_type.data_size      :=  NULL;
  class_types(generic_type.class_id) := generic_type;
--
  generic_type.class_id       :=  constant.COLLECTION;
  generic_type.name           :=  'Class - collection of OBJECT';
  generic_type.base_id        :=  constant.COLLECTION;
  generic_type.base_class_id  :=  constant.COLLECTION;
  generic_type.is_array       :=  TRUE;
  generic_type.interface      :=  'NUMBER';
  generic_type.class_ref      :=  constant.OBJECT;
  class_types(generic_type.class_id) := generic_type;
--
  generic_type.class_id       :=  constant.REFERENCE;
  generic_type.name           :=  'Class - reference to OBJECT';
  generic_type.base_id        :=  constant.REFERENCE;
  generic_type.base_class_id  :=  constant.REFERENCE;
  generic_type.is_array       :=  FALSE;
  generic_type.interface      :=  'VARCHAR2';
  generic_type.data_size      :=  constant.REF_PREC;
  class_types(generic_type.class_id) := generic_type;
--
  generic_type.class_id       :=  'ROWID';
  generic_type.name           :=  'ROWID type';
  generic_type.base_id        :=  constant.OLE;
  generic_type.base_class_id  :=  constant.OLE;
  generic_type.interface      :=  'ROWID';
  generic_type.class_ref      :=  NULL;
  generic_type.data_size      :=  NULL;
  generic_type.data_precision :=  -1000;
  class_types(generic_type.class_id) := generic_type;
--
  generic_type.class_id       :=  'RAW';
  generic_type.name           :=  'RAW type';
  generic_type.interface      :=  'RAW';
  generic_type.data_size      :=  2000;
  class_types(generic_type.class_id) := generic_type;
--
  generic_type.class_id       :=  'LONG';
  generic_type.name           :=  'LONG type';
  generic_type.interface      :=  'LONG';
  generic_type.data_size      :=  NULL;
  class_types(generic_type.class_id) := generic_type;
--
  generic_type.class_id       :=  'LONG RAW';
  generic_type.name           :=  'LONG RAW type';
  generic_type.interface      :=  'LONG RAW';
  class_types(generic_type.class_id) := generic_type;
--
  generic_type.class_id       :=  'BLOB';
  generic_type.name           :=  'BLOB type';
  generic_type.interface      :=  'BLOB';
  class_types(generic_type.class_id) := generic_type;
--
  generic_type.class_id       :=  'CLOB';
  generic_type.name           :=  'CLOB type';
  generic_type.interface      :=  'CLOB';
  class_types(generic_type.class_id) := generic_type;
--
  generic_type.class_id       :=  'BFILE';
  generic_type.name           :=  'BFILE type';
  generic_type.interface      :=  'BFILE';
  class_types(generic_type.class_id) := generic_type;
--
  generic_type.class_id       :=  constant.GENERIC_TIMESTAMP;
  generic_type.name           :=  'DateTime type - Timestamp';
  generic_type.base_id        :=  constant.GENERIC_TIMESTAMP;
  generic_type.base_class_id  :=  constant.GENERIC_DATE;
  generic_type.interface      :=  'TIMESTAMP(9)|TIMESTAMP_UNCONSTRAINED';
  generic_type.data_size      :=  9;
  generic_type.data_precision :=  NULL;
  class_types(generic_type.class_id) := generic_type;
--
  generic_type.class_id       :=  constant.GENERIC_INTERVAL;
  generic_type.name           :=  'DateTime type - Interval';
  generic_type.base_id        :=  constant.GENERIC_INTERVAL;
  generic_type.interface      :=  'INTERVAL DAY(9) TO SECOND(9)|DSINTERVAL_UNCONSTRAINED';
  generic_type.data_precision :=  9;
  class_types(generic_type.class_id) := generic_type;
--
  generic_type.class_id       :=  constant.GENERIC_TIMESTAMP||'_TZ';
  generic_type.name           :=  'DateTime type - Timestamp';
  generic_type.base_id        :=  constant.GENERIC_TIMESTAMP;
  generic_type.interface      :=  'TIMESTAMP(9) WITH TIME ZONE|TIMESTAMP_TZ_UNCONSTRAINED';
  generic_type.data_precision :=  1;
  class_types(generic_type.class_id) := generic_type;
--
  generic_type.class_id       :=  constant.GENERIC_TIMESTAMP||'_LTZ';
  generic_type.name           :=  'DateTime type - Timestamp';
  generic_type.base_id        :=  constant.GENERIC_TIMESTAMP;
  generic_type.interface      :=  'TIMESTAMP(9) WITH LOCAL TIME ZONE|TIMESTAMP_LTZ_UNCONSTRAINED';
  generic_type.data_precision :=  2;
  class_types(generic_type.class_id) := generic_type;
--
  generic_type.class_id       :=  constant.GENERIC_INTERVAL||'_YM';
  generic_type.name           :=  'DateTime type - Interval';
  generic_type.base_id        :=  constant.GENERIC_INTERVAL;
  generic_type.interface      :=  'INTERVAL YEAR(9) TO MONTH|YMINTERVAL_UNCONSTRAINED';
  generic_type.data_precision :=  NULL;
  class_types(generic_type.class_id) := generic_type;
--
  generic_type.class_id       :=  constant.BOOLSTRING;
  generic_type.name           :=  'Boolean string';
  generic_type.base_id        :=  constant.GENERIC_STRING;
  generic_type.base_class_id  :=  constant.GENERIC_STRING;
  generic_type.interface      :=  'VARCHAR2';
  generic_type.data_size      :=  constant.BOOL_PREC;
  class_types(generic_type.class_id) := generic_type;
--
  generic_type.class_id       :=  constant.REFSTRING;
  generic_type.name           :=  'Kernel reference';
  generic_type.data_size      :=  constant.REF_PREC;
  class_types(generic_type.class_id) := generic_type;
--
  generic_type.class_id       :=  constant.RUNTIME;
  generic_type.name           :=  'Run-Time Library procedures';
  generic_type.entity_id      :=  'KERNEL';
  generic_type.base_id        :=  constant.GENERIC_NULL;
  generic_type.base_class_id  :=  constant.STRUCTURE;
  generic_type.interface      :=  'NUMBER';
  generic_type.data_size      :=  NULL;
  class_types(generic_type.class_id) := generic_type;
--
  generic_type.class_id       :=  constant.OBJECT;
  generic_type.name           :=  'Class OBJECT - parent for all classes';
  generic_type.parent_id      :=  NULL;
  generic_type.base_id        :=  constant.STRUCTURE;
  generic_type.interface      :=  'RTL.OBJECT_REC';
  generic_type.data_size      :=  176;
  class_types(generic_type.class_id) := generic_type;
  classtables(generic_type.class_id).class_id := constant.OBJECT;
  classtables(generic_type.class_id).table_name := 'OBJECTS';
  classtables(generic_type.class_id).table_owner:= inst_info.owner;
  classtables(generic_type.class_id).distance := 0;
  class_attrs(generic_type.class_id) := ';1:1;2:2;*1;';
  attr_types(1).class_id:= constant.OBJECT;
  attr_types(1).attr_id := 'ID';
  attr_types(1).position:= 1;
  attr_types(1).self_class_id := constant.REFERENCE;
  attr_types(1).name := 'Object ID';
  attr_dist('OBJECT.ID') := 0;
  attr_idxs('OBJECT.ID') := 1;
  attr_types(2).class_id:= constant.OBJECT;
  attr_types(2).attr_id := 'CLASS_ID';
  attr_types(2).position:= 2;
  attr_types(2).self_class_id := 'METACLASS_REF';
  attr_types(2).name := 'Object Class';
  attr_dist('OBJECT.CLASS_ID') := 0;
  attr_idxs('OBJECT.CLASS_ID') := 2;
  class_cols(generic_type.class_id) := ';1;2;';
  col_types(1).class_id:= constant.OBJECT;
  col_types(1).tbl_name:= 'OBJECTS';
  col_types(1).col_name:= 'ID';
  col_types(1).qual := 'ID';
  col_types(1).self_class_id := constant.REFERENCE;
  col_types(1).base_id := constant.REFERENCE;
  col_types(1).target_id := constant.OBJECT;
  col_types(1).features:= '00000';
  col_types(1).flags := '0';
  col_types(1).position:= 1;
  col_idxs('OBJECT.ID') := 1;
  col_types(2).class_id:= constant.OBJECT;
  col_types(2).tbl_name:= 'OBJECTS';
  col_types(2).col_name:= 'CLASS_ID';
  col_types(2).qual := 'CLASS_ID';
  col_types(2).self_class_id := 'METACLASS_REF';
  col_types(2).base_id := constant.REFERENCE;
  col_types(2).target_id := constant.METACLASS;
  col_types(2).features:= '00000';
  col_types(2).flags := '0';
  col_types(2).position:= 2;
  col_idxs('OBJECT.CLASS_ID') := 2;
--
  init_flag := false;
end;
--
procedure reset_class(p_class varchar2) is
  idx varchar2(4004);
  str varchar2(512);
  i   pls_integer;
begin
  if p_class is null then
    classparent.delete;
    class_types.delete;
    classtables.delete;
    class_attrs.delete;
    class_parts.delete;
    attr_types.delete;
    attr_dist.delete;
    attr_idxs.delete;
    col_types.delete;
    col_idxs.delete;
    Init;
    return;
  end if;
  idx := p_class;
  if class_types.exists(idx) and class_types(idx).kernel then
    init_flag := true;
  end if;
  classparent.delete(idx);
  class_types.delete(idx);
  classtables.delete(idx);
  class_attrs.delete(idx);
  str := attr_dist.next(idx||'.');
  if str is not null then
    idx := idx||'._%';
    while str like idx loop
      attr_dist.delete(str);
      if attr_idxs.exists(str) then
        i := attr_idxs(str);
        if attr_types.exists(i) and attr_types(i).class_id = p_class then
          attr_types.delete(i);
        end if;
        attr_idxs.delete(str);
      end if;
      str := attr_dist.next(str);
    end loop;
  end if;
  if class_cols.exists(p_class) then
    class_cols.delete(p_class);
    str := col_idxs.next(p_class||':');
    if str is not null then
      idx := p_class||':_%';
      while str like idx loop
        i := col_idxs(str);
        if col_types.exists(i) and col_types(i).class_id = p_class then
          col_types.delete(i);
        end if;
        col_idxs.delete(str);
        str := col_idxs.next(str);
      end loop;
    end if;
  end if;
  if class_parts.exists(p_class) then
    class_parts.delete(p_class);
    str := class_parts.next(p_class||'.');
    if str is null then
      return;
    end if;
    idx := p_class||'._%';
    while str like idx loop
      class_parts.delete(str);
      str := class_parts.next(str);
    end loop;
  end if;
end;
--
-- @METAGS class_exist
function class_exist ( p_class_id   IN varchar2,
		               p_class_info IN OUT nocopy class_info_t
		             ) return boolean is
    v_class_id  varchar2(16);
    kernel varchar2(1);
    hastyp varchar2(1);
    properties varchar2(2048);
begin
    if p_class_id is null or length(p_class_id)>16 then
        p_class_info := null;
        return FALSE;
    end if;
    if init_flag then init; end if;
    v_class_id := upper(p_class_id);
    if class_types.exists(v_class_id) then
        p_class_info := class_types(v_class_id);
        return not p_class_info.base_id is null;
    end if;
	select name,
	       parent_id,
           entity_id,
		   base_class_id,
	       has_instances,
		   interface,
		   data_size,
		   data_precision,
	       target_class_id,
           short_name,
           key_attr,
           init_method_id,
           init_state_id,
		   kernel,
		   has_type,
		   temp_type,
		   properties
	into p_class_info.name,
	     p_class_info.parent_id,
	     p_class_info.entity_id,
	     p_class_info.base_id,
	     p_class_info.has_instances,
		 p_class_info.interface,
		 p_class_info.data_size,
		 p_class_info.data_precision,
	     p_class_info.class_ref,
	     p_class_info.flags,
	     p_class_info.key_attr,
	     p_class_info.method_id,
	     p_class_info.state_id,
		 kernel,
		 hastyp,
		 p_class_info.temp_type,
		 properties
	from classes
    where id = v_class_id;
    p_class_info.base_class_id := p_class_info.base_id;
    p_class_info.class_id := v_class_id;
	p_class_info.is_array := p_class_info.base_id in (constant.COLLECTION,constant.GENERIC_TABLE);
	p_class_info.kernel := nvl(kernel = constant.YES, FALSE);
	p_class_info.has_type := nvl(hastyp = constant.YES, FALSE);
	p_class_info.has_row_id := nvl(has_rowid(properties) = '1', false);
    if p_class_info.parent_id is NULL then
        p_class_info.parent_id:=constant.OBJECT;
    end if;
    p_class_info.flags := rpad(nvl(p_class_info.flags,'0'),30,'0');
    class_types(v_class_id) := p_class_info;
    if p_class_info.has_row_id then
        type_with_rowid_exists := true;
    end if;
    return TRUE;
exception when NO_DATA_FOUND then
    p_class_info := null;
    class_types(v_class_id) := p_class_info;
    return FALSE;
end class_exist;
--
function has_rowid(properties varchar2, p_class_id varchar2:=null) return varchar2 is
begin
    if extract_property(properties, 'ROWID')='1' then
        return '1';
    elsif p_class_id is not null then
        for c in (select 1 from classes cl where cl.id = p_class_id and rownum<2 and extract_property(cl.properties, 'ROWID')='1') loop
            return '1';
        end loop;
    end if;
    return null;
end;
--
function table_exist ( p_class_id   IN varchar2,
		               p_table_info IN OUT nocopy table_info_t,
                       p_log_table  boolean default false
		             ) return boolean is
    v_cls  varchar2(16);
begin
    if p_class_id is null then
        p_table_info := null;
        return FALSE;
    end if;
    if init_flag then init; end if;
  if classtables.exists(p_class_id) then
    p_table_info := classtables(p_class_id);
    if p_table_info.table_name is null then
      return false;
    end if;
  else
    select --+ INDEX(cr unq_cls_rel_chld_dist)
      ct.class_id,
      ct.table_name,
      ct.param_group,
      ct.flags,
      ct.log_table,
      ct.owner,
      ct.log_owner,
      ct.cached,
      cr.distance
    into
      p_table_info.class_id,
      p_table_info.table_name,
      p_table_info.param_group,
      p_table_info.flags,
      p_table_info.log_table,
      p_table_info.table_owner,
      p_table_info.log_owner,
      p_table_info.cached,
      p_table_info.distance
    from class_tables ct, class_relations cr
    where ct.class_id = cr.parent_id
      and cr.child_id = p_class_id
      and rownum = 1;
    if p_table_info.table_owner is null then
      p_table_info.table_owner := inst_info.gowner;
    end if;
    if p_table_info.log_table is not null and p_table_info.log_owner is null then
      p_table_info.log_owner := inst_info.gowner;
    end if;
    classtables(p_class_id) := p_table_info;
  end if;
  if p_log_table and p_table_info.log_table is null then
    v_cls := class_parent(p_table_info.class_id);
    if v_cls<>constant.OBJECT then
      return table_exist(v_cls,p_table_info,true);
    end if;
  end if;
  return true;
exception when NO_DATA_FOUND then
    p_table_info := null;
    classtables(p_class_id) := p_table_info;
    return FALSE;
end;
--
-- @METAGS class_table
procedure class_table ( p_class_id IN  varchar2,
                        p_table    OUT nocopy varchar2,
                        p_group    OUT nocopy varchar2,
                        p_self     varchar2 default null) is
    v_info table_info_t;
begin
    if p_class_id is null then
        return;
    end if;
    if table_exist(p_class_id,v_info) then
      if v_info.distance<>0 and p_self='1' then
        return;
      end if;
      p_table := v_info.table_name;
      p_group := v_info.param_group;
    end if;
end class_table;
--
function class_table ( p_class_id IN varchar2, p_self varchar2 default null ) return varchar2 is
    v_table varchar2(30);
    v_group varchar2(30);
begin
    class_table(p_class_id, v_table, v_group, p_self );
    return v_table;
end;
--
-- @METAGS is_kernel
function is_kernel ( p_id    varchar2,
                     p_class boolean default TRUE
                   ) return boolean is
    v_info class_info_t;
begin
    if p_class then
      if class_exist(p_id,v_info) then
        return v_info.kernel;
      end if;
      return FALSE;
    end if;
    select kernel into v_info.flags from methods where id = p_id;
    return nvl(v_info.flags = constant.YES, FALSE);
exception when NO_DATA_FOUND then
    return FALSE;
end;
--
function has_instances (p_id    varchar2,
                     p_class boolean default TRUE
                   ) return boolean is
    v_info class_info_t;
begin
    if p_class then
      if class_exist(p_id,v_info) then
        return nvl(v_info.has_instances = constant.YES, FALSE);
      end if;
      return FALSE;
    else
      select m.has_instances into v_info.has_instances from classes m where m.id = p_id;
    end if;
    return nvl(v_info.has_instances = constant.YES, FALSE);
exception when NO_DATA_FOUND then
    return FALSE;
end;
--
function has_stringkey ( p_class varchar2) return boolean is
    v_info class_info_t;
begin
    if class_exist(p_class,v_info) then
      return v_info.kernel or pk_is_rowid(v_info.class_id) or not v_info.key_attr is null;
    end if;
    return FALSE;
end;
--
function process_types_with_rowid return boolean is
begin
    return type_with_rowid_exists;
end;
--
function pk_is_rowid (p_class varchar2) return boolean is
    v_info class_info_t;
begin
    if class_exist(p_class, v_info) then
        return nvl(v_info.has_row_id, false);
    end if;
    return false;
end;
--
function check_class_flags(p_flag varchar2,p_self boolean) return boolean is
begin
  if p_self then
    return p_flag='1';
  elsif not p_self then
    return p_flag in ('1','2');
  end if;
  return p_flag in ('1','3');
end;
--
function has_childs ( p_class varchar2) return boolean is
    v_info class_info_t;
begin
    if class_exist(p_class,v_info) then
      return substr(v_info.flags,13,1)='1';
    end if;
    return FALSE;
end;
--
function has_state_id ( p_class varchar2, p_self boolean default true) return boolean is
    v_info class_info_t;
begin
    if class_exist(p_class,v_info) then
      return check_class_flags(substr(v_info.flags,3,1),p_self);
    end if;
    return FALSE;
end;
--
function has_collection_id ( p_class varchar2, p_self boolean default true) return boolean is
    v_info class_info_t;
begin
    if class_exist(p_class,v_info) then
      return check_class_flags(substr(v_info.flags,24,1),p_self);
    end if;
    return FALSE;
end;
--
function has_partitions ( p_class varchar2) return varchar2 is
    v_info table_info_t;
begin
    if table_exist(p_class,v_info) then
      if v_info.param_group='PARTITION' then
        return '1';
      elsif v_info.param_group='PARTVIEW' then
        return '2';
      end if;
    end if;
    return '0';
end;
--
procedure fill_class_attrs(cls varchar2,p_attr in out nocopy attr_info_t) is
  n pls_integer;
begin
  class_attrs(cls) := ';';
  p_attr.distance := 0;
  p_attr.class_id := cls;
  n := attr_types.last;
  for c in (
    select attr_id, self_class_id, name, required, position
      from class_attributes where class_id = cls
     order by position, attr_id
  ) loop
    p_attr.attr_id := c.attr_id;
    p_attr.self_class_id := c.self_class_id;
    p_attr.name := c.name;
    p_attr.flags:= c.required;
    p_attr.position := c.position;
    p_attr.method_id := null;
    if p_attr.flags = constant.METHOD_ATTRIBUTE then
      begin
        select id into p_attr.method_id from methods
         where class_id=cls and short_name=c.attr_id and flags=constant.METHOD_ATTRIBUTE;
      exception when no_data_found then null;
      end;
    end if;
    n := n+1;
    attr_types(n) := p_attr;
    attr_idxs(cls||'.'||c.attr_id) := n;
    attr_dist(cls||'.'||c.attr_id) := 0;
    class_attrs(cls) := class_attrs(cls)||c.position||':'||n||';';
  end loop;
end;
--
procedure get_class_attrs(p_attrs in out nocopy attr_info_tbl_t, p_class varchar2, p_self boolean) is
  v_type  class_info_t;
  v_attr  attr_info_t;
  v_cls varchar2(16);
  n pls_integer;
  i pls_integer;
  j pls_integer;
  d pls_integer;
begin
  n := nvl(p_attrs.last,0);
  if not class_exist(p_class,v_type) then
    return;
  end if;
  v_cls := v_type.class_id;
  if v_type.base_id <> constant.STRUCTURE then
    if find_attr(null,v_cls,v_attr,v_type) then
      p_attrs(n+1) := v_attr;
    end if;
    return;
  end if;
  d := 0;
  loop
    if not class_attrs.exists(v_cls) then
      fill_class_attrs(v_cls,v_attr);
    end if;
    i := 1;
    loop
      j := instr(class_attrs(v_cls),':',i);
      exit when j = 0;
      i := j+1;
      j := instr(class_attrs(v_cls),';',i);
      exit when j = 0;
      i := substr(class_attrs(v_cls),i,j-i);
      v_attr := attr_types(i);
      i := j;
      n := n+1;
      v_attr.distance := d;
      p_attrs(n) := v_attr;
    end loop;
    exit when p_self;
    v_cls := v_type.parent_id;
    exit when v_cls is null or v_cls = constant.OBJECT;
    exit when not class_exist(v_cls,v_type);
    d := d+1;
  end loop;
end;
--
function  find_attr ( p_attr_id  IN varchar2,
                      p_class_id IN varchar2,
     		          p_attr     IN OUT nocopy attr_info_t,
     		          p_dbtype   IN OUT nocopy class_info_t
                    ) return boolean is
    idx varchar2(40);
    cls varchar2(16);
    n pls_integer;
begin
    if not class_exist(p_class_id,p_dbtype) then
      p_attr := null;
      return FALSE;
    end if;
-- patch for scalar classes
    if ltrim(p_attr_id) is NULL then
      p_attr.class_id := p_dbtype.class_id;
      p_attr.method_id:= null;
      p_attr.self_class_id := p_dbtype.class_id;
      p_attr.name := p_dbtype.name;
      p_attr.position := 1;
      p_attr.distance := 0;
      p_attr.flags:= '0';
      if p_dbtype.base_id = constant.STRUCTURE then
        return FALSE;
      end if;
      p_attr.attr_id  := ' ';
      return TRUE;
	end if;
    cls := p_dbtype.class_id;
    idx := cls||'.'||p_attr_id;
    if attr_dist.exists(idx) then
      if attr_dist(idx) is null then
        p_attr := null;
        p_dbtype := null;
        return false;
      end if;
      n := attr_idxs(idx);
    end if;
    if n > 0 and attr_types.exists(n) then
      p_attr := attr_types(n);
      p_attr.distance := attr_dist(idx);
    elsif ascii(p_attr_id)=PROC then
      p_attr.attr_id := lower(p_attr_id);
      if p_attr.attr_id='%id' then
        p_attr.position := -1;
        p_attr.name := 'ID';
        if p_dbtype.kernel or pk_is_rowid(p_dbtype.class_id) or not p_dbtype.key_attr is null then
          p_attr.self_class_id := constant.REFSTRING;
        else
          p_attr.self_class_id := constant.GENERIC_NUMBER;
        end if;
        p_attr.distance := 0;
      elsif p_attr.attr_id='%class' then
        p_attr.position := -2;
        p_attr.name := 'CLASS_ID';
        p_attr.self_class_id := constant.REFSTRING;
        p_attr.distance := 0;
      elsif p_attr.attr_id='%collection' then
        p_attr.position := -3;
        p_attr.name := '%collection';
        if field_exist(p_attr.name,cls,false) then
          p_attr.distance := 0;
        else
          p_attr.distance := 1;
        end if;
        p_attr.name := 'COLLECTION_ID';
        p_attr.self_class_id := constant.COLLECTION;
      elsif p_attr.attr_id='%state' then
        p_attr.position := -4;
        p_attr.name := '%state';
        if field_exist(p_attr.name,cls,false) then
          p_attr.distance := 0;
        else
          p_attr.distance := 1;
        end if;
        p_attr.name := 'STATE_ID';
        p_attr.self_class_id := constant.REFSTRING;
      else
        raise no_data_found;
      end if;
      p_attr.flags:= '0';
      p_attr.class_id := cls;
      p_attr.method_id:= null;
      n := attr_types.last+1;
      attr_types(n) := p_attr;
      attr_idxs(idx):= n;
      attr_dist(idx):= p_attr.distance;
    elsif p_dbtype.base_id <> constant.STRUCTURE then
      p_attr := null;
      attr_dist(idx) := null;
      return FALSE;
    else
      if class_attrs.exists(cls) then
        cls := p_dbtype.parent_id;
        if cls is null then
          raise no_data_found;
        end if;
      else
        fill_class_attrs(cls,p_attr);
        if attr_idxs.exists(idx) then
          p_attr := attr_types(attr_idxs(idx));
          cls := null;
        else
          cls := p_dbtype.parent_id;
          if cls is null then
            raise no_data_found;
          end if;
        end if;
      end if;
      if cls is not null then
        if cls = constant.OBJECT then
          raise no_data_found;
        end if;
        if find_attr(p_attr_id,cls,p_attr,p_dbtype) then
          p_attr.distance := p_attr.distance+1;
          n := attr_idxs(cls||'.'||p_attr_id);
          attr_idxs(idx):= n;
          attr_dist(idx):= p_attr.distance;
          return true;
        else
          return false;
        end if;
      end if;
    end if;
    if class_exist(p_attr.self_class_id,p_dbtype) then
      return true;
    end if;
    p_attr := null;
    attr_dist(idx) := null;
    return false;
exception when NO_DATA_FOUND or VALUE_ERROR then
    p_attr := null;
    p_dbtype := null;
    if not idx is null then
      attr_dist(idx) := null;
    end if;
    return false;
end;
--
function find_attr_by_pos (p_attr_pos pls_integer,
                      p_class_id IN varchar2,
                      p_attr     IN OUT nocopy attr_info_t,
                      p_dbtype   IN OUT nocopy class_info_t
                    ) return boolean is
    pos pls_integer;
    str varchar2(40);
    cls varchar2(16);
begin
    if not class_exist(p_class_id,p_dbtype) then
      p_attr := null;
      return FALSE;
    end if;
-- patch for scalar classes
    if p_dbtype.base_id<>constant.STRUCTURE then
      if p_attr_pos<>1 then
        p_dbtype := null;
        return FALSE;
      end if;
      p_attr.class_id := p_dbtype.class_id;
      p_attr.method_id:= null;
      p_attr.self_class_id := p_dbtype.class_id;
      p_attr.name := p_dbtype.name;
      p_attr.position := 1;
      p_attr.distance := 0;
      p_attr.attr_id  := ' ';
      p_attr.flags := '0';
      return TRUE;
	end if;
    cls := p_dbtype.class_id;
    if p_attr_pos<0 then
      if p_attr_pos=-1 then
        p_attr.attr_id := '%id';
        p_attr.name := 'ID';
        if p_dbtype.kernel or pk_is_rowid(p_dbtype.class_id) or not p_dbtype.key_attr is null then
          p_attr.self_class_id := constant.REFSTRING;
        else
          p_attr.self_class_id := constant.GENERIC_NUMBER;
        end if;
        p_attr.distance := 0;
      elsif p_attr_pos=-2 then
        p_attr.attr_id := '%class';
        p_attr.name := 'CLASS_ID';
        p_attr.self_class_id := constant.REFSTRING;
        p_attr.distance := 0;
      elsif p_attr_pos=-3 then
        p_attr.attr_id := '%collection';
        p_attr.name := '%collection';
        if field_exist(p_attr.name,cls,false) then
          p_attr.distance := 0;
        else
          p_attr.distance := 1;
        end if;
        p_attr.name := 'COLLECTION_ID';
        p_attr.self_class_id := constant.COLLECTION;
      elsif p_attr_pos=-4 then
        p_attr.attr_id := '%state';
        p_attr.name := '%state';
        if field_exist(p_attr.name,cls,false) then
          p_attr.distance := 0;
        else
          p_attr.distance := 1;
        end if;
        p_attr.name := 'STATE_ID';
        p_attr.self_class_id := constant.REFSTRING;
      else
        raise no_data_found;
      end if;
      p_attr.flags:= '0';
      p_attr.class_id := cls;
      p_attr.position := p_attr_pos;
      p_attr.method_id:= null;
      str := cls||'.'||p_attr.attr_id;
      if not attr_dist.exists(str) then
        pos := attr_types.last+1;
        attr_types(pos) := p_attr;
        attr_idxs(str):= pos;
        attr_dist(str):= p_attr.distance;
      end if;
    else
      if not class_attrs.exists(cls) then
        fill_class_attrs(cls,p_attr);
      end if;
      str := ';'||p_attr_pos||':';
      pos := instr(class_attrs(cls),str);
      if pos>0 then
        pos := pos+length(str);
        pos := substr(class_attrs(cls),pos,instr(class_attrs(cls),';',pos)-pos);
        if attr_types.exists(pos) then
          p_attr := attr_types(pos);
          str := cls||'.'||p_attr.attr_id;
        else
          p_attr := null;
          p_dbtype := null;
          return false;
        end if;
      else
        str := p_dbtype.parent_id;
        if str is null or str = constant.OBJECT then
          raise no_data_found;
        end if;
        if find_attr_by_pos(p_attr_pos,str,p_attr,p_dbtype) then
          p_attr.distance := p_attr.distance+1;
          pos := attr_idxs(str||'.'||p_attr.attr_id);
          str := cls||'.'||p_attr.attr_id;
          attr_idxs(str):= pos;
          attr_dist(str):= p_attr.distance;
          return true;
        else
          return false;
        end if;
      end if;
    end if;
    if class_exist(p_attr.self_class_id,p_dbtype) then
      return true;
    end if;
    p_attr := null;
    attr_dist(str) := null;
    return false;
exception when NO_DATA_FOUND or VALUE_ERROR then
    p_attr := null;
    p_dbtype := null;
    return FALSE;
end;
--
function get_weight(p_base varchar2, p_pos pls_integer) return pls_integer is
begin
  if p_base in (constant.GENERIC_STRING,constant.GENERIC_NUMBER) then
    return p_pos;
  elsif p_base = constant.MEMO then
    return p_pos + 1000000;
  elsif p_base = constant.REFERENCE then
    return p_pos + 2000000;
  elsif p_base = constant.COLLECTION then
    return p_pos + 3000000;
  elsif p_base = constant.GENERIC_DATE then
    return p_pos + 4000000;
  elsif p_base = constant.STRUCTURE then
    return p_pos + 5000000;
  end if;
  return 10000000;
end;
--
function find_def_attr (
                      p_class_id varchar2,
                      p_attr     in out nocopy attr_info_t,
                      p_dbtype   in out nocopy class_info_t,
                      p_parents  boolean
                    ) return pls_integer is
    str varchar2(40);
    cls varchar2(16);
    d pls_integer;
    i pls_integer;
    j pls_integer;
    n pls_integer;
    w pls_integer;
    p pls_integer;
begin
    if not class_exist(p_class_id,p_dbtype) then
      p_attr := null;
      return 0;
    end if;
    if p_dbtype.base_id <> constant.STRUCTURE then
      if p_parents is null then
        p_attr.class_id := p_dbtype.class_id;
        p_attr.attr_id  := ' ';
        p_attr.method_id:= null;
        p_attr.self_class_id := p_dbtype.class_id;
        p_attr.name := p_dbtype.name;
        p_attr.position := 1;
        p_attr.distance := 0;
        p_attr.flags:= '0';
        return 1;
      end if;
      p_attr := null;
      return 0;
	end if;
    cls := p_dbtype.class_id;
    if not class_attrs.exists(cls) then
      fill_class_attrs(cls,p_attr);
    end if;
    p := instr(class_attrs(cls),';*');
    if p > 0 then
      p := p+2;
      p := substr(class_attrs(cls),p,instr(class_attrs(cls),';',p)-p);
      if attr_types.exists(p) then
        p_attr := attr_types(p);
        str := cls||'.'||p_attr.attr_id;
        if class_exist(p_attr.self_class_id,p_dbtype) then
          if attr_dist.exists(str) and attr_dist(str) is not null then
            p_attr.distance := attr_dist(str);
          end if;
          return p;
        else
          attr_dist(str) := null;
        end if;
      else
        p_dbtype := null;
      end if;
      p_attr := null;
      return 0;
    end if;
    n := 0; d := 0; w := 10000000;
    if nvl(p_parents,true) and p_dbtype.parent_id <> constant.OBJECT then
      str := p_dbtype.parent_id;
      i := find_def_attr(str,p_attr,p_dbtype,p_parents);
      if i > 0 then
        j := get_weight(p_dbtype.base_class_id,p_attr.position);
        if j < w then
          w := j;
          n := i;
          d := p_attr.distance+1;
        end if;
      end if;
    end if;
    p := 2;
    loop
      j := instr(class_attrs(cls),':',p);
      exit when j = 0;
      p := j+1;
      j := instr(class_attrs(cls),';',p);
      exit when j = 0;
      i := substr(class_attrs(cls),p,j-p);
      p := j+1;
      p_attr := attr_types(i);
      if class_exist(p_attr.self_class_id,p_dbtype) then
        j := get_weight(p_dbtype.base_class_id,p_attr.position);
        if j < w then
          w := j;
          n := i;
          d := 0;
        end if;
      else
        attr_dist(cls||'.'||p_attr.attr_id) := null;
      end if;
    end loop;
    if n > 0 then
      p_attr := attr_types(n);
      p_attr.distance := d;
      str := cls||'.'||p_attr.attr_id;
      if not class_exist(p_attr.self_class_id,p_dbtype) then
        n := 0;
      end if;
    end if;
    if n = 0 then
      p_attr := null;
      return 0;
    end if;
    attr_dist(str) := d;
    attr_idxs(str) := n;
    class_attrs(cls) := class_attrs(cls)||'*'||n||';';
    return n;
end;
--
function get_def_qual(p_class_id varchar2,
                      p_dbtype   in out nocopy class_info_t,
                      p_parents  boolean
                     ) return varchar2 is
  v_attr attr_info_t;
  v_qual varchar2(1000);
  n pls_integer;
begin
  if find_def_attr(p_class_id,v_attr,p_dbtype,p_parents) > 0 then
    if p_dbtype.base_id = constant.STRUCTURE then
      v_qual := get_def_qual(v_attr.self_class_id,p_dbtype,p_parents);
      if v_qual is not null then
        return v_attr.attr_id||'.'||v_qual;
      end if;
    else
      return v_attr.attr_id;
    end if;
  end if;
  return null;
end;
--
-- @METAGS attr_exist
function attr_exist ( p_attr_id  IN varchar2,
     		          p_dbtype   IN OUT nocopy class_info_t,
                      p_class_id IN varchar2
                    ) return boolean is
    v_attr attr_info_t;
begin
    if length(p_attr_id)>16 or length(p_class_id)>16 then
      p_dbtype := null;
      return FALSE;
    end if;
    return find_attr(upper(p_attr_id),upper(p_class_id),v_attr,p_dbtype);
end attr_exist;
--
/*	type column_info_t is record (
        class_id       varchar2(16),
        tbl_name       varchar2(30),
        col_name       varchar2(30),
        self_class_id  varchar2(16),
        base_id        varchar2(16),
        target_id      varchar2(16),
        mapped_id      varchar2(16),
        features       varchar2(30), <static-1><trigger-2><logging-3,4><partitioned-5><notcached-6>
        flags          varchar2(30), 0 / P<Primary Attr Id> / A<Attr Method Id>
        position       pls_integer
	);*/
procedure fill_class_cols(cls varchar2,p_tbl table_info_t, p_col in out nocopy column_info_t) is
  n pls_integer;
  b boolean;
  p varchar2(1);
begin
  class_cols(cls):= ';';
  p_col.class_id := cls;
  n := col_types.last;
  if p_tbl.distance = 0 then
    p_col.tbl_name := p_tbl.table_name;
    if p_tbl.cached > 1 then
      b := true;
    elsif p_tbl.cached < -1 then
      b := false;
    end if;
    if p_tbl.param_group='PARTITION' then
      p := '1';
    elsif p_tbl.param_group='PARTVIEW' then
      p := '2';
    else
      p := '0';
    end if;
    for c in (
      select nvl(qual_pos,position) pos, qual, column_name,
             self_class_id, base_class_id, target_class_id, mapped_from, not_cached,
             nvl(static,'0')||nvl(def,'0')||lpad(nvl(logging,'0'),2,'0') props, flags
        from class_tab_columns where class_id = cls and deleted = '0'
       order by 1
    ) loop
      p_col.qual := c.qual;
      p_col.col_name := c.column_name;
      p_col.self_class_id := c.self_class_id;
      p_col.base_id := c.base_class_id;
      p_col.target_id := c.target_class_id;
      p_col.mapped_id := c.mapped_from;
      if b is null then
        p_col.features := '1';
      elsif c.not_cached is null then
        if b then
          p_col.features := '0';
        else
          p_col.features := '1';
        end if;
      else
        p_col.features := c.not_cached;
      end if;
      p_col.features := c.props||p||p_col.features;
      if c.flags is null then
        p_col.flags := '0';
      else
        p_col.flags := replace(c.flags,'.');
      end if;
      p_col.position := c.pos;
      n := n+1;
      col_types(n) := p_col;
      col_idxs(cls||':'||c.qual) := n;
      class_cols(cls) := class_cols(cls)||n||';';
    end loop;
  else
    p_col.tbl_name := null;
    p_col.mapped_id:= null;
    p_col.features := '000000';
    for c in (
      select position, qual, field, self_class_id, base_class_id, target_class_id, flags
        from class_rec_fields where class_id = cls
       order by 1
    ) loop
      p_col.qual := c.qual;
      p_col.col_name := c.field;
      p_col.self_class_id := c.self_class_id;
      p_col.base_id := c.base_class_id;
      p_col.target_id := c.target_class_id;
      if c.flags is null then
        p_col.flags := '0';
      else
        p_col.flags := replace(c.flags,'.');
      end if;
      p_col.position := c.position;
      n := n+1;
      col_types(n) := p_col;
      col_idxs(cls||':'||c.qual) := n;
      class_cols(cls) := class_cols(cls)||n||';';
    end loop;
  end if;
end;
--
function find_column ( p_class_id varchar2,
                       p_qual     varchar2,
                       p_mapped   pls_integer,
                       p_tbl      in out nocopy table_info_t,
                       p_col      in out nocopy column_info_t
                      ) return boolean is
  cls varchar2(16) := p_class_id;
  idx varchar2(500);
  m pls_integer; -- 1 - mapped columns, 2 - system columns , 4 - self columns, 8 - get fields
  b boolean;
begin
  if cls is null then
    return false;
  end if;
  idx := cls||':'||nvl(p_qual,' ');
  if col_idxs.exists(idx) then
    m := col_idxs(idx);
  end if;
  if m > 0 and col_types.exists(m) then
    p_col := col_types(m);
    m := nvl(p_mapped,0);
    if p_col.tbl_name is null and bitand(m,8) = 0 then
      return false; -- not column
    elsif bitand(m,4) <> 0 and p_col.class_id <> cls then
      return false; -- not self
    end if;
    b := false;
  else
    m := nvl(p_mapped,0);
    b := table_exist(cls,p_tbl);
    if bitand(m,8) <> 0 or b and p_tbl.distance = 0 then
      if not class_cols.exists(cls) then
        fill_class_cols(cls,p_tbl,p_col);
      end if;
      if col_idxs.exists(idx) then
        p_col := col_types(col_idxs(idx));
        b := false;
      else
        b := true;
      end if;
    else
      b := true;
    end if;
  end if;
  loop
    if b then
      exit when bitand(m,4) <> 0;
      cls := class_parent(cls);
      exit when cls is null or cls = constant.OBJECT;
      exit when not find_column(cls,p_qual,bitand(m,8),p_tbl,p_col);
      if not col_idxs.exists(idx) then
        col_idxs(idx) := col_idxs(cls||':'||nvl(p_qual,' '));
      end if;
    end if;
    if p_col.mapped_id is null then
      if bitand(m,2) = 0 then -- not system column
        return true;
      end if;
    elsif p_col.mapped_id = constant.OBJECT then
      return true; -- system column
    elsif bitand(m,3) = 0 then  -- not mapped and not system column
      return true;
    end if;
    b := true;
  end loop;
  return false;
end;
--
-- @METAGS qual_column
function qual_column ( p_class_id IN  varchar2,
                       p_qual     IN  varchar2,
                       p_table    OUT nocopy varchar2,
                       p_column   OUT nocopy varchar2,
                       p_features OUT nocopy varchar2,
                       p_mapped   IN  varchar2 default null
                      ) return boolean is
  v_tbl table_info_t;
  v_col column_info_t;
begin
  if find_column(p_class_id,p_qual,to_number(p_mapped,'FMXX'),v_tbl,v_col) then
    p_table := v_col.tbl_name;
    p_column:= v_col.col_name;
    p_features := v_col.base_id||'.'||v_col.target_id||'.'||v_col.features||v_col.flags||'.'||v_col.self_class_id||'.'||v_col.class_id;
    return true;
  end if;
  return false;
end qual_column;
--
procedure qual_column( p_class_id IN  varchar2,
                       p_qual     IN  varchar2,
                       p_table    OUT nocopy varchar2,
                       p_column   OUT nocopy varchar2,
                       p_features OUT nocopy varchar2,
                       p_mapped   IN  varchar2 default null
                      ) is
    v_info table_info_t;
    v_col column_info_t;
    b boolean;
begin
    b := nvl(ascii(p_qual)<>PROC,true);
    if b and find_column(p_class_id,p_qual,to_number(p_mapped,'FMXX'),v_info,v_col) then
      p_table := v_col.tbl_name;
      p_column:= v_col.col_name;
      p_features := v_col.base_id||'.'||v_col.target_id||'.'||v_col.features||v_col.flags||'.'||v_col.self_class_id||'.'||v_col.class_id;
      return;
    end if;
    if not b or nvl(p_mapped,'0')<>'1' and p_qual='CLASS_ID' then
        if table_exist(p_class_id,v_info) then
          p_table := v_info.table_name;
        else
          p_table := 'OBJECTS';
        end if;
        if v_info.cached > 1 or v_info.cached < -1 then
          v_info.param_group := '..0000000.';
        else
          v_info.param_group := '..0000010.';
        end if;
        if v_info.param_group='PARTITION' then
          v_info.param_group := '..00001'||substr(v_info.param_group,8);
        elsif v_info.param_group='PARTVIEW' then
          v_info.param_group := '..00002'||substr(v_info.param_group,8);
        end if;
        if b then
          if v_info.table_name<>'OBJECTS' then
            p_column := ''''||p_class_id||'''';
          else
            p_column := p_qual;
          end if;
          v_info.param_group := constant.GENERIC_STRING||v_info.param_group||constant.GENERIC_STRING;
        else
          p_column:= substr(p_qual,2);
          if p_qual='%ROWID' then
            v_info.param_group := constant.OLE||v_info.param_group||p_qual;
          else
            v_info.param_group := constant.GENERIC_NUMBER||v_info.param_group||constant.GENERIC_NUMBER;
          end if;
        end if;
        p_features := v_info.param_group||'.'||p_class_id;
    end if;
end qual_column;
--
-- @METAGS attr_column
procedure attr_column ( p_class_id IN  varchar2,
                        p_qual     IN  varchar2,
                        p_table    OUT nocopy varchar2,
                        p_column   OUT nocopy varchar2,
                        p_mapped   IN  varchar2 default null
					  ) is
    v_str varchar2(200);
begin
    qual_column(p_class_id,p_qual,p_table,p_column,v_str,p_mapped);
end attr_column;
--
-- @METAGS attr_column
function attr_column ( p_class_id IN varchar2,
                       p_qual     IN varchar2,
					   p_table    IN boolean default FALSE
			         ) return varchar2 is
    table_name  varchar2(30);
    column_name varchar2(30);
begin
	attr_column( p_class_id, p_qual, table_name, column_name );
	if p_table then
		return table_name||'.'||column_name;
	end if;
	return column_name;
end attr_column;
--
function field_exist( p_qual  IN OUT nocopy varchar2,
                      p_class IN varchar2,
                      p_tbl   IN boolean
                    ) return boolean is
    v_qual  varchar2(500);
    v_tbl   table_info_t;
    v_col   column_info_t;
    m pls_integer;
    b boolean;
begin
  if p_class is null then
    return false;
  end if;
  if ascii(p_qual)=PROC then
    if p_qual='%id' then
      v_qual := 'ID';
      b := null;
    elsif p_qual='%class' then
      v_qual := 'CLASS_ID';
      b := null;
    else
      v_qual := upper(substr(p_qual,2))||'_ID';
      b := true;
    end if;
  else
    v_qual := p_qual;
    b := false;
  end if;
  if p_tbl then
    if nvl(b,true) then
      p_qual := 'OBJECT.'||v_qual;
      return true;
    end if;
    if find_column(p_class,v_qual,8,v_tbl,v_col) then
      p_qual := v_col.class_id||'.'||v_col.col_name;
      return true;
    end if;
  elsif table_exist(p_class,v_tbl) and v_tbl.distance = 0 then
    m := 4;
    if b is null then
      p_qual:= 'OBJECT.'||v_qual;
      return true;
    elsif b then
      m := 6;
    end if;
    if find_column(p_class,v_qual,m,v_tbl,v_col) then
      p_qual := v_col.class_id||'.'||v_col.col_name;
      return true;
    end if;
  elsif not b then
    if find_column(p_class,v_qual,12,v_tbl,v_col) then
      p_qual := v_col.class_id||'.'||v_col.col_name;
      return true;
    end if;
  end if;
  return false;
end field_exist;
--
function qual_exist( p_qual  IN OUT nocopy varchar2,
                     p_class IN varchar2,
                     p_self  IN boolean
                    ) return boolean is
  v_tbl   table_info_t;
  v_col   column_info_t;
  v_cls   varchar2(16);
  v_idx   varchar2(500);
  b boolean;
begin
  if p_class is null then
    return false;
  end if;
  if substr(p_qual,1,2)<>'C_' then
    if p_qual in ('ID','CLASS_ID','STATE_ID','COLLECTION_ID','ROWID') then
      b := true;
    end if;
  end if;
  if table_exist(p_class,v_tbl) and v_tbl.distance = 0 then
    if b then
      if p_qual in ('ID','ROWID') then
        p_qual := '%'||lower(p_qual);
        return true;
      elsif p_qual='CLASS_ID' then
        p_qual := '%class';
        return true;
      end if;
    end if;
  elsif b then
    return false;
  end if;
  v_cls := p_class;
  loop
    if not class_cols.exists(v_cls) then
      fill_class_cols(v_cls,v_tbl,v_col);
    end if;
    v_idx := col_idxs.next(v_cls||':');
    while v_idx like v_cls||':_%' loop
      if col_types(col_idxs(v_idx)).col_name = p_qual then
        p_qual := substr(v_idx,length(v_cls)+1);
        if b then
          p_qual := '%'||lower(replace(p_qual,'_ID'));
        end if;
        return true;
      end if;
      v_idx := col_idxs.next(v_idx);
    end loop;
    exit when p_self;
    v_cls := class_parent(v_cls);
    exit when v_cls is null or v_cls = constant.OBJECT;
    if table_exist(v_cls,v_tbl) then null; end if;
  end loop;
  return false;
end qual_exist;
--
procedure get_fields(p_quals in out nocopy constant.varchar2_table,
                     p_types in out nocopy constant.refstring_table,
                     p_class varchar2,p_mode boolean default true,p_self number default 0) is
  i pls_integer;
  j pls_integer;
  p pls_integer;
  n pls_integer;
  b boolean;
  cls varchar2(16);
  str varchar2(256);
  cid varchar2(16);
  cl  class_info_t;
  atr attr_info_t;
  tbl table_info_t;
  col column_info_t;
begin
  p_quals.delete; p_types.delete;
  if not class_exist(p_class,cl) then
    return;
  end if;
  if cl.kernel or pk_is_rowid(cl.class_id) or not cl.key_attr is null then
    cid := constant.REFSTRING;
  else
    cid := constant.GENERIC_NUMBER;
  end if;
  if cl.class_id = constant.OBJECT then
    p_quals(0) := 'STATE_ID.%state'; p_types(0) := constant.REFSTRING;
    p_quals(-1):= 'COLLECTION_ID.%collection'; p_types(-1) := constant.COLLECTION;
    p_quals(-2):= 'CLASS_ID.%class'; p_types(-2):= constant.REFSTRING;
    p_quals(-3):= 'ID.%id'; p_types(-3) := cid;
  elsif p_mode and bitand(p_self,8)=0 then
    if cl.base_id = constant.STRUCTURE then
      n := 0; i := 2;
      str := get_parents(cl.class_id,false)||cl.class_id||'.';
      loop
        p := instr(str,'.',i);
        exit when p = 0;
        cls := substr(str,i,p-i);
        i := p+1;
        if not class_attrs.exists(cls) then
          fill_class_attrs(cls,atr);
        end if;
        p := 1;
        loop
          j := instr(class_attrs(cls),':',p);
          exit when j = 0;
          p := j+1;
          j := instr(class_attrs(cls),';',p);
          exit when j = 0;
          p := substr(class_attrs(cls),p,j-p);
          atr := attr_types(p);
          p := j;
          if ( bitand(p_self,1)=0 or cls=cl.class_id )
            and ( bitand(p_self,2)=0 or nvl(atr.flags,'0')<>constant.PRIMARY_ATTR )
            and ( bitand(p_self,4)=0 or nvl(atr.flags,'0')<>constant.METHOD_ATTRIBUTE )
          then
            n := n+1;
            p_quals(n) := 'C_'||atr.attr_id||'.'||atr.attr_id;
            p_types(n) := atr.self_class_id;
          end if;
        end loop;
      end loop;
      p_quals(0) := 'STATE_ID.%state'; p_types(0) := constant.REFSTRING;
      p_quals(-1):= 'COLLECTION_ID.%collection'; p_types(-1) := constant.COLLECTION;
      p_quals(-2):= 'CLASS_ID.%class'; p_types(-2):= constant.REFSTRING;
      p_quals(-3):= 'ID.%id'; p_types(-3) := cid;
    else
      p_quals(1) := ' '; p_types(1) := cl.class_id;
    end if;
  else
    cls := cl.class_id;
    n := 0; i := 0;
    loop
      b := table_exist(cls,tbl) and tbl.distance = 0;
      if not class_cols.exists(cls) then
        fill_class_cols(cls,tbl,col);
      end if;
      p := 2;
      loop
        j := instr(class_cols(cls),';',p);
        exit when j = 0;
        p := substr(class_cols(cls),p,j-p);
        col := col_types(p);
        p := j+1;
        if ( bitand(p_self,2)=0 or col.flags not like 'P%' and ( col.mapped_id is null or col.mapped_id=constant.OBJECT ) )
          and ( bitand(p_self,4)=0 or col.flags not like 'A%' )
        then
          if b then
            j := 0;
            if col.qual in ('ID','CLASS_ID','COLLECTION_ID','STATE_ID') and col.qual=col.col_name then
              if not p_mode then
                if col.qual='COLLECTION_ID' then
                  if p_quals.exists(0) and p_quals(0)='STATE_ID.%state' then
                    p_quals(-1):= 'COLLECTION_ID.%collection'; p_types(-1):= constant.COLLECTION;
                  else
                    p_quals(0) := 'COLLECTION_ID.%collection'; p_types(0) := constant.COLLECTION;
                  end if;
                elsif col.qual='STATE_ID' then
                  if p_quals.exists(0) and p_quals(0)='COLLECTION_ID.%collection' then
                    p_quals(-1) := p_quals(0); p_types(-1) := p_types(0);
                  end if;
                  p_quals(0) := 'STATE_ID.%state'; p_types(0) := constant.REFSTRING;
                end if;
              end if;
            elsif not p_mode then
              j := 1;
            elsif bitand(p_self,1)=0 and col.mapped_id is null or bitand(p_self,1)>0 and i = 0 then
              j := 1;
            end if;
          else
            j := 1;
          end if;
          if j > 0 then
            n := n+1;
            p_quals(n) := col.col_name||'.'||col.qual;
            if col.base_id = constant.GENERIC_BOOLEAN then
              p_types(n) := constant.BOOLSTRING;
            else
              p_types(n) := col.self_class_id;
            end if;
          end if;
        end if;
      end loop;
      if not p_mode then
        if b then
          j := nvl(p_quals.first,1)-1;
          p_quals(j) := 'CLASS_ID.%class'; p_types(j) := constant.REFSTRING;
          j := j-1;
          p_quals(j) := 'ID.%id'; p_types(j) := cid;
        elsif p_quals.count=0 then
          p_quals(1) := ' '; p_types(1) := constant.BOOLSTRING;
        end if;
        return;
      end if;
      cls := class_parent(cls);
      exit when cls is null or cls = constant.OBJECT;
      i := i+1;
    end loop;
    p_quals(0) := 'STATE_ID.%state'; p_types(0) := constant.REFSTRING;
    p_quals(-1):= 'COLLECTION_ID.%collection'; p_types(-1) := constant.COLLECTION;
    p_quals(-2):= 'CLASS_ID.%class'; p_types(-2):= constant.REFSTRING;
    p_quals(-3):= 'ID.%id'; p_types(-3) := cid;
  end if;
end;
--
procedure get_class_columns(p_cols in out nocopy column_info_tbl_t, p_class varchar2, p_self boolean) is
  v_typ class_info_t;
  v_col column_info_t;
  v_tbl table_info_t;
  v_cls varchar2(16);
  n pls_integer;
  i pls_integer;
  j pls_integer;
  d pls_integer;
begin
  n := nvl(p_cols.last,0);
  if not class_exist(p_class,v_typ) then
    return;
  end if;
  v_cls := v_typ.class_id;
  loop
    if not class_cols.exists(v_cls) then
      if table_exist(v_cls,v_tbl) then null; end if;
      fill_class_cols(v_cls,v_tbl,v_col);
    end if;
    i := 2;
    loop
      j := instr(class_cols(v_cls),';',i);
      exit when j = 0;
      i := substr(class_cols(v_cls),i,j-i);
      n := n+1;
      p_cols(n) := col_types(i);
      i := j+1;
    end loop;
    exit when p_self;
    v_cls := v_typ.parent_id;
    exit when v_cls is null or v_cls = constant.OBJECT;
    exit when not class_exist(v_cls,v_typ);
  end loop;
end;
--
procedure get_partition(p_name in out nocopy varchar2, p_key in out nocopy number,
                        p_class_id varchar2, p_position integer default null) is
    v_cur   pls_integer;
    v_pos   pls_integer;
    v_mirr  boolean;
    v_idx   varchar2(20);
begin
    p_name := null; p_key := null;
    if class_parts.exists(p_class_id) then
      v_cur := class_parts(p_class_id);
      if v_cur=0 then return; end if;
    else
      select nvl(max(partition_position),0) into v_cur
        from class_partitions where class_id=p_class_id;
      class_parts(p_class_id) := v_cur;
      if v_cur=0 then return; end if;
      for c in (
        select partition_position, partition_name, partition_key, mirror
          from class_partitions where class_id=p_class_id and partition_position is not null
      ) loop
        class_parts(p_class_id||'.'||c.partition_position) := c.partition_key||'.'||c.mirror||'.'||c.partition_name;
      end loop;
    end if;
    v_pos := nvl(p_position,0);
    if v_pos <= 0 then
      if v_pos <= -1000 then
        v_pos := v_pos+1000;
        v_mirr:= true;
      end if;
      v_pos := v_cur+v_pos;
    elsif v_pos > 1000 then
      v_pos := v_pos-1000;
      v_mirr:= true;
    end if;
    if v_pos < 1 then
        v_pos := 1;
    end if;
    if v_pos>v_cur then
        v_pos := v_cur;
    end if;
    v_idx := p_class_id||'.'||v_pos;
    if class_parts.exists(v_idx) then
      if v_pos = v_cur then
        p_key := 1000;
        if v_mirr then
          v_pos := instr(class_parts(v_idx),'.');
        end if;
      else
        v_pos := instr(class_parts(v_idx),'.');
        p_key := substr(class_parts(v_idx),1,v_pos-1);
      end if;
      v_cur := instr(class_parts(v_idx),'.',-1);
      if v_mirr then
        p_name := substr(class_parts(v_idx),v_pos+1,v_cur-v_pos-1);
        if p_name is not null then
          p_name := '#'||p_name;
          return;
        end if;
      end if;
      p_name := substr(class_parts(v_idx),v_cur+1);
    end if;
exception when value_error then
    p_name := null; p_key := null;
end;
-- @METAGS partition_name
function partition_name(p_class_id varchar2, p_position integer default null) return varchar2 is
    v_name  varchar2(30);
    v_key   number;
begin
    get_partition(v_name,v_key,p_class_id,p_position);
    return v_name;
end;
--
function partition_key(p_class_id varchar2, p_position integer default null) return number is
    v_name  varchar2(30);
    v_key   number;
begin
    get_partition(v_name,v_key,p_class_id,p_position);
    return v_key;
end;
-- @METAGS method_exist
function method_exist ( p_sname     IN varchar2,
			            p_method    IN OUT nocopy method_info_t,
                        p_class_id  IN varchar2
		              ) return boolean is
    v_sname     varchar2(16);
    v_class_id  varchar2(16);
    v_class     class_info_t;
    v_getpack   boolean;
begin
    if length(p_sname) > 16 or length(p_class_id) > 16 then
        p_method := null;
		return FALSE;
	end if;
    v_sname := upper(p_sname);
    v_class_id := upper(p_class_id);
    v_getpack := true;
    if p_method.features < 0 then
      v_getpack := false;
    end if;
-- searching for p_sname through all levels of inheritance
    for c in (select /*+ INDEX (class_relations unq_cls_rel_chld_dist) */
                    id, name, short_name, class_id, flags, propagate,
                    result_class_id, package_name, text_type, ext_id, src_id
               from methods, class_relations
              where short_name = v_sname
                and class_id = parent_id
                and child_id = v_class_id
              order by distance)
    loop
        p_method.id   := c.id;
        p_method.name := c.name;
        p_method.sname:= c.short_name;
        p_method.flags:= c.flags;
        p_method.ext_id := c.ext_id;
        p_method.class_id := c.class_id;
        p_method.result_id:= c.result_class_id;
        if c.package_name is null and c.src_id is not null then
          if v_getpack then
            select package_name into p_method.package from methods where id = c.src_id;
          else
            select short_name into p_method.package from methods where id = c.src_id;
          end if;
        elsif v_getpack then
          p_method.package  := c.package_name;
        else
          p_method.package  := c.short_name;
        end if;
        p_method.features := bitand(c.text_type,3);
        if c.propagate = '1' then -- archive package
          p_method.features := p_method.features + 4;
        end if;
  --
        if p_method.result_id is not null and class_exist(p_method.result_id,v_class) then
            p_method.base_id := v_class.base_id;
            p_method.class_ref:= v_class.class_ref;
            p_method.interface:= v_class.interface;
            p_method.is_array := v_class.base_id in (constant.COLLECTION,constant.GENERIC_TABLE);
        else
            p_method.base_id := NULL;
            p_method.class_ref := NULL;
            p_method.interface := NULL;
            p_method.is_array := FALSE;
        end if;
        return TRUE;
    end loop;
  --
    p_method := null;
	return FALSE;
end method_exist;
--
-- @METAGS desc_method
procedure desc_method ( p_id     IN  varchar2,
	                    p_method IN OUT nocopy method_info_t
					  ) is
    v_class class_info_t;
    v_arch  varchar2(10);
    v_src   varchar2(16);
    v_getpack   boolean := true;
begin
    if p_method.features < 0 then
      v_getpack := false;
    end if;
	select name,
		   short_name,
           ext_id,
		   class_id,
		   flags,
		   result_class_id,
           package_name,
           text_type,
           propagate,
           src_id
	into p_method.name,
		 p_method.sname,
         p_method.ext_id,
		 p_method.class_id,
		 p_method.flags,
		 p_method.result_id,
         p_method.package,
         p_method.features,
         v_arch,
         v_src
	from methods where id = p_id;
    p_method.id := p_id;
    if p_method.package is null and v_src is not null then
      if v_getpack then
        select package_name into p_method.package from methods where id = v_src;
      else
        select short_name into p_method.package from methods where id = v_src;
      end if;
    elsif not v_getpack then
      p_method.package := p_method.sname;
    end if;
    p_method.features := bitand(p_method.features,3);
    if v_arch = '1' then -- archive package
      p_method.features := p_method.features + 4;
    end if;
--
	if p_method.result_id is not null and class_exist(p_method.result_id,v_class) then
        p_method.base_id := v_class.base_id;
		p_method.class_ref:= v_class.class_ref;
		p_method.interface:= v_class.interface;
        p_method.is_array := v_class.base_id in (constant.COLLECTION,constant.GENERIC_TABLE);
	else
        p_method.base_id := NULL;
		p_method.class_ref := NULL;
		p_method.interface := NULL;
        p_method.is_array := FALSE;
	end if;
--
end desc_method;
--
function  find_method ( p_id     IN  varchar2,
	                    p_method IN OUT nocopy method_info_t
					  ) return boolean is
begin
    desc_method(p_id,p_method);
    return true;
exception when no_data_found then
    p_method := null;
    return false;
end;
--
-- @METAGS is_parent
procedure fill_parents(p_list in out nocopy varchar2, p_class varchar2) is
begin
  p_list := '.';
  for c in (
    select /*+ index(cr unq_cls_rel_chld_dist) */ parent_id
      from class_relations cr where child_id=p_class and distance>0
     order by distance
  ) loop
    p_list := '.'||c.parent_id||p_list;
  end loop;
end;
--
function is_parent ( p_parent_class IN varchar2,
                     p_child_class  IN varchar2,
                     p_start    IN boolean default FALSE
				   ) return boolean is
    v_class class_info_t;
    lst varchar2(256);
    str varchar2(30);
begin
    if p_child_class=p_parent_class then
      return not p_start;
    elsif p_parent_class=constant.OBJECT then
      return true;
    elsif p_child_class=constant.OBJECT then
      return false;
    end if;
    if class_exist(p_child_class,v_class) then
      if v_class.parent_id=p_parent_class then
        return true;
      elsif v_class.parent_id=constant.OBJECT then
        return false;
      end if;
      str := '.'||p_parent_class||'.';
      if classparent.exists(v_class.class_id) then
        return instr(classparent(v_class.class_id),str)>0;
      end if;
      fill_parents(lst,v_class.class_id);
      classparent(v_class.class_id) := lst;
      return instr(lst,str)>0;
    end if;
	return FALSE;
end is_parent;
--
function get_parents( p_class IN varchar2, p_check_class boolean default true ) return varchar2 is
    v_class class_info_t;
    lst varchar2(256);
begin
    if p_check_class then
      if not class_exist(p_class,v_class) then
        return null;
      end if;
    else
      v_class.class_id := p_class;
    end if;
    if classparent.exists(v_class.class_id) then
      return classparent(v_class.class_id);
    end if;
    fill_parents(lst,v_class.class_id);
    classparent(v_class.class_id) := lst;
    return lst;
end;
--
function top_parent( p_class IN varchar2 ) return varchar2 is
    lst varchar2(256);
    idx pls_integer;
begin
    lst := get_parents(p_class,true);
    idx := instr(lst,'.',2);
    if idx>0 then
      return substr(lst,2,idx-2);
    end if;
	return null;
end;
--
function common_parent( p_class1 varchar2, p_class2 varchar2 ) return varchar2 is
    lst1 varchar2(256);
    lst2 varchar2(256);
    i1 pls_integer;
    i2 pls_integer;
    i pls_integer;
    j pls_integer;
begin
    if p_class1 = p_class2 then
      return p_class1;
    end if;
    lst1 := get_parents(p_class1,true);
    i1 := instr(lst1,'.',2);
    if i1 > 0 and instr(lst1,'.'||p_class2||'.') > 0 then
      return p_class2;
    end if;
    lst2 := get_parents(p_class2,true);
    i2 := instr(lst2,'.',2);
    if i2 > 0 then
      if instr(lst2,'.'||p_class1||'.') > 0 then
        return p_class1;
      end if;
    elsif i1 = 0 then
      return null;
    end if;
    if i1 = i2 and substr(lst1,2,i1-2) = substr(lst2,2,i2-2) then
      i := 2;
      loop
        j := i1+1;
        i1 := instr(lst1,'.',j);
        i2 := instr(lst2,'.',j);
        if i1 > 0 and i2 >0 and i1 = i2 and substr(lst1,2,i1-2) = substr(lst2,2,i2-2) then
          i := j;
        else
          exit;
        end if;
      end loop;
      return substr(lst1,i,j-i-1);
    else
      return null;
    end if;
end;
--
-- @METAGS is_compatible
function is_compatible ( p_parent_class IN varchar2,
                         p_child_class  IN varchar2
					   ) return boolean is
    v_parent  class_info_t;
    v_child   class_info_t;
begin
  if not class_exist(p_parent_class,v_parent) then
    return FALSE;
  end if;
  if not class_exist(p_child_class,v_child) then
    return FALSE;
  end if;
  if v_parent.base_id=v_child.base_id then
    if v_parent.base_id=constant.REFERENCE then
      return is_parent(v_parent.class_ref, v_child.class_ref);
    elsif v_parent.base_id=constant.COLLECTION then
      return is_compatible(v_parent.class_ref, v_child.class_ref);
    elsif v_parent.base_id in (constant.STRUCTURE,constant.OLE,constant.GENERIC_TABLE) then
      return p_parent_class=p_child_class;
    end if;
    return TRUE;
  elsif v_parent.base_id=constant.MEMO and v_child.base_id=constant.GENERIC_STRING then
    return TRUE;
  elsif v_child.base_id=constant.MEMO and v_parent.base_id=constant.GENERIC_STRING then
    return TRUE;
  end if;
  return FALSE;
end is_compatible;
--
-- @METAGS is_reference
function is_reference ( p_referencing IN varchar2,
                        p_referenced  IN varchar2
					  ) return boolean is
  v_class class_info_t;
begin
  if class_exist(p_referencing,v_class) then
	return is_parent(v_class.class_ref, p_referenced);
  end if;
  return FALSE;
end is_reference;
--
-- @METAGS get_class
function get_class ( p_object_id IN number ) return varchar2 is
begin
    return rtlobj.get_class(p_object_id);
end;
--
function get_class ( p_object_id IN varchar2 ) return varchar2 is
begin
    return rtlobj.get_class(p_object_id);
end;
--
-- @METAGS get_parent
procedure get_parent ( p_collect number, p_object in out nocopy rtl.object_rec ) is
begin
    rtlobj.get_parent(p_collect,p_object.id,p_object.class_id);
end;
--
-- @METAGS counter
procedure counter( p_collect_id number,
                   p_class      varchar2,
                   p_cnt in out nocopy number ) is
    v_class varchar2(16) := p_class;
begin
    if v_class is null then
        v_class := rtlobj.coll2class(p_collect_id);
        if v_class is null then p_cnt:=0; return; end if;
    end if;
    execute immediate 'BEGIN :CNT:='||class_mgr.interface_package(v_class)||
        '.COUNT$(:COLL,:CNT); END;'
        using in out p_cnt, p_collect_id;
end;
--
-- @METAGS c_empty
function c_empty ( p_collect_id number,
                   p_class      varchar2  default NULL ) return boolean is
    v_class varchar2(16) := p_class;
    v_cnt   number:=1;
begin
    if v_class is null then
        v_class := rtlobj.coll2class(p_collect_id);
        if v_class is null then return TRUE; end if;
    end if;
    counter(p_collect_id,v_class,v_cnt);
    return v_cnt=0;
end c_empty;
--
-- @METAGS attr_name
function attr_name ( p_attr_id varchar2, p_class_id varchar2 ) return varchar2 is
  v_attr  attr_info_t;
  v_class class_info_t;
begin
  if length(p_attr_id)>16 or length(p_class_id)>16 then
    return null;
  end if;
  if find_attr(upper(p_attr_id),upper(p_class_id),v_attr,v_class) then
    return v_attr.name;
  end if;
  return null;
end;
--
function attr_name ( p_attr_pos pls_integer, p_class_id varchar2 ) return varchar2 is
  v_attr  attr_info_t;
  v_class class_info_t;
begin
  if length(p_class_id)>16 then
    return null;
  end if;
  if find_attr_by_pos(p_attr_pos,upper(p_class_id),v_attr,v_class) then
    return v_attr.name;
  end if;
  return null;
end;
--
-- @METAGS state_name
function state_name ( p_state_id varchar2, p_class_id varchar2 ) return varchar2 is
    v_name  varchar2(128);
begin
    select name into v_name from states
    where class_id = upper(p_class_id) and id = upper(p_state_id);
    return v_name;
exception when others then
    return NULL;
end;
--
-- @METAGS class_name
function class_name ( p_class_id varchar2 ) return varchar2 is
  v_class class_info_t;
begin
  if class_exist(p_class_id,v_class) then
	return v_class.name;
  end if;
  return NULL;
end;
--
-- @METAGS class_base
function class_base ( p_class_id varchar2, p_sql varchar2 default null ) return varchar2 is
  v_class class_info_t;
begin
  if class_exist(p_class_id,v_class) then
    if p_sql='0' then
      return v_class.base_id;
    end if;
	return v_class.base_class_id;
  end if;
  return NULL;
end;
--
-- @METAGS class_target
function class_target ( p_class_id varchar2 ) return varchar2 is
  v_class class_info_t;
begin
  if class_exist(p_class_id,v_class) then
	return v_class.class_ref;
  end if;
  return NULL;
end;
--
function class_parent ( p_class_id varchar2 ) return varchar2 is
  v_class class_info_t;
begin
  if class_exist(p_class_id,v_class) then
	return v_class.parent_id;
  end if;
  return NULL;
end;
--
function class_entity ( p_class_id varchar2 ) return varchar2 is
  v_class class_info_t;
begin
  if class_exist(p_class_id,v_class) then
	return v_class.entity_id;
  end if;
  return NULL;
end;
--
function class_flags ( p_class_id varchar2 ) return varchar2 is
  v_class class_info_t;
begin
  if class_exist(p_class_id,v_class) then
	return v_class.flags;
  end if;
  return NULL;
end;
--
function class_state ( p_class_id varchar2 ) return varchar2 is
  v_class class_info_t;
begin
  if class_exist(p_class_id,v_class) then
	return v_class.state_id;
  end if;
  return NULL;
end;
--
-- @METAGS class_size
function class_size ( p_class_id varchar2 ) return pls_integer is
    v_base  varchar2(16);
    v_size  pls_integer;
    siz     pls_integer := 0;
begin
  for c in (
    select cl.id, cl.base_class_id, cl.data_size
      from classes cl, class_relations cr
     where cr.child_id=p_class_id and cl.id=cr.parent_id
            )
  loop
    v_base := c.base_class_id;
    if v_base = constant.STRUCTURE then
        for cc in (select self_class_id from class_attributes where class_id=c.id)
        loop
            siz := siz + class_size(cc.self_class_id);
        end loop;
    else
        v_size := c.data_size;
        if v_base = constant.GENERIC_STRING  then
            siz := siz + nvl(v_size,constant.STR_PREC);
        elsif v_base = constant.GENERIC_NUMBER  then
            siz := siz + nvl(v_size,38);
        elsif v_base = constant.GENERIC_DATE  then
            siz := siz + nvl(v_size,8);
        elsif v_base = constant.GENERIC_BOOLEAN then
            siz := siz + nvl(v_size,constant.BOOL_PREC);
        elsif v_base = constant.MEMO then
            siz := siz + nvl(v_size,constant.MEMO_PREC);
        else
            siz := siz + nvl(v_size,16);
        end if;
    end if;
  end loop;
  return siz;
end;
--
function class_temp_type ( p_class_id varchar2 ) return varchar2 is
  v_class class_info_t;
begin
  if class_exist(p_class_id,v_class) then
  return v_class.temp_type;
  end if;
  return NULL;
end;
--
function qualprop(
		p_class_id	in varchar2,
		p_qual		in varchar2,
		p_elem_class		out nocopy varchar2,
		p_elem_base_class	out nocopy varchar2,
		p_elem_target_class	out nocopy varchar2,
		p_elem_name			in out nocopy varchar2,
        p_separator in varchar2) return varchar2 is
    v_class     class_info_t;
	v_elem      attr_info_t;
    v_qual      varchar2(700);
    v_el        varchar2(700);
    v_cls       varchar2(100);
	n_dot       pls_integer;
    v_sep       boolean;
begin
	p_elem_class		:= null;
	p_elem_base_class 	:= null;
	p_elem_target_class	:= null;
	v_qual:= rtrim(p_qual);
    v_sep := not p_separator is null;
	if v_qual is null then
      if not class_exist(p_class_id,v_class) then
        return message.get_text('EXEC','BAD_CLASS_ID', p_class_id);
      end if;
      if v_sep and not p_qual is null then
        if p_elem_name is null then
          p_elem_name := v_class.name;
        else
          p_elem_name := p_elem_name||p_separator||v_class.name;
        end if;
      end if;
      p_elem_class		:= v_class.class_id;
      p_elem_base_class 	:= v_class.base_class_id;
      p_elem_target_class := v_class.class_ref;
      return null;
	end if;
	n_dot := instr(v_qual, '.');
    if n_dot = 1 then
      v_qual := substr(v_qual, 2); n_dot := instr(v_qual, '.');
	end if;
    if n_dot > 0 then
      v_el := substr(v_qual, 1, n_dot - 1);
      -- Оставляем первую точку, она нам нужна для разыменования REFERENCE
      v_qual := substr(v_qual, n_dot);
    else
      v_el := v_qual; v_qual := null;
    end if;
	n_dot := instr(v_el, ':');
    if n_dot>1 then
      v_cls:= substr(v_el,1,n_dot-1);
      v_el := substr(v_el,n_dot+1);
    else
      v_cls:= p_class_id;
    end if;
    if not class_exist(v_cls,v_class) then
      return message.get_text('EXEC','BAD_CLASS_ID', v_cls);
    end if;
	if v_class.base_class_id = 'STRUCTURE' then
      --dbms_output.put_line('Реквизит: ' || v_el);
      if not find_attr(v_el,v_class.class_id,v_elem,v_class) then
        return message.get_text('CLS','BAD_CLASS_ATTR', v_cls, v_el);
      end if;
      if v_sep then
        if p_elem_name is null then
          p_elem_name := v_elem.name;
        else
          p_elem_name := p_elem_name||p_separator||v_elem.name;
        end if;
      end if;
      return qualprop(v_elem.self_class_id, v_qual, p_elem_class, p_elem_base_class, p_elem_target_class, p_elem_name, p_separator);
    else
      if rtrim(v_el) is null then
        if v_sep and not v_el is null then
          if p_elem_name is null then
            p_elem_name := v_class.name;
          else
            p_elem_name := p_elem_name||p_separator||v_class.name;
          end if;
        end if;
      elsif v_qual is null then
        v_qual := v_el;
      else
        v_qual := v_el||'.'||v_qual;
      end if;
      if v_class.base_class_id in ('REFERENCE','COLLECTION','TABLE') then
        -- Если уж мы сюда попали - значит мы хотим пойти по target_class_id
        if not v_sep and p_elem_name is null then
          p_elem_name := p_qual;
        end if;
        return qualprop(v_class.class_ref, v_qual, p_elem_class, p_elem_base_class, p_elem_target_class, p_elem_name, p_separator);
      elsif not v_qual is null then
        return message.get_text('CLS','BAD_CLASS_ATTR', v_cls, v_qual);
      else
        p_elem_class		:= v_class.class_id;
        p_elem_base_class 	:= v_class.base_class_id;
		p_elem_target_class := v_class.class_ref;
      end if;
    end if;
    return null;
end qualprop;
--
function qual_class(p_class_id varchar2, p_qual varchar2) return varchar2 is
  v_name varchar2(700);
  v_self varchar2(16);
  v_base varchar2(16);
  v_targ varchar2(16);
begin
  if qualprop(p_class_id,p_qual,v_self,v_base,v_targ,v_name,null) is null then
    return v_self;
  end if;
  return null;
end;
--
function qual_base (p_class_id varchar2, p_qual varchar2) return varchar2 is
  v_name varchar2(700);
  v_self varchar2(16);
  v_base varchar2(16);
  v_targ varchar2(16);
begin
  if qualprop(p_class_id,p_qual,v_self,v_base,v_targ,v_name,null) is null then
    return v_base;
  end if;
  return null;
end;
--
function qual_name (p_class_id varchar2, p_qual varchar2, p_separator varchar2 default ' ') return varchar2 is
  v_name varchar2(4000);
  v_self varchar2(16);
  v_base varchar2(16);
  v_targ varchar2(16);
begin
  if qualprop(p_class_id,p_qual,v_self,v_base,v_targ,v_name,p_separator) is null then
    null;
  end if;
  return v_name;
end;
--
function qual_target(p_class_id varchar2, p_qual varchar2) return varchar2 is
  v_name varchar2(700);
  v_self varchar2(16);
  v_base varchar2(16);
  v_targ varchar2(16);
begin
  if qualprop(p_class_id,p_qual,v_self,v_base,v_targ,v_name,null) is null then
    return v_targ;
  end if;
  return null;
end;
--
procedure correct_qual(p_class_id varchar2,p_qual in out nocopy varchar2) is
    v_qual      varchar2(700);
    v_cls       varchar2(100);
    v_base      varchar2(100);
    v_name      varchar2(700);
	i           pls_integer;
	j           pls_integer;
begin
	i := instr(p_qual, '@');
    if nvl(i,0)=0 then
      return;
    end if;
    v_qual := substr(p_qual,1,i-1);
    if v_qual is null then
      v_cls := p_class_id;
    else
      j := instr(v_qual,'.',-1);
      if j>0 then
        if j+1=i then
          v_qual := substr(p_qual,1,j-1);
          if not qualprop(p_class_id,v_qual,v_cls,v_base,v_cls,v_name,null) is null then
            return;
          end if;
        elsif instr(v_qual,':',-1)+1=i then
          v_cls := substr(p_qual,j+1,i-j-2);
        else
          return;
        end if;
      elsif instr(v_qual,':',-1)+1=i then
        v_cls := substr(p_qual,1,i-2);
      else
        return;
      end if;
    end if;
    if v_cls is null then
      return;
    end if;
	j := instr(p_qual,'.',i+1);
    if j>0 then
      v_qual := substr(p_qual,i+1,j-i-1);
    else
      v_qual := substr(p_qual,i+1);
    end if;
    if qual_exist(v_qual,v_cls,false) then
      if j>0 then
        v_qual := v_qual||substr(p_qual,j);
        correct_qual(v_cls,v_qual);
      end if;
      p_qual := substr(p_qual,1,i-1)||v_qual;
    end if;
end correct_qual;
--
-- @METAGS coll2class
function coll2class ( p_collect_id IN number ) return varchar2 is
begin
    return rtlobj.coll2class(p_collect_id);
end;
--
-- @METAGS c_count
function c_count ( p_collect_id number,
                   p_class      varchar2  default NULL ) return pls_integer is
    v_class varchar2(16) := p_class;
    v_cnt   number;
begin
    if v_class is null then
        v_class := rtlobj.coll2class(p_collect_id);
        if v_class is null then return 0; end if;
    end if;
    counter(p_collect_id,v_class,v_cnt);
    return v_cnt;
end c_count;
--
-- @METAGS operating_date
function operating_date ( p_date IN date  ) return date is
	v_date  date := sysdate;
	v_trunc date := trunc(v_date);
begin
	if trunc(p_date) = v_trunc then
		return v_date;
	elsif trunc(p_date) < v_trunc then
		return v_trunc;
	else
		return to_date(to_char(v_trunc,'yyyymmdd') || '235959', 'yyyymmddhh24miss');
	end if;
end operating_date;
--
-- @METAGS plsql_exec_name
function plsql_exec_name ( p_method_id IN varchar2, p_validate varchar2 default null ) return varchar2 is
	v_pack_name  varchar2(30);
	v_pack_src   varchar2(30);
    v_short_name varchar2(16);
    v_arch   varchar2(10);
    v_ext_id varchar2(16) := p_method_id;
begin
  loop
	select package_name,
		   short_name,
           propagate,
           ext_id
	into v_pack_name,
		 v_short_name,
         v_arch,
         v_ext_id
	from methods
	where id = v_ext_id;
    exit when v_ext_id is null;
    v_pack_src := v_pack_name;
  end loop;
  if v_pack_name is null then
    v_pack_name := v_pack_src;
  end if;
  if p_validate like 'Z_%' then
    if v_arch = '1' and instr(p_validate,'Z_') = 1 then
      v_pack_name := 'Z_'||substr(v_pack_name,3);
    end if;
    if p_validate like 'Z_1' then
      return v_pack_name||'.'||v_short_name||'_VALIDATE';
    end if;
    return v_pack_name||'.'||v_short_name||'_EXECUTE';
  elsif p_validate='1' then
    return v_pack_name||'.'||v_short_name||'_VALIDATE';
  end if;
  return v_pack_name||'.'||v_short_name||'_EXECUTE';
end plsql_exec_name;
--
-- @METAGS set_index_list
procedure set_index_list(p_list  varchar2,
                         p_tbl   in out nocopy   constant.integer_table,
                         p_clear boolean  default true,
                         p_char  varchar2 default null) is
    v_str   varchar2(100);
    v_char  varchar2(1) := substr(nvl(p_char,','),1,1);
    ii  pls_integer := 1;
    l   pls_integer := length(p_list);
    j   pls_integer;
    i   pls_integer;
    jj  pls_integer;
begin
    if p_clear then
        p_tbl.delete; j:=0;
    else
        j := nvl(p_tbl.last,0);
    end if;
    while ii<=l loop
        i := instr(p_list,v_char,ii);
        if i>ii then
            v_str := substr(p_list,ii,i-ii);
        elsif i=0 then
            i := l;
            v_str := substr(p_list,ii);
        else
            v_str := null;
        end if;
        --if i>1 then
          begin
            jj := rtrim(ltrim(v_str));
            j := j+1;
            p_tbl(j) := jj;
          exception when others then null;
          end;
        --end if;
        ii := i+1;
    end loop;
end;
--
-- @METAGS set_refs_list
procedure set_refs_list(p_list  varchar2,
                        p_tbl   in out nocopy   constant.reference_table,
                        p_clear boolean  default true,
                        p_char  varchar2 default null ) is
    v_str   varchar2(100);
    v_char  varchar2(1) := substr(nvl(p_char,','),1,1);
    ii  pls_integer := 1;
    l   pls_integer := length(p_list);
    j   pls_integer;
    i   pls_integer;
    r   number;
begin
    if p_clear then
        p_tbl.delete; j:=0;
    else
        j := nvl(p_tbl.last,0);
    end if;
    while ii<=l loop
        i := instr(p_list,v_char,ii);
        if i>ii then
            v_str := substr(p_list,ii,i-ii);
        elsif i=0 then
            i := l;
            v_str := substr(p_list,ii);
        else
            v_str := null;
        end if;
        --if i>1 then
          begin
            r := rtrim(ltrim(v_str));
            j := j+1;
            p_tbl(j) := r;
          exception when others then null;
          end;
        --end if;
        ii := i+1;
    end loop;
end;
--
procedure set_refs_list(p_list  varchar2,
                        p_tbl   in out nocopy   constant.refstring_table,
                        p_clear boolean  default true,
                        p_char  varchar2 default null ) is
    v_str   varchar2(200);
    v_char  varchar2(1) := substr(nvl(p_char,','),1,1);
    ii  pls_integer := 1;
    l   pls_integer := length(p_list);
    j   pls_integer;
    i   pls_integer;
begin
    if p_clear then
        p_tbl.delete; j:=0;
    else
        j := nvl(p_tbl.last,0);
    end if;
    while ii<=l loop
        i := instr(p_list,v_char,ii);
        if i>ii then
            v_str := substr(p_list,ii,i-ii);
        elsif i=0 then
            i := l;
            v_str := substr(p_list,ii);
        else
            v_str := null;
        end if;
        --if i>1 then
          j := j+1;
          p_tbl(j) := rtrim(ltrim(v_str));
        --end if;
        ii := i+1;
    end loop;
end;
--
procedure set_defs_list(p_list  varchar2,
                        p_tbl   in out nocopy   constant.defstring_table,
                        p_clear boolean  default true,
                        p_char  varchar2 default null ) is
    v_str   varchar2(300);
    v_char  varchar2(1) := substr(nvl(p_char,NL),1,1);
    ii  pls_integer := 1;
    l   pls_integer := length(p_list);
    j   pls_integer;
    i   pls_integer;
begin
    if p_clear then
        p_tbl.delete; j:=0;
    else
        j := nvl(p_tbl.last,0);
    end if;
    while ii<=l loop
        i := instr(p_list,v_char,ii);
        if i>ii then
            v_str := substr(p_list,ii,i-ii);
        elsif i=0 then
            i := l;
            v_str := substr(p_list,ii);
        else
            v_str := null;
        end if;
        --if i>1 then
          j := j+1;
          p_tbl(j) := rtrim(ltrim(v_str));
        --end if;
        ii := i+1;
    end loop;
end;
--
-- @METAGS set_string_list
procedure set_string_list(p_list  varchar2,
                          p_tbl   in out nocopy   constant.string_table,
                          p_clear boolean  default true,
                          p_char  varchar2 default null ) is
    v_str   varchar2(32767);
    v_char  varchar2(100) := nvl(p_char,NL);
    i   pls_integer;
    ii  pls_integer := 1;
    j   pls_integer;
    jj  pls_integer := 0;
    l   pls_integer := length(p_list);
    ll  pls_integer := length(v_char);
    ok  boolean := true;
    b   boolean;
begin
    if p_clear then
        p_tbl.delete; j:=0;
    else
        j := nvl(p_tbl.last,0);
    end if;
    if v_char=CTRL_C then
        b := true;
        v_char:= constant.ESC;
    end if;
    if v_char=constant.ESC then
        ok:= false;
        if ascii(p_list)=3 then
            b := true;
        end if;
        ii := instr(p_list,v_char,1);
        if ii>0 then ii:= ii+1; else return; end if;
        if b then jj:=2; else jj:=1; end if;
    end if;
    while ii<=l loop
        i := instr(p_list,v_char,ii+jj);
        if i>ii then
            v_str := substr(p_list,ii,i-ii);
        elsif i=0 then
            i := l;
            v_str := substr(p_list,ii);
        else
            v_str := null;
        end if;
        if ok then
            j := j+1;
            p_tbl(j) := v_str;
        elsif b then
            j := ascii(v_str) - 1 + 127*(ascii(substr(v_str,2,1))-1);
            p_tbl(j) := replace(substr(v_str,3),constant.NC,constant.ESC);
        else
            j := ascii(v_str);
            p_tbl(j) := replace(substr(v_str,2),constant.NC,constant.ESC);
        end if;
        ii := i+ll;
    end loop;
end;
--
-- @METAGS set_number_list
procedure set_number_list(p_list  varchar2,
                          p_tbl   in out nocopy   constant.number_table,
                          p_clear boolean  default true,
                          p_char  varchar2 default null) is
    v_str   varchar2(100);
    v_char  varchar2(1) := substr(nvl(p_char,','),1,1);
    ii  pls_integer := 1;
    l   pls_integer := length(p_list);
    j   pls_integer;
    i   pls_integer;
    n   number;
begin
    if p_clear then
        p_tbl.delete; j:=0;
    else
        j := nvl(p_tbl.last,0);
    end if;
    while ii<=l loop
        i := instr(p_list,v_char,ii);
        if i>ii then
            v_str := substr(p_list,ii,i-ii);
        elsif i=0 then
            i := l;
            v_str := substr(p_list,ii);
        else
            v_str := null;
        end if;
        --if i>1 then
          begin
            n := rtrim(ltrim(v_str));
            j := j+1;
            p_tbl(j) := n;
          exception when others then null;
          end;
        --end if;
        ii := i+1;
    end loop;
end;
--
-- @METAGS set_date_list
procedure set_date_list(p_list  varchar2,
                        p_tbl   in out nocopy   constant.date_table,
                        p_clear boolean  default true,
                        p_char  varchar2 default null) is
    v_str   varchar2(100);
    v_char  varchar2(1) := substr(nvl(p_char,','),1,1);
    ii  pls_integer := 1;
    l   pls_integer := length(p_list);
    j   pls_integer;
    i   pls_integer;
    d   date;
begin
    if p_clear then
        p_tbl.delete; j:=0;
    else
        j := nvl(p_tbl.last,0);
    end if;
    while ii<=l loop
        i := instr(p_list,v_char,ii);
        if i>ii then
            v_str := substr(p_list,ii,i-ii);
        elsif i=0 then
            i := l;
            v_str := substr(p_list,ii);
        else
            v_str := null;
        end if;
        --if i>1 then
          begin
            d := to_date(rtrim(ltrim(v_str)),constant.DATE_FORMAT);
            j := j+1;
            p_tbl(j) := d;
          exception when others then null;
          end;
        --end if;
        ii := i+1;
    end loop;
end;
--
-- @METAGS set_bool_list
procedure set_bool_list( p_list  varchar2,
                         p_tbl   in out nocopy   constant.boolean_table,
                         p_clear boolean  default true,
                         p_char  varchar2 default null) is
    v_str   varchar2(100);
    v_char  varchar2(1) := substr(nvl(p_char,','),1,1);
    ii  pls_integer := 1;
    l   pls_integer := length(p_list);
    j   pls_integer;
    i   pls_integer;
begin
    if p_clear then
        p_tbl.delete; j:=0;
    else
        j := nvl(p_tbl.last,0);
    end if;
    while ii<=l loop
        i := instr(p_list,v_char,ii);
        if i>ii then
            v_str := substr(p_list,ii,i-ii);
        elsif i=0 then
            i := l;
            v_str := substr(p_list,ii);
        else
            v_str := null;
        end if;
        --if i>1 then
            j := j+1;
            p_tbl(j) := rtrim(ltrim(v_str))=constant.YES;
        --end if;
        ii := i+1;
    end loop;
end;
--
-- @METAGS get_index_list
function get_index_list( p_tbl   in constant.integer_table,
                         p_idx   in out nocopy pls_integer,
                         p_char  varchar2 default null) return varchar2 is
    v_char  varchar2(1) := substr(nvl(p_char,','),1,1);
    v_buf   varchar2(32700);
begin
    p_idx := nvl(p_idx,p_tbl.first);
    while not p_idx is null loop
--        v_buf := v_buf||v_char||p_tbl(p_idx);
        v_buf := v_buf||p_tbl(p_idx)||v_char;
        p_idx := p_tbl.next(p_idx);
    end loop;
    return v_buf;
exception when value_error then return v_buf;
end;
--
-- @METAGS get_refs_list
function get_refs_list ( p_tbl   in constant.reference_table,
                         p_idx   in out nocopy pls_integer,
                         p_char  varchar2 default null) return varchar2 is
    v_char  varchar2(1) := substr(nvl(p_char,','),1,1);
    v_buf   varchar2(32700);
begin
    p_idx := nvl(p_idx,p_tbl.first);
    while not p_idx is null loop
--        v_buf := v_buf||v_char||p_tbl(p_idx);
        v_buf := v_buf||p_tbl(p_idx)||v_char;
        p_idx := p_tbl.next(p_idx);
    end loop;
    return v_buf;
exception when value_error then return v_buf;
end;
--
function get_refs_list ( p_tbl   in constant.refstring_table,
                         p_idx   in out nocopy pls_integer,
                         p_char  varchar2 default null) return varchar2 is
    v_char  varchar2(1) := substr(nvl(p_char,','),1,1);
    v_buf   varchar2(32700);
begin
    p_idx := nvl(p_idx,p_tbl.first);
    while not p_idx is null loop
--        v_buf := v_buf||v_char||p_tbl(p_idx);
        v_buf := v_buf||p_tbl(p_idx)||v_char;
        p_idx := p_tbl.next(p_idx);
    end loop;
    return v_buf;
exception when value_error then return v_buf;
end;
--
function get_defs_list ( p_tbl   in constant.defstring_table,
                         p_idx   in out nocopy pls_integer,
                         p_char  varchar2 default null) return varchar2 is
    v_char  varchar2(1) := substr(nvl(p_char,NL),1,1);
    v_buf   varchar2(32700);
begin
    p_idx := nvl(p_idx,p_tbl.first);
    while not p_idx is null loop
--        v_buf := v_buf||v_char||p_tbl(p_idx);
        v_buf := v_buf||p_tbl(p_idx)||v_char;
        p_idx := p_tbl.next(p_idx);
    end loop;
    return v_buf;
exception when value_error then return v_buf;
end;
--
-- @METAGS get_date_list
function get_date_list ( p_tbl   in constant.date_table,
                         p_idx   in out nocopy pls_integer,
                         p_char  varchar2 default null) return varchar2 is
    v_char  varchar2(1) := substr(nvl(p_char,','),1,1);
    v_buf   varchar2(32700);
begin
    p_idx := nvl(p_idx,p_tbl.first);
    while not p_idx is null loop
--        v_buf := v_buf||v_char||to_char(p_tbl(p_idx),constant.DATE_FORMAT);
        v_buf := v_buf||to_char(p_tbl(p_idx),constant.DATE_FORMAT)||v_char;
        p_idx := p_tbl.next(p_idx);
    end loop;
    return v_buf;
exception when value_error then return v_buf;
end;
--
-- @METAGS get_number_list
function get_number_list(p_tbl   in constant.number_table,
                         p_idx   in out nocopy pls_integer,
                         p_char  varchar2 default null) return varchar2 is
    v_char  varchar2(1) := substr(nvl(p_char,','),1,1);
    v_buf   varchar2(32700);
begin
    p_idx := nvl(p_idx,p_tbl.first);
    while not p_idx is null loop
--        v_buf := v_buf||v_char||to_char(p_tbl(p_idx));
        v_buf := v_buf||to_char(p_tbl(p_idx))||v_char;
        p_idx := p_tbl.next(p_idx);
    end loop;
    return v_buf;
exception when value_error then return v_buf;
end;
--
-- @METAGS get_bool_list
function get_bool_list ( p_tbl   in constant.boolean_table,
                         p_idx   in out nocopy pls_integer,
                         p_char  varchar2 default null) return varchar2 is
    v_char  varchar2(1) := substr(nvl(p_char,','),1,1);
    v_str   varchar2(2);
    v_buf   varchar2(32700);
    ok      boolean;
begin
    p_idx := nvl(p_idx,p_tbl.first);
    while not p_idx is null loop
        ok := p_tbl(p_idx);
        if ok is null then v_str:=v_char;
--        elsif ok then v_str:=v_char||constant.YES;
--        else v_str:=v_char||constant.NO; end if;
        elsif ok then v_str:=constant.YES||v_char;
        else v_str:=constant.NO||v_char; end if;
        v_buf := v_buf||v_str;
        p_idx := p_tbl.next(p_idx);
    end loop;
    return v_buf;
exception when value_error then return v_buf;
end;
--
-- @METAGS get_string_list
function get_string_list(p_tbl   in constant.string_table,
                         p_idx   in out nocopy pls_integer,
                         p_char  in varchar2 default null,
						 p_dch   in varchar2 default null--maximov
						 ) return varchar2 is
    v_char  varchar2(10) := nvl(p_char,NL);
    v_buf   varchar2(32500);
    b   boolean;
    ok  boolean;
    i   pls_integer;
begin
    if v_char = CTRL_C then
      ok:= false;
      b := true;
      v_buf := CTRL_C;
      v_char:= constant.ESC;
    elsif v_char = constant.ESC then
      ok := false;
      if p_tbl.last > 127 then
        b := true;
        v_buf := CTRL_C;
      end if;
    else
      ok := true;
    end if;
    if p_dch is not null then
      v_char := p_dch;
      if not ok then
        ok := null;
      end if;
    end if;
    p_idx := nvl(p_idx,p_tbl.first);--maximov
    while not p_idx is null loop
      if ok then
        v_buf := v_buf||p_tbl(p_idx)||v_char;
      elsif b then
        i := trunc(p_idx/127) + 1;
        if ok is null then
          v_buf := v_buf||v_char||replace(chr((p_idx mod 127)+1)||chr(i)||p_tbl(p_idx),constant.ESC,constant.NC);
        else
          v_buf := v_buf||v_char||chr((p_idx mod 127)+1)||chr(i)||replace(p_tbl(p_idx),constant.ESC,constant.NC);
        end if;
      elsif ok is null then
        v_buf := v_buf||v_char||replace(chr(p_idx)||p_tbl(p_idx),constant.ESC,constant.NC);
      else
        v_buf := v_buf||v_char||chr(p_idx)||replace(p_tbl(p_idx),constant.ESC,constant.NC);
      end if;
      p_idx := p_tbl.next(p_idx);
    end loop;
    return v_buf;
exception when value_error then return v_buf;
end;
--maximov {
function iif(abool in boolean, av1 in varchar2, av2 in varchar2) return varchar2 as
begin
  if abool then
    return av1;
  else
    return av2;
  end if;
end iif;
--
function rpad_val(adata in varchar2, acol_count in pls_integer, achar in varchar2 default null) return varchar2 as
ch varchar2(10) := nvl(achar,GRID_CHAR);
n number := 0;
cind pls_integer := 0;
begin
  loop
    cind := instr(adata,ch,cind + 1);
    exit when cind = 0;
    n := n + 1;
    exit when n = acol_count;
  end loop;
  if    cind = 0 and n = acol_count - 1 then
    return adata;
  elsif cind > 0 then
    return substr(adata,1,cind - 1);
  else null;
    return rpad(adata,length(adata) + acol_count - n - 1,ch);
  end if;
end rpad_val;
--
function grid_get(avalues in constant.string_table, aflags in out nocopy constant.defstring_table,
  aind in out nocopy pls_integer,
  acol_count in pls_integer,
  agrid_char in varchar2 default null, ares_char in varchar2 default null) return varchar2 as
gch varchar2(10) := nvl(agrid_char,GRID_CHAR);
rch varchar2(10) := nvl(ares_char,constant.NC);
result varchar2(32500);
begin
  aind := nvl(aind,aflags.first);
  if aind is null then return null; end if;
  loop
    if    aflags(aind) = 'D' then
      result := 'D,' || aind;
      aflags.delete(aind);
    elsif aflags(aind) = 'I' then
      result := 'S,' || aind || ',' || replace(avalues(aind),gch,rch);
      aflags.delete(aind);
    end if;
    aind := aflags.next(aind);
    exit when aind is null or not result is null;
  end loop;
  return result;
end grid_get;
--
function grid_get_col(avalues in constant.string_table, aflags in out nocopy constant.defstring_table,
 aind in out pls_integer, acol in pls_integer, agrid_char in varchar2 default null) return varchar2 as
gch varchar2(10) := nvl(agrid_char,GRID_CHAR);
result varchar2(32500);
j pls_integer;
tbl "CONSTANT".string_table;
begin
  j := nvl(aind,aflags.first);
  while not j is null loop
    if check_flag(aflags(j),acol) then
      tbl(j) := get_row_val(avalues(j),acol,gch);
    end if;
    j := aflags.next(j);
  end loop;
  j := null;
  result := get_string_list(tbl,j,constant.ESC,constant.NC);
  aind := j;
  if j is null then j := tbl.last; else j := tbl.prior(j); end if;
  while not j is null loop
    set_flag(aflags(j),acol,'0');
	if instr(aflags(j),'1') = 0 then aflags.delete(j); end if;
    j := tbl.prior(j);
  end loop;
  return result;
end grid_get_col;
--
procedure set_flag(aflags in out nocopy varchar2, aind in pls_integer, aaction in boolean default true) as
begin
  set_flag(aflags,aind,iif(aaction,'1','0'));
end set_flag;
--
procedure set_flag(aflags in out nocopy varchar2, aind in pls_integer, avalue in char) as
begin
  aflags := substr(aflags,1,aind - 1) || avalue || substr(aflags,aind + 1);
end set_flag;
--
function check_flag(aflags in varchar2, aind in pls_integer) return boolean as
begin
  return nvl(ascii(substr(aflags,aind,1)), ZERO) <> ZERO;
end check_flag;
--
function flags_or(aflags in constant.defstring_table, acount in pls_integer) return varchar2 as
result varchar2(128) := rpad('0',acount,'0');
i pls_integer;
begin
  for j in 1..acount loop
    i := aflags.first;
    while not i is null loop
      if aflags(i) not in ('I','D') and check_flag(aflags(i),j) then
        set_flag(result,j,'1');
        exit;
      end if;
      i := aflags.next(i);
    end loop;
  end loop;
  return result;
end flags_or;
--
function get_row_val(arow in varchar2, aind in pls_integer, achar in varchar2 default null) return varchar2 as
ci pls_integer := 0;
pi pls_integer;
c pls_integer := 0;
ch varchar2(10) := nvl(achar,GRID_CHAR);
begin
  loop
    pi := ci;
    ci := instr(arow,ch,ci + 1);
    if c = aind - 1 then
      if ci = 0 then
        return substr(arow,pi + 1);
      else
        return substr(arow,pi + 1,ci - pi - 1);
      end if;
    end if;
    if ci = 0 then return null; end if;
    c := c + 1;
  end loop;
end get_row_val;
--
procedure set_row_val(arow in out nocopy varchar2, aind in pls_integer, avalue in varchar2, achar in varchar2 default null) as
ci pls_integer := 0;
pi pls_integer;
c pls_integer := 0;
ch varchar2(10) := nvl(achar,GRID_CHAR);
begin
  loop
    pi := ci;
    ci := instr(arow,ch,ci + 1);
    if c = aind - 1 then
      if ci = 0 then
        arow := substr(arow,1,pi) || avalue;
      else
        arow := substr(arow,1,pi) || avalue || substr(arow,ci);
      end if;
      return;
    end if;
    if ci = 0 then return; end if;
    c := c + 1;
  end loop;
end set_row_val;
--
procedure check_vals(abuf in out nocopy varchar2, apar in varchar2, aflags in out nocopy varchar2,
  acol_count in pls_integer, adep_flags in out nocopy varchar2,
  acheck_flags in varchar2 default null,
  achar in varchar2 default null) as
ch varchar2(10) := nvl(achar,GRID_CHAR);
begin
  for i in 1..acol_count loop
    if acheck_flags is null or check_flag(acheck_flags,i) then
      if nvl(get_row_val(abuf,i,ch),constant.NC) <> nvl(get_row_val(apar,i,ch),constant.NC) then
        set_row_val(abuf,i,get_row_val(apar,i,ch),ch);
        set_flag(aflags,i,'1');
        set_flag(adep_flags,i,'1');
      else
        set_flag(adep_flags,i,check_flag(aflags,i));
        set_flag(aflags,i,'0');
      end if;
    end if;
  end loop;
end check_vals;
--
procedure sorting(p_idx   in out nocopy constant.integer_table,
                  p_vals  in constant.integer_table,
                  p_left  in pls_integer,
                  p_right in pls_integer) is
  I pls_integer;
  J pls_integer;
  x pls_integer;
  n pls_integer;
begin
  I := p_left;
  J := p_right;
  n := (i+j)/2;
  x := p_vals(p_idx(n));
  loop
    while x<p_vals(p_idx(j)) loop j:=j-1; end loop;
    while p_vals(p_idx(i))<x loop i:=i+1; end loop;
    if I<=J then
      n := p_idx(i);
      p_idx(i) := p_idx(j);
      p_idx(j) := n;
      i := i+1;
      j := j-1;
    end if;
    exit when I > J;
  end loop;
  if p_left<J  then Sorting(p_idx,p_vals,p_left,J);  end if;
  if I<p_right then Sorting(p_idx,p_vals,I,p_right); end if;
  /*for i in p_left..p_right-1 loop
    for ii in i+1..p_right loop
      if p_vals(p_idx(ii))<p_vals(p_idx(i)) then
        x := p_idx(i);
        p_idx(i) := p_idx(ii);
        p_idx(ii):= x;
      end if;
    end loop;
  end loop;*/
end;
--
procedure sorting(p_idx   in out nocopy constant.integer_table,
                  p_vals  in constant.number_table,
                  p_left  in pls_integer,
                  p_right in pls_integer) is
  I pls_integer;
  J pls_integer;
  x number;
  n pls_integer;
begin
  I := p_left;
  J := p_right;
  n := (i+j)/2;
  x := p_vals(p_idx(n));
  loop
    while x<p_vals(p_idx(j)) loop j:=j-1; end loop;
    while p_vals(p_idx(i))<x loop i:=i+1; end loop;
    if I<=J then
      n := p_idx(i);
      p_idx(i) := p_idx(j);
      p_idx(j) := n;
      i := i+1;
      j := j-1;
    end if;
    exit when I > J;
  end loop;
  if p_left<J  then Sorting(p_idx,p_vals,p_left,J);  end if;
  if I<p_right then Sorting(p_idx,p_vals,I,p_right); end if;
end;
--
procedure sorting(p_idx   in out nocopy constant.integer_table,
                  p_vals  in constant.refstring_table,
                  p_left  in pls_integer,
                  p_right in pls_integer) is
  I pls_integer;
  J pls_integer;
  x varchar2(128);
  n pls_integer;
begin
  I := p_left;
  J := p_right;
  n := (i+j)/2;
  x := p_vals(p_idx(n));
  loop
    while x<p_vals(p_idx(j)) loop j:=j-1; end loop;
    while p_vals(p_idx(i))<x loop i:=i+1; end loop;
    if I<=J then
      n := p_idx(i);
      p_idx(i) := p_idx(j);
      p_idx(j) := n;
      i := i+1;
      j := j-1;
    end if;
    exit when I > J;
  end loop;
  if p_left<J  then Sorting(p_idx,p_vals,p_left,J);  end if;
  if I<p_right then Sorting(p_idx,p_vals,I,p_right); end if;
end;
--
procedure sorting(p_idx   in out nocopy constant.integer_table,
                  p_vals  in constant.defstring_table,
                  p_left  in pls_integer,
                  p_right in pls_integer) is
  I pls_integer;
  J pls_integer;
  x varchar2(256);
  n pls_integer;
begin
  I := p_left;
  J := p_right;
  n := (i+j)/2;
  x := p_vals(p_idx(n));
  loop
    while x<p_vals(p_idx(j)) loop j:=j-1; end loop;
    while p_vals(p_idx(i))<x loop i:=i+1; end loop;
    if I<=J then
      n := p_idx(i);
      p_idx(i) := p_idx(j);
      p_idx(j) := n;
      i := i+1;
      j := j-1;
    end if;
    exit when I > J;
  end loop;
  if p_left<J  then Sorting(p_idx,p_vals,p_left,J);  end if;
  if I<p_right then Sorting(p_idx,p_vals,I,p_right); end if;
end;
--
procedure sorting(p_idx   in out nocopy constant.integer_table,
                  p_vals  in constant.string_table,
                  p_left  in pls_integer,
                  p_right in pls_integer) is
  I pls_integer;
  J pls_integer;
  x varchar2(32767);
  n pls_integer;
begin
  I := p_left;
  J := p_right;
  n := (i+j)/2;
  x := p_vals(p_idx(n));
  loop
    while x<p_vals(p_idx(j)) loop j:=j-1; end loop;
    while p_vals(p_idx(i))<x loop i:=i+1; end loop;
    if I<=J then
      n := p_idx(i);
      p_idx(i) := p_idx(j);
      p_idx(j) := n;
      i := i+1;
      j := j-1;
    end if;
    exit when I > J;
  end loop;
  if p_left<J  then Sorting(p_idx,p_vals,p_left,J);  end if;
  if I<p_right then Sorting(p_idx,p_vals,I,p_right); end if;
end;
--
procedure sorting(p_idx   in out nocopy constant.integer_table,
                  p_vals  in constant.date_table,
                  p_left  in pls_integer,
                  p_right in pls_integer) is
  I pls_integer;
  J pls_integer;
  x date;
  n pls_integer;
begin
  I := p_left;
  J := p_right;
  n := (i+j)/2;
  x := p_vals(p_idx(n));
  loop
    while x<p_vals(p_idx(j)) loop j:=j-1; end loop;
    while p_vals(p_idx(i))<x loop i:=i+1; end loop;
    if I<=J then
      n := p_idx(i);
      p_idx(i) := p_idx(j);
      p_idx(j) := n;
      i := i+1;
      j := j-1;
    end if;
    exit when I > J;
  end loop;
  if p_left<J  then Sorting(p_idx,p_vals,p_left,J);  end if;
  if I<p_right then Sorting(p_idx,p_vals,I,p_right); end if;
end;
--
function soft_replace(str  varchar2,
                      str1 varchar2 default null,
                      str2 varchar2 default null,
                      symb varchar2 default null) return varchar2 is
  i    pls_integer;
  pos  pls_integer;
  pos1 pls_integer := 1;
  len  pls_integer := length(str);
  len1 pls_integer := length(str1);
  s    varchar2(32767);
  ss   varchar2(32767);
  s1   varchar2(2000);
  chrs varchar2(256);
  chr0 varchar2(256);
  b    boolean;
begin
  if len=0  then return null; end if;
  if len1=0 then return str;  end if;
  s := upper(str);
  s1:= upper(str1);
  chrs := symb;
  if chrs is null then
    chrs := '"#$''0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_';
  end if;
  chr0 := rpad(CHAR0,length(chrs),CHAR0);
  loop
    pos:=instr(s,s1,pos1);
    if pos=0 then
      ss := ss||substr(str,pos1);
      exit;
    end if;
    i := pos+len1;
    if i<=len then
      b := translate(substr(s,i,1),chrs,chr0)=CHAR0;
    else
      b := false;
    end if;
    if b then
      ss := ss||substr(str,pos1,i-pos1);
    else
      if pos>1 then
        b := translate(substr(s,pos-1,1),chrs,chr0)=CHAR0;
      end if;
      if b then
        ss := ss||substr(str,pos1,i-pos1);
      else
        ss := ss||substr(str,pos1,pos-pos1)||str2;
      end if;
    end if;
    pos1 := i;
    exit when pos1>len;
  end loop;
  return ss;
exception
  when VALUE_ERROR then
    return str;
end;
--
procedure add_buf ( p_text in out nocopy constant.DEFSTRING_TABLE,
                    p_buf  in out nocopy constant.DEFSTRING_TABLE,
                    p_end  boolean default true,
                    p_del  boolean default false
                  ) is
    i pls_integer;
    j pls_integer;
begin
  if p_end then
    i := p_text.first;
    j := nvl(p_buf.last,0);
    while not i is null loop
      j := j+1;
      p_buf(j) := p_text(i);
      i := p_text.next(i);
    end loop;
  else
    i := p_text.last;
    j := nvl(p_buf.first,p_text.count+1);
    while not i is null loop
      j := j-1;
      p_buf(j) := p_text(i);
      i := p_text.prior(i);
    end loop;
  end if;
  if p_del then
    p_text.delete;
  end if;
end;
--
procedure put_buf ( p_text varchar2,
                    p_buf  in out nocopy constant.DEFSTRING_TABLE,
                    p_end  boolean default true
                  ) is
    len  pls_integer := nvl(length(p_text),0);
    len1 pls_integer;
    pos0 pls_integer;
    pos1 pls_integer;
    pos  pls_integer;
    inc  pls_integer;
begin
    if p_end then
        pos := nvl(p_buf.last,0);
        inc := 1;
    else
        pos := nvl(p_buf.first,0);
        inc := -1;
    end if;
    if len <= 256 then
        pos := pos+inc;
        p_buf(pos) := p_text;
		return;
	end if;
    pos0 := inc;
    loop
      pos1 := instr( p_text, NL, pos0 );
      if p_end then
        if pos1 = 0 or pos1>pos0+255 then
            len1 := 256;
            pos1 := pos0+255;
		else
            len1 := pos1-pos0+1;
		end if;
        pos := pos+1;
        p_buf(pos) := substr(p_text,pos0,len1);
        pos0 := pos1+1;
        exit when pos0>len;
      else
        if pos1 = 0 or pos1<len+pos0-254 then
            pos1 := len+pos0-254;
            if pos1<=0 then
                pos1 := 1;
            end if;
		end if;
        pos := pos-1;
        p_buf(pos) := substr(p_text,pos1,len+pos0-pos1+2);
        pos0 := pos1-len-2;
        exit when pos0<-len;
      end if;
	end loop;
end;
--
function get_buf ( p_text in out nocopy varchar2,
                   p_buf  in out nocopy constant.DEFSTRING_TABLE,
                   p_end  boolean default true,
                   p_del  boolean default false,
                   p_idx  pls_integer default null
                 ) return pls_integer is
  i pls_integer := p_idx;
begin
  if p_end then
    i := nvl(i,p_buf.first);
    while not i is null loop
      p_text := p_text||p_buf(i);
      i := p_buf.next(i);
    end loop;
  else
    i := nvl(i,p_buf.last);
    while not i is null loop
      p_text := p_buf(i)||p_text;
      i := p_buf.prior(i);
    end loop;
  end if;
  if p_del then
    p_buf.delete;
  end if;
  return i;
exception when value_error then
  if p_del and not i is null then
    if p_end then
      p_buf.delete(p_buf.first,i-1);
    else
      p_buf.delete(i+1,p_buf.last);
    end if;
  end if;
  return i;
end;
--
procedure replace_buf( p_buf  in out nocopy constant.DEFSTRING_TABLE,
                       p_search varchar2, p_replace varchar2 default null ) is
  i pls_integer := p_buf.first;
begin
  while not i is null loop
    p_buf(i) := replace(p_buf(i),p_search,p_replace);
    i := p_buf.next(i);
  end loop;
end;
--
procedure instr_buf( p_idx in out nocopy pls_integer, p_pos in out nocopy pls_integer,
                     p_buf constant.DEFSTRING_TABLE, p_search varchar2 ) is
  i pls_integer := p_buf.first;
  j pls_integer;
begin
  p_idx := null; p_pos := null;
  while not i is null loop
    j := instr(p_buf(i),p_search);
    if j>0 then
      p_idx := i;
      p_pos := j;
      exit;
    end if;
    i := p_buf.next(i);
  end loop;
end;
--
procedure add_buf ( p_text in out nocopy constant.STRING_TABLE,
                    p_buf  in out nocopy constant.STRING_TABLE,
                    p_end  boolean default true,
                    p_del  boolean default false
                  ) is
    i pls_integer;
    j pls_integer;
    l pls_integer;
begin
  if p_end then
    i := p_text.first;
    j := nvl(p_buf.last,0);
    while not i is null loop
      l := length(p_text(i));
      if l>0 then
        if p_buf.exists(j) and l+nvl(length(p_buf(j)),0)<=20000 then
          p_buf(j) := p_buf(j)||p_text(i);
        else
          j := j+1;
          p_buf(j) := p_text(i);
        end if;
      end if;
      i := p_text.next(i);
    end loop;
  else
    i := p_text.last;
    j := nvl(p_buf.first,p_text.count+1);
    while not i is null loop
        l := length(p_text(i));
        if l>0 then
          if p_buf.exists(j) and l+nvl(length(p_buf(j)),0)<=20000 then
            p_buf(j) := p_text(i)||p_buf(j);
          else
            j := j-1;
            p_buf(j) := p_text(i);
          end if;
        end if;
      i := p_text.prior(i);
    end loop;
  end if;
  if p_del then
    p_text.delete;
  end if;
end;
--
procedure put_buf( p_text varchar2,
                   p_buf  in out nocopy constant.STRING_TABLE,
                   p_end  boolean default true
                 ) is
  j pls_integer;
  l pls_integer;
begin
  l := length(p_text);
  if l>0 then
    if p_end then
      j := nvl(p_buf.last,0);
      if p_buf.exists(j) and l+nvl(length(p_buf(j)),0)<=20000 then
        p_buf(j) := p_buf(j)||p_text;
      elsif l<=20000 then
        j := j+1;
        p_buf(j) := p_text;
      else
        l := instr(p_text,NL,16000);
        if l=0 then
          l := 16000;
        end if;
        j := j+1;
        p_buf(j) := substr(p_text,1,l);
        j := j+1;
        p_buf(j) := substr(p_text,l+1);
      end if;
    else
      j := nvl(p_buf.first,1);
      if p_buf.exists(j) and l+nvl(length(p_buf(j)),0)<=20000 then
        p_buf(j) := p_text||p_buf(j);
      elsif l<=20000 then
        j := j-1;
        p_buf(j) := p_text;
      else
        l := instr(p_text,NL,16000);
        if l=0 then
          l := 16000;
        end if;
        j := j-1;
        p_buf(j) := substr(p_text,l+1);
        j := j-1;
        p_buf(j) := substr(p_text,1,l);
      end if;
    end if;
  end if;
end;
--
function get_buf ( p_text in out nocopy varchar2,
                   p_buf  in out nocopy constant.STRING_TABLE,
                   p_end  boolean default true,
                   p_del  boolean default false,
                   p_idx  pls_integer default null
                 ) return pls_integer is
  i pls_integer := p_idx;
begin
  if p_end then
    i := nvl(i,p_buf.first);
    while not i is null loop
      p_text := p_text||p_buf(i);
      i := p_buf.next(i);
    end loop;
  else
    i := nvl(i,p_buf.last);
    while not i is null loop
      p_text := p_buf(i)||p_text;
      i := p_buf.prior(i);
    end loop;
  end if;
  if p_del then
    p_buf.delete;
  end if;
  return i;
exception when value_error then
  if p_del and not i is null then
    if p_end then
      p_buf.delete(p_buf.first,i-1);
    else
      p_buf.delete(i+1,p_buf.last);
    end if;
  end if;
  return i;
end;
--
procedure replace_buf( p_buf  in out nocopy constant.STRING_TABLE,
                       p_search varchar2, p_replace varchar2 default null ) is
  i pls_integer := p_buf.first;
begin
  while not i is null loop
    p_buf(i) := replace(p_buf(i),p_search,p_replace);
    i := p_buf.next(i);
  end loop;
end;
--
procedure instr_buf( p_idx in out nocopy pls_integer, p_pos in out nocopy pls_integer,
                     p_buf constant.STRING_TABLE, p_search varchar2 ) is
  i pls_integer := p_buf.first;
  j pls_integer;
begin
  p_idx := null; p_pos := null;
  while not i is null loop
    j := instr(p_buf(i),p_search);
    if j>0 then
      p_idx := i;
      p_pos := j;
      exit;
    end if;
    i := p_buf.next(i);
  end loop;
end;
--
function  equal_buf(p_buf1 constant.DEFSTRING_TABLE,
                    p_buf2 constant.DEFSTRING_TABLE) return boolean is
    idx1 pls_integer;
    idx2 pls_integer;
    pos1 pls_integer;
    pos2 pls_integer;
    len1 pls_integer;
    len2 pls_integer;
    len  pls_integer;
    procedure next(p_buf constant.DEFSTRING_TABLE, idx in out nocopy pls_integer,
                   pos in out nocopy pls_integer, len in out nocopy pls_integer) is
    begin
        loop
            exit when pos <= len;
            if idx is null then
              idx := p_buf.first;
            else
              idx := p_buf.next(idx);
            end if;
            exit when idx is null;
            len := length(p_buf(idx));
            pos := 1;
        end loop;
    end;
begin
    loop
        next(p_buf1, idx1, pos1, len1);
        next(p_buf2, idx2, pos2, len2);
        exit when idx1 is null or idx2 is null;
        len := (len1 - pos1 + 1);
        if len > (len2 - pos2 + 1) then
            len := (len2 - pos2 + 1);
        end if;
        if substr(p_buf1(idx1), pos1, len) <> substr(p_buf2(idx2), pos2, len) then
            return false;
        end if;
        pos1 := pos1 + len;
        pos2 := pos2 + len;
    end loop;
    return (idx1 is null and idx2 is null);
end;
-------------------------------------------------------------------------------------------
-- @METAGS extract_property
function extract_property(p_string   in varchar2,
                          p_property in varchar2 default NULL
                         ) return varchar2 is
    v_property  varchar2(128);
    pos pls_integer;
    p1  pls_integer;
    p2  pls_integer;
begin
    v_property := trim(p_property);
    if v_property is null then
      return trim(p_string);
    elsif ascii(v_property)=asc_dlm then
      pos := 1;
      loop
        p1 := instr(p_string,v_property,pos);
        if p1>0 then
          p1 := p1+length(v_property);
          pos:= instr(p_string,DLM,p1);
          if p1=pos then
            return '1';
          end if;
          p2 := instr(p_string,' ',p1);
          if p2=p1 then
            if pos>0 then
              return nvl(substr(p_string,p2+1,pos-p2-1),'1');
            end if;
            return nvl(substr(p_string,p2+1),'1');
          end if;
          exit when pos=0;
        else
          exit;
        end if;
      end loop;
    else
      pos := instr(upper(p_string),DLM||upper(v_property)||' ');
      if pos>0 then
        p1 := pos+length(v_property)+2;
        p2 := instr(p_string,DLM,p1);
        if p2>0 then
          return substr(p_string,p1,p2-p1);
        end if;
        return substr(p_string,p1);
      end if;
    end if;
    return null;
end;
--
procedure put_property(p_string in out nocopy varchar2,
                       p_property  in varchar2 default null,
                       p_value  in varchar2 default null) is
    v_property  varchar2(128);
    pos pls_integer;
    i   pls_integer;
    j   pls_integer;
    put boolean;
    spc boolean;
begin
    v_property := trim(p_property);
    if v_property is null then
      if p_value=DLM then
        p_string := null;
      else
        p_string := p_value;
      end if;
      return;
    end if;
    if p_value is null then
      put := true;
    else
      put := p_value<>DLM;
    end if;
    if ascii(v_property)=asc_dlm then
      spc := not p_value is null;
    else
      spc := true;
      v_property := DLM||v_property;
    end if;
    pos := 1;
    loop
      pos := instr(upper(p_string),upper(v_property),pos);
      if pos>0 then
        i := pos+length(v_property);
        j := ascii(substr(p_string,i,1));
        if j is null then
          exit;
        elsif j=ascii(' ') then
          j := instr(p_string,DLM,i+1); exit;
        elsif j=asc_dlm then
          j := i; exit;
        else
          pos := i;
        end if;
      else
        exit;
      end if;
    end loop;
    if pos>0 then
        i := i-1;
        if j>0 then
            if put then
              if spc then
                p_string := substr(p_string,1,i)||' '||p_value||substr(p_string,j);
              else
                p_string := substr(p_string,1,i)||substr(p_string,j);
              end if;
            elsif pos>1 then
              p_string := substr(p_string,1,pos-1)||substr(p_string,j);
            else
              p_string := substr(p_string,j);
            end if;
        elsif put then
          if spc then
            p_string := substr(p_string,1,i)||' '||p_value||DLM;
          else
            p_string := substr(p_string,1,i)||DLM;
          end if;
        elsif pos>1 then
          p_string := substr(p_string,1,pos);
        else
          p_string := null;
        end if;
    elsif put then
      pos := length(p_string);
      if spc then
        if pos>0 and substr(p_string,pos,1)=DLM then
          p_string := substr(p_string,1,pos-1)||v_property||' '||p_value||DLM;
        else
          p_string := p_string||v_property||' '||p_value||DLM;
        end if;
      elsif pos>0 and substr(p_string,pos,1)=DLM then
        p_string := substr(p_string,1,pos-1)||v_property||DLM;
      else
        p_string := p_string||v_property||DLM;
      end if;
    end if;
end;
--
procedure remove_property(p_string in out nocopy varchar2,
                       p_property  in varchar2 default null) is
begin
  put_property(p_string, p_property, '|');
end;
--
function normalize_properties(p_prop in varchar2, p_skip varchar2 default null) return varchar2 is
    str varchar2(2000);
    s   varchar2(500);
    i   pls_integer;
    j   pls_integer;
    k   pls_integer;
    l   pls_integer;
    t   "CONSTANT".varchar2_table_s;--props_tbl_t;
begin
    if p_prop is null then return null; end if;
    i := 1;
    l := length(p_prop);
    loop
      j := instr(p_prop,DLM,i);
      if j=0 then j:=l+1; end if;
      if j>i then
        str := substr(p_prop,i,j-i);
        k := instr(str,' ');
        if k>1 then
          s := substr(str,1,k-1);
        else
          s := str;
        end if;
        if not t.exists(s) then
          t(s) := str;
        end if;
      end if;
      i := j+1;
      exit when i>l;
    end loop;
    if nvl(p_skip,'0') = '1' and t.exists('RTLBASE') then
      t.delete('RTLBASE');
    end if;
    str := DLM;
    if t.count > 0 then
      s := t.first;
      while s is not null loop
        str := str || t(s) || DLM;
        s := t.next(s);
      end loop;
    end if;
    return str;
end;
--
function get_ncharset return varchar2 is
begin
    if NCHARSET is null then
    	select value into NCHARSET from nls_database_parameters where parameter = 'NLS_NCHAR_CHARACTERSET';
    end if;
    return NCHARSET;
end;
--
function encode_national_string(national_string nvarchar2) return varchar2 is
begin
	if national_string is null then
		return null;
	end if;
	return utl_raw.cast_to_varchar2(utl_encode.base64_encode(utl_raw.cast_to_raw(convert(national_string, 'AL32UTF8', get_ncharset))));
end;
--
function decode_national_string(national_string varchar2) return nvarchar2 is
begin
	if national_string is null then
		return null;
	end if;
	return convert(utl_raw.cast_to_nvarchar2(utl_encode.base64_decode(utl_raw.cast_to_raw(national_string))), get_ncharset, 'AL32UTF8');
end;
--
function is_nvarchar_based(base_class varchar2) return boolean is
begin
	return (base_class like constant2.GENERIC_NSTRING or base_class like constant2.NMEMO);
end;
-------------------------------------------------------------------------------------------
end lib;
/
show errors package body lib
