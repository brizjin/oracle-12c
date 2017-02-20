prompt plp2plsql body
create or replace package body 
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/2plsql2.sql $
 *  $Author: petrushov $
 *  $Revision: 126198 $
 *  $Date:: 2016-10-31 11:06:44 #$
 */
plp2plsql is
--
/* $NoKeywords: $ */
--
    NL  constant varchar2(1) := chr(10);    -- new line
    SP  constant varchar2(1) := ' ';        -- space
    TAB constant varchar2(1) := chr(9);    -- tabulation
    TB2 constant varchar2(2) := TAB || TAB;
    TB3 constant varchar2(3) := TAB || TB2;
    TB4 constant varchar2(4) := TB2 || TB2;

--
    YESSTR constant varchar2(7) := ' = ''1'')';
    NOTSTR constant varchar2(7) := ' = ''0'')';
    TRUE_CONST  constant varchar2(5) := 'true';
    FALSE_CONST constant varchar2(5) := 'false';
    NULL_CONST  constant varchar2(5) := 'null';
    NULL_STMT   constant varchar2(5) := 'null;';
    NULL_STRING constant varchar2(5) := '''''';
--
    ASC_DIEZ    constant pls_integer := ascii('#');
    COL_FLAG    constant pls_integer := 1000000000;
    COL_FADD    constant pls_integer := 1002000000;
--
    C_DATA_VIEWS varchar2(16) := 'DATA$VIEWS$';
--
    SYS            varchar2(10) := 'SYSTEM'; -- system class
    new_this       varchar2(10) := plib.THIS;
    var_this       varchar2(10) := plib.var('var$');
    obj_this       varchar2(10) := plib.var('obj$');
    var_class      varchar2(10) := plib.var('CLASS');
    var_collect    varchar2(10) := plib.var('coll$');
    var_obj_class  varchar2(10) := plib.var('class$');
    var_obj_class$ varchar2(11) := plib.var('class$$');
    var_prefix     varchar2(10) := plib.var('prf$');
    var_ins        varchar2(10) := plib.var('this$');
    var_prt        varchar2(10) := plib.var('prt$');
    var_key        varchar2(10) := plib.var('key$');
    -- cache_processing
    var_get        varchar2(10) := plib.var('get$');
    var_old        varchar2(10) := plib.var('old$');
    var_id         varchar2(10) := plib.var('id$');
    -- this_ins
    var_chk        varchar2(10) := plib.var('chk$');
    var_stat       varchar2(10) := plib.var('st$');
    var_static     varchar2(10) := plib.var('stat$');
--
    obj_count      pls_integer := 0;
    get_count      pls_integer := 0;
    set_count      pls_integer := 0;
    this_table     varchar2(30);
    this_upd       boolean default FALSE;
    this_mtd       boolean default FALSE;
    this_chg       boolean default FALSE;
    this_get       boolean default FALSE;
--
    self_ref       varchar2(16) := 'number';
    self_interface varchar2(30);
    get_this       varchar2(100);
    set_this       varchar2(100);
    obj_select     varchar2(100);
    self_type      varchar2(100);
    this_part      varchar2(10);
    over_count     pls_integer;
    chg_count      pls_integer := 0;
    col_count      pls_integer := 0;
    col_cached     pls_integer := 0;
    col_attrs      pls_integer := 0;
    init_proc      pls_integer := 0;
    tmp_loop       pls_integer := 0;
    cnt_autonom    pls_integer := 0;
    idx_base_decl  pls_integer := 0;
    tmp_continue   boolean default FALSE;
    self_calc      boolean default TRUE;
    self_static    boolean default FALSE;
    self_cached    boolean default FALSE;
    self_attrs     boolean default FALSE;
    lock_this      boolean default FALSE;
    is_method      boolean default FALSE;
    is_validator   boolean default FALSE;
    is_base_func   boolean default FALSE;
    sos_method     boolean default FALSE;
    sosmethod      boolean default FALSE;
    chk_var        boolean default FALSE;
    cache_this     boolean default FALSE;
    cache_obj      boolean default FALSE;
    call_obj       boolean default FALSE;
    this_var       boolean default FALSE;
    this_obj       boolean default FALSE;
    this_add       boolean default FALSE;
    this_new       boolean default FALSE;
    this_ins       boolean default FALSE;
    this_del       boolean default FALSE;
    this_grp       boolean default FALSE;
    this_trig      boolean default FALSE;
    this_attr      boolean default FALSE;
    this_static    boolean default FALSE;
    this_kernel    boolean default FALSE;
    set_rules      boolean default FALSE;
    has_check      boolean default FALSE;
    has_src_id     boolean default FALSE;
    chk_call       boolean default FALSE;
    chk_return     boolean default FALSE;
    chk_sav        boolean default FALSE;
    sav_upd        boolean default FALSE;
    sav_mtd        boolean default FALSE;
    sav_chg        boolean default FALSE;
    global_cache   boolean default TRUE;
    cache_class    boolean default TRUE;
    chk_key        boolean;
    class_info     lib.class_info_t;
    method_info    lib.method_info_t;
    plsql_reserved plib.string_stbl_t;
    calc_rtl       plib.string_stbl_t;
    temp_vars      plib.string_rec_tbl_t;
    used_attrs     plib.string_rec_tbl_t;
    overlapped     plib.string_rec_tbl_t;
    counters       rtl.integer_table;
    dmp_counters   pls_integer;
    max_counters   pls_integer;
    stp_counters   pls_integer;
    dmp_pipe       varchar2(100);
    use_counters   boolean;
--
    tmp_vars     pls_integer := 0;
    query_idx    pls_integer := 1000;
    cursor_idx   pls_integer := 0;
    bRhtContext  boolean;
    bObjContext  boolean;
    bRefContext  boolean;
    bAddSysCols  boolean;
    bObjChkMode  boolean;
    use_context  boolean;
    use_java     boolean;
    skip_attrs   boolean := false;
    chk_class    boolean := false;
    cur_alias    varchar2(10) := 'a';
    cur_class    varchar2(100);
    cur_nested   varchar2(100);
    crit_hints   varchar2(2000);
    cur_pref     varchar2(30);
    table_info   lib.table_info_t;
    plpclass     plib.plp_class_t;
    crit_cols    "CONSTANT".MEMO_TABLE;
    sel_crit_tree select_crit_tree;
    type column_info_t is record (
        name             varchar2(64),
        target_class_id  varchar2(16),
        sizeable         varchar2(1),
        unvisible        varchar2(1),
        align            varchar2(1),
        orderby          pls_integer,
        width            pls_integer,
        data_precision   pls_integer);
--
    procedure exception2plsql ( p_idx  IN     pls_integer,
                                p_l    IN     pls_integer,
                                p_decl in out nocopy varchar2,
                                p_text in out nocopy plib.string_tbl_t,
                                t_idx  IN     pls_integer default NULL,
                                p_lock IN     boolean default TRUE
                              );
--
    procedure sos2plsql ( p_idx  IN     pls_integer,
                          p_l    IN     pls_integer,
                          p_decl in out nocopy varchar2,
                          p_text in out nocopy plib.string_tbl_t,
                          t_idx  IN     pls_integer default NULL,
                          p_lock IN     boolean default TRUE
                        );
    procedure declare2plsql ( p_idx   IN     pls_integer,
                              p_l     IN     pls_integer,
                              p_decl  in out nocopy plib.string_tbl_t,
                              p_block IN     pls_integer default DECLARE_FORMAT_VARS,
                              p_typed IN     boolean default TRUE,
                              p_pack  IN     boolean default FALSE,
                              p_null  IN     boolean default FALSE
                            );
--
  function  locate2plsql ( p_idx  IN     pls_integer,
                           p_l    IN     pls_integer,
                           p_decl in out nocopy varchar2,
                           p_text in out nocopy varchar2
                         ) return varchar2;
  procedure cursor2plsql ( p_idx  IN pls_integer,
                           p_l    IN pls_integer,
                           p_decl in out nocopy varchar2,
                           p_text in out nocopy varchar2
                         );
--
function get_ref_class(p_idx pls_integer) return varchar2 is
  v_cls plib.plp_class_t;
  typ pls_integer;
begin
  typ := plib.ir(p_idx).type;
  if typ = plp$parser.OBJECT_REF_ then
    v_cls.class_id := plib.ir(p_idx).text1;
    if v_cls.class_id is null then
      v_cls.class_id := plib.ir(p_idx).text;
    end if;
    return v_cls.class_id;
  elsif typ = plp$parser.LOCK_REF_ then
    return null;
  end if;
  plib.expr_class (p_idx,v_cls);
  if v_cls.is_reference then
    return v_cls.class_id;
  end if;
  return null;
end;
--
function is_variable(p_idx pls_integer) return boolean is
  typ pls_integer;
  i pls_integer;
  j pls_integer;
  l pls_integer;
  b boolean;
begin
  if plib.ir(p_idx).text is null then -- var header
    typ := plib.ir(p_idx).type;
    b := typ = plp$parser.ID_;
    if b or typ = plp$parser.ATTR_ then
      l := p_idx;
      i := plib.ir(l).down;
      while i is not null loop
        typ := plib.ir(i).type;
        j := plib.ir(i).right;
        if typ = plp$parser.ID_ then
          if plib.ir(i).node in (1,4,5) then
            b := false;
          else
            if plib.ir(i).down is not null then
              b := null;
            elsif not b then
              b := true;
            end if;
            if j is null and l <> p_idx then
              if plib.ir(i).text in ('FIRST','LAST','COUNT') then
                b := null;
              end if;
            end if;
          end if;
        elsif typ in (plp$parser.ATTR_,plp$parser.TEXT_) then
          if plib.ir(i).down is not null then
            b := false;
          end if;
        elsif typ = plp$parser.VARMETH_ then
          if plib.ir(i).type1 < 0 or plib.ir(i).einfo < -10 then
            if plib.ir(i).down is not null then
              b := null;
            elsif not b then
              b := true;
            end if;
          else
            b := false;
          end if;
        elsif typ = plp$parser.MODIFIER_ then
          if plib.ir(i).down is null then
            typ := plib.ir(i).type1;
            if typ = plp$parser.OBJ_ID_ then
              null;
            elsif typ in (plp$parser.OBJ_CLASS_,plp$parser.OBJ_STATE_,plp$parser.OBJ_COLLECTION_) then
              if get_ref_class(plib.ir(i).left) is not null then
                b := false;
              end if;
            else
              b := false;
            end if;
          else
            b := false;
          end if;
        else
          b := false;
        end if;
        exit when not b;
        l := i;
        i := j;
      end loop;
      return b;
    elsif typ = plp$parser.VARMETH_ then
      typ := plib.last_child(p_idx);
      if plib.ir(typ).type = plp$parser.VARMETH_ and ( plib.ir(typ).type1 < 0 or plib.ir(typ).einfo < -10 ) then
        return true;
      end if;
    end if;
  end if;
  return false;
end;
--
function rtl_calc(p_func varchar2) return boolean is
begin
  return calc_rtl.exists(p_func);
end;
--
procedure inc_counter(p_typ pls_integer) is
begin
  if counters.exists(p_typ) then
    counters(p_typ) := counters(p_typ)+1;
  else
    counters(p_typ) := 1;
  end if;
end;
--
procedure init_counters(p_calls pls_integer default null,p_pipe varchar2 default null) is
begin
  dmp_counters := 0;
  counters.delete;
  if p_calls is null then
    max_counters := sys_context(inst_info.owner||'_USER','PLP_MAX_COUNTERS');
  else
    max_counters := p_calls;
    executor.set_context('PLP_MAX_COUNTERS',p_calls);
  end if;
  if p_pipe is null then
    dmp_pipe := sys_context(inst_info.owner||'_USER','PLP_DUMP_PIPE');
  else
    dmp_pipe := p_pipe;
    executor.set_context('PLP_DUMP_PIPE',p_pipe);
  end if;
  if max_counters>0 then
    use_counters := true;
    stp_counters := trunc((max_counters-1)/10)+1;
  else
    use_counters := false;
    max_counters := 0;
    stp_counters := 0;
  end if;
end;
--
procedure dump_counters(p_reset boolean default true) is
  i pls_integer;
  j pls_integer;
  typ pls_integer;
  pfx varchar2(10);
begin
  stdio.put_line_pipe('>>> '||plib.g_method_pack||': '||plib.plp$errors,dmp_pipe,0);
  dmp_counters := dmp_counters+1;
  if p_reset or (dmp_counters mod stp_counters)=0 then
    i := counters.first;
    j := 0;
    while not i is null loop
      if i < 0 then
        typ := -i;
      elsif i < 1000 then
        typ := i;
        if j = 0 then
          j := 1;
          pfx := 'EXPR ';
        end if;
      elsif i < 2000 then
        typ := i-1000;
        if j = 1 then
          j := 2;
          pfx := 'DECL ';
        end if;
      elsif i<3000 then
        typ := i-2000;
        if j = 2 then
          j := 3;
          pfx := 'STMT ';
        end if;
      elsif i<4000 then
        typ := i-3000;
        if j = 3 then
          j := 4;
          pfx := 'SQL  ';
        end if;
      else
        typ := i-4000;
        if j = 4 then
          j := 5;
          pfx := 'SMTH ';
        end if;
      end if;
      stdio.put_line_pipe(pfx||plib.type_name(typ)||': '||counters(i),dmp_pipe,0);
      i := counters.next(i);
    end loop;
    if p_reset or dmp_counters>=max_counters then
      dmp_counters := 0;
      counters.delete;
    end if;
  end if;
end;
--
-- @METAGS class2plsql
function class2plsql ( p_class IN varchar2,
                       p_prec  IN boolean default TRUE,
                       p_idx   IN pls_integer default null,
                       p_row   IN boolean default FALSE
                     ) return varchar2 is
    prec       varchar2(100);
    interface  varchar2(100);
    pos           pls_integer;
begin
  if lib.class_exist( p_class, class_info ) then
    if p_row then
      if class_info.has_type then
        return inst_info.gowner||'.'||class_mgr.make_otype_name(p_class);
      end if;
      return class_mgr.interface_package(p_class)||'.'||class_mgr.make_class_rowname(p_class);
    elsif class_info.base_id=constant.GENERIC_TABLE then
      return inst_info.gowner||'.'||class_mgr.make_otype_table(class_info.class_ref);
    end if;
    interface := class_info.interface;
    if interface is NULL then
        interface := 'varchar2';
        plib.plp_error(p_idx, 'NO_INTERFACE', p_class);
    end if;
    pos := instr(interface,'|');
    if not p_prec then
        if pos > 0 then
            interface := substr(interface,pos + 1);
        end if;
        return interface;
    end if;
    if pos > 0 then
        interface := substr(interface,1,pos - 1);
    end if;
    if class_info.base_id in (constant.REFERENCE,constant.OLE,constant.COLLECTION) then
        if not class_info.data_size is NULL then
          if class_info.data_size between 1 and 32767 then
            prec := '('||to_char(class_info.data_size)||')';
          else
            prec := STR_PREC;
          end if;
        end if;
    elsif class_info.base_id in (constant.GENERIC_STRING,constant.GENERIC_NULL) then
        if class_info.data_size between 1 and 32767 then
            prec := '('||to_char(class_info.data_size)||')';
        else
            prec := STR_PREC;
        end if;
    elsif class_info.base_id = constant2.GENERIC_NSTRING then
        if class_info.data_size between 1 and 16383 then
            prec := '('||to_char(class_info.data_size)||')';
        else
            prec := NSTR_PREC;
        end if;
    elsif class_info.base_id = constant.MEMO then
        if class_info.data_size between 1 and 32767 then
            prec := '('||to_char(class_info.data_size)||')';
        else
            prec := MEMO_PREC;
        end if;
    elsif class_info.base_id = constant2.NMEMO then
        if class_info.data_size between 1 and 16383 then
            prec := '('||to_char(class_info.data_size)||')';
        else
            prec := NMEMO_PREC;
        end if;
    elsif class_info.base_id = constant.GENERIC_NUMBER and not class_info.kernel then
        if class_info.data_size between 1 and 38 then
            prec := '('||to_char(class_info.data_size);
        end if;
        if class_info.data_precision between -84 and 127 then
            prec := nvl(prec,'(38')||','||to_char(class_info.data_precision);
        end if;
        if not prec is null then
            prec := prec||')';
        end if;
    else
        prec := NULL;
    end if;
  else
    interface := 'varchar2';
    plib.plp_error(p_idx, 'NO_INTERFACE', p_class);
    if p_prec then
        prec := STR_PREC;
    end if;
  end if;
  return interface||prec;
end class2plsql;
--
function ref_string(p_kernel boolean,p_prec boolean, p_rowid boolean) return varchar2 is
begin
  if p_rowid then
    return 'rowid';
  elsif p_kernel then
    if p_prec then
      return 'varchar2'||REF_PREC;
    else
      return 'varchar2';
    end if;
  end if;
  return 'number';
end;
-- @METAGS plsql_type
function plsql_type ( p_idx  IN pls_integer,
                      p_prec IN boolean default TRUE,
                      p_type IN boolean default TRUE,
                      p_null IN boolean default FALSE,
                      p_chk  IN boolean default FALSE
                    ) return varchar2 is
    v_type  boolean := p_type;
    v_null  boolean := p_null;
    idx pls_integer := p_idx;
    ii  pls_integer;
    typ pls_integer;
    str varchar2(20000);
    txt varchar2(2000);
begin
    if v_type then
        ii := plib.ir(p_idx).down;
    end if;
    typ := plib.ir(idx).type;
<<retry>>
    str := plib.ir(idx).text;
    if typ = plp$parser.STRING_ then
        if not v_type and plib.ir(idx).type1 = -plp$parser.CONCAT_ then
            str := class2plsql( 'CLOB', p_prec, idx );
        elsif p_prec then
            if v_type then
                if str is NULL then
                    str := STR_PREC;
                else
                    str := '('||str||')';
                end if;
            else
                str := MEMO_PREC;
            end if;
            str:='varchar2'||str;
        else
            str:='varchar2';
        end if;
    elsif typ = plp$parser.NSTRING_ then
        if not v_type and plib.ir(idx).type1 = -plp$parser.CONCAT_ then
            str := class2plsql( 'NCLOB', p_prec, idx );
        elsif p_prec then
            if v_type then
                if str is NULL then
                    str := NSTR_PREC;
                else
                    str := '('||str||')';
                end if;
            else
                str := NMEMO_PREC;
            end if;
            str:='nvarchar2'||str;
        else
            str:='nvarchar2';
        end if;
    elsif typ = plp$parser.NUMBER_ then
        if v_type then
          if p_prec and not str is NULL then
            if not plib.ir(idx).text1 is NULL then
                str := str||','||plib.ir(idx).text1;
            end if;
            str := 'number('||str||')';
          else
            str := 'number';
          end if;
        elsif plib.ir(idx).type1 = plp$parser.CONSTANT_ then
          str := plib.num_const_type(str);
          if str = constant.GENERIC_INTEGER then
            str := 'pls_integer';
          else
            str := lower(str);
          end if;
        else
            str := 'number';
        end if;
    elsif typ = plp$parser.INTEGER_ then
        str := 'pls_integer';
    elsif typ = plp$parser.DATE_ then
        str := 'date';
    elsif typ = plp$parser.TIMESTAMP_ then
        if p_prec then
            if str is null then
                str := 'timestamp';
            else
                str := 'timestamp(' || str || ')';
            end if;
            if    plib.ir(idx).text1 = '1' then
                str := str || ' with time zone';
            elsif plib.ir(idx).text1 = '2' then
                str := str || ' with local time zone';
            end if;
        else
            if    plib.ir(idx).text1 = '1' then
                str := 'timestamp_tz_unconstrained';
            elsif plib.ir(idx).text1 = '2' then
                str := 'timestamp_ltz_unconstrained';
            else
                str := 'timestamp_unconstrained';
            end if;
        end if;
    elsif typ = plp$parser.INTERVAL_ then
        if p_prec then
            if str is null then
                str := 'interval day to second';
            elsif plib.ir(idx).text1 is null then
                str := 'interval year(' || str || ') to month';
            else
                str := 'interval day(' || str || ') to second(' || plib.ir(idx).text1 || ')';
            end if;
        elsif str is not null and plib.ir(idx).text1 is null then
            str := 'yminterval_unconstrained';
        else
            str := 'dsinterval_unconstrained';
        end if;
    elsif typ = plp$parser.BOOLEAN_ then
        str := 'boolean';
    elsif typ = plp$parser.EXCEPTION_ then
        str := 'exception';
        v_null := FALSE;
    elsif typ = plp$parser.RAW_ then
        str := lower(str);
        if p_prec and not plib.ir(idx).text1 is null then
            str := str||'('||plib.ir(idx).text1||')';
        end if;
    elsif typ = plp$parser.REF_ then
      if plib.ir(idx).left is not null and plib.ir(plib.ir(idx).left).text = plib.THIS then
      -- параметр THIS секции VALIDATE/EXECUTE для простых операций не может быть типа rowid (может использоваться для хранения collection_id)
        str := ref_string(plib.ir(idx).type1=1,p_prec, false);
      else
        str := ref_string(plib.ir(idx).type1=1,p_prec, lib.pk_is_rowid(plib.ir(idx).text));
      end if;
    elsif typ = plp$parser.DBOBJECT_ then
        txt := plib.ir(idx).text1;
        if txt in (constant.COLLECTION,'%collection') then
          str := 'number';
        elsif txt='%rowtable' then
          str := class_mgr.interface_package(str)||'.'||class_mgr.make_record_tables(str);
        else
          str := class2plsql( str, p_prec, idx, txt='%rowtype' );
        end if;
    elsif typ = plp$parser.TYPE_ then
        str := plib.ir(idx).text1;
        if str is null then
          str := plib.get_new_name(idx);
        end if;
        if plib.ir(idx).node = 0 and plib.ir(idx).type1 is null or str = '<TMP>' then
            idx := plib.ir(idx).down;
            typ := plib.ir(idx).type;
            goto retry;
        elsif plib.ir(idx).type1=plp$parser.SELECT_ then
            str := str||'%rowtype';
        elsif instr(str,'CONSTANT.')=1 then
            str := '"CONSTANT"'||substr(str,9);
        end if;
        if idx = p_idx then
            v_type := false;
        else
            v_null := false;
        end if;
    elsif typ = plp$parser.ID_ then
        idx := plib.ir(idx).type1;
        if not idx is null then
            v_type := TRUE;
            typ := plib.ir(idx).type;
            goto retry;
        end if;
    elsif typ = plp$parser.ATTR_ then
        typ := plib.ir(idx).type1;
        str := plib.ir(idx).text1;
        if typ=plp$parser.REF_ then
        -- Не может быть реквизитов-ссылок на тип с идентификацией по rowid
          str := ref_string(lib.has_stringkey(lib.class_target(str)),p_prec, false);
        elsif typ = -plp$parser.REF_ then
          str := ref_string(lib.has_stringkey(str),p_prec, lib.pk_is_rowid(str));
        elsif typ=plp$parser.OBJ_COLLECTION_ then
        -- значение реквизита-коллекции всегда число
          str := ref_string(false,p_prec, false);
        else
          str := class2plsql( str, p_prec, idx, typ = plp$parser.TYPE_ );
        end if;
    elsif typ in (plp$parser.VARMETH_,plp$parser.RTL_) then
        typ := abs(plib.ir(idx).type1);
        str := plib.ir(idx).text1;
        if str is null then
            if typ>10 then
                idx := typ;
                typ := plib.ir(idx).type;
                v_type := TRUE;
                goto retry;
            end if;
        elsif typ=plp$parser.REF_ then
            str := ref_string(lib.has_stringkey(str),p_prec, lib.pk_is_rowid(str));
        elsif typ=plp$parser.OBJ_COLLECTION_ then
            str := ref_string(false,p_prec, false);
        elsif typ = plp$parser.OBJ_TYPE_ then
            str := class_mgr.interface_package(str)||'.'||class_mgr.make_record_tables(str);
        else
            str := class2plsql( str, p_prec, idx, typ = plp$parser.TYPE_ );
        end if;
    elsif typ = plp$parser.METHOD_ then
        typ := plib.ir(idx).type1;
        if typ is null then
            str := null;
        else
          lib.desc_method( plib.ir(idx).text1, method_info );
          if typ=-plp$parser.REF_ then
            str := ref_string(lib.has_stringkey(method_info.result_id),p_prec, lib.pk_is_rowid(method_info.result_id));
          elsif typ=plp$parser.REF_ then
            if instr(method_info.flags,constant.METHOD_NEW) != 0 then
              str := ref_string(lib.has_stringkey(method_info.result_id),p_prec, lib.pk_is_rowid(method_info.result_id));
            else
              str := ref_string(lib.has_stringkey(method_info.class_ref),p_prec, lib.pk_is_rowid(method_info.class_ref));
            end if;
          else
            str := class2plsql( method_info.result_id, p_prec, idx );
          end if;
        end if;
    elsif typ = plp$parser.DBCLASS_ then
        str := ref_string(lib.has_stringkey(str),p_prec, lib.pk_is_rowid(str));
    elsif typ = plp$parser.NULL_ then
        str := 'varchar2';
        if p_prec then
            str := str||STR_PREC;
        end if;
    elsif typ = plp$parser.PRIOR_ then
        idx := plib.ir(idx).down;
        typ := plib.ir(idx).type;
        if typ=plp$parser.DBCLASS_ then
            typ := plp$parser.DBOBJECT_;
        end if;
        goto retry;
    elsif typ = plp$parser.UNION_ then
        idx := plib.ir(idx).down;
        typ := plib.ir(idx).type;
        goto retry;
    elsif typ = plp$parser.MODIFIER_ then
        typ := plib.ir(idx).type1;
        str := plib.ir(idx).text1;
        if str is null then
          null;
        elsif typ in (plp$parser.OBJ_PARENT_,plp$parser.OBJECT_REF_,plp$parser.INSERT_,plp$parser.LOCATE_) then
          str := ref_string(lib.has_stringkey(str),p_prec, lib.pk_is_rowid(str));
        elsif typ=plp$parser.OBJ_COLLECTION_ then
          str := ref_string(false,p_prec, false);
        elsif typ in (plp$parser.OBJ_INIT_,plp$parser.RTL_,plp$parser.DELETE_,plp$parser.LOCK_,plp$parser.VAR_) then
          str := null;
        elsif typ in (plp$parser.ID_,plp$parser.IS_) then
          idx := str;
          typ := plib.ir(idx).type;
          v_type := TRUE;
          goto retry;
        else
          str := class2plsql( str, p_prec, idx, typ = plp$parser.TYPE_ );
        end if;
    elsif typ in (plp$parser.INVALID_,plp$parser.UNKNOWN_) then
        str := null;
    else
        plib.plp_error(p_idx, 'IR_UNEXPECTED', 'plsql_type', plib.type_name(typ),p_idx);
        str := null;
    end if;
    if v_type then
      if not ii is null then
        declare
            edecl   varchar2(2000);
            etext   varchar2(20000);
            b       boolean;
        begin
            tmp_expr_idx := null;
            b := expr2plsql(ii,edecl,txt,etext);
            str := str||' := '||etext;
            if not (txt is null and edecl is null) then
              if p_chk and etext=lasttmp and txt='Clear$'||etext||';'||NL then
                edecl := substr(edecl,1,instr(edecl,'procedure Clear$')-1);
                if not edecl is null then
                  str := str||'<$NULL$>'||edecl;
                end if;
              else
                plib.plp_error(ii,'BAD_DEFAULT_EXPR');
              end if;
            end if;
        end;
      elsif instr(str,'.')>0 then
        if p_prec and str like inst_info.gowner||'.Z#%#TYPE' then
          ii := plib.parent(p_idx);
          if ii is not null and plib.ir(ii).type=plp$parser.ID_ then
            str := str||' := '||str||'()';
          end if;
        end if;
      elsif v_null then
        str := str||' := null';
      end if;
    end if;
    return str;
end plsql_type;
--
function plp_class( class  plib.plp_class_t,
                    p_prec boolean
                  ) return varchar2 is
  str varchar2(2000);
  idx pls_integer;
begin
  if class.is_udt then
    idx := class.class_id;
    return plsql_type(idx,p_prec,true,false,false);
  elsif class.is_reference then
    return ref_string(class.kernel,p_prec, lib.pk_is_rowid(class.class_id));
  elsif class.base_type=plp$parser.ONE_ and class.data_precision=-1000 then
    str := lower(class.class_id);
    if p_prec and not class.data_size is null then
        str := str||'('||class.data_size||')';
    end if;
  elsif not class.class_id is null then
    if class.base_type in (plp$parser.COLLECTION_,plp$parser.OBJ_COLLECTION_) then
      str := 'number';
    elsif class.base_type = plp$parser.OBJ_TYPE_ then
      str := class_mgr.interface_package(class.class_id)||'.'||class_mgr.make_record_tables(class.class_id);
    else
      str := class2plsql(class.class_id,p_prec,null,class.base_type=plp$parser.TYPE_ );
    end if;
  elsif class.base_type = plp$parser.STRING_ then
    str:='varchar2';
    if p_prec then
      if class.data_size is null then
        str := str||STR_PREC;
      else
        str := str||'('||class.data_size||')';
      end if;
    end if;
  elsif class.base_type = plp$parser.NUMBER_ then
    str := 'number';
    if p_prec and not class.data_size is null then
      str := str||'('||class.data_size;
      if class.data_precision is null then
        str := str||')';
      else
        str := str||','||class.data_precision||')';
      end if;
    end if;
  elsif class.base_type = plp$parser.INTEGER_ then
    str := 'pls_integer';
  elsif class.base_type = plp$parser.DATE_ then
    str := 'date';
  elsif class.base_type = plp$parser.MEMO_ then
    str:='varchar2';
    if p_prec then
      if class.data_size is null then
        str := str||MEMO_PREC;
      else
        str := str||'('||class.data_size||')';
      end if;
    end if;
  elsif class.base_type = plp$parser.TIMESTAMP_ then
    if p_prec then
      if class.data_size is null then
        str := 'timestamp';
      else
        str := 'timestamp(' || class.data_size || ')';
      end if;
      if class.data_precision = 1 then
        str := str || ' with time zone';
      elsif class.data_precision = 2 then
        str := str || ' with local time zone';
      end if;
    elsif class.data_precision = 1 then
      str := 'timestamp_tz_unconstrained';
    elsif class.data_precision = 2 then
      str := 'timestamp_ltz_unconstrained';
    else
      str := 'timestamp_unconstrained';
    end if;
  elsif class.base_type = plp$parser.INTERVAL_ then
    if p_prec then
      if class.data_size is null then
        str := 'interval day to second';
      elsif class.data_precision is null then
        str := 'interval year(' || class.data_size || ') to month';
      else
        str := 'interval day(' || class.data_size || ') to second(' || class.data_precision || ')';
      end if;
    elsif class.data_size is not null and class.data_precision is null then
      str := 'yminterval_unconstrained';
    else
      str := 'dsinterval_unconstrained';
    end if;
  elsif class.base_type = plp$parser.BOOLEAN_ then
    str := 'boolean';
  elsif class.base_type = plp$parser.EXCEPTION_ then
    str := 'exception';
  end if;
  return str;
end;
--
-- @METAGS put_set_this
procedure put_set_this(p_text in out nocopy varchar2, p_mgn varchar2 default null) is
begin
    p_text := p_text||p_mgn||set_this;
    set_count:= set_count + 1;
    lock_this:= true;
    this_upd := false;
end;
--
-- @METAGS put_get_this
procedure put_get_this(p_text in out nocopy varchar2, p_mgn varchar2 default null) is
begin
    p_text := p_text||p_mgn||get_this||NL;
    get_count:= get_count + 1;
    this_mtd := false;
    if call_obj then
      this_chg := false;
    end if;
end;
--
-- @METAGS tmpvar
function tmpvar ( p_decl pls_integer,
                  p_name varchar2 default NULL,
                  p_text varchar2 default NULL,
                  p_type pls_integer default NULL
                ) return boolean is
    v_text  varchar2(2000) := upper(p_text);
    v_type  pls_integer;
begin
    if p_decl < 0 then
      last_idx := null;
      v_type := 0;
    elsif p_type < 0 then
      v_type := 0;
      last_idx := plib.find_record(temp_vars,v_text,p_decl,null,null,0);
    else
      v_type := nvl(p_type,0);
      last_idx := plib.find_record(temp_vars,v_text,p_decl,v_type,null,0);
    end if;
    if last_idx is NULL then
        last_idx:= temp_vars.last;
        if last_idx > 0  then
          last_idx := last_idx + 1;
        else
          last_idx := 1;
        end if;
        lasttmp := plib.var(p_name||'_'||last_idx);
        temp_vars(last_idx).text1:=v_text;
        temp_vars(last_idx).text2:=p_decl;
        temp_vars(last_idx).text3:=v_type;
        temp_vars(last_idx).text4:=lasttmp;
        return TRUE;
    else
        lasttmp:=temp_vars(last_idx).text4;
        return FALSE;
    end if;
end tmpvar;
-- @METAGS tmpvaredit
procedure tmpvaredit ( p_idx pls_integer,
                       p_name varchar2,
                       p_text varchar2 default NULL,
                       p_type pls_integer default NULL
                       ) is
begin
      temp_vars(p_idx).text1:=upper(p_text);
   temp_vars(p_idx).text4:=p_name;
   if not p_type is null then
      temp_vars(p_idx).text3:=p_type;
   end if;
end tmpvaredit;
--
function get_tmpvar ( p_idx pls_integer ) return varchar2 is
begin
  if temp_vars.exists(p_idx) then
    return temp_vars(p_idx).text4;
  end if;
  return null;
end;
--
procedure set_const_var ( p_const varchar2, p_idx in out nocopy pls_integer ) is
begin
  if p_idx is not null then
    temp_vars.delete(p_idx);
  end if;
  p_idx := temp_vars.first;
  if p_idx < 0  then
    p_idx := p_idx - 1;
  else
    p_idx := -1;
  end if;
  temp_vars(p_idx).text4 := p_const;
end;
--
-- @METAGS insert2plsql
function  insert2plsql(p_idx  IN pls_integer,
                       mgn    IN varchar2,
                       p_decl in out nocopy varchar2,
                       p_text in out nocopy varchar2
                      ) return varchar2 is
    v_var  pls_integer;
    v_set  pls_integer;
    v_mode pls_integer;
    v_idx  pls_integer;
    eprog  varchar2(32767);
    etext  varchar2(32767);
    etext1 varchar2(32767);
    var_id varchar2(100);
    v_cls  varchar2(100);
    v_cls1 varchar2(100);
    b      boolean;
begin
    v_var := plib.ir(p_idx).down;
    v_set := plib.ir(v_var).right;
    v_mode:= plib.ir(p_idx).node;
    v_cls := plib.ir(p_idx).text1;
    v_cls1:= plib.ir(p_idx).text;
    db_update := true;
    -- только copy (v_mode = 1) может возвращать ссылку, остальные возвращают pls_integer
    var_id := ref_string(lib.has_stringkey(v_cls),true,(v_mode=1 and lib.pk_is_rowid(v_cls)));
    if tmpvar(tmp_sos_idx,'ID',var_id,tmp_expr_idx) then
        p_decl := mgn||lasttmp||TAB||var_id||';'||NL||p_decl;
    end if;
    tmp_expr_idx := nvl(tmp_expr_idx,0) + 1;
    var_id:= lasttmp;
    v_idx := last_idx;
    b := var2plsql( v_var, p_decl, eprog, etext, null, mgn);
    p_text:= p_text||eprog;
    eprog := NULL;
    if plib.ir(v_set).type = plp$parser.DBCLASS_ then
        etext1 := 'NULL';
    else
        b := var2plsql ( v_set, p_decl, eprog, etext1, null, mgn );   -- collection/class
    end if;
    if v_mode=0 then
      p_text := p_text||mgn||var_ID||' := '||etext||';'
             || case when eprog is null then TAB else NL||eprog||mgn end
             || class_mgr.interface_package(v_cls)||'.set_collection('
             || var_ID||','||etext1||');'||NL;
    else
      if v_mode=1 then
        if v_cls<>v_cls1 then
            etext := class_mgr.interface_package(v_cls1)||'.copy('||etext||', NULL)';
        end if;
        if not eprog is NULL then
            v_cls1 := class2plsql(v_cls,true,v_set);
            if tmpvar(tmp_sos_idx,'INSERT',v_cls1,tmp_expr_idx) then
                p_decl := mgn||lasttmp||TAB||v_cls1||';'||NL||p_decl;
            end if;
            tmp_expr_idx := tmp_expr_idx + 1;
            p_text:= p_text||mgn||lasttmp||' := '||etext||';'||NL||eprog;
            etext := lasttmp;
        end if;
        v_cls1 := '.copy(';
      elsif v_mode=2 then
        v_cls1 := '.copy$rectbl(';
      elsif v_mode=3 then
        v_cls1 := '.copy$tbl(';
      else
        v_cls1 := '.set_col$tbl(';
      end if;
      etext := mgn||var_ID||' := '||class_mgr.interface_package(v_cls)
            ||v_cls1||etext||','||etext1;
      v_var := plib.ir(v_set).right;
      while not v_var is null loop
        b := expr2plsql ( v_var, p_decl, eprog, etext1, mgn );
        p_text:= p_text||eprog;
        etext := etext||','||etext1;
        v_var := plib.ir(v_var).right;
      end loop;
      p_text := p_text||etext||');'||NL;
    end if;
    return var_id||':'||v_idx;
end insert2plsql;
--
function  dbclass2plsql ( p_class  varchar2,
                          p_kernel boolean,
                          p_mgn    varchar2,
                          p_idx    pls_integer,
                          p_all    pls_integer,
                          objid    in out nocopy varchar2,
                          edecl    in out nocopy varchar2,
                          etext    in out nocopy varchar2,
                          tmpprog  in out nocopy varchar2,
                          tmpidx   in out nocopy pls_integer
                        ) return boolean is
    retry     boolean := not plib.g_method_subst;
    cur       pls_integer;
    jj        pls_integer;
    v_tmpidx  pls_integer;
    eprog     varchar2(8000);
    edecl1    varchar2(8000);
    v_str     varchar2(100);
    b         boolean;
begin
    if use_java then
      b := plp2java.dbclass2java (p_class,p_kernel,p_mgn,p_idx,p_all,objid,edecl,etext,tmpprog,tmpidx);
      if b then
        return true;
      end if;
      plib.fill_class_info(plpclass,p_class,null);
      plpclass.is_reference := true;
      objid := plp2java.add_bind(tmp_vars,cur_pref,plpclass,objid,false,null);
      return false;
    end if;
    v_str := ref_string(p_kernel,true, lib.pk_is_rowid(p_class));
    if tmpvar(tmp_sos_idx,'ID',v_str,tmp_expr_idx) then
      tmpprog := p_mgn||lasttmp||TAB||v_str||';'||NL;
    else
      tmpprog := null;
    end if;
    objid := lasttmp;
    tmpidx:= last_idx;
    plib.ir(p_idx).einfo := tmpidx;
    if retry then cur := 1; else cur := 0; end if;
    v_tmpidx := tmp_expr_idx;
    jj := construct_cursor_text( NULL,case when retry then 'c_obj' else objid end,
        NULL,p_idx,NULL,p_idx,NULL,NULL,NULL,length(p_mgn),p_all,jj,cur,edecl1,eprog,etext);
    tmp_expr_idx := v_tmpidx;
    if retry then
        etext :=p_mgn||'declare'||NL||edecl1||etext||';'||NL
              ||p_mgn|| 'begin'||NL||eprog
              ||p_mgn||TAB||objid||' := null;'||NL
              ||p_mgn||TAB||'for c in c_obj loop '||objid||' := c.id; exit; end loop;'||NL
              ||p_mgn||'end;'||NL;
    else
        etext := plib.nn( p_mgn||'declare'||NL,edecl1 )
            ||p_mgn||'begin'||NL||eprog||etext||';'||NL
            ||p_mgn||'exception'||NL
            ||p_mgn||TAB||'when NO_DATA_FOUND then raise rtl.NO_DATA_FOUND;'||NL
            ||p_mgn||TAB||'when TOO_MANY_ROWS then raise rtl.TOO_MANY_ROWS;'||NL
            ||p_mgn||'end;'||NL;
    end if;
    -- try calculate
    if plib.g_calc_class and p_all = 2000 /*and trim(replace(eprog, NL)) is null*/ then
      v_str := objid;
      edecl1:= replace(replace(etext,v_str,':ID'),' then raise rtl.',' then raise ');
      begin
        execute immediate edecl1 using in out v_str;
        plib.plp_warning( p_idx, 'ID_SUBSTITUTE', v_str, p_class );
        if v_str is null then
          objid := NULL_CONST;
        elsif p_kernel then
          objid := ''''||v_str||'''';
        else
          objid := v_str;
        end if;
        etext := null;
        if tmpprog is null then
          tmpidx := null;
        end if;
        return true;
      exception
        when NO_DATA_FOUND then
            plib.plp_error( p_idx, 'OBJECT_NOT_FOUND', p_class );
        when TOO_MANY_ROWS then
            plib.plp_error( p_idx, 'TOO_MANY_OBJECTS', p_class );
        when others then
          if sqlcode in (-4061,-6508) then
            rtl.debug( 'var2plsql: '||sqlerrm||':'||NL||edecl1,1,false,null);
            raise;
          end if;
      end;
    end if;
    return false;
end;
--
-- @METAGS replace_text
procedure replace_text(p_idx pls_integer, p_srch varchar2, p_repl varchar2) is
    node    plib.ir_node_t := plib.ir(p_idx);
begin
    if node.type=plp$parser.TEXT_ and node.type1>0 and node.node>COL_FLAG then
        plib.ir(p_idx).text := replace(node.text,p_srch,p_repl);
    elsif not node.down is null then
        replace_text(node.down,p_srch,p_repl);
    end if;
    if not node.right is null then
        replace_text(node.right,p_srch,p_repl);
    end if;
end;
--
-- @METAGS this_state
procedure this_state(p_mtd boolean, p_upd boolean, p_chg boolean, p_get boolean, p_obj boolean,
                     p_getobj boolean, p_txt in out nocopy varchar2, p_mgn varchar2) is
    b boolean;
    m boolean;
begin
    b := p_chg;
    if p_upd then
      if this_mtd then
        put_set_this(p_txt,p_mgn);
      elsif p_getobj then
        m := this_upd;
        put_set_this(p_txt,p_mgn);
        this_upd := m;
      else
        this_upd := true;
      end if;
    elsif p_mtd then
      if this_upd then
        put_get_this(p_txt,p_mgn);
      elsif p_obj then
        m := this_mtd;
        if call_obj then
          b := this_chg;
        end if;
        put_get_this(p_txt,p_mgn);
        if call_obj then
          this_chg := b;
          b := false;
        end if;
        this_mtd := m;
      else
        this_mtd := true;
      end if;
    end if;
    if b then
        this_chg := true;
        if this_get then
            p_txt := p_txt||p_mgn||obj_select;
            chg_count := chg_count + 1;
        end if;
    end if;
    if p_get then
        this_get := true;
    end if;
end;
--
function get_def_partkey(p_class varchar2, p_var boolean) return varchar2 is
begin
  if chk_key then
    if p_class=plib.g_class_id or lib.is_parent(p_class, plib.g_class_id) then
      if p_var then
        return 'nvl('||var_key||',valmgr.get_key('''||p_class||'''))';
      end if;
      return 'nvl('||var_key||',-1)';
    elsif p_var then
      return 'rtl.bool_num('||var_prt||'<0,valmgr.get_key('''||p_class||'''),0)';
    end if;
    return var_prt;
  end if;
  if p_var then
    return 'valmgr.get_key('''||p_class||''')';
  end if;
  return '-1';
end;
--
procedure conv_boolean(p_idx pls_integer,p_text in out nocopy varchar2) is
  idx pls_integer;
  typ pls_integer;
begin
  idx := plib.parent(p_idx);
  if idx is not null then
    typ := plib.ir(idx).type;
    if typ in ( plp$parser.WHERE_, plp$parser.HAVING_, plp$parser.CONNECT_, plp$parser.START_, plp$parser.DBCLASS_)
      -- PLATFORM-7717
      -- т.к. не парсится слово THEN в конструкции CASE, то проверим, что мы в условии WHEN
      -- смотри plp$parser.yyparse с условием yym = 204 и yym = 205, отсутствует 206 - разбор ноды для THEN
      or typ = plp$parser.WHEN_ and p_idx <> plib.last_child(idx)
      or typ = plp$parser.BOOLEAN_ and plib.ir(idx).type1 in ( plp$parser.OR_, plp$parser.AND_, plp$parser.NOT_ )
      or typ = plp$parser.ATTR_ and plib.ir(idx).type1 = plp$parser.COLLECTION_
      or typ = plp$parser.MODIFIER_ and plib.ir(idx).type1 = plp$parser.OBJ_COLLECTION_
    then
      p_text := '('||p_text||YESSTR;
    end if;
  end if;
end;
--
function get_iface_call(c_type in out nocopy varchar2,
                        objid varchar2, ocls varchar2, qual varchar2,
                        cls   varchar2, typ  pls_integer, p_left boolean) return varchar2 is

    v_func  varchar2(700);
begin
    if typ = plp$parser.RECORD_ then
        if instr(qual,'.') = 0 then
          if p_left then
            v_func := '.s$'||class_mgr.make_valid_literal(lower(qual));
          else
            v_func := '.g$'||class_mgr.make_valid_literal(lower(qual));
          end if;
          return class_mgr.interface_package(ocls)||v_func||'('||objid;
        end if;
        if p_left then
          v_func := '.set_'||class_mgr.make_valid_literal(cls);
        else
          v_func := '.get_'||class_mgr.make_valid_literal(cls);
        end if;
        return class_mgr.interface_package(ocls)||v_func||'('||objid||','''||qual||'''';
    end if;
    if typ > 0 then
      v_func := nvl(qual,SP);
      if lib.field_exist(v_func,ocls,true) then
        v_func := lower(substr(v_func,instr(v_func,'.')+1));
        if instr(v_func,'c_') = 1 then
          v_func := substr(v_func,3);
        end if;
        if p_left then
          v_func := '.s#'||v_func;
        else
          v_func := '.g#'||v_func;
        end if;
        if c_type is null then
          if typ in (plp$parser.STRING_,plp$parser.MEMO_) then
            c_type := rtl.STRING_EXPR;
          elsif typ = plp$parser.REF_ then
            if cls is null or lib.has_stringkey(lib.class_target(cls)) then
              c_type := rtl.STRING_EXPR;
            else
              c_type := rtl.NUMBER_EXPR;
            end if;
          elsif typ in (plp$parser.COLLECTION_,plp$parser.OBJ_COLLECTION_) then
            c_type := rtl.NUMBER_EXPR;
          elsif typ = plp$parser.ONE_ then
            if not lib.is_kernel(cls) then
              c_type := rtl.NUMBER_EXPR;
            end if;
          end if;
        end if;
        return class_mgr.interface_package(ocls)||v_func||'('||objid;
      end if;
    end if;
    if typ = plp$parser.STRING_ then
        v_func := 'str';
        c_type := nvl(c_type,rtl.STRING_EXPR);
    elsif typ = plp$parser.REF_ then
        v_func := 'ref';
        if c_type is null then
          if cls is null or lib.has_stringkey(lib.class_target(cls)) then
            c_type := rtl.STRING_EXPR;
          else
            c_type := rtl.NUMBER_EXPR;
          end if;
        end if;
    elsif typ in (plp$parser.NUMBER_,plp$parser.INTEGER_) then
        v_func := 'num';
    elsif typ in (plp$parser.COLLECTION_,plp$parser.OBJ_COLLECTION_) then
        v_func := 'coll';
        c_type := nvl(c_type,rtl.NUMBER_EXPR);
    elsif typ = plp$parser.BOOLEAN_ then
        v_func := 'bool';
    elsif typ = plp$parser.DATE_ then
        if lib.is_kernel(cls) then
            if    cls = 'TIMESTAMP' then
                v_func := 'ts';
            elsif cls = 'TIMESTAMP_TZ' then
                v_func := 'tstz';
            elsif cls = 'TIMESTAMP_LTZ' then
                v_func := 'tsltz';
            elsif cls = 'INTERVAL' then
                v_func := 'dsi';
            elsif cls = 'INTERVAL_YM' then
                v_func := 'ymi';
            else
                v_func :='date';
            end if;
        else
            v_func := 'date';
        end if;
    elsif typ = plp$parser.MEMO_ then
        v_func := 'memo';
        c_type := nvl(c_type,rtl.STRING_EXPR);
    elsif typ = plp$parser.TIMESTAMP_ then
        if cls = 'TIMESTAMP_TZ' then
            v_func := 'tstz';
        elsif cls = 'TIMESTAMP_LTZ' then
            v_func := 'tsltz';
        else
            v_func := 'ts';
        end if;
    elsif typ = plp$parser.INTERVAL_ then
        if cls = 'INTERVAL_YM' then
            v_func := 'ymi';
        else
            v_func := 'dsi';
        end if;
    elsif typ = plp$parser.ONE_ then
        if lib.is_kernel(cls) then
          v_func := lower(replace(cls,' '));
        else
          v_func := 'ole';
          c_type := nvl(c_type,rtl.NUMBER_EXPR);
        end if;
    elsif typ = -plp$parser.BOOLEAN_ then
        v_func := 'bool_char';
    elsif typ = plp$parser.TABLE_ then
        if p_left is null then
          v_func := 'tbl_'||lower(class_mgr.make_valid_literal(cls));
        else
          v_func := 'tbl_'||lower(class_mgr.make_valid_literal(lib.class_target(cls)));
        end if;
    else
        v_func := 'str';
    end if;
    if p_left then
        v_func := '.set_'||v_func;
    else
        v_func := '.get_'||v_func;
    end if;
    return class_mgr.interface_package(ocls)||v_func||'('||objid||','''||nvl(qual,SP)||'''';
end;
--
-- @METAGS var2plsql
function  var2plsql ( p_idx    IN     pls_integer,
                      p_decl   in out nocopy varchar2,
                      p_prog   in out nocopy varchar2,
                      p_text   in out nocopy varchar2,
                      p_rvalue IN     varchar2 default NULL,
                      p_mgn    IN     varchar2 default NULL,
                      p_calc   IN     boolean  default TRUE,
                      p_bool   IN     boolean  default FALSE,
                      p_index  IN     boolean  default TRUE
                    ) return boolean is
    i         pls_integer;
    j         pls_integer;
    idx       pls_integer;
    typ       pls_integer;
    typ1      pls_integer;
    v_idx     pls_integer;
    v_setidx  pls_integer;
    ref_idx   pls_integer;
    ocls      varchar2(200);
    objid     varchar2(8000);
    qual      varchar2(2000);
    ptext     varchar2(8000);
    etext     varchar2(32767);
    eprog     varchar2(32767);
    itext     varchar2(32767);    -- index text
    txt       varchar2(2000);
    txt1      varchar2(100);
    prt       varchar2(100);
    dot       varchar2(1);
    c_type    varchar2(1) := rtl.STRING_EXPR;
    inobj     boolean;
    new_class boolean := FALSE;
    obj_lock  boolean := FALSE;
    obj_coll  boolean := FALSE;
    add_tmp   boolean := FALSE;
    v_left    boolean;
    v_assign  boolean;
    expand    boolean;
    expand1   boolean;
    c_idx     boolean;
    c_check   boolean;
    pupd      boolean;
    pmtd      boolean;
    pchg      boolean;
    pget      boolean;
    pobj      boolean;
    pgobj     boolean;
    obj       boolean;
    v_exec    boolean;
    v_calc    boolean := p_calc;
    ok        boolean := FALSE;
    v_expr    plib.expr_info_t;
    v_class   plib.plp_class_t;
    v_method  lib.method_info_t;
--
    procedure objlock(p_class varchar2, p_idx pls_integer) is
      obj   varchar2(16);
      suff  varchar2(100);
      idx   pls_integer;
    begin
      idx := plib.ir(p_idx).einfo;
      if idx is not null and temp_vars.exists(idx) then
        obj := temp_vars(idx).text4;
      else
        obj := ref_string(lib.has_stringkey(p_class),true,lib.pk_is_rowid(p_class));
        if tmpvar(tmp_sos_idx,'ID',obj,tmp_expr_idx) then
            p_decl := p_mgn||lasttmp||TAB||obj||';'||NL||p_decl;
        end if;
        obj := lasttmp;
        db_update := true;
        plib.ir(p_idx).einfo := last_idx;
        if p_class=constant.OBJECT then
          suff := 'rtl';
          ptext:= null;
        else
          suff := class_mgr.interface_package(p_class);
        end if;
        p_prog := p_prog||p_mgn||obj||':='||objid||'; '||suff||'.lock_object('||obj||','||linfo_txt||ptext||');'||NL;
      end if;
      obj_lock := FALSE;
      add_tmp := TRUE;
      objid := obj;
    end;
--
    procedure set_rvalue(p_self boolean) is
      v_type  varchar2(100);
    begin
      if p_self then
        v_type := self_type;
      else
        v_type := plsql_type(p_idx,true,false,false,false);
      end if;
      if tmpvar(tmp_sos_idx,plib.THIS,v_type,-1) then --,tmp_expr_idx) then
        p_decl := p_mgn||lasttmp||TAB||v_type||';'||NL||p_decl;
      end if;
      v_setidx := last_idx;
      if lasttmp <> p_rvalue then
        p_prog := p_prog||p_mgn||lasttmp||' := '||p_rvalue||';'||NL;
      end if;
      --tmp_expr_idx := nvl(tmp_expr_idx,0) + 1;
    end;
--
    procedure objthis(p_lock  boolean default FALSE,
                      p_cache boolean default TRUE) is
        i   pls_integer;
    begin
        if is_method and objid=new_this then
            if p_lock or obj_lock then
                if instr(plib.g_method_flags,constant.METHOD_STATIC) > 0 then
                    plib.plp_warning(p_idx,'OBJECT_STATIC',ocls);
                end if;
                lock_this:= true;
                obj_lock := false;
            end if;
            if cache_this and plib.g_optim_this and ocls=plib.g_class_id then
              if p_cache then
                if not ptext is null then
                  if prt is null or ptext<>prt then
                    plib.plp_warning(p_idx,'TYPE_WRONG',substr(ptext,2));
                  end if;
                end if;
                if qual is null then
                  i := plib.add_unique(used_attrs,'$<NULL>$');
                elsif v_left and not this_ins and qual=plib.g_class_key then
                  return;
                else
                  i := plib.add_unique(used_attrs,qual);
                end if;
                this_var:=true;
                call_obj:=cache_obj;
                if p_lock then
                  this_upd := TRUE;
                  used_attrs(i).text4 := constant.YES;
                  if this_attr and qual=plib.g_method_sname then
                    plib.plp_warning(p_idx,'ASSIGNMENT', plib.g_class_id||'.'||plib.g_method_sname );
                  end if;
                end if;
                if this_mtd then
                  if v_assign and v_setidx is null and p_index is null then
                    set_rvalue(qual is null);
                  end if;
                  put_get_this(p_prog,p_mgn);
                end if;
                if not qual is null then
                  qual := class_mgr.qual2elem(qual);
                end if;
                obj_count := obj_count + 1;
                etext:= var_this||qual;
                qual := null;
                objid:= null;
              elsif p_lock and not this_var and qual is null then
                this_mtd := true;
              end if;
            end if;
        end if;
    end;
--
    procedure objclass(p_class varchar2) is
      jj  pls_integer;
      v_kernel  boolean;
    begin
      jj := plib.ir(i).einfo;
      add_tmp := true;
      if jj is not null and temp_vars.exists(jj) then
        objid := temp_vars(jj).text4;
        eprog := null;
        etext := null;
      else
        v_kernel := lib.has_stringkey(p_class);
        if dbclass2plsql (
                         p_class  => p_class,
                         p_kernel => v_kernel,
                         p_mgn    => p_mgn,
                         p_idx    => i,
                         p_all    => j,
                         objid    => objid,
                         edecl    => p_decl,
                         etext    => etext,
                         tmpprog  => eprog,
                         tmpidx   => jj
        ) then
          set_const_var(objid,jj);
          plib.ir(i).einfo := jj;
        end if;
      end if;
      if jj < 0 then
        ok := c_check;
        add_tmp := false;
      end if;
    end;
--
    procedure obj_chg(p_qual varchar2) is
    begin
        if this_chg then
            p_prog := p_prog||p_mgn||obj_select;
            chg_count := chg_count + 1;
        end if;
        if not ptext is null then
          if prt is null or ptext<>prt then
            plib.plp_warning(p_idx,'TYPE_WRONG',substr(ptext,2));
          end if;
        end if;
        this_obj := true;
        this_get := true;
        this_chg := false;
        etext := obj_this||p_qual;
    end;
--
    procedure check_part_key(p_class varchar2) is
    begin
      if ptext=prt then
        if p_class=plib.g_class_id or lib.is_parent(p_class, plib.g_class_id) then
          if not p_bool then
            ptext := ', key_ => nvl('||var_key||',-1)';
          else
            ptext := ',nvl('||var_key||',-1)';
          end if;
        elsif not p_bool then
          ptext := ', key_ => '||var_prt;
        else
          ptext := ','||var_prt;
        end if;
      end if;
    end;
--
    procedure attr_index is
    begin
        j := 0;
        new_class:=lib.class_exist(txt1,class_info);
        ocls  := nvl(class_info.class_ref,class_info.class_id);
        objclass(ocls);
        if etext is not null then
          p_decl := eprog||p_decl;
          p_prog := p_prog||etext;
        end if;
        etext := objid;
        ok    := FALSE;
        inobj := FALSE;
        qual  := NULL; dot := NULL;
    end;
--
    procedure get_index(p_mtd boolean  default false,
                        p_txt varchar2 default null,
                        p_var boolean  default true) is
      tmpprg varchar2(4000);
      tmptxt varchar2(32767);
      v_nam  varchar2(100);
      v_tnam varchar2(30);
      vset   boolean;
      vget   boolean;
      i1     pls_integer;
      i2     pls_integer;
      jj     pls_integer;
      cnt    pls_integer;
      gcnt   pls_integer;
      v_chk  boolean;
      v_par  boolean := false;
      v_set  boolean := false;
      v_get  boolean := false;
      oupd   boolean := this_upd;
      omtd   boolean := this_mtd;
      ochg   boolean := this_chg;
      oget   boolean := this_get;
      next   boolean := p_txt is null;
    begin
      c_idx:= true; pobj := false; pgobj := false;
      pmtd := null; pupd := null;
      pchg := null; pget := null;
      itext:= null; eprog:= null;
      while not j is null or not next loop
        if is_method then
          this_mtd := false; this_upd := false; cnt := obj_count;
          this_chg := ochg;  this_get := oget; gcnt := get_count;
        end if;
        jj := j;
        vset := true;
        if next then
          if plib.ir(j).type = plp$parser.SETPAR_ then
            v_nam := plib.ir(j).text;
            if v_nam is null then
              if itext is null then
                if p_var then
                  v_nam := ',';
                else
                  v_nam := ',)(';
                end if;
              else
                v_nam := ')(';
              end if;
            elsif v_nam <> '$$$' then
              if plib.g_parse_java then
                v_nam := ',/*'||v_nam||' =>*/';
              else
                v_nam := ','||v_nam||' => ';
              end if;
            else
              vset := false;
            end if;
            jj := plib.ir(j).down;
          else
            v_nam := ',';
          end if;
          if vset then
            if plib.pop_expr_info(jj,v_expr) then
              vget := plib.get_expr_type(jj,v_class);
            else
              v_expr := null;
            end if;
            c_idx := expr2plsql(jj,p_decl,tmpprg,tmptxt,p_mgn,false,p_calc,p_bool) and c_idx;
            if v_expr.compatible >= 0 then
              plib.put_expr_info(jj,v_expr);
            end if;
          end if;
        else
          vget := not j is null and plib.ir(j).type=plp$parser.SETPAR_ and plib.ir(j).type1=0;
          if vget then
            c_idx := expr2plsql(plib.ir(j).down,p_decl,tmpprg,tmptxt,p_mgn,false,p_calc,p_bool);
            if this_mtd or this_upd or length(tmptxt)>198 then
              vget := false;
              plib.plp_error(j,'TYPE_WRONG',tmptxt);
            elsif ocls=',NULL' or ocls like ',''%' and ocls not like ',''$$$%' then
              plib.plp_warning(j,'ASSIGN_ERROR',var_class,tmptxt);
            else
              vget := false;
              plib.plp_warning(j,'NOT_LVALUE',var_class);
            end if;
            j := plib.ir(j).right;
            jj:= j;
            this_mtd := false; this_upd := false;
          end if;
          if vget then
            ocls := ','||tmptxt;
          else
            tmpprg:= null;
          end if;
          tmptxt:= p_txt;
          if v_expr.param_dir is not null then
            if v_expr.expand > 0 then
              vget := plib.get_expr_type(v_expr.expand,v_class);
            else
              plib.fill_class_info(v_class,v_method.class_id,null);
              v_class.is_reference := true;
              v_expr.compatible := 0;
            end if;
          end if;
        end if;
        if vset then
          vget := v_expr.param_dir is not null or this_mtd or this_upd;
          if tmpprg is not null then
            p_prog := p_prog||tmpprg;
            --vget := true;
          end if;
          v_chk := null;
          if vget then
            if v_expr.compatible is null then
              tmpprg := plsql_type(jj,true,false,false,false);
            else
              tmpprg := plp_class(v_class,true);
            end if;
            if tmpvar(tmp_sos_idx,'PARAM',tmpprg,tmp_expr_idx) then
              p_decl := p_mgn||lasttmp||TAB||tmpprg||';'||NL||p_decl;
            end if;
            tmp_expr_idx := nvl(tmp_expr_idx,0) + 1;
            v_tnam := lasttmp;
            if oupd then
              v_chk := true;
            elsif omtd then
              v_chk := false;
            end if;
          else
            v_tnam := null;
          end if;
          vget := false; vset := false;
          if is_method then
            if tmptxt = new_this then
              vset := true;
              if this_attr then
                plib.plp_warning(nvl(jj,i),'RECURSIVE_CALLS', plib.g_class_id||'.'||plib.g_method_sname );
              end if;
            elsif cnt <> obj_count then
              vget := true;
            end if;
            ochg := this_chg; oget := this_get;
          end if;
          if v_expr.param_dir is null or v_expr.param_dir <> constant.PARAM_OUT then
            if vset then
              v_par := true;
              v_set := plib.g_optim_this;
            elsif vget then
              v_get := true;
            end if;
            if this_upd then
              if omtd then
                put_get_this(p_prog,p_mgn);
                omtd := false; v_get := false;
                if call_obj then
                  ochg := false;
                end if;
              end if;
              oupd := true;
            elsif this_mtd then
              if oupd then
                put_set_this(p_prog,p_mgn);
                oupd := false; v_set := false;
              end if;
              omtd := true;
              ochg := true;
            end if;
            if v_expr.conv_in > 0 then
              tmptxt := plib.ir(v_expr.conv_in).text||'('||tmptxt||')';
            elsif not p_bool and v_expr.compatible = 2 and v_class.base_type = plp$parser.BOOLEAN_  then
              tmptxt := 'rtl.char_bool('||tmptxt||')';
            end if;
            if v_tnam is not null then
              if v_set and v_chk then
                if not this_upd then
                  oupd := false;
                end if;
                put_set_this(p_prog,p_mgn);
              elsif v_get and not v_chk then
                if not this_mtd then
                  omtd := false;
                  if call_obj then
                    ochg := false;
                  end if;
                end if;
                put_get_this(p_prog,p_mgn);
              end if;
              v_set := false; v_get := false;
              p_prog:= p_prog||p_mgn||v_tnam||' := '||tmptxt||';'||NL;
            end if;
          end if;
          if v_tnam is not null then
            if v_expr.param_dir in (constant.PARAM_IN_OUT,constant.PARAM_OUT) then
              if v_expr.conv_out > 0 then
                tmpprg := plib.ir(v_expr.conv_out).text||'('||v_tnam||')';
              else
                tmpprg := v_tnam;
              end if;
              if is_method then
                if pmtd is null then
                  this_mtd := false;
                  this_upd := false;
                  this_chg := false;
                  this_get := false;
                else
                  this_mtd := pmtd;
                  this_upd := pupd;
                  this_chg := pchg;
                  this_get := pget;
                end if;
              end if;
              if next then
                tmptxt:= null;
                c_idx := var2plsql(jj,p_decl,eprog,tmptxt,tmpprg,p_mgn,p_calc,p_bool) and c_idx;
              elsif v_expr.expand > 0 then
                if ocls is null then
                  i1 := i;
                else
                  i1 := plib.ir(i).left;
                end if;
                i2 := plib.ir(i1).left;
                plib.ir(i1).left := null;
                plib.ir(i2).right:= null;
                tmptxt:= null;
                c_idx := var2plsql(v_idx,p_decl,eprog,tmptxt,tmpprg,p_mgn,p_calc,p_bool) and c_idx;
                plib.ir(i1).left := i2;
                plib.ir(i2).right:= i1;
              else
                tmptxt:= p_txt||' := '||tmpprg;
                if vset then
                  this_mtd := true;
                  this_chg := true;
                end if;
              end if;
              if is_method then
                pupd := this_upd;
                pmtd := this_mtd;
                pchg := this_chg;
                pget := this_get;
                if vget then
                  pobj := true;
                end if;
                if gcnt < get_count then
                  pgobj:= true;
                end if;
              end if;
              eprog := eprog||p_mgn||tmptxt||';'||NL;
            end if;
            tmptxt := v_tnam;
          end if;
          if next then
            j := plib.ir(j).right;
            itext:= itext||v_nam||tmptxt;
          else
            next := true;
            itext:= tmptxt||ocls;
          end if;
        else
          j := plib.ir(j).right;
        end if;
      end loop;
      this_mtd := omtd;
      this_upd := oupd;
      this_chg := ochg;
      this_get := oget;
      if v_set and this_upd then
        put_set_this(p_prog,p_mgn);
      elsif v_get and this_mtd then
        put_get_this(p_prog,p_mgn);
      end if;
      if v_par and p_mtd then
        this_chg := true;
        this_mtd := plib.g_optim_this;
      end if;
    end;
--
    procedure setparam is
    begin
        itext := plsql_type(i,true,false,false,false);
        p_prog := p_prog||p_mgn;
        if itext is null then
          itext := NULL_CONST;
        else
          if tmpvar(tmp_sos_idx,'RESULT',itext,tmp_expr_idx) then
            p_decl := p_mgn||lasttmp||TAB||itext||';'||NL||p_decl;
          end if;
          add_tmp := TRUE;
          itext := lasttmp;
          p_prog:= p_prog||itext||' := ';
        end if;
        p_prog := p_prog||etext||';'||NL;
        if pmtd is not null then
          declare
            mtd boolean := this_mtd;
            upd boolean := this_upd;
            chg boolean := this_chg;
            get boolean := this_get;
          begin
            this_mtd := pmtd;
            this_upd := pupd;
            this_chg := pchg;
            this_get := pget;
            --stdio.put_line_buf('>>>'||etext);
            --stdio.put_line_buf('++>'||rtl.bool_char(upd)||rtl.bool_char(mtd)||rtl.bool_char(chg)||rtl.bool_char(get));
            --stdio.put_line_buf('-->'||rtl.bool_char(this_upd)||rtl.bool_char(this_mtd)||rtl.bool_char(this_chg)||rtl.bool_char(this_get));
            this_state(mtd,upd,chg,get,pobj,pgobj,p_prog,p_mgn);
            --stdio.put_line_buf('==>'||rtl.bool_char(this_upd)||rtl.bool_char(this_mtd)||rtl.bool_char(this_chg)||rtl.bool_char(this_get));
          end;
        end if;
        p_prog:= p_prog||eprog;
        etext := itext;
        eprog := null;
    end;
--
begin
    if p_rvalue is NULL then
      v_left := false;
      c_check:= plib.g_calc_expr;
      v_assign := false;
    else
      v_left := true;
      c_check:= false;
      v_assign := ascii(p_rvalue)<>13;
    end if;
    if plib.g_method_arch then
      if plib.g_prt_actual then
        ptext := null;
      elsif not p_bool then
        ptext := ', key_ => -1';
      else
        ptext := ',-1';
      end if;
    elsif not p_bool then
        ptext := ', key_ => 0';
    else
        ptext := ',0';
    end if;
    prt := ptext;
    if is_method then
      inobj:= true;
      objid:= new_this;
      ocls := plib.g_class_id;
    else
      inobj:= false;
      objid:= null;
      ocls := constant.OBJECT;
    end if;
    --dump_node(plib.ir(p_idx));
    i:= plib.ir(p_idx).node;
    if nvl(p_index,true) then
        v_idx := p_idx;
        expand := i < 0 and i > -10;
        expand1:= i >-2;
    else
        v_idx := plib.parent(p_idx);
    end if;
    i := plib.ir(v_idx).down;
    while not i is NULL loop
      idx := plib.ir(i).right;
      typ := plib.ir(i).type;
      typ1:= plib.ir(i).type1;
      txt := plib.ir(i).text;
      txt1:= plib.ir(i).text1;
      j   := plib.ir(i).down;   -- index list
      if use_counters then inc_counter(typ); end if;
      if typ = plp$parser.ID_ then
        ok := false;
        txt:= plib.get_new_name(-i);
        if plib.ir(i).node=4 and instr(txt1,'.') = 0 then
            typ := txt1;
            qual:= plib.ir(typ).text1;
            typ := bitand(plib.ir(typ).type1,15);
            inobj := false;
            if typ > 1 then
              if bitand(typ,2) > 0 then
                inobj := true;
                db_update := true;
              end if;
              if bitand(typ,8) > 0 then
                db_context := true;
              end if;
              if not p_bool and bitand(typ,4) > 0 then
                plib.plp_error(i, 'TYPE_WRONG', txt);
              end if;
            end if;
            if sosmethod and has_src_id and j is null and plib.g_src_merge and txt like 'BASE$%' then
              if is_validator and txt='BASE$VALIDATE' or not is_validator and txt='BASE$EXECUTE' then
                chk_call := false;
                --PLATFORM-8599
                if over_count>0 and (not upper(nvl(substr(rtl.setting('PLP_EXTENSION_SYS_SWITCH'),1,1),'N')) in ('Y','1')) and this_upd then
                   put_set_this(p_prog,p_mgn);
                end if;
              end if;
            end if;
            get_index(inobj,null,false);
            inobj:= true;
            if not qual is null then
              declare
                mtd boolean := this_mtd;
                upd boolean := this_upd;
                chg boolean := this_chg;
                get boolean := this_get;
              begin
                this_mtd := instr(qual,'MTD')>0;
                this_upd := instr(qual,'UPD')>0;
                this_chg := instr(qual,'CHG')>0;
                this_get := instr(qual,'GET')>0;
                --stdio.put_line_buf('**>'||txt||'.'||qual);
                --stdio.put_line_buf('++>'||rtl.bool_char(upd)||rtl.bool_char(mtd)||rtl.bool_char(chg)||rtl.bool_char(get));
                --stdio.put_line_buf('-->'||rtl.bool_char(this_upd)||rtl.bool_char(this_mtd)||rtl.bool_char(this_chg)||rtl.bool_char(this_get));
                this_state(mtd,upd,chg,get,instr(qual,'OBJ')>0,instr(qual,'G$O')>0,p_prog,p_mgn);
                --stdio.put_line_buf('==>'||rtl.bool_char(this_upd)||rtl.bool_char(this_mtd)||rtl.bool_char(this_chg)||rtl.bool_char(this_get));
              end;
            end if;
            if nvl(p_bool,true) and plib.g_parse_java and plib.ir(i).left = v_idx then
              if instr(txt,'.') + instr(txt,'<') = 0 then
                txt := plib.g_method_pack||'.'||plib.ir(i).text;
              end if;
            end if;
        elsif ascii(txt1) = ascii('%') then -- cursor attributes
            j := instr(txt1,'.');
            typ := substr(txt1,j+1);
            txt1:= substr(txt1,1,j-1);
            if typ < 0 then -- static cursor
              txt := plib.ir(i).text;
            end if;
            itext := null;
            eprog := null;
            inobj := false;
            if txt1 in ('%ROWCOUNT','%ISOPEN','%FOUND','%NOTFOUND') then
              txt := txt || txt1;
            end if;
        else
            inobj:= plib.ir(i).node=1;
            get_index(false,null,not inobj);
            if plib.ir(i).node=5 then
              dot := null;
            end if;
        end if;
        inobj := inobj and itext is null and eprog is null and not idx is null;
        etext := etext||dot||txt;
        if etext = '<PLP$CAST>' then  -- cast_to
            etext := substr(itext,2);
        elsif not itext is NULL then
            etext := etext||'('||substr(itext,2)||')';
        end if;
        if not eprog is null then setparam; end if;
        if typ1 is null then
            typ := null;
        else
            typ := plib.ir(typ1).type;
        end if;
        if typ = plp$parser.REF_ then
            ocls := plib.ir(typ1).text;
            typ1 := typ;
            objid:= etext;
            dot  := NULL;
        elsif typ = plp$parser.DBOBJECT_ then
            ocls := plib.ir(typ1).text;
            typ1 := plib.convert_base(plib.ir(typ1).text1);
            objid:= NULL;
            dot  := '.';
        else
            ocls := NULL;
            objid:= NULL;
            dot  := '.';
        end if;
        txt1 := ocls;
        if inobj and objid is null then
          etext := etext||'()';
        end if;
        qual := NULL; inobj:= FALSE;
      elsif typ = plp$parser.ATTR_ then
        new_class := not j is null;
        if txt like '$$$%' then
          etext := etext||dot||substr(txt,4);
          if new_class then
            ok := false;
            get_index;
            etext := etext||'('||substr(itext,2)||')';
            dot := '.';
          else
            dot := null;
          end if;
          objid := null;
          qual := null;
        elsif new_class and plib.ir(i).einfo = 0 then
          ok := false;
          get_index;
          if objid is NULL then
            etext := etext||qual||replace(dot,'.','.A#')||class_mgr.replace_invalid_symbols(txt);
          else
            etext := get_iface_call(c_type,objid,ocls,qual||dot||txt,txt1,plp$parser.TABLE_,null)||ptext||')';
            --etext := class_mgr.interface_package(ocls)||'.get_tbl_'||lower(class_mgr.make_valid_literal(txt1))||'('||objid||','''||qual||dot||txt||''''||ptext||')';
          end if;
          etext := etext||'('||substr(itext,2)||')';
          dot := '.';
          objid := null;
          qual := null;
        elsif new_class and i<>p_idx then
          attr_index;
          txt1 := ocls;
        else
          --if txt like 'plp$%' then   -- renamed
          --    txt := substr(txt,5);
          --end if;
          if objid is NULL then
            if ocls=constant.OBJECT then
              qual := qual||dot||txt;
            else
              qual := qual||replace(dot,'.','.A#')||class_mgr.replace_invalid_symbols(txt);
            end if;
            if plib.ir(i).left = v_idx then
              plib.plp_error(i, 'TYPE_WRONG', txt);
            end if;
          else
              qual := qual||dot||txt;
              inobj := TRUE;
              v_calc := p_calc;
          end if;
          dot := '.';
          exit when new_class;
          if obj_coll then
              plib.plp_error(i, 'TYPE_WRONG', txt);
          end if;
        end if;
        new_class := FALSE;
      elsif typ in (plp$parser.RTL_,plp$parser.VARMETH_) then
        inobj:= false;
        new_class := typ=plp$parser.RTL_;
        if typ1<0 then -- constant
            typ1:=-typ1;
            ok := plib.g_calc_const;
            if ok then
              if plib.g_parse_java then
                if typ1 = plp$parser.DATE_ then
                  ok := false;
                else
                  v_calc := substr(txt,1,instr(txt,'.')-1) in ('CONSTANT','RTL','STDIO','INST_INFO','MESSAGE','METHOD','PLIB');
                end if;
              else
                v_calc := plib.g_calc_attr and txt like 'INST_INFO.%';
              end if;
            else
              v_calc := false;
            end if;
        else
          typ := bitand(plib.ir(i).node,15);
          if typ > 1 then
            if bitand(typ,2) > 0 then
              inobj := true;
              db_update := true;
            end if;
            if bitand(typ,8) > 0 then
              db_context := true;
            end if;
            if not p_bool and bitand(typ,4) > 0 then
              plib.plp_error(i, 'TYPE_WRONG', txt);
            end if;
          end if;
        end if;
        typ := plib.ir(i).einfo;
        if plib.g_parse_java and typ in (257,258,260,290) then -- get_value/set_value/get_object/get_parent
          if txt <> upper(txt) then  -- converted
            if plib.pop_expr_info(j,v_expr) then null; end if;
          end if;
        end if;
        get_index(inobj);
        new_class := new_class and itext is null and eprog is null and not idx is null;
        etext := etext||dot||txt;
        if c_check and c_idx then
            if calc_rtl.exists(etext) then
                c_type:=substr(txt1,1,1);
                v_calc:=p_calc;
                ok:=true;
            end if;
        end if;
        if typ = 164 then -- plp_calc
          if typ1=plp$parser.NULL_ then
            v_exec := false;
          else
            v_exec := true;
          end if;
          v_calc:= true;
          c_check:= true;
          ok:=true;
          etext := substr(itext,2);
        elsif typ = 165 then -- cast_to
          etext := substr(itext,2);
        elsif not itext is NULL then
          etext := etext||'('||substr(itext,2)||')';
          if typ = 100 then  -- collect
            typ := plib.parent(v_idx);
            if not p_bool or plib.ir(typ).type <> plp$parser.PRIOR_ then  -- cast
              plib.plp_error(i, 'TYPE_WRONG', txt);
            end if;
          end if;
        end if;
        --etext:= etext||itext;
        ocls := txt1;
        if typ1=plp$parser.REF_ then
            objid := etext;
            dot := NULL;
        else
            objid := NULL;
            dot := '.';
        end if;
        if not eprog is null then setparam; end if;
        if new_class and objid is null then
          etext := etext||'()';
        end if;
        qual := NULL;
        inobj:= FALSE; new_class := FALSE;
      elsif typ in (plp$parser.OBJECT_REF_,plp$parser.LOCK_REF_) then
        inobj := TRUE;
        if obj_coll then
            plib.plp_error(plib.ir(ref_idx).left, 'TYPE_WRONG', '<COLLECTION>');
        end if;
        obj_coll := typ=plp$parser.LOCK_REF_;
        if txt1 is null then
            ocls := txt;
        else
            objthis;
            ocls  := txt1;
            if objid is NULL then
                objid := etext||qual;
            else
                if chk_key then check_part_key(txt); end if;
                --if obj_coll then
                --    objid := '.get_coll('||objid;
                --else
                --    objid := '.get_ref('||objid;
                --end if;
                --objid := class_mgr.interface_package(txt)||objid||','''||nvl(qual,' ')||''''||ptext||')';
                objid := get_iface_call(c_type,objid,txt,qual,null,case when obj_coll then plp$parser.COLLECTION_ else plp$parser.REF_ end,false)||ptext||')';
            end if;
            qual := NULL; dot := NULL;
        end if;
        if ocls like '$$$%' then
          ocls := substr(ocls,5);
          if is_method and not obj_coll and objid=new_this then
            new_class := true;
          end if;
          if txt1 is not null then
            txt1 := ocls;
          end if;
        end if;
        if j is null then
            ptext := prt;
        else
            get_index;
            etext := substr(itext,2);
            if not p_bool then
              ptext := ', key_ => '||etext;
            else
              ptext := ','||etext;
            end if;
        end if;
        obj_lock:= (typ1 mod 1000)=plp$parser.LOCK_REF_;
        ref_idx := i;
      elsif typ = plp$parser.DBCLASS_ then
        v_calc := false;
        ocls := txt1;
        objid := 'valmgr.static('''||txt||''')';
        --objid := ''''||txt||'''';
        new_class := j is NULL;
        if new_class then
            if c_check and self_calc then
                ok := txt=SYS;
                v_calc := p_calc and plib.g_parse_java;
            end if;
            if txt<>txt1 then
              plib.plp_error(i, 'TYPE_WRONG', txt1);
            end if;
        else
          j := 2000; -- scan in all class
          objclass(txt);
            --rtl.debug( 'var2plsql: '||i||' DBCLASS etext '||NL||etext,0);
          if etext is not null then
              p_prog := p_prog || etext;
              p_decl := eprog || p_decl;
          end if;
        end if;
        etext:= objid;
        inobj:= FALSE;
        qual := NULL; dot := NULL;
      elsif typ = plp$parser.METHOD_ then
        inobj := nvl(obj_lock,false);
        obj_lock := FALSE;
        if not qual is null then
            objthis;
            if objid is NULL then
                objid := etext||qual;
            else
                if chk_key then check_part_key(ocls); end if;
                --objid := class_mgr.interface_package(ocls)||'.get_ref('||objid||','''||qual||''''||ptext||')';
                objid := get_iface_call(c_type,objid,ocls,qual,null,plp$parser.REF_,false)||ptext||')';
            end if;
            ptext := prt;
        elsif objid is null then
            objid := etext;
        end if;
        if ok and v_calc then
            objid:=rtl.calculate(objid,rtl.STRING_EXPR,true);
        end if;
        ok:=false;
        lib.desc_method(txt1,v_method);
        if has_src_id and txt1=plib.g_method_src then
          if sosmethod and (objid=new_this or this_grp and objid=plib.THIS) then
            if inobj and is_validator or not (inobj or is_validator) then
              chk_call := false;
              obj_lock := true;
              if plib.g_src_merge and p_index then
                typ := plib.find_left(v_idx,plp$parser.FUNCTION_);
                typ := plib.ir(plib.ir(plib.ir(plib.ir(typ).down).right).right).down;
                if is_validator then
                  qual := 'BASE$VALIDATE';
                else
                  qual := 'BASE$EXECUTE';
                end if;
                typ := plib.find_child(typ,plp$parser.FUNCTION_,qual);
                if typ is not null then
                  if plib.ir(typ).node <= 0 then
                    plib.ir(typ).node := 1;
                  end if;
                  i := plib.ir(v_idx).down;
                  plib.delete_children(i);
                  j := plib.ir(i).right;
                  if j is not null then
                    plib.delete_branch(j);
                  end if;
                  j := plib.ir(typ).down;
                  plib.ir(v_idx).type := plp$parser.ID_;
                  plib.ir(v_idx).type1:= j;
                  plib.ir(v_idx).text := null;
                  plib.ir(v_idx).text1:= null;
                  plib.ir(v_idx).node := 0;
                  plib.ir(v_idx).einfo:= null;
                  plib.ir(i).type := plp$parser.ID_;
                  plib.ir(i).type1:= j;
                  plib.ir(i).text := qual;
                  plib.ir(i).text1:= typ;
                  plib.ir(i).node := 4;
                  plib.ir(i).einfo:= typ;
                  return var2plsql(v_idx,p_decl,p_prog,p_text,null,p_mgn,p_calc,p_bool,true);
                end if;
              end if;
            end if;
          end if;
          if plib.g_src_merge then
            txt1 := plib.g_method_id;
            if is_method then
              plib.plp_warning(i,'RECURSIVE_CALLS', plib.g_class_id||'.'||plib.g_method_sname );
            end if;
          end if;
        elsif not inobj and not v_method.ext_id is null and txt1<>plib.g_method_id then
          txt1 := v_method.ext_id;
          lib.desc_method(txt1,v_method);
        end if;
        if txt1=plib.g_method_id then
            v_method.package := null;
            v_method.features:= 0;
        else
          if v_method.package is null then
            v_method.package := method.make_pack_name(v_method.class_id,v_method.sname,txt1);
          end if;
          if not plib.g_prt_actual and bitand(v_method.features,4) > 0 then
            v_method.package := method.conv_pack_name(v_method.package,true);
          end if;
        end if;
        etext := method.make_proc_name(v_method.sname,inobj,v_method.package);
        ocls  := ','''||ocls||'''';
        if inobj then
            txt1 := NULL;
            if bitand(v_method.features,2) > 0 then
                db_update := true; ok := true;
            end if;
        else
            txt1 := v_method.result_id;
            if bitand(v_method.features,1) > 0 then
                db_update := true; ok := true;
            end if;
        end if;
        if instr(v_method.flags,constant.METHOD_STATIC) != 0 then    -- static
          objid := 'NULL';
        else
          obj := false;
          if new_class and is_method then
            obj := objid=new_this;
            if lib.is_parent(v_method.class_id, plib.g_class_id) then -- overlapped
              if instr(v_method.flags,constant.METHOD_NEW) != 0 then
                if (txt!=plib.g_method_sname or v_method.id=plib.g_method_id) and
                  (not plib.g_src_merge or txt!=plib.g_src_sname or v_method.id=plib.g_method_src)
                then
                  if obj then
                    new_class := false;
                  end if;
                elsif inobj and this_ins and bitand(v_method.features,2) = 0 then
                  objid:= 'nvl('||new_this||','||var_collect||')';
                  ocls := ',rtl.bool_char('||var_collect||' is null'||replace(ocls,',''',',''$$$#')||replace(ocls,',''',',''$$$_')||')';
                  obj_lock := null;
                  obj := null;
                else
                  obj := true;
                end if;
              elsif instr(v_method.flags,constant.METHOD_GROUP) != 0 then
                objid := plib.THIS;
                obj := null;
              else
                obj := true;
              end if;
            elsif obj then
              new_class := false;
            elsif instr(v_method.flags,constant.METHOD_GROUP) != 0 then
              plib.plp_error(i, 'BAD_PARAM_TYPE',plib.THIS,v_method.sname);
            end if;
          end if;
          if new_class then
            if obj then
              objid := new_this;
              if instr(v_method.flags,constant.METHOD_DELETE)=0
                and instr(v_method.flags,constant.METHOD_CRITERION)=0
              then
                ocls  := replace(ocls,',''',',''$$$#');
              end if;
            elsif not obj then
              objid := 'NULL';
            end if;
          elsif instr(v_method.flags,constant.METHOD_NEW) != 0 then   -- constructor
            if obj or is_method and objid=new_this then
              if inobj and this_ins and bitand(v_method.features,2) = 0 then
                ocls := ',rtl.bool_char('||new_this||' is null';
                if obj_lock then
                  if over_count>0 then
                    ocls := ocls||' or '||var_prefix||',';
                  else
                    ocls := ocls||' or '||var_class||' like ''$$$#%'',';
                  end if;
                  ocls := ocls||var_class||','||var_obj_class||','||var_obj_class||')';
                else
                  ocls := ocls||','||var_class||','||var_obj_class||')';
                end if;
                objid:= 'nvl('||new_this||','||var_collect||')';
                obj_lock := null;
              elsif obj_lock then
                if over_count>0 then
                  ocls := ',rtl.bool_char('||var_prefix||',';
                else
                  ocls := ',rtl.bool_char('||var_class||' like ''$$$#%'',';
                end if;
                ocls := ocls||var_class||','||var_obj_class||','||var_obj_class||')';
              elsif inobj or txt=plib.g_method_sname and v_method.id!=plib.g_method_id or
                plib.g_src_merge and txt=plib.g_src_sname and v_method.id!=plib.g_method_src
              then
                ocls := ','||var_obj_class;
              else
                objid := 'NULL';
              end if;
            elsif obj_coll then    -- constructor for collection
                ocls  := replace(ocls,',''',',''$$$_');
            else
                ocls := ',NULL';
            end if;
          elsif obj_lock then
            if instr(v_method.flags,constant.METHOD_GROUP) != 0 then
              ocls := ','||var_class;
            else
              ocls := ',nvl('||var_class||','||var_obj_class||')';
            end if;
          else
            ocls := ',NULL';
            if obj or is_method and objid=new_this then
              if instr(v_method.flags,constant.METHOD_DELETE)=0
                and instr(v_method.flags,constant.METHOD_GROUP)=0
                and instr(v_method.flags,constant.METHOD_CRITERION)=0
              then
                ocls := ','||var_obj_class;
              end if;
            end if;
          end if;
        end if;
        v_expr := null;
        if inobj then
            if instr(v_method.flags,constant.METHOD_TRIGGER) != 0 then
              plib.plp_error(i,'TYPE_WRONG',v_method.class_id||':'||v_method.sname);
            elsif objid='NULL' or obj_lock is null then
              v_expr.param_dir := constant.PARAM_IN;
            elsif plib.pop_expr_info(i,v_expr) then
              plib.put_expr_info(i,v_expr);
            end if;
        end if;
        get_index(ok,objid);
        if not ptext is null and instr(v_method.flags,constant.METHOD_TRIGGER)!=0 then
          if chk_key then check_part_key(v_method.class_id); end if;
          itext := itext||','||substr(ptext,10);
        end if;
        etext := etext||'('||itext||')';
        if typ1=plp$parser.REF_ then
            objid:=etext;
            dot:=NULL;
            if instr(v_method.flags,constant.METHOD_NEW) = 0 then
                txt1 := v_method.class_ref;
            end if;
        else
            objid := NULL;
            dot := '.';
        end if;
        if not eprog is null then setparam; end if;
        ocls := txt1;
        inobj:= FALSE;  qual := NULL;
        ok := FALSE;
        new_class:= FALSE;
        obj_coll := FALSE;
        obj_lock := FALSE;
      elsif typ = plp$parser.MODIFIER_ then
        dot := null;
        if typ1 in ( plp$parser.INSERT_, plp$parser.LOCATE_ ) then
          j := plib.ir(i).einfo;
          if j is not null and temp_vars.exists(j) then
            etext := temp_vars(j).text4;
          else
            typ := tmp_expr_idx;
            if typ1 = plp$parser.LOCATE_ then
              etext := locate2plsql(plib.ir(i).down,length(p_mgn),p_decl,p_prog);
            else
              etext := insert2plsql(i,p_mgn,p_decl,p_prog);
            end if;
            tmp_expr_idx := typ;
            j := instr(etext,':',-1);
            if j > 0 then
              plib.ir(i).einfo := substr(etext,j+1);
              etext := substr(etext,1,j-1);
            end if;
          end if;
          objid := etext;
          add_tmp := true;
        else
          if txt like '$$$%' then
            txt := substr(txt,5);
          end if;
          if inobj and plib.ir(i).left<>v_idx then
            objthis(v_left and typ1=plp$parser.OBJ_ID_);
          end if;
          if c_check and self_calc and new_class and plib.g_calc_attr then
            ok:= true; v_calc:=p_calc;
          end if;
          if objid is null then
            if not inobj and qual is null and get_ref_class(plib.ir(i).left) is null then
              inobj := null;
            else
              inobj := false;
            end if;
            objid := etext||qual;
          else
            inobj := not qual is null;
          end if;
          typ := plib.ir(i).node;
          if typ<0 then
            typ := (-typ) mod 1000;
          end if;
          if typ1 = plp$parser.OBJ_ID_ then
            if not j is null then
                get_index;
                if not p_bool then
                  ptext := ', key_ => '||substr(itext,2);
                else
                  ptext := itext;
                end if;
            end if;
            if inobj then
                v_calc := p_calc;
                if chk_key then check_part_key(ocls); end if;
                if obj_lock then objlock(ocls,i); end if;
                if v_left then
                    db_update := true;
                    v_left:= false;
                    if v_setidx is null then
                      etext := p_rvalue;
                    else
                      etext := temp_vars(v_setidx).text4;
                    end if;
                    --etext := class_mgr.interface_package(ocls)||'.set_ref('||objid||','''||qual||''','||etext||ptext||')';
                    etext := get_iface_call(c_type,objid,ocls,qual,null,plp$parser.REF_,true)||','||etext||ptext||')';
                else
                    --etext := class_mgr.interface_package(ocls)||'.get_ref('||objid||','''||qual||''''||ptext||')';
                    etext := get_iface_call(c_type,objid,ocls,qual,null,plp$parser.REF_,false)||ptext||')';
                    if ok and c_check and v_calc and not add_tmp then
                      if txt1 = constant.REFSTRING then
                        c_type := rtl.STRING_EXPR;
                      else
                        c_type := rtl.NUMBER_EXPR;
                      end if;
                    end if;
                end if;
            else
                if inobj is null then
                    etext := objid||'.id';
                else
                    etext := objid;
                end if;
                v_calc:= false;
            end if;
            objid := null;
          else
            if inobj then
                v_calc := p_calc;
                if chk_key then check_part_key(ocls); end if;
                if obj_lock then objlock(ocls,i); end if;
                --objid := class_mgr.interface_package(ocls)||'.get_ref('||objid||','''||qual||''''||ptext||')';
                objid := get_iface_call(c_type,objid,ocls,qual,null,plp$parser.REF_,false)||ptext||')';
                ptext := prt;
                inobj := false;
            elsif is_method and not inobj then
                inobj := objid=new_this;
            end if;
            obj := txt=constant.OBJECT;
            qual := class_mgr.interface_package(txt);
            if typ1 = plp$parser.OBJ_COLLECTION_ then
                if v_left and idx is null and j is null then
                  if inobj is null then
                    etext := objid||'.collection_id';
                  else
                    db_update := true;
                    v_left:= false;
                    if obj then
                      qual := 'rtl.set_object';
                    else
                      qual := qual||'.set';
                    end if;
                    if v_setidx is null then
                      etext := p_rvalue;
                    else
                      etext := temp_vars(v_setidx).text4;
                    end if;
                    etext := qual||'_collection('||objid||','||etext||')';
                    if inobj then
                      lock_this:= true;
                      this_chg := true;
                    end if;
                  end if;
                elsif not j is null and i<>p_idx and bitand(typ,8)=0 then
                    attr_index;
                else
                    if bitand(typ,8)>0 then
                      get_index;
                      if not p_bool then
                        ptext := ', key_ => '||substr(itext,2);
                      else
                        ptext := itext;
                      end if;
                    end if;
                    if obj_coll then
                        etext := objid;
                    elsif inobj is null then
                        etext := objid||'.collection_id';
                    elsif inobj and cache_obj and plib.g_optim_this then
                        obj_chg('.collection_id');
                    else
                        if obj then
                            qual := 'rtl';
                            ptext:= null;
                        end if;
                        if chk_key then check_part_key(txt); end if;
                        etext := qual||'.get_object('||objid||ptext||').collection_id';
                    end if;
                    objid := null; qual := null;
                    exit when not j is null and bitand(typ,8)=0;
                end if;
            elsif typ1 in (plp$parser.OBJ_STATE_,plp$parser.STRING_) then
                if v_left then
                  if inobj is null then
                    etext := objid||'.state_id';
                  else
                    if obj then
                      qual := 'rtl';
                    end if;
                    db_update := true;
                    get_index;
                    if v_setidx is null then
                      etext := p_rvalue;
                    else
                      etext := temp_vars(v_setidx).text4;
                    end if;
                    if not obj and itext is null then
                      typ := plib.parent(v_idx);
                      if typ is not null and plib.ir(typ).type = plp$parser.ASSIGN_ and plib.ir(typ).type1 = plp$parser.UPDATE_ then -- assignment from update
                        v_left := false;
                      end if;
                    end if;
                    if v_left then
                      etext := qual||'.change_state('||objid||','||etext||itext||')';
                    else
                      etext := qual||'.set_state('||objid||','||etext||itext||')';
                    end if;
                    v_left:= false;
                    if inobj then
                      if plib.g_optim_this then
                        this_mtd := true;
                        if this_upd then
                          put_set_this(p_prog,p_mgn);
                        end if;
                      end if;
                      lock_this:= true;
                      this_chg := true;
                    end if;
                  end if;
                else
                  if not j is null then
                    get_index;
                    if not p_bool then
                      ptext := ', key_ => '||substr(itext,2);
                    else
                      ptext := itext;
                    end if;
                  end if;
                  if obj then
                    qual := 'rtl';
                    ptext:= null;
                  end if;
                  obj := inobj and cache_obj and plib.g_optim_this;
                  if obj then
                    obj_chg('.state_id');
                  elsif inobj is null then
                    etext := objid||'.state_id';
                  else
                    if chk_key then check_part_key(txt); end if;
                    etext := qual||'.get_object('||objid||ptext||').state_id';
                  end if;
                  if typ1=plp$parser.STRING_ then
                    itext := etext;
                    if obj then
                      obj_chg('.class_id');
                    elsif inobj is null then
                      etext := objid||'.class_id';
                    else
                      etext := qual||'.get_object('||objid||ptext||').class_id';
                    end if;
                    etext := 'lib.state_name('||itext||','||etext||')';
                  end if;
                end if;
                objid := null;
            elsif typ1 in (plp$parser.OBJ_CLASS_,plp$parser.OBJ_CLASS_PARENT_,plp$parser.OBJ_CLASS_ENTITY_,plp$parser.STRING_CONST_) then
                if bitand(typ,8)>0 then
                  get_index;
                  if not p_bool then
                    ptext := ', key_ => '||substr(itext,2);
                  else
                    ptext := itext;
                  end if;
                end if;
                j := typ mod 4;
                if inobj and cache_obj and plib.g_optim_this then
                  if j=1 or j<>2 and cache_class then
                    etext := var_obj_class;
                    chk_var := null;
                  else
                    obj_chg('.class_id');
                  end if;
                elsif new_class then
                    etext := ''''||ocls||'''';
                    --etext := objid;
                    v_calc:= false;
                elsif inobj is null then
                    etext := objid||'.class_id';
                elsif obj then
                    etext := 'rtl.object_class('||objid||')';
                else
                  if chk_key then check_part_key(txt); end if;
                  if j=2 then
                    etext := qual||'.get_object('||objid||ptext||').class_id';
                  else
                    etext := qual||'.class$('||objid||',false'||ptext||')';
                    if lib.class_exist(txt,class_info) then
                      if substr(class_info.flags,13,1)='0' then
                        plib.plp_warning(i,'CLASS_HAS_NO_CHILDS',txt);
                      end if;
                    end if;
                  end if;
                end if;
                if typ1 = plp$parser.OBJ_CLASS_PARENT_ then
                    v_calc:= p_calc;
                    etext := 'rtl.class_parent('||etext||')';
                elsif typ1 = plp$parser.OBJ_CLASS_ENTITY_ then
                    v_calc:= p_calc;
                    etext := 'rtl.class_entity('||etext||')';
                elsif typ1 = plp$parser.STRING_CONST_ then
                    v_calc:= p_calc;
                    etext := 'lib.class_name('||etext||')';
                end if;
                objid := null;
            elsif typ1 in (plp$parser.OBJ_PARENT_,plp$parser.OBJECT_REF_,plp$parser.DBCLASS_,plp$parser.CLASS_REF_) then
                if typ1 in (plp$parser.OBJ_PARENT_,plp$parser.DBCLASS_) then
                    if obj then
                        qual := 'rtl';
                        ptext:= null;
                    end if;
                    if inobj and cache_obj and plib.g_optim_this then
                        obj_chg('.collection_id');
                    elsif inobj is null then
                        etext := objid||'.collection_id';
                    else
                        if chk_key then check_part_key(txt); end if;
                        etext := qual||'.get_object('||objid||ptext||').collection_id';
                    end if;
                    ptext := prt;
                else
                    etext := objid;
                    txt := ocls;
                    obj := txt=constant.OBJECT;
                    if obj then
                        qual := 'rtl';
                    else
                        qual := class_mgr.interface_package(txt);
                    end if;
                end if;
                if obj then
                    ptext:= null;
                end if;
                etext := qual||'.get_parent('||etext||ptext;
                if typ1 in (plp$parser.OBJ_PARENT_,plp$parser.OBJECT_REF_) then
                    etext := etext||').id';
                    objid := etext;
                    ptext := prt;
                else
                    etext := etext||').class_id';
                    objid := null;
                end if;
                txt1 := substr(txt1,instr(txt1,'.',-1)+1);
            elsif typ1 = plp$parser.RTL_ then
                db_update := true;
                get_index;
                if typ=16 then
                  etext := qual||'.lock$tbl(';
                  ptext := null;
                  inobj := false;
                  new_class := false;
                else
                  if obj then
                    qual := 'rtl';
                    ptext:= null;
                  end if;
                  if (typ mod 4) = 1 then
                    etext := qual||'.lock_object_wait(';
                  else
                    etext := qual||'.lock_object(';
                  end if;
                  if bitand(typ,8)>0 then
                    ptext := null;
                  end if;
                end if;
                if new_class then
                  objid := rtl.bool_char(lib.has_stringkey(txt), '''0''', '0');
                elsif inobj is null then
                  objid := objid||'.id';
                end if;
                if itext is null then
                  itext := ','||linfo_txt;
                  if new_class then
                    itext := itext||','''||ocls||'''';
                  end if;
                else
                  itext := replace(itext,'''<LOCK$INFO>''',linfo_txt);
                end if;
                if chk_key then check_part_key(txt); end if;
                etext := etext||objid||itext||ptext||')';
                objid := null; txt1 := null;
            elsif typ1 = plp$parser.SOS_ then
                if not obj_coll then
                    objid := NULL_CONST;
                end if;
                get_index;
                if obj then
                  etext := 'lib.c_count('||objid||')';
                else
                  if typ=0 then
                    ptext := null;
                  end if;
                  if chk_key then check_part_key(txt); end if;
                  etext := qual||'.count$('||objid||itext||ptext||')';
                end if;
                objid := null;
            elsif typ1 = plp$parser.OBJ_INIT_ then
                v_expr := null;
                if plib.pop_expr_info(i,v_expr) then
                  plib.put_expr_info(i,v_expr);
                end if;
                ocls := null;
                get_index(false,objid);
                --get_index;
                if typ between 1 and 4 then
                  --itext := ',true'||itext;
                  if typ in (2,4) then
                    db_update := true;
                  end if;
                  if typ<3 then
                    if chk_key then check_part_key(txt); end if;
                    itext := itext||ptext;
                  end if;
                end if;
                --etext := qual||'.'||txt1||'('||objid||itext||')';
                etext := qual||'.'||txt1||'('||itext||')';
                if not eprog is null then setparam; end if;
                objid := null; txt1 := null;
            elsif typ1 = plp$parser.DELETE_ then
                db_update := true;
                if obj_coll then
                    obj := ocls=constant.OBJECT;
                    etext := 'method_mgr.delete_collection('||objid;
                    if obj then
                        etext := etext||')';
                    else
                        etext := etext||','''||ocls||''')';
                    end if;
                else
                  get_index;
                  if typ=16 then
                    if not itext is null then
                      itext := ',null'||itext;
                    end if;
                    etext := qual||'.delete$tbl('||objid||itext||')';
                  else
                    if inobj is null then
                      objid := objid||'.id';
                    end if;
                    if not itext is null then
                      ptext := ', key_ => '||substr(itext,2);
                    end if;
                    if obj then
                      etext := 'rtl.destructor('||objid||')';
                    else
                      if chk_key then check_part_key(txt); end if;
                      etext := qual||'.delete('||objid||ptext||')';
                    end if;
                  end if;
                end if;
                objid := null; txt1 := null;
            elsif typ1 = plp$parser.VAR_ then
                db_update := true;
                if inobj is null then
                  objid := objid||'.id';
                end if;
                if obj then
                  qual := 'rtl';
                end if;
                etext := qual||'.write2log('||objid||')';
                objid := null; txt1 := null;
            elsif typ1 = plp$parser.ATTR_ then
              if v_left then
                get_index;
                if v_setidx is null then
                  etext := p_rvalue;
                else
                  etext := temp_vars(v_setidx).text4;
                end if;
                etext := qual||'.set$key('||etext||itext||')';
                v_left:= false;
              else
                if new_class then
                    etext := 'valmgr.get_key('''||ocls||''')';
                else
                    if inobj is null then
                      objid := objid||'.id';
                    end if;
                    etext := qual||'.key$('||objid||')';
                end if;
              end if;
              objid := null; ok:=false;
            elsif typ1 = plp$parser.TEXT_ then
                get_index;
                if bitand(typ,8)>0 then
                  ptext := null;
                end if;
                if itext is null then
                  if new_class then
                    itext := ','''||ocls||''',';
                  else
                    itext := ',null,';
                  end if;
                  itext := itext||linfo_txt;
                else
                  itext := replace(itext,'''<LOCK$INFO>''',linfo_txt);
                end if;
                if inobj is null then
                  objid := objid||'.id';
                end if;
                if obj then
                  qual := 'rtl';
                  ptext:= null;
                end if;
                if chk_key then check_part_key(txt); end if;
                etext := qual||'.request_lock('||objid||itext||ptext||')';
                objid := null;
            elsif typ1 = plp$parser.NUMBER_ then
                get_index;
                if bitand(typ,8)>0 then
                  ptext := null;
                end if;
                if itext is null then
                  itext := ',null';
                end if;
                if inobj is null then
                  objid := objid||'.id';
                end if;
                if obj then
                  etext := 'rtl.object_scn('||objid||itext||')';
                else
                  if chk_key then check_part_key(txt); end if;
                  etext := qual||'.scn$('||objid||itext||ptext||')';
                end if;
                objid := null;
            elsif typ1 = plp$parser.LOCK_ then
                get_index;
                if bitand(typ,8)>0 then
                  ptext := null;
                end if;
                if itext is null then
                  itext := ',null';
                end if;
                if inobj is null then
                  objid := objid||'.id';
                end if;
                if obj then
                  qual := 'rtl';
                  ptext:= null;
                end if;
                if chk_key then check_part_key(txt); end if;
                etext := qual||'.check_lock('||objid||itext||ptext||')';
                objid := null; txt1 := null;
            elsif typ1 = plp$parser.MODIFIER_ then
                get_index;
                if bitand(typ,8)>0 then
                  ptext := null;
                end if;
                etext := '.get$value(';
                if new_class then
                    objid := 'valmgr.static('''||ocls||''')';
                elsif inobj is null then
                    etext := '.get$rec_value(';
                end if;
                if chk_key then check_part_key(txt); end if;
                if v_left then
                  if v_setidx is null then
                    itext := replace(itext,'''<SET$VALUE>''',p_rvalue);
                  else
                    itext := replace(itext,'''<SET$VALUE>''',temp_vars(v_setidx).text4);
                  end if;
                  etext := '.s'||substr(etext,3);
                  if new_class or inobj is not null then
                    db_update := true;
                  end if;
                  v_left := false;
                end if;
                etext := qual||etext||objid||itext||ptext||')';
                objid := null;
            elsif typ1 in (plp$parser.REF_,plp$parser.DBOBJECT_) then
                get_index;
                if inobj is null then
                  objid := objid||'.id';
                end if;
                itext := objid||itext;
                if typ1=plp$parser.DBOBJECT_ then
                  itext := 'obj_accessible('||itext;
                else
                  itext := 'ref_accessible('||replace(itext,'''<REF$CLASS>''',''''||ocls||'''');
                end if;
                etext := '(security.'||itext||',''0'')=''1'')';
                objid := null;
            elsif typ1 = plp$parser.COLLECTION_ then
                get_index;
                if inobj is null then
                  objid := objid||'.collection_id';
                end if;
                etext := qual||'.get_col$tbl('||substr(itext,2)||','||objid||')';
                objid := null;
            elsif typ1 in (plp$parser.ASSIGN_,plp$parser.NULL_) then
                db_update := true;
                get_index;
                if typ1=plp$parser.ASSIGN_ then
                  etext := '.log$vals(';
                else
                  etext := '.del_vals(';
                end if;
                etext := qual||etext||substr(itext,2)||')';
                objid := null; txt1 := null;
            elsif typ1 in (plp$parser.COLL_,plp$parser.ANY_) then
                get_index;
                if inobj is null then
                  objid := objid||'.id';
                end if;
                itext := objid||itext;
                if typ1=plp$parser.COLL_ then
                  etext := '.get$vals(';
                else
                  etext := '.get_arch(';
                end if;
                etext := qual||etext||itext||')';
                objid := null;
            elsif typ1 = plp$parser.IS_ then
                get_index;
                if inobj is null then
                  objid := objid||'.id';
                end if;
                if itext is null then
                  plib.plp_error(i, 'TYPE_WRONG', '%arch');
                end if;
                etext := qual||'.get$arch('||objid||itext||')';
                objid := null; txt1 := null; dot := '.';
            elsif typ1 = plp$parser.VARMETH_ then
                get_index;
                if itext is null then
                  plib.plp_error(i, 'TYPE_WRONG', '%compare');
                end if;
                etext := qual||'.cmp$struc('||objid||itext||')';
                objid := null;
            end if;
          end if;
        end if;
        ocls  := txt1;
        inobj := false;
        new_class:= false;
        obj_coll := false;
        qual := NULL;
      elsif typ = plp$parser.TEXT_ then
        ok:=false;
        if typ1<0 then
            typ1:= -typ1;
            ok  := c_check;
            v_calc := false;
        elsif j is null and c_check and self_calc
          and typ1=plp$parser.REF_ and ascii(txt)=ascii('''') then
            ok:= txt1=SYS;
        end if;
        etext:= txt;
        objid:= txt;
        ocls := txt1;
      else
        plib.plp_error(i, 'IR_UNEXPECTED', 'var2plsql', plib.type_name(typ), i);
      end if;
      exit when idx is NULL;
      i := idx;
    end loop;
    if expand and txt1 is not null then
        if lib.class_exist(txt1,class_info) then
            if expand1 and class_info.base_id=constant.REFERENCE then
                objthis;
                if objid is null then
                    objid := etext||qual;
                else
                    if chk_key then check_part_key(ocls); end if;
                    if obj_lock then objlock(ocls,ref_idx); end if;
                    --objid:= class_mgr.interface_package(ocls)||'.get_ref('||objid||','''||nvl(qual,' ')||''''||ptext||')';
                    objid := get_iface_call(c_type,objid,ocls,qual,null,plp$parser.REF_,false)||ptext||')';
                end if;
                txt1 := class_info.class_ref;
                new_class:=lib.class_exist(txt1,class_info);
                ptext:= prt;
            elsif qual is null then
                objthis(v_left,this_var);
            else
                objthis;
                if objid is null then
                    objid := etext||qual;
                else
                    if chk_key then check_part_key(ocls); end if;
                    if obj_lock then objlock(ocls,ref_idx); end if;
                    --objid:= class_mgr.interface_package(ocls)||'.get_ref('||objid||','''||qual||''''||ptext||')';
                    objid := get_iface_call(c_type,objid,ocls,qual,null,plp$parser.REF_,false)||ptext||')';
                end if;
                ptext:= prt;
            end if;
            typ1 := plib.convert_base(class_info.base_id);
            qual := NULL;
            ocls := txt1;
        else
            plib.plp_error( i, 'CLASS_NOT_FOUND',txt1 );
        end if;
    elsif inobj then
        objthis(v_left);
    else
        objid := null;
    end if;
    if v_left then
      if v_setidx is null then
        eprog := p_rvalue;
      else
        eprog := temp_vars(v_setidx).text4;
      end if;
    else
      eprog := null;
    end if;
    if objid is null then
        etext := etext||qual;
        if v_left then
          if etext=eprog then
            etext := NULL_CONST;
          else
            if is_method and etext=new_this then
              plib.plp_warning(v_idx,'ASSIGN_ERROR',etext,eprog);
              if this_upd then
                  put_set_this(p_prog,p_mgn);
              end if;
              this_mtd := true;
              this_chg := true;
            end if;
            if v_assign then
              etext := etext||' := '||eprog;
            end if;
          end if;
        end if;
    else
        if obj_lock then objlock(ocls,ref_idx); end if;
        if typ1 = plp$parser.RECORD_ then
            if ocls=constant.OBJECT then
                p_text := p_text||'rtl.get_object('||objid||')';
                if v_left then
                    plib.plp_error(v_idx,'NOT_LVALUE',ocls);
                end if;
                return false;
            end if;
            etext := get_iface_call(c_type,objid,ocls,qual,txt1,typ1,v_left);
            c_check := false;
        else
            if add_tmp or v_left then
              c_check := false;
            else
              c_check := c_check and ok and v_calc and plib.g_calc_attr;
              if c_check then
                c_type := null;
              end if;
            end if;
            etext := get_iface_call(c_type,objid,ocls,qual,txt1,typ1,v_left);
            c_check := c_check and c_type is not null;
        end if;
        if chk_key then check_part_key(ocls); end if;
        if v_left then
            db_update := true;
            if c_check and self_calc then
              if ocls=SYS then
                plib.plp_error(v_idx,'NOT_LVALUE',ocls);
              end if;
            end if;
            etext := etext||','||eprog||ptext||')';
            c_check := false;
            if is_method and objid=new_this and qual=plib.g_class_key then
              plib.plp_warning(v_idx,'ASSIGN_ERROR',objid,eprog);
              if this_upd then
                put_set_this(p_prog,p_mgn);
              end if;
              this_mtd := true;
              this_chg := true;
              etext := etext||';'||NL||p_mgn||new_this||' := '||eprog;
            end if;
        else
            etext := etext||ptext||')';
        end if;
    end if;
    if add_tmp then
        tmp_expr_idx := nvl(tmp_expr_idx,0) + 1;
        ok := FALSE;
    else
        ok := ok and c_check;
    end if;
    if ok and v_calc then
      itext:=etext;
      begin
        if v_exec is null then
          etext:=rtl.calculate(itext,c_type,true);
          ok := etext<>itext;
        else
          execute immediate 'BEGIN :RESULT:='||itext||'; END;' using out etext;
          if v_exec then
            etext := ''''||replace(etext,'''','''''')||'''';
          end if;
        end if;
      exception
        when others then
          if sqlcode in (-4061,-6508) then
            rtl.debug( 'var2plsql: '||sqlerrm||':'||NL||itext,1,false,null);
            raise;
          end if;
          plib.plp_error( p_idx, 'PARSER_ERROR', sqlerrm, is_error => plib.g_calc_expr );
          ok := false;
          etext := itext;
      end;
    end if;
    p_text:=p_text||etext;
    return ok;
end var2plsql;
--
function get_bool_const(p_value varchar2,p_bool boolean) return pls_integer is
begin
  if p_value = TRUE_CONST then
    return 1;
  elsif p_value = FALSE_CONST then
    return -1;
  elsif p_value = NULL_CONST then
    return 0;
  end if;
  if p_bool then
    if p_value = '('''||constant.YES||''''||YESSTR then
      return 1;
    elsif p_value = '('''||constant.NO||''''||YESSTR then
      return -1;
    elsif p_value = '(null'||YESSTR then
      return 0;
    end if;
  elsif p_bool is null then
    if p_value = ''''||constant.YES||'''' then
      return 1;
    elsif p_value = ''''||constant.NO||'''' then
      return -1;
    end if;
  end if;
  return null;
end;
--
function set_bool_const(p_value pls_integer) return varchar2 is
begin
  if p_value > 0 then
    return TRUE_CONST;
  elsif p_value < 0 then
    return FALSE_CONST;
  end if;
  return NULL_CONST;
end;
--
-- @METAGS expr2plsql
function  expr2plsql ( p_idx   IN     pls_integer,
                       p_decl  in out nocopy varchar2,
                       p_prog  in out nocopy varchar2,
                       p_text  in out nocopy varchar2,
                       p_mgn   IN     varchar2 default NULL,
                       p_wipe  IN     boolean  default FALSE,
                       p_calc  IN     boolean  default TRUE,
                       p_bool  IN     boolean  default FALSE
                     ) return boolean is
    idx    pls_integer := p_idx;
    down   pls_integer;
    typ    pls_integer;
    typ1   pls_integer;
    lp     varchar2(1);
    rp     varchar2(1);
    eprog  varchar2(32767);
    etext  varchar2(32767);
    txtbuf varchar2(32767);
    txt    varchar2(2000);
    v_expr plib.expr_info_t;
    v_class plib.plp_class_t;
    ok     boolean default FALSE;
    res1   boolean;
    res2   boolean;
begin
--    rtl.debug('expr2plsql: '||plib.ns(p_idx), 8);
    if p_wipe then
        p_decl := NULL;
    end if;
    p_text := NULL;
    p_prog := NULL;
    if p_idx is NULL then
        return FALSE;
    end if;
    if plib.g_parse_java or p_bool then
      if plib.pop_expr_info(p_idx,v_expr) then
        ok := plib.get_expr_type(p_idx,v_class);
        ok := expr2plsql(p_idx,p_decl,p_prog,p_text,p_mgn,false,p_calc,p_bool);
        plib.put_expr_info(p_idx,v_expr);
        if v_expr.conv_in > 0 then
          p_text := plib.ir(v_expr.conv_in).text||'('||p_text||')';
        elsif v_expr.compatible = 2 then
          if p_bool then
            conv_boolean(p_idx,p_text);
          elsif not p_bool and v_class.base_type = plp$parser.BOOLEAN_  then
            p_text := 'rtl.char_bool('||p_text||')';
          end if;
        end if;
        return ok;
      end if;
    end if;
    typ  := plib.ir(p_idx).type;
--    rtl.debug('expr2plsql: '||plib.type_name(typ)||' '||plib.type_name(typ1), 8);
    if typ in (
        plp$parser.ATTR_,
        plp$parser.METHOD_,
        plp$parser.RTL_,
        plp$parser.VARMETH_,
        plp$parser.ID_,
        plp$parser.DBCLASS_,
        plp$parser.UNKNOWN_
    ) then
        if use_counters then inc_counter(plp$parser.VAR_); end if;
        return var2plsql( p_idx, p_decl, p_prog, p_text, NULL, p_mgn, p_calc,p_bool );
    end if;
    typ1 := plib.ir(p_idx).type1;
    down := plib.ir(p_idx).down;
    txt  := plib.ir(p_idx).text;
    if plib.ir(p_idx).text1 = 'P' then
        lp := '(';
        rp := ')';
    end if;
    if typ in(plp$parser.BOOLEAN_,plp$parser.EXCEPTION_) then
        if typ1 = plp$parser.CONSTANT_ then
            if use_counters then inc_counter(typ1); end if;
            p_text := txt;
            ok:=TRUE;
        elsif typ1 in (plp$parser.SELECT_,plp$parser.EXISTS_) then
            if use_counters then inc_counter(typ1); end if;
            idx := query2plsql(down,p_decl,p_prog,etext,typ,false,plib.nn(SP,plib.get_comments(down)),length(p_mgn));
            if typ1=plp$parser.SELECT_ then
                idx := plib.ir(down).right;
                res2:= false;
                loop
                    res1:= expr2plsql(idx,p_decl,eprog,txtbuf,p_mgn,false,p_calc,p_bool);
                    p_prog := p_prog||eprog;
                    if res2 then
                        p_text := p_text||','||txtbuf;
                    else
                        p_text := txtbuf;
                    end if;
                    idx := plib.ir(idx).right;
                    exit when idx is null;
                    res2:= true;
                end loop;
                if res2 then
                    p_text:= '('||p_text||')';
                end if;
            end if;
            p_text := lp||p_text||' '||txt||' ('||NL||etext||NL||p_mgn||TAB||')'||rp;
        else
            if use_counters then inc_counter(typ); end if;
            res2:=plib.ir(down).right is NULL;
            res1:=expr2plsql( down, p_decl, eprog, etext,p_mgn,false,p_calc /*and not res2*/,p_bool);
            p_prog := p_prog||eprog;
            if res2 then
                if typ1=plp$parser.NULL_ then
                  if res1 and etext in (NULL_CONST,NULL_STRING) then
                    if txt = plib.IS_NOT_NULL then
                      typ := -1;
                    else
                      typ := 1;
                    end if;
                    ok := null;
                  else
                    p_text := lp||etext||' '||txt||rp;
                  end if;
                elsif typ1 = plp$parser.NOT_ then
                  if res1 then
                    typ := get_bool_const(etext,p_bool);
                    if typ is not null then
                      typ:= -sign(typ);
                      ok := null;
                    end if;
                  end if;
                  if not ok then
                    if p_bool then
                        typ := length(etext)-6;
                        if typ>0 and instr(substr(etext,1,typ-1),SP)>0 then
                            typ := 0;
                        end if;
                        if typ>0 and instr(etext,YESSTR)=typ then
                            etext := substr(etext,1,typ-1)||NOTSTR;
                        elsif typ>0 and instr(etext,NOTSTR)=typ then
                            etext := substr(etext,1,typ-1)||YESSTR;
                        else
                            etext := lp||txt||' '||etext||rp;
                        end if;
                    else
                        etext := lp||txt||' '||etext||rp;
                    end if;
                    p_text := etext;
                  end if;
                elsif typ1 = plp$parser.NUMBER_ then
                  if res1 then
                    if etext in (NULL_CONST,NULL_STRING) then
                      typ := 0;
                    elsif etext like '%nan' and txt like '%NAN' then
                      typ := 1;
                    elsif etext like '%infinity' and txt like '%INFINITE' then
                      typ := 1;
                    else
                      typ := -1;
                    end if;
                    if instr(txt,'not') > 0 then
                      typ := -typ;
                    end if;
                    ok := null;
                  end if;
                  if not ok then
                    p_text := lp||etext||' '||txt||rp;
                  end if;
                elsif typ1 = plp$parser.COLLECTION_ then
                    p_text := lp||etext||' '||txt||rp;
                end if;
            else
                idx := down;
                down:= plib.ir(idx).right;
                if typ1=plp$parser.IN_ then
                    p_text := lp||etext||SP||txt||' ';
                    res2:=res1;
                    p_text:=p_text||'(';
                    loop
                        res2:=expr2plsql( down, p_decl, eprog, etext,p_mgn,false,p_calc /*and not res2*/,p_bool) and res2;
                        p_prog:=p_prog||eprog;
                        p_text:=p_text||etext;
                        down:=plib.ir(down).right;
                        exit when down is null;
                        p_text:=p_text||',';
                    end loop;
                    p_text:=p_text||')'||rp;
                elsif typ1=plp$parser.LIKE_ then
                    res2:=expr2plsql( down, p_decl, eprog, txtbuf,p_mgn,false,p_calc /*and not res1*/,p_bool);
                    p_prog := p_prog||eprog;
                    down:=plib.ir(down).right;
                    if down is null and (res1 or res2) then
                      if res1 and etext in (NULL_CONST,NULL_STRING) or res2 and txtbuf in (NULL_CONST,NULL_STRING) then
                        typ:= 0;
                        ok := null;
                      end if;
                    end if;
                    if not ok then
                      p_text := lp||etext||SP||txt||SP||txtbuf;
                      if not down is null then
                        res2:=expr2plsql( down, p_decl, eprog, etext,p_mgn,false,p_calc /*and not res2*/,p_bool) and res2;
                        p_prog := p_prog||eprog;
                        p_text := p_text||' escape '||etext;
                      end if;
                      p_text:=p_text||rp;
                    end if;
                else
                  res2:=expr2plsql( down, p_decl, eprog, txtbuf,p_mgn,false,p_calc /*and not res1*/,p_bool);
                  if typ1 in (plp$parser.AND_, plp$parser.OR_) then
                    ok := typ1 = plp$parser.AND_;
                    if res1 then
                      typ := get_bool_const(etext,p_bool);
                    end if;
                    if res2 then
                      typ1:= get_bool_const(txtbuf,p_bool);
                    end if;
                    if res1 and typ is not null then
                      if ok and typ < 0 or not ok and typ > 0 then
                        ok := null;
                        if eprog is not null and instr(eprog,'Get$Obj') = 0 and instr(eprog,'Set$Obj$') = 0 then
                          eprog := null;
                        end if;
                      elsif res2 and typ1 is not null then
                        if ok and (typ1 < 0 or typ > 0) or not ok and (typ1 > 0 or typ < 0) then
                          typ:= typ1;
                        end if;
                        ok := null;
                      elsif ok and typ > 0 or not ok and typ < 0 then
                        etext := null;
                      end if;
                    elsif res2 and typ1 is not null then
                      if ok and typ1 < 0 or not ok and typ1 > 0 then
                        typ:= typ1;
                        ok := null;
                      elsif ok and typ1 > 0 or not ok and typ1 < 0 then
                        txtbuf := null;
                      end if;
                    end if;
                    if ok is null then
                      p_prog := p_prog||eprog;
                    else
                      if eprog is not null then
                        if not p_bool and etext is not null and instr(eprog,'Get$Obj') = 0 and instr(eprog,'Set$Obj$') = 0 then
                          if not res1 and not is_variable(idx) then
                            if tmpvar(tmp_sos_idx,'BOOL','boolean',tmp_expr_idx) then
                              p_decl := p_mgn||lasttmp||TAB||'boolean;'||NL||p_decl;
                            end if;
                            tmp_expr_idx := nvl(tmp_expr_idx,0) + 1;
                            p_prog := p_prog||p_mgn||lasttmp||' := '||etext||';'||NL;
                            etext := lasttmp;
                          end if;
                          if ok then
                            p_prog := p_prog||p_mgn||'if nvl('||etext||',true) then'||NL||eprog||p_mgn||'end if;'||NL;
                          else
                            p_prog := p_prog||p_mgn||'if not nvl('||etext||',false) then'||NL||eprog||p_mgn||'end if;'||NL;
                          end if;
                        else
                          p_prog := p_prog||eprog;
                        end if;
                      end if;
                      if etext is null then
                        p_text := lp||txtbuf||rp;
                      elsif txtbuf is null then
                        p_text := lp||etext||rp;
                      else
                        p_text := lp||etext||SP||txt||SP||txtbuf||rp;
                      end if;
                      ok := false;
                    end if;
                  else    -- relational
                    p_prog := p_prog||eprog;
                    if res1 and etext in (NULL_CONST,NULL_STRING) or res2 and txtbuf in (NULL_CONST,NULL_STRING) then
                      typ:= 0;
                      ok := null;
                    else
                      p_text := lp||etext||SP||txt||SP||txtbuf||rp;
                    end if;
                  end if;
                end if;
            end if;
            if ok is null then
              p_text := set_bool_const(typ);
              ok := true;
            elsif res1 and res2 then
              if p_calc then
                p_text := rtl.calculate(p_text,rtl.BOOLEAN_EXPR,true);
              end if;
              ok := true;
            end if;
        end if;
        if ok and nvl(p_bool,true) then
          typ := get_bool_const(p_text,false);
          if typ is not null then
            if typ > 0 then
                p_text := ''''||constant.YES||'''';
            elsif typ < 0 then
                p_text := ''''||constant.NO||'''';
            end if;
            if p_bool then
                conv_boolean(p_idx,p_text);
            end if;
          end if;
        end if;
    elsif typ = plp$parser.STRING_ then
        if typ1 = plp$parser.CONSTANT_ then
            if use_counters then inc_counter(typ1); end if;
            if txt is null then
              p_text := NULL_STRING;
            else
              p_text := ''''||replace(txt,'''','''''')||'''';
            end if;
            ok:=TRUE;
        else
            if use_counters then inc_counter(typ); end if;
            res1:=expr2plsql( down, p_decl, eprog, etext,p_mgn,false,p_calc,p_bool);
            p_prog := p_prog||eprog;
            if res1 and etext in (NULL_CONST,NULL_STRING) then
              p_text := null;
            else
              p_text := etext;
            end if;
            res2:=expr2plsql( plib.ir(down).right, p_decl, eprog, etext,p_mgn,false,p_calc/* and not res1*/,p_bool);
            p_prog := p_prog||eprog;
            if res2 and etext in (NULL_CONST,NULL_STRING) then
              if p_text is null then
                ok := true;
                p_text := etext;
              else
                ok := null;
              end if;
            elsif p_text is null then
              p_text := etext;
              down := plib.ir(down).right;
              ok := null;
            else
              p_text := p_text||txt||etext;
            end if;
            if ok is null then
              plib.expr_class(down,v_class);
              if v_class.is_reference and not v_class.kernel or not v_class.is_reference and v_class.base_type not in (plp$parser.STRING_,plp$parser.MEMO_) then
                p_text := 'to_char('||p_text||')';
              end if;
              ok := false;
            end if;
            if not ok then
              if res1 and res2 then
                if p_calc then
                    p_text:=rtl.calculate(p_text,rtl.STRING_EXPR,true);
                end if;
                ok:=TRUE;
              elsif lp is not null then
                  p_text := lp||p_text||rp;
              end if;
            end if;
        end if;
    elsif typ=plp$parser.NUMBER_ or typ1 in (plp$parser.NUMLOW_,plp$parser.NUMHIGH_)
      and typ in (plp$parser.DATE_,plp$parser.TIMESTAMP_,plp$parser.INTERVAL_,plp$parser.NULL_) then
        if typ1 = plp$parser.CONSTANT_ then
            if use_counters then inc_counter(typ1); end if;
            p_text := txt;
            ok:=TRUE;
        else
            if use_counters then inc_counter(typ); end if;
            res2:=plib.ir(down).right is NULL;
            res1:=expr2plsql( down, p_decl, eprog, etext,p_mgn,false,p_calc /*and not res2*/,p_bool);
            p_prog := p_prog||eprog;
            if res1 and etext = NULL_CONST then
              ok := true;
              p_text := etext;
            elsif res2 then
              if txt in ('+','-') then
                lp := '('; rp := ')';
              end if;
              p_text := lp||txt||etext||rp;
            else
              res2:=expr2plsql( plib.ir(down).right, p_decl, eprog, txtbuf,p_mgn,false,p_calc /*and not res1*/,p_bool);
              p_prog := p_prog||eprog;
              if res2 and txtbuf = NULL_CONST then
                ok := true;
                p_text := txtbuf;
              else
                p_text := lp||etext||txt||txtbuf||rp;
              end if;
            end if;
            if not ok then
              if res1 and res2 then
                if p_calc then
                    p_text:=rtl.calculate(p_text,rtl.NUMBER_EXPR,true);
                    if p_text like '-%' then
                      p_text := '('||p_text||')';
                    end if;
                end if;
                ok:=TRUE;
              end if;
            end if;
        end if;
    elsif typ = plp$parser.TEXT_ then
        if use_counters then inc_counter(typ); end if;
        p_text := txt;
        if p_bool and abs(typ1) = plp$parser.BOOLEAN_ then
            conv_boolean(p_idx,p_text);
        end if;
    elsif typ = plp$parser.NULL_ then
      if use_counters then inc_counter(typ); end if;
      if typ1=plp$parser.TEXT_ then
        p_text := plib.ir(p_idx).text1;
      else
        typ1 := plib.ir(p_idx).node;
        if typ1<0 then
            if typ1=-1 then
                typ := txt;
                etext := plsql_type(typ);
                if plib.ir(typ).text1 is null and instr(etext,'.')=0 then
                  typ1:= plib.find_left(p_idx,plp$parser.DECLARE_);
                  if not typ1 is null then
                    idx := plib.parent(typ1);
                    if idx is not null and plib.ir(idx).type = plp$parser.FUNCTION_ then
                      typ1 := plib.parent(idx);
                    end if;
                    if typ1 is not null and typ1 = plib.parent(typ) then
                      ok := null;
                    end if;
                  end if;
                end if;
            else
                etext := class2plsql(txt,true,idx);
            end if;
            if tmpvar(tmp_sos_idx,'NULL',etext,tmp_expr_idx) then
                p_decl := p_mgn||lasttmp||TAB||etext||';'||NL||p_decl;
                if ok is null then
                  p_decl := p_mgn||'type'||TAB||etext||';'||NL||p_decl;
                end if;
                ok:=TRUE;
            end if;
            txt := 'Clear$'||lasttmp;
            if ok or instr(p_decl,'procedure '||txt)=0 then
                p_decl := p_decl||p_mgn||'procedure '||txt
                    ||' is var$ '||etext||'; begin '||lasttmp||':=var$; end;'||NL;
            end if;
            p_prog := p_prog||p_mgn||txt||';'||NL;
            p_text := lasttmp;
            tmp_expr_idx := nvl(tmp_expr_idx,0) + 1;
            ok:=FALSE;
        else
            p_text := NULL_CONST;
            ok:=TRUE;
        end if;
      end if;
    elsif typ = plp$parser.PRIOR_ then
      if use_counters then inc_counter(typ); end if;
      if typ1=plp$parser.VARMETH_ then -- analytic function
        res1:= expr2plsql( down, p_decl, eprog, etext,p_mgn,false,p_calc,p_bool);
        p_prog := p_prog||eprog;
        p_text := etext;
        down:= plib.ir(down).right;
        if not down is null then
          txtbuf := plib.ir(down).text;
          typ := 0;
          idx := plib.ir(down).right;
          while not idx is null loop
            res1:= expr2plsql( idx, p_decl, eprog, etext,p_mgn,false,p_calc,p_bool);
            p_prog := p_prog||eprog;
            typ := typ+1;
            txtbuf := replace(txtbuf,'['||typ||']',etext);
            idx := plib.ir(idx).right;
          end loop;
          p_text := p_text||SP||txtbuf;
        end if;
      else
        res1 := txt is null;
        if res1 then  -- cast_to
            down := plib.ir(down).right;
        end if;
        if txt='as' then -- cast
          etext:= plsql_type(down,true,false);
          if plib.g_parse_java and nvl(p_bool,true) and ascii(etext) > ascii('Z') then  -- java type
            plib.expr_class(down,v_class);
            if v_class.is_udt and v_class.is_collection and v_class.data_size > 0 then
              plib.expr_class(v_class.elem_class_id,v_class,true,true);
              etext := nvl(plib.table_type(v_class,1,false),etext);
            end if;
          end if;
        else
          res2 := expr2plsql( down, p_decl, eprog, etext,p_mgn,false,p_calc,p_bool);
          p_prog := p_prog||eprog;
        end if;
        if res1 then -- cast_to
            p_text := lp||etext||rp;
        else
            down := plib.ir(down).right;
            if down is null then -- prior/distinct
                p_text := lp||txt||SP||etext||rp;
            else
                res1 := expr2plsql( down, p_decl, eprog, txtbuf,p_mgn,false,p_calc /*and not res2*/,p_bool);
                p_prog := p_prog||eprog;
                if txt <> SP then -- as(cast)/from(trim,extract)/at time zone(to_tz)
                  p_text := lp||txtbuf||SP||txt||SP||etext||rp;
                else -- to_interval
                  p_text := lp||txtbuf||SP||etext||rp;
                end if;
                if res1 and res2 then
                    if p_calc then
                        p_text:=rtl.calculate(p_text,nvl(chr(plib.ir(p_idx).type1),rtl.STRING_EXPR),true);
                    end if;
                    ok:=TRUE;
                end if;
            end if;
        end if;
      end if;
    elsif typ = plp$parser.CASE_ then
      declare
        v_searched  boolean := (plib.ir(down).type = plp$parser.WHEN_);   -- searched case
      begin
        if use_counters then inc_counter(typ); end if;
        p_text := lp||'case';
        res2 := true;
        while not down is null loop
            typ := plib.ir(down).type;
            if typ in (plp$parser.WHEN_,plp$parser.ELSE_) then
              idx := plib.ir(down).down;
              res1:= true;
            else
              idx := down;
              res1:= false;
            end if;
            if v_searched and p_bool is null then
            -- PLATFORM-6817: условие WHEN в searched case в sql-запросах (p_bool is null) должно компилироваться как логическое
              res2:= expr2plsql( idx, p_decl, eprog, etext,p_mgn,false,p_calc,true) and res2;
            else
              res2:= expr2plsql( idx, p_decl, eprog, etext,p_mgn,false,p_calc,p_bool) and res2;
            end if;
            p_prog:=p_prog||eprog;
            if res1 then
              if typ=plp$parser.WHEN_ then
                res2:=expr2plsql( plib.ir(idx).right, p_decl, eprog, txtbuf,p_mgn,false,p_calc,p_bool) and res2;
                p_prog:=p_prog||eprog;
                p_text:=p_text||' when '||etext||' then '||txtbuf;
              else
                p_text:=p_text||' else '||etext;
              end if;
            else
              p_text:=p_text||' '||etext;
            end if;
            down:=plib.ir(down).right;
        end loop;
        p_text:=p_text||' end'||rp;
        ok := res2;
      end;
    elsif typ = plp$parser.CURSOR_ then
        if use_counters then inc_counter(typ); end if;
        if txt='SELECT' then
            idx := query2plsql(down,p_decl,p_prog,etext,typ,false,plib.nn(SP,plib.get_comments(down)),length(p_mgn));
            txt := plib.ir(p_idx).text1;
        elsif not typ1 is null then
            typ1:= plib.ir(plib.ir(typ1).down).type1;
            idx := plib.ir(typ1).down;
            etext := plib.get_cursor(plib.ir(idx).text1);
            if etext is null then
              plib.plp_error(p_idx, 'EXTERNAL_CURSOR', plib.ir(typ1).text );
            else
              if use_context is null and plib.ir(typ1).node<>2 then
                if plib.ir(idx).node=0 then
                  if this_mtd then
                    put_get_this(p_prog,p_mgn);
                  end if;
                  obj_count := obj_count+1;
                end if;
                txt := plib.ir(typ1).text;
                if length(txt) > 23 then
                  txt := substr(txt,1,23-length(plib.ir(idx).text1))||plib.ir(idx).text1;
                end if;
                p_prog:= p_prog||p_mgn||'Cursor$'||txt||';'||NL;
              end if;
            end if;
            typ := plib.ir(idx).type1;
            txt := nvl(plib.ir(p_idx).text1,'cursor');
        end if;
        if typ>0 then
          plib.plp_error(p_idx,'CURSOR_LOCK_NOT_ALLOWED');
        end if;
        p_text := lp||txt||'('||NL||etext||NL||p_mgn||TAB||')'||rp;
    elsif typ = plp$parser.UNION_ then
        if use_counters then inc_counter(typ); end if;
        res1 := expr2plsql( down, p_decl, eprog, p_text,p_mgn,false,p_calc,p_bool);
        p_prog := p_prog||eprog;
        res2 := expr2plsql( plib.ir(down).right, p_decl, eprog, etext,p_mgn,false,p_calc,p_bool);
        p_prog := p_prog||eprog;
        p_text := p_text||SP||txt||SP||etext;
        ok := false;
    else
        plib.plp_error(p_idx, 'IR_UNEXPECTED', 'expr2plsql', plib.type_name(typ),p_idx);
    end if;
--    rtl.debug('expr2plsql: return '||p_text, 8);
    return ok and plib.g_calc_expr;
end expr2plsql;
--
-- @METAGS fill_overlapped
procedure fill_overlapped( overlapped in out nocopy plib.string_rec_tbl_t,
                           p_idx pls_integer, p_sig varchar2, p_src_sig varchar2, p_getid boolean) is
    i   pls_integer;
    lvl pls_integer;
    cnt pls_integer;
    v_class varchar2(16);
    v_sname varchar2(16);
    v_pack  varchar2(100);
    v_sig   varchar2(32767);
    v_pars  pls_integer;
    v_cnt   pls_integer;
    ok  boolean;
begin
    cnt := 0;
    overlapped.delete;
    for c in (
               select  /*+ INDEX(class_relations unq_cls_rel_prnt_dist_child) */
                     child_id, distance
                from class_relations
               where parent_id = plib.g_class_id and distance>0
               order by distance
             )
    loop
        v_class := c.child_id;
        lvl := c.distance; ok := false;
        if plib.g_method_src is null then
          v_sname := plib.g_method_sname;
        else
          v_sname := plib.g_src_sname;
        end if;
        begin
            select id, package_name, text_type, propagate, flags, result_class_id, ext_id
              into method_info.id, v_pack, i, v_cnt, method_info.flags, method_info.result_id, method_info.ext_id
              from methods
             where short_name = v_sname and class_id = v_class and src_id is null;
            ok := true;
        exception when NO_DATA_FOUND then null;
        end;
        if ok then
            i := bitand(i,3);
            if v_cnt = 1 then -- archive package
              if instr(translate(method_info.flags,'AT','!!'),'!') = 0 then
                i := i + 4;
              end if;
            end if;
            v_cnt := null;
            if method_info.ext_id is null then
              v_sig := method.method_signature(method_info.id,method_info.flags,method_info.result_id,false,true);
              ok := v_sig = p_sig;
            else
              ok := method.method_signature(method_info.ext_id,method_info.flags,method_info.result_id,false,true) = p_sig;
              if ok then
                if v_pack is null then
                  v_pack := method.make_pack_name(v_class,v_sname,method_info.id);
                end if;
                method_info.id := method_info.ext_id;
                lib.desc_method(method_info.id,method_info);
                v_sname := method_info.sname;
                i := method_info.features;
                if method_info.package is not null then
                  v_pack := method_info.package;
                end if;
              else
                v_sig := method.method_signature(method_info.id,method_info.flags,method_info.result_id,false,true);
                ok := v_sig = p_sig;
              end if;
            end if;
            if not ok and plib.g_src_merge and p_sig <> p_src_sig then
              ok := v_sig = p_src_sig;
              if ok then
                if v_pars is null then
                  lvl := 0;
                  v_pars := 0;
                  loop
                    lvl := instr(p_src_sig,',',lvl+1);
                    if lvl > 0 then
                      v_pars := v_pars+1;
                    else
                      exit;
                    end if;
                  end loop;
                end if;
                v_cnt := v_pars;
              end if;
            end if;
            if ok then
              if upper(nvl(substr(rtl.setting('PLP_EXTENSION_SYS_SWITCH'),1,1),'N')) in ('Y','1') or not has_src_id or plib.g_src_merge then --PLATFORM-8599
              plib.check_app_error_lic(null, 'LIC_ACCESS_DENIED', constant.METHOD_REF_TYPE, v_class, v_sname, method_info.id);
                  plib.add2depends(method_info.id,constant.METHOD_REF_TYPE,v_sname,method_info.id, plib.g_src_merge);
              end if;
              v_sig := method_info.id;
              if v_pack is null then
                v_pack := method.make_pack_name(v_class,v_sname,method_info.id);
              end if;
              if method_info.ext_id is null then
                method_info.package := v_pack;
                method_info.sname := v_sname;
                method_info.features := i;
              else
                method_info.id := method_info.ext_id;
                plib.check_app_error_lic(null, 'LIC_ACCESS_DENIED', constant.METHOD_REF_TYPE, v_class, method_info.sname, method_info.id);
                plib.add2depends(method_info.id,constant.METHOD_REF_TYPE,method_info.sname,method_info.id);
                lib.desc_method(method_info.id,method_info);
                if method_info.package is null or method_info.package = v_pack then
                  i := method_info.features;
                  v_sig := method_info.id;
                  method_info.package := v_pack;
                end if;
              end if;
              cnt := cnt + 1;
              if p_getid then
                v_sig := v_cnt||'.'||v_sig;
                v_pack:= v_cnt||'.'||method_info.id;
              else
                v_sig := method.make_proc_name(v_sname,true,v_pack)||'.'||v_cnt||'.'||i;
                v_pack:= method.make_proc_name(method_info.sname,false,method_info.package)||'.'||v_cnt||'.'||method_info.features;
              end if;
              overlapped(cnt).text1 := v_class;
              overlapped(cnt).text2 := v_sig;  --validate
              overlapped(cnt).text3 := v_pack; --execute
            else
              plib.plp_error(p_idx,'OVERLAPPED',plib.g_method_sname,v_class,is_error=>false);
            end if;
        end if;
        if not ok and lvl > 1 and cnt > 0 then
            for cc in (
                    select /*+ INDEX(class_relations unq_cls_rel_chld_dist) */
                           parent_id
                      from class_relations
                     where child_id = v_class
                       and distance > 0
                       and distance < lvl
                     order by distance
                      )
            loop
                i := plib.find_record(overlapped,cc.parent_id);
                if i > 0 then
                    overlapped(i).text4 := overlapped(i).text4||','''||v_class||'''';
                    exit;
                end if;
            end loop;
        end if;
    end loop;
end;
--
-- @METAGS cache_processing
function cache_processing (p_text in out nocopy plib.string_tbl_t, p_mgn varchar2, p_set boolean) return boolean is
    b   boolean;
    i   pls_integer;
    j   pls_integer;
    pos pls_integer;
    v_cnt   pls_integer := 0; -- кол-во реквизитов задействованных в блоке validate(execute)
    s_cnt   pls_integer := 0; -- кол-во реквизитов задействованных в блоке validate(execute), в которые УСТАНАВЛИВАЮТСЯ значения
    a_cnt   pls_integer := 0; -- кол-во функциональных реквизитов задействованных в блоке validate(execute)
    b_cnt   pls_integer := 0; -- кол-во реквизитов типа BOOLEAN задействованных в блоке validate(execute)
    c_cnt   pls_integer := 0; -- кол-во кэшируемых реквизитов задействованных в блоке validate(execute)
    u_cnt   pls_integer := 0; -- кол-во функциональных реквизитов задействоанных в блоке validate(execute), в которые УСТАНАВЛИВАЮТСЯ значения
    w_cnt   pls_integer := 0;
    v_cprt  pls_integer := 0;
    g_stat  boolean default FALSE;
    s_stat  boolean default FALSE;
    v_chk   boolean default FALSE;
    v_gatr  boolean;
    v_satr  boolean;
    v_set   boolean;
    v_get   boolean;
    v_bool  boolean;
    v_stat  boolean;
    v_obj   boolean;
    o_obj   boolean;
    mgn1    varchar2(20) := p_mgn||TAB;
    mgn2    varchar2(20) := mgn1 ||TAB;
    v_key   varchar2(30);
    v_prt   varchar2(100);
    v_col   varchar2(100);
    v_tbl   varchar2(200);
    s_check varchar2(200);
    v_elem  varchar2(1000);
    v_qual  varchar2(1000);
    set_str varchar2(20000);
    get_str varchar2(20000);
    s_str   varchar2(8000);
    r_str   varchar2(4000);
    g_str   varchar2(8000);
    g_bool  varchar2(4000);
    s_bool  varchar2(4000);
    set_atr varchar2(4000);
    g_attr  varchar2(2000); -- список shortname функциональных реквизитов задействованных в блоке validate(execute)(параметр для get$attr)
    s_attr  varchar2(2000); -- список shortname функционвльных реквизитов задействованных в блоке validate(execute), только для УСТАНОВКИ значений(параметр для set$attr)
    rec plib.string_rec_t;
    tbl plib.string_tbl_t;
    prt plib.string_tbl_t;
    tbp plib.string_tbl_t;
    type rec_tbl is table of varchar2(10000) index by binary_integer;
    t_select    rec_tbl;
    t_into      rec_tbl;
    t_update    rec_tbl;
    xid varchar2(5) := rtl.bool_char(lib.pk_is_rowid(substr(this_table,3)), 'rowid', 'id'); -- Колонка для идентификации в типе(по id или rowid)
    v_check_readonly_exist boolean := false; -- флаг, который показывает, добавлен ли уже в код Set$Obj$This проверка режима READONLY
begin
  if this_ins then
    i := plib.add_unique(used_attrs,'$<NULL>$');
    if lock_this then
        used_attrs(i).text4 := constant.YES;
    end if;
  elsif used_attrs.count=0 then
    if this_attr then
      this_var := false;
      return false;
    else
      i := plib.add_unique(used_attrs,'$<NULL>$');
    end if;
  end if;
  if set_count>0 then
    i := plib.find_record(used_attrs,null,null,null,constant.YES);
    if i is null then
        i := used_attrs.next(0);
        while not i is null loop
            used_attrs(i).text4 := constant.YES;
            i := used_attrs.next(i);
        end loop;
    end if;
  end if;
  v_obj := this_obj and call_obj;
  o_obj := v_obj;
  if p_set then
    v_get := true;
  else
    v_get := null;
  end if;
  if not plib.g_method_arch then
    v_key := ',key_=>0);';
  elsif not plib.g_prt_actual then
    if chk_key then
      v_key := ',key_=>nvl('||var_key||',-1));';
    else
      v_key := ',key_=>-1);';
    end if;
  else
    v_key := ');';
  end if;
  if plib.fill_attrs(used_attrs,v_obj,v_get) then
    j := used_attrs.first;
    v_set := false;
    g_attr:= ',';
    s_attr:= ',';
    -- Цикл по реквизитам задействованным в блоке validate(execute)
    while not j is null loop
      rec := used_attrs(j);
      if j<0 then
        v_elem:= '.'||rec.text1;
        if not v_obj then
          v_obj := true;
          this_obj := true;
          call_obj := true;
        end if;
      else
        v_cnt := v_cnt+1;
        v_elem:= class_mgr.qual2elem(rec.text1);
        if this_attr then
          if p_set then
            if rec.text4 is null then
              v_col := 'R';
            else
              v_col := 'W';
            end if;
          else
            v_col := 'G';
          end if;
          plib.add2depends(plib.g_class_id,v_col,rec.text1,null);
        end if;
      end if;
      if not v_set is null then
        pos := instr(rec.text2,'.');
        v_col := substr(rec.text2,pos+1);
        v_tbl := substr(rec.text2,1,pos-1);
        v_qual:= var_this||v_elem;
        i := instr(rec.text3,'.',1,2)+1;
        if substr(rec.text3,i+6,1)=constant.PRIMARY_ATTR then
          v_get := false;
          v_col := 'ID';
        else
          v_get := substr(rec.text3,i+6,1)=constant.METHOD_ATTRIBUTE;
        end if;
        pos := plib.find_string(tbl,v_tbl);
        if pos is null then
            pos := nvl(tbl.last,0) + 1;
            if pos>1 and v_tbl=this_table then
                tbl(pos) := tbl(1);
                tbp(pos) := tbp(1);
                prt(pos) := prt(1);
                t_into(pos) := t_into(1);
                t_select(pos) := replace(t_select(1),', a1.',', a'||pos||'.');
                t_update(pos) := t_update(1);
                pos := 1;
            end if;
            tbl(pos) := v_tbl;
            tbp(pos) := null;
            prt(pos) := null;
            t_into(pos) := null;
            t_select(pos) := null;
            t_update(pos) := null;
            if substr(rec.text3,i+4,1)!=constant.NO then
              if plib.g_prt_actual then
                if substr(rec.text3,i+4,1)=constant.YES then
                  tbp(pos):= ' partition('||v_tbl||'#0)';
                  prt(pos):= '=1000';
                end if;
              else
                if plib.g_method_arch then
                  v_cprt:= v_cprt+1;
                  v_prt := var_prt||v_cprt;
                  lib.put_buf(p_mgn||v_prt||TAB||'number := valmgr.get_key('''
                    ||substr(rec.text3,instr(rec.text3,'.',-1)+1)||''');'||NL,p_text,false);
                  if chk_key then
                    prt(pos):= '>=nvl('||var_key||','||v_prt||')';
                  else
                    prt(pos):= '>='||v_prt;
                  end if;
                end if;
                if substr(rec.text3,i+4,1)!=constant.YES then
                  tbp(pos):= '#PRT';
                end if;
              end if;
            end if;
        end if;
        v_stat := not this_attr and substr(rec.text3,i,1)=constant.YES;
        v_bool:= instr(rec.text3,constant.GENERIC_BOOLEAN)=1;
        v_set := p_set and not rec.text4 is null;
        b := true;
        begin
          if v_bool then
            b_cnt := b_cnt + 1;
            v_tbl := 'b$'||b_cnt;
          end if;
          if v_set then
            s_cnt := s_cnt + 1;
            if v_get or self_cached and substr(rec.text3,i+5,1)=constant.NO then
              if v_get then
                b := self_cached and not this_attr;
                if b and u_cnt>0 then
                  w_cnt := w_cnt+2;
                end if;
              else
                w_cnt := w_cnt+1;
                if self_cached and not this_attr and rec.text4<>constant.YES then
                  b := false;
                end if;
              end if;
              if b then
                v_prt := '1';
                v_tbl := substr(rec.text3,instr(rec.text3,'.',1,3)+1,instr(rec.text3,'.',1,4)-instr(rec.text3,'.',1,3)-1);
                set_atr:= set_atr||mgn1||get_iface_call(v_prt,new_this,plib.g_class_id,rec.text1,
                  v_tbl,plib.convert_base(substr(rec.text3,1,instr(rec.text3,'.')-1)),true)||','||v_qual||v_key||NL;
                --class_utils.base2sql(substr(rec.text3,1,instr(rec.text3,'.')-1),v_prt,v_prt,v_tbl,
                --  substr(rec.text3,instr(rec.text3,'.',1,3)+1,instr(rec.text3,'.',1,4)-instr(rec.text3,'.',1,3)-1),null,false,null);
                --set_atr:= set_atr||mgn1||self_interface||'.set_'||v_tbl||'('||new_this
                --  ||','''||rec.text1||''','||v_qual||v_key||NL;
              else
                b := true;
              end if;
            else
              v_chk := v_chk or nvl(substr(rec.text3,i+1,1)=constant.YES,FALSE);
              if v_stat then
                s_stat:= TRUE;
                s_str := s_str||mgn2||'if '||v_qual||'='||var_static||v_elem||' then '||v_qual||':=null; end if;'||NL;
                r_str := r_str||mgn2||v_qual||' := nvl('||v_qual||','||var_static||v_elem||');'||NL;
                b := false;
              end if;
              if t_update(pos) is null then
                t_update(pos) := ', sn=nvl(sn,1)+1, su=rtl.uid$';
                /*if tbl(pos)=this_table then
                  b := this_scn;
                elsif inst_info.db_version<10
                  or lib.table_exist(substr(rec.text3,instr(rec.text3,'.',-1)+1),table_info)
                 and table_info.flags like '0%' then
                  b := true;
                else
                  b := false;
                end if;
                if b then
                  t_update(pos) := ', sn=nvl(sn,1)+1';
                end if;*/
              end if;
              if v_bool then
                s_bool := s_bool ||mgn1||v_tbl||TAB||'varchar2'||BOOL_PREC||';'||NL;
                set_str:= set_str||mgn1||v_tbl||' := valmgr.bool2char('||v_qual||');'||NL;
                t_update(pos) := t_update(pos)||', '||v_col||'='||v_tbl;
              else
                t_update(pos) := t_update(pos)||', '||v_col||'='||v_qual;
              end if;
            end if;
          end if;
          if v_stat then
            g_stat:= TRUE;
            if b then
              g_str := g_str||mgn2||v_qual||' := nvl('||v_qual||','||var_static||v_elem||');'||NL;
            end if;
          end if;
          if j>0 or ascii(v_col)<>ascii('''') then
            v_col := 'a'||pos||'.'||v_col;
          end if;
          if v_get then
            a_cnt := a_cnt+1;
            if v_set then
              u_cnt := u_cnt+1;
            end if;
            if pos>1 or tbl(pos)<>this_table then
              v_gatr := true;
              if v_set then
                v_satr := true;
              end if;
            end if;
            i := instr(rec.text1,'.',-1);
            if i>0 then
              v_elem := substr(rec.text1,1,i-1)||',';
              if instr(g_attr,v_elem)=0 then
                g_attr := g_attr||v_elem;
              end if;
              if v_set then
                if instr(s_attr,v_elem)=0 then
                  s_attr := s_attr||v_elem;
                end if;
              end if;
            elsif not (this_attr and rec.text1=plib.g_method_sname) then
              g_attr := g_attr||rec.text1||',';
              if v_set then
                s_attr := s_attr||rec.text1||',';
              end if;
            elsif p_set then
              g_attr := g_attr||rec.text1||',';
            end if;
          elsif self_cached and j>0 and substr(rec.text3,i+5,1)=constant.NO then
            c_cnt := c_cnt+1;
          else
            t_select(pos) := t_select(pos)||', '||v_col;
            if v_bool then
              g_bool := g_bool ||mgn1||v_tbl||TAB||'varchar2'||BOOL_PREC||';'||NL;
              get_str:= get_str||mgn1||v_qual||' := valmgr.char2bool('||v_tbl||');'||NL;
              v_qual := v_tbl;
            end if;
            t_into(pos) := t_into(pos)||', '||v_qual;
          end if;
        exception when value_error then
          v_set := null;
          exit when not this_attr;
        end;
      end if;
      j := used_attrs.next(j);
    end loop;
    if this_attr and v_obj then
      plib.add2depends(plib.g_class_id,case when p_set then 'R' else 'G' end,'%SYSTEM%',null);
    end if;
    j := tbl.last;
    if j is null then
      if this_ins then
        if lock_this then
          s_cnt := 1;
        end if;
      else
        return false;
      end if;
    end if;
    if v_set is null or self_cached is null and not this_attr then
      v_set := null;
      v_get := null;
      g_stat:= self_static;
    else
      if this_ins then
        col_count := v_cnt;
        col_cached:= c_cnt;
        col_attrs := a_cnt;
      elsif col_count=0 then
        i := plib.add_unique(used_attrs,'$<NULL>$');
        v_get := plib.fill_attrs(used_attrs,false,false);
        col_cached:= 0;
        col_attrs := 0;
        if self_cached or self_attrs then
          j := used_attrs.next(0);
          while not j is null loop
            col_count := col_count+1;
            rec := used_attrs(j);
            if substr(rec.text3,instr(rec.text3,'.',1,2)+7,1)=constant.METHOD_ATTRIBUTE then
              col_attrs := col_attrs+1;
            elsif self_cached then
              if substr(rec.text3,instr(rec.text3,'.',1,2)+6,1)=constant.NO then
                col_cached := col_cached+1;
              end if;
            end if;
            j := used_attrs.next(j);
          end loop;
        else
          col_count := used_attrs.count;
          if v_obj then
            j := used_attrs.first;
            while j<0 loop
              col_count := col_count-1;
              j := used_attrs.next(j);
            end loop;
          end if;
        end if;
      end if;
      if w_cnt>2 then
        v_set := false;
      else
        v_set := col_count>s_cnt*2;
      end if;
      if v_set then
        if c_cnt+a_cnt=0 then
          v_get := col_count>v_cnt*2;
        elsif c_cnt+a_cnt=v_cnt then
          v_get := false;
        elsif (col_count-col_cached-col_attrs)=(v_cnt-c_cnt-a_cnt) then
          v_get := false;
        elsif col_count>(v_cnt-c_cnt-a_cnt)*2 then
          v_get := true;
          for i in 1..tbl.count loop
            if not (tbl(i)=this_table or t_select(i) is null) then
              v_get := false; exit;
            end if;
          end loop;
        else
          v_get := false;
        end if;
      else
        v_get := false;
      end if;
    end if;
    if v_get or v_set then
      declare
        from_str varchar2(2000);
        wher_str varchar2(2000);
      begin
        j := tbl.last;
        if tbl(1)<>this_table then
            j := j+1;
            tbl(j) := tbl(1);
            tbp(j) := tbp(1);
            prt(j) := prt(1);
            t_into(j) := t_into(1);
            t_select(j) := replace(t_select(1),', a1.',', a'||j||'.');
            t_update(j) := t_update(1);
            tbl(1) := this_table;
            tbp(1) := null;
            prt(1) := null;
            t_into(1):= null;
            t_select(1) := null;
            t_update(1) := null;
            if this_part!=constant.NO then
              if plib.g_prt_actual then
                if this_part=constant.YES then
                  tbp(1):= ' partition('||this_table||'#0)';
                  prt(1):= '=1000';
                end if;
              else
                if plib.g_method_arch then
                  v_cprt:= v_cprt+1;
                  v_prt := var_prt||v_cprt;
                  lib.put_buf(p_mgn||v_prt||TAB||'number := valmgr.get_key('''||plib.g_class_id||''');'||NL,p_text,false);
                  if chk_key then
                    prt(1):= '>=nvl('||var_key||','||v_prt||')';
                  else
                    prt(1):= '>='||v_prt;
                  end if;
                end if;
                if this_part!=constant.YES then
                  tbp(1):= '#PRT';
                end if;
              end if;
            end if;
        end if;
        if v_get then
          from_str:= tbl(1)||tbp(1);
          -- j=1 - отсутствует иерархия классов при формировании тела get$obj$this.
          if j=1 then
            t_select(1) := replace(t_select(1),'a1.');
            wher_str:= ' where '||xid||'='||var_id;
            if not prt(1) is null then
              wher_str:= wher_str||' and key'||prt(1);
            end if;
          -- j>1 - присутствует иерархия классов при формировании тела get$obj$this. При идентификации по rowid, иерархия классов не поддерживается
          else
            from_str:= from_str||' a1';
            wher_str:= ' where a1.id='||var_id;
            if not prt(1) is null then
              wher_str:= wher_str||' and a1.key'||prt(1);
            end if;
          end if;
        end if;
        pos := 2;
        for i in 1..j loop
            if v_get then
              if i=1 then
                if t_select(1) is null then
                  t_select(1) := 'select';
                  t_into(1) := '  into';
                else
                  t_select(1) := 'select' ||substr(t_select(1),2);
                  t_into(1) := '  into' ||substr(t_into(1),2);
                  pos := 1;
                end if;
              elsif not t_select(i) is null then
                if pos=1 then
                  t_select(1) := t_select(1)||t_select(i);
                  t_into(1):= t_into(1)||t_into(i);
                else
                  t_select(1) := t_select(1)||substr(t_select(i),2);
                  t_into(1):= t_into(1)||substr(t_into(i),2);
                  pos := 1;
                end if;
                from_str:= tbl(i)||tbp(i)||' a'||i||', '||from_str;
                wher_str:= wher_str||' and a1.id=a'||i||'.id';
                if not prt(i) is null then
                  wher_str:= wher_str||' and a'||i||'.key'||prt(i);
                end if;
              end if;
            end if;
            -- Формирование тела Set$Obj$This
            if v_set and not t_update(i) is null then
                if prt(i) is null  then
                  v_col := ';';
                else
                  v_col := ' and key'||prt(i)||';';
                end if;
                if not v_check_readonly_exist then
                    set_str := set_str||mgn1||'valmgr.check_readonly;'||NL;
                    v_check_readonly_exist := true;
                end if;
                set_str := set_str
                    ||mgn1||'update '||tbl(i)||tbp(i)||' set'||NL
                    ||mgn1||'    '||substr(t_update(i),2)||NL
                    ||mgn1||'    '||'where '||xid||'='||new_this||v_col||NL;
            end if;
        end loop;
        if v_get then
            get_str := mgn1||t_select(1)||NL||mgn1||t_into(1)||NL
                ||mgn1||'  from '||from_str||NL||mgn1||wher_str||';'||NL||get_str;
            if s_stat then
              g_str := g_str||r_str;
            end if;
            if c_cnt>0 then
              if p_set then
                v_prt := FALSE_CONST;
              else
                v_prt := NULL_CONST;
                g_bool:= null;
                get_str := null;
              end if;
              get_str := mgn1||var_this||' := '||self_interface||'.get_'||class_mgr.make_valid_literal(plib.g_class_id)||'('||var_id||',null,'||v_prt||v_key||NL||get_str;
            end if;
            if length(g_attr)>1 then
              v_prt := var_this||'.id:='||var_id;
              if not v_obj and c_cnt=0 then
                v_prt := v_prt||'; '||var_this||'.class_id:='||var_obj_class;
              end if;
              get_str := get_str||mgn1||v_prt||';'||NL;
            end if;
        end if;
        if v_set and not set_atr is null then
          set_str := set_str||set_atr;
        end if;
      exception when value_error then
        v_get := false;
        v_set := false;
      end;
    end if;
  else
    v_get := null;
    v_set := null;
    s_cnt := set_count;
    g_stat:= self_static;
  end if;
    lib.instr_buf(i,i,p_text,'Set$Obj$This');
    if i>0 then
      lib.put_buf(p_mgn||'procedure Set$Obj$This;'||NL,p_text,false);
    end if;
    lib.instr_buf(i,i,p_text,'Get$Obj$This');
    if i>0 then
      lib.put_buf(p_mgn||'procedure Get$Obj$This;'||NL,p_text,false);
    else
      i := 0;
    end if;
    if s_cnt+set_count>0 then
      if this_kernel or s_cnt=0 then
        s_bool := null; s_str := null; r_str := null; v_stat := false;
        s_check:= mgn1; v_tbl := NL; v_chk := false;
        if this_kernel then
          set_str:= 'message.error(''CLS'',''METADATA'');';
        else
          set_str:= NULL_STMT;
        end if;
      else
        db_update := true;
        v_stat := length(s_attr)>1 and not this_attr;
        if v_set then
          v_chk := v_chk and has_check and not this_attr;
        else
          s_bool:= null;
          set_str := mgn1||self_interface||'.set_'||class_mgr.make_valid_literal(plib.g_class_id)||'('||new_this||',null,'||var_this;
          if this_attr then
            v_prt := ',null,false';
            v_chk := false;
          elsif v_set is null then
            v_prt := ',true,true';
            v_stat:= false;
            s_stat:= false;
            v_chk := false;
            s_str := null;
          else
            v_chk := v_chk and has_check and not this_attr;
            if v_stat then
              --if u_cnt=col_attrs then
              --  v_prt := ',false,false';
              --  v_stat:= false;
              --else
                v_prt := ',null,false';
              --end if;
            else
              v_prt := ',false,false';
            end if;
            if s_stat then
              s_str := mgn2||self_interface||'.correct$set('||var_this||','||var_static||');'||NL;
              r_str := mgn2||self_interface||'.correct$get('||var_this||','||var_static||');'||NL;
            end if;
          end if;
          set_str := set_str||v_prt||v_key||NL;
        end if;
        v_elem := var_this;
        if s_stat then
          s_str := mgn1||'if '||var_stat||' then '||NL||s_str||mgn1||'end if;'||NL;
          if v_stat or v_chk then
            r_str := mgn1||'if '||var_stat||' then '||NL||r_str||mgn1||'end if;'||NL;
          else
            v_elem := 'var$';
            set_str:= replace(set_str,var_this,'var$');
            s_bool := s_bool||mgn1||'var$'||TAB||self_type||';'||NL;
            s_str := mgn1||'var$ := '||var_this||';'||NL||replace(s_str,var_this,'var$');
            r_str := null;
          end if;
        else
          r_str := null;
        end if;
        if v_chk then
            s_check := mgn1||self_interface||'.check$('||new_this||','
                ||var_this||','||var_old||','||var_obj_class||v_key||NL;
            v_tbl := mgn1||var_old||' := '||var_this||';'||NL;
        else
            v_tbl := null; s_check := null;
        end if;
        if v_set then
          if self_cached and v_stat then
            if i=0 then
              lib.put_buf(p_mgn||'procedure Get$Obj$This;'||NL,p_text,false);
            end if;
            r_str := mgn1||'Get$Obj$This;'||NL;
            v_stat:= false;
          elsif self_static then
            if instr(set_str,mgn1||'update ')>0 then
              v_tbl := v_tbl||mgn1||'if '||new_this||'=valmgr.static('||var_obj_class||') then cache_mgr.reg_event(0,'||var_obj_class||'); end if;'||NL;
            end if;
          end if;
        end if;
        if this_ins then
            if o_obj then
              v_prt := ','||obj_this||'.state_id);';
            else
              v_prt := ');';
            end if;
            if s_stat then
              v_prt := FALSE_CONST||v_prt;
            else
              v_prt := TRUE_CONST||v_prt;
            end if;
            s_str := s_str
                ||mgn1||'if '||new_this||' is null then '||NL
                ||mgn2||'if '||var_obj_class||' = '''||plib.g_class_id||''' then'||NL
                ||mgn2||TAB||new_this||' := '||self_interface||'.copy('
                ||v_elem||','||var_collect||',null,'||v_prt||NL
                ||mgn2||'else'||NL;
            -- PLATFORM-2531: Возможность создания экземпляра дочернего ТБП сложным конструктором
            s_str := s_str
                ||mgn2||TAB||new_this||' := construct('||var_obj_class||','
                ||v_elem||','||var_collect||','||v_prt||NL;
            s_str := s_str
                ||mgn1||'end if;'||NL
                ||mgn1||'else'||NL;
            v_tbl := mgn1||'end if; '||var_chk||':=false;'||NL||v_tbl;
        elsif this_attr then
            s_str := mgn1||'if '||new_this||' is null or '||var_get||' is null then return; end if; '||var_get||':=false;'||NL||s_str;
        else
            s_str := mgn1||'if '||new_this||' is null then return; end if;'||NL||s_str;
        end if;
      end if;
      -- PLATFORM-2531: Возможность создания экземпляра дочернего ТБП сложным конструктором
      if this_ins then
        declare
          pack_name varchar(100);
        begin
          if plib.g_src_merge then
            pack_name := method.make_pack_name(plib.g_class_id,plib.g_src_sname,plib.g_method_src);
          else
            pack_name := method.make_pack_name(plib.g_class_id,plib.g_method_sname,plib.g_method_id);
          end if;
          lib.put_buf(
                  p_mgn||     'function construct(target in varchar2,rec_ in '|| class2plsql(plib.g_class_id) || ',collection_id_ number, stat_ boolean default true, state_id_ varchar2 default null) return varchar2 is'||NL||
                  p_mgn||TAB||  'unrelated boolean := true; text varchar2(2000);dtext varchar2(2000);this$ varchar2(100);prev varchar2(200);ifp varchar2(200);vstat varchar2(5);'||NL||
                  p_mgn||     'begin'||NL||
                  p_mgn||TAB||  'if stat_ then vstat := ''true''; else vstat := ''false''; end if;'||NL||
                  p_mgn||TAB||  'FOR cur IN ('||NL||
                  p_mgn||TB2||    'select PARENT_ID "ROOT",DISTANCE from class_relations where CHILD_ID = target order by 2 desc)'||NL||
                  p_mgn||TAB||  'LOOP'||NL||
                  p_mgn||TB2||    'if cur.root = ''' || plib.g_class_id || ''' then'||NL||
                  p_mgn||TB3||      'prev := '''||pack_name||'.plp$buf$'';'||NL||
                  p_mgn||TB3||      pack_name||'.plp$buf$ := plp$var$;'||NL||
                  p_mgn||TB3||      'unrelated := false;'||NL||
                  p_mgn||TB2||    'else'||NL||
                  p_mgn||TB3||      'if not prev is null then'||NL||
                  p_mgn||TB4||        'ifp := class_mgr.interface_package(cur.root);'||NL||
                  p_mgn||TB4||        'dtext := dtext || ''v$''||cur.root||'' ''||ifp||''.CLASS#''||cur.root|| '';'';'||NL||
                  p_mgn||TB4||        'text := text || ifp || ''.set$child(v$'' || cur.root || '','' || prev || '');'';'||NL||
                  p_mgn||TB4||        'prev := ''v$'' || cur.root ;'||NL||
                  p_mgn||TB3||      'end if;'||NL||
                  p_mgn||TB2||    'end if;'||NL||
                  p_mgn||TB2||    'if cur.root = target then'||NL||
                  p_mgn||TB3||      'text := text || '':1 := '' || ifp || ''.copy(v$'' || cur.root || '',:2,null,''||vstat||'',:3);'';'||NL||
                  p_mgn||TB3||      'exit;'||NL||
                  p_mgn||TB2||    'end if;'||NL||
                  p_mgn||TAB||  'END LOOP;'||NL||
--                  p_mgn||TAB||'rtl.debug(''declare '' || dtext || '' begin '' || text || '' end;'');'||NL||
                  p_mgn||TAB||  'if unrelated then'||NL||
                  p_mgn||TB2||    'message.error('''||constant.EXEC_ERROR||''',''BAD_CLASS_ID'',target);'||NL||
                  p_mgn||TAB||  'end if;'||NL||
                  p_mgn||TAB||  'execute immediate ''declare '' || dtext || '' begin '' || text || '' end;'' using out this$, collection_id_,state_id_;'||NL||
                  p_mgn||TAB||  'return this$;'||NL||
                  p_mgn||     'end;'||NL
                  ,p_text);
        end;
      end if;

      lib.put_buf(p_mgn||'procedure Set$Obj$This is'||NL||s_bool
            ||p_mgn||'begin'||NL||s_str||s_check,p_text);
      if v_stat then
        if u_cnt=col_attrs then
          s_attr := null;
        end if;
        lib.put_buf(mgn1||self_interface||'.set$attrs('||var_this||case when v_satr then ',true' else ',false' end||',true,'''||s_attr||''''||v_key||NL,p_text);
      end if;
      lib.put_buf(set_str||v_tbl||r_str||p_mgn||'end;'||NL,p_text);
    else
      v_chk := false;
    end if;
    if not nvl(v_get,false) then
        g_bool:= null;
        if p_set then
          if v_get is null then
            v_prt := TRUE_CONST;
            if g_stat then
              g_stat := null;
            else
              g_stat := false;
            end if;
            --v_chk := false;
            g_str := null;
            g_attr:= null;
          else
            if self_cached or self_attrs then
              v_prt := NULL_CONST;
              -- Если в validate(execute) используются только кэшируемые реквизиты, либо только кэшируемые и функциональные реквизиты и целевая операция для функционального реквизита(this_attr=true), то сбрасываем параметр(g_attr) для get$attr
              if v_set and (c_cnt > 0 or this_attr) and c_cnt+a_cnt=v_cnt then
                v_prt := FALSE_CONST;
                g_attr:= null;
              -- По этой ветке пойдем если у нас как минимум операция-конструктор (this_ins=true)
              elsif a_cnt=col_attrs then
                if not (self_static or g_stat) then
                  v_prt := TRUE_CONST;
                  g_attr:= null;
                end if;
              end if;
            else
              v_prt := FALSE_CONST;
            end if;
            if g_stat then
              g_str := mgn2||self_interface||'.correct$get('||var_this||','||var_static||');'||NL;
            end if;
          end if;
        else
          v_prt := NULL_CONST;
          g_stat:= false;
          --v_chk := false;
          g_str := null;
        end if;
        if v_get is null or v_obj or c_cnt>0 or v_cnt>a_cnt then
          get_str := mgn1||var_this||' := '||self_interface||'.get_'||class_mgr.make_valid_literal(plib.g_class_id)||'('||var_id||',null,'||v_prt||v_key||NL;
        else
          get_str := mgn1||var_this||'.id:='||var_id||'; '||var_this||'.class_id:='||var_obj_class||';'||NL;
        end if;
    end if;
    v_col := TAB||self_type||';'||NL;
    if v_chk then
        lib.put_buf(p_mgn||var_old||v_col,p_text,false);
        v_tbl := mgn1 ||var_old||' := '||var_this||';'||NL;
    else
        v_tbl := null;
    end if;
    if g_stat then
        lib.put_buf(p_mgn||var_stat||TAB||'boolean;'
            ||TAB||var_static||v_col,p_text,false);
        g_bool := g_bool||mgn1||'ok$'||TAB||'boolean;'||NL;
        s_str := mgn1||'ok$ := not '||var_stat||' is null;'||NL
            ||mgn1||'if ok$ then '||var_id||' := '||new_this||';'||NL
            ||mgn1||'else '||var_id||':=valmgr.static('||var_obj_class||',true); ok$:='
            ||new_this||'='||var_id||'; '||var_stat||':=not ok$; end if;'||NL
            ||mgn1||'loop'||NL;
        s_bool:= mgn1||'exit when ok$; ok$ := true;'||NL
            ||mgn1||var_id||' := '||new_this||'; '||var_static||' := '||var_this||';'||NL
            ||mgn1||'end loop;'||NL;
        g_str := mgn1||'if '||var_stat||' then '||NL||g_str||mgn1||'end if;'||NL;
    else
        s_bool:= null;
        s_str := mgn1||var_id||' := '||new_this||';'||NL;
    end if;
    if this_attr then
      if p_set then
        lib.put_buf(p_mgn||var_get||TAB||'boolean := true;'||NL,p_text,false);
        g_bool:= g_bool||mgn1||'v$val'||TAB||class2plsql(plib.g_method_result)||';'||NL;
        v_elem:= class_mgr.qual2elem(plib.g_method_sname,var_this);
        v_qual:= mgn1||'if '||var_get||' then v$val:='||v_elem||'; end if;'||NL;
        v_prt := SP||var_get||':=null;';
      else
        v_prt := null;
        v_qual:= null;
      end if;
      s_str := NL||mgn2||'if '||var_class||' is null then return; end if;'||NL
        ||mgn2||new_this||':='||var_this||'.id; '||var_obj_class||':=nvl('||var_this||'.class_id,'||var_class||');'||v_prt||NL
        ||mgn1||'else'||NL||v_qual||s_str;
      g_str := g_str||mgn1||'end if;'||NL;
      if p_set then
        s_bool:= s_bool||mgn1||'if '||var_get||' then '||v_elem||':=v$val; end if; '||var_get||':=false;'||NL;
      end if;
    else
      lib.put_buf(p_mgn||var_this||v_col,p_text,false);
      s_str := ' return; end if;'||NL||s_str;
    end if;
    if o_obj then
      g_str := g_str||mgn1||obj_this||'.id:='||new_this||'; '||obj_this||'.class_id:='
        ||var_this||'.class_id; '||obj_this||'.state_id:='||var_this||'.state_id; '
        ||obj_this||'.collection_id:='||var_this||'.collection_id;'||NL;
    end if;
    if v_get then
      g_str := g_str||p_mgn||'exception when NO_DATA_FOUND then'||NL
        ||mgn1||'message.error(''EXEC'',''OBJECT_NOT_FOUND'','||var_id||');'||NL;
    end if;
    lib.put_buf(p_mgn||'procedure Get$Obj$This is'||NL||g_bool
        ||mgn1||var_id||TAB||self_ref||';'||NL
        ||p_mgn||'begin if '||new_this||' is null then'
        ||s_str||get_str,p_text);
    if length(g_attr)>1 then
      if a_cnt=col_attrs then
        g_attr := null;
      end if;
      lib.put_buf(mgn1||self_interface||'.get$attrs('||var_this||case when v_gatr then ',true' else ',false' end||',true,'''||g_attr||''''||v_key||NL,p_text);
    end if;
    lib.put_buf(s_bool||v_tbl||g_str||p_mgn||'end;'||NL,p_text);
    tbl.delete; prt.delete;
    t_select.delete;
    t_into.delete;
    t_update.delete;
    used_attrs.delete;
    return g_stat;
end;
--
procedure replace_type(p_decl in out nocopy varchar2) is
  i pls_integer;
  j pls_integer;
begin
  loop
    i := instr(p_decl,TAB||'type'||TAB);
    if i > 0 then
      j := instr(p_decl,NL,i+6);
    else
      j := 0;
    end if;
    if j > 0 then
      p_decl := rtrim(substr(p_decl,1,i-1),TAB)||substr(p_decl,j+1);
    else
      exit;
    end if;
  end loop;
end;
--
-- @METAGS func2plsql
procedure func2plsql ( p_idx  IN     pls_integer,
                       p_l    IN     pls_integer,
                       p_text in out nocopy plib.string_tbl_t,
                       p_decl in out nocopy varchar2,
                       p_pack IN     boolean  default FALSE
                     ) is
    idx    pls_integer := p_idx;
    i      pls_integer;
    cnt    pls_integer;
    gcnt   pls_integer;
    txt    varchar2(200);
    mgn    varchar2(100) := rpad(TAB, p_l, TAB);
    v_key  varchar2(100);
    edecl  varchar2(32767);
    edecl1 varchar2(32767);
    v_decl plib.string_tbl_t;
    v_text plib.string_tbl_t;
    is_func       boolean;
    db_upd        boolean;
    db_ctx        boolean;
    is_meth       boolean;
    is_execute    boolean;
    is_validate   boolean;
    is_univer     boolean;
    is_unival     boolean;
    over          boolean;
    except        boolean;
    comment       boolean;
    v_obj         boolean;
    v_sos         boolean;
    vsos          boolean;
    is_base_valid boolean := false;
    is_base_exec  boolean := false;
    v_auto        pls_integer;
    i_params      pls_integer;
    i_sos         pls_integer;
    mgn1          varchar2(100) := mgn||TAB;
    mgn2          varchar2(100) := mgn1||TAB;
    sig           varchar2(32767);
    tmp_idx       pls_integer;
    sos_idx       pls_integer;
    v_tmp_loop    pls_integer;
function get_sys_overlapped(params pls_integer, is_validate boolean, is_execute boolean, v_obj_class varchar2) return varchar2 is
    ret_str       varchar2(32767) := null;
begin
    if not this_new then
      ret_str := ret_str||mgn1||'if '||v_obj_class||' != '''||plib.g_class_id||''' then'||NL;
    end if;
    over := false;
    for j in 1..over_count loop
        if over then
            ret_str := ret_str||mgn2||'elsif ';
        else
            edecl1 := null; over := true;
            declare2plsql(params,p_l,v_decl,DECLARE_FORMAT_LIST,FALSE);
            i := lib.get_buf(edecl1,v_decl,true,true);
            if not plib.g_src_merge and (this_new or this_del) then
                gcnt := 2;
            else
                gcnt := 3;
                i := instr(edecl1,',',1,2);
                if i>0 then
                    edecl1 := substr(edecl1,i);
                else
                    edecl1 := ')';
                end if;
                edecl1 := '('||new_this||',nvl('||var_class||','||v_obj_class||')'||edecl1;
            end if;
            if is_validate then
              gcnt := gcnt + 2;
            end if;
            ret_str := ret_str||mgn2||'if ';
        end if;
        if overlapped(j).text4 is null then
          ret_str := ret_str
            ||v_obj_class||' = '''||overlapped(j).text1||''' then'||NL||mgn2||TAB;
        else
          ret_str := ret_str
            ||v_obj_class||' in ('''||overlapped(j).text1||''''
            ||overlapped(j).text4||') then'||NL||mgn2||TAB;
        end if;
        if is_validate then
          if this_new then
            ret_str := ret_str||'if '||new_this||' is null then '||new_this||':='||var_collect||'; end if;'||NL||mgn2||TAB;
          end if;
        elsif is_func then
            ret_str := ret_str||'return ';
        end if;
        if is_validate then
          txt := overlapped(j).text2;
          i := instr(txt,'.',-1);
          method_info.features := substr(txt,i+1);
          if bitand(method_info.features,2) > 0 then
            db_update := true;
          end if;
        elsif is_execute then
          txt := overlapped(j).text3;
          i := instr(txt,'.',-1);
          method_info.features := substr(txt,i+1);
          if bitand(method_info.features,1) > 0 then
            db_update := true;
          end if;
        end if;
        txt := substr(txt,1,i-1);
        i := instr(txt,'.',-1);
        cnt := substr(txt,i+1);   -- params counter
        txt := substr(txt,1,i-1); -- method call
        if not plib.g_prt_actual and bitand(method_info.features,4) > 0 then
          txt := method.conv_pack_name(txt,true);
        end if;
        ret_str := ret_str||txt;
        if cnt is null then
          ret_str := ret_str||edecl1||';'||NL;
        else
          i := instr(edecl1,',',1,gcnt+cnt);
          if i > 0 then
            ret_str := ret_str||substr(edecl1,1,i-1)||');'||NL;
          else
            ret_str := ret_str||edecl1||';'||NL;
          end if;
        end if;
        if not is_func or is_validate then
            ret_str := ret_str||mgn2||TAB||'return;'||NL;
        end if;
    end loop;
    ret_str := ret_str||mgn2||'end if;'||NL;
    if not this_new then
      ret_str := ret_str||mgn1||'end if;'||NL;
    end if;
    return ret_str;
end;
begin
    is_execute := ( plib.section = method.EXECUTE_SYS_SECTION );
    is_validate:= ( plib.section = method.VALIDATE_SYS_SECTION );
    is_meth := is_execute or is_validate;
    if is_meth then
        is_method := true;
        lock_this := false;
        if is_execute then
            lock_this := this_new or this_del;
        end if;
        this_var:= this_ins or this_attr;
        chk_call:= has_src_id;
        chk_var := not this_var;
        chk_key := (this_attr or this_trig) and plib.g_method_arch and not plib.g_prt_actual;
        this_obj:= false;
        is_validator := is_validate;
    end if;
    edecl := plib.get_new_name(idx);
    if is_validate then
        edecl:= edecl||'_'||method.VALIDATE_SECTION;
    elsif is_execute then
        edecl:= edecl||'_'||method.EXECUTE_SECTION;
    end if;
    if instr(plib.section,'$')>0 then
      txt := replace(plib.section,'$');
      if txt=method.EXECUTE_SYS_SECTION then
        txt := '_'||method.EXECUTE_SECTION;
        is_univer := true;
      elsif txt=method.VALIDATE_SYS_SECTION then
        txt := '_'||method.VALIDATE_SECTION;
        is_univer := true;
        is_unival := true;
      end if;
      if is_univer then
        edecl := edecl||txt;
      else
        txt := null; --???
      end if;
    end if;
    i := plib.ir(idx).down;    -- return type
    is_func := plib.ir(i).type<>plp$parser.INVALID_;
    if is_func then
      edecl1 := mgn||'function '||edecl;
    else
      edecl1 := mgn||'procedure '||edecl;
    end if;

    if plib.g_src_merge and over_count>0 and is_base_func and
       not upper(nvl(substr(rtl.setting('PLP_EXTENSION_SYS_SWITCH'),1,1),'N')) in ('Y','1') then
      if edecl = 'BASE$VALIDATE' then
          is_base_valid := true;
      else
          is_base_exec := true;
      end if;
    else
      idx_base_decl := plib.ir(i).right;
    end if;
--    rtl.debug('func2plsql: '||plib.iif(is_method,'','not ')||'method '||plib.section);
    i_params := plib.ir(i).right;              -- declare params (DECLARE_)
    lib.put_buf(edecl1,v_decl);
    declare2plsql(i_params, p_l, v_decl, DECLARE_FORMAT_LIST);  -- list
    edecl := null;
    tmp_idx := lib.get_buf(edecl,v_decl,true,true);
    if is_func then
        edecl := edecl||' return '||plsql_type(i, FALSE);
    end if;
    tmp_idx:= instr(edecl,edecl1);
    edecl1 := null;
    if tmp_idx>1 then
      edecl1:= substr(edecl,1,tmp_idx-1);
      edecl := substr(edecl,tmp_idx);
    end if;
    i := plib.ir(i_params).right;              -- func.proc body (BLOCK_)
    if is_meth or is_univer or p_pack and plib.section = method.PUBLIC_SECTION then
        if edecl1 is not null then
          replace_type(edecl1);
              edecl1 := edecl1||edecl;
          else
              edecl1 := edecl;
        end if;
        plib.pack_header := plib.pack_header||edecl1||plib.nn(SP,plib.ir(idx).text1)||';'||NL;
        if i is null then
          if nvl(plib.ir(idx).einfo,0) = 0 then -- no implemetation
            plib.plp_warning(idx,'METHOD_NOT_FOUND',plib.ir(idx).text);
          end if;
          return;
        end if;
        edecl1 := null;
    else
      if nvl(chk_var,true) and not i is null then
        if chk_var is null or this_var or this_obj then
          plib.plp_warning(p_idx,'CACHE_ATTRS');
        end if;
        chk_var := false;
      end if;
      if plib.ir(idx).node<1 then
        plib.plp_warning(idx,'NOT_USED',plib.ir(idx).text);
        if i is not null and plib.ir(idx).einfo = 0 then
          tmp_idx := plib.glob_defined(null,plib.ir(idx).text);
          if tmp_idx is null or plib.glob_defined(tmp_idx,plib.ir(idx).text) is not null then
            return;
          end if;
        else
          return;
        end if;
      end if;
    end if;
    if i is null then
      if plib.ir(idx).einfo > 0 then
        if edecl1 is not null then
          replace_type(edecl1);
          edecl := edecl1||edecl;
        end if;
        lib.put_buf(edecl||plib.nn(SP,plib.ir(idx).text1)||';'||NL,p_text);
      else -- no implementation
        plib.plp_warning(idx,'METHOD_NOT_FOUND',plib.ir(idx).text);
      end if;
      if p_decl is not null then
        p_decl := null;
      end if;
      return;
    end if;
    if p_decl is null then
      if edecl1 is not null then
        replace_type(edecl1);
        edecl := edecl1||edecl;
      end if;
    else
      p_decl := edecl1;
    end if;
    if bitand(plib.ir(idx).type1,4)>0 then
      edecl := edecl||' pipelined';
    end if;
    tmp_idx := plib.ir(i).down;               -- DECLARE
    i_sos := plib.ir(tmp_idx).right;          -- SOS
    edecl := edecl||' is'||NL;
    if is_meth then
      if this_grp then
        is_method:= FALSE;
        new_this := '''$TABLE$''';
      else
        if this_new then
          edecl := edecl||mgn1||var_collect||TAB||'number;'||NL;
        end if;
        edecl := edecl||mgn1||var_obj_class||TAB||'varchar2'||REF_PREC||';';
        if over_count is null then
          if this_static or this_attr then
            over_count := 0;
          else
            edecl1 := method.method_signature(plib.g_method_id,plib.g_method_flags,plib.g_method_result,false,true);
            if plib.g_src_merge then
              fill_overlapped(overlapped,p_idx,edecl1,method.method_signature(plib.g_method_src,plib.g_method_flags,plib.g_method_result,false,true),false);
            else
              fill_overlapped(overlapped,p_idx,edecl1,null,false);
            end if;
            over_count := overlapped.count;
          end if;
        end if;
        if over_count>0 and not this_del then
          edecl := edecl||TAB||var_prefix||TAB||'boolean;';
        end if;
        edecl := edecl||NL;
        if chk_key then
          edecl := edecl||mgn1||var_key||TAB||'number;'||TAB||var_prt||TAB||'number := '||plib.var('KEY')||';'||NL;
        end if;
        if is_execute or this_attr then
            new_this:=plib.var(plib.THIS);
            idx := plib.find_child(tmp_idx,plp$parser.ID_,new_this);
            if idx is null then
                edecl := edecl||mgn1||new_this||TAB||self_ref||' := '||plib.THIS||';'||NL;
                plib.replace_prefix( tmp_idx, plib.THIS, new_this );
            end if;
        else
            new_this:=plib.THIS;
        end if;
        if cache_this then
            set_this := 'Set$Obj$This;'||NL;
            get_this := 'Get$Obj$This;';
            used_attrs.delete;
        end if;
        obj_select:= 'Get$Object$;'||NL;
        get_count := 0;
        set_count := 0;
        obj_count := 0;
        chg_count := 0;
      end if;
      call_obj := false;
    elsif is_univer then
      lib.put_buf(edecl,p_text);
      edecl := mgn||'begin'||NL||mgn1;
      if is_func then
        edecl := edecl||'return ';
      end if;
      if plib.g_parse_java then
        txt := plib.correct_name(plib.g_method_sname)||txt;
      else
        txt := plib.g_method_sname||txt;
      end if;
      edecl := edecl||txt||'(this,plp$class';
      i := plib.ir(i_params).down;
      i := plib.ir(plib.ir(i).right).right;
      if is_unival then
        edecl := edecl||',p_message,p_info';
        i := plib.ir(plib.ir(i).right).right;
      end if;
      if i is not null and plib.ir(i).text = 'P$' and plib.ir(i).right is null then
        i := plib.ir(plib.ir(i).down).type1;  -- all_params_type record
        if i is not null then
          i := plib.ir(i).down;  -- all_params_type fields
          if i is not null and plib.ir(i).text <> 'DUMMY' then
            loop
              edecl := edecl || ',p$.'||plib.get_new_name(i);
              i := plib.ir(i).right;
              exit when i is null;
            end loop;
          end if;
        end if;
      elsif is_unival then
        edecl1:= null;
        for c in ( select short_name,src_pos,flag,class_id
                     from method_parameters
                    where method_id = plib.g_method_id
                    order by position )
        loop
          if plib.g_parse_java then
            c.short_name := plib.correct_name(c.short_name);
          end if;
          if c.src_pos is null then
            if c.flag = constant.RTL_TABLE then
              txt := class_mgr.make_valid_literal(c.class_id||'_TABLE');
            elsif c.flag = constant.RTL_COLLECTION then
              txt := class_mgr.make_valid_literal(c.class_id||'_TBLROW');
            elsif c.flag = constant.RTL_DBTABLE then
              txt := class_mgr.interface_package(c.class_id)||'.'||class_mgr.make_record_tables(c.class_id);
            elsif c.flag = constant.RTL_REFERENCE then
              txt := ref_string(lib.has_stringkey(c.class_id),true, lib.pk_is_rowid(c.class_id));
            else
              txt := class2plsql( c.class_id, p_row => c.flag=constant.RTL_DBROW );
            end if;
            edecl1 := edecl1||mgn1||c.short_name||SP||txt||';'||NL;
          end if;
          edecl := edecl||','||c.short_name;
        end loop;
        if edecl1 is not null then
          lib.put_buf(edecl1,p_text);
        end if;
      elsif i is not null then
        loop
          edecl := edecl||','||plib.get_new_name(i);
          i := plib.ir(i).right;
          exit when i is null;
        end loop;
      end if;
      lib.put_buf(edecl||');'||NL||mgn||'end;'||NL,p_text);
      return;
    end if;
    db_upd := db_update;
    db_ctx := db_context;
    v_auto := cnt_autonom;
    db_update := false;
    db_context:= false;
    this_add := false;
    sos_idx := tmp_sos_idx;
    tmp_sos_idx := tmp_sos_idx+1;
    declare2plsql(tmp_idx, p_l, v_decl, DECLARE_FORMAT_VARS);  -- func vars
    tmp_var_idx:=tmp_var_idx+1;
    tmp_idx:=tmp_var_idx;
    lib.put_buf(edecl,p_text);
    if is_method then
      if chk_var is null or chk_var and (this_var or this_obj) then
        plib.plp_warning(p_idx,'CACHE_ATTRS');
        chk_var := false;
      end if;
      if cache_this or cache_obj then
        this_add := is_meth;
      end if;
      cnt := obj_count;
      gcnt:= get_count;
    end if;
    this_get := false;
    this_chg := false;
    this_mtd := false;
    if this_add then
      this_upd := this_ins and cache_this;
    else
      this_upd := false;
    end if;
    edecl1 := null;
    v_tmp_loop := tmp_loop;
    tmp_loop := 0;
    v_sos:= sos_method;
    vsos := sosmethod;
    sos_method:= is_meth;
    sosmethod := is_meth;
    sos2plsql(i_sos, p_l+1, edecl1, v_text,tmp_idx);
    if v_text.count=0 then
        v_text(1) := mgn1||NULL_STMT||NL;
    end if;
    i := plib.ir(i_sos).right;          -- EXCEPTION
    if not plib.ir(i).down is NULL then
        except:=false;
        exception2plsql(i,p_l,edecl1,v_text,tmp_idx);
    end if;
    i := instr(edecl1,mgn1||'procedure Clear$'||plib.var(null));
    if i>0 then
        lib.put_buf(substr(edecl1,i),v_decl);
        edecl1:= rtrim(substr(edecl1,1,i-1),TAB);
    end if;
    tmp_loop := v_tmp_loop;
    tmp_sos_idx := sos_idx;
    sos_method:= v_sos;
    sosmethod := vsos;
    chk_return:= false;
    if is_method then
        txt := null;
        if this_upd and not is_meth then
            txt := 'UPD';
            lib.instr_buf(i,i,v_text,'--$ '||var_this);
            if i>0 then
                lib.replace_buf(v_text,'--$ '||var_this,get_this);
                get_count := get_count + 1;
            end if;
        else
            if this_mtd then
                txt := 'MTD';
            end if;
            lib.replace_buf(v_text,mgn1||'--$ '||var_this||NL);
        end if;
        if this_chg then
            txt := txt||'CHG';
        end if;
        if this_get then
            txt := txt||'GET';
        end if;
        if cnt<obj_count then
            txt := txt||'OBJ';
        end if;
        if gcnt<get_count then
            txt := txt||'G$O';
        end if;
        plib.ir(p_idx).text1 := txt;
    end if;
    if is_meth then
        v_obj := false;
        if not plib.g_method_arch then
          v_key := ',key_=>0);';
        elsif not plib.g_prt_actual then
          if chk_key then
            v_key := ',key_=>nvl('||var_key||',-1));';
          else
            v_key := ',key_=>-1);';
          end if;
        else
          v_key := ');';
        end if;
        if this_obj then
          if not call_obj or chg_count>0 then
            sig := mgn1||'procedure Get$Object$';
            lib.instr_buf(i,i,v_decl,'Get$Object$');
            if i>0 then
                lib.put_buf(sig||';'||NL,v_decl,false);
            end if;
            sig := sig||' is'||NL||mgn1||'begin'||NL;
            if this_ins then
                sig := sig
                    ||mgn2||'if '||new_this||' is null then '||obj_this||'.class_id:='||var_obj_class||'; '
                    ||obj_this||'.collection_id:='||var_collect||'; '||obj_this||'.state_id:=valmgr.class_state('
                    ||var_obj_class||'); else'||NL;
                txt := ' end if;';
            else
                txt := null;
            end if;
            edecl := sig||mgn2||obj_this||' := '||self_interface||'.get_object('
                  ||new_this||v_key||txt||NL||mgn1||'end;'||NL;
            lib.put_buf(edecl,v_decl);
          end if;
          lib.put_buf(mgn1||obj_this||TAB||'rtl.object_rec;'||NL,v_decl,false);
          v_obj := true;
        end if;
        if this_var then
            over := cache_processing(v_decl,mgn1,is_validate or not this_attr);
        end if;
        if not edecl1 is null then
            lib.put_buf(edecl1,v_decl,false);
        end if;
        lib.add_buf(v_decl,p_text,true,true);
        edecl := mgn||'begin'||NL;
        comment:= plib.section in (method.EXECUTE_SECTION,method.VALIDATE_SECTION);
        if comment then
            edecl := edecl
                ||plib.SECTION_COMMENT
                ||case when is_execute then method.EXECUTE_SYS_SECTION else method.VALIDATE_SYS_SECTION end||NL;
        end if;
        if chk_key then
          edecl := edecl||mgn1||'if '||var_prt||'=0 then '||var_key||':=0; else if '
            ||var_prt||'>0 then '||var_key||':='||var_prt||'; end if; '||var_prt||':=-1; end if;'||NL;
        end if;
      if this_grp or this_attr then
        null;
      else
        edecl := edecl||mgn1||'if ';
        if this_static or this_new then
          edecl := edecl||new_this||' is NULL then'||NL||mgn2;
          if this_new then
            edecl := edecl
                ||'if '||var_class||' like ''$$$%'' then '||var_obj_class||':=substr('||var_class||',5);'||NL
                ||mgn2||'else ';
          end if;
          edecl := edecl||var_obj_class||' := nvl('||var_class||','''||plib.g_class_id||''');';
          if this_new then
            edecl := edecl||' end if;';
          else
            edecl := edecl||TAB||new_this||' := valmgr.static('||var_obj_class||');';
          end if;
          edecl := edecl||NL||mgn1||'elsif ';
        end if;
        edecl := edecl||var_class||' is NULL then'||NL||mgn2;
        if  not (plib.g_this_null or this_new or this_static) then
          edecl := edecl||'if '||new_this||' is NULL then '||var_obj_class||':='''||plib.g_class_id||'''; else '
                || var_obj_class||':='||self_interface||'.class$('||new_this||v_key||' end if;';
        else
          edecl := edecl||var_obj_class||' := '||self_interface||'.class$('||new_this||v_key;
        end if;
        if not (this_static or this_del) then
          edecl := edecl||NL||mgn1||'elsif '||var_class||' like ''$$$%'' then'||NL||mgn2;
          if this_new then
            edecl := edecl||'if substr('||var_class||',4,1)=''_'' then '
                ||var_collect||':='||new_this||'; '||new_this||':=null; ';
          end if;
          if over_count>0 then
            if this_new then
              edecl := edecl||NL||mgn2||'else ';
            end if;
            edecl := edecl||var_prefix||':=true; ';
            if this_new then
              edecl := edecl||'end if;'||NL||mgn2;
            end if;
            edecl := edecl||var_obj_class||':=substr('||var_class||',5);';
          elsif this_new then
            edecl := edecl||var_obj_class||':=substr('||var_class||',5);'||NL
              ||mgn2||'else '||var_obj_class||':='||self_interface||'.class$('||new_this||v_key||' end if;';
          elsif not plib.g_this_null then
            edecl := edecl||'if '||new_this||' is NULL then '||var_obj_class||':='''||plib.g_class_id||'''; else '
                    || var_obj_class||':='||self_interface||'.class$('||new_this||v_key||' end if;';
          else
            edecl := edecl||var_obj_class||' := '||self_interface||'.class$('||new_this||v_key;
          end if;
        end if;
        edecl := edecl||NL||mgn1||'else '||var_obj_class||' := '||var_class||';'||NL
              ||mgn1||'end if;'||NL;
        if not this_static then
          if this_new then
             if this_ins then
                edecl := edecl
                    ||mgn2||'if '||new_this||' is NULL then'||NL;
                if v_obj and this_obj and call_obj then
                    edecl := edecl||mgn2||TAB||obj_this||'.class_id:='||var_obj_class||'; '
                        ||obj_this||'.collection_id:='||var_collect||'; '||obj_this||'.state_id:=valmgr.class_state('||var_obj_class||');'||NL;
                end if;
                if over then
                    edecl := edecl||mgn2||TAB||var_stat
                        ||' := nvl('||var_collect||'<>0,true);'||NL
                        ||mgn2||TAB||'if '||var_stat||' then '
                        ||var_static||':='||self_interface||'.get_'||class_mgr.make_valid_literal(plib.g_class_id)
                        ||'(valmgr.static('||var_obj_class||',true),null,false); end if;'||NL;
                end if;
                if is_execute then
                    txt := null;
                else
                    txt := ' and p_message<>''DEFAULT''';
                end if;
                edecl := edecl ||mgn2||TAB||'if '||var_chk||txt||' then '||var_this||':='||var_ins
                    ||'; else '||self_interface||'.init('||var_this||case when over is null then ',true); ' else ',false); ' end;
                if over then
                    edecl := edecl||NL||mgn2||TAB||'if '||var_stat||' then '
                        ||self_interface||'.correct$get('||var_this||','||var_static||'); end if;'
                        ||NL||mgn2||TAB;
                end if;
                edecl := edecl||'end if;'||NL
                    ||mgn2||'else Get$Obj$This; end if;'||NL;
            else
                edecl := edecl||mgn1||'if '||var_obj_class||' = '''||plib.g_class_id||''' then'||NL --
                              ||mgn2||'if '||new_this||' is NULL then'||NL; --
                db_update := true;
                edecl := edecl
                    ||mgn2||TAB||new_this||' := '||self_interface||'.new('
                    ||var_collect||');'||NL
                    ||mgn2||'end if;'||NL;
                edecl := edecl||mgn1||'else'||NL;
            end if;
          end if;
          if over_count>0 and (upper(nvl(substr(rtl.setting('PLP_EXTENSION_SYS_SWITCH'),1,1),'N')) in ('Y','1') or not has_src_id) then
            edecl := edecl||get_sys_overlapped(i_params,is_validate,is_execute,var_obj_class);
          end if;
          if this_new and not this_ins then
            edecl := edecl
              ||mgn2||'if '||new_this||' is NULL then'||NL
              ||mgn2||TAB||new_this||':=rtl.constructor('||var_obj_class||','''||plib.g_class_id||''','||var_collect||');'||NL
              ||mgn2||'end if;'||NL||mgn1||'end if;'||NL;
          end if;
          if over_count>0 and not this_del then
            edecl := edecl
                ||mgn1||'if '||var_prefix||' then'||NL||mgn2;
            if not (plib.g_this_null or this_new) then
              edecl := edecl||'if '||new_this||' is NULL then '||var_obj_class||':='''||plib.g_class_id||'''; else '
                    || var_obj_class||':='||self_interface||'.class$('||new_this||v_key||' end if;';
            else
              edecl := edecl||var_obj_class||' := '||self_interface||'.class$('||new_this||v_key;
            end if;
            edecl := edecl||NL||mgn1||'end if;'||NL;
          end if;
        end if;
      end if;
        if is_validate and lock_this and not this_attr then
            plib.plp_error(i_sos,'CHANGE_DATABASE', is_error => false );
        end if;
        db_update := db_update or lock_this;
        lock_this := lock_this and not this_static;
        over := this_var and not this_ins;
        if lock_this then
          if this_attr then
            txt := var_obj_class||':='||var_class||'; '||self_interface||
                '.lock_object('||new_this||','||linfo_txt||','||var_obj_class||v_key||NL;
          else
            if this_get and not call_obj then
              txt := SP||obj_select;
            else
              txt := NL;
            end if;
            txt := self_interface||'.lock_object('||new_this||','||
                linfo_txt||','||var_obj_class||v_key||txt;
          end if;
        elsif this_attr then
            txt := var_obj_class||' := '||var_class||';'||NL;
        elsif this_get and not call_obj then
            txt := obj_select;
        else
            txt := 'rtl.read(null);'||NL;
        end if;
        edecl := edecl||mgn1||txt;
        if this_attr and not this_var then
          if not v_obj then
            lib.instr_buf(i,i,v_text,new_this);
            if i>0 and is_validate then
              lib.instr_buf(i,i,v_text,'MESSAGE.ERROR(''EXEC'',''UPDATING_NOT_ALLOWED'','''||plib.g_class_id||'.'||plib.g_method_sname||''');');
              if i>0 then
                i := 0;
              end if;
            end if;
          end if;
          if v_obj or i>0 then
            edecl := edecl||mgn1||'if '||new_this||' is null and not '||var_class||' is null then'||NL
              ||mgn2||new_this||':='||var_this||'.id; '||var_obj_class||':=nvl('||var_this||'.class_id,'||var_class||');'||NL;
            if v_obj then
              edecl := edecl||mgn2||obj_this||'.id:='||new_this||'; '||obj_this||'.class_id:='
              ||var_this||'.class_id; '||obj_this||'.state_id:='||var_this||'.state_id; '
              ||obj_this||'.collection_id:='||var_this||'.collection_id;'||NL
              ||mgn1||'else'||NL||mgn2||obj_select;
            end if;
            edecl := edecl||mgn1||'end if;'||NL;
          end if;
        end if;
        if is_execute and not this_attr or this_attr and is_validate then
            if plib.g_method_log>0 then
              if plib.g_method_log>2 then
                edecl := edecl||mgn1||'rtl.writelog(''L'',';
              else
                edecl := edecl||mgn1||'rtl.write_log(''L'',';
              end if;
              edecl := edecl||new_this||'||''.''||'
                 ||var_class||'||''.START'',null,'''||plib.g_method_id||''');'||NL;
            end if;
        end if;
        if is_execute then
            if not (plib.g_read_pipe is null and plib.g_write_pipe is null) then
                edecl := edecl
                   ||mgn1||'stdio.setup_pipes('
                   ||case when plib.g_read_pipe  is null then NULL_CONST else ''''||plib.g_read_pipe ||'''' end||','
                   ||case when plib.g_write_pipe is null then NULL_CONST else ''''||plib.g_write_pipe||'''' end||');'||NL;
            end if;
            if this_trig then
                edecl := edecl||mgn1||'valmgr.get_quals(attrs_list);'||NL;
            end if;
            if db_update then
              if bitand(plib.g_method_upd,1) = 0 then
                plib.g_method_upd := plib.g_method_upd + 1;
              end if;
              if this_attr then
                plib.plp_error(i_sos,'CHANGE_DATABASE');
              end if;
            else
              plib.g_method_upd := bitand(plib.g_method_upd,2);
            end if;
        elsif db_update then
          if bitand(plib.g_method_upd,2) = 0 then
            plib.g_method_upd := plib.g_method_upd + 2;
          end if;
        else
          plib.g_method_upd := bitand(plib.g_method_upd,1);
        end if;
        if over then
            put_get_this(edecl,mgn1);
        end if;
        if comment then
            edecl := edecl||plib.SECTION_COMMENT||plib.section||NL;
        end if;
        if chk_call and has_src_id then
            plib.plp_error(i_sos,'NO_SOURCE_METHOD_CALL' );
        end if;
        except := not except;
        this_var  := FALSE;
        this_obj  := FALSE;
        is_method := FALSE;
        chk_call  := FALSE;
        chk_var   := FALSE;
        chk_key   := FALSE;
        is_validator := FALSE;
        if cache_this and plib.g_optim_this and (obj_count < get_count + set_count) and not this_ins then
            plib.plp_error(i_sos,'CACHE_OPTIMIZATION', is_error => false );
        end if;
    else
        if not edecl1 is null then
          lib.put_buf(edecl1,v_decl,false);
        end if;
        lib.add_buf(v_decl,p_text,true,true);
        edecl := mgn||'begin'||NL;
        if is_base_valid or is_base_exec then--PLATFORM-8599
            edecl := mgn1||var_obj_class$||TAB||'varchar2'||REF_PREC||';'||NL||edecl;
            edecl := edecl||plib.SECTION_COMMENT
                     ||case when is_base_valid then method.VALIDATE_SYS_SECTION else method.EXECUTE_SYS_SECTION end
                     || '_SRC' ||NL;
            if not (this_static or this_del) then
               edecl := edecl
                  	    ||mgn1||'if Not '||var_class||' is Null and '||var_class||' like ''$$$%'' then '||NL
                        ||mgn2||var_obj_class$||':=substr('||var_class||',5);'||NL
                        ||mgn1||'else'||NL
                        ||mgn2||var_obj_class$||':='||var_obj_class||';'||NL
                        ||mgn1||'end if;'||NL;
            else
               edecl := edecl
                        ||mgn1||var_obj_class$||':='||var_obj_class||';'||NL;
            end if;
            edecl := edecl||get_sys_overlapped(idx_base_decl,is_base_valid,is_base_exec,var_obj_class$);
            edecl := edecl||plib.SECTION_COMMENT
                     ||case when is_base_valid then method.VALIDATE_SECTION else method.EXECUTE_SECTION end
                     || '_SRC' || NL;
        end if;
        if db_update then
          plib.set_function(p_idx,2);
        end if;
        if db_context then
          plib.set_function(p_idx,8);
        end if;
    end if;
    lib.put_buf(edecl,p_text);
    if except then
      lib.put_buf(mgn||'BEGIN'||NL,v_text,false);
      lib.put_buf(mgn||'END;'||NL,v_text);
    end if;
    lib.add_buf(v_text,p_text,true,true);
    lib.put_buf(mgn||'end;'||NL,p_text);
    db_update := db_upd;
    db_context:= db_ctx;
    cnt_autonom := v_auto;
end func2plsql;
-- @METAGS declare2plsql
-- p_block: 0 block declare
--          1 func vars
--          2 list
procedure declare2plsql ( p_idx   IN     pls_integer,
                          p_l     IN     pls_integer,
                          p_decl  in out nocopy plib.string_tbl_t,
                          p_block IN     pls_integer default DECLARE_FORMAT_VARS,
                          p_typed IN     boolean default TRUE,
                          p_pack  IN     boolean default FALSE,
                          p_null  IN     boolean default FALSE
                        ) is
    idx       pls_integer := plib.ir(p_idx).down;
    i         pls_integer;
    mgn       varchar2(100) := rpad(TAB, p_l+1, TAB);
    par       boolean;
    typ       pls_integer;
    origin    boolean := TRUE;
    prev_line pls_integer := 0;
    v_buf     plib.string_tbl_t;
    edecl     varchar2(32767);
    etext     varchar2(32767);
    eprog     varchar2(20000);
    org_text  varchar2(30);
    tbl       varchar2(30);
    put       boolean;
    put_id    boolean;
    put_prog  boolean;
    v_list    boolean;
begin
    par := not idx is NULL;
    v_list := p_block = DECLARE_FORMAT_LIST;
    if par then
        if p_block = DECLARE_FORMAT_BLOCK then
            lib.put_buf(rpad(TAB,p_l,TAB)||'declare'||NL,p_decl);
        elsif v_list then
            lib.put_buf('(',p_decl);
        end if;
    end if;
    while not idx is NULL loop
      put := plib.plp$define or v_list;
      typ := plib.ir(idx).type;
      put_prog := FALSE;
      if typ = plp$parser.PRAGMA_ then
        if use_counters then inc_counter(typ+1000); end if;
        plib.use_pragma(idx);
        if this_attr then
            plib.g_optim_this := true;
        end if;
        if put then
            org_text:=null;
            put_id:= TRUE;
            edecl := plib.pragma_text(idx);
            if instr(edecl,plib.SECTION_COMMENT) = 1 then
                if p_pack and (plib.section = method.PUBLIC_VARS_SECTION
                  or plib.section = method.PUBLIC_SECTION)
                then
                  if instr(edecl,method.PUBLIC_SECTION||SP)>0 then
                    if plib.g_for_f12 then
                       edecl := replace(edecl,method.PUBLIC_SECTION||SP,method.PRIVATE_SECTION||SP);
                    end if;
                    lib.put_buf(edecl,p_decl);
                  end if;
                  if plib.g_for_f12_ext and instr(edecl,method.PUBLIC_SECTION||'_SRC'||SP)>0 then
                      edecl := replace(edecl, method.PUBLIC_SECTION||'_SRC'||SP,method.PRIVATE_SECTION||'_SRC'||SP);
                  end if;
                  plib.pack_header := plib.pack_header||substr(edecl,1,instr(edecl,SP,-1)-1)||NL;
                  put := false;
                end if;
                origin:= true;
            elsif edecl=plib.INITIALIZE_PRAGMA then
                init_proc := plib.ir(idx).type1;
                put:=false;
            elsif edecl in (plib.GET_PRAGMA,plib.THIS_PRAGMA) then
                put:=false;
            elsif edecl like 'pragma AUTONOMOUS_TRANSACTION%' then
                cnt_autonom := cnt_autonom+1;
            end if;
        end if;
      elsif put then
        put_id:=TRUE; org_text:=null;
        --rtl.debug('declare2plsql: '||idx||' '||plib.type_name(plib.ir(idx).type)||' length(p_decl) = '||length(p_decl));
        if (origin or plib.ir(idx).line - prev_line != 1) and not v_list
/*           and typ != plp$parser.PRAGMA_
           and typ in ( plp$parser.TEXT_, plp$parser.ID_ )
           and p_block != DECLARE_FORMAT_LIST
           and plib.section != method.PUBLIC_VARS_SECTION*/
        then
            org_text := plib.origin_text(idx);
            if org_text is NULL then
                origin := TRUE;
            else
                origin := FALSE;
            end if;
        end if;
        if typ = plp$parser.ID_ then
            if use_counters then inc_counter(typ+1000); end if;
            edecl := plib.get_new_name(idx);
            if plsql_reserved.exists(edecl) then
                edecl := plib.var(edecl||'$');
                plib.replace_prefix(plib.ir(p_idx).right, plib.ir(idx).text, edecl);
                plib.ir(idx).text := edecl;
            end if;
            if v_list then
                if p_typed then
                    edecl := edecl||' '||plib.ir(idx).text1||' ';
                    eprog := plsql_type(plib.ir(idx).down, FALSE,TRUE,FALSE,TRUE);
                    i := instr(eprog,'<$NULL$>');
                    if i>0 then
                      edecl := edecl||substr(eprog,1,i-1);
                      eprog := rpad(TAB,p_l,TAB)||substr(eprog,i+8);
                      put_prog := TRUE;
                    else
                      edecl := edecl||eprog;
                      eprog := null;
                    end if;
                end if;
                if not plib.ir(idx).right is NULL then
                    edecl := edecl||',';
                end if;
            else
                eprog := plib.ir(idx).text1;
                if not eprog is NULL then
                    eprog := 'constant'||TAB;
                end if;
                edecl := mgn||edecl||TAB||eprog||plsql_type(plib.ir(idx).down,true,true,p_null)||';'||NL;
                put_id:=plib.ir(idx).node>0;
                eprog := null;
            end if;
        elsif typ = plp$parser.FUNCTION_ then
            if use_counters then inc_counter(typ+1000); end if;
            if plib.ir(idx).text in ('BASE$VALIDATE','BASE$EXECUTE') then
                is_base_func := true;
                --idx_base_decl := p_idx;
            end if;
            if put then
               if p_pack and plib.section = method.PUBLIC_SECTION  and (plib.g_for_f12 or plib.g_for_f12_ext)  and not org_text is null then
                    plib.pack_header:=plib.pack_header||org_text;
               end if;
            end if;
            eprog := '1';
            func2plsql(idx, p_l+1,v_buf,eprog,p_pack);
            if eprog = '1' then
              null;
            else
              if eprog is not null then
                lib.put_buf(eprog,p_decl,false);
              end if;
              if org_text is not null then
                lib.put_buf(org_text,p_decl);
              end if;
              lib.add_buf(v_buf,p_decl,true,true);
            end if;
            put:=FALSE;
            origin:=true;
            is_base_func := false;
            idx_base_decl := 0;
        elsif typ = plp$parser.TYPE_ then
--          put := plib.ir(idx).text1 is null;
          edecl := plib.get_new_name(idx);
          put := instr(edecl,'.')=0;
          if put then
            put_id:=plib.ir(idx).node>0;
            typ := plib.ir(idx).type1;
            i := plib.ir(idx).down;
            if not plib.ir(idx).text1 is null then
                if use_counters then inc_counter(plp$parser.TYPE_+1000); end if;
                edecl := mgn||'subtype '||edecl||' is '||plib.ir(idx).text1||';'||NL;
                plib.plp_warning(idx,'RUNTIME_DECLARATION',plib.ir(idx).text);
                put_id:= null;
            elsif typ = plp$parser.RECORD_ then
                if use_counters then inc_counter(typ+1000); end if;
                edecl := mgn||'type '||edecl||' is record (';
                while not i is NULL loop
                    edecl := edecl||NL||mgn||TAB||plib.get_new_name(i);
                    edecl := edecl||TAB||plsql_type(plib.ir(i).down);
                    i := plib.ir(i).right;
                    if not i is NULL then
                        edecl := edecl||',';
                    end if;
                end loop;
                edecl := edecl||NL||mgn||');'||NL;
                origin:=true;
            elsif typ = plp$parser.CURSOR_ then
                if use_counters then inc_counter(typ+1000); end if;
                edecl := mgn||'type '||edecl||' is ref cursor';
                if plib.ir(i).type<>plp$parser.NULL_ then
                    edecl := edecl||' return '||plsql_type(i);
                end if;
                edecl := edecl||';'||NL;
            elsif typ = plp$parser.SELECT_ then
                if use_counters then inc_counter(typ+1000); end if;
                cursor2plsql(idx,p_l,edecl,eprog);
                put_prog := TRUE;
            elsif typ = plp$parser.TABLE_ then
                if use_counters then inc_counter(typ+1000); end if;
                typ := plib.ir(i).right;
                tbl := 'table';
                if plib.ir(typ).node>0 then
                  eprog := null;
                  typ := plib.ir(typ).node-1;
                  if typ>0 then
                    tbl := 'varray('||typ||')';
                  end if;
                elsif plib.ir(typ).type=plp$parser.INTEGER_ then
                  eprog := ' index by binary_integer';
                else
                  eprog := ' index by '||plsql_type(typ);
                end if;
                edecl := mgn||'type '||edecl||' is '||tbl||' of '||plsql_type(i)||eprog||';'||NL;
                eprog := null;
            else
                if use_counters then inc_counter(plp$parser.TYPE_+1000); end if;
                while plib.ir(i).type=plp$parser.ID_ loop
                    typ := plib.ir(i).type1;
                    if not typ is null and plib.ir(typ).type1 is null then
                        i := plib.ir(typ).down;
                    else
                        exit;
                    end if;
                end loop;
                if plib.ir(i).type=plp$parser.ID_ then
                    edecl := 'subtype '||edecl;
                else
                    edecl := '-- type '||edecl;
                end if;
                edecl := mgn||edecl||' is '||plsql_type(i)||';'||NL;
            end if;
          end if;
        elsif typ = plp$parser.TEXT_ then
            if use_counters then inc_counter(typ+1000); end if;
            edecl := plib.ir(idx).text;
            if plib.g_method_lock then
                db_update := true;
                if is_method then
                    lock_this := true;
                end if;
            end if;
            origin:=true;
        else
            plib.plp_error(idx, 'IR_UNEXPECTED', 'declare2plsql', plib.type_name(typ),idx);
        end if;
      end if;
      i := plib.ir(idx).right;
      if put then
        if p_pack and (plib.section = method.PUBLIC_VARS_SECTION
          or plib.section = method.PUBLIC_SECTION) then
            plib.pack_header:=plib.pack_header||org_text||replace(edecl,'-- type ','subtype ');
            if put_prog then
                etext := etext||eprog;
            end if;
        elsif put_id then
            if put_prog then
                etext := etext||eprog;
                if i is null then
                  typ := instr(edecl,NL,-2);
                  if typ>0 and instr(edecl,'procedure Cursor$',typ)>0 then
                    edecl := substr(edecl,1,typ);
                  end if;
                end if;
            end if;
            if not org_text is null then
                edecl := org_text||edecl;
            end if;
            if not edecl is null then
                lib.put_buf(edecl,p_decl);
            end if;
        else
          if not put_id then
            plib.plp_warning(idx,'NOT_USED',plib.ir(idx).text);
          end if;
          origin := true;
        end if;
      end if;
      prev_line := nvl(plib.ir(idx).line,0);
      idx := i;
    end loop;
    if par then
      if v_list then
        lib.put_buf(')',p_decl);
        if not etext is null then
          lib.put_buf(etext,p_decl,false);
        end if;
      elsif not etext is null then
        lib.put_buf(etext,p_decl);
      end if;
    end if;
end declare2plsql;
-----------------------------------------------------
procedure block2plsql(p_idx  IN     pls_integer,
                      p_l    IN     pls_integer,
                      p_decl in out nocopy varchar2,
                      p_text in out nocopy plib.string_tbl_t,
                      t_idx  in     pls_integer default NULL,
                      p_lock IN     boolean default TRUE
                     ) is
    v_decl  plib.string_tbl_t;
    v_text  plib.string_tbl_t;
    tmpidx  pls_integer;
    sos_idx pls_integer;
    etext   varchar2(32767);
    mgn     varchar2(100) := rpad(TAB,p_l,TAB);    -- left margin
    i   pls_integer := plib.ir(p_idx).down;
    j   pls_integer;
    upd boolean;
    mtd boolean;
    chg boolean;
    get boolean;
begin
    upd := this_upd;
    mtd := this_mtd;
    chg := this_chg;
    get := this_get;
    sos_idx := tmp_sos_idx;
    declare2plsql(i,p_l,v_decl,DECLARE_FORMAT_VARS,
        true,false,plib.g_method_check and tmp_loop>0);      -- DECLARE
    i := plib.ir(i).right;              -- SOS
    j := plib.ir(i).right;              -- EXCEPTION
    this_upd := upd;
    this_mtd := mtd;
    this_chg := chg;
    this_get := get;
    this_add := is_method;
    if v_decl.count=0 and not t_idx is null then
        sos2plsql( i, p_l+1, p_decl, v_text,t_idx,p_lock );
        if v_text.count=0 then
            v_text(1) := mgn||TAB||NULL_STMT||NL;
        end if;
        exception2plsql(j, p_l,p_decl,v_text,t_idx,p_lock);
    else
        tmp_var_idx:=tmp_var_idx+1;
        tmpidx:=tmp_var_idx;
        sos2plsql( i, p_l+1, etext, v_text,tmpidx,p_lock );
        if v_text.count=0 then
            v_text(1) := mgn||TAB||NULL_STMT||NL;
        end if;
        exception2plsql(j, p_l,etext,v_text,tmpidx,p_lock);
        if not etext is null or v_decl.count>0 then
            etext := mgn||'declare'||NL||etext;
        end if;
    end if;
    tmp_sos_idx := sos_idx;
    this_add := false;
    --chk_return:= false;
    lib.put_buf(mgn||'begin'||NL,v_text,false);
    lib.put_buf(mgn||'end;'||NL,v_text);
    if not etext is null then
        i := instr(etext,mgn||TAB||'procedure Clear$'||plib.var(null));
        if i>0 then
            lib.put_buf(rtrim(substr(etext,1,i-1),TAB),v_decl,false);
            lib.put_buf(substr(etext,i),v_decl);
        else
            lib.put_buf(etext,v_decl,false);
        end if;
        lib.add_buf(v_decl,p_text,true,true);
    end if;
    lib.add_buf(v_text,p_text,true,true);
end;
-----------------------------------------------------
--
-- @METAGS add_text
function add_text(p_idx pls_integer, p_text varchar2) return pls_integer is
    idx  pls_integer;
    idx1 pls_integer := p_idx;
    b    boolean := not p_text is null;
begin
  if b then
    --stdio.put_line_buf('<<<'||p_text||'>>>');
    if plib.ir(p_idx).text1 is NULL and
      plib.ir(p_idx).type in (plp$parser.BOOLEAN_,plp$parser.TEXT_)
    then
      plib.ir(p_idx).text1:='P';
    elsif plib.ir(p_idx).type=plp$parser.BOOLEAN_ and plib.ir(p_idx).type1=plp$parser.AND_ then
      idx := plib.ir(p_idx).down;
      if plib.ir(idx).type=plp$parser.TEXT_ and plib.ir(idx).node>COL_FLAG and plib.ir(idx).text=p_text then
        b := false;
      end if;
    end if;
    if b then
      idx := plib.add2ir(plp$parser.TEXT_,plp$parser.TEXT_,p_text,null);
      idx1:= plib.add2ir(plp$parser.BOOLEAN_,plp$parser.AND_,'and','P',idx);
      plib.replace_node(p_idx,idx1);
      plib.ir(idx).node := idx+COL_FADD;
      plib.ir(idx).right  := p_idx;
      plib.ir(p_idx).left := idx;
      plib.ir(p_idx).right:= null;
    end if;
  end if;
  return idx1;
end;
--
-- @METAGS add_tmp_part
function add_tmp_part(p_class varchar2, p_prefix varchar2, p_tab varchar2,
                      p_idx in out nocopy pls_integer, p_decl in out nocopy varchar2) return varchar2 is
    edecl varchar2(100);
    i   pls_integer;
    j   pls_integer;
begin
  if use_java then
    plib.fill_class_info(plpclass);
    plpclass.base_type := plp$parser.NUMBER_;
    return plp2java.add_bind(p_idx,p_prefix,plpclass,p_class,true,2);
  end if;
  if use_context is null then
    edecl := TAB||'number := '||get_def_partkey(p_class,true)||';'||NL;
    i := instr(p_decl,edecl);
    if i>8 then
      j := instr(p_decl,TAB,i-length(p_decl)-2);
    end if;
    if j>0 then
      return substr(p_decl,j+1,i-j-1);
    else
      p_idx := p_idx+1;
      p_decl:= p_tab||p_prefix||p_idx||edecl||p_decl;
      return p_prefix||p_idx;
    end if;
  elsif use_context then
    return 'sys_context('''||Inst_info.Owner||'_KEYS'','''||p_class||'.KEY'')';
  else
    return 'valmgr.get_key('''||p_class||''')';
  end if;
end;
--
function def_tmp_part(p_part varchar2) return boolean is
begin
  if use_context is null then
    if p_part like '%'||plib.var('%')||'$P%' then
      return true;
    end if;
  elsif use_context then
    if p_part like '%sys_context('''||Inst_info.Owner||'_KEYS'',''%.KEY'')' then
      return true;
    end if;
  elsif p_part like '%valmgr.get_key(''%'')' then
    return true;
  end if;
  return false;
end;
--
function get_col_text(p_col varchar2, p_alias varchar2, p_expr varchar2, p_outer boolean) return varchar2 is
  v_col varchar2(1000);
begin
  if instr(p_col,'''')=0 then
    v_col := p_alias||'.'||p_col;
    if p_outer then
      v_col := v_col||'(+)';
    end if;
    if p_expr is null then
      return v_col;
    end if;
    return replace(p_expr,'<$COL$>',v_col);
  end if;
  return p_col;
end;
--
function calculate_twice ( p_idx        IN pls_integer,
                           p_expression IN varchar2,
                           p_type       IN varchar2 default rtl.STRING_EXPR,
                           p_transform  IN boolean  default FALSE
                         ) return varchar2 is
    result   varchar2(2100);
    v_bin    boolean;
begin
    -- PLATFORM-11217
    -- Если в блоке инициализации пакета возникает ошибка, то при первом обращении к пакету константа не будет получена,
    -- необходимо получить константу еще раз.
    -- Начиная с Oracle 12, инициализация будет выполнятся при обращении к пакету до тех пор пока не будет завершена без ошибок
    -- в этом случае вернем ошибку.
    result := rtl.calculate(p_expression,p_type,p_transform);
    if result != p_expression then
      return result;
    end if;

    if p_type=rtl.NUMBER_EXPR then
      if p_transform and instr(p_expression,'''') = 0 then
        result:=upper(p_expression);
        if instr(translate(result,'DF','!!'),'!') > 0 then
          v_bin := ltrim(result,'+-/*0123456789EDF.() '||chr(9)||chr(10)) is null
                or instr(result,'BINARY_') > 0;
        end if;
      end if;
      result:='TO_CHAR('||p_expression||')';
    else
      result:=p_expression;
    end if;

    begin
      execute immediate 'BEGIN :RESULT:='||result||'; END;' using out result;
      if p_transform then
        if result is NULL then
            result:='null';
        elsif p_type=rtl.STRING_EXPR then
            result:=''''||replace(result,'''','''''')||'''';
        elsif p_type=rtl.NUMBER_EXPR then
          if result = 'Nan' then
            result := 'binary_double_nan';
          elsif result = 'Inf' then
            result := 'binary_double_infinity';
          elsif result = '-Inf' then
            result := '-binary_double_infinity';
          elsif v_bin and instr(result,'E') > 0 then
            result := result||'D';
          end if;
        end if;
      end if;
      return result;
    exception
      when others then
        if sqlcode in (-4061,-6508) then
          rtl.debug( 'var2plsql: '||sqlerrm||':'||NL||p_expression,1,false,null);
          raise;
        end if;
        plib.plp_error( p_idx, 'PARSER_ERROR', sqlerrm);
        return p_expression;
    end;
end calculate_twice;
-- @METAGS find_used
function  find_used ( p_x       IN varchar2,        --
                      p_idx     IN pls_integer,  --
                      p_class   IN varchar2,
                      used_tables in out nocopy plib.string_rec_tbl_t,
                      joins       in out nocopy plib.string_rec_tbl_t,
                      p_decl    in out nocopy varchar2,
                      p_text    in out nocopy varchar2,
                      tmp_idx   in out nocopy pls_integer,
                      or_idx    in out nocopy pls_integer,
                      p_repls   IN plib.idx_tbl_t,
                      tmp_pref  IN varchar2,
                      p_alias   IN varchar2,
                      p_l       IN pls_integer,
                      p_outer   IN pls_integer,
                      p_last    IN boolean,
                      p_mapped  IN varchar2,
                      p_crit    IN varchar2
                      ,p_part_all  IN boolean          -- PLATFORM-1507 - режим использования архивных разделов = 'ALL'
                    ) return boolean is
    eprog    varchar2(10000);
    etext    varchar2(10000);
    edecl    varchar2(1000);
    b_table  varchar2(100);
    b_class  varchar2(100);
    mgn      varchar2(100) := rpad(TAB,p_l+1,TAB);   -- left margin
    ppath    varchar2(2000);-- add_joins
    cls      varchar2(30);  -- add_joins
    col      varchar2(100); -- add_joins
    col1     varchar2(1000);-- add_joins
    col2     varchar2(1000);-- add_joins
    or_list  varchar2(256);
    not_obj  boolean;
    not_x    boolean;
    v_joins  boolean;
    v_crit   boolean;
    v_optim  boolean;
    v_or     boolean;
    v_t1     pls_integer;
    v_j1     pls_integer;
    b_part   pls_integer;
    or_cnt   pls_integer;
    and_cnt  pls_integer;
    or_tabs  plib.string_tbl_t;
    and_tabs plib.string_tbl_t;
    or_expr  plib.idx_tbl_t;
    and_expr plib.idx_tbl_t;
--
-- @METAGS join_text
    function join_text(p_idx pls_integer) return varchar2 is
        i   pls_integer;
        j   pls_integer;
        p   pls_integer;
    begin
        i := plib.find_record(used_tables,joins(p_idx).text1);
        j := plib.find_record(used_tables,joins(p_idx).text3);
        if instr(used_tables(j).text4,' partition')=0 then
          edecl := ' and '||p_alias||j||'.key>=';
          if ascii(used_tables(j).text4)=ASC_DIEZ then
            edecl := edecl||substr(used_tables(j).text4,2);
          else
            edecl := edecl||used_tables(j).text4;
          end if;
        else
          p := instr(used_tables(j).text4,'|');
          if p>0 then
            edecl := ' and '||p_alias||j||'.key='||substr(used_tables(j).text4,p+1);
          else
            edecl := null;
          end if;
        end if;
        p := instr(joins(p_idx).text4,'.');
        if p>1 then
          edecl := get_col_text(substr(joins(p_idx).text4,1,p-1),p_alias||j,substr(joins(p_idx).text4,p+1),false)||edecl;
        else
          edecl := get_col_text(joins(p_idx).text4,p_alias||j,null,false)||edecl;
        end if;
        p := instr(joins(p_idx).text2,'.');
        if p>1 then
          return get_col_text(substr(joins(p_idx).text2,1,p-1),p_alias||i,substr(joins(p_idx).text2,p+1),false)||'='||edecl;
        end if;
        return get_col_text(joins(p_idx).text2,p_alias||i,null,false)||'='||edecl;
    end;
--
    procedure get_or_list(p_tabs in out nocopy varchar2, p_list in out nocopy varchar2,
                          p_idx  pls_integer, p_add boolean) is
      i pls_integer;
      j pls_integer;
      n pls_integer;
    begin
      p_tabs := or_tabs(p_idx);
      if or_tabs.exists(-p_idx) then
        p_list := or_tabs(-p_idx);
        j := 1;
        loop
          i := instr(p_list,',',j+1);
          exit when i=0;
          n := substr(p_list,j+1,i-j-1);
          j := length(and_tabs(n));
          if j>1 then
            if p_add then
              p_tabs := and_tabs(n)||':'||n||':'||p_tabs;
            else
              p_tabs := substr(and_tabs(n),1,j-1)||p_tabs;
            end if;
          end if;
          j := i;
        end loop;
      else
        p_list := null;
      end if;
    end;
--
-- @METAGS findused
  function  findused ( p_idx     IN pls_integer,
                       p_replace IN boolean,
                       p_sibling IN boolean,
                       p_cast    IN pls_integer,
                       p_alias_override IN boolean -- true, если у текущего узла p_idx есть предок с типом узла plp$parser.SELECT_ с алиасом,
                                                   -- который совпадает с алиасом p_x, который пришел в find_used. На практике это означает,
                                                   -- например, в подзапросе у источников данных такой же алиас, как и у основного запроса.
                                                   -- false, иначе.
                     ) return boolean is
    idx      pls_integer;
    idx1     pls_integer;
    u_idx    pls_integer;
    typ      pls_integer;
    v_part   pls_integer;
    v_class  varchar2(30);
    o_class  varchar2(30);
    qual     varchar2(700);
    pqual    varchar2(700);
    path     varchar2(2000);
    itext    varchar2(2000);
    v_expr   varchar2(1000);-- add_joins
    v_qual   varchar2(1000);-- findused
    v_table  varchar2(200);
    v_column varchar2(40);
    b        boolean;
    scan     boolean;
    ok       boolean;
    obj_lock boolean;
    obj_coll boolean;
    obj_tbl  boolean;
    v_ovl    boolean;
    v_typ    boolean;
    v_cast   boolean;
    v_outcol boolean;
    v_repl   boolean;
    v_outer  pls_integer;
    v_out    pls_integer;
--
    procedure get_index(p_find boolean) is
      i pls_integer;
    begin
      i := plib.ir(idx).down;
      itext := null;
      if not i is null then
        if p_find then
          b := findused( i, p_replace, false, null, p_alias_override );
        end if;
        tmp_expr_idx := null;
        b := expr2plsql(i,p_decl,eprog,itext,mgn,false,true,null);
        p_text := p_text||eprog;
        b := null;
        plib.delete_node(i);
      end if;
    end;
--
    procedure get_ref_class(p_find boolean,p_col boolean) is
    begin
      get_index(p_find);
      if itext in ('''<REF$CLASS>''',NULL_CONST,NULL_STRING) then
        if o_class='<SUBQUERY>' then
          if cur_class like '%rowtype' then
            o_class := plib.g_class_id;
          else
            o_class := nvl(cur_class,plib.g_class_id);
          end if;
        end if;
        if p_col then
          lib.qual_column( o_class, 'CLASS_ID', eprog, itext, edecl, '2' );
          if eprog<>v_table or itext is null then
            itext := ''''||o_class||'''';
          elsif substr(itext,1,1)<>'''' then
            itext := p_alias||u_idx||'.'||itext;
          end if;
        else
          itext := ''''||o_class||'''';
        end if;
      end if;
    end;
--
    procedure get_ref_access(p_src varchar2,p_cls varchar2) is
      bb  boolean;
      src varchar2(10000);
    begin
      src:= p_src;
      bb := src is null;
      b := typ=plp$parser.DBOBJECT_;
      if v_outer=2 or (not use_context is null) and bObjChkMode then
        if bb then
          src := get_col_text(v_column,p_alias||u_idx,v_expr,false);
          used_tables(u_idx).text3 := substr(used_tables(u_idx).text3,1,1)||'01';
        end if;
        if lib.has_stringkey(p_cls) then
          etext := 'o.obj_id';
        else
          etext := 'to_number(o.obj_id)';
        end if;
        if b then
          src := src||' in (select '||etext||' from object_rights o, subj_equal e where e.subj_id='||itext
              ||' and o.subj_id=e.equal_id';
        else
          src := src||' in (select '||etext||' from object_rights_ex o, subj_equal e where e.subj_id='||itext
              ||' and o.subj_id=e.equal_id';
          get_ref_class(bb,false);
          src := src||' and o.right_class_id='||itext;
        end if;
        get_index(bb);
        if itext not in (NULL_CONST,NULL_STRING) then
          src := src||' and o.class_id='||itext;
        end if;
      elsif Use_Context and bRhtContext and (bObjContext and b or bRefContext and not b)
       and upper(replace(itext,' '))='SYS_CONTEXT('''||inst_info.Owner||'_SYSTEM'',''USER'')'  then
        if bb then
          src := get_col_text(v_column,p_alias||u_idx,v_expr,v_outcol);
        end if;
        if b then
          src := '(sys_context('''||inst_info.Owner||'_ORIGHTS'','||src||') like ''_%''';
          b := null;
        else
          get_ref_class(bb,bb);
          src := '(sys_context('''||inst_info.Owner||'_ERIGHTS'',('||itext||')||'||src||')=''0''';
        end if;
      else
        if bb then
          src := get_col_text(v_column,p_alias||u_idx,v_expr,false);
        end if;
        if not lib.has_stringkey(p_cls) then
          src := 'to_char('||src||')';
        end if;
        if b then
          src := 'exists (select 1 from object_rights o, subj_equal e where e.subj_id='||itext
              ||' and o.subj_id=e.equal_id and o.obj_id='||src;
        else
          src := 'exists (select 1 from object_rights_ex o, subj_equal e where e.subj_id='||itext
              ||' and o.subj_id=e.equal_id and o.obj_id='||src;
          get_ref_class(bb,bb);
          src := src||' and o.right_class_id='||itext;
        end if;
        get_index(bb);
        if itext not in (NULL_CONST,NULL_STRING) then
          src := src||' and o.class_id='||itext;
        end if;
      end if;
      eprog := NL||mgn||src||')'||NL||mgn;
    end;
--
    procedure put_outer_join(i pls_integer, bpath boolean) is
        col varchar2(1);
        s   varchar2(5);
    begin
        s := nvl(used_tables(u_idx).text3,'000');
        if obj_lock then
          s := '1'||substr(s,2);
          col := '1';
          if not i is null then
            used_tables(i).text3 := col||substr(used_tables(i).text3,2);
          end if;
        else
          col := substr(s,1,1);
        end if;
        if v_outer = 2 then
            s := col||'11';
        elsif v_outer = 1 or v_out = 1 then
            s := col||'01';
            if i>1 then
                used_tables(i).text3 := s;
            end if;
        elsif v_out = 2 and (u_idx=1 or instr(path,':')>0) then
            s := col||'11';
        elsif substr(s,3,1)='0' then
          if bpath and (p_outer>0 or v_or)then
            if p_outer>0 or u_idx>v_t1 then
              s := col||'10';
            end if;
          elsif not (p_outer>0 or v_or) then
            s := col||'00';
            if i>1 and substr(used_tables(i).text3,3,1)='0' then
              used_tables(i).text3 := s;
            end if;
          elsif i>1 then
            s := col||substr(used_tables(i).text3,2,1)||'0';
          end if;
        end if;
        used_tables(u_idx).text3 := s;
        if v_or then
          if instr(or_list,','||u_idx||',')=0 then
            or_list := or_list||u_idx||',';
          end if;
        end if;
    end;
--
    procedure add_prt_prop(col varchar2,cls varchar2) is
      j       pls_integer;
    begin
      if p_part_all then        -- PLATFORM-1507 - режим использования архивных разделов = 'ALL'
        return;
      end if;
      if u_idx>1 or b_part is null then
        if not itext is null then
          if col=constant.YES then
            used_tables(u_idx).text4 := itext;
          elsif col!=constant.NO then
            used_tables(u_idx).text4 := '#'||itext;
          end if;
          if u_idx>1 and b_part is null and not v_typ and instr(used_tables(u_idx).text1,':')=0 then
            j := 1;
            while j<u_idx loop
              if (instr(used_tables(j).text1,':')=0) and def_tmp_part(used_tables(j).text4) then
                if ascii(used_tables(j).text4)=ASC_DIEZ then
                  used_tables(j).text4 := '#'||itext;
                else
                  used_tables(j).text4 := itext;
                end if;
              end if;
              j := used_tables.next(j);
            end loop;
          end if;
        elsif col!=constant.NO then
          if not v_part is null then
            lib.get_partition(used_tables(u_idx).text4,j,cls,v_part);
            if used_tables(u_idx).text4=v_table then
              used_tables(u_idx).text4 := ' partition';
            elsif ascii(used_tables(u_idx).text4)=ASC_DIEZ then
              if col=constant.YES then
                used_tables(u_idx).text4 := ' partition'||used_tables(u_idx).text4||'|'||j;
              else
                used_tables(u_idx).text4 := ' partition'||used_tables(u_idx).text4;
              end if;
            elsif col=constant.YES then
              used_tables(u_idx).text4 := ' partition('||nvl(used_tables(u_idx).text4,v_table||'#0')||')|'||nvl(j,1000);
            else
              used_tables(u_idx).text4 := '# partition|'||nvl(j,1000);
            end if;
          elsif used_tables(u_idx).text4 is null then
            if v_column='KEY' and p_outer<=0 then
              if col=constant.YES then
                used_tables(u_idx).text4 := ' partition';
              else
                used_tables(u_idx).text4 := '# partition';
              end if;
            elsif plib.g_method_arch then
              j := 1;
              if u_idx>1 and not v_typ and instr(used_tables(u_idx).text1,':')=0 and instr(used_tables(1).text4,' partition')=0 then
                if not def_tmp_part(used_tables(1).text4) then
                  if ascii(used_tables(1).text4)=ASC_DIEZ then
                    if col=constant.YES then
                      used_tables(u_idx).text4 := substr(used_tables(1).text4,2);
                    else
                      used_tables(u_idx).text4 := used_tables(1).text4;
                    end if;
                  elsif col=constant.YES then
                    used_tables(u_idx).text4 := used_tables(1).text4;
                  else
                    used_tables(u_idx).text4 := '#'||used_tables(1).text4;
                  end if;
                  j := 0;
                end if;
              end if;
              if j>0 then
                if col=constant.YES then
                  used_tables(u_idx).text4 := add_tmp_part(cls,tmp_pref||'P',mgn,tmp_idx,p_decl);
                else
                  used_tables(u_idx).text4 := '#'||add_tmp_part(cls,tmp_pref||'P',mgn,tmp_idx,p_decl);
                end if;
              end if;
            elsif col=constant.YES then
              used_tables(u_idx).text4 := ' partition';
            else
              used_tables(u_idx).text4 := '# partition';
            end if;
          elsif v_column='KEY' and p_outer<=0 then
            if used_tables(u_idx).text4 like '%'||plib.var('%')||'$P%' then
              if col=constant.YES then
                used_tables(u_idx).text4 := ' partition';
              else
                used_tables(u_idx).text4 := '# partition';
              end if;
            end if;
          end if;
        end if;
      end if;
    end;
--
    function get_attr_expr(edecl varchar2) return boolean is
      v_self  varchar2(16);
      v_btyp  pls_integer;
    begin
      v_self := substr(edecl,instr(edecl,'.',1,3)+1,instr(edecl,'.',1,4)-instr(edecl,'.',1,3)-1);
      v_btyp := plib.convert_base(substr(edecl,1,instr(edecl,'.')-1));
      --class_utils.base2sql(substr(edecl,1,instr(edecl,'.')-1),cls,cls,col,v_self,null,true,null);
      cls := substr(edecl,instr(edecl,'.',-1)+1);
      if obj_coll or obj_lock or v_ovl then
        u_idx := null;
      elsif v_typ then
        if cls=v_class then
          u_idx := plib.find_record(used_tables,nvl(path,p_alias||'$'||v_table),v_table);
        else
          u_idx := null;
        end if;
      elsif path is null then
        u_idx := nvl(plib.find_record(used_tables,p_alias||'$'||v_table),1);
      else
        u_idx := plib.find_record(used_tables,path);
      end if;
      if itext is null then
        if not plib.g_method_arch then
          eprog := ',0)';
        elsif not plib.g_prt_actual then
          eprog := ','||get_def_partkey(p_class,false)||')';
        else
          eprog := ')';
        end if;
      else
        eprog := ','||itext||')';
      end if;
      if v_btyp = plp$parser.BOOLEAN_ then
        v_btyp := -v_btyp;
      end if;
      col := '1';
      if u_idx is null then
        v_expr := get_iface_call(col,'<$COL$>',cls,qual,v_self,v_btyp,false)||eprog;
        --v_expr := class_mgr.interface_package(cls)||'.get_'||col||'(<$COL$>,'''||qual||eprog;
        col := 'id';
      else
        v_expr := get_iface_call(col,nvl(v_expr,'<$COL$>'),cls,qual,v_self,v_btyp,false)||eprog;
        --v_expr := class_mgr.interface_package(cls)||'.get_'||col||'('||nvl(v_expr,'<$COL$>')||','''||qual||eprog;
        v_table := used_tables(u_idx).text2;
        col := nvl(v_column,'ID');
        return false;
      end if;
      return true;
    end;
--
    function get_expr(edecl varchar2) return boolean is
    begin
      if edecl is null then
        cls := null;
        v_expr := null;
        return true;
      end if;
      case substr(edecl,instr(edecl,'.',1,2)+7,1)
        when constant.METHOD_ATTRIBUTE then
          return get_attr_expr(edecl);
        when constant.PRIMARY_ATTR then
          cls := v_class;
          v_table := lib.class_table(v_class);
          if obj_coll or obj_lock or v_ovl then
            u_idx := null;
          elsif v_typ then
            u_idx := plib.find_record(used_tables,nvl(path,p_alias||'$'||v_table),v_table);
          elsif path is null then
            u_idx := nvl(plib.find_record(used_tables,p_alias||'$'||v_table),1);
          else
            u_idx := plib.find_record(used_tables,path,v_table);
          end if;
          if u_idx is null then
            col := 'id';
          else
            v_table := used_tables(u_idx).text2;
            col := nvl(v_column,'ID');
            return false;
          end if;
        else
          cls := substr(edecl,instr(edecl,'.',-1)+1);
          v_expr := null;
      end case;
      return true;
    end;
--
    procedure add_joins(p_err boolean, p_mapped varchar2) is
        i     pls_integer;
        j     pls_integer;
        v_add boolean;
    begin
        ppath:= path;
        if ppath is NULL then            -- the same class, maybe different table
            obj_lock := obj_lock or p_outer is null;
            if v_joins then
              --if length(v_class) > 16 then
              --  stdio.put_line_buf('>>>'||v_class||'.'||qual);
              --end if;
              lib.qual_column( v_class, qual, v_table, col, edecl, p_mapped );
              if col is null then
                if p_err then
                  v_column := null;
                  v_expr := null;
                  return;
                elsif qual is null then
                  return;
                end if;
              end if;
              v_add := get_expr(edecl);
              if use_java then
                plp2java.add_sync(cls,substr(edecl,instr(edecl,'.',1,2)+6,1)=constant.NO);
              end if;
              v_column:= col;
            else
              v_table := b_table;
              v_column:= qual;
              v_expr:= null;
              edecl := null;
              v_add := true;
            end if;
            path := p_alias||'$'||v_table;
            if v_table = b_table then
                u_idx := 1;
            elsif v_add then
                i := 1;
                u_idx := plib.add_unique( joins, p_alias||'$'||b_table, 'id', path, 'id' );
                u_idx := plib.add_unique( used_tables, path, v_table);
            end if;
            if v_crit and v_ovl then
              if v_joins is null then
                v_qual := v_class||':@';
              else
                v_qual := v_class||':';
              end if;
            end if;
        elsif obj_tbl then
            i:= plib.find_record(used_tables,ppath);
            v_table := 'table('||get_col_text(v_column,p_alias||i,v_expr,false)||')';
            path := path||':'||plib.ns(pqual);
            u_idx:= plib.add_unique( used_tables, path, v_table );
            v_column:= qual;
            v_expr:= null;
            edecl := null;
            if v_crit then
              v_qual := v_qual||plib.ns(pqual)||'.';
              if v_ovl then
                v_qual := v_qual||v_class||':';
              end if;
              v_qual := v_qual||'@';
            end if;
        else
            lib.qual_column ( v_class, qual, v_table, col, edecl, p_mapped );
            if col is null then
              if p_err then
                v_column := null;
                v_expr := null;
                return;
              elsif qual is null then
                return;
              end if;
            end if;
            col1 := v_column;
            if not v_expr is null then
              col1 := col1||'.'||v_expr;
              --stdio.put_line_buf('>>>'||col1||'<'||path);
            end if;
            v_add := get_expr(edecl);
            if use_java then
              plp2java.add_sync(cls,substr(edecl,instr(edecl,'.',1,2)+6,1)=constant.NO);
            end if;
            i := null;
            if col1 = 'ID' then
              if v_add then
                u_idx:= plib.find_record(used_tables,path);
                if u_idx is null then
                  u_idx:= plib.add_unique( used_tables, path, v_table, p_find => false);
                elsif v_table != used_tables(u_idx).text2 then
                  i:= u_idx;
                  path := path||'|'||v_table;
                  u_idx:= plib.add_unique( joins, ppath, 'id', path, 'id' );
                  u_idx:= plib.add_unique( used_tables, path, v_table);
                end if;
              end if;
              v_column := col;
            elsif not col is null then
              if pqual='%objparent' then
                col1 := 'COLLECTION_ID';
                col2 := col;
                if not v_expr is null then
                  col2 := col2||'.'||v_expr;
                end if;
              else
                if obj_coll then
                  col2 := 'collection_id';
                else
                  col2 := 'id';
                end if;
              end if;
              v_column := col;
              if v_crit then
                v_qual := v_qual||plib.ns(pqual)||'.';
                if v_ovl then
                  v_qual := v_qual||v_class||':';
                end if;
              end if;
             if v_add then
              path := path||':'||plib.ns(pqual);
              j := plib.find_record(used_tables,path);
              if v_typ or obj_coll then
                if j is null then
                  j := plib.add_unique( joins, ppath, col1, path, col2 );
                  i := plib.find_record(used_tables,ppath);
                  if cls=v_class then
                    u_idx := plib.add_unique( used_tables, path, v_table, p_find => false );
                  else
                    col := v_table;
                    lib.qual_column ( v_class, '%ID', v_table, eprog, etext, p_mapped );
                    u_idx := plib.add_unique( used_tables, path, v_table, p_find => false );
                    if not etext is null then
                      add_prt_prop(substr(etext,instr(etext,'.',1,2)+5,1),v_class);
                    end if;
                    put_outer_join(i,true);
                    i := u_idx;
                    v_table := col;
                    ppath:= path;
                    path := path||'|'||v_table;
                    j := plib.find_record(joins,null,null,path);
                    if j is null then
                      j := plib.add_unique( joins, ppath, 'id', path, 'id', p_find => false );
                    else
                      joins(j).text1 := ppath;
                      joins(j).text2 := 'id';
                      joins(j).text4 := 'id';
                    end if;
                    u_idx := plib.add_unique( used_tables, path, v_table );
                  end if;
                else
                  i := plib.find_record(used_tables,ppath);
                  if cls=v_class then
                    if v_table=used_tables(j).text2 then
                      u_idx := j;
                      j := plib.add_unique( joins, ppath, col1, path, col2 );
                    else
                      path := path||'|'||v_table;
                      j := plib.find_record(joins,null,null,path);
                      if j is null then
                        j := plib.add_unique( joins, ppath, col1, path, col2, p_find => false );
                      else
                        joins(j).text1 := ppath;
                        joins(j).text2 := col1;
                        joins(j).text4 := col2;
                      end if;
                      u_idx := plib.add_unique( used_tables, path, v_table );
                    end if;
                  else
                    col := v_table;
                    lib.qual_column ( v_class, '%ID', v_table, eprog, etext, p_mapped );
                    if v_table=used_tables(j).text2 then
                      u_idx := j;
                      j := plib.add_unique( joins, ppath, col1, path, col2 );
                    else
                      path := path||'|'||v_table;
                      j := plib.find_record(joins,null,null,path);
                      if j is null then
                        j := plib.add_unique( joins, ppath, col1, path, col2, p_find => false );
                      else
                        joins(j).text1 := ppath;
                        joins(j).text2 := col1;
                        joins(j).text4 := col2;
                      end if;
                      u_idx := plib.add_unique( used_tables, path, v_table );
                    end if;
                    if not etext is null then
                      add_prt_prop(substr(etext,instr(etext,'.',1,2)+5,1),v_class);
                    end if;
                    put_outer_join(i,true);
                    i := u_idx;
                    v_table := col;
                    ppath:= path;
                    path := path||'|'||v_table;
                    j := plib.find_record(joins,null,null,path);
                    if j is null then
                      j := plib.add_unique( joins, ppath, 'id', path, 'id', p_find => false );
                    else
                      joins(j).text1 := ppath;
                      joins(j).text2 := 'id';
                      joins(j).text4 := 'id';
                    end if;
                    u_idx := plib.add_unique( used_tables, path, v_table );
                  end if;
                end if;
              else
                if j is null then
                  i := plib.find_record(used_tables,path||'|'||v_table);
                  if cls=v_class and i is null then  -- new paradigma
                    u_idx:= plib.add_unique( used_tables, path, v_table, p_find => false );
                  else
                    path := path||'|'||v_table;
                    u_idx:= plib.add_unique( used_tables, path, v_table );
                  end if;
                  j := plib.find_record(joins,null,null,path);
                  if j is null then
                    j := plib.add_unique( joins, ppath, col1, path, col2, p_find => false );
                  else
                    ppath := joins(j).text1;
                  end if;
                  i := plib.find_record(used_tables,ppath);
                else
                  if v_table=used_tables(j).text2 then
                    u_idx := j;
                    j := plib.add_unique( joins, ppath, col1, path, col2 );
                    i := plib.find_record(used_tables,ppath);
                  elsif cls=v_class then
                    path := path||'|'||v_table;
                    j := plib.find_record(joins,null,null,path);
                    if j is null then
                      j := plib.add_unique( joins, ppath, col1, path, col2, p_find => false );
                    else
                      ppath := joins(j).text1;
                    end if;
                    i := plib.find_record(used_tables,ppath);
                    u_idx := plib.add_unique( used_tables, path, v_table );
                  else
                    i := j;
                    ppath:= path;
                    path := path||'|'||v_table;
                    j := plib.find_record(joins,null,null,path);
                    if j is null then
                      j := plib.add_unique( joins, ppath, 'id', path, 'id', p_find => false );
                    else
                      ppath := joins(j).text1;
                      i := plib.find_record(used_tables,ppath);
                    end if;
                    u_idx := plib.add_unique( used_tables, path, v_table );
                  end if;
                end if;
              end if;
             end if;
            end if;
        end if;
        if not_obj and v_table='OBJECTS' or v_column is null then
          --if p_err then
            plib.plp_error(idx1,'NO_TABLE_COLUMN',qual,v_class);
          --end if;
        end if;
        if not edecl is null then
          add_prt_prop(substr(edecl,instr(edecl,'.',1,2)+5,1),cls);
        end if;
        put_outer_join(i,not ppath is null);
        v_outcol := v_out=2 and not (p_outer>0 or v_or);
        pqual := qual;
        qual  := null;
        v_part:= null;
        itext := null;
        v_ovl := false;
        v_typ := false;
        v_out := 0;
        obj_lock:=false;
    end;
--
-- @METAGS add_mods
    procedure add_mods is
        i   pls_integer;
        prt pls_integer;
    begin
        prt:=v_part;
        typ:=plib.ir(idx).type1;
        if typ in (plp$parser.OBJ_ID_,plp$parser.REF_,plp$parser.DBOBJECT_,plp$parser.MODIFIER_,plp$parser.IS_,plp$parser.ANY_) then
          qual := '%ID';
          if obj_coll or v_ovl or v_typ then
            if b and typ=plp$parser.OBJ_ID_ then
              get_index(true);
            end if;
            add_joins(false,'0');
            v_column := 'ID';
            v_expr := null;
          else
            v_column := nvl(v_column,'ID');
            if path is null then
              path := p_alias||'$'||v_table;
              u_idx := plib.find_record( used_tables, path, v_table );
              if p_outer is null then
                used_tables(1).text3 := '100';
                used_tables(u_idx).text3 := '100';
              end if;
            else
              u_idx := plib.find_record( used_tables, path, v_table );
            end if;
            if v_outer in (1,2) then
              put_outer_join(null,false);
            end if;
          end if;
          if typ=plp$parser.IS_ then
            if not plib.ir(idx).down is null then
              typ := plp$parser.ANY_;
            end if;
            b := false;
          else
            b := typ=plp$parser.OBJ_ID_;
          end if;
        elsif typ in (plp$parser.OBJ_STATE_,plp$parser.STRING_) then
          qual := 'STATE_ID';
          if b then get_index(true); end if;
          if p_outer>0 and typ=plp$parser.OBJ_STATE_ then
            add_joins(true,'2');
            if v_column is null then
              v_column := NULL_STRING;
              v_expr := null;
            end if;
          else
            add_joins(false,'2');
          end if;
          b := typ=plp$parser.OBJ_STATE_;
        elsif typ in (plp$parser.OBJ_CLASS_,plp$parser.OBJ_CLASS_PARENT_,plp$parser.OBJ_CLASS_ENTITY_,plp$parser.STRING_CONST_) then
          qual := 'CLASS_ID';
          if b then get_index(true); end if;
          if p_outer>0 then
            add_joins(true,'2');
          else
            add_joins(false,'2');
            if p_mapped='1' and v_column like '''%' then
              plib.plp_error(idx1,'NO_TABLE_COLUMN',pqual,v_class);
            end if;
          end if;
          b := typ=plp$parser.OBJ_CLASS_;
        elsif typ = plp$parser.OBJ_COLLECTION_ then
          qual := 'COLLECTION_ID';
          if b then get_index(true); end if;
          if p_outer>0 then
            add_joins(true,'2');
            if v_column is null then
              v_column := 'to_number('''')';
              v_expr := null;
            end if;
          else
            add_joins(false,'2');
          end if;
          b := true;
        elsif typ in (plp$parser.OBJ_PARENT_,plp$parser.DBCLASS_) then
          qual := 'COLLECTION_ID';
          add_joins(false,'2');
          b := false;
        elsif typ = plp$parser.ROWID_ then
          qual := '%ROWID';
          add_joins(false,'0');
          b := true;
        elsif typ = plp$parser.ATTR_ then
          qual := '%KEY';
          add_joins(false,'0');
          b := true;
        elsif typ = plp$parser.NUMBER_ then
          qual := '%SN';
          if b then get_index(true); end if;
          add_joins(false,'0');
          b := true;
        elsif typ = plp$parser.NUMHIGH_ then
          qual := '%SU';
          add_joins(false,'0');
          b := true;
        elsif typ = plp$parser.NUMLOW_ then
          qual := '%ORA_ROWSCN';
          add_joins(false,'0');
          b := true;
        else
          qual := null;
          b := false;
        end if;
        if b then b := false;
        elsif typ in (plp$parser.SOS_,plp$parser.REF_,plp$parser.DBOBJECT_,plp$parser.MODIFIER_,plp$parser.ANY_) then
          get_index(true);
          if typ=plp$parser.SOS_ then
            if obj_coll then
              eprog := get_col_text(v_column,p_alias||u_idx,v_expr,v_outcol);
            else
              eprog := NULL_CONST;
            end if;
            if use_java then
              plp2java.add_sync(plib.ir(idx).text,null);
            end if;
            etext := class_mgr.interface_package(plib.ir(idx).text)||'.count$('||eprog||','||itext;
            get_index(true);
            if itext is null then
              eprog := etext||')';
            else
              eprog := etext||','||itext||')';
            end if;
          elsif typ=plp$parser.MODIFIER_ then
            etext := itext;
            get_index(true);
            if not itext is null then
              etext := etext||','||itext;
            end if;
            get_index(true);
            if not itext is null then
              etext := etext||','||itext;
            end if;
            if use_java then
              plp2java.add_sync(v_class,null);
            end if;
            eprog := class_mgr.interface_package(v_class)||'.get$value('
                  || get_col_text(v_column,p_alias||u_idx,v_expr,v_outcol)||','||etext||')';
          elsif typ=plp$parser.ANY_ then
            v_class := plib.ir(idx).text;
            etext := itext;
            get_index(true);
            if use_java then
              plp2java.add_sync(v_class,null);
            end if;
            etext := class_mgr.interface_package(v_class)||'.get_arch('
                  || get_col_text(v_column,p_alias||u_idx,v_expr,v_outcol)||','||etext||','||itext;
            get_index(true);
            if itext is null then
              i := plib.ir(idx).right;
              if i is null then
                eprog := etext||')';
              else
                eprog := etext||','''||plib.ir(i).text||''')';
                plib.delete_node(i);
              end if;
            else
              eprog := etext||','||itext||')';
            end if;
          else
            get_ref_access(null,plib.ir(idx).text);
            plib.ir(p_idx).type1 := plp$parser.NULL_;
          end if;
          itext := null;
        else
          i := u_idx;
          if typ in (plp$parser.OBJ_CLASS_PARENT_,plp$parser.OBJ_CLASS_ENTITY_,plp$parser.STRING_CONST_) then
            u_idx := plib.add_unique( joins, path, v_column||plib.nn('.',v_expr), path||':'||plib.ns(pqual), 'id' );
            v_table := 'CLASSES';
            v_expr:= null;
            if typ=plp$parser.OBJ_CLASS_PARENT_ then
              qual := '%classparent';
              v_column:= 'PARENT_ID';
            elsif typ=plp$parser.OBJ_CLASS_ENTITY_ then
              qual := '%entity';
              v_column:= 'ENTITY_ID';
            else
              qual := '%classname';
              v_column:= 'NAME';
            end if;
          elsif typ in (plp$parser.OBJ_PARENT_,plp$parser.DBCLASS_,plp$parser.CLASS_REF_,plp$parser.OBJECT_REF_) then
            u_idx := instr(plib.ir(idx).text1,'.',-1);
            if u_idx>0 and typ=plp$parser.OBJ_PARENT_ then
              v_class := substr(plib.ir(idx).text1,u_idx+1);
              qual := substr(plib.ir(idx).text1,1,u_idx-1);
              v_out:= instr(qual,'.');
              if v_out>0 then
                typ := substr(qual,1,v_out-1);
                qual:= substr(qual,v_out+1);
              end if;
              if typ>0 then
                typ := null;
              end if;
              v_out:= 0;
              v_typ:= false;
              pqual:= '%objparent';
              v_part := typ;
              add_joins(false,p_mapped);
              qual := '%ID';
              v_column:= 'ID';
              v_expr := null;
              v_part := typ;
              add_joins(false,'0');
              pqual:= '%objparent';
              qual := '%parent';
            else
              v_table := storage_mgr.view_col2obj_name(v_class);
              select count(1) into u_idx from user_views where view_name=v_table;
              if u_idx>0 then
                qual := 'id';
              else
                v_table := 'COL2OBJ';
                qual := 'collection_id';
              end if;
              v_part:= prt;
              u_idx := plib.add_unique( joins, path, v_column||plib.nn('.',v_expr), path||':'||plib.ns(pqual), qual );
              v_expr:= null;
              if typ=plp$parser.DBCLASS_ then
                v_column:= 'CLASS_ID';
                qual := '%parentclass';
              elsif typ=plp$parser.CLASS_REF_ then
                v_column:= 'CLASS_ID';
                qual := '%class';
              else
                v_column:= 'OBJECT_ID';
                qual := '%parent';
              end if;
            end if;
          elsif typ=plp$parser.STRING_ then
            u_idx:= plib.add_unique( joins, path, 'STATE_ID', path||':'||plib.ns(pqual), 'id' );
            u_idx:= plib.add_unique( joins, path, 'CLASS_ID', path||':'||plib.ns(pqual), 'class_id' );
            v_table := 'STATES';
            v_column:= 'NAME';
            v_expr := null;
            qual := '%statename';
          elsif typ=plp$parser.IS_ then
            i := plib.ir(idx).right;
            if i is null then
              qual := 'VALUE';
              v_out:= v_outer;
            else
              qual := plib.ir(i).text;
              v_out:= plib.ir(i).node;
              plib.delete_node(i);
            end if;
            pqual := '%arch';
            i := u_idx;
            u_idx := plib.add_unique( joins, path, v_column||plib.nn('.',v_expr), path||':'||pqual, 'id' );
            v_class := plib.ir(idx).text;
            v_table := null;
            if lib.table_exist(v_class,table_info,true) then
              v_table := table_info.log_table;
            end if;
            if v_table is null then
              plib.plp_error(idx,'NO_TABLE_COLUMN',pqual,v_class);
            end if;
            v_class := table_info.class_id;
            v_outer := v_out;
            v_column:= qual;
            v_expr:= null;
          else
            i := 0;
            plib.plp_error(idx,'CHANGE_DATABASE');
          end if;
          v_out:= 0;
          if i>0 then
            if pqual='%objparent' then null; else
              path := path||':'||plib.ns(pqual);
              if v_crit then
                v_qual := v_qual||plib.ns(pqual)||'.';
                if v_ovl then
                  v_qual := v_qual||v_class||':';
                end if;
              end if;
            end if;
            u_idx:= plib.add_unique( used_tables, path, v_table);
            put_outer_join(i,true);
          end if;
          pqual:= qual;
        end if;
        if not plib.ir(idx).right is null then
          v_class := substr(plib.ir(idx).text1,instr(plib.ir(idx).text1,'.',-1)+1);
        end if;
        v_outcol := v_outer=2 and not (p_outer>0 or v_or);
        qual := null;
        v_ovl:= false;
        v_typ:= false;
    end;
--
    procedure process_or_expr is
      l   pls_integer;
      i   pls_integer;
      j   pls_integer;
      ii  pls_integer;
      t1  pls_integer;
      t2  pls_integer;
      s1  varchar2(2000);
      s2  varchar2(2000);
      st  varchar2(10);
      t   plib.idx_tbl_t;
      q   plib.string_tbl_t;
    begin
      get_or_list(ppath,qual,1,false);
      loop -- excluding same tables and joins
        i := instr(ppath,',',2);
        exit when i=0;
        s1:= substr(ppath,1,i);
        t1:= substr(s1,2,i-2);
        ppath := replace(ppath,s1,',');
        b := true;
        for i in 2..or_cnt loop
          get_or_list(path,qual,i,false);
          if instr(path,s1)=0 then
            b := false; exit;
          end if;
        end loop;
        if b or t1<=v_t1 then
          for i in 1..or_cnt loop
            or_tabs(i) := replace(or_tabs(i),s1,',');
          end loop;
          for i in 1..and_cnt loop
            and_tabs(i):= replace(and_tabs(i),s1,',');
          end loop;
          if b and substr(used_tables(t1).text3,3,1)='0' then
            used_tables(t1).text3 := substr(used_tables(t1).text3,1,1)||'00'; -- set inner join
          end if;
        end if;
      end loop;
      if not v_optim then return; end if;
      l := 1000;
      for i in 1..or_cnt loop
        get_or_list(path,qual,i,false);
        j := length(path);
        if j<l then l:=j; end if;
      end loop;
      if l<2 then return; end if;
      /*stdio.put_line_buf('******');
      plib.dump_strings(joins,'joins',0);
      plib.dump_strings(used_tables,'tables',0);
      stdio.put_line_buf('!!! 2 !!! '||l);
      for i in 1..or_cnt loop
        stdio.put_line_buf('OR'||i||':'||or_expr(i)||'<'||or_tabs(i)||'>');
        if or_tabs.exists(-i) then
          stdio.put_line_buf('XX'||i||':'||or_tabs(-i));
        end if;
      end loop;
      for i in 1..and_cnt loop
        stdio.put_line_buf('AND'||i||':'||and_expr(i)||'<'||and_tabs(i)||'>');
      end loop;*/
      get_or_list(ppath,qual,1,true);
      --stdio.put_line_buf('<'||ppath||'><'||qual||'>');
      loop -- adding joins to branches for same tables
        i := instr(ppath,',',2);
        exit when i=0;
        s1:= substr(ppath,1,i);
        ppath := replace(ppath,s1,',');
        if substr(s1,2,1)<>':' then
          t1:= substr(s1,2,i-2);
          s2:= used_tables(t1).text2;
          if t1>v_t1 and instr(used_tables(t1).text1,':')>0 then
            --stdio.put_line_buf('** '||t1||'<'||ppath||'><'||used_tables(t1).text1||'><'||s2||'><'||s1||'>');
            t.delete;
            for i in 2..or_cnt loop
              b := false;
              get_or_list(path,qual,i,true);
              j := instr(path,s1);
              if j>0 then
                t2:= t1;
                b := true;
              else
                j := 1;
                loop
                  ii := instr(path,',',j+1);
                  exit when ii=0;
                  if substr(path,j+1,1)<>':' then
                    t2 := substr(path,j+1,ii-j-1);
                    if t2>v_t1 and used_tables.exists(t2) then
                     itext := used_tables(t2).text1;
                     if instr(itext,':')>0 and used_tables(t2).text2=s2 then
                      b := false;
                      if used_tables(t1).text3=used_tables(t2).text3
                        and nvl(used_tables(t1).text4,'!')=nvl(used_tables(t2).text4,'!')
                      then
                        b := true;
                        st:= ','||t2||',';
                        for k in 1..i-1 loop
                          if k=1 or t2<>t(k) then
                            get_or_list(s2,qual,k,true);
                            if instr(s2,st)>0 then
                              b := false; exit;
                            end if;
                          end if;
                        end loop;
                        s2:= used_tables(t1).text2;
                      end if;
                      exit when b;
                      qual := p_alias||'$OR$:';
                      if instr(itext,qual) = 1 then -- add deleted join
                        l := plib.find_record(joins,null,null,itext,null,v_j1);
                        if l is not null then
                          or_idx := or_idx + 1;
                          typ := instr(itext,':',1,2);
                          if typ > 0 then
                            itext := qual||or_idx||substr(itext,typ);
                          else
                            itext := qual||or_idx;
                          end if;
                          l := plib.add_unique(joins,joins(l).text1,joins(l).text2,itext,joins(l).text4,false);
                          used_tables(t2).text1 := itext;
                        end if;
                      end if;
                     end if;
                    end if;
                  end if;
                  j := ii;
                end loop;
              end if;
              if b then
                t(i) := t2;
                j := instr(path,':',j);
                if j>0 then
                  j := substr(path,j+1,instr(path,':',j+1)-j-1);
                  t(-i):= -j;
                else
                  t(-i):= i;
                end if;
                --stdio.put_line_buf('## '||t(i)||'.'||t(-i)||'<'||path||'><'||s2||'>');
              else exit;
              end if;
            end loop;
            if t.count = (or_cnt-1)*2 then
              t(1) := t1;
              j := instr(ppath,':');
              if j>0 then
                j := substr(ppath,j+1,instr(ppath,':',j+1)-j-1);
                t(-1):= -j;
              else
                t(-1):= 1;
              end if;
              or_idx := or_idx + 1;
              path := p_alias||'$OR$:'||or_idx;
              for i in 1..or_cnt loop
                t2:= t(i);
                s1:= used_tables(t2).text1;
                --stdio.put_line_buf('++'||i||'.'||t2||'<'||s1||'>'||used_tables(t2).text2);
                if s1=path then
                  qual := q(t2);
                else
                  l := length(s1);
                  j := joins.next(v_j1);
                  qual := null;
                  while not j is null loop
                    s2 := joins(j).text1;
                    if instr(s2,s1)=1 then
                      if length(s2)=l then
                        joins(j).text1:=path;
                      elsif substr(s2,l+1,1)=':' then
                        joins(j).text1:=path||substr(s2,l+1);
                      end if;
                    end if;
                    s2 := joins(j).text3;
                    if instr(s2,s1)=1 then
                      if length(s2)=l then
                        if not qual is NULL then
                          qual := qual||' and ';
                        end if;
                        qual := qual||join_text(j);
                        joins.delete(j);
                      elsif substr(s2,l+1,1)=':' then
                        joins(j).text3:=path||substr(s2,l+1);
                      end if;
                    end if;
                    j := joins.next(j);
                  end loop;
                  j := joins.next(v_j1);
                  while not j is null loop
                    ii := j;
                    loop
                      ii := plib.find_record(joins,joins(j).text1,joins(j).text2,joins(j).text3,joins(j).text4,ii);
                      exit when ii is null;
                      joins.delete(ii);
                    end loop;
                    j := joins.next(j);
                  end loop;
                  j := used_tables.next(v_t1);
                  while not j is null loop
                    s2 := used_tables(j).text1;
                    if instr(s2,s1)=1 then
                      if length(s2)=l then
                        used_tables(j).text1:=path;
                        q(j):= qual;
                      elsif substr(s2,l+1,1)=':' then
                        used_tables(j).text1:=path||substr(s2,l+1);
                      end if;
                    end if;
                    j := used_tables.next(j);
                  end loop;
                end if;
                j := t(-i);
                if j>0 then
                  t(-i) := add_text(or_expr(j),qual);
                  or_expr(j) := t(-i);
                else
                  t(-i) := add_text(and_expr(-j),qual);
                  and_expr(-j) := t(-i);
                end if;
              end loop;
              for i in 1..or_cnt loop
                t2:= t(i);
                if t2<>t1 then
                  replace_text(t(-i),p_alias||t2||'.',p_alias||t1||'.');
                  used_tables.delete(t2);
                end if;
              end loop;
              --stdio.put_line_buf('******> '||or_idx);
              --plib.dump_strings(joins,'joins',0);
              --plib.dump_strings(used_tables,'tables',0);
            end if;
          end if;
        end if;
      end loop;
      --stdio.put_line_buf('******');
      --plib.dump_strings(joins,'joins',0);
      --plib.dump_strings(used_tables,'tables',0);
    end;
--
  begin
    if p_idx is NULL then
        return FALSE;
    end if;
    ok := false;
    idx := plib.ir(p_idx).down;
    typ := plib.ir(p_idx).type;
    v_class := b_class;
    v_outer := 0;
    v_out := 0;
    v_ovl := false;
    v_typ := plib.g_typed_joins;
    scan  := false;
    v_cast:= not p_cast is null;
    if v_crit then
      if v_joins is null then
        v_qual := v_class||':@';
      else
        v_qual := v_class||':';
      end if;
    end if;
    if typ in (plp$parser.ATTR_,plp$parser.ID_,plp$parser.RTL_,plp$parser.VARMETH_,
        plp$parser.METHOD_) and plib.ir(p_idx).text is NULL or typ=plp$parser.DBCLASS_
    then    -- var head
      if not idx is null then
        u_idx := plib.ir(idx).type;
        if u_idx = plp$parser.ID_ then
          -- Если при разборе текущего выражения встретилось обращение к реквизиту с алиасом, равным p_x
          -- и в процессе разбора дерева не встретилось источника данных с таким же алиасом, то обрабатываем этот узел
          -- Если же p_alias_override = true. То на этом шаге ничего не делаем. Этот узел обработает один из запусков construct_cursor_text,
          -- внутри которого запустится find_used. Так как construct_cursor_text запускается каждый раз над select, то он уже
          -- не будет включать часть дерева разбора, поэтому рано или поздно p_alias_override = false.
          if plib.ir(idx).text=p_x and not p_alias_override then
            idx1 := plib.ir(idx).right;
            if v_joins then
              if idx1 is NULL or plib.ir(idx1).type in ( plp$parser.OBJECT_REF_, plp$parser.MODIFIER_ ) then
                b:=true;
                if idx1 is null then
                    if plib.ir(p_idx).node>-1 then
                        v_out := plib.add2ir(plp$parser.MODIFIER_,plp$parser.OBJ_ID_,null,null);
                        plib.add_sibling(idx,v_out);
                        plib.ir(v_out).node:=0;
                        v_out := 0;
                    end if;
                elsif plib.ir(idx1).text1 is null then
                    idx := idx1;
                    v_outer := nvl(plib.ir(idx).type1,0);
                    if (v_outer mod 1000)=plp$parser.LOCK_REF_ then
                        used_tables(1).text3 := '100';
                    end if;
                    v_outer := trunc(v_outer/1000);
                    v_typ := v_outer>3;
                    if v_typ then
                      v_outer := v_outer mod 4;
                    end if;
                    v_typ := v_typ or plib.g_typed_joins;
                    v_class := plib.ir(idx).text;
                    if v_class like '$$$%' then
                      v_ovl := true;
                      v_class := substr(v_class,5);
                    end if;
                    get_index(true);
                    if b is null then
                        null;
                    elsif b_part is null then
                        typ := plib.ir(idx).node;
                        if typ<=0 then v_part:=typ; end if;
                    else
                        v_part := b_part;
                    end if;
                    idx := plib.ir(idx).right;
                    b:=false;
                end if;
                if b then
                    b := lib.class_exist(plib.ir(plib.ir(idx).type1).text, class_info);
                    plib.ir(idx).type := plp$parser.ATTR_;
                    plib.ir(idx).type1:= plib.convert_base(class_info.base_id);    -- attr base class
                    plib.ir(idx).text := null;                 -- attr empty qualifier
                    plib.ir(idx).text1:= class_info.class_id;  -- attr class
                    idx1 := plib.ir(idx).right;
                    if not idx1 is null and plib.ir(idx1).text is null then
                      plib.ir(idx1).text := class_info.class_id;
                      plib.ir(idx1).text1:= constant.REFSTRING;
                    end if;
                end if;
              else
                idx := idx1;
              end if;
              scan := TRUE;
            elsif not idx1 is NULL then
              if plib.ir(idx1).type=plp$parser.ID_ then
                plib.expr_class(idx1,plpclass);
                if plpclass.is_reference or plpclass.base_type<>plp$parser.RECORD_ then
                  scan:= TRUE;
                  idx := idx1;
                  plib.ir(idx).type := plp$parser.ATTR_;
                  if plpclass.is_reference then
                    plib.ir(idx).type1:= plp$parser.REF_;
                  else
                    plib.ir(idx).type1:= plpclass.base_type;
                  end if;
                  plib.ir(idx).text1:= plpclass.class_id;
                elsif plpclass.is_udt and plpclass.base_type=plp$parser.RECORD_ and plib.ir(plpclass.class_id).type1=plp$parser.CURSOR_ then
                  scan:= TRUE;
                  idx := idx1;
                end if;
              elsif plib.ir(idx1).type=plp$parser.ATTR_ and plib.ir(idx1).text like '$$$%' then
                scan:= TRUE;
                idx := idx1;
              end if;
            end if;
          end if;
        elsif u_idx = plp$parser.ATTR_ then
            scan := not_x;
        elsif u_idx = plp$parser.DBCLASS_ then
            idx:=plib.ir(idx).right;
        elsif u_idx = plp$parser.OBJECT_REF_ then
            scan := not_x ;
            if scan then
                b := lib.class_exist(plib.ir(idx).text, class_info);
                plib.add_neighbour(idx,plib.add2ir(plp$parser.ATTR_,plib.convert_base(class_info.base_id),null,class_info.class_id),false);
            end if;
        end if;
      end if;
--
        edecl := null;
        if scan then
            v_table := b_table;
            obj_lock:= FALSE;
            obj_coll:= FALSE;
            obj_tbl := FALSE;
            b   := FALSE;
            idx1:= idx;
            while not idx is null loop
                b := TRUE;
                typ := plib.ir(idx).type;
                if typ in (plp$parser.ATTR_,plp$parser.ID_) then
                    qual := qual||case when qual is NULL then '' else '.' end||replace(plib.ir(idx).text,'$$$');
                    v_out:= plib.ir(idx).node;
                elsif typ in (plp$parser.OBJECT_REF_,plp$parser.LOCK_REF_) then
                    add_joins(false,p_mapped);
                    v_class := nvl(plib.ir(idx).text1,plib.ir(idx).text);
                    if v_class like '$$$%' then
                      v_ovl := true;
                      v_class := substr(v_class,5);
                    end if;
                    v_outer := nvl(plib.ir(idx).type1,0);
                    obj_coll:= typ=plp$parser.LOCK_REF_;
                    typ := v_outer mod 1000;
                    v_outer := trunc(v_outer/1000);
                    obj_lock:= typ=plp$parser.LOCK_REF_;
                    obj_tbl := typ=plp$parser.TABLE_;
                    v_typ := v_outer>3;
                    if v_typ then
                      v_outer := v_outer mod 4;
                    end if;
                    v_typ := v_typ or plib.g_typed_joins;
                    get_index(true);
                    if not b is null then
                        typ := plib.ir(idx).node;
                        if typ<=0 then v_part:=typ; end if;
                    end if;
                elsif typ = plp$parser.MODIFIER_ then
                    o_class := v_class;
                    if not qual is null then
                        add_joins(false,p_mapped);
                        obj_coll:= false;
                        obj_tbl := false;
                    end if;
                    v_outer := plib.ir(idx).node;
                    if v_outer<0 then
                        v_outer:= -v_outer;
                        v_part := 1-trunc(v_outer/1000);
                        v_outer:= v_outer mod 1000;
                    end if;
                    b := bitand(v_outer,8)>0;
                    v_typ := bitand(v_outer,4)>0;
                    v_outer := v_outer mod 4;
                    v_ovl := false;
                    v_typ := v_typ or plib.g_typed_joins;
                    if not obj_coll then
                        v_class := plib.ir(idx).text;
                        if v_class like '$$$%' then
                          v_ovl := true;
                          v_class := substr(v_class,5);
                        end if;
                    end if;
                    v_out := v_outer;
                    add_mods;
                elsif typ in (plp$parser.METHOD_,plp$parser.RTL_) then
                    plib.plp_error(idx,'CHANGE_DATABASE');
                    b := null;
                end if;
                if not (b is null or plib.ir(idx).down is null) then
                    plib.plp_error(idx,'CHANGE_DATABASE');
                end if;
                idx1:= idx;
                idx := plib.ir(idx).right;
                if v_cast and idx is null then
                   v_cast := false;
                   idx := p_cast;
                end if;
            end loop;
            if not b is null then
                ok := b;
                if ok then
                  if v_out=1 then
                    ok := null;
                  else
                    ok := v_out=2;
                  end if;
                  add_joins(false,p_mapped);
                end if;
                if instr(v_column,'''')>0 then
                    eprog:= v_column;
                    scan := null;
                else
                    eprog:= get_col_text(v_column,p_alias||u_idx,v_expr,v_outcol);
                    if p_outer = -10 then  --insert/update
                      if use_java then
                        if plib.ir(p_idx).type=plp$parser.ATTR_ and plib.ir(p_idx).type1=plp$parser.REF_ then
                          plp2java.add_sync(lib.class_target(plib.ir(p_idx).text1),false);
                        end if;
                      end if;
                    elsif v_crit then
                      -- если в used_tables(u_idx).text2 встретился символ $, значит, жто курсор и нас интересуеи только часть текста до символа $
                      if crit_extension and used_tables.exists(u_idx) then
                        eprog := regexp_substr(used_tables(u_idx).text2,'[^$"]+') || '.' || v_column;
                      end if;
                      idx := plib.find_left(p_idx,plp$parser.ASSIGN_,p_crit);
                      if not idx is null and (ok or plib.ir(idx).text1 is null) then
                        if not obj_tbl and instr(path,':')>0 then
                          u_idx:= plib.find_record(joins,null,null,path);
                          if not u_idx is null then
                            typ := instr(joins(u_idx).text2,'.');
                            if typ>1 then
                              v_column := substr(joins(u_idx).text2,1,typ-1);
                              v_expr := substr(joins(u_idx).text2,typ+1);
                            else
                              v_column := joins(u_idx).text2;
                              v_expr := null;
                            end if;
                            u_idx:= plib.find_record(used_tables,joins(u_idx).text1);
                          end if;
                        elsif nvl(v_joins,true) then
                          u_idx:= plib.find_record(used_tables,path);
                          v_column := 'ID';
                          v_expr := null;
                          if ok then
                            v_qual:= v_qual||'$$$.';
                          end if;
                        else
                          u_idx := null;
                        end if;
                        if not u_idx is null then
                          if ok is null then
                            plib.ir(idx).text1 := v_qual||'['||pqual||']';
                          else
                            plib.ir(idx).text1 := v_qual||'['||pqual||']'||rtl.bool_char(obj_tbl,'2',rtl.bool_char(obj_coll))||
                              get_col_text(v_column,p_alias||u_idx,v_expr,false)||'*'||v_class;
                          end if;
                        end if;
                      end if;
                    end if;
                end if;
            end if;
            typ:=plib.ir(p_idx).type1;
            ok:=true;
            if typ is not null and plib.ir(p_idx).type = plp$parser.ID_ then
              edecl := '<ID>';
            end if;
        elsif v_cast then
            return false;
        else
            scan:=TRUE; b:=NULL; v_part := 0;
            ok := not skip_attrs; v_repl := false;
            if plib.ir(p_idx).node>-1 then
              if typ=plp$parser.ID_ then
                scan := plib.ir(idx).node=4 and not plib.ir(idx).text1 is null;
                if scan then
                  idx1 := plib.ir(idx).text1;
                  v_part := plib.ir(idx1).type1;
                  scan := bitand(v_part,1) = 0; -- check restrict_references
                  if scan then
                    b := bitand(v_part,2) <> 0; -- db_update
                  elsif plib.g_parse_java then
                    v_repl := null;
                  else
                    v_repl := true;
                  end if;
                end if;
              elsif typ=plp$parser.ATTR_ then
                idx1:=idx;
                if not idx1 is null then
                  if skip_attrs and not use_context is null and u_idx=plp$parser.DBCLASS_ and plib.ir(idx).type=plp$parser.ATTR_ then
                    b := false;
                    v_out := plib.ir(idx).left;
                  end if;
                  loop
                    typ:=plib.ir(idx1).type;
                    if typ in (plp$parser.ID_,plp$parser.VARMETH_) then
                        if not plib.ir(idx1).right is null and typ=plp$parser.VARMETH_ and plib.ir(idx1).einfo=165 then -- cast_to
                          u_idx := plib.ir(plib.ir(plib.ir(idx1).down).down).right;
                          if findused(u_idx,false,false,plib.ir(idx1).right,p_alias_override) then
                            scan := null; exit;
                          end if;
                        end if;
                        if typ=plp$parser.VARMETH_ then
                          v_repl := false;
                          if plib.ir(idx1).einfo > 0 then -- function/constant
                            v_repl := plib.ir(idx1).type1 > 0; -- function
                            if v_repl then
                              v_part := plib.ir(idx1).node;
                            end if;
                          end if;
                          scan := FALSE;
                          if ok is null then
                            if v_repl then
                              ok := true;
                            else
                              ok := plib.ir(idx1).down is null; -- skip id with index (forall clause)
                            end if;
                          end if;
                        else
                          scan := plib.ir(idx1).node=4 and not plib.ir(idx1).text1 is null;
                          if scan then -- function
                            typ := plib.ir(idx1).text1;
                            v_part := plib.ir(typ).type1;
                            scan := bitand(v_part,1) = 0; -- check restrict_references
                            if scan then
                              b := bitand(v_part,2) <> 0; -- db_update
                            end if;
                            v_repl := not scan;
                            ok := nvl(ok,true);
                          else  -- variable/constant
                            v_repl := false;
                            if ok is null then
                              ok := plib.ir(idx1).down is null; -- skip id with index (forall clause)
                            end if;
                          end if;
                        end if;
                    elsif typ=plp$parser.MODIFIER_ then
                        scan:=plib.ir(idx1).type1 not in (plp$parser.OBJ_ID_,plp$parser.CLASS_REF_,plp$parser.OBJECT_REF_);
                        v_repl := false; --not scan;
                    elsif typ in (plp$parser.OBJECT_REF_,plp$parser.LOCK_REF_) then
                        if ok then scan:=TRUE; end if;
                        b := false;
                        v_repl := false; --not scan;
                    elsif typ=plp$parser.RTL_ then
                        v_part := plib.ir(idx1).node;
                        b := bitand(v_part,2) > 0; -- db_update
                        scan:=TRUE;
                        v_repl := false;
                    elsif typ<>plp$parser.ATTR_ then
                        scan:=TRUE;
                        v_repl := false;
                    end if;
                    idx1:=plib.ir(idx1).right;
                    exit when scan or idx1 is null;
                  end loop;
                end if;
              elsif typ=plp$parser.VARMETH_ then
                scan := FALSE;
                idx1 := plib.ir(idx).einfo;
                if idx1 > 0 then -- function/constant
                  if idx1 in ( 168, 216 ) then  -- rownum/sequence
                    u_idx := idx;
                    scan := null;
                  end if;
                  v_repl := plib.ir(idx).type1 > 0; -- function
                  if v_repl then
                    v_part := plib.ir(idx).node;
                    if plib.g_parse_java then
                      if idx1 = 160 then -- sys_context
                        idx1 := plib.ir(idx).down;
                        if plib.ir(idx1).type = plp$parser.STRING_
                          and plib.ir(idx1).type1 = plp$parser.CONSTANT_
                          and upper(plib.ir(idx1).text) = 'USERENV'
                        then
                          v_part := 1; -- no sync context
                        else
                          v_repl := null;
                        end if;
                      elsif idx1 = 205 then -- rtl.user
                        v_repl := null;
                      elsif plib.get_new_name(idx) like 'Z_%.%' then -- methods functions
                        v_repl := null;
                      end if;
                    end if;
                  elsif skip_attrs and plib.ir(idx).right is null then -- constant can't be used in sql
                    plib.expr_class(p_idx,plpclass);
                    if not plpclass.is_reference then
                      if plpclass.base_type in (plp$parser.STRING_, plp$parser.NUMBER_) then
                        typ := -plpclass.base_type; b := true;
                      elsif plpclass.base_type = plp$parser.INTEGER_ then
                        typ := -plp$parser.NUMBER_; b := true;
                      end if;
                    end if;
                  end if;
                end if;
              elsif typ=plp$parser.RTL_ then
                v_part := plib.ir(idx).node;
                b := bitand(v_part,2) > 0; -- db_update
              end if;
            end if;
            if scan is null then
              eprog := null;
              if idx = u_idx then
                idx := plib.ir(u_idx).down; -- next_value parameter
                if idx is not null then
                  ok := findused( idx, p_replace, true, null, p_alias_override );
                  etext := null;
                  ok := expr2plsql(idx,p_decl,eprog,etext,mgn,false,true,null);
                  --ok := var2plsql(idx,p_decl,eprog,etext,null,mgn,true,null);
                  p_text := p_text||eprog;
                  eprog := '('||etext||')';
                  plib.delete_children(u_idx);
                end if;
                idx := u_idx;
              end if;
              eprog:= plib.ir(u_idx).text||eprog;
              scan := true;
              typ:= plib.ir(p_idx).type1;
              ok := true;
            else
              if not plib.g_parse_java then
                v_repl := not scan;
              end if;
              ok := findused( idx, p_replace and nvl(v_repl,false), true, null, p_alias_override );
              --ok := findused( idx, not scan and p_replace, true, null );
              if ok then
                if scan then
                  if plib.ir(p_idx).node=-10 and not idx is null then
                    if typ=plp$parser.VARMETH_ and instr(plib.ir(idx).text,'.')=0 then
                      scan := false;
                      v_repl := false;
                    elsif typ=plp$parser.ATTR_ and plib.ir(idx).type=plp$parser.VARMETH_ then
                      idx1 := plib.last_child(p_idx);
                      if plib.ir(idx1).type=plp$parser.MODIFIER_ then
                        scan:= findused( idx, p_replace, true, null, p_alias_override );
                        idx := plib.ir(idx1).left;
                        plib.ir(idx1).left := null;
                        plib.ir(idx).right := null;
                        eprog:=NULL;
                        etext:=NULL;
                        tmp_expr_idx := null;
                        b := var2plsql(p_idx,p_decl,eprog,etext,null,mgn,true,null);
                        p_text := p_text||eprog;
                        o_class:= b_class;
                        typ := plib.ir(idx1).type1;
                        idx := idx1;
                        v_outer := plib.ir(idx).node;
                        if v_outer<0 then
                          v_outer:= (-v_outer) mod 1000;
                        end if;
                        v_outer := v_outer mod 4;
                        get_index(false);
                        get_ref_access('('||etext||')',plib.ir(idx1).text);
                        scan := null;
                        v_repl := true;
                      end if;
                    end if;
                    if scan then
                      plib.plp_error(p_idx,'BAD_BOOLEAN_CONVERSION');
                    end if;
                  else
                    plib.plp_error(p_idx,'CHANGE_DATABASE',is_error=>nvl(b,true));
                    scan := false;
                  end if;
                end if;
                if p_replace and not nvl(v_repl,false) then
                  b := findused( idx, true, true, null, p_alias_override );
                end if;
              elsif scan then
                if skip_attrs and not b is null then
                  plib.plp_error(p_idx,'CHANGE_DATABASE',is_error=>b);
                  scan:=false;
                  if not b and v_out>0 and plib.ir(v_out).down is null then
                    etext := rtl.calculate('valmgr.static('''||plib.ir(v_out).text||''')',rtl.STRING_EXPR,true);
                    if etext='''0''' then
                      plib.plp_warning(v_out,'OBJECT_NOT_FOUND',plib.ir(v_out).text);
                    end if;
                    plib.ir(v_out).text := etext;
                    plib.ir(v_out).type := plp$parser.TEXT_;
                  end if;
                elsif p_replace then
                  if plib.ir(p_idx).node=-10 and not idx is null then
                    if typ = plp$parser.VARMETH_ and plib.ir(idx).einfo = 70 then -- decode
                      scan := findused( idx, true, true, null, p_alias_override );
                      scan := false;
                    end if;
                  end if;
                else
                  scan := false;
                end if;
              elsif plib.g_parse_java and p_replace then
                if v_repl is null or use_java and not v_repl then
                  scan := true;
                end if;
              --elsif use_java and not v_repl then
              --  scan := p_replace;
              end if;
              if scan then
                typ:=plib.ir(p_idx).type1;
                eprog:=NULL;
                etext:=NULL;
                tmp_expr_idx := null;
                if use_java then
                  scan := plp2java.var4sql(p_idx,p_decl,eprog,etext,mgn,true,true);
                else
                  scan := var2plsql(p_idx,p_decl,eprog,etext,null,mgn);
                end if;
                p_text:=p_text||eprog;
                if scan then
                    if etext='true' then
                        etext:= constant.YES;
                        typ  := -plp$parser.BOOLEAN_;
                    elsif etext='false' then
                        etext:= constant.NO;
                        typ  := -plp$parser.BOOLEAN_;
                    end if;
                    eprog:=etext;
                elsif use_java then
                    plib.expr_class(p_idx,plpclass);
                    if plpclass.base_type = plp$parser.BOOLEAN_ then
                        typ  := -plp$parser.BOOLEAN_;
                        scan := true;
                    end if;
                    eprog := plp2java.add$bind(tmp_idx,p_text,tmp_pref,plpclass,etext,true,mgn);
                else
                    tmp_idx:= tmp_idx+1;
                    eprog  := tmp_pref||tmp_idx;
                    edecl  := plsql_type(p_idx,true,false);
                    if upper(edecl)=constant.GENERIC_BOOLEAN then
                        edecl:= 'varchar2'||BOOL_PREC;
                        etext:= 'rtl.bool_char('||etext||')';
                        typ  := -plp$parser.BOOLEAN_;
                        scan := true;
                    end if;
                    if not use_context is null and etext like 'valmgr.static(''%'')' then
                        eprog := rtl.calculate(etext,rtl.STRING_EXPR,true);
                        if eprog='''0''' then
                          plib.plp_warning(p_idx,'OBJECT_NOT_FOUND',substr(etext,16,length(etext)-17));
                        end if;
                        scan := true;
                    else
                        p_decl:= mgn ||eprog||TAB||edecl||';'||NL||p_decl;
                        p_text:= p_text||mgn||eprog||' := '||etext||';'||NL;
                    end if;
                end if;
                if scan or typ is null or plib.ir(p_idx).type <> plp$parser.ID_ then
                  edecl := null;
                else
                  edecl := '<ID>';
                end if;
                scan := null;
                if use_java then
                  idx1 := null;
                else
                  idx1 := p_repls.first;
                  while not idx1 is null loop
                    plib.replace_nodes(p_repls(idx1),p_idx,plp$parser.TEXT_,eprog,typ,edecl,idx1<0);--,plib.ir(p_idx).text1);
                    idx1 := p_repls.next(idx1);
                  end loop;
                end if;
              elsif scan is null then
                scan:= true;
                typ := plp$parser.NULL_;
              elsif b and typ < 0 then  --constants calculation
                typ := -typ;
                if typ = plp$parser.NUMBER_ then
                  etext := calculate_twice(p_idx, plib.ir(idx).text,rtl.NUMBER_EXPR,true);
                else
                  etext := calculate_twice(p_idx, plib.ir(idx).text);
                end if;
                if etext <> plib.ir(idx).text then
                  plib.ir(p_idx).type := typ;
                  plib.ir(p_idx).text := etext;
                  plib.ir(p_idx).text1:= NULL;
                  plib.ir(p_idx).type1:= plp$parser.CONSTANT_;
                  plib.ir(p_idx).node := 0;
                  plib.delete_children(p_idx);
                end if;
              elsif p_replace and plib.g_parse_java and v_part > 0 then
                if bitand(v_part,8) > 0 then  -- sync contexts
                  if use_java then
                    plp2java.add_sync('<CONTEXT>',null);
                  else
                    etext := '/* synchronizeUserContext(); */';
                    if p_text is null or instr(p_text,etext) = 0 then
                      p_text:= p_text||mgn||etext||NL;
                    end if;
                  end if;
                end if;
              end if;
              idx1 := plib.last_child(p_idx);
            end if;
        end if; -- iterator var prefix
        if nvl(scan,true) then
            if idx1 is null then
              plib.ir(p_idx).text1:= NULL;
            elsif plib.ir(p_idx).type=plp$parser.ID_ and not typ is null then
              plib.ir(p_idx).text1:= edecl;
              plib.ir(p_idx).node := plib.ir(idx1).node;
            elsif typ in (plp$parser.COLLECTION_,plp$parser.OBJ_COLLECTION_,plp$parser.TABLE_) then
              plib.ir(p_idx).node := plib.ir(idx1).node;
            else
              plib.ir(p_idx).text1:= NULL;
            end if;
            plib.ir(p_idx).type := plp$parser.TEXT_;
            plib.ir(p_idx).text := eprog;
            plib.ir(p_idx).type1:= typ;
            if scan then
              plib.ir(p_idx).node := plib.ir(p_idx).node+COL_FADD;
            end if;
            plib.delete_children(p_idx);
        end if; -- iterator var prefix
    elsif v_cast then
        return false;
    else    -- not var head
      scan := true;
      if typ=plp$parser.BOOLEAN_ then
        typ := plib.ir(p_idx).type1;
        if typ = plp$parser.OR_ and p_outer <= 0 then
          if v_or then
            scan := false;
            path := or_list;
          else
            scan := true;
            v_or := true;
            v_j1 := nvl(joins.last,0);
            v_t1 := used_tables.last;
            or_expr.delete;
            or_tabs.delete;
            and_expr.delete;
            and_tabs.delete;
            or_cnt := 0;
            and_cnt:= 0;
          end if;
          for i in 1..2 loop
            b := true;
            if plib.ir(idx).type=plp$parser.BOOLEAN_ then
              if plib.ir(idx).type1=plp$parser.OR_ then
                b := false;
              elsif plib.ir(idx).type1=plp$parser.AND_ then
                b := null;
                typ := or_cnt;
              end if;
            end if;
            or_list:= ',';
            ok := findused(idx,p_replace,false,null,p_alias_override) or ok;
            if b or b is null and typ=or_cnt then
              or_cnt := or_cnt+1;
              or_expr(or_cnt) := idx;
              or_tabs(or_cnt) := or_list;
              --stdio.put_line_buf('>>>'||or_cnt||' - '||idx||' '||or_list);
              --plib.dump_strings(joins,'joins',0);
              --plib.dump_strings(used_tables,'tables',0);
            end if;
            idx:= plib.ir(idx).right;
          end loop;
          if scan then
            if or_cnt>0 then process_or_expr; end if;
            v_or := false;
            or_expr.delete;
            or_tabs.delete;
            and_expr.delete;
            and_tabs.delete;
            or_cnt := 0;
            and_cnt:= 0;
            or_list:= null;
            --stdio.put_line_buf('******'||v_j1||'.'||v_t1);
            --plib.dump_strings(joins,'joins',0);
            --plib.dump_strings(used_tables,'tables',0);
          else
            or_list:= path;
          end if;
          scan := false;
        elsif v_or and typ = plp$parser.AND_ then
          b := false;
          typ := or_cnt;
          for i in 1..2 loop
            if plib.ir(idx).type=plp$parser.BOOLEAN_ and plib.ir(idx).type1=plp$parser.OR_ then
              b := true;
            end if;
            ok := findused(idx,p_replace,false,null,p_alias_override) or ok;
            idx:= plib.ir(idx).right;
          end loop;
          if b and length(or_list)>1 then
            and_cnt := and_cnt+1;
            and_tabs(and_cnt) := or_list;
            idx := p_idx;
            loop
              idx1 := plib.parent(idx);
              if not idx1 is null and plib.ir(idx1).type=plp$parser.BOOLEAN_ and plib.ir(idx1).type1=plp$parser.AND_ then
                idx := idx1;
              else exit; end if;
            end loop;
            and_expr(and_cnt) := idx;
            for i in typ+1..or_cnt loop
              if or_tabs.exists(-i) then
                or_tabs(-i) := ','||and_cnt||or_tabs(-i);
              else
                or_tabs(-i) := ','||and_cnt||',';
              end if;
            end loop;
            --stdio.put_line_buf('-->'||and_cnt||' - '||idx||' '||or_list);
            --plib.dump_strings(joins,'joins',0);
            --plib.dump_strings(used_tables,'tables',0);
          end if;
          scan := false;
        elsif typ in (plp$parser.SELECT_,plp$parser.EXISTS_) then
          b := v_optim;
          v_optim := false;
          -- Сюда мы попадаем из where в запросе
          -- если текущий узел = plp$parser.SELECT_ и его алиас совпадает с p_x, то у всех потомков текущего узла
          -- p_alias_override должен быть равен true
          ok := findused(idx,false,false,null,p_alias_override or typ = plp$parser.SELECT_ and plib.ir(p_idx).text = p_x);
          v_optim := b;
          idx:= plib.ir(idx).right;
        end if;
      elsif typ in (plp$parser.CURSOR_,plp$parser.SELECT_) and not plib.ir(p_idx).type1 is null then
        b := v_optim;
        v_optim := false;
        -- Сюда мы попадем из select list(подзапрос в select)
        -- если текущий узел = plp$parser.SELECT_ и его алиас совпадает с p_x, то у всех потомков текущего узла
        -- p_alias_override должен быть равен true
        ok := findused(idx,false,typ = plp$parser.SELECT_,null,p_alias_override or typ = plp$parser.SELECT_ and plib.ir(p_idx).text = p_x);
        v_optim := b;
        scan := false;
      elsif typ=plp$parser.PRIOR_ and plib.ir(p_idx).type1<>plp$parser.VARMETH_
        and (plib.ir(p_idx).text is null or plib.ir(p_idx).text='as')
      then
        ok := findused(plib.ir(idx).right,p_replace,true,null,p_alias_override);
        scan := false;
      end if;
      if scan then
      -- children
        if not idx is NULL then
          ok:=findused(idx,p_replace,true,null,p_alias_override);
        elsif typ=plp$parser.TEXT_ and plib.ir(p_idx).type1>0 then
          ok:=plib.ir(p_idx).node>COL_FLAG;
        end if;
      end if;
    end if;
    -- sibling
    idx := plib.ir(p_idx).right;
    if p_sibling and not idx is NULL then
        ok:=findused( idx, p_replace, true, null, p_alias_override ) or ok;
    end if;
    return ok;
  end findused;
begin
    b_part  := instr(used_tables(1).text4,'|');
    if b_part>0 then
        b_table := substr(used_tables(1).text4,b_part+1);
        b_part  := instr(b_table,'|');
        if b_part>0 then
            b_part := substr(b_table,1,b_part-1);
        else
            b_part := b_table;
        end if;
    else
        b_part := null;
    end if;
    b_table := used_tables(1).text2;
    b_class := p_class;
    not_obj := b_table<>'OBJECTS';
    v_joins := true;
    if b_class like '<%>' then
      v_joins := b_class<>'<SUBQUERY>';
      if v_joins then
        v_joins := null;
        b_class := substr(b_class,2,length(b_class)-2);
      end if;
    end if;
    v_crit  := not p_crit is null;
    not_x := p_x is null;
    v_or  := false;
    if plib.g_optim_code and p_outer = -1 then
      v_optim := true;
    else
      v_optim := false;
    end if;
    return findused(p_idx,p_last,false,null,false);
end find_used;
--
function order_dir(p_typ varchar2) return varchar2 is
begin
  if p_typ='D' then
    return ' desc';
  elsif p_typ='F' then
    return ' asc nulls first';
  elsif p_typ='L' then
    return ' asc nulls last';
  elsif p_typ='f' then
    return ' desc nulls first';
  elsif p_typ='l' then
    return ' desc nulls last';
  end if;
  return null;
end;
--
procedure get_next_alias is
    c pls_integer;
begin
    for i in reverse 1..length(cur_alias) loop
        c := ascii(substr(cur_alias,i,1))+1;
        if c>ascii('z') then
            if i>1 then
                cur_alias := rpad(substr(cur_alias,1,i-1),length(cur_alias),'a');
            else
                cur_alias := rpad('a',length(cur_alias)+1,'a'); exit;
            end if;
        else
            cur_alias := substr(cur_alias,1,i-1)||chr(c)||substr(cur_alias,i+1); exit;
        end if;
    end loop;
end;
--
function get_alias_idx(p_alias varchar2) return pls_integer is
    idx pls_integer := 0;
begin
    for i in 1..length(p_alias) loop
        idx := idx*128 + ascii(substr(p_alias,i,1));
    end loop;
    return idx;
end;
--
function compare_quals(p_path varchar2,p_qual varchar2) return boolean is
  v_qual  varchar2(1000);
  i pls_integer;
  j pls_integer;
  p pls_integer;
begin
  v_qual := upper(replace(replace(replace(p_path,':','.'),'< >'),'<NULL>'));
  p := 1;
  loop
    i := instr(v_qual,'|',p);
    if i>0 then
      j := instr(v_qual,'.',i);
      if j>0 then
        v_qual := substr(v_qual,1,i-1)||substr(v_qual,j);
        p := i;
      else
        v_qual := substr(v_qual,1,i-1);
        exit;
      end if;
    else
      exit;
    end if;
  end loop;
  return v_qual=p_qual;
end;
--
function get_table_alias(p_path  varchar2,
                         all_used plib.string_rec_tbl_t,
                         prefixes plib.string_tbl_t,
                         aliases  plib.idx_tbl_t
                        ) return varchar2 is
  v_str varchar2(1000);
  v_pfx varchar2(100);
  v_tbl varchar2(100);
  v_qual  varchar2(1000);
  i pls_integer;
  j pls_integer;
  p pls_integer;
  n pls_integer;
  b boolean;
begin
  v_str := upper(replace(replace(replace(p_path,SP),'['),']'));
  i := instr(v_str,'.');
  if i>0 then
    v_qual:= substr(v_str,i+1);
    v_pfx := substr(v_str,1,i-1);
    i := instr(v_qual,'|');
    if i>0 then
      v_tbl := substr(v_qual,i+1);
      v_qual:= substr(v_qual,1,i-1);
    end if;
  else
    v_pfx := v_str;
    i := instr(v_pfx,'|');
    if i>0 then
      v_tbl := substr(v_pfx,i+1);
      v_pfx := substr(v_pfx,1,i-1);
    end if;
  end if;
  i := plib.find_string(prefixes,v_pfx);
  if i is null then
    return v_str;
  end if;
  v_pfx := null;
  i := aliases(i);
  n := 0;
  j := all_used.next(i);
  while not j is null loop
    if v_pfx is null then
      p := instr(all_used(j).text1,'$');
      v_pfx := substr(all_used(j).text1,1,p-1);
    elsif not all_used(j).text1 like v_pfx||'$%' then
      exit;
    end if;
    b := false;
    p := instr(all_used(j).text1,':');
    if v_qual is null then
      b := p=0;
    elsif p>0 then
      b := compare_quals(substr(all_used(j).text1,p+1),v_qual);
    end if;
    if b then
      if v_tbl is null or all_used(j).text2=v_tbl then
        n := j;
        exit;
      end if;
    end if;
    j := all_used.next(j);
  end loop;
  if n>0 then
    v_str := v_pfx||(n-i);
  end if;
  return v_str;
end;
--
function parse_hints(p_hints  varchar2,
                     all_used plib.string_rec_tbl_t,
                     prefixes plib.string_tbl_t,
                     aliases  plib.idx_tbl_t
                     ) return varchar2 is
  v_hints varchar2(2000);
  i pls_integer;
  j pls_integer;
  p pls_integer;
begin
  if p_hints is null then return null; end if;
  p := 1;
  loop
    i := instr(p_hints,'plp$hint(',p);
    if i>0 then
      j := instr(p_hints,')',i);
      if j>0 then
        v_hints := v_hints||substr(p_hints,p,i-p)||get_table_alias(substr(p_hints,i+9,j-i-9),all_used,prefixes,aliases);
        p := j+1;
      else
        i := i+1;
        v_hints := v_hints||substr(p_hints,p,i-p);
        p := i;
      end if;
    else
      v_hints := v_hints||substr(p_hints,p);
      exit;
    end if;
  end loop;
  return v_hints;
end;
--
-- @METAGS construct_cursor_text
function construct_cursor_text ( p_x      IN     varchar2,         -- set object prefix
                                 p_name   IN     varchar2,         -- cursor name
                                 p_select IN     pls_integer,      -- select list index
                                 p_set    IN     pls_integer,   -- base class/collection
                                 p_into   IN     pls_integer,   -- into list index
                                 p_where  IN     pls_integer,   -- where condition
                                 p_having IN     pls_integer,   -- having condition
                                 p_group  IN     pls_integer,   -- group by list index
                                 p_order  IN     pls_integer,   -- order by list index
                                 p_l      IN     pls_integer,   -- text indent
                                 p_all    IN     pls_integer,   -- all condition (lock)
                                 p_locks  in out nocopy pls_integer,   -- lock list index
                                 p_cursor in out nocopy pls_integer,
                                 p_decl   in out nocopy varchar2,         -- declarations
                                 p_text   in out nocopy varchar2,         -- p_prog
                                 str      in out nocopy varchar2,         -- select body
                                 p_hints  IN     varchar2 default NULL,
                                 p_dist   IN     varchar2 default NULL,
                                 p_wipe   IN     boolean  default TRUE
                                ) return pls_integer is
--    str         varchar2(32767);
    eprog       varchar2(30000);
    etext       varchar2(30000);
    edecl       varchar2(30000);
    ord_text    varchar2(30000);
    lock_text   varchar2(30000);
    cols_list   varchar2(20000);
    coll_text   varchar2(100);
    key_text    varchar2(100);
    i           pls_integer;
    j           pls_integer;
    idx         pls_integer;
    cnt         pls_integer;
    idx1        pls_integer;
    by_row      pls_integer;
    v_lock      pls_integer;
    old_vars    pls_integer;
    old_query   pls_integer;
    or_idx      pls_integer;
    v_set       pls_integer;
    v_part      pls_integer;
    ret_idx     pls_integer;
    tmp_idx     pls_integer;
    into_idx    pls_integer := p_into;
    from_idx    pls_integer := p_set;
    v_mode      pls_integer := 0; -- 0 - select/cursor, 1 - insert, 2 - update, 3 - delete
    used_tables plib.string_rec_tbl_t;
    joins       plib.string_rec_tbl_t;
    all_used    plib.string_rec_tbl_t;
    all_joins   plib.string_rec_tbl_t;
    prefixes    plib.string_tbl_t;
    aliases     plib.idx_tbl_t;
    v_repls     plib.idx_tbl_t;
    v_expr      plib.expr_info_t;
    class       varchar2(30);
    v_coll_cls  varchar2(30);
    v_alias     varchar2(10);
    v_nt_alias  varchar2(10);
    old_alias   varchar2(10);
    old_pref    varchar2(30);
    parent      varchar2(16);
    base_table  varchar2(100);
    v_x         varchar2(1000);
    mgn         varchar2(100) := rpad(TAB,p_l+1,TAB);    -- left margin
    mgn1        varchar2(100) := rpad(TAB,p_l+2,TAB);   -- left margin
    pref        varchar2(30);
    ref_type    varchar2(16);
    b           boolean;
    bb          boolean;
    is_kernel   boolean;
    is_class    boolean;
    v_crit      boolean;
    v_static    boolean;
    v_others    boolean;
    v_chk       boolean;
    v_sel       boolean;
    --v_scn       boolean;
    v_selkey    boolean;
    v_nt_id     pls_integer;
    v_info      plib.plp_class_t;
    v_class     lib.class_info_t;
    v_order     boolean := plib.g_tbl_order;
    v_cursor    boolean := p_cursor>0;
--
    procedure add_prtprop(i pls_integer,p_prt varchar2,p_cls varchar2,p_tbl varchar2) is
      v_def boolean;
      v_str varchar2(10);
      v_prt pls_integer;
    begin
      -- для таблицы должна быть указана партиция:
      --  условие архивации "Только актуальные данные" или в запросе указан раздел
      --  и в запросе указан режим использования архивных разделов <> 'ALL'
      if v_part<=0 then
        if i = 1 then
          v_str := '|'||v_part;
          v_selkey := true;
        end if;
        used_tables(i).text4 := null;
        lib.get_partition(used_tables(i).text4,v_prt,p_cls,v_part);
        if used_tables(i).text4=p_tbl then
          used_tables(i).text4 := ' partition'||v_str;
          if i = 1 then
            v_selkey := null;
          end if;
        elsif ascii(used_tables(i).text4)=ASC_DIEZ then
          if p_prt='PARTITION' then
            used_tables(i).text4 := ' partition'||used_tables(i).text4||'|'||v_prt;
          else
            used_tables(i).text4 := ' partition'||used_tables(i).text4;
            if i = 1 then
              v_selkey := null;
            end if;
          end if;
        elsif p_prt='PARTITION' then
          used_tables(i).text4 := ' partition('||nvl(used_tables(i).text4,p_tbl||'#0')||')'||v_str||'|'||nvl(v_prt,1000);
        else
          used_tables(i).text4 := '# partition'||v_str||'|'||nvl(v_prt,1000);
        end if;
      -- Необходимо добаление условия на ключи архивации
      --  условие архивации в операции "Архивные данные" или задана PRAGMA ARCHIVE с соответсвующими параметрами
      --  и в запросе указан режим использования архивных разделов <> 'ALL'
      elsif plib.g_method_arch and v_part <> 3 then
        v_def := true;
        if i = 1 then
          v_selkey := true;
        elsif not plib.g_typed_joins and instr(used_tables(1).text4,' partition')=0 then
          if used_tables(1).text4 not like '%'||plib.var('%')||'$P%' then
            if ascii(used_tables(1).text4)=ASC_DIEZ then
              if p_prt='PARTITION' then
                used_tables(i).text4 := substr(used_tables(1).text4,2);
              else
                used_tables(i).text4 := used_tables(1).text4;
              end if;
            elsif p_prt='PARTITION' then
              used_tables(i).text4 := used_tables(1).text4;
            else
              used_tables(i).text4 := '#'||used_tables(1).text4;
            end if;
            v_def := false;
          end if;
        end if;
        if v_def then
          if p_prt='PARTITION' then
            used_tables(i).text4 := add_tmp_part(p_cls,pref||'P',mgn,tmp_vars,p_decl);
          else
            used_tables(i).text4 := '#'||add_tmp_part(p_cls,pref||'P',mgn,tmp_vars,p_decl);
          end if;
        end if;
      -- для таблицы не должна быть указана партиция и не нужно условие на ключ архивации:
      --  в запросе указан режим использования архивных разделов = 'ALL' или условие архивации "Все архивные данные" и в запросе явно не указан раздел
      else
        if i = 1 then
          v_selkey := false;
        end if;
        if p_prt='PARTITION' then
          used_tables(i).text4 := ' partition';
        else
          used_tables(i).text4 := '# partition';
        end if;
      end if;
    end;
--
    procedure add_system_table(p_qual varchar2, p_get boolean) is
      prt  varchar2(10);
    begin
      if p_get then
        lib.qual_column(class,p_qual,edecl,ord_text,eprog,'2');
        if class<>constant.OBJECT and edecl='OBJECTS' then
          edecl:=null; ord_text:=null;
        end if;
      end if;
      if edecl<>base_table then
        i := plib.find_record(used_tables,v_alias||'$'||edecl,edecl);
        b := p_qual='COLLECTION_ID';
        if b then
          v_coll_cls := substr(eprog,instr(eprog,'.',-1)+1);
        end if;
        if i is null then
          if not b then
            if not v_coll_cls is null then
              lib.qual_column(v_coll_cls,p_qual,edecl,ord_text,eprog,'2');
              i := plib.find_record(used_tables,v_alias||'$'||edecl,edecl);
            end if;
            if not i is null then
              ord_text := v_alias||i||'.'||ord_text;
            elsif p_qual='CLASS_ID' then
              ord_text := ''''||class||'''';
            else
              ord_text := null;
            end if;
            return;
          elsif p_get then
            if bAddSysCols and substr(v_class.flags,24,1)<>'0' --needs collection_id
            then null;
            else
              ord_text := null; return;
            end if;
          end if;
          i := used_tables.last+1;
          used_tables(i).text1 := v_alias||'$'||edecl;
          used_tables(i).text2 := edecl;
          used_tables(i).text3 := '000';
          plib.add_unique( joins, used_tables(1).text1, 'id', used_tables(i).text1, 'id' );
          prt := substr(eprog,instr(eprog,'.',1,2)+5,1);
          if prt!=constant.NO then
            if prt=constant.YES then prt:='PARTITION'; end if;
            add_prtprop(i,prt,v_coll_cls,edecl);
          end if;
        end if;
        ord_text := v_alias||i||'.'||ord_text;
      elsif p_get and instr(ord_text,'''')=0 then
        ord_text := v_alias||'1.'||ord_text;
      end if;
    end;
--
    procedure check_columns(p_column varchar2) is
      i pls_integer;
      j pls_integer;
    begin
      i := instr(cols_list,';'||p_column||'|');
      if i>0 then
        j := instr(cols_list,';',i+1);
        if j>0 then
          cols_list := substr(cols_list,1,i)||substr(cols_list,j+1);
        else
          cols_list := substr(cols_list,1,i-1);
        end if;
      end if;
    end;
--
    procedure check_seqs(p_expr varchar2) is
      i pls_integer;
      j pls_integer;
      p pls_integer;
      s varchar2(30);
    begin
      p := 1;
      loop
        i := instr(p_expr,'.nextval',p);
        if i > 0 then
          j := i-1;
          while j >=p and instr('0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_#$',substr(p_expr,j,1)) > 0 loop
            j := j-1;
          end loop;
          if (i-j) between 2 and 31 then
            s := substr(p_expr,j+1,i-j-1);
            cols_list := replace(cols_list,'|'||s||'.NEXTVAL','|rtl.next_value('''||s||''')');
          end if;
          p := i+8;
        else
          exit;
        end if;
      end loop;
    end;
--
   function replace_with_rowid (p_str in out varchar2, alias varchar2, c boolean) return boolean is
     for_id varchar2(37) := '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_';
     symbol varchar2(1);
     attr varchar2(2);
     for_row varchar2(3);
     str varchar2(13); -- 10/alias + .id
     str_len pls_integer;
     idx pls_integer;
     pos pls_integer := 1;
     to_check boolean;
     b boolean := false;

     function skip (k pls_integer) return pls_integer is
       m pls_integer := k;
     begin
       loop
         symbol := substr(p_str, m, 1);
         if (symbol is null) or (instr(for_id, symbol) = 0) then
           return m;
         else
           m := m + 1;
         end if;
       end loop;
     end;

   begin
     if c then
       attr := 'ID';
       for_row := 'ROW';
     else
       attr := 'id';
       for_row := 'row';
     end if;
     if alias is null then
       str := attr;
       str_len := 2;
       to_check := true;
     else
       str := alias || '.' || attr;
       str_len := length(alias) + 3;
       to_check := false;
     end if;
     loop
       if to_check then
         loop
           idx := instr(p_str, str, pos);
           if idx > 0 then
             if idx <> 1 then
               symbol := substr(p_str, idx - 1, 1);
               if instr(for_id, symbol) = 0 then
                 exit;
               else
                 pos := skip(idx + str_len) + 1;
               end if;
             end if;
           else
             return b;
           end if;
         end loop;
       else
         idx := instr(p_str, str, pos);
       end if;
       if idx > 0 then
         symbol := substr(p_str, idx + str_len, 1);
         if (symbol is null) or (instr(for_id, symbol) = 0) then
           p_str :=    substr(p_str, 1, idx + str_len - 3) || for_row
                    || substr(p_str, idx + str_len - 2);
           b := true;
           if symbol is null then
             return b;
           else
             pos := idx + str_len + 4;
           end if;
         else
           pos := skip(idx + str_len + 1) + 1;
         end if;
       else
         return b;
       end if;
     end loop;
   end;
--
   procedure request_process (p_str in out varchar2) is
     type alias_tbl_s is table of varchar2(10) index by binary_integer;
     alias_tbl alias_tbl_s;
     class_id varchar2(256);
     alias varchar2(10);
     i pls_integer;
     j pls_integer;
     k pls_integer := 1;
     m pls_integer;
     b1 boolean := false;
     b2 boolean := false;

     function for_update_of_with_rowid (p_str in out varchar2, alias varchar2, k pls_integer, c boolean) return boolean is
       rez boolean := false;
       what varchar2(16); -- 10/alias + .rowid
       x pls_integer;
   begin
       if c then
          what := ' ' || alias || '.ROWID';
       else
          what := ' ' || alias || '.rowid';
       end if;
       j := instr(p_str, what, k + 13); -- 'for update of'
       if j > 0 then
          x := j + length(what);
          if x - 1 != length(p_str) then
             if instr(p_str, ' ' || alias || '.', x) > 0 then
                -- удаляемый фрагмент не бывает последним
                p_str := substr(p_str, 1, j - 1) || substr(p_str, x + 1);
                rez := true;
             end if;
          end if;
       end if;
       return rez;
     end;

   begin
     i := all_used.first;
     j := 1;
     while not (i is null) loop
       if all_used(i).text2 like 'TABLE$%' then
         k := instr(p_str, 'table(cast(', k);
         if k > 0 then
           k := instr(p_str, 'Z#', k);
           if k > 0 then
             m := instr(p_str, '#TABLE', -1);
             if m > (k + 2) then
                class_id :=  substr(p_str, k + 2, m - k - 2);
             end if;
           end if;
         end if;
       else
         if 'Z#' = substr(all_used(i).text2, 1, 2) then
           class_id := substr(all_used(i).text2, 3); --Z#
         end if;
       end if;
       if not (class_id is null) then
         if lib.pk_is_rowid(class_id) then
           alias_tbl(j) := substr(all_used(i).text1, 1, instr(all_used(i).text1, '$') - 1) || '1';
           j := j + 1;
         end if;
       end if;
       i := all_used.next(i);
     end loop;

     i := alias_tbl.first;
     while not (i is null) loop
       alias := alias_tbl(i);
       b1 := replace_with_rowid(p_str, alias, true);
       b1 := b1 or replace_with_rowid(p_str, alias, false);
       if b1 then
          k := instr(p_str, 'for update of', -1);
          if k > 0 then
             b2 := for_update_of_with_rowid(p_str, alias, k, true);
             b2 := b2 or for_update_of_with_rowid(p_str, alias, k, false);
          end if;
       end if;
       i := alias_tbl.next(i);
     end loop;
   end;
--
    procedure split_columns is
      i pls_integer := 2;
      j pls_integer := 1;
      k pls_integer;
      l pls_integer := 0;
      x pls_integer := 2;
      val varchar2(2000);
      col varchar2(30);

      procedure for_insert is
        k pls_integer := instr(lock_text, 'Z#');
        m pls_integer := instr(lock_text, ' ', k);
        class_id varchar2(16) := substr(lock_text, k + 2, m - k - 2);
        i pls_integer;
        j pls_integer;
        b boolean;
      begin
        if lib.pk_is_rowid(class_id) then
          b := replace_with_rowid(edecl, '', true);
          if b then -- attempt to set id/rowid
            null; -- possible WARN\ERR
          end if;
          k := instr(upper(cols_list),'.ID|',2);
          if k > 0 then
            i := instr(cols_list, ';', k - length(cols_list));
            j := instr(cols_list, ';', k);
            if j > 0 then
              cols_list := substr(cols_list,1,i-1)||substr(cols_list,j);
            else
              cols_list := substr(cols_list,1,i-1);
            end if;
          end if;
        end if;
      end;

    begin
--if use_java then
   if lib.process_types_with_rowid() then
      if v_mode=1 then
         for_insert();
         if cols_list is null then
              return;
         end if;
      end if;
   end if;
--end if;
      while j>0 loop
        j := instr(cols_list,';',i);
        k := instr(cols_list,'|',i);
        if or_idx>0 then
          idx1:= idx1+1;
          col := ' s$'||idx1;
          l := length(col);
        end if;
        if j>0 then
          val := substr(cols_list,k+1,j-k-1);
          cols_list := substr(cols_list,x,k-x)||col||','||substr(cols_list,j+1);
        else
          val := substr(cols_list,k+1);
          cols_list := substr(cols_list,x,k-x)||col;
        end if;
        k := k+l+1;
        if val is null then
          x := instr(cols_list,'a1.STATE_ID',i-1);
          if use_java then
            if x > 0 and x <= i then
              x := 3;
            else
              x := 1;
            end if;
            plib.fill_class_info(plpclass);
            plpclass.base_type := plp$parser.STRING_;
            val := plp2java.add_bind(tmp_vars,pref,plpclass,class,false,x);
          else
            tmp_vars := tmp_vars+1;
            val := pref||tmp_vars;
            if x > 0 and x <= i then
              p_decl:= mgn||val||TAB||'varchar2(16):=valmgr.class_state('''||class||''');'||NL||p_decl;
            else
              p_decl:= mgn||val||TAB||'varchar2(16):='''||class||''';'||NL||p_decl;
            end if;
          end if;
        elsif instr(cols_list,'|'||val,k)>0 then
          i := instr(val,'.NEXTVAL');
          if i>0 then
            cols_list := replace(cols_list,'|'||val,'|rtl.next_value('''||substr(val,1,i-1)||''')');
          end if;
        end if;
        eprog := eprog||val||',';
        i := k;
        x := 1;
      end loop;
    end;
--
    procedure extract_return is
    begin
      i := instr(str,'$<$ret$>$');
      j := instr(str,'$<$ret$>$',i+9);
      etext := etext||', '||substr(str,i+9,j-i-9);
      edecl := null;
      for n in 1..or_idx loop
        edecl := edecl||', r$'||n;
      end loop;
      if v_mode=1 then
        str := substr(str,1,i-1)||substr(edecl,3)||substr(str,j+9);
      else
        edecl := substr(edecl,3)||substr(str,j+9);
        str := substr(str,1,i-1);
        i := instr(str,NL,-1);
        str := substr(str,1,i-1);
      end if;
    end;
--
begin
    if p_wipe then
        old_vars := tmp_vars;
        old_query:= query_idx;
        old_pref := cur_pref;
        old_alias:= cur_alias;
        cursor_idx := cursor_idx + 1;
        tmp_vars := 0;
        query_idx:= 1000;
        cur_alias:= 'a';
        p_decl := NULL;
    end if;
    if p_name like C_DATA_VIEWS||'%' then
      v_crit := true;
    end if;
    v_sel := true;
    v_chk := chk_class;
    p_cursor:= cursor_idx;
    tmp_idx := tmp_expr_idx;
    pref:= plib.var(p_cursor)||'$';
    cur_pref:= pref;
    str := NULL;
    p_text := NULL;
    by_row := trunc(p_all/10000);
    v_lock := p_all mod 1000;
    v_repls(1) := p_where; v_repls(2) := p_having;
    v_repls(3) := p_group; v_repls(4) := p_order;
    if not p_locks is null then
      if p_locks<0 then
        v_mode := -p_locks;
        p_locks:= null;
      elsif plib.ir(p_locks).type=plp$parser.LOCK_ then
        v_others:= false;
      else
        v_others:= true;
        v_repls(0) := p_locks;
        p_locks := null;
      end if;
    end if;
    v_repls(5) := p_locks;
    if not into_idx is null then
      if plib.ir(into_idx).type=plp$parser.RETURN_ then
        into_idx:= plib.ir(into_idx).down;
        ret_idx := plib.ir(into_idx).right;
        v_repls(6) := ret_idx;
        if use_java and ret_idx is not null then
          idx := 0;
          cols_list := null;
          j := plib.ir(ret_idx).down;
          loop
            plib.expr_class(j,v_info,true,null);
            cols_list := cols_list || plp2java.add_bind(idx,pref,v_info,null,false,0);
            j := plib.ir(j).right;
            exit when j is null;
            cols_list := cols_list || ', ';
          end loop;
        end if;
      end if;
    end if;
--entry for loop
  while not from_idx is null loop
    joins.delete;
    used_tables.delete;
    idx := plib.ir(from_idx).down;
    b := plib.ir(from_idx).type=plp$parser.IN_;
    if v_set is null then
      v_x := p_x;
      j := p_all;
      if b then
        v_set := idx;
        from_idx := plib.ir(idx).right;
      else
        v_set := from_idx;
        from_idx := null;
      end if;
    else
      if b then
        v_set := idx;
        v_x := plib.ir(from_idx).text;
        j := plib.ir(from_idx).type1;
      else
        v_set := from_idx;
        v_x := plib.ir(idx).text;
        j := 0;
      end if;
      from_idx := plib.ir(from_idx).right;
    end if;
    v_alias:= cur_alias;
    get_next_alias;
    idx := get_alias_idx(v_alias);
    aliases(idx) := nvl(all_used.last,0);
    prefixes(idx):= v_x;
    or_idx := 0;
    idx := plib.ir(v_set).type;
    idx1:= v_set;
    class := null;
    parent:= null;
    ord_text := null;
    is_class := false;
    is_kernel:= false;
    v_static := false;
    v_coll_cls := null;
    base_table := null;
    edecl := null; eprog := null; etext := null;
    if idx=plp$parser.DBCLASS_ then
      class := plib.ir(v_set).text;
      if plib.ir(v_set).text1='%arch' then
        is_kernel := true;
        b := lib.table_exist(class, table_info, true );
        base_table := table_info.log_table;
        if cur_nested is null then
          if chk_class then
            cur_class := base_table||'%rowtype';
            rtl.debug('4.'||cur_class,3,false,null);
          end if;
          chk_class:= false;
        end if;
      else
        is_class := true;
        idx := trunc(j/1000) mod 10;
        if idx=0 then
            ord_text := 'COLLECTION_ID is NULL';
            coll_text:= 'NULL';
        elsif idx in (1,3) then
            ord_text := 'COLLECTION_ID is not NULL';
        end if;
        v_static := idx in (3,4);
        idx := plib.ir(v_set).down;
        if not idx is null and plib.ir(idx).type=plp$parser.DBCLASS_ then
            idx1 := idx;
        end if;
      end if;
    elsif idx=plp$parser.SELECT_ then
      is_kernel := true;
      if p_select is null and not p_wipe then
        v_sel := false;
        base_table:= 'CURSOR$'||p_cursor;
        idx := p_locks;
      else
        j := query2plsql(v_set,p_decl,eprog,etext,idx,false,plib.nn(SP,plib.get_comments(v_set)),p_l+1);
        p_text := p_text||eprog;
--      if use_java then
              if lib.process_types_with_rowid() then
                request_process(etext);
              end if;
--        end if;
        plib.add_cursor(etext,query_idx);
        base_table:= 'CURSOR$'||query_idx;
        query_idx := query_idx+1;
      end if;
      if idx>0 then
        plib.plp_error(v_set,'CURSOR_LOCK_NOT_ALLOWED',plib.ir(v_set).text);
      end if;
      chk_class:= false;
    elsif idx=plp$parser.CURSOR_ then
        is_kernel := true;
        i := plib.ir(v_set).type1;
        if plib.ir(i).type1=plp$parser.SELECT_ then
            j := plib.ir(i).down;
            if plib.get_cursor(plib.ir(j).text1) is null then
              plib.plp_error(v_set, 'EXTERNAL_CURSOR', plib.ir(i).text );
            else
              base_table := 'CURSOR$'||plib.ir(j).text1;
              if use_context is null then
                if use_java then
                  plp2java.add_cursor_used(plib.ir(j).text1);
                elsif plib.ir(i).node<>2 then
                  if plib.ir(j).node=0 then
                    if this_mtd then
                      put_get_this(p_text,mgn);
                    end if;
                    obj_count := obj_count+1;
                  end if;
                  key_text := plib.ir(i).text;
                  if length(key_text) > 23 then
                    key_text := substr(key_text,1,23-length(plib.ir(j).text1))||plib.ir(j).text1;
                  end if;
                  p_text:= p_text||mgn||'Cursor$'||key_text||';'||NL;
                end if;
              end if;
              if plib.ir(j).type1>0 then
                plib.plp_error(v_set,'CURSOR_LOCK_NOT_ALLOWED',plib.ir(i).text);
              end if;
            end if;
            chk_class:= false;
        else
            j := plib.ir(v_set).down;
            base_table := plib.ir(j).text;
            if cur_nested is null then
              if chk_class then
                cur_class := base_table||'%rowtype';
                rtl.debug('4.'||cur_class,3,false,null);
              end if;
              chk_class:= false;
            end if;
            --if base_table like 'VW_%' then
            if plib.g_parse_java and base_table like 'VW_%' then
              for c in (select id from criteria
                         where short_name = 'VW_'||substr(base_table,4) and instr(properties,'|USERCONTEXT 1')>0
              ) loop
                --db_context := true; -- info about using contexts in non PL/Plus criteria may be not adequate
                if use_java then
                  plp2java.add_sync('<CONTEXT>',null);
                else
                  eprog := '/* synchronizeUserContext(); */';
                  if p_text is null or instr(p_text,eprog) = 0 then
                    p_text:= p_text||mgn||eprog||NL;
                  end if;
                end if;
              end loop;
            end if;
        end if;
    else
      b := true;
      class := plib.collection_element_class(v_set,ord_text,b);
      if not ord_text is null then
        bb := b is null;
        if idx=plp$parser.TEXT_ then
          etext:= plib.ir(v_set).text;
          is_kernel := etext like '%(+)';
          if is_kernel then
            etext := substr(etext,1,length(etext)-3);
          end if;
        else
          if use_java then
            is_kernel := plp2java.var4sql( v_set, p_decl, eprog, etext, mgn, true, true);
            plib.expr_class(v_set,plpclass);
            etext := plp2java.add_bind(tmp_vars,pref,plpclass,etext,false,null);
            bb := true;
          else
            is_kernel := var2plsql ( v_set, p_decl, eprog, etext,null,mgn,true,null);
          end if;
          p_text:= p_text||eprog;
          idx1 := plib.last_child(idx1);
          if plib.ir(idx1).type in (plp$parser.RTL_,plp$parser.VARMETH_) then -- function
            is_kernel := false;
          else
            is_kernel := plib.ir(idx1).node=2;
          end if;
        end if;
        if bb and not etext like 'CAST(%' then
          etext := 'cast('||etext||' as '||ord_text||')';
        end if;
        etext := 'table('||etext||')';
        if is_kernel then
          etext := etext||'(+)';
        end if;
--      if use_java then
              if lib.process_types_with_rowid() then
                request_process(etext);
              end if;
--        end if;
        plib.add_cursor(etext,-query_idx);
        base_table:= 'TABLE$'||query_idx;
        query_idx := query_idx+1;
        ord_text  := null;
        if not b then
          if chk_class and not cur_nested is null then
            cur_class := class;
            rtl.debug('3.'||cur_class,3,false,null);
          end if;
          class := '<'||class||'>';
          is_kernel := null;
        else
          is_kernel := true;
        end if;
        chk_class:= false;
      elsif idx=plp$parser.TEXT_ then
        coll_text:= plib.ir(v_set).text;
        ord_text := 'COLLECTION_ID='||coll_text;
      else
        b := plib.ir(v_set).text is null;
        if b then
          idx1 := plib.last_child(idx1);
        end if;
        if use_java then
          if plp2java.var4sql( v_set, p_decl, eprog, etext, mgn, true, b) then
            coll_text := etext;
          else
            plib.fill_class_info(plpclass);
            plpclass.base_type := plp$parser.NUMBER_;
            coll_text := plp2java.add_bind(tmp_vars,pref,plpclass,etext,false,null);
          end if;
          p_text:= p_text||eprog;
        else
          tmp_vars := tmp_vars+1;
          coll_text:= pref||tmp_vars;
          p_decl:= mgn||coll_text||TAB||'number;'||NL||p_decl;
          b := var2plsql ( v_set, p_decl, eprog, etext,null,mgn,true,false,b );   -- collection/class
          p_text:= p_text||eprog||mgn||coll_text||' := '||etext||';'||NL;
        end if;
        ord_text := 'COLLECTION_ID='||coll_text;
      end if;
    end if;
    v_part := plib.ir(idx1).node;
    if is_kernel then
      class := '<SUBQUERY>';
      parent:= null;
    elsif not is_kernel then
      b := lib.class_exist(class, v_class );
      b := lib.table_exist(class, table_info );
      base_table := table_info.table_name;
      if v_mode > 0 and table_info.distance > 0 then
        plib.plp_warning(v_set,'NO_CLASS_TABLE',class);
      end if;
      if use_java then
        plp2java.add_sync(table_info.class_id,abs(table_info.cached)>1);
      end if;
      class := v_class.class_id;
      parent:= v_class.parent_id;
      is_kernel := v_class.kernel;
      if v_part>COL_FLAG then
        v_part := v_part-COL_FADD;
      end if;
      if v_part<=-1000 then
        v_part := trunc(v_part/1000) + 1;
      end if;
      if b and cur_nested is null then
        if chk_class then
          cur_class := class;
          rtl.debug('0.'||cur_class,3,false,null);
        end if;
        chk_class := false;
      end if;
      if table_info.param_group like 'PART%' then
        add_prtprop(1,table_info.param_group,class,base_table);
      elsif v_part<=0 then
        used_tables(1).text4 := ' partition|'||v_part;
      end if;
    end if;
    if base_table is null then
        plib.plp_error(v_set,'NO_CLASS_TABLE',class);
    end if;
    if not is_kernel and not lib.pk_is_rowid(v_class.class_id) and v_class.key_attr is null then
      ref_type := 'number';
    else
      ref_type := 'varchar2'||REF_PREC;
    end if;
    used_tables(1).text1 := v_alias||'$'||base_table;
    used_tables(1).text2 := base_table;
    if by_row=0 and v_lock>0 then
      used_tables(1).text3 := '100';
    else
      used_tables(1).text3 := '000';
    end if;
    if not ord_text is NULL then
        lib.qual_column(class,'COLLECTION_ID',edecl,eprog,eprog,'2');
        if edecl=base_table then
          ord_text := v_alias||'1.'||ord_text;
        elsif v_mode=1 then
          ord_text := NULL;
          coll_text:= NULL;
        else
          if is_class and not edecl is null then
            is_class := not lib.check_class_flags(substr(v_class.flags,24,1),false); --storage_mgr.needs_collection_id(class,false);
            if is_class then
              is_class := not lib.has_collection_id(substr(eprog,instr(eprog,'.',-1)+1),true);
            end if;
          end if;
          if is_class then
            ord_text := NULL;
          elsif edecl is null then
            plib.plp_error(v_set,'NO_TABLE_COLUMN','COLLECTION_ID',class);
          else
            add_system_table('COLLECTION_ID',false);
          end if;
        end if;
    end if;
    if v_mode=1 then
      str := null;
    elsif not ord_text is null then
      if str is null then
        str := ord_text;
      else
        str := ord_text||' and '||str;
      end if;
    end if;
    if by_row = 1 then
      if use_java then
        ord_text := '1.ID>:';
      else
        p_decl := p_decl||mgn||plib.var('FOR')||TAB||ref_type||';'||NL;
        p_text := mgn||plib.var('FOR')||' := 0;'||NL||p_text;
        ord_text := '1.ID>';
      end if;
      ord_text := v_alias||ord_text||plib.var('FOR');
      if str is null then
        str := ord_text;
      else
        str := ord_text||' and '||str;
      end if;
    end if;
--
    idx := p_select;
    cnt := 0;
    is_class := from_idx is null;
    if v_crit and v_sel and nvl(bAddSysCols,true) and v_alias='a' then
        lock_text:= '111';
    else
        ord_text := null;
        lock_text:= null;
    end if;
    key_text := null;
    if v_mode=2 then
      key_text := '1';
    end if;
    while not idx is null loop
        cnt := cnt+1;
        j := plib.ir(idx).down;
        if plib.ir(idx).text is null then
          plib.ir(idx).text := 'v$'||cnt;
        end if;
        bb := false;
        if v_chk then
          if plib.ir(idx).text='ID' then
            plib.expr_class(j,v_info);
            bb := true;
          end if;
        end if;
        if v_crit then
          ord_text := plib.ir(idx).text;
          if not lock_text is null then
            if ord_text='COLLECTION_ID' then
              lock_text := '0'||substr(lock_text,2);
            elsif ord_text='CLASS_ID' then
              lock_text := substr(lock_text,1,1)||'0'||substr(lock_text,3);
            elsif ord_text='STATE_ID' then
              lock_text := substr(lock_text,1,2)||'0';
            end if;
          end if;
        end if;
        idx1 := plib.ir(j).right;
        if idx1 is null then
          i := 1;
        else
          i := -10;
        end if;
        v_repls(-1) := plib.ir(idx).right;
        -- Если мы компилируем представление, то find_used вызовется столько раз, сколько у нас колонок в представлении(для скрытых find_used колонок не вызывается)
        b := find_used( v_x, j, class, used_tables, joins, p_decl, p_text,
                        tmp_vars, or_idx, v_repls, pref, v_alias, p_l, i, is_class, key_text, ord_text, (v_part=3));  --PLATFORM-1507
        if idx1 is null then
          if bb then
            if b and plib.ir(j).type=plp$parser.TEXT_ and plib.ir(j).type1>0 and plib.ir(j).node>COL_FLAG then
              if v_info.is_reference then
                cur_class:= v_info.class_id;
                chk_class:= false;
                rtl.debug('1.'||cur_class,3,false,null);
              else
                ord_text := plib.ir(j).text;
                if ord_text like v_alias||'_%.ID' then
                  j := instr(ord_text,'.');
                  begin
                    j := substr(ord_text,length(v_alias)+1,j-length(v_alias)-1);
                    if used_tables(j).text2 like 'CURSOR$%' then
                      null;
                    elsif used_tables(j).text2 like 'TABLE$%' then
                      null;
                    elsif used_tables(j).text2 like 'table(%' then
                      null;
                    else
                      ord_text := storage_mgr.table2class(used_tables(j).text2);
                      if not ord_text is null then
                        cur_class := ord_text;
                        chk_class := false;
                        rtl.debug('2.'||cur_class,3,false,null);
                      end if;
                    end if;
                  exception when value_error or no_data_found then null;
                  end;
                end if;
              end if;
            end if;
          end if;
        else
          if not b then
            plib.plp_error(j,'COLUMN_EXPECTED');
          end if;
          plib.ir(idx).text1 := 'u$'||cnt;
          b := find_used( v_x, idx1, class, used_tables, joins, p_decl, p_text,
                          tmp_vars, or_idx, v_repls, pref, v_alias, p_l, 0, is_class, key_text, null ,(v_part=3));  --PLATFORM-1507
        end if;
        idx1:= idx;
        idx := plib.ir(idx).right;
    end loop;
--
    j := v_repls.last;
    while not j is null loop
        if not v_repls(j) is null then
            idx := plib.ir(v_repls(j)).down;
            while not idx is NULL loop
                if j > 2 then
                  if j=5 then
                    i := null;
                  else
                    i := 1;
                  end if;
                else
                 i := -j;
                end if;
                b := find_used( v_x, idx, class, used_tables, joins, p_decl, p_text,
                                tmp_vars, or_idx, v_repls, pref, v_alias, p_l, i, is_class, null, null ,(v_part=3));  --PLATFORM-1507
                idx := plib.ir(idx).right;
            end loop;
        end if;
        j := v_repls.prior(j);
    end loop;
    idx := from_idx;
    while not idx is null loop
      if plib.ir(idx).type=plp$parser.IN_ then
        j := plib.ir(idx).down;
      else
        j := idx;
      end if;
      b := find_used( v_x, j, class, used_tables, joins, p_decl, p_text,
                      tmp_vars, or_idx, v_repls, pref, v_alias, p_l, 0, false, null, null ,(v_part=3));  --PLATFORM-1507
      if b then
        v_order := false;
      end if;
      idx := plib.ir(idx).right;
    end loop;
--
    -- Добавление системных колонок COLLECTION_ID, CLASS_ID, STATE_ID
    if lock_text<>'000' and not nvl(v_crit and crit_extension, false) then
     if class like '<%>' then
      if not cur_nested is null and class<>'<SUBQUERY>' then
        class := substr(class,2,length(class)-2);
        for j in 1..3 loop
          if substr(lock_text,j,1)='1' then
            if j=1 then
              v_x := 'COLLECTION_ID';
              ord_text := '%collection';
            elsif j=2 then
              v_x := 'CLASS_ID';
              ord_text := '%class';
            else
              v_x := 'STATE_ID';
              ord_text := '%state';
            end if;
            if lib.field_exist(ord_text,class,false) then
              ord_text := v_alias||'1'||substr(ord_text,instr(ord_text,'.'));
              if j=2 then
                ord_text := 'nvl('||ord_text||','''||class||''')';
              end if;
              -- Само добавление системных колонок
              idx := plib.add2ir(plp$parser.ASSIGN_,null,v_x,null,
                     plib.add2ir(plp$parser.TEXT_,null,ord_text,null));
              plib.add_neighbour(idx1,idx);
            end if;
          end if;
        end loop;
      end if;
     else
      for j in 1..3 loop
        if substr(lock_text,j,1)='1' then
          if j=1 then
            v_x := 'COLLECTION_ID';
          elsif j=2 then
            v_x := 'CLASS_ID';
          else
            v_x := 'STATE_ID';
          end if;
          add_system_table(v_x,true);
          if not ord_text is null then
            -- Само добавление системных колонок
            idx := plib.add2ir(plp$parser.ASSIGN_,null,v_x,null,
                   plib.add2ir(plp$parser.TEXT_,null,ord_text,null));
            plib.add_neighbour(idx1,idx);
          end if;
        end if;
      end loop;
     end if;
    end if;
    if v_static then
      add_system_table('CLASS_ID',true);
      ord_text := 'not exists (select 1 from obj_static os where os.class_id='||nvl(ord_text,''''||class||'''')||' and os.id='||v_alias||'1.id'||')'||NL||mgn1;
      if str is NULL then
        str := ord_text;
      else
        str := str||NL||mgn1||' and '||ord_text;
      end if;
    end if;
--
    b := substr(used_tables(1).text3,1,1)='1';
    if b then
        null;
    elsif by_row>0 and v_lock>0 then
        i := used_tables.next(1);
        while not i is null loop
            if substr(used_tables(i).text3,1,1)='1' then
                used_tables(1).text3 := '1'||substr(used_tables(1).text3,2);
                b := TRUE; exit;
            end if;
            i := used_tables.next(i);
        end loop;
        if b then null; else
            v_lock := 0;
        end if;
        by_row := by_row+2;
    end if;
    if b then
        while parent<>constant.OBJECT loop
            b := lib.class_exist(parent, class_info );
            b := lib.table_exist(parent, table_info );
            edecl := v_alias||'$'||table_info.table_name;
            i := plib.find_record(used_tables,edecl);
            if i is null then
                i := plib.add_unique(used_tables,edecl,table_info.table_name, p_find => false);
                used_tables(i).text3 := '100';
                if table_info.param_group like 'PART%' then
                  add_prtprop(i,table_info.param_group,parent,table_info.table_name);
                end if;
            else
              used_tables(i).text3 := '1'||substr(used_tables(i).text3,2);
            end if;
            i := plib.add_unique( joins, used_tables(1).text1, 'id', edecl, 'id' );
            parent := class_info.parent_id;
        end loop;
    end if;
    --plib.dump_strings( used_tables, 'Used Tables',0 );
    --plib.dump_strings( joins, 'Joins',0 );
    key_text := null;
    i := instr(used_tables(1).text4,'|',-1);
    if instr(used_tables(1).text4,' partition')=0 then
      if v_mode=1 then
        if ascii(used_tables(1).text4)<>ASC_DIEZ then
          key_text := '1000';
        end if;
      else
        if not str is null then
            str := str||' and ';
        end if;
        if substr(used_tables(1).text3,2,1) = '1' then
          str := str||v_alias||'1.key(+)>=';
        else
          str := str||v_alias||'1.key>=';
        end if;
        if ascii(used_tables(1).text4) = ASC_DIEZ then
          str := str||substr(used_tables(1).text4,2);
        else
          str := str||used_tables(1).text4;
        end if;
      end if;
--PLATFORM-2189 BS00513588 : условие архивации "Все архивные данные"; insert в партифицировнную (PARTITION) таблицу
-- ТБП партифицирован,не требуется условие на key (used_tables(1).text4 = ' partition') :
--  в запросе указан режим использования архивных разделов = 'ALL' или условие архивации "Все архивные данные" и в запросе явно не указан раздел
    elsif i = 0 and v_mode=1 and ascii(used_tables(1).text4)<>ASC_DIEZ then
    -- при вставке в партифицированный тип колонка key должна заполняться значением 1000
      key_text := 1000;
    elsif i>11 then
      if v_mode=1 then
        if ascii(used_tables(1).text4)<>ASC_DIEZ then
          key_text := substr(used_tables(1).text4,i+1);
        end if;
      else
        if v_crit or ascii(used_tables(1).text4)=ASC_DIEZ then
          j := 1;
        else
          j := v_repls(1);
          if not j is null then
              j := plib.ir(j).down;
          end if;
        end if;
        if not j is null then
            if not str is null then
                str := str||' and ';
            end if;
            if substr(used_tables(1).text3,2,1) = '1' then
              str := str||v_alias||'1.key(+)=';
            else
              str := str||v_alias||'1.key=';
            end if;
            str := str||substr(used_tables(1).text4,i+1);
        end if;
      end if;
    end if;
    i := nvl(all_used.last,0);
    j := used_tables.first;
    while not j is null loop
        if used_tables(j).text2 like 'table(%' then
          v_order := false;
        end if;
        all_used(i+j) := used_tables(j);
        j := used_tables.next(j);
    end loop;
    i := nvl(all_joins.last,0);
    j := joins.first;
    while not j is null loop
        all_joins(i+j) := joins(j);
        j := joins.next(j);
    end loop;
  end loop; -- from_idx
    idx := all_joins.first;
    if not idx is null then
        if not str is null then
            str := str||' and ';
        end if;
        loop
            j := plib.find_record(all_used,all_joins(idx).text1);
            i := instr(all_used(j).text1,'$');
            v_alias := substr(all_used(j).text1,1,i-1);
            idx1:= aliases(get_alias_idx(v_alias));
            edecl := all_joins(idx).text2;
            i := instr(edecl,'.');
            if i>1 then
              str := str||get_col_text(substr(edecl,1,i-1),v_alias||(j-idx1),substr(edecl,i+1),false)||'=';
            else
              str := str||get_col_text(edecl,v_alias||(j-idx1),null,false)||'=';
            end if;
            j := plib.find_record(all_used,all_joins(idx).text3);
            if substr(all_used(j).text3,2,1)='1' then
              eprog := '(+)';
            else
              eprog := null;
            end if;
            edecl := all_joins(idx).text4;
            i := instr(edecl,'.');
            if i>1 then
              str := str||get_col_text(substr(edecl,1,i-1),v_alias||(j-idx1),substr(edecl,i+1),not eprog is null);
            else
              str := str||get_col_text(edecl,v_alias||(j-idx1),null,not eprog is null);
            end if;
            if instr(all_used(j).text4,' partition')=0 then
                str := str||' and '||v_alias||(j-idx1)||'.key'||eprog||'>=';
                if ascii(all_used(j).text4)=ASC_DIEZ then
                  str := str||substr(all_used(j).text4,2);
                else
                  str := str||all_used(j).text4;
                end if;
            else
              i := instr(all_used(j).text4,'|');
              if i>0 then
                str := str||' and '||v_alias||(j-idx1)||'.key'||eprog||'='||substr(all_used(j).text4,i+1);
              end if;
            end if;
            idx := all_joins.next(idx);
            exit when idx is null;
            str := str||' and ';
        end loop;
    end if;
    edecl := null;
    lock_text := null;
    if v_sel then
      is_class := FALSE;
      if p_x is null then
        b := false;
      elsif use_java then
        b := plp2java.check_save;
      else
        b := this_upd;
      end if;
      if v_order then
        i := all_used.last;
      else
        i := all_used.first;
      end if;
      loop
        j := instr(all_used(i).text1,'$');
        v_alias := substr(all_used(i).text1,1,j-1);
        idx1:= i-aliases(get_alias_idx(v_alias));
        if all_used(i).text2 like 'CURSOR$%' then
          j := substr(all_used(i).text2,8);
          edecl := edecl||'('||NL||plib.get_cursor(j)||NL||mgn1||')';
        elsif all_used(i).text2 like 'TABLE$%' then
          j := substr(all_used(i).text2,7);
          ord_text := plib.get_cursor(-j);
          if not cur_nested is null and ord_text='table(V$NESTED)' then
            j := instr(cur_nested,'.');
            v_nt_alias:= 'p$'||v_alias||idx1;
            ord_text := substr(cur_nested,2,j-2)||' '||v_nt_alias||', table('||v_nt_alias||'.'||substr(cur_nested,j+1)||')';
          end if;
          edecl := edecl||ord_text;
          if substr(all_used(i).text3,2,1)='1' then
            edecl := edecl||'(+)';
          end if;
        elsif all_used(i).text2 like 'table(%' then
          edecl := edecl||all_used(i).text2;
          if substr(all_used(i).text3,2,1)='1' then
            edecl := edecl||'(+)';
          end if;
        elsif instr(all_used(i).text4,' partition#')=1 then
          j := instr(all_used(i).text4,'|');
          if j>0 then
            edecl := edecl||substr(all_used(i).text4,12,j-12);
          else
            edecl := edecl||substr(all_used(i).text4,12);
          end if;
        else
          edecl := edecl||all_used(i).text2;
          if ascii(all_used(i).text4)=ASC_DIEZ then
            edecl := edecl||'#PRT';
          elsif instr(all_used(i).text4,' partition(')=1 then
            edecl := edecl||substr(all_used(i).text4,1,instr(all_used(i).text4,'|')-1);
          end if;
          if substr(all_used(i).text3,1,1)='1' then
            lock_text:=', '||v_alias||idx1||'.ID'||lock_text;
          end if;
          if b and all_used(i).text2=this_table then
            is_class := TRUE;
          end if;
        end if;
        edecl := edecl||' '||v_alias||idx1;
        if v_order then
            i := all_used.prior(i);
        else
            i := all_used.next(i);
        end if;
        exit when i is null;
        edecl := edecl||', ';
      end loop;
      if is_class then
        if use_java then
          plp2java.add_sync('<THIS>',null);
        else
          put_set_this(p_text,mgn);
        end if;
      end if;
    end if;
--
    if not p_locks is null then
        idx := plib.ir(p_locks).down;
        p_locks := plib.ir(p_locks).type1;
        while not idx is null loop
            if plib.ir(idx).type=plp$parser.TEXT_ and plib.ir(idx).type1>0 and plib.ir(idx).node>COL_FLAG and instr(plib.ir(idx).text,'''')=0 then
                etext := plib.ir(idx).text;
                if instr(lock_text,etext)>0 then null;
                else
                    lock_text:=lock_text||', '||etext;
                end if;
            else
                plib.plp_error(idx,'COLUMN_EXPECTED');
            end if;
            idx := plib.ir(idx).right;
        end loop;
    else
        p_locks := v_lock;
    end if;
    if not lock_text is null then
        if p_locks=0 then
          if by_row>0 then
            p_locks := -1;
          else
            p_locks := 1;
          end if;
        end if;
        lock_text:=NL||mgn1||'for update of'||substr(lock_text,2);
        if p_locks < 2 then
            lock_text:=lock_text||' nowait';
        elsif p_locks < 999 then
            lock_text:=lock_text||' wait '||(p_locks-1);
        end if;
        if v_crit then
            plib.plp_error(v_set,'CURSOR_LOCK_NOT_ALLOWED',plib.ir(v_set).text);
        end if;
    end if;
--
    tmp_expr_idx := null;
    ord_text := null;
    v_static := false;
    if not p_where is NULL then -- where
      i := plib.ir(v_repls(1)).down;
      if not i is NULL then
        b:=expr2plsql ( i, p_decl, eprog, etext, mgn,FALSE,TRUE,TRUE );      -- where expression
        if lib.process_types_with_rowid() then
            request_process(etext);
        end if;
        p_text := p_text||eprog;
        if b and etext='(''1'' = ''1'')' then
            null;
        elsif str is NULL then
            str := etext;
        else
            str := str||NL||mgn1||'  and ('||etext||')';
        end if;
        i := plib.ir(i).right;
        if not i is null then
            b:=expr2plsql ( i, p_decl, eprog, etext, mgn,FALSE,TRUE,TRUE );  -- connect by expression
            p_text := p_text||eprog;
            ord_text := NL||mgn1||'connect '||plib.ir(i).text1||' '||etext;
            v_static := true;
            i := plib.ir(i).right;
            if not i is null then
              b:=expr2plsql ( i, p_decl, eprog, etext, mgn,FALSE,TRUE,TRUE ); -- start with expression
              p_text := p_text||eprog;
              ord_text := ord_text||NL||mgn1||'start with '||etext;
            end if;
        end if;
      end if;
    end if;
    if v_others then
        i := plib.ir(v_repls(0)).down;
        b := expr2plsql ( i, p_decl, eprog, etext, mgn,FALSE,TRUE,TRUE );      -- others expression
        p_text := p_text||eprog;
        b := not str is null;
        if use_context is null or not bObjChkMode then
          str := str||NL||'/*<$others$> '||etext||' */';
          if b then
            str := NL||mgn1||'where '||str;
          end if;
        elsif b then
          str := NL||mgn1||'where '||str||NL||mgn1||' and ( '||etext||' )';
        else
          str := NL||mgn1||'where '||etext;
        end if;
    else
        str := plib.nn(NL||mgn1||'where ', str);
    end if;
    or_idx  := 0;
    v_others:= all_used.count>1;
    if v_crit or v_mode>0 then
      if v_sel then
        lock_text := NL||mgn1||'from '||edecl;
      end if;
      edecl := str;
      str := ord_text;
      ord_text := edecl;
    elsif v_sel then
      str := NL||mgn1||'from '||edecl||str||ord_text;
    end if;
    if not (v_cursor and ret_idx is null) then
      if into_idx is null then
        if not use_java then
          str := NL||mgn1||'into '||p_name||str;
        end if;
      else
        edecl := null;
        if not ret_idx is null then
          if v_mode=1 and not ord_text is null then
            v_others := true;
          end if;
          j := plib.ir(ret_idx).down;
          loop
            b := expr2plsql ( j, p_decl, eprog, etext, mgn, FALSE, TRUE, NULL );
            p_text:= p_text||eprog;
            edecl := edecl ||etext;
            j := plib.ir(j).right;
            if v_others and v_mode>0 then
              or_idx:= or_idx+1;
              edecl := edecl||' r$'||or_idx;
            end if;
            exit when j is null;
            edecl := edecl ||', ';
          end loop;
          if v_others and v_mode>0 then
            edecl := '$<$ret$>$'||edecl||'$<$ret$>$';
          end if;
        end if;
        if use_java then
          if bitand(plib.ir(into_idx).type1,2)=2 then
            if not v_cursor then
              v_cursor := null;
            end if;
          end if;
          if ret_idx is not null then
            str := str||NL||mgn1||'returning '||edecl||NL||mgn1||'into '||cols_list;
            cols_list := null;
          end if;
        else
          if bitand(plib.ir(into_idx).type1,2)=2 then
            if not v_cursor then
              v_cursor := null;
            end if;
            edecl := edecl||NL||mgn1||'bulk collect into ';
          else
            edecl := edecl||NL||mgn1||'into ';
          end if;
          idx := plib.ir(into_idx).down;
          loop
              etext := null;
              b := var2plsql( idx,p_decl,p_text,etext,chr(13),mgn );
              edecl := edecl||etext;
              idx := plib.ir(idx).right;
              exit when idx is null;
              edecl := edecl||', ';
          end loop;
          if ret_idx is null then
            str := edecl||str;
          else
            str := str||NL||mgn1||'returning '||edecl;
          end if;
        end if;
      end if;
    end if;
    idx := p_select;
    is_class:= null;
    v_nt_id := 0;
    if v_crit then
      old_alias:= cur_alias;
    end if;
    if idx is null then
      edecl := ', '||v_alias||'1.id';
      if by_row>2 then
        if v_selkey is null then
          edecl := edecl||', to_number(null) key';
        elsif v_selkey then
          edecl := edecl||', '||v_alias||'1.key';
        else
          edecl := edecl||', 0 key';
        end if;
      end if;
    else edecl := null;
      if v_mode=1 then
        str := str||'$<$values$>$';
        cols_list := ';a1.ID|SEQ_ID.NEXTVAL';
        if not key_text is null then
          cols_list := cols_list||';a1.KEY|'||key_text;
        end if;
        b := lib.check_class_flags(substr(v_class.flags,3,1),false); --storage_mgr.needs_state_id(class,false);
        if b or substr(v_class.flags,13,1)='1' or lib.has_partitions(v_class.parent_id)<>'0' then --storage_mgr.needs_class_id(class) then
          cols_list := cols_list||';a1.CLASS_ID|';
        end if;
        if b then
          cols_list := cols_list||';a1.STATE_ID|';
        end if;
        if not coll_text is null then
          cols_list := cols_list||';a1.COLLECTION_ID|'||coll_text;
        end if;
        for c in (select class_id,qual,column_name,sequenced,seq_num,base_class_id,self_class_id
                    from class_tab_columns
                   where class_id=class and deleted='0' and mapped_from is null
                     and (base_class_id=constant.COLLECTION or sequenced is not null))
        loop
          cols_list := cols_list||';a1.'||c.column_name||'|';
          if c.base_class_id = constant.COLLECTION then
            cols_list := cols_list||'SEQ_ID.NEXTVAL';
          elsif c.seq_num <> '0' and lib.class_exist(c.self_class_id,class_info) then
            class_info.data_size := class_info.data_size - nvl(class_info.data_precision,0);
            cols_list := cols_list||'num_interface.next$('''||c.class_id||''','''||c.qual||''','''||c.sequenced||''''||
                case when class_info.data_size < 28 then ','||class_info.data_size end ||')';
          else
            cols_list := cols_list||c.sequenced||'.NEXTVAL';
          end if;
        end loop;
      end if;
      cnt := 0;
      while not idx is null loop
        j := plib.ir(idx).down;
        idx1:= 1;
        if plib.ir(j).type=plp$parser.IN_ then
          i := plib.ir(j).down;
          j := plib.ir(j).right;
          if plib.ir(j).type=plp$parser.IN_ then
            j := plib.ir(j).down;
            loop
              if plib.ir(i).type=plp$parser.TEXT_ and plib.ir(i).type1>0 and plib.ir(i).node>COL_FLAG and instr(plib.ir(i).text,'''')=0 then
                etext := plib.ir(i).text;
                /*if plib.g_parse_java then
                  if plib.pop_expr_info(i,v_expr) then
                    if v_expr.conv_in > 0 then
                      etext := plib.ir(v_expr.conv_in).text||'('||etext||')';
                    end if;
                  end if;
                  plib.put_expr_info(i,v_expr);
                end if;*/
              else
                plib.plp_error(i,'COLUMN_EXPECTED');
              end if;
              edecl := edecl ||', '||etext;
              if v_mode=1 then
                check_columns(etext);
                if is_class then
                  plib.plp_error(i,'INSERT_LIST');
                end if;
                is_class := false;
                if or_idx>0 then
                  cnt := cnt+1;
                  edecl := edecl||' i$'||cnt;
                end if;
              elsif v_others then
                edecl := edecl||' '||plib.ir(idx).text||'_'||idx1;
              else
                edecl := edecl||' = ';
              end if;
              b := expr2plsql ( j, p_decl, eprog, etext, mgn, FALSE, TRUE, NULL );
              p_text:= p_text||eprog;
              if v_mode=1 then
                str := str||', '||etext;
                if instr(etext,'.nextval') > 0 and cols_list is not null then
                  check_seqs(etext);
                end if;
              elsif v_others then
                edecl := edecl||', '||etext||' '||plib.ir(idx).text1||'_'||idx1;
              else
                edecl := edecl||etext;
              end if;
              i := plib.ir(i).right;
              j := plib.ir(j).right;
              exit when i is null or j is null;
              idx1 := idx1+1;
            end loop;
            j := null;
          else
            if v_mode=1 then
              if not is_class is null then
                plib.plp_error(i,'INSERT_LIST');
              end if;
              is_class := true;
              edecl:= edecl||', ';
            else
              edecl:= edecl||', (';
            end if;
            loop
              if plib.ir(i).type=plp$parser.TEXT_ and plib.ir(i).type1>0 and plib.ir(i).node>COL_FLAG and instr(plib.ir(i).text,'''')=0 then
                etext := plib.ir(i).text;
                /*if plib.g_parse_java then
                  if plib.pop_expr_info(i,v_expr) then
                    if v_expr.conv_in > 0 then
                      etext := plib.ir(v_expr.conv_in).text||'('||etext||')';
                    end if;
                  end if;
                  plib.put_expr_info(i,v_expr);
                end if;*/
              else
                plib.plp_error(i,'COLUMN_EXPECTED');
              end if;
              edecl := edecl||etext;
              if v_mode=1 then
                check_columns(etext);
                if or_idx>0 then
                  cnt := cnt+1;
                  edecl := edecl||' i$'||cnt;
                end if;
              end if;
              i := plib.ir(i).right;
              exit when i is null;
              edecl := edecl||',';
              idx1  := idx1+1;
            end loop;
            if v_mode=2 then
              if not v_others then
                edecl := edecl||') = ';
              elsif idx1=1 then
                edecl := edecl||') '||plib.ir(idx).text;
              else
                plib.plp_error(j,'UPDATE_LIST');
              end if;
            end if;
          end if;
        else
          if plib.ir(j).type=plp$parser.TEXT_ and plib.ir(j).type1>0 and plib.ir(j).node>COL_FLAG and (v_mode=0 or instr(plib.ir(j).text,'''')=0) then
            etext := plib.ir(j).text;
            if plib.g_parse_java and v_mode = 0 then
              if plib.pop_expr_info(j,v_expr) then
                if v_expr.conv_in > 0 then
                  etext := plib.ir(v_expr.conv_in).text||'('||etext||')';
                end if;
              end if;
              plib.put_expr_info(j,v_expr);
            end if;
          elsif v_mode > 0 then
            plib.plp_error(j,'COLUMN_EXPECTED');
          else
            b := expr2plsql ( j, p_decl, eprog, etext, mgn, FALSE, TRUE, NULL );
            p_text:= p_text||eprog;
          end if;
          b := true;
          if not cur_nested is null and v_cursor and v_mode=0 and plib.ir(idx).text='NT$ID' then
            b := false;
            v_nt_id := idx;
          end if;
          if v_crit then
              if lib.process_types_with_rowid() then
              request_process(etext);
            end if;
            crit_cols(idx) := etext;
            b := false;
          elsif not b then
            b := v_nt_alias is null;
          end if;
          if b then
            cnt := cnt+1;
            edecl := edecl ||', '||etext;
            if v_mode=1 then
              check_columns(etext);
              if is_class then
                plib.plp_error(j,'INSERT_LIST');
              end if;
              is_class := false;
              if or_idx>0 then
                edecl := edecl||' i$'||cnt;
              end if;
            elsif v_mode=2 and not v_others then
              edecl := edecl||' = ';
            elsif v_cursor then
              edecl := edecl||' '||plib.ir(idx).text;
            elsif use_java then
              edecl := edecl||' v$'||cnt;
            end if;
          end if;
          j := plib.ir(j).right;
        end if;
        if not j is null then
          if plib.ir(j).type=plp$parser.SELECT_ then
            i := query2plsql(j,p_decl,eprog,etext,i,false,plib.nn(SP,plib.get_comments(j)),p_l+1);
            p_text:= p_text||eprog;
            etext := '('||NL||etext||NL||mgn1||')';
          else
            b := expr2plsql ( j, p_decl, eprog, etext, mgn, FALSE, TRUE, NULL );
            p_text:= p_text||eprog;
          end if;
          if v_mode=1 then
            str := str||', '||etext;
            if instr(etext,'.nextval') > 0 and cols_list is not null then
              check_seqs(etext);
            end if;
          elsif v_others then
            edecl := edecl||', '||etext||' '||plib.ir(idx).text1;
          else
            edecl := edecl||etext;
          end if;
        end if;

    -- Сохранение значений колонок в структуру специального типа
    -- используемую вдальнейшем для сравнения PLPlus представлений
        if p_name = C_DATA_VIEWS and crit_extension then
          if plib.ir(plib.ir(idx).down).type = plp$parser.CURSOR_ then
            sel_crit_tree(plib.ir(idx).text) := 'CURSOR';
          else
            sel_crit_tree(plib.ir(idx).text) := etext;
          end if;
        end if;

        idx := plib.ir(idx).right;
      end loop;
    end if;
    if v_crit then
      crit_hints := parse_hints(p_hints,all_used,prefixes,aliases);
      if not cur_nested is null then
        if not v_nt_alias is null then
          crit_cols(0) := v_nt_alias||'.ID';
        elsif v_nt_id>0 then
          crit_cols(0) := crit_cols(v_nt_id);
        elsif class='<SUBQUERY>' then
          crit_cols(0) := 'NT$ID';
        elsif substr(cur_nested,1,1)='1' then
          crit_cols(0) := NULL_CONST;
        else
          crit_cols(0) := 'to_number(null)';
        end if;
      end if;
    else
      etext := parse_hints(p_hints,all_used,prefixes,aliases);
      if not etext is null then
        etext := '/*+'||etext||' */ ';
      elsif bitand(by_row,1)=1 then
        etext := '/*+ FIRST_ROWS */ ';
      end if;
      if v_mode=1 then
        idx1 := 0;
        eprog:= null;
        if not cols_list is null then
          split_columns;
          if not cols_list is null then -- due to rowid
          edecl := ', '||cols_list||edecl;
          end if;
        end if;
        if use_java then
          eprog := '1,sys_context('''||inst_info.owner||'_SYSTEM'',''ID''),'||eprog;
        else
          eprog := '1,rtl.uid$,'||eprog;
        end if;
        if or_idx>0 then
          edecl := '  a1.SN s$n,a1.SU s$u'||edecl;
        else
          edecl := '  a1.SN,a1.SU'||edecl;
        end if;
        /*if v_scn then
          eprog := '1,'||eprog;
          if or_idx>0 then
            edecl := '  a1.SN s$0'||edecl;
          else
            edecl := '  a1.SN'||edecl;
          end if;
        end if;*/
        if v_others or not ord_text is null then
          etext := mgn||'insert into ('||NL||mgn1||'select '||etext||substr(edecl,3);
          if or_idx>0 then
            extract_return;
            edecl := ',s$n,s$u';
            --if v_scn then
            --  edecl := ',s$0';
            --else
            --  edecl := null;
            --end if;
            for i in 1..idx1 loop
              edecl := edecl||',s$'||i;
            end loop;
            for i in 1..cnt loop
              edecl := edecl||',i$'||i;
            end loop;
            edecl := '('||substr(edecl,2)||')';
          else
            edecl := null;
          end if;
          etext := etext||lock_text||plib.nn(null,ord_text,' with check option')||NL||mgn||') '||edecl;
        else
          i := instr(lock_text,'from ')+5;
          etext := mgn||'insert '||etext||'into '||substr(lock_text,i)
              ||' ('||substr(replace(edecl,'a1.'),2)||' )'||NL||mgn1;
        end if;
        i := instr(str,'$<$values$>$');
        if is_class then
          edecl := substr(str,i+14);
          if not eprog is null then
            j := instr(edecl,'select ')+6;
            if substr(edecl,j,4)=' /*+' then
              j := instr(edecl,'*/ ',j+4)+2;
            end if;
            if substr(edecl,j,9)=' distinct' then
              j := j+9;
            end if;
            edecl := substr(edecl,1,j)||eprog||substr(edecl,j+1);
          end if;
        else
          edecl := 'values ('||eprog||substr(str,i+14)||')';
        end if;
        str := etext||edecl||substr(str,1,i-1);
      elsif v_mode=2 then
        if use_java then
          v_x := 'sys_context('''||inst_info.owner||'_SYSTEM'',''ID'')';
        else
          v_x := 'rtl.uid$';
        end if;
        if v_others then
          i := instr(edecl,'.');
          pref := 'a1.';
          if i>0 then
            j := instr(substr(edecl,1,i),' ',-1);
            if j>0 then
              pref := substr(edecl,j+1,i-j);
            end if;
          end if;
          edecl := '  '||pref||'SN v$n, '||pref||'SU v$u, nvl('||pref||'SN,1)+1 u$n, '||v_x||' u$u'||edecl;
          /*if v_scn then
            i := instr(edecl,'.');
            pref := 'a1.';
            if i>0 then
              j := instr(substr(edecl,1,i),' ',-1);
              if j>0 then
                pref := substr(edecl,j+1,i-j);
              end if;
            end if;
            edecl := '  '||pref||'SN v$0, nvl('||pref||'SN,1)+1 u$0'||edecl;
          end if;*/
          etext := mgn||'update ('||NL||mgn1||'select '||etext||substr(edecl,3);
          if or_idx>0 then
            extract_return;
            edecl := '$<$return$>$'||edecl;
          else
            edecl := null;
          end if;
          str := etext||lock_text||ord_text||str||NL||mgn||') set'||edecl;
        else
          edecl := '  a1.SN=nvl(a1.SN,1)+1, a1.SU='||v_x||edecl;
          --if v_scn then
          --  edecl := '  a1.SN=nvl(a1.SN,1)+1'||edecl;
          --end if;
          i := instr(lock_text,'from ')+5;
          str := mgn||'update '||etext||substr(lock_text,i)||' set'||NL||mgn1||substr(edecl,3)||ord_text||str;
        end if;
      elsif v_mode=3 then
        if v_others then
          etext := mgn||'delete from ('||NL||mgn1||'select '||etext||substr(edecl,3);
          if or_idx>0 then
            extract_return;
            edecl := NL||mgn1||'returning '||edecl;
          else
            edecl := null;
          end if;
          str := etext||lock_text||ord_text||str||NL||mgn||')'||edecl;
        else
          i := instr(lock_text,'from ');
          str := mgn||'delete '||etext||substr(lock_text,i)||ord_text||str;
        end if;
      elsif v_sel then
        if not use_java and not into_idx is null and bitand(plib.ir(into_idx).type1,4)=4 then
          edecl := ', '||plib.ir(into_idx).text||'('||substr(edecl,3)||')';
        end if;
        if not cur_nested is null then
          if not v_nt_alias is null then
            edecl := ', '||v_nt_alias||'.ID NT$ID'||edecl;
          elsif v_nt_id>0 then
            null;
          elsif class='<SUBQUERY>' then
            edecl := ', NT$ID'||edecl;
          elsif substr(cur_nested,1,1)='1' then
            edecl := ', null NT$ID'||edecl;
          else
            edecl := ', to_number(null) NT$ID'||edecl;
          end if;
        end if;
        str := mgn1||'select '||etext||p_dist||substr(edecl,2)||str;
      end if;
      if v_mode>0 then
        lock_text:= null;
        ord_text := null;
      end if;
    end if;
    if not p_group is null then
        idx := plib.ir(p_group).down; edecl := null;
        while not idx is null loop
            b := expr2plsql ( idx, p_decl, eprog, etext, mgn, FALSE, TRUE, NULL );
            p_text := p_text||eprog;
            edecl := edecl||','||etext;
            idx := plib.ir(idx).right;
        end loop;
        if not edecl is null then
            str := str||NL||mgn1||'group by '||substr(edecl,2);
        end if;
    end if;
    if not p_having is null then
        b := expr2plsql ( plib.ir(p_having).down, p_decl, eprog, etext, mgn, FALSE, TRUE, TRUE );    -- having expression
        p_text := p_text||eprog;
        if not etext is null then
            str := str||NL||mgn1||'having '||etext;
        end if;
    end if;
--
    edecl := null;
    if not use_java then
      if plib.g_method_cache and plib.g_method_commit then
        edecl:=edecl||mgn||'cache_mgr.write_cache;'||NL;
      end if;
      if p_locks<>0 then
        etext := p_cursor||lpad(plib.g_method_id,10,'0');

        if plib.sql_options_lock_info_cur then
           edecl := edecl
            ||mgn||'rtl.lock_put_get('''||etext||''',''CURSOR'','||linfo_txt||');'||NL;
        end if;

      end if;
    end if;
    p_text := p_text||edecl;
    if not v_cursor then
      if not (p_order is null or plib.ir(p_order).down is null) then
        plib.plp_warning(p_order,'ORDERING_NOT_USED');
      end if;
    else
        if bitand(by_row,1)=1 then
            str := str||NL||mgn1||'order by '||v_alias||'1.id';
        end if;
        if not p_order is NULL then
            v_x := plib.ir(p_order).text;
            idx := plib.ir(p_order).down;                   -- head of 'order by' list
            j := instr(v_x,'.');
            i := j+1;
            edecl := null;
            while not idx is NULL loop
                b:=expr2plsql ( idx, p_decl, eprog, etext, mgn, FALSE, TRUE, NULL );    -- order by expression
                edecl := edecl||','||etext||order_dir(substr(v_x,i,1));
                p_text := p_text||eprog;
                i := i + 1;
                idx := plib.ir(idx).right;
            end loop;
            if not edecl is NULL then
                if bitand(by_row,1)=1 then
                    plib.plp_warning(p_order,'ORDERING_NOT_USED');
                else
                    if v_static then
                      v_x := substr(v_x,1,j-1)||' ';
                    else
                      v_x := 'by ';
                    end if;
                    str := str||NL||mgn1||'order '||v_x||substr(edecl,2);
                end if;
            end if;
        end if;
    end if;
    if v_crit then
      if not (p_decl is null and p_text is null) then
        rtl.debug(NL||p_decl||NL||p_text,1,false,null);
        plib.plp_error(v_set,'CURSOR_DECLARATIONS',plib.ir(v_set).text);
      end if;
      p_decl := lock_text;
      p_text := ord_text;
    else
      str := str||lock_text;
      if v_cursor and not p_name is null then
        p_decl := p_decl||mgn||'cursor '||p_name||' is'||NL;
      end if;
    end if;
    if p_wipe then
--      if use_java then
              if lib.process_types_with_rowid() then
                request_process(str);
              end if;
--        end if;
        plib.add_cursor(str,p_cursor);
        tmp_vars := old_vars;
        query_idx:= old_query;
        cur_pref := old_pref;
        cur_alias:= old_alias;
    end if;
    idx := all_used.count;
    if is_kernel then idx:=-idx; end if;
    tmp_expr_idx := tmp_idx;
    chk_class := false;
--    if use_java then
          if lib.process_types_with_rowid() then
            request_process(str);
       end if;
    if use_java then
          if plp2java.gen_DAO() then
           declare
             ind pls_integer;
             list_of_tbls varchar2(512) := '';
           begin
             ind := all_used.first;
             while not ind is null loop
                list_of_tbls := list_of_tbls || all_used(ind).text2 || '|';
                ind := all_used.next(ind);
             end loop;
             plp2java.take_tbls_in_request(list_of_tbls);
           end;
         end if;
    end if;
    return idx;
end construct_cursor_text;
--
-- @METAGS collect_hints
function collect_hints ( p_idx IN pls_integer, p_child boolean default false ) return varchar2 is
    idx   pls_integer;
    typ   pls_integer;
    child pls_integer;
    txt   varchar2(4000);
    txt1  varchar2(4000);
begin
    idx := plib.ir(p_idx).left;
    while not idx is null loop
        typ := plib.ir(idx).type;
        if typ = plp$parser.PRAGMA_ then
          if plib.ir(idx).text = plib.HINT_PRAGMA then
            child := plib.ir(idx).down;
            while not child is NULL loop
              if not ltrim(plib.ir(child).text) is null then
                txt := txt||' '||trim(plib.ir(child).text);
              end if;
              child := plib.ir(child).right;
            end loop;
          end if;
        elsif typ in (plp$parser.LABEL_,plp$parser.NULL_) then
            null;
        else
            exit;
        end if;
        idx := plib.ir(idx).left;
    end loop;
    idx := p_idx;
    if p_child then
        idx := plib.ir(p_idx).down;
    end if;
    txt1 := plib.get_comments(idx);
    if txt1 is null then
        return txt;
    end if;
    return txt||' '||txt1;
end collect_hints;
--
-- @METAGS query2plsql
function  query2plsql (  p_idx  IN pls_integer,
                         p_decl in out nocopy varchar2,
                         p_prog in out nocopy varchar2,
                         p_text in out nocopy varchar2,
                         p_locks   out pls_integer,
                         p_wipe IN boolean  default false,
                         hints  IN varchar2 default null,
                         p_l    IN pls_integer default 0
                       ) return pls_integer is
    idx       pls_integer;
    typ       pls_integer;
    v_idx     pls_integer;
    v_set     pls_integer;
    sel_idx   pls_integer;
    group_idx pls_integer;
    hav_idx   pls_integer;
    where_idx pls_integer;
    order_idx pls_integer;
    lock_idx  pls_integer;
    v_cursor  pls_integer;
    mgn       varchar2(1000);
    txt       varchar2(1000);
begin
  typ := plib.ir(p_idx).type1;
  txt := plib.ir(p_idx).text;
  idx := plib.ir(p_idx).down;   -- INTO list/type declaration
  v_idx := plib.ir(idx).right;  -- ID declaration
  v_set := plib.ir(idx).text1;  -- collection/class
  if plib.ir(idx).type=plp$parser.INTO_ then -- into vars list
    v_cursor := 0;
  else
    v_cursor := 1;
    idx := null;
  end if;
  if typ=plp$parser.UNION_ then
    declare
      edecl   varchar2(32767);
      eprog   varchar2(32767);
      etext   varchar2(32767);
      ord_txt varchar2(4000);
      mgn     varchar2(100) := rpad(TAB,p_l+1,TAB); -- left margin
      v_pref  varchar2(30);
      v_alias varchar2(10);
      v_als   varchar2(10);
      b       boolean;
      col     boolean;
    begin
      if p_wipe then
        cursor_idx := cursor_idx + 1;
        v_pref := cur_pref;
        sel_idx := tmp_vars;
        v_alias := cur_alias;
        group_idx:= query_idx;
        tmp_vars := 0;
        query_idx:= 1000;
        cur_alias:= 'a';
        p_decl := null;
      end if;
      v_set := plib.ir(v_idx).right; -- first query
      v_als := cur_alias;
      v_cursor:= cursor_idx;
      ord_txt := plib.get_comments(v_set);
      if ord_txt is null then
          ord_txt := hints;
      else
          ord_txt := hints||' '||ord_txt;
      end if;
      where_idx := query2plsql(v_set,p_decl,p_prog,p_text,lock_idx,false,ord_txt,p_l);
      v_set := plib.ir(v_set).right; -- second query
      ord_txt := plib.get_comments(v_set);
      if ord_txt is null then
          ord_txt := hints;
      else
          ord_txt := hints||' '||ord_txt;
      end if;
      where_idx := query2plsql(v_set,p_decl,eprog,etext,lock_idx,false,ord_txt,p_l);
      p_prog := p_prog||eprog;
      p_text := p_text||NL||mgn||TAB||txt||NL||etext;
      if plib.ir(p_idx).text1 = 'P' then
        p_text := mgn||TAB||'('||ltrim(p_text,TAB)||')';
      end if;
      order_idx := plib.ir(v_set).right;
      col := idx is null;
      if not col then -- into vars list
        col := bitand(plib.ir(idx).type1,2)=2;
      end if;
      b := false;
      if not order_idx is null then
        txt := plib.ir(v_idx).text;
        lock_idx := plib.ir(order_idx).right;
        v_idx := plib.ir(order_idx).down;
        if not v_idx is null then
          if not col then
            v_idx := null;
            plib.plp_warning(order_idx,'ORDERING_NOT_USED');
          end if;
        end if;
        if not (lock_idx is null and v_idx is null) then
          cur_alias := v_als;
          v_idx := 1;
          v_idx := construct_cursor_text ( txt,
                                  null,
                                  null,
                                  p_idx,
                                  null,
                                  null,
                                  null,
                                  null,
                                  order_idx,
                                  p_l,
                                  0,
                                  lock_idx,
                                  v_idx,
                                  p_decl,
                                  eprog,
                                  etext,
                                  null,
                                  null,
                                  false);
          p_prog := p_prog||eprog;
          p_text := mgn||'select * '||NL||mgn||'from ('||NL||p_text||NL||mgn||') '||v_als||'1'||etext;
          b := true;
        end if;
      end if;
      if p_wipe then
        plib.add_cursor(p_text,v_cursor);
      end if;
      if not idx is null and not use_java then
        if b then
          p_text := substr(p_text,instr(p_text,NL)+1);
        else
          p_text := mgn||'from ('||NL||p_text||NL||mgn||')';
        end if;
        idx := plib.ir(idx).down;
        edecl := null;
        while not idx is null loop
            etext := null;
            b := var2plsql( idx,p_decl,p_prog,etext,null,mgn );
            edecl := edecl||', '||etext;
            idx := plib.ir(idx).right;
        end loop;
        p_text := mgn||'select * '||case when col then 'bulk collect into' else 'into' end||substr(edecl,2)||NL||p_text;
      end if;
      if p_wipe then
        tmp_vars := sel_idx;
        query_idx:= group_idx;
        cur_alias:= v_alias;
        cur_pref := v_pref;
      end if;
      p_locks := 0;
    end;
  else
    sel_idx  := plib.ir(v_set).right; -- select list head
    where_idx:= plib.ir(sel_idx).right;   -- where clause head
    sel_idx  := plib.ir(sel_idx).down; -- select list first entry
    group_idx:= plib.ir(where_idx).right; -- group clause head
    hav_idx  := plib.ir(group_idx).right; -- having clause head
    order_idx:= plib.ir(hav_idx).right;   -- order clause head
    if not order_idx is null then
      lock_idx := plib.ir(order_idx).right; -- for update clause head
    end if;
    v_idx := construct_cursor_text ( txt,
                            null,
                            sel_idx,
                            v_set,
                            idx,
                            where_idx,
                            hav_idx,
                            group_idx,
                            order_idx,
                            p_l,
                            typ,
                            lock_idx,
                            v_cursor,
                            p_decl,
                            p_prog,
                            p_text,
                            hints,
                            plib.ir(p_idx).text1,
                            p_wipe);
    p_locks := lock_idx;
  end if;
  return v_cursor;
end query2plsql;
--
-- @METAGS iterator2plsql
procedure iterator2plsql ( p_idx  IN pls_integer,
                           p_l    IN pls_integer,
                           p_text in out nocopy plib.string_tbl_t,
                           l_text in out nocopy varchar2
                         ) is
    idx       pls_integer;
    idx1      pls_integer;
    cnt       pls_integer;
    gcnt      pls_integer;
    in_idx    pls_integer;
    sos_idx   pls_integer;
    where_idx pls_integer;
    order_idx pls_integer;
    v_lock    pls_integer;
    v_cursor  pls_integer := 1;
    xvar      varchar2(1000);
    xvar1     varchar2(1000);
    xvar2     varchar2(30);
    edecl     varchar2(32767);
    eprog     varchar2(32767);
    etext     varchar2(32767);
    sos_text  plib.string_tbl_t;
    mgn       varchar2(100) := rpad(TAB,p_l+1,TAB);    -- left margin
    mgn0      varchar2(100) := rpad(TAB,p_l,TAB);
    mgn1      varchar2(100) := rpad(TAB,p_l+2,TAB);
    suffix    varchar2(30);
    vclass    varchar2(16);
    ref_type  varchar2(16);
    b         boolean;
    mtd       boolean;
    upd       boolean;
    get       boolean;
    locking   boolean;
    by_row    boolean;
    xid       varchar2(5);                -- Колонка для идентификации в типе, по которому проходит итератор (id или rowid)
begin
    tmp_var_idx:=tmp_var_idx+1;
    tmp_sos_idx:=tmp_var_idx;
    xvar1:= plib.ir(p_idx).text1;
    idx  := plib.ir(p_idx).down;
    if not xvar1 is null then
        vclass := plib.ir(plib.ir(idx).down).text;
        idx := plib.ir(idx).right;
    end if;
    xvar := plib.ir(idx).text;
    ref_type := plsql_type(plib.ir(idx).down);
    xid := rtl.bool_char(lib.pk_is_rowid(plib.ir(plib.ir(idx).down).text), 'rowid', 'id');
    in_idx := plib.ir(idx).right;           -- IN_
    sos_idx := plib.ir(in_idx).right;       -- SOS_
    idx := plib.ir(in_idx).down;            -- collection/class
    idx1:= plib.ir(in_idx).type1;           -- lock/all/one clause
    by_row := idx1>=10000;
    if by_row and ( (idx1 mod 1000) > 0 ) then
      xvar2 := plib.var('K$');
    end if;
    where_idx := plib.ir(idx).right;        -- where clause
    order_idx := plib.ir(where_idx).right;  -- order by clause
    idx1 := construct_cursor_text ( xvar,
                            'c_obj',
                            null,
                            idx,
                            null,
                            where_idx,
                            null,
                            null,
                            order_idx,
                            p_l,
                            idx1,
                            v_lock,
                            v_cursor,
                            edecl,
                            eprog,
                            etext,
                            collect_hints(p_idx),
                            plib.ir(in_idx).text1
                          );
    xvar := plib.ir(p_idx).text;
    edecl := edecl||etext||';'||NL;
    b := this_chg;
    get := this_get;
    upd := this_upd;
    mtd := this_mtd;
    cnt := obj_count;
    gcnt:= get_count;
    sos2plsql ( sos_idx, p_l+2, edecl, sos_text,tmp_var_idx, by_row or v_lock=0 );      -- sos
    etext := null;
    this_state(mtd,upd,b,get,cnt<obj_count,gcnt<get_count,etext,mgn);
    if not xvar1 is null then
        edecl := mgn||xvar1||TAB||class2plsql(vclass,true,idx)||';'||NL||edecl;
    end if;
    if not xvar2 is null then
        edecl := mgn||xvar2||TAB||'number;'||NL||edecl;
    end if;
    etext :=  mgn0|| 'declare' || NL
           || mgn || xvar ||TAB||ref_type||';'||NL||edecl
           || mgn0|| 'begin' || NL
           || eprog
           || etext;
    locking:= v_lock>0 and v_lock<999;
    if by_row then
        etext := etext||l_text
           || mgn ||'loop'||NL
           || mgn1||xvar||' := null;'||NL
           || mgn1|| 'for '||plib.var('c_obj')||' in c_obj loop' || NL
           || mgn1||TAB||xvar||' := '||plib.var('c_obj')||'.'||xid||';';
        if not xvar2 is null then
          etext := etext||SP||xvar2||' := '||plib.var('c_obj')||'.key;';
        end if;
        etext := etext||' exit;' || NL
           || mgn1|| 'end loop;' || NL
           || mgn1|| 'exit when '||xvar||' is null;'|| NL
           || mgn1||plib.var('FOR')||' := '||xvar||';' || NL;
        if v_lock<=0 then
            b := v_lock<0;
            v_lock := plib.ir(in_idx).type1 mod 1000;
            if v_lock>0 then
                db_update := true;
                suffix:= '(';
                xvar1 := ', key_ => '||xvar2||');';
                if v_lock>998 then
                  suffix:= '_wait(';
                elsif v_lock>1 then
                  xvar1 := ', p_wait => '||(v_lock-1)||xvar1;
                end if;
                etext := etext || mgn1
                       ||class_mgr.interface_package(plib.ir(in_idx).text)
                       ||'.lock_object'||suffix||xvar||','||linfo_txt||xvar1||NL;
            elsif b then
                v_lock := 1;
                locking := true;
            end if;
        end if;
    else
        etext := etext||l_text
           || mgn || 'for '||plib.var('c_obj')||' in c_obj loop' || NL
           || mgn1||xvar||' := '||plib.var('c_obj')||'.'||xid||';' || NL;
    end if;
    lib.put_buf(etext,p_text);
    if sos_text.count=0 then
        sos_text(1) := mgn1||'exit;'||NL;
    end if;
    lib.add_buf(sos_text,p_text,true,true);
    l_text := mgn || 'end loop;' || NL;
    if locking then
      db_update := true;
      if v_lock=1 then
        suffix := 'BUSY';
      else
        suffix := 'WAIT or rtl.RESOURCE_LOCK';
      end if;
      l_text := l_text
            ||mgn0||'exception when rtl.RESOURCE_'||suffix||' then raise rtl.CANNOT_LOCK;'||NL;
    end if;
    l_text := l_text || mgn0 || 'end;' || NL;
end iterator2plsql;
--
-- @METAGS locate2plsql
function  locate2plsql ( p_idx  IN     pls_integer,
                         p_l    IN     pls_integer,
                         p_decl in out nocopy varchar2,
                         p_text in out nocopy varchar2
                       ) return varchar2 is
    node      pls_integer := plib.ir(p_idx).node;
    where_idx pls_integer;
    order_idx pls_integer;
    xvar_id   varchar2(1000);
    xvar1     varchar2(100);
    xvar2     varchar2(100);
    edecl     varchar2(32767);
    eprog     varchar2(32767);
    etext     varchar2(32767);
    mgn0      varchar2(100) := rpad(TAB,p_l,TAB); -- left margin
    mgn       varchar2(100) := rpad(TAB,p_l+1,TAB);    -- left margin
    suffix    varchar2(30);
    v_cls     varchar2(30);
    b         boolean;
    locking   boolean;
    idx       pls_integer;
    v_var     pls_integer;
    v_set     pls_integer;
    v_idx     pls_integer;
    tmp_idx   pls_integer;
    v_lock    pls_integer;
    v_cursor  pls_integer;
    var_idx   pls_integer;
    --dlevel    pls_integer := 2;
    xid       varchar2(5);                -- Колонка для идентификации в типе, по которому проходит итератор (id или rowid)
begin
    tmp_idx := tmp_sos_idx;
    v_var := plib.ir(p_idx).down;
    v_cls := plib.ir(p_idx).text1;
    v_set := plib.ir(v_var).right;    -- collection/class
    idx := plib.ir(p_idx).type1;    -- lock/all/one clause
    v_idx := plib.ir(v_set).right;  -- var definition
    xvar_id := plib.get_new_name(v_idx);
    xvar1 := plib.ir(v_idx).text;
    xid := rtl.bool_char(lib.pk_is_rowid(plib.ir(plib.ir(v_idx).down).text), 'rowid', 'id');
    v_idx := plib.ir(v_idx).right;  -- var name
    where_idx := plib.ir(v_idx).right;      -- where clause head
    order_idx := plib.ir(where_idx).right;    -- order clause head
    if node in (0,1) then
        edecl := ref_string(lib.has_stringkey(v_cls),true, lib.pk_is_rowid(v_cls));
        if tmpvar(tmp_idx,'ID',edecl,tmp_expr_idx) then
            p_decl := mgn0||lasttmp||TAB||edecl||';'||NL||p_decl;
        end if;
        tmp_expr_idx := nvl(tmp_expr_idx,0) + 1;
        plib.replace_prefix(v_idx,xvar1,lasttmp);
        xvar_id := lasttmp;
        var_idx := last_idx;
        xvar1 := xvar_id;
    end if;
    b:=plib.ir(p_idx).text is NULL;-- not exact text
    if b then
      if (idx mod 1000) > 0  then
        xvar2 := plib.var('K$');
      end if;
      idx := idx+20000;
    end if;
    tmp_var_idx:=tmp_var_idx+1;
    tmp_sos_idx:=tmp_var_idx;
    if b then v_cursor := 1; else v_cursor := 0; end if;
    idx := construct_cursor_text ( xvar1,
                            case when b then 'c_obj' else xvar_id end,
                            null,
                            v_set,
                            null,
                            where_idx,
                            null,
                            null,
                            order_idx,
                            p_l,
                            idx,
                            v_lock,
                            v_cursor,
                            edecl,
                            eprog,
                            etext,
                            collect_hints(p_idx)
                          );
    locking:= v_lock>0 and v_lock<999;
    if b then -- not exact
        if not xvar2 is null then
          edecl := mgn||xvar2||TAB||'number;'||NL||edecl;
        end if;
        p_text := p_text
               || mgn0||'declare'||NL
               ||edecl|| etext ||';'||NL
               || mgn0||'begin'||NL ||eprog
               || mgn ||xvar_id||' := NULL;' || NL
               || mgn ||'for '||plib.var('c_obj')||' in c_obj loop' || NL
               || mgn ||TAB||xvar_id||' := '||plib.var('c_obj')||'.'||xid||';';
        if not xvar2 is null then
          p_text := p_text||SP||xvar2||' := '||plib.var('c_obj')||'.key;';
        end if;
        p_text := p_text||' exit;'|| NL
               || mgn || 'end loop;' || NL;
        if plib.g_method_subst then
            p_text := p_text
               || mgn || 'if '||xvar_id||' is NULL then raise rtl.NO_DATA_FOUND; end if;'||NL;
        end if;
        if v_lock<=0 then
            b := v_lock<0;
            v_lock := plib.ir(p_idx).type1 mod 1000;
            if v_lock>0 then
                db_update := true;
                suffix:= '(';
                xvar2 := ', key_ => '||xvar2||');';
                if v_lock>998 then
                  suffix:= '_wait(';
                elsif v_lock>1 then
                  xvar2 := ', p_wait => '||(v_lock-1)||xvar2;
                end if;
                p_text := p_text || mgn
                       ||class_mgr.interface_package(v_cls)
                       ||'.lock_object'||suffix||xvar_id||','||linfo_txt||xvar2||NL;
            elsif b then
                v_lock := 1;
                locking := true;
            end if;
        end if;
        if locking then
            p_text := p_text||mgn0||'exception'||NL;
        end if;
    else
        p_text := p_text
           || plib.nn( mgn0 ||'declare'||NL, edecl)
           || mgn0 ||'begin'||NL
           || eprog|| etext ||';'||NL;
        if plib.g_method_subst then
            etext := 'raise rtl.NO_DATA_FOUND;';
        else
            etext := xvar_id||' := null;';
        end if;
        p_text := p_text ||mgn0||'exception'|| NL
            ||mgn ||'when NO_DATA_FOUND then '||etext||NL
            ||mgn ||'when TOO_MANY_ROWS then raise rtl.TOO_MANY_ROWS;'||NL;
    end if;
    if locking then
        db_update := true;
        if v_lock=1 then
          suffix := 'BUSY';
        else
          suffix := 'WAIT or rtl.RESOURCE_LOCK';
        end if;
        p_text := p_text
            ||mgn||'when rtl.RESOURCE_'||suffix||' then raise rtl.CANNOT_LOCK;'||NL;
    end if;
    p_text := p_text
            ||mgn0|| 'end;' || NL;
    tmp_sos_idx := tmp_idx;
    if node=0 then
        tmp_expr_idx := null;
        b := expr2plsql ( v_idx, p_decl, etext, edecl, mgn );
        p_text := p_text||etext;
        etext := null;
        b := var2plsql ( v_var, p_decl, p_text, etext, edecl,mgn );
        p_text := p_text||mgn0||etext||';'||NL;
    end if;
    if var_idx is null then
      return xvar_id;
    end if;
    return xvar_id||':'||var_idx;
end locate2plsql;
--
-- @METAGS select2plsql
procedure select2plsql ( p_idx  IN     pls_integer,
                         p_l    IN     pls_integer,
                         p_text in out nocopy varchar2
                       )  is
    lock_idx  pls_integer;
    edecl     varchar2(32767);
    eprog     varchar2(32767);
    etext     varchar2(32767);
    suffix    varchar2(30);
    mgn0      varchar2(100) := rpad(TAB,p_l,TAB); -- left margin
    mgn       varchar2(100) := rpad(TAB,p_l+1,TAB);    -- left margin
    tmp_idx   pls_integer;
    v_cursor  pls_integer;
    v_type    boolean;
begin
    tmp_idx:= tmp_sos_idx;
    v_type := bitand(plib.ir(plib.ir(p_idx).down).type1,3)=0;
    tmp_var_idx:=tmp_var_idx+1;
    tmp_sos_idx:=tmp_var_idx;
    v_cursor := query2plsql(p_idx,edecl,eprog,etext,lock_idx,true,collect_hints(p_idx),p_l);
    etext := eprog||etext||';'||NL;
    eprog := null;
    if lock_idx>0 then
      db_update := true;
      if lock_idx<999 then
        if lock_idx=1 then
          suffix := 'BUSY';
        else
          suffix := 'WAIT or rtl.RESOURCE_LOCK';
        end if;
        eprog := mgn||'when rtl.RESOURCE_'||suffix||' then raise rtl.CANNOT_LOCK;'||NL;
      end if;
    end if;
    if v_type then
      eprog := eprog
        || mgn ||'when NO_DATA_FOUND then '||case when plib.g_method_subst then 'raise rtl.NO_DATA_FOUND;' else NULL_STMT end||NL
        || mgn ||'when TOO_MANY_ROWS then raise rtl.TOO_MANY_ROWS;'||NL;
    end if;
    if not eprog is null then
      eprog := mgn0||'exception'|| NL || eprog;
    end if;
    if edecl is null and eprog is null then
      p_text:= p_text||etext;
    else
       p_text:= p_text
           || plib.nn( mgn0||'declare'||NL, edecl)
           || mgn0||'begin'||NL||etext||eprog
           || mgn0||'end;' ||NL;
    end if;
    tmp_sos_idx := tmp_idx;
end select2plsql;
--
procedure forall_text(p_idx pls_integer, p_var pls_integer, mgn varchar2,
                      txtfor in out nocopy varchar2, p_decl in out nocopy varchar2, p_text in out nocopy varchar2) is
    eprog varchar2(4000);
    v_txt varchar2(4000);
    v_idx varchar2(100);
    v_sav boolean;
    v_for pls_integer := p_idx;
    b boolean;
begin
    v_idx := plib.ir(v_for).text1;
    v_sav := plib.ir(v_for).text='exceptionloop';
    txtfor:= mgn||'forall '||plib.get_new_name(p_var)||' in ';
    v_for := plib.ir(v_for).down;
    b:=expr2plsql(v_for,p_decl,eprog,v_txt,mgn,false);
    p_text := p_text||eprog;
    if v_idx='index' then
      txtfor:= txtfor||'values of ';
    elsif v_idx='in' then
      txtfor:= txtfor||'indices of ';
      v_for := plib.ir(v_for).right;
      if not v_for is null then
        txtfor:= txtfor||v_txt||' between ';
        b:=expr2plsql(v_for,p_decl,eprog,v_txt,mgn,false);
        p_text := p_text||eprog;
        txtfor := txtfor||v_txt||' and ';
        b:=expr2plsql(plib.ir(v_for).right,p_decl,eprog,v_txt,mgn,false);
        p_text := p_text||eprog;
      end if;
    else
      txtfor:= txtfor||v_txt||' .. ';
      b:=expr2plsql(plib.ir(v_for).right,p_decl,eprog,v_txt,mgn,false);
      p_text := p_text||eprog;
    end if;
    txtfor:= txtfor||v_txt;
    if v_sav then
      txtfor:= txtfor||' save exceptions';
    end if;
    txtfor:= txtfor||NL;
end;
--
procedure insert2plsql2( p_idx  IN     pls_integer,
                         p_l    IN     pls_integer,
                         p_text in out nocopy varchar2
                       )  is
    idx       pls_integer;
    sel_idx   pls_integer;
    ret_idx   pls_integer;
    where_idx pls_integer;
    lock_idx  pls_integer;
    edecl     varchar2(32767);
    etext     varchar2(32767);
    txt       varchar2(32767);
    txtfor    varchar2(8000);
    hints     varchar2(2000);
    mgn0      varchar2(100) := rpad(TAB,p_l,TAB); -- left margin
    mgn       varchar2(100) := rpad(TAB,p_l+1,TAB);    -- left margin
    dcl       boolean;
    excpt     boolean;
    chk_ins   boolean;
    v_set     pls_integer;
    v_for     pls_integer;
    tmp_idx   pls_integer;
    v_cursor  pls_integer := 1;
    --dlevel    pls_integer := 2;
    node      plib.ir_node_t := plib.ir(p_idx);
begin
    skip_attrs := false;
    chk_ins := true;
    tmp_idx := tmp_sos_idx;
    v_set := plib.ir(node.down).down;
    if plib.ir(v_set).type=plp$parser.INTEGER_ then
      v_for := v_set;
      v_set := plib.ir(node.down).right;
      skip_attrs := null;
    else
      v_set := node.down;
    end if;
    v_set := plib.ir(v_set).right;  -- collection/class
    where_idx:= plib.ir(v_set).right;   -- where clause head
    sel_idx  := plib.ir(where_idx).right; -- select list first entry
    if plib.ir(sel_idx).type=plp$parser.RETURN_ then
      ret_idx := sel_idx;
      excpt := bitand(plib.ir(plib.ir(ret_idx).down).type1,3)=0;
      sel_idx := plib.ir(ret_idx).right; -- select list first entry
    end if;
    tmp_var_idx:=tmp_var_idx+1;
    tmp_sos_idx:=tmp_var_idx;
    hints := collect_hints(p_idx);
    if instr(upper(hints),' PLP_SKIP_CHECK')>0 then
        hints := rtl.safe_replace(hints,' PLP_SKIP_CHECK');
        chk_ins := false;
    end if;
    lock_idx := -1;
    idx := construct_cursor_text ( node.text,
                            null,
                            sel_idx,
                            v_set,
                            ret_idx,
                            where_idx,
                            null,
                            null,
                            null,
                            p_l,
                            0,
                            lock_idx,
                            v_cursor,
                            edecl,
                            etext,
                            txt,
                            hints
                          );
  if idx > 0 then
    if idx > 1 then
      plib.plp_warning(p_idx,'DML_QUERY',node.text1,'INSERT');
    end if;
    if not v_for is null then
      forall_text(v_for,node.down,mgn,txtfor,edecl,etext);
    end if;
    txt := txt||';'||NL;
    dcl := not edecl is null or excpt;
    if dcl then
        p_text := p_text
           || plib.nn( mgn0||'declare'||NL, edecl)
           || mgn0||'begin'||NL|| etext;
        if excpt then
          txt := txt||mgn0||'exception when TOO_MANY_ROWS then raise rtl.TOO_MANY_ROWS;'||NL;
        end if;
        txt := txt||mgn0||'end;'||NL;
    else
        p_text := p_text||etext;
    end if;
    if chk_ins then
      p_text := p_text
             || mgn || 'valmgr.check_insert('''||node.text1||''');'||NL;
    end if;
    p_text := p_text|| txtfor||txt;
    db_update := true;
  else
    plib.plp_warning(p_idx,'DML_METADATA',node.text1,'INSERT');
    p_text := p_text||mgn0||'message.error(''CLS'',''METADATA'');'||NL;
  end if;
    tmp_sos_idx := tmp_idx;
    skip_attrs := false;
end insert2plsql2;
--
-- @METAGS update2plsql
procedure update2plsql ( p_idx  IN     pls_integer,
                         p_l    IN     pls_integer,
                         p_text in out nocopy varchar2
                       )  is
    idx       pls_integer;
    sel_idx   pls_integer;
    ret_idx   pls_integer;
    where_idx pls_integer;
    lock_idx  pls_integer;
    edecl     varchar2(32767);
    etext     varchar2(32767);
    txt       varchar2(32767);
    txtfor    varchar2(8000);
    cols      varchar2(8000);
    hints     varchar2(2000);
    v_obj     varchar2(1000);
    mgn0      varchar2(100) := rpad(TAB,p_l,TAB); -- left margin
    mgn       varchar2(100) := rpad(TAB,p_l+1,TAB);    -- left margin
    extend    boolean;
    dcl       boolean;
    excpt     boolean;
    chk_sys   boolean;
    chk_upd   boolean;
    b         boolean;
    bb        boolean;
    v_set     pls_integer;
    v_for     pls_integer;
    tmp_idx   pls_integer;
    v_cursor  pls_integer := 1;
    --dlevel    pls_integer := 2;
    node      plib.ir_node_t := plib.ir(p_idx);
begin
    skip_attrs := false;
    chk_sys := true;
    chk_upd := true;
    tmp_idx := tmp_sos_idx;
    v_set := plib.ir(node.down).down;
    if plib.ir(v_set).type=plp$parser.INTEGER_ then
      v_for := v_set;
      v_set := plib.ir(node.down).right;
      skip_attrs := null;
    else
      v_set := node.down;
    end if;
    v_set := plib.ir(v_set).right;  -- collection/class
    where_idx:= plib.ir(v_set).right;   -- where clause head
    sel_idx  := plib.ir(where_idx).right; -- select list first entry
    if plib.ir(sel_idx).type=plp$parser.RETURN_ then
      ret_idx := sel_idx;
      excpt := bitand(plib.ir(plib.ir(ret_idx).down).type1,3)=0;
      sel_idx := plib.ir(ret_idx).right; -- select list first entry
    end if;
    tmp_var_idx:=tmp_var_idx+1;
    tmp_sos_idx:=tmp_var_idx;
    hints := collect_hints(p_idx);
    if instr(upper(hints),' PLP_SYSTEM_COLUMNS')>0 then
        hints := rtl.safe_replace(hints,' PLP_SYSTEM_COLUMNS');
        chk_sys := false;
    end if;
    if instr(upper(hints),' PLP_SKIP_CHECK')>0 then
        hints := rtl.safe_replace(hints,' PLP_SKIP_CHECK');
        chk_upd := false;
    end if;
    idx := instr(upper(hints),' OBJECT_ID(');
    if idx>0 then
      lock_idx := instr(hints,')',idx+11);
      if lock_idx>0 then
        v_obj := substr(hints,idx+11,lock_idx-idx-11);
        hints := substr(hints,1,idx-1)||substr(hints,lock_idx+1);
        if not v_obj is null then
          v_obj := ','||upper(v_obj);
        end if;
      end if;
    end if;
    lock_idx := -2;
    idx := construct_cursor_text ( node.text,
                            null,
                            sel_idx,
                            v_set,
                            ret_idx,
                            where_idx,
                            null,
                            null,
                            null,
                            p_l,
                            node.type1,
                            lock_idx,
                            v_cursor,
                            edecl,
                            etext,
                            txt,
                            hints
                          );
  if idx>0 then
    extend:= idx>1;
    if not v_for is null then
      forall_text(v_for,node.down,mgn,txtfor,edecl,etext);
    end if;
    if chk_upd and v_obj is null and node.einfo is not null then
      if plib.ir.exists(node.einfo) and plib.ir(node.einfo).type <> plp$parser.TEXT_ then
        b := expr2plsql(node.einfo,edecl,hints,v_obj,mgn,false);
        v_obj := ','||v_obj;
      end if;
    end if;
    dcl := not edecl is null or excpt;
    if dcl then
        p_text := p_text
           || plib.nn( mgn0||'declare'||NL, edecl)
           || mgn0||'begin'||NL|| etext;
    else
        p_text := p_text||etext;
    end if;
    etext := null; v_set := 0;
    while not sel_idx is null loop
        v_set := v_set+1;
        idx := plib.ir(sel_idx).down;
        b := plib.ir(idx).type=plp$parser.IN_;
        bb:= b;
        if b then
          bb := plib.ir(plib.ir(idx).right).type=plp$parser.IN_;
          idx:= plib.ir(idx).down;
        end if;
        v_for:= 1;
        loop
          edecl := replace(plib.ir(idx).text,'a1.');
          if edecl in ('ID','CLASS_ID','STATE_ID','COLLECTION_ID') then
            plib.plp_error(idx,'UPDATING_NOT_ALLOWED',edecl,is_error=>chk_sys);
          elsif not edecl is null then
            cols := cols ||'.'||edecl;
          end if;
          if bb then
            etext:= etext||', v$'||v_set||'_'||v_for||'=u$'||v_set||'_'||v_for;
          end if;
          idx := plib.ir(idx).right;
          exit when not b or idx is null;
          v_for := v_for+1;
        end loop;
        if not bb then
          etext := etext||', v$'||v_set||'=u$'||v_set;
        end if;
        sel_idx := plib.ir(sel_idx).right;
    end loop;
    if extend then
      plib.plp_warning(p_idx,'DML_QUERY',node.text1,'UPDATE');
      if ret_idx is null then
        idx := 0;
      else
        idx := instr(txt,'$<$return$>$');
      end if;
      if instr(txt,'.SN v$n,')>0 then
        etext := '  v$n=u$n, v$u=u$u'||etext;
      end if;
      if idx>0 then
        txt := substr(txt,1,idx-1)||substr(etext,2)||NL||mgn||TAB||'returning '||substr(txt,idx+12);
      else
        txt := txt||substr(etext,2);
      end if;
    end if;
    txt := txt||';'||NL;
    if chk_upd then
        txt := txt||mgn||'if sql%rowcount>0 then valmgr.check_cached('''||node.text1||cols||''''||v_obj||'); end if;'||NL;
    end if;
    if dcl then
        if excpt then
          txt := txt||mgn0||'exception when TOO_MANY_ROWS then raise rtl.TOO_MANY_ROWS;'||NL;
        end if;
        txt := txt||mgn0||'end;'||NL;
    end if;
    if chk_upd then
      p_text := p_text
             || mgn || 'valmgr.check_update('''||node.text1||cols||''');'||NL;
    end if;
    p_text := p_text|| txtfor||txt;
    db_update := true;
  else
    plib.plp_warning(p_idx,'DML_METADATA',node.text1,'UPDATE');
    p_text := p_text||mgn0||'message.error(''CLS'',''METADATA'');'||NL;
  end if;
    tmp_sos_idx := tmp_idx;
    skip_attrs := false;
end update2plsql;
--
-- @METAGS for2plsql
procedure for2plsql ( p_idx  IN pls_integer,
                      p_l    IN pls_integer,
                      p_text in out nocopy plib.string_tbl_t,
                      l_text in out nocopy varchar2
                    ) is
    idx       pls_integer;
    cnt       pls_integer;
    gcnt      pls_integer;
    lock_idx  pls_integer;
    sos_idx   pls_integer;
    xvar      varchar2(1000);
    edecl     varchar2(32767);
    eprog     varchar2(32767);
    etext     varchar2(32767);
    hints     varchar2(4000);
    sos_text  plib.string_tbl_t;
    mgn0      varchar2(100) := rpad(TAB,p_l,TAB); -- left margin
    mgn       varchar2(100) := rpad(TAB,p_l+1,TAB);    -- left margin
    b         boolean;
    mtd       boolean;
    upd       boolean;
    get       boolean;
begin
    tmp_var_idx:=tmp_var_idx+1;
    tmp_sos_idx:=tmp_var_idx;
    xvar:= plib.ir(p_idx).text;
    idx := plib.ir(plib.ir(p_idx).down).right; -- select sequence
    sos_idx := plib.ir(idx).right; -- SOS index
    hints := collect_hints(p_idx);
    etext := plib.get_comments(idx);
    if not etext is null then
        hints := hints||' '||etext;
    end if;
    etext := null;
    idx := query2plsql(idx,edecl,eprog,etext,lock_idx,true,hints,p_l);
    b := this_chg;
    get := this_get;
    upd := this_upd;
    mtd := this_mtd;
    cnt := obj_count;
    gcnt:= get_count;
    edecl := edecl
          || mgn||'cursor c_obj is'||NL||etext||';'||NL
          || mgn||xvar||TAB||'c_obj%rowtype;'||NL;
    sos2plsql ( sos_idx, p_l+2, edecl, sos_text,tmp_var_idx, lock_idx=0 );      -- sos
    etext := null;
    this_state(mtd,upd,b,get,cnt<obj_count,gcnt<get_count,etext,mgn);
    etext :=  mgn0|| 'declare' || NL
           || edecl
           || mgn0|| 'begin' || NL
           || eprog
           || etext
           || l_text
           || mgn || 'for '||plib.var('c_obj')||' in c_obj loop' || NL
           || mgn || TAB||xvar||' := '||plib.var('c_obj')||';' || NL;
    lib.put_buf(etext,p_text);
    if sos_text.count=0 then
        sos_text(1) := mgn||TAB||'exit;'||NL;
    end if;
    lib.add_buf(sos_text,p_text,true,true);
    l_text := mgn || 'end loop;' || NL;
    if lock_idx>0 then
        db_update := true;
        if lock_idx<999 then
            if lock_idx=1 then
              xvar := 'BUSY';
            else
              xvar := 'WAIT or rtl.RESOURCE_LOCK';
            end if;
            l_text := l_text
                ||mgn0||'exception when rtl.RESOURCE_'||xvar||' then raise rtl.CANNOT_LOCK;'||NL;
        end if;
    end if;
    l_text := l_text || mgn0 || 'end;' || NL;
end for2plsql;
--
-- @METAGS delete2plsql
procedure delete2plsql ( p_idx  IN     pls_integer,
                         p_l    IN     pls_integer,
                         p_text in out nocopy varchar2
                       )  is
    idx       pls_integer;
    where_idx pls_integer;
    lock_idx  pls_integer;
    ret_idx   pls_integer;
    edecl     varchar2(32767);
    etext     varchar2(32767);
    txt       varchar2(32767);
    txtfor    varchar2(8000);
    hints     varchar2(2000);
    mgn0      varchar2(100) := rpad(TAB,p_l,TAB); -- left margin
    mgn       varchar2(100) := rpad(TAB,p_l+1,TAB);    -- left margin
    dcl       boolean;
    excpt     boolean;
    chk_del   boolean;
    v_set     pls_integer;
    v_for     pls_integer;
    tmp_idx   pls_integer;
    v_cursor  pls_integer := 1;
    --dlevel    pls_integer := 2;
    node      plib.ir_node_t := plib.ir(p_idx);
begin
    skip_attrs := false;
    chk_del := true;
    tmp_idx := tmp_sos_idx;
    v_set := plib.ir(node.down).down;
    if plib.ir(v_set).type=plp$parser.INTEGER_ then
      v_for := v_set;
      v_set := plib.ir(node.down).right;
      skip_attrs := null;
    else
      v_set := node.down;
    end if;
    v_set := plib.ir(v_set).right;  -- collection/class
    where_idx:= plib.ir(v_set).right;   -- where clause head
    ret_idx:= plib.ir(where_idx).right; -- return clause head
    if not ret_idx is null then
      excpt := bitand(plib.ir(plib.ir(ret_idx).down).type1,3)=0;
    end if;
    tmp_var_idx:=tmp_var_idx+1;
    tmp_sos_idx:=tmp_var_idx;
    hints := collect_hints(p_idx);
    if instr(upper(hints),' PLP_SKIP_CHECK')>0 then
        hints := rtl.safe_replace(hints,' PLP_SKIP_CHECK');
        chk_del := false;
    end if;
    lock_idx := -3;
    idx := construct_cursor_text ( node.text,
                            null,
                            null,
                            v_set,
                            ret_idx,
                            where_idx,
                            null,
                            null,
                            null,
                            p_l,
                            node.type1,
                            lock_idx,
                            v_cursor,
                            edecl,
                            etext,
                            txt,
                            hints
                          );
  if idx > 0 then
    if idx > 1 then
      plib.plp_warning(p_idx,'DML_QUERY',node.text1,'DELETE');
    end if;
    if not v_for is null then
      forall_text(v_for,node.down,mgn,txtfor,edecl,etext);
    end if;
    txt := txt||';'||NL;
    if chk_del then
        txt := txt||mgn||'if sql%rowcount>0 then valmgr.check_cached('''||node.text1||'''); end if;'||NL;
    end if;
    dcl := not edecl is null or excpt;
    if dcl then
        p_text := p_text
           || plib.nn( mgn0||'declare'||NL, edecl)
           || mgn0||'begin'||NL|| etext;
        if excpt then
          txt := txt||mgn0||'exception when TOO_MANY_ROWS then raise rtl.TOO_MANY_ROWS;'||NL;
        end if;
        txt := txt||mgn0||'end;'||NL;
    else
        p_text := p_text||etext;
    end if;
    if chk_del then
      p_text := p_text
             || mgn || 'valmgr.check_delete('''||node.text1||''');'||NL;
    end if;
    p_text := p_text|| txtfor||txt;
    db_update := true;
  else
    plib.plp_warning(p_idx,'DML_METADATA',node.text1,'DELETE');
    p_text := p_text||mgn0||'message.error(''CLS'',''METADATA'');'||NL;
  end if;
    tmp_sos_idx := tmp_idx;
    skip_attrs := false;
end delete2plsql;
--
-- @METAGS cursor2plsql
procedure cursor2plsql ( p_idx  IN pls_integer,
                         p_l    IN pls_integer,
                         p_decl in out nocopy varchar2,
                         p_text in out nocopy varchar2
                       ) is
    idx       pls_integer;
    cnt       pls_integer;
    v_locks   pls_integer;
    v_cursor  pls_integer;
    xvar      varchar2(2000);
    etext     varchar2(32767);
    mgn       varchar2(100) := rpad(TAB,p_l+1,TAB); -- left margin
    b   boolean;
begin
    idx := plib.ir(p_idx).down; -- select sequence
    cnt := obj_count;
    tmp_var_idx := tmp_var_idx +1; -- PLATFORM-664
    tmp_sos_idx := tmp_var_idx;
    v_cursor := query2plsql(idx,p_decl,p_text,etext,v_locks,true,collect_hints(p_idx,true),p_l);
    if not use_context is null then
      if not p_text is null then
        rtl.debug(NL||p_text,1,false,null);
        plib.plp_error(p_idx,'CURSOR_DECLARATIONS',plib.ir(p_idx).text);
      end if;
    else
      xvar:= plib.get_new_name(p_idx);
      if not xvar like 'tmp$%' then
        b := plib.ir(p_idx).node<>2 or plib.section=method.PUBLIC_SECTION;
        if b then
          p_decl := p_decl||mgn||'cursor '||xvar||' is '||NL||etext||';'||NL;
        else
          plib.plp_warning(p_idx,'NOT_USED', xvar);
        end if;
        if length(xvar) > 23 then
          etext := v_cursor;
          xvar := substr(xvar,1,23-length(etext))||etext;
        end if;
        xvar:= mgn||'procedure Cursor$'||xvar;
        if p_text is null then
          if not plib.g_optim_code or plib.section=method.PUBLIC_SECTION then
            p_decl := p_decl||xvar||';'||NL;
            p_text := xvar||' is begin null; end;'||NL;
            plib.ir(p_idx).node := 1;
          else
            plib.ir(p_idx).node := 2;
          end if;
        else
          p_decl := p_decl||xvar||';'||NL;
          if not b then
            plib.ir(p_idx).node := 1;
          end if;
          p_text := xvar||' is'||NL
           || mgn||'begin'||NL||p_text
           || mgn||'end;'||NL;
        end if;
      end if;
    end if;
    plib.ir(idx).type1 := v_locks;
    plib.ir(idx).text1 := v_cursor;
    if cnt<obj_count then
      plib.ir(idx).node := 0;
    end if;
end cursor2plsql;
--
-- @METAGS for2cursor
procedure for2cursor( p_idx  IN pls_integer,
                      p_l    IN pls_integer,
                      p_text in out nocopy plib.string_tbl_t,
                      l_text in out nocopy varchar2
                    ) is
    idx       pls_integer;
    typ       pls_integer;
    cnt       pls_integer;
    gcnt      pls_integer;
    v_idx     pls_integer;
    lock_idx  pls_integer;
    sos_idx   pls_integer;
    xvar      varchar2(1000);
    xcur      varchar2(1000);
    xproc     varchar2(1000);
    xlock     varchar2(100);
    edecl     varchar2(32767);
    sos_text  plib.string_tbl_t;
    mgn0      varchar2(100) := rpad(TAB,p_l,TAB); -- left margin
    mgn       varchar2(100) := rpad(TAB,p_l+1,TAB);    -- left margin
    b         boolean;
    mtd       boolean;
    upd       boolean;
    get       boolean;
begin
    tmp_var_idx:=tmp_var_idx+1;
    tmp_sos_idx:=tmp_var_idx;
    v_idx := plib.ir(p_idx).down; -- loop var definition
    xvar:= plib.get_new_name(v_idx);   -- loop var name
    idx := plib.ir(v_idx).right;  -- cursor reference
    sos_idx := idx;
    --xcur:= plib.ir(idx).text;   -- cursor name
    idx := plib.ir(idx).type1;  -- cursor definition
    typ := plib.ir(idx).type1;
    b := true;
    if typ = plp$parser.SELECT_ then
      xcur:= plib.get_new_name(idx);   -- cursor name
      cnt := plib.ir(idx).down;
      lock_idx := plib.ir(cnt).type1; -- for update flag
      if plib.ir(idx).node<>2 and plib.ir(cnt).node=0 and instr(xcur,'.')=0 then
        if this_mtd then
          put_get_this(xproc,mgn);
        end if;
        obj_count := obj_count+1;
      end if;
      b := false;
    elsif typ = plp$parser.CURSOR_ then
      b := var2plsql ( plib.ir(sos_idx).down, edecl, xproc, xcur, null, mgn );
      b := true;
      lock_idx := plib.ir(v_idx).down;
      if plib.ir(lock_idx).type = plp$parser.ID_ and not plib.ir(lock_idx).type1 is null then
        lock_idx := plib.ir(lock_idx).type1;
        if plib.ir(lock_idx).type=plp$parser.TYPE_ and plib.ir(lock_idx).type1=plp$parser.SELECT_ then
          lock_idx := plib.ir(plib.ir(lock_idx).down).type1; -- for update flag
          b := false;
        end if;
      end if;
    end if;
    if b then
      lock_idx := 0; -- for update flag
    end if;
    b := this_chg;
    get := this_get;
    upd := this_upd;
    mtd := this_mtd;
    cnt := obj_count;
    gcnt:= get_count;
    sos_idx := plib.ir(sos_idx).right;-- SOS index
    sos2plsql ( sos_idx, p_l+2, edecl, sos_text,tmp_var_idx, lock_idx=0 );
    this_state(mtd,upd,b,get,cnt<obj_count,gcnt<get_count,xproc,mgn);
    if typ=plp$parser.SELECT_ then
      typ := instr(xcur,'.');
      if typ>0 then
        if length(xcur)-typ > 23 then
          plib.plp_warning(idx, 'EXTERNAL_CURSOR', xcur );
        end if;
        xproc := xproc||mgn||substr(xcur,1,typ)||'Cursor$'||substr(xcur,typ+1)||';'||NL;
      elsif plib.ir(idx).node<>2 then
        if length(xcur) > 23 then
          xlock := plib.ir(plib.ir(idx).down).text1;
          xlock := substr(xcur,1,23-length(xlock))||xlock;
        else
          xlock := xcur;
        end if;
        xproc := xproc||mgn||'Cursor$'||xlock||';'||NL;
        xlock := null;
      end if;
      b := not edecl is null;
      if lock_idx > 0 then
        db_update := true;
        if lock_idx<999 then
            if lock_idx=1 then
              xlock := 'BUSY';
            else
              xlock := 'WAIT or rtl.RESOURCE_LOCK';
            end if;
            xlock := mgn0||'exception when rtl.RESOURCE_'||xlock||' then raise rtl.CANNOT_LOCK;'||NL;
            b:=true;
        end if;
      end if;
      if b then
        edecl := plib.nn(mgn0||'declare'||NL,edecl)||mgn0||'begin'||NL;
      end if;
      edecl := edecl||xproc||l_text
            || mgn||'for '||xvar||' in '||xcur||' loop'|| NL;
      l_text:= mgn||'end loop;'||NL||xlock;
      if b then
          l_text := l_text||mgn0||'end;'||NL;
      end if;
    elsif typ = plp$parser.CURSOR_ then
      edecl := mgn0||'declare'||NL
            || mgn||xvar||TAB||plsql_type(plib.ir(v_idx).down)||';'||NL
            || edecl
            || mgn0||'begin'||NL
            || xproc||l_text
            || mgn ||'loop fetch '||xcur||' into '||xvar||'; exit when '||xcur||'%NOTFOUND;'||NL;
      l_text := mgn||'end loop;'||NL||mgn0||'end;'||NL;
    end if;
    lib.put_buf(edecl,p_text);
    if sos_text.count=0 then
        sos_text(1) := mgn||TAB||'exit;'||NL;
    end if;
    lib.add_buf(sos_text,p_text,true,true);
end for2cursor;
--
-- @METAGS sos2plsql
procedure sos2plsql ( p_idx  IN     pls_integer,
                      p_l    IN     pls_integer,
                      p_decl in out nocopy varchar2,
                      p_text in out nocopy plib.string_tbl_t,
                      t_idx  IN     pls_integer default NULL,
                      p_lock IN     boolean default TRUE
                    ) is
    idx    pls_integer := plib.ir(p_idx).down;
    idx1   pls_integer;
    i      pls_integer;
    j      pls_integer;
    typ    pls_integer;
    cnt    pls_integer;
    typ1   pls_integer;
    txt    varchar2(32767);
    mgn    varchar2(100) := rpad(TAB,p_l,TAB);    -- left margin
    eprog  varchar2(32767);
    etext  varchar2(32767);
    etext1 varchar2(32767);
    b      boolean;
    upd    boolean;
    mtd    boolean;
    chg    boolean;
    get    boolean;
    v_add  boolean;
    v_skip boolean;
    v_sos  boolean := sos_method;
    vsos   boolean := sosmethod;
    v_chk  boolean default TRUE;
    lfor   boolean default TRUE;
    origin boolean default TRUE;
    contin boolean;
    prev_line pls_integer := 0;
    dlevel  pls_integer;
    tmp_idx pls_integer := nvl(t_idx,tmp_var_idx);
    return_changed_data boolean;
begin
    if this_add then
        v_add := true;
    else
        v_add := false;
        this_upd := false;
        this_mtd := false;
        this_chg := false;
        this_get := false;
    end if;
    this_add := false;
    chk_return := false;
    tmp_sos_idx:= tmp_idx;
--    rtl.debug( 'sos2plsql: start at '||p_idx, dlevel );
    rtl.get_debug_info(dlevel,i,etext,j);
    if dlevel >= 1000 then
        i := plib.ir(idx).line;
        if i > 0 then
            j := plib.find_left(idx, plp$parser.FUNCTION_);
            if j is null then
                etext := null;
            else
                etext := plib.ir(j).text;
            end if;
            lib.put_buf(mgn||'rtl.debug('''||plib.g_class_id||'.'||plib.g_method_sname||'.'||plib.section||'.'||etext||'.'||i||''',0,true);'||NL,p_text);
        end if;
    end if;
    while not idx is NULL loop
      typ := plib.ir(idx).type;
      txt := plib.ir(idx).text;
      idx1:= plib.ir(idx).right;
      b := plib.plp$define;
      --chk_return := false;
      if typ = plp$parser.PRAGMA_ then
        if use_counters then inc_counter(typ+2000); end if;
        plib.use_pragma(idx);
        if this_attr then
            plib.g_optim_this := true;
        end if;
        rtl.get_debug_info(dlevel,i,etext,j);
        if b then
            txt := plib.pragma_text(idx);
            if txt=plib.GET_PRAGMA then
                txt := null;
                if is_method and v_chk then
                  if plib.g_optim_this then
                    if cache_this then
                      this_var := true;
                      this_upd := false;
                      call_obj := cache_obj;
                      put_get_this(txt,mgn);
                    elsif cache_obj and this_obj then
                        txt := txt||mgn||obj_select;
                        this_get := true;
                        this_chg := false;
                        chg_count:= chg_count + 1;
                    end if;
                  else
                    plib.plp_warning(idx,'CACHE_THIS',plib.GET_PRAGMA);
                  end if;
                end if;
            elsif txt=plib.THIS_PRAGMA then
                txt := null;
                if is_method and cache_this and v_chk then
                  if plib.g_optim_this then
                    this_var := true;
                    this_mtd := false;
                    put_set_this(txt,mgn);
                  else
                    plib.plp_warning(idx,'CACHE_THIS',plib.THIS_PRAGMA);
                  end if;
                end if;
            elsif txt=plib.INITIALIZE_PRAGMA then
                init_proc := plib.ir(idx).type1;
                txt := null;
            end if;
            if txt is NULL then
                origin := TRUE;
            else
              lib.put_buf(txt,p_text);
              if instr(txt,plib.SECTION_COMMENT) = 1 then
                origin := TRUE;
              end if;
              chk_return := false;
            end if;
        elsif plib.plp$define then
            v_chk := v_chk and not idx1 is null;
        end if;
      elsif b then
       v_skip := true;
       if v_chk then
        v_skip:= null;
        tmp_expr_idx := null;
        chk_return := false;
        i := plib.ir(idx).down;
        if (origin or plib.ir(idx).line - prev_line != 1) and typ != plp$parser.PRAGMA_ then
            etext := plib.origin_text(idx);
            if etext is null then
                origin := TRUE;
            else
                lib.put_buf(etext,p_text);
                origin := FALSE;
            end if;
        end if;
        if typ = plp$parser.ASSIGN_ then
            declare
                l_idx   pls_integer;
                r_idx   pls_integer;
                node    pls_integer;
                tmpprog varchar2(2000);
            begin
                if use_counters then inc_counter(typ+2000); end if;
                etext := NULL;
                l_idx := i;
                r_idx := plib.ir(i).right;
                i := plib.ir(r_idx).right;
                upd := true;
                if i is null then
                  if plib.ir(l_idx).type=plp$parser.IN_ then
                    l_idx := plib.ir(l_idx).down;
                    r_idx := plib.ir(r_idx).down;
                    while not (r_idx is null or l_idx is null) loop
                      etext := null;
                      b := expr2plsql( r_idx, p_decl, eprog, etext1, mgn );
                      b := var2plsql ( l_idx, p_decl, eprog, etext, etext1, mgn );
                      lib.put_buf(eprog||mgn||etext||';'||NL,p_text);
                      l_idx := plib.ir(l_idx).right;
                      r_idx := plib.ir(r_idx).right;
                    end loop;
                    origin := true;
                    upd := false;
                  elsif plib.ir(idx).type1=plp$parser.COLLECTION_ then  -- collection conversion
                    declare
                      v_expr  plib.expr_info_t;
                      v_pref  varchar2(100);
                      v_suff  varchar2(10);
                    begin
                      v_pref := null;
                      v_suff := null;
                      get := plib.g_parse_java and plib.pop_expr_info(r_idx,v_expr);
                      b := expr2plsql( r_idx, p_decl, eprog, etext1, mgn );
                      if get then
                        if v_expr.conv_in > 0 then
                          v_pref := plib.ir(v_expr.conv_in).text||'(';
                          v_suff := ')';
                        end if;
                        plib.put_expr_info(r_idx,v_expr);
                      end if;
                      b := var2plsql ( l_idx, p_decl, eprog, etext, null, mgn );
                      if not nvl(is_variable(r_idx),false) then
                        txt := plsql_type(r_idx,true,false);
                        if tmpvar(tmp_idx,'ARRAY',txt,-1) then
                          p_decl := mgn||lasttmp||TAB||txt||';'||NL||p_decl;
                        end if;
                        eprog := eprog||mgn||lasttmp||' := '||etext1||';'||NL;
                        etext1:= lasttmp;
                      end if;
                      txt := plib.ir(idx).text1;
                      j := instr(txt,'.');
                      if j > 0 then
                        txt := substr(txt,j+1);
                      else
                        txt := null;
                      end if;
                      if txt is null then
                        txt := 'pls_integer';
                      else
                        txt := plsql_type(txt);
                      end if;
                      if tmpvar(tmp_idx,'LOOP',txt,-1) then
                        p_decl := mgn||lasttmp||TAB||txt||';'||NL||p_decl;
                      end if;
                      --PLTFM-3896
                      if plib.ir(plib.ir(plib.ir(plib.ir(l_idx).type1).down).right).node = 1 then
                          eprog := eprog||mgn||etext||'.delete; '||etext||'.extend('||etext1||'.count); '||lasttmp||':='||etext1||'.first;'||NL;
                      else
                          eprog := eprog||mgn||etext||'.delete; '||lasttmp||':='||etext1||'.first;'||NL;
                      end if;
                      eprog := eprog||mgn||'while not '||lasttmp||' is null loop'||NL;
                      etext := TAB||etext||'('||lasttmp||') := '||v_pref||etext1||'('||lasttmp||')'||v_suff||'; '
                            ||lasttmp||' := '||etext1||'.next('||lasttmp||');'||NL
                            || mgn||'end loop';
                    end;
                  else
                      if is_method then
                        txt := rtl.bool_char(this_upd)||rtl.bool_char(this_mtd)||rtl.bool_char(this_chg)||rtl.bool_char(this_get);
                      end if;
                      b := expr2plsql( r_idx, p_decl, eprog, etext1, mgn );
                      b := true;
                      if is_method then
                        if not (eprog is null and txt=rtl.bool_char(this_upd)||rtl.bool_char(this_mtd)||rtl.bool_char(this_chg)||rtl.bool_char(this_get)) then
                          b := null;
                        end if;
                      end if;
                      b := var2plsql ( l_idx, p_decl, eprog, etext, etext1, mgn, true, false, b );
                  end if;
                else
                    b := FALSE;
                    j := plib.ir(r_idx).down;
                    typ1:= plib.ir(r_idx).type;
                    node:= plib.ir(r_idx).node;
                    plib.ir(r_idx).node := 0;
                    if expr2plsql( r_idx, p_decl, eprog, etext1, mgn ) then
                        b := TRUE;
                        txt := etext1;
                    elsif j is null then
                        txt := etext1;
                    elsif is_variable(r_idx) then
                        txt := etext1;
                    else
                        txt := plsql_type(l_idx,true,false);
                        if tmpvar(tmp_idx,'ASSIGN',txt,tmp_expr_idx) then
                            p_decl := mgn||lasttmp||TAB||txt||';'||NL||p_decl;
                        end if;
                        tmp_expr_idx := nvl(tmp_expr_idx,0)+1;
                        txt:= lasttmp;
                        if txt<>etext1 then
                            eprog := eprog||mgn||txt||' := '||etext1||';'||NL;
                            etext1:= txt;
                        end if;
                    end if;
                    if not j is null then
                      declare
                        rvalue  plib.plp_class_t;
                      begin
                        plib.expr_class(r_idx,rvalue);
                        plib.ir(j).text  := txt;
                        plib.ir(j).text1 := nvl(rvalue.class_id,rvalue.base_id);
                        plib.ir(j).type  := plp$parser.TEXT_;
                        typ1 := rvalue.base_type;
                        if b then
                            typ1 := -typ1;
                        end if;
                        plib.ir(j).type1 := typ1;
                        plib.ir(r_idx).type1 := typ1;
                        plib.ir(r_idx).text  := null;
                        plib.ir(r_idx).text1 := nvl(rvalue.class_id,rvalue.base_id);
                        plib.ir(r_idx).type  := plp$parser.VARMETH_;
                        plib.delete_children(j);
                        plib.delete_branch(plib.ir(j).right);
                      end;
                    end if;
                    if node<0 and node>-10 then
                        plib.ir(r_idx).node := node;
                        b := expr2plsql( r_idx, p_decl, tmpprog, etext1, mgn );
                        eprog:=eprog||tmpprog;
                    end if;
                    b := var2plsql ( l_idx, p_decl, eprog, etext, etext1, mgn );
                    l_idx := i;
                    while not l_idx is null loop
                        etext := etext||'; ';
                        node := plib.ir(l_idx).node;
                        plib.ir(l_idx).node:= node mod 100;
                        node := trunc(node/100);
                        if node<0 then
                            plib.ir(r_idx).node := node;
                            b := expr2plsql( r_idx, p_decl, tmpprog, etext1, mgn );
                            eprog:=eprog||tmpprog;
                        else
                            etext1 := txt;
                        end if;
                        b:=var2plsql( l_idx, p_decl, eprog, etext, etext1, mgn );
                        l_idx := plib.ir(l_idx).right;
                    end loop;
                end if;
                if upd then
                  lib.put_buf(eprog||mgn||etext||';'||NL,p_text);
                  origin := not eprog is NULL;
                end if;
            end;
        elsif typ = plp$parser.IF_ then
          declare
            ch  boolean;
            gt  boolean;
            mt  boolean;
            c   boolean;
            m   boolean;
            bb  boolean;
            ii  pls_integer;
            u   pls_integer;
            n   pls_integer;
            v_if boolean;
            v_text plib.string_tbl_t;
          begin
            if use_counters then inc_counter(typ+2000); end if;
            j := 0; u := 0; n := 0;
            v_if := txt is null;
            if v_if then
              idx1 := null;
            elsif plib.ir(idx).type1 is null then
              idx1 := 1;
            else
              idx1 := length(txt) + 3; --'plp$case = '
            end if;
            if is_method then
              upd := this_upd;
              mtd := this_mtd; m := mtd; mt := false;
              chg := this_chg; c := chg; ch := false;
              get := this_get; gt:= get;
            end if;
            this_add := is_method;
            sosmethod := false;
            while not i is NULL loop
                typ1 := plib.ir(i).type;
                ii := plib.ir(i).down;
                if is_method then
                  this_upd := upd;
                  this_mtd := mtd;
                  this_chg := chg;
                  this_get := get;
                end if;
                b := FALSE;
                etext1 := null;
                if typ1 = plp$parser.ELSIF_ then
                  if plib.plp$define then
                    tmp_expr_idx := null;
                    bb:= expr2plsql(ii, p_decl, eprog, etext, mgn);
                    b := bb and plib.g_optim_code;
                    if bb then
                      typ := get_bool_const(etext,false);
                    end if;
                    if b and typ <= 0 then
                        b := FALSE;
                        ii:= null;
                    else
                        b := b and typ > 0;
                        if b then
                            if j>0 then
                                etext1 := mgn||'else'||NL;
                            end if;
                        elsif j=0 then
                            if is_method then
                              upd := this_upd;
                              mtd := this_mtd; m := mtd;
                              chg := this_chg; c := chg;
                              get := this_get; gt:= get;
                            end if;
                            if v_if then
                              etext1 := eprog||mgn||'if '||etext||' then'||NL;
                            elsif idx1 = 1 then
                              etext1 := eprog||mgn||'case when '||etext||' then'||NL;
                            else
                              if bb then
                                etext := set_bool_const(typ);
                              else
                                etext := substr(etext,idx1);
                              end if;
                              etext1 := eprog||mgn||'case '||txt||' when '||etext||' then'||NL;
                            end if;
                            j := 1;
                        else
                          if is_method then
                            bb := false;
                            if upd then
                              if this_mtd then
                                put_get_this(etext1,mgn);
                                bb := true;
                              end if;
                            elsif this_upd then
                              put_set_this(etext1,mgn);
                              bb := true;
                            end if;
                            if bb then
                              if tmpvar(tmp_idx,'IF','boolean',-1) then
                                p_decl := mgn||lasttmp||TAB||'boolean;'||NL||p_decl;
                              end if;
                              if etext<>lasttmp then
                                eprog := eprog||mgn||lasttmp||' := '||etext||';'||NL;
                                etext := lasttmp;
                              end if;
                              eprog := eprog||etext1;
                            end if;
                            mtd := this_mtd; m := m or mtd;
                            chg := this_chg; c := c or chg;
                            get := this_get; gt:=gt or get;
                          end if;
                            if eprog is NULL then
                              if v_if then
                                etext1 := mgn||'elsif '||etext||' then'||NL;
                              else
                                etext1 := mgn||'when '||substr(etext,idx1)||' then'||NL;
                              end if;
                            else
                              if v_if then
                                etext1 := mgn||'else'||NL||eprog||mgn||'if '||etext||' then'||NL;
                              else
                                v_if := true;
                                etext1 := mgn||'else'||NL||eprog||mgn||'if '||etext||' then'||NL;
                              end if;
                                j := j + 1;
                            end if;
                        end if;
                        ii := plib.ir(ii).right;
                    end if;
                  else
                    ii := plib.ir(ii).right;
                  end if;
                elsif typ1 = plp$parser.ELSE_ then
                  if plib.plp$define and j>0 then
                    etext1 := mgn||'else'||NL;
                    v_if := null;
                  end if;
                else
                    plib.plp_error(i, 'IR_UNEXPECTED', 'sos2plsql', plib.type_name(typ1), i);
                end if;
                if not ii is null then
                    bb := not etext1 is null;
                    if bb then
                      lib.put_buf(etext1,v_text);
                    else
                      bb := j>0;
                    end if;
                    typ1 := v_text.count;
                    sos2plsql(ii, p_l+1, p_decl, v_text, tmp_idx,p_lock);
                    if v_text.count=typ1 then
                      lib.put_buf(mgn||TAB||NULL_STMT||NL,v_text);
                    elsif is_method and not chk_return then
                      if bb then
                        etext1 := null;
                        if upd then
                          if this_mtd then
                            put_get_this(etext1,mgn||TAB);
                          end if;
                        elsif mtd then
                          if this_upd then
                            put_set_this(etext1,mgn||TAB);
                          end if;
                        elsif this_upd then
                          etext1 := mgn||TAB||'--* '||var_this||NL;
                          u := u+1;
                        end if;
                        if not etext1 is null then
                          lib.put_buf(etext1,v_text);
                        end if;
                        n := n+1;
                        mt := mt or this_mtd;
                        ch := ch or this_chg;
                        gt := gt or this_get;
                      else
                        upd := this_upd;
                        mtd := this_mtd; m := mtd;
                        chg := this_chg; c := chg;
                        get := this_get; gt:= get;
                      end if;
                    end if;
                    chk_return := false;
                end if;
                exit when b;
                i := plib.ir(i).right;
            end loop;
            if j>0 then
              etext1 := null;
              if idx1 is not null then
                j := j-1;
              end if;
              for jj in 1..j loop
                etext1 := etext1||mgn||'end if;'||NL;
              end loop;
              if idx1 is not null then
                if not v_if then
                  etext1 := etext1||mgn||'else null;'||NL;
                end if;
                etext1 := etext1||mgn||'end case;'||NL;
              end if;
              lib.put_buf(etext1,v_text);
            end if;
            this_add := false;
            sosmethod:= vsos;
            if is_method then
              if v_if is not null then
                mt := mt or m;
                ch := ch or c;
              end if;
              if u>0 then
                if mt or is_validator and n>u then
                  lib.replace_buf(v_text,'--* '||var_this||NL,set_this);
                  set_count := set_count+1;
                else
                  lib.replace_buf(v_text,mgn||TAB||'--* '||var_this||NL);
                  upd := true;
                end if;
              end if;
              this_upd := upd;
              this_mtd := mt;
              this_chg := ch;
              this_get := gt;
            end if;
            if v_text.count=0 then
              lib.put_buf(mgn||NULL_STMT||NL,p_text);
            else
              lib.add_buf(v_text,p_text,true,true);
            end if;
            idx1:= plib.ir(idx).right;
          end;
        elsif typ in (plp$parser.RTL_,plp$parser.VARMETH_) then
            if use_counters then inc_counter(typ+2000); end if;
            eprog := NULL;
            etext := NULL;
            b:=var2plsql( idx, p_decl, eprog, etext, null, mgn );
            origin:= not eprog is NULL;
            eprog := eprog||mgn;
            typ1 := abs(plib.ir(idx).type1);
            if typ1>1 then
                plib.plp_warning(idx, 'RESULT_LOST' );
                etext1 := plsql_type(idx,true,false);
                if tmpvar(tmp_idx,'RESULT',etext1,-1) then
                    p_decl := mgn||lasttmp||TAB||etext1||';'||NL||p_decl;
                end if;
                if etext=lasttmp then
                    etext := NULL_CONST;
                else
                    eprog := eprog||lasttmp||' := ';
                end if;
            elsif etext like 'MESSAGE.%' and etext<>'MESSAGE.CLEAR' then
                typ := plp$parser.RAISE_;
                v_chk := not plib.g_optim_code;
                chk_return := plib.g_optim_this;
                chk_sav := false;
            end if;
            lib.put_buf(eprog||etext||';'||NL,p_text);
        elsif typ = plp$parser.RETURN_ then
            if use_counters then inc_counter(typ+2000); end if;
            etext := NULL;
            v_chk := v_sos and is_validator;
            chk_sav := false;
            if v_sos and this_upd then
                chk_sav := true;
                sav_upd := this_upd;
                sav_mtd := this_mtd;
                sav_chg := this_chg;
                if v_chk and this_ins then
                  if lock_this then
                    --etext := mgn||'if not '||new_this||' is null then'||NL;
                    put_set_this(etext,mgn||TAB);
                    --etext := etext||mgn||'end if;'||NL;
                  end if;
                else
                    put_set_this(etext,mgn);
                end if;
--                this_upd := true;
                origin:= TRUE;
            elsif is_method and this_mtd then
                etext := mgn||'--$ '||var_this||NL;
            end if;
            --PLATFORM-8599
            if plib.g_src_merge  and over_count>0 and not upper(nvl(substr(rtl.setting('PLP_EXTENSION_SYS_SWITCH'),1,1),'N')) in ('Y','1') then
                if is_base_func then
                    if this_upd then
                       put_set_this(etext,mgn);
                    end if;
                    this_mtd := true;
                end if;
            end if;
            b := TRUE;
            if v_sos then
                if v_chk then
                    b := FALSE;
                    if this_ins then
                        origin:= TRUE;
                        etext := mgn||'if '||new_this||' is null then '
                              || var_chk||':=true; '||var_ins||':='||var_this||'; '||new_this||':='||var_collect||';'||NL
                              || mgn||'else '||var_chk||':=false;'||NL||etext||mgn||'end if;'||NL;
                    elsif this_attr and plib.g_method_log>1 and (plib.g_method_log mod 2)=0 then
                      if plib.g_method_log>2 then
                        etext := etext||mgn||'rtl.writelog(''L'',';
                      else
                        etext := etext||mgn||'rtl.write_log(''L'',';
                      end if;
                      etext := etext||new_this||'||''.''||'
                          ||var_class||'||''.FINISH'',null,'''||plib.g_method_id||''');'||NL;
                      origin := TRUE;
                    end if;
                    etext := etext||mgn||'return;'||NL;
                else
                    if this_del then
                        if not plib.g_method_arch then
                          eprog := ',key_=>0);';
                        elsif not plib.g_prt_actual then
                          if chk_key then
                            eprog := ',key_=>nvl('||var_key||',-1));';
                          else
                            eprog := ',key_=>-1);';
                          end if;
                        else
                          eprog := ');';
                        end if;
                        etext := etext
                           ||mgn||'if '||var_class||' is NULL then'||NL
                           ||mgn||TAB||self_interface||'.delete('||new_this||','||var_obj_class||eprog||NL;
                        if set_rules then
                          etext := etext||mgn||TAB
                           ||'rules.set_object_rights('||var_obj_class||','||new_this||',''DELETE'');'||NL;
                        end if;
                        etext := etext||mgn||'end if;'||NL;
                        origin:= TRUE;
                    elsif this_trig then
                        etext := etext||mgn||'valmgr.set_quals(attrs_list);'||NL;
                        origin:= TRUE;
                    elsif this_ins and set_count = 0 then
                        put_set_this(etext,mgn);
                        set_count := 0;
                    end if;
                    if plib.g_method_log>1 and (plib.g_method_log mod 2)=0 and not this_attr then
                      if plib.g_method_log>2 then
                        etext := etext||mgn||'rtl.writelog(''L'',';
                      else
                        etext := etext||mgn||'rtl.write_log(''L'',';
                      end if;
                      etext := etext||new_this||'||''.''||'
                          ||var_class||'||''.FINISH'',null,'''||plib.g_method_id||''');'||NL;
                      origin := TRUE;
                    end if;
                    if this_new then
                        b := FALSE;
                        if set_rules then
                            etext := etext
                                ||mgn||'rules.set_object_rights('||var_obj_class||','||new_this||');'||NL;
                            origin := TRUE;
                        end if;
                        if this_ins then
                            etext := etext||mgn||var_chk||' := false;'||NL;
                            origin:= TRUE;
                        end if;
                        etext := etext||mgn||'return '||new_this||';'||NL;
                    end if;
                end if;
            end if;
            v_chk := not plib.g_optim_code;
            if b then
                if i is NULL then
                    etext := etext||mgn||'return;'||NL;
                else
                    return_changed_data := this_upd;
                    b:=expr2plsql(i, p_decl, eprog, etext1, mgn );
                    return_changed_data := this_upd and not return_changed_data;
                    etext:= etext||eprog;
                    typ1 := plib.ir(idx).type1;
                    if not typ1 is null then
                        eprog  := plsql_type(typ1);
                        if tmpvar(tmp_idx,'RESULT',eprog,-1) then
                            p_decl := mgn||lasttmp||TAB||eprog||';'||NL||p_decl;
                        end if;
                        eprog := lasttmp;
                        if eprog <> etext1 then
                          etext := etext||mgn||eprog||' := '||etext1||';'||NL;
                        end if;
                        etext1:= eprog;
                    end if;
                    if plib.ir(idx).text is null then
                        if return_changed_data then -- обработка  если возращаемая функция изменила данные
                            eprog  := plsql_type(plib.ir(idx).down,true,false);
                            if tmpvar(tmp_idx,'RESULT',eprog,-1) then
                                p_decl := mgn||lasttmp||TAB||eprog||';'||NL;
                            end if;
                            eprog := lasttmp;
                            if eprog <> etext1 then
                              etext1 := eprog||' := '||etext1||';'||NL;
                            end if;
                            put_set_this(etext1, mgn);
                            etext1:= etext1||mgn||'return '||eprog;
                        else
                            etext1:= 'return '||etext1;
                        end if;
                    else
                        etext1:= plib.ir(idx).text||'('||etext1||')';
                        v_chk := true;
                    end if;
                    etext := etext||mgn||etext1||';'||NL;
                    origin:= origin or not eprog is NULL;
                end if;
            end if;
            lib.put_buf(etext,p_text);
            chk_return := plib.g_optim_this;
        elsif typ = plp$parser.ID_ then
            if use_counters then inc_counter(typ+2000); end if;
            eprog := NULL;
            etext := NULL;
            b:=var2plsql( idx, p_decl, eprog, etext, null, mgn );
            origin:= not eprog is NULL;
            eprog := eprog||mgn;
            typ1 := plib.ir(idx).type1;
            if not typ1 is null and plib.ir(typ1).type!=plp$parser.INVALID_ then
                plib.plp_warning(idx, 'RESULT_LOST' );
                etext1 := plsql_type(idx,true,false);
                if tmpvar(tmp_idx,'RESULT',etext1,-1) then
                    p_decl := mgn||lasttmp||TAB||etext1||';'||NL||p_decl;
                end if;
                if etext=lasttmp then
                    etext := NULL_CONST;
                else
                    eprog := eprog||lasttmp||' := ';
                end if;
            end if;
            lib.put_buf(eprog||etext||';'||NL,p_text);
        elsif typ = plp$parser.BLOCK_ then
            if use_counters then inc_counter(typ+2000); end if;
            block2plsql(idx,p_l,p_decl,p_text,tmp_idx,p_lock);
            sosmethod:= vsos;
        elsif typ = plp$parser.METHOD_ then
            if use_counters then inc_counter(typ+2000); end if;
            eprog := NULL;
            etext := NULL;
            b:=var2plsql( idx, p_decl, eprog, etext, null, mgn );
            origin:= not eprog is NULL;
            eprog := eprog||mgn;
            typ1 := plib.ir(idx).type1;
            if not typ1 is null then
              if plib.ir(idx).type = plp$parser.ID_ then
                b := plib.ir(typ1).type!=plp$parser.INVALID_ ;
              else
                lib.desc_method(plib.ir(idx).text1, method_info);
                b := not method_info.result_id is NULL;
              end if;
              if b then
                plib.plp_warning(idx, 'RESULT_LOST' );
                etext1 := plsql_type(idx,true,false);
                if tmpvar(tmp_idx,'RESULT',etext1,-1) then
                    p_decl := mgn||lasttmp||TAB||etext1||';'||NL||p_decl;
                end if;
                if etext=lasttmp then
                    etext := NULL_CONST;
                else
                    eprog := eprog||lasttmp||' := ';
                end if;
              end if;
            end if;
            lib.put_buf(eprog||etext||';'||NL,p_text);
        elsif typ = plp$parser.NULL_ then
            if use_counters then inc_counter(typ+2000); end if;
            lib.put_buf(mgn||NULL_STMT||NL,p_text);
        elsif typ = plp$parser.FOR_ then
            typ1:=plib.ir(idx).type1;
            tmp_loop := tmp_loop+1;
            contin := tmp_continue;
            tmp_continue := false;
            sosmethod := false;
            if lfor then
                etext1 := NULL;
            end if;
            if typ1 = plp$parser.FOR_ then
              declare
                v_text plib.string_tbl_t;
              begin
                if use_counters then inc_counter(typ1+2000); end if;
                i := plib.ir(i).right;
                j := plib.ir(i).down;
                b:=expr2plsql(j, p_decl, eprog, etext, mgn );
                etext1:=etext1||mgn||'for '||txt||' in '||plib.ir(idx).text1||' '||etext;
                j:=plib.ir(j).right;
                txt := eprog;
                b:=expr2plsql(j, p_decl, eprog, etext, mgn );
                etext1 := etext1||'..'||etext||' loop'||NL;
                txt := txt||eprog;
                j:=plib.ir(j).right;
                get := true;
                if j is null then
                    b:=false;
                else
                    tmp_expr_idx := null;
                    b:=expr2plsql(j, p_decl, eprog, etext, mgn ) and plib.g_optim_code;
                    if b then
                      typ := get_bool_const(etext,false);
                    end if;
                    if b and typ is not null then
                      b := typ <= 0;
                      if b then
                        get := false;
                        etext1 := etext1||mgn||'exit;'||NL;
                      end if;
                    else
                      b := true;
                      etext1 := etext1||eprog||mgn||'if '||etext||' then'||NL;
                      if not eprog is null then
                        etext1 := txt||etext1;
                        txt := null;
                      end if;
                    end if;
                end if;
                if get then
                    upd := this_upd;
                    mtd := this_mtd;
                    chg := this_chg;
                    get := this_get;
                    cnt := obj_count;
                    j := get_count;
                    sos2plsql( plib.ir(i).right, p_l+1, p_decl, v_text,tmp_idx,p_lock );
                    this_state(mtd,upd,chg,get,cnt<obj_count,j<get_count,txt,mgn);
                    if txt is null then
                      lib.put_buf(etext1,p_text);
                    elsif b and not eprog is null then
                      lib.put_buf(etext1||txt,p_text);
                    else
                      lib.put_buf(txt||etext1,p_text);
                    end if;
                    if v_text.count>0 then
                      etext1 := null;
                      lib.add_buf(v_text,p_text,true,true);
                    else
                      etext1 := mgn||TAB||'exit;'||NL;
                    end if;
                    if b then
                      etext1 := etext1||mgn||'end if;'||NL;
                    end if;
                else
                    etext1 := txt||etext1;
                end if;
                etext1 := etext1||mgn||'end loop;'||NL;
              end;
            elsif typ1 = plp$parser.IN_ then
                if use_counters then inc_counter(typ1+2000); end if;
                iterator2plsql( idx, p_l, p_text,etext1 ); -- start with ID
                tmp_sos_idx := tmp_idx;
            elsif typ1 = plp$parser.SELECT_ then
                if use_counters then inc_counter(typ1+2000); end if;
                for2plsql( idx, p_l, p_text, etext1 );
                tmp_sos_idx := tmp_idx;
            elsif typ1 = plp$parser.CURSOR_ then
                if use_counters then inc_counter(typ1+2000); end if;
                for2cursor( idx, p_l, p_text, etext1 );
                tmp_sos_idx := tmp_idx;
            end if;
            if tmp_continue then
              i := instr(etext1,'end loop;'||NL,-1);
              if i>0 then
                etext1 := substr(etext1,1,i-1)||'<<end$loop$'||tmp_loop||'>>null;'||substr(etext1,i);
              end if;
            end if;
            lib.put_buf(etext1,p_text);
            sosmethod:= vsos;
            tmp_loop := tmp_loop-1;
            chk_return := false;
            tmp_continue := contin;
            origin:= TRUE;
            lfor  := TRUE;
        elsif typ = plp$parser.LOCATE_ then
            if use_counters then inc_counter(typ+2000); end if;
            etext1:= null;
            etext := locate2plsql(idx, p_l, p_decl, etext1);
            lib.put_buf(etext1,p_text);
--            tmp_sos_idx := tmp_idx;
            origin := TRUE;
        elsif typ=plp$parser.SELECT_ then
            if use_counters then inc_counter(typ+3000); end if;
            etext := NULL;
            select2plsql(idx, p_l, etext);
            lib.put_buf(etext,p_text);
            origin := TRUE;
        elsif typ=plp$parser.UNKNOWN_ then
            eprog := NULL;
            etext := NULL;
            b:=var2plsql( idx, p_decl, eprog, etext, null, mgn );
            origin := not eprog is NULL;
            typ := plib.ir(idx).type1;
            if typ=-4 then
              if use_counters then inc_counter(plp$parser.CURSOR_+3000); end if;
              etext := 'close '||etext;
            elsif typ in (-2,-3) then
              if use_counters then inc_counter(plp$parser.CURSOR_+3000); end if;
              b := typ=-3;
              typ := plib.last_child(idx);
              txt := plib.ir(typ).text1;
              typ := substr(txt,instr(txt,'.')+1);
              if typ < 0  then -- static
                typ := -typ;
              end if;
              typ1:= null;
              i := plib.ir(typ).down;
              if b then
                typ1 := i;
                i := plib.ir(i).right;
              end if;
              etext1:= etext;
              etext := null;
              loop
                b:=var2plsql( i, p_decl, eprog, etext, null, mgn );
                i:=plib.ir(i).right;
                exit when i is null;
                etext := etext||',';
              end loop;
              etext := 'fetch '||etext1||case when bitand(plib.ir(typ).type1,2)=2 then ' bulk collect into ' else ' into ' end||etext;
              if not typ1 is null then
                b := expr2plsql(typ1,p_decl,etext1,txt,mgn);
                eprog := eprog||etext1;
                etext := etext||' limit '||txt;
              end if;
            elsif typ < 0 then
              if use_counters then inc_counter(plp$parser.CURSOR_+3000); end if;
              b := typ=-1;
              if b then
                typ := plib.last_child(idx);
                txt := plib.ir(typ).text1;
                typ := substr(txt,instr(txt,'.')+1);
                if typ < 0 then -- static
                  typ := -typ;
                  b := null;
                else
                  cursor2plsql(typ,p_l-1,etext1,eprog);
                  p_decl:= etext1||p_decl;
                end if;
              else
                typ := -typ;
                b := plib.ir(typ).node=2; -- empty procedure
              end if;
              txt := plib.get_new_name(typ);
              i := plib.ir(typ).down;
              j := plib.ir(i).text1;
              etext1:= plib.get_cursor(j);
              if b is null or etext1 is null then
                j := instr(txt,'.');
                if not b is null or j=0 and etext1 is null then
                  plib.plp_error(idx, 'EXTERNAL_CURSOR', txt );
                elsif not etext1 is null then
                  etext1:= null;
                  b := plib.ir(typ).node=2;
                elsif j>0 then
                  etext1:= substr(txt,1,j);
                  txt := substr(txt,j+1);
                end if;
                etext := 'open '||etext;
              else
                etext := 'open '||etext||' for '||NL||etext1;
                etext1:= null;
              end if;
              if b then null; else
                if plib.ir(i).node=0 then
                  if this_mtd then
                    put_get_this(eprog,mgn);
                  end if;
                  obj_count := obj_count+1;
                end if;
                if length(txt) > 23 then
                  txt := substr(txt,1,23-length(plib.ir(i).text1))||plib.ir(i).text1;
                end if;
                etext := etext1||'Cursor$'||txt||'; '||etext;
              end if;
              j := plib.ir(i).type1;
              if j>0 and j<999 then
                if j=1 then
                  txt := 'BUSY';
                else
                  txt := 'WAIT or rtl.RESOURCE_LOCK';
                end if;
                etext := 'begin'||NL||mgn||TAB||etext||';'||NL
                    ||mgn||'exception when rtl.RESOURCE_'||txt||' then raise rtl.CANNOT_LOCK;'||NL
                    ||mgn||'end';
                origin:= true;
              end if;
            else
              if use_counters then inc_counter(plp$parser.VAR_+2000); end if;
            end if;
            lib.put_buf(eprog||mgn||etext||';'||NL,p_text);
        elsif typ = plp$parser.EXIT_ then
          if use_counters then inc_counter(typ+2000); end if;
          if tmp_loop>0 then
            if i is NULL then
                etext := null;
                if is_method and this_var then
                  if this_upd then
                    put_set_this(etext,mgn);
                    origin:= TRUE;
                  elsif this_mtd then
                    put_get_this(etext,mgn);
                    origin:= TRUE;
                  end if;
                end if;
                lib.put_buf(etext||mgn||'exit '||txt||';'||NL,p_text);
                v_chk := not plib.g_optim_code;
                if plib.g_optim_this then
                  chk_return := null;
                end if;
                chk_sav := false;
            else
                b:=expr2plsql(i, p_decl, eprog, etext, mgn ) and plib.g_optim_code;
                if b then
                  typ := get_bool_const(etext,false);
                end if;
                if b and typ <= 0 then
                    lib.put_buf(mgn||NULL_STMT||NL,p_text);
                else
                    if b and typ > 0 then
                        lib.put_buf(mgn||'exit '||txt||';'||NL,p_text);
                        v_chk := FALSE;
                    else
                        lib.put_buf(eprog||mgn||'exit '||txt||' when '||etext||';'||NL,p_text);
                        origin := not eprog is NULL;
                    end if;
                end if;
            end if;
            sosmethod := false;
          else
            lib.put_buf(mgn||NULL_STMT||NL,p_text);
          end if;
        elsif typ = plp$parser.WHILE_ then
            if use_counters then inc_counter(typ+2000); end if;
            if lfor then
                etext1 := NULL;
            end if;
            b:=expr2plsql(i, p_decl, eprog, etext, mgn ) and plib.g_optim_code;
            if b then
              typ := get_bool_const(etext,false);
            end if;
            if b and typ <= 0 then
                lib.put_buf(etext1||mgn||NULL_STMT||NL,p_text);
            else
              declare
                v_text plib.string_tbl_t;
              begin
                if b and typ > 0 then
                  etext1 := etext1||mgn||'loop'||NL;
                else
                  b := false;
                  if eprog is NULL then
                    etext1 := etext1||mgn||'while '||etext||' loop'||NL;
                  else
                    etext1 := etext1||mgn||'loop'||NL||eprog||mgn||'if '||etext||' then null; else exit; end if;'||NL;
                  end if;
                end if;
                sosmethod:= false;
                tmp_loop := tmp_loop+1;
                contin := tmp_continue;
                tmp_continue := false;
                upd := this_upd;
                mtd := this_mtd;
                chg := this_chg;
                get := this_get;
                cnt := obj_count;
                j := get_count;
                sos2plsql( plib.ir(i).right, p_l+1, p_decl, v_text,tmp_idx,p_lock );
                etext := null;
                this_state(mtd,upd,chg,get,cnt<obj_count,j<get_count,etext,mgn);
                if etext is null then
                  lib.put_buf(etext1,p_text);
                elsif eprog is null then
                  lib.put_buf(etext||etext1,p_text);
                else
                  lib.put_buf(etext1||etext,p_text);
                end if;
                if v_text.count>0 then
                  etext1:= null;
                  lib.add_buf(v_text,p_text,true,true);
                else
                  etext1 := mgn||TAB||'exit;'||NL;
                  b := false;
                end if;
                etext1 := etext1||mgn||case when tmp_continue then '<<end$loop$'||tmp_loop||'>>null;' else '' end||'end loop;'||NL;
                lib.put_buf(etext1,p_text);
                sosmethod:= vsos;
                tmp_loop := tmp_loop-1;
                if b then
                  if chk_return is null then
                    chk_return := false;
                  else
                    chk_return := plib.g_optim_this;
                  end if;
                else
                  chk_return := false;
                end if;
                tmp_continue := contin;
              end;
            end if;
            lfor  := TRUE;
        elsif typ = plp$parser.LOOP_ then
          declare
            v_text plib.string_tbl_t;
          begin
            if use_counters then inc_counter(typ+2000); end if;
            if lfor then
                etext1 := NULL;
            end if;
            tmp_loop := tmp_loop+1;
            contin := tmp_continue;
            tmp_continue := false;
            upd := this_upd;
            mtd := this_mtd;
            chg := this_chg;
            get := this_get;
            cnt := obj_count;
            j := get_count;
            sos2plsql( i, p_l+1, p_decl, v_text, tmp_idx,p_lock );
            etext := null;
            this_state(mtd,upd,chg,get,cnt<obj_count,j<get_count,etext,mgn);
            etext1:= etext||etext1;
            if not etext1 is null then
                lib.put_buf(etext1,p_text);
            end if;
            if v_text.count>0 then
                lib.put_buf(mgn||'loop'||NL,p_text);
                lib.add_buf(v_text,p_text,true,true);
                lib.put_buf(mgn||case when tmp_continue then '<<end$loop$'||tmp_loop||'>>null;' else '' end||'end loop;'||NL,p_text);
                if chk_return is null then
                  chk_return := false;
                else
                  chk_return := plib.g_optim_this;
                end if;
            end if;
            sosmethod:= vsos;
            tmp_loop := tmp_loop-1;
            tmp_continue := contin;
            lfor  := TRUE;
          end;
        elsif typ = plp$parser.INSERT_ then
            etext1:= null;
            if plib.ir(idx).type1=plp$parser.SELECT_ then
              if use_counters then inc_counter(typ+3000); end if;
              insert2plsql2(idx, p_l, etext1);
            else
              if use_counters then inc_counter(typ+2000); end if;
              etext := insert2plsql(idx,mgn,p_decl,etext1);
            end if;
            lib.put_buf(etext1,p_text);
            origin := TRUE;
        elsif typ = plp$parser.GOTO_ then
            if use_counters then inc_counter(typ+2000); end if;
            etext := null;
            if is_method and this_var then
              chk_sav := true;
              sav_upd := this_upd;
              sav_mtd := this_mtd;
              sav_chg := this_chg;
              if this_upd then
                put_set_this(etext,mgn);
                origin:= TRUE;
              elsif this_mtd then
                put_get_this(etext,mgn);
                origin:= TRUE;
              end if;
            else
              chk_sav := false;
            end if;
            lib.put_buf(etext||mgn||'goto '||txt||';'||NL,p_text);
            v_chk := not plib.g_optim_code;
            if plib.g_optim_this then
              chk_return := null;
            end if;
            sosmethod := false;
        elsif typ = plp$parser.SAVEPOINT_ then
            if use_counters then inc_counter(plp$parser.SETPAR_+2000); end if;
            etext := NULL;
            db_update := true;
            if p_lock and is_method and this_upd then
                put_set_this(etext,mgn);
                origin := TRUE;
            end if;
            etext := etext||mgn||'cache_mgr.cache_set_savepoint ('''||txt||''');'||NL;
            lib.put_buf(etext,p_text);
        elsif typ = plp$parser.RAISE_ then
            if use_counters then inc_counter(typ+2000); end if;
            if i is NULL then
                lib.put_buf(mgn||'raise;'||NL,p_text);
            else
                eprog := NULL;
                etext := NULL;
                b:=var2plsql( i, p_decl, eprog, etext );
                lib.put_buf(eprog||mgn||'raise '||etext||';'||NL,p_text);
                origin := not eprog is NULL;
            end if;
            v_chk := not plib.g_optim_code;
            chk_return := plib.g_optim_this;
            chk_sav := false;
        elsif typ = plp$parser.ROLLBACK_ then
            if use_counters then inc_counter(plp$parser.SETPAR_+2000); end if;
            etext := mgn||'cache_mgr.cache_rollback';
            db_update := true;
            if cnt_autonom > 0 then
                etext := etext||'('''||txt||''',true)';
            elsif not p_lock then
                etext := etext||'('''||txt||''',null)';
            elsif txt is not null then
                etext := etext||'('''||txt||''')';
            end if;
            lib.put_buf(etext||';'||NL,p_text);
            if p_lock and is_method then
                this_chg := true;
                this_mtd := true;
                this_upd := false;
            end if;
        elsif typ = plp$parser.COMMIT_ then
            if use_counters then inc_counter(plp$parser.SETPAR_+2000); end if;
            etext := NULL;
            db_update := true;
            if p_lock and is_method and this_upd then
                put_set_this(etext,mgn);
                origin := true;
            end if;
            etext := etext||mgn||'cache_mgr.cache_commit';
            if cnt_autonom > 0 then
                etext := etext||'(true)';
            elsif not p_lock then
                etext := etext||'(null)';
            end if;
            lib.put_buf(etext||';'||NL,p_text);
        elsif typ=plp$parser.ATTR_ then
            if use_counters then inc_counter(typ+2000); end if;
            eprog := NULL;
            etext := NULL;
            b:=var2plsql( idx, p_decl, eprog, etext, null, mgn );
            origin := not eprog is NULL;
            if origin then
                lib.put_buf(eprog,p_text);
            end if;
        elsif typ=plp$parser.UPDATE_ then
            if use_counters then inc_counter(typ+3000); end if;
            etext := NULL;
            update2plsql(idx, p_l, etext);
            lib.put_buf(etext,p_text);
            origin := TRUE;
        elsif typ=plp$parser.DELETE_ then
            if use_counters then inc_counter(typ+3000); end if;
            etext := NULL;
            delete2plsql(idx, p_l, etext);
            lib.put_buf(etext,p_text);
            origin := TRUE;
        elsif typ = plp$parser.CONTINUE_ then
          if use_counters then inc_counter(plp$parser.END_+2000); end if;
          tmp_continue := tmp_loop>0;
          if tmp_continue then
            etext := null;
            if is_method and this_var then
              if this_upd then
                put_set_this(etext,mgn);
                origin := true;
              elsif this_mtd then
                put_get_this(etext,mgn);
                origin := true;
              end if;
            end if;
            if inst_info.db_version > 10 then
              etext := etext||mgn||'continue;'||NL;
              tmp_continue := false;
            else
              etext := etext||mgn||'goto end$loop$'||tmp_loop||';'||NL;
            end if;
            v_chk := not plib.g_optim_code;
            chk_return := plib.g_optim_this;
            chk_sav := false;
          else
            etext:= mgn||NULL_STMT||NL;
          end if;
          lib.put_buf(etext,p_text);
        elsif typ = plp$parser.ANY_ then
          i := plib.ir(idx).down;
          b := expr2plsql(i, p_decl, eprog, etext, mgn );
          txt := eprog;
          etext := mgn||'execute immediate '||etext;
          i := plib.ir(i).right;
          if i is null then
            lib.put_buf(txt||etext||';'||NL,p_text);
            if plib.g_method_lock then
              db_update := true;
              if is_method then
                lock_this := true;
              end if;
            end if;
          else
            typ := plib.ir(i).type;
            if typ in (plp$parser.INTO_,plp$parser.RETURN_) then
              if bitand(plib.ir(i).type1,2)=2 then
                eprog := 'bulk collect into ';
              else
                eprog := 'into ';
              end if;
              j := plib.ir(i).down;
              loop
                etext1:= null;
                b := var2plsql(j,p_decl,txt,etext1,chr(13),mgn);
                eprog := eprog||etext1;
                j := plib.ir(j).right;
                exit when j is null;
                eprog := eprog||', ';
              end loop;
              i := plib.ir(i).right;
              b := typ = plp$parser.RETURN_;
              if b then
                eprog := NL||mgn||TAB||'returning '||eprog;
              else
                etext := etext||NL||mgn||TAB||eprog;
                eprog := null;
              end if;
            else
              b := plib.g_method_lock;
              eprog := null;
            end if;
            if b then
              db_update := true;
              if is_method then
                lock_this := true;
              end if;
            end if;
            if txt is not null then
              lib.put_buf(txt,p_text);
            end if;
            if i is not null and plib.ir(i).type=plp$parser.BY_ then
              etext := etext||NL||mgn||TAB||'using ';
              i := plib.ir(i).down;
              loop
                j := plib.ir(i).down;
                if plib.ir(i).text is null then
                  b := expr2plsql(j,p_decl,txt,etext1,mgn);
                else
                  txt := null;
                  etext1 := null;
                  b := var2plsql(j,p_decl,txt,etext1,chr(13),mgn);
                end if;
                if txt is not null then
                  lib.put_buf(txt,p_text);
                end if;
                etext := etext||plib.ir(i).text||etext1;
                i := plib.ir(i).right;
                exit when i is null;
                etext := etext||', ';
              end loop;
            end if;
            lib.put_buf(txt||etext||eprog||';'||NL,p_text);
            origin := TRUE;
          end if;
        else
          v_skip := false;
        end if;
        prev_line := nvl(plib.ir(idx).line,0);
        if v_chk and dlevel < 0 and prev_line > 0 then
            typ := plib.ir(idx).type;
            if typ not in (plp$parser.EXIT_,plp$parser.RETURN_,plp$parser.RAISE_,plp$parser.NULL_,
              plp$parser.GOTO_,plp$parser.CONTINUE_,plp$parser.LABEL_)
            then
                lib.put_buf(mgn||'rtl.debug('''||plib.type_name(typ)
                  ||' statement processed ('||prev_line||','||plib.ir(idx).pos||')'','||(-dlevel)||',true);'||NL,p_text);
            end if;
        end if;
       end if;
       if not v_skip is null then
        if typ=plp$parser.LABEL_ then
          if use_counters then inc_counter(typ+2000); end if;
          etext1 := mgn||'<<'||txt||'>>'||NL;
          if not idx1 is NULL and plib.ir(idx1).type in (plp$parser.FOR_,plp$parser.WHILE_,plp$parser.LOOP_) then
             lfor := FALSE;
          else
             lfor := TRUE;
             lib.put_buf(etext1,p_text);
          end if;
          v_chk := TRUE;
          chk_return := false;
        elsif typ=plp$parser.TEXT_ then
          if use_counters then inc_counter(typ+2000); end if;
          lib.put_buf(txt,p_text);
          if plib.g_method_lock then
            db_update := true;
            if is_method then
              lock_this := true;
            end if;
          end if;
          origin:= TRUE;
          v_chk := TRUE;
          chk_return := false;
        elsif not v_skip then
          plib.plp_error(idx, 'IR_UNEXPECTED', 'sos2plsql', plib.type_name(typ), idx );
        end if;
       end if;
      end if;
      idx := idx1;
    end loop;
    this_add := v_add;
end sos2plsql;
--
-- @METAGS exception2plsql
procedure exception2plsql ( p_idx  IN     pls_integer,
                            p_l    IN     pls_integer,
                            p_decl in out nocopy varchar2,
                            p_text in out nocopy plib.string_tbl_t,
                            t_idx  IN     pls_integer default NULL,
                            p_lock IN     boolean default TRUE
                          ) is
    idx   pls_integer := plib.ir(p_idx).down;
    typ   pls_integer;
    i     pls_integer;
    mgn   varchar2(100) := rpad(TAB, p_l, TAB);
    eprog varchar2(32767);
    etext varchar2(8000);
    v_text  plib.string_tbl_t;
    b     boolean;
    upd   boolean;
    mtd   boolean;
    chg   boolean;
    get   boolean;
    ch    boolean;
    mt    boolean;
    gt    boolean;
    null_ boolean;
begin
    if not idx is NULL then
        null_ := true;
        if nvl(chk_return,true) and chk_sav then
          upd := sav_upd;
          mtd := sav_mtd;
          chg := sav_chg;
        else
          upd := this_upd;
          mtd := this_mtd;
          chg := this_chg;
        end if;
        get:= this_get;
        gt := get; mt := mtd; ch := chg;
        while not idx is NULL loop
          typ:=plib.ir(idx).type;
          if typ in (plp$parser.WHEN_,plp$parser.OTHERS_) then
            i := plib.ir(idx).down;
            b := plib.plp$define;
            this_upd := upd;
            this_mtd := mtd;
            this_chg := chg;
            this_get := get;
            eprog := null;
            if typ=plp$parser.WHEN_ then
              if b then
                tmp_expr_idx := null;
                b:=expr2plsql(i, p_decl, eprog, etext, mgn, false, false );
                eprog := eprog||mgn||'when '||etext||' then'||NL;
              end if;
              i:=plib.ir(i).right;
            elsif b then
              eprog := mgn||'when others then'||NL;
              if plib.ir(idx).type1=0 then
                eprog := eprog||mgn||'if sqlcode in (-4061,-6508) then raise; end if;'||NL;
              end if;
            end if;
            sosmethod := false;
            sos2plsql(i, p_l+1, p_decl, v_text,t_idx,p_lock);
            if v_text.count>0 then
                b := not eprog is null;
                if b then
                  if null_ then
                    null_ := false;
                    eprog := mgn||'exception'||NL||eprog;
                  end if;
                  lib.put_buf(eprog,p_text);
                else
                  b := not null_;
                end if;
                lib.add_buf(v_text,p_text,true,true);
                if is_method and not chk_return then
                  if b then
                    eprog := null;
                    if upd then
                      if this_mtd then
                        put_get_this(eprog,mgn||TAB);
                      end if;
                    elsif this_upd then
                      put_set_this(eprog,mgn||TAB);
                    end if;
                    if not eprog is null then
                      lib.put_buf(eprog,p_text);
                    end if;
                    mt := mt or this_mtd;
                    ch := ch or this_chg;
                    gt := gt or this_get;
                  else
                    upd := this_upd;
                    mtd := this_mtd; mt := mtd;
                    chg := this_chg; ch := chg;
                    get := this_get; gt := get;
                  end if;
                end if;
            end if;
            chk_return := false;
          end if;
          idx := plib.ir(idx).right;
        end loop;
        this_upd := upd;
        this_mtd := mt;
        this_chg := ch;
        this_get := gt;
    end if;
end exception2plsql;
--
procedure init(p_java boolean) is
    table_info     lib.table_info_t;
begin
    temp_vars.delete;
    used_attrs.delete;
    overlapped.delete;
    over_count := null;
    tmp_loop   := 0;
    tmp_var_idx:= 0;
    tmp_sos_idx:= 0;
    col_count  := 0;
    col_attrs  := 0;
    col_cached := 0;
    cnt_autonom:= 0;
    init_proc  := 0;
    tmp_continue  := FALSE;
    self_interface:= class_mgr.interface_package(plib.g_class_id);
    self_type  := class2plsql(plib.g_class_id);
    linfo_txt  := '''['||plib.g_class_id||']::['||plib.g_method_sname||']''';
    new_this   := plib.THIS;
    chk_return := FALSE;
    lock_this  := FALSE;
    is_method  := FALSE;
    sos_method := FALSE;
    sosmethod  := FALSE;
    chk_var    := FALSE;
    this_var   := FALSE;
    this_obj   := FALSE;
    this_chg   := FALSE;
    this_get   := FALSE;
    this_upd   := FALSE;
    this_mtd   := FALSE;
    this_add   := FALSE;
    this_ins   := FALSE;
    call_obj   := FALSE;
    db_update  := FALSE;
    db_context := FALSE;
    chk_call   := FALSE;
    chk_key    := FALSE;
    has_src_id := not plib.g_method_src is null;
    this_new   := instr(plib.g_method_flags,constant.METHOD_NEW)>0;       -- операция конструктор
    this_del   := instr(plib.g_method_flags,constant.METHOD_DELETE)>0;    -- операция деструктор
    this_grp   := instr(plib.g_method_flags,constant.METHOD_GROUP)>0;     -- операция списочная
    this_trig  := instr(plib.g_method_flags,constant.METHOD_TRIGGER)>0;   -- операция триггер
    this_static:= instr(plib.g_method_flags,constant.METHOD_STATIC)>0     -- операция групповая(статическая)
               or instr(plib.g_method_flags,constant.METHOD_CRITERION)>0; -- операция фильтр
    this_attr  := instr(plib.g_method_flags,constant.METHOD_ATTRIBUTE)>0; -- операция для функционального реквизита
    this_kernel:= substr(plib.g_class_flags,31,1)=constant.YES;
    -- self_ref не может быть типа rowid, т.к. используется для генерации кода "plp$THIS  varchar2(128) := THIS;" в секции EXECUTE, а значением plp$THIS может быть идентификатор коллекции
    self_ref := ref_string(this_kernel or lib.pk_is_rowid(plib.g_class_id) or not plib.g_class_key is null,true, false);
    cache_this := (global_cache or this_attr) and plib.g_base_id=constant.STRUCTURE and not this_grp;
    cache_obj  := global_cache and not (this_grp or this_static);
    if this_new and cache_this then
        this_ins := not plib.g_constructor;
    end if;
    if this_ins or this_attr then
        cache_obj := true;
        plib.g_optim_this := true;
        plib.g_method_cobj:= true;
    end if;
    self_calc  := plib.g_class_id<>SYS;
    set_rules  := substr(plib.g_class_flags,1, 1)=constant.YES;
    if this_trig then
      has_check  := false;
    else
      has_check  := substr(plib.g_class_flags,8, 1)=constant.YES;
    end if;
    self_static:= substr(plib.g_class_flags,14,1)=constant.YES;
    this_part  := substr(plib.g_class_flags,16,2);
    if instr(this_part,'1') > 0 then
      self_cached := true;
    elsif instr(this_part,'2') > 0 then
      self_cached := null;
    else
      self_cached := false;
    end if;
    self_attrs := lib.table_exist(plib.g_class_id,table_info);
    this_table := table_info.table_name;
    if table_info.param_group like 'PART%' then
      if table_info.param_group='PARTITION' then
        this_part := '1';
      else
        this_part := '2';
      end if;
    else
      this_part := '0';
    end if;
    --if inst_info.db_version<10 or table_info.flags like '0%' then
    --  this_scn := true;
    --else
    --  this_scn := false;
    --end if;
    self_attrs := substr(plib.g_class_flags,21,1)=constant.YES;
--
    cur_class  := null;
    use_context:= null;
    skip_attrs := false;
    chk_class:= false;
    query_idx:= 1000;
    cur_alias:= 'a';
    use_java := nvl(p_java,false);
    tmp_vars := 0;
    cursor_idx := 0;
    -- PLATFORM-1540 добавлен сброс значений переменных в умолчательное значение
    chk_sav:= false;
    sav_chg:= false;
    sav_mtd:= false;
    sav_upd:= false;
end;
--
-- @METAGS ir2plsql
procedure ir2plsql ( p_idx  IN     pls_integer,
                     p_l    IN     pls_integer,
                     p_text in out nocopy plib.string_tbl_t
                   ) is
    idx pls_integer := p_idx;
    str varchar2(100);
    typ pls_integer;
    ok  boolean;
begin
--    rtl.debug( 'ir2plsql: start ' || p_idx||' level '||p_l );
    Init(false);
    p_text.delete;
    typ := plib.ir(idx).type;
-- FUNCTION_: function/procedure declaration
    if typ = plp$parser.FUNCTION_ then
--        rtl.debug( 'ir2plsql: func '||idx||' in '||p_idx );
        if use_counters then inc_counter(typ+1000); end if;
        func2plsql( idx, p_l, p_text, str, true );
-- DECLARE_: params/variables declarations
    elsif typ = plp$parser.DECLARE_ then
--        rtl.debug( 'ir2plsql: declare '||idx||' in '||p_idx );
        declare2plsql( idx, p_l, p_text, DECLARE_FORMAT_VARS,TRUE,TRUE );
    else
        plib.plp_error( idx, 'IR_UNEXPECTED', 'ir2plsql', plib.type_name(typ), idx );
    end if;
    if this_ins then
      -- PLATFORM-2531: добавили в пакет буферную переменную
      plib.pack_header := plib.pack_header || TAB || 'plp$buf$ ' || self_type || ';' || NL;
      lib.put_buf(TAB||var_ins||TAB||self_type||';'||NL
                || TAB||var_chk||TAB||'boolean := false;'||NL,p_text,false);
    end if;
    idx:= plib.ir(idx).right;
    ok := not idx is null and plib.ir(idx).type=plp$parser.BLOCK_;
    if init_proc>0 or ok then
        db_update := false;
        db_context:= false;
        lib.put_buf('-- INITIALIZATION'||NL||'begin'||NL,p_text);
        if init_proc>0 then
            lib.put_buf(TAB||plib.get_new_name(init_proc)||';'||NL,p_text);
            typ := plib.ir(init_proc).type1;
            if bitand(typ,2) > 0 then
                db_update := true;
            end if;
            if bitand(typ,8) > 0 then
                db_context:= true;
            end if;
        end if;
        if ok then
            if plib.section<>method.PRIVATE_SECTION then
                plib.section := method.PRIVATE_SECTION;
                lib.put_buf(plib.SECTION_COMMENT||method.PRIVATE_SECTION||NL,p_text);
            end if;
            typ := p_text.last+1;
            block2plsql(idx,1,str,p_text,null);
            if instr(p_text(typ),TAB||'begin'||NL)=1 then
                p_text(typ) := substr(p_text(typ),8);
                typ := p_text.last;
                p_text(typ) := substr(p_text(typ),1,length(p_text(typ))-6);
            end if;
        end if;
        if db_update or db_context then
            if db_update and instr(plib.g_method_flags,constant.METHOD_LIBRARY)=0 then
                plib.g_method_upd := 3;
            end if;
            idx := plib.ir(p_idx).down;
            while not idx is null loop
                if plib.ir(idx).type=plp$parser.FUNCTION_ then
                  if db_update then
                    plib.set_function(idx,2);
                  end if;
                  if db_context then
                    plib.set_function(idx,8);
                  end if;
                end if;
                idx := plib.ir(idx).right;
            end loop;
        end if;
    end if;
    temp_vars.delete;
    used_attrs.delete;
    overlapped.delete;
    if use_counters then dump_counters(false); end if;
end ir2plsql;
--
function check_alias(p_alias varchar2, p_als in out nocopy plib.string_tbl_t, p_idx pls_integer) return varchar2 is
    v_alias varchar2(1000);
    s   varchar2(10);
    i   pls_integer;
    j   pls_integer;
    l   pls_integer := 30;
    q   boolean := false;
begin
    if p_alias is null then
      v_alias := 'C$'||mod(p_idx,10000);
    else
      i := length(p_alias);
      if substr(p_alias,1,1)='"' and substr(p_alias,i,1)='"' then
        q := true; l := 28;
        v_alias := substr(p_alias,2,i-2);
      else
        v_alias := upper(p_alias);
        l := 1;
        loop
          j := instr(v_alias,':',l);
          if j>0 then
            i := instr(v_alias,'.',l);
            if i=0 or i>j then
              v_alias := substr(v_alias,1,l-1)||substr(v_alias,j+1);
            elsif i<j then
              v_alias := substr(v_alias,1,i)||substr(v_alias,j+1);
              l := i+1;
            end if;
          else
            exit;
          end if;
        end loop;
        l := 30;
      end if;
      while length(v_alias)>l loop
        i := instr(v_alias,'.');
        if i>0 then
            v_alias := 'C_'||substr(v_alias,i+1);
        else
            v_alias := substr(v_alias,1,l);
            exit;
        end if;
      end loop;
      if q then
        v_alias := '"'||v_alias||'"';
      else
        v_alias := replace(class_mgr.replace_invalid_symbols(v_alias),'.','#');
      end if;
    end if;
    i := 0;
    loop
      j := plib.find_string(p_als,v_alias);
      exit when j is null or j=p_idx;
      if q then
        v_alias := substr(v_alias,2,length(v_alias)-2);
      end if;
      i := i+1;
      s := '_'||i;
      if i>1 then
        j := instr(v_alias,'_',-1);
        v_alias := substr(v_alias,1,j-1);
      elsif length(s)+length(v_alias)>l then
        v_alias := substr(v_alias,1,l-length(s));
      end if;
      v_alias := v_alias||s;
      if q then
        v_alias := '"'||v_alias||'"';
      end if;
    end loop;
    p_als(p_idx) := v_alias;
    return v_alias;
end;
--
procedure fill_column_info(p_info in out nocopy column_info_t,p_alias varchar2,p_nosort boolean) is
  v_props varchar2(4000);
  i pls_integer;
begin
  p_info := null;
  v_props:= plib.get_column_props(p_alias);
  if v_props is null then
    return;
  end if;
  p_info.name := substr(method.extract_property(v_props,'NAME'),1,64);
  p_info.target_class_id := substr(method.extract_property(v_props,'TARGET_CLASS_ID'),1,16);
  p_info.sizeable := substr(method.extract_property(v_props,'SIZEABLE'),1,1);
  p_info.unvisible:= substr(method.extract_property(v_props,'UNVISIBLE'),1,1);
  p_info.align := substr(method.extract_property(v_props,'ALIGN'),1,1);
  p_info.width := method.extract_property(v_props,'WIDTH');
  p_info.data_precision := method.extract_property(v_props,'DATA_PRECISION');
  if not p_nosort then
    v_props := method.extract_property(v_props,'ORDER_BY');
    i := instr(v_props,' ');
    if i>0 then
      p_info.orderby := substr(v_props,1,i-1);
      if upper(trim(substr(v_props,i+1)))='DESC' then
        p_info.orderby := -p_info.orderby;
      end if;
    elsif i=0 then
      p_info.orderby := v_props;
    end if;
  end if;
  if p_info.sizeable not in ('0','1') then
    p_info.sizeable := null;
  end if;
  if p_info.unvisible not in ('0','1','2') then
    p_info.unvisible := null;
  end if;
  if p_info.align not in ('0','1','2') then
    p_info.align := null;
  end if;
exception when value_error then
  null;
end;
--
function criteria2plsql( p_cr_id varchar2,
                         p_text  in out nocopy varchar2,
                         p_from  in out nocopy varchar2,
                         p_where in out nocopy varchar2,
                         p_next  in out nocopy varchar2
                       ) return pls_integer is
    idx       pls_integer;
    idx1      pls_integer;
    typ       pls_integer;
    v_idx     pls_integer;
    v_set     pls_integer;
    sel_idx   pls_integer;
    group_idx pls_integer;
    hav_idx   pls_integer;
    where_idx pls_integer;
    order_idx pls_integer;
    lock_idx  pls_integer;
    v_cursor  pls_integer;
    str       varchar2(4000);
    str1      varchar2(4000);
    str2      varchar2(4000);
    str3      varchar2(4000);
    v_hint    varchar2(2000);
    v_props   varchar2(2000);
    v_qual    varchar2(1000);
    v_nested  varchar2(1000);
    v_column  varchar2(100);
    edecl     varchar2(32767);
    eprog     varchar2(32767);
    etext     varchar2(32767);
    dist      varchar2(100);
    v_class   varchar2(16);
    v_flags   varchar2(1);
    v_als     varchar2(40);
    v_crit    varchar2(30);
    v_usrctx  varchar2(16);
    v_info    plib.plp_class_t;
    v_decl    plib.string_tbl_t;
    v_colinfo column_info_t;
    b         boolean;
    bSort     boolean;
    bArch     boolean;
--
    procedure set_props is
    begin
      if bSort then
        v_props := v_props||'|NoSort';
      end if;
      v_props := replace(v_props,'|BaseClassIncompatible');
      if v_class<>cur_class then
        method.put_property(v_props,'BaseClass',cur_class);
        plib.plp_warning(v_set,'TYPES_INCOMPATIBLE',v_class,cur_class);
        if not cur_class like '%rowtype' and (lib.is_parent(v_class,cur_class) or lib.is_parent(cur_class,v_class)) then null;
        else
          v_props := v_props||'|BaseClassIncompatible';
        end if;
      else
        method.put_property(v_props,'BaseClass','|');
      end if;
      method.put_property(v_props,'USERCONTEXT',case when db_context then '1' else nvl(v_usrctx,'0') end);
    end;
--
begin
  sel_crit_tree.delete;
  use_context:= null;
  cur_nested := null;
  skip_attrs := false;
  select class_id,short_name,flags,properties,condition,order_by,group_by,ref_rights,nested_qual
    into v_class,v_crit,v_flags,v_props,str,str1,str2,v_hint,v_nested
    from criteria where id=p_cr_id and instr(properties,'|PlPlus')>0;
  if not v_nested is null then
    idx := instr(v_nested,':');
    if idx>1 then
      cur_nested := substr(v_nested,1,idx-1);
      v_nested := nvl(substr(v_nested,idx+1),' ');
    else
      cur_nested := v_class;
    end if;
    if lib.qual_column(cur_nested,v_nested,str3,v_column,etext) then
      if substr(etext,1,instr(etext,'.',1,2)-1)=constant.GENERIC_TABLE||'.'||v_class then
        etext:= 'v$nested ['||cur_nested||']::['||replace(v_nested,'.','].[')||'];';
        cur_nested := rtl.bool_char(lib.has_stringkey(cur_nested))||str3||'.'||v_column;
        v_nested := null;
      else
        etext:= 'v$nested ['||cur_nested||']::['||replace(v_nested,'.','].[')||'];';
      end if;
    end if;
  end if;
  if InStr(v_props,'|Actual') > 0 then
    etext := 'pragma '||plib.ARCHIVE_PRAGMA||'(true,true);'||etext;
  elsif InStr(v_props,'|Archive') > 0 then
    if InStr(v_props,'|ArchView') > 0 and dict_mgr.option_enabled('ORM.ARC.PACK') then
      if p_text = '1' then
        bArch := true;
      else
        bArch := false;
      end if;
    else
      etext := 'pragma '||plib.ARCHIVE_PRAGMA||'(true,false);'||etext;
    end if;
  end if;
  if p_next is not null then
    v_usrctx := method.extract_property(v_props,'USERCONTEXT');
  end if;
  p_text := 'pragma '||plib.ORIGIN_PRAGMA||'('''||method.PRIVATE_SECTION||''');'||etext||NL||str||str1||str2;
  p_from := null;
  p_where:= null;
  p_next := null;
loop
  plib.in_str := p_text;
  plib.g_crit_id := p_cr_id;
  idx := plib.parse$('RTL',false,false,false,bArch);
  if idx<>0 then
    goto exiting;
  elsif not (cur_nested is null or v_nested is null) then
    plib.plp_error(null,'NO_TABLE_COLUMN',v_nested,cur_nested);
    goto exiting;
  end if;
  init(false);
  idx := plib.find_child(ir_root,plp$parser.TYPE_,'MAIN');
  if idx is null then
    plib.plp_error(null,'NO_CURSOR_BODY');
    goto exiting;
  elsif v_hint is null then
    exit;
  else
    idx := plib.ir(idx).down;
    if plib.ir(idx).type1=plp$parser.UNION_ then
        idx := plib.ir(plib.ir(idx).down).right;
    end if;
    str := plib.ir(idx).text;
    v_hint:= rtl.safe_replace(v_hint,'A1.',str||'.');
    idx := instr(p_text,';',-1);
    if idx>0 then
      p_text := substr(p_text,1,idx-1)||NL||'others '||v_hint||substr(p_text,idx);
    end if;
    v_hint := null;
  end if;
end loop;

  if bRhtContext is null then
    bRhtContext := nvl(rtl.setting('RIGHTS_CONTEXT'),'1')='1';
    bObjContext := nvl(rtl.setting('OBJECT_RIGHTS_CONTEXT'),'1')='1';
    bRefContext := nvl(rtl.setting('OBJECT_RIGHTS_EX_CONTEXT'),'1')='1';
  end if;
  bAddSysCols := true;
  if InStr(v_props,'|NoSystem')>0 then
    bAddSysCols := false;
  elsif InStr(v_props,'|NoCheckArrays')>0 then
    bAddSysCols := null;
  end if;
  bObjChkMode := false;
  if InStr(v_props,'|ObjPriority')>0 then
    bObjChkMode := true;
  end if;
  if v_flags='R' and InStr(v_props,'|Context')>0 or InStr(v_props,'|NoContext')=0 then
    use_context := storage_mgr.use_context;
  else
    use_context := false;
  end if;
  v_hint:= collect_hints(idx,true);
  idx1 := plib.ir(idx).left;
  plib.ir(idx1).right := null;
  skip_attrs := true;
  declare2plsql( ir_root,0,v_decl,DECLARE_FORMAT_VARS,TRUE,TRUE );
  if v_decl.count>0 then
    idx1 := lib.get_buf(p_next,v_decl,true,true);
    if not cur_nested is null then
      idx1 := instr(p_next,'V$NESTED');
      if idx1>0 then
        p_next := substr(p_next,instr(p_next,NL,idx1+1)+1);
      end if;
    end if;
    if not p_next is null then
      rtl.debug(p_next,1,false,null);
      plib.plp_error(idx,'CURSOR_DECLARATIONS',plib.ir(idx).text);
      goto exiting;
    end if;
    v_decl.delete;
  end if;
  idx := plib.ir(idx).down; -- select sequence
  --plib.dump_ir(idx,0,0,false);
  typ := plib.ir(idx).type1;
  str := plib.ir(idx).text;
  idx1:= plib.ir(idx).down;   -- INTO list/type declaration
  v_idx := plib.ir(idx1).right;  -- ID declaration
  v_set := plib.ir(idx1).text1;  -- collection/class
  v_cursor:= 1;
  v_props := replace(replace(v_props,'|Complex'),'|NoSort');
  skip_attrs := true;
  chk_class:= true;
  cur_class:= v_class;
  query_idx:= 1000;
  cur_alias:= 'a';
  use_java := false;
  tmp_vars := 0;
  crit_cols.delete;
  if typ=plp$parser.UNION_ then

    if crit_extension then
      sel_crit_tree(plib.ir(idx).text) := plib.ir(idx).text;
      t_crit_tree(p_cr_id) := sel_crit_tree;
      goto Exiting;
    end if;

    cursor_idx := cursor_idx + 1;
    v_set := plib.ir(v_idx).right; -- first query
    v_cursor:= cursor_idx;
    str1 := plib.get_comments(v_set);
    if str1 is null then
      str1 := v_hint;
    else
      str1 := v_hint||' '||str1;
    end if;
    where_idx := query2plsql(v_set,edecl,eprog,p_from,lock_idx,false,str1,0);
    v_set := plib.ir(v_set).right; -- second query
    str1 := plib.get_comments(v_set);
    if str1 is null then
      str1 := v_hint;
    else
      str1 := v_hint||' '||str1;
    end if;
    where_idx := query2plsql(v_set,edecl,str2,etext,lock_idx,false,str1,0);
    eprog := eprog ||str2;
    p_from:= p_from||NL||TAB||TAB||str||NL||etext;
    order_idx := plib.ir(v_set).right;
    if not order_idx is null then
      str := plib.ir(v_idx).text;
      lock_idx := plib.ir(order_idx).right;
      v_idx := plib.ir(order_idx).down;
      if not (lock_idx is null and v_idx is null) then
        cur_alias := 'a';
        v_idx := 1; etext := null;
        v_idx := construct_cursor_text ( str,
                                C_DATA_VIEWS,
                                null,
                                idx,
                                null,
                                null,
                                null,
                                null,
                                order_idx,
                                0,
                                0,
                                lock_idx,
                                v_idx,
                                etext,
                                p_where,
                                p_next,
                                null,
                                null,
                                false);
          eprog := eprog||etext;
      end if;
    end if;
    if not (edecl is null or eprog is null) then
      rtl.debug(NL||edecl||NL||eprog,1,false,null);
      plib.plp_error(idx,'CURSOR_DECLARATIONS',plib.ir(idx).text);
    end if;
    bSort := not p_next is null;
    plib.add_cursor(p_from||p_next,v_cursor);
    if plib.plp$errors<>0 then
      goto exiting;
    end if;
    v_props := v_props||'|Complex';
    set_props;
    v_hint:= ltrim(v_hint);
    class_mgr.skip_changes(class_mgr.DCOT_CRITERIA, null);
--    class_mgr.skip_changes(class_mgr.DCOT_CRITERIA,class_mgr.DCCT_CRITERIA);
    update criteria set hints=v_hint, properties=v_props where id=p_cr_id;
--    class_mgr.skip_changes(class_mgr.DCOT_CRITERIA,class_mgr.DCCT_CRITERIA_COLUMNS);
    update criteria_columns set position=0 where criteria_id=p_cr_id;
    idx1 := plib.ir(idx1).down; -- fields description
    v_idx:= 0;
    while not idx1 is null loop
      str := plib.ir(idx1).text;
      if str like 'REF$_%' then
        str1 := substr(str,5);
        plib.expr_class(plib.ir(idx1).down,v_info,true,true);
        b := true;
        if v_info.is_reference or v_info.is_collection then
          v_info.elem_class_id := nvl(v_info.elem_class_id,v_info.class_id);
          if v_info.is_reference then
            v_flags := '0';
          else
            v_flags := rtl.bool_char(v_info.base_type=plp$parser.TABLE_,'2','1');
          end if;
          begin
            select target_class_id into str2 from criteria_columns
             where criteria_id=p_cr_id and qual=str1 and ref_type is null and position<>0 and rownum=1;
            fill_column_info(v_colinfo,str,bSort);
            if not v_colinfo.target_class_id is null then
              str2 := v_colinfo.target_class_id;
            end if;
            if str2<>v_info.elem_class_id
              and (lib.is_parent(str2,v_info.elem_class_id) or lib.is_parent(v_info.elem_class_id,str2)) then
                v_info.elem_class_id := str2;
            end if;
            update criteria_columns set
              reference_id=str, target_class_id=v_info.elem_class_id, ref_type=v_flags
             where criteria_id=p_cr_id and qual=str1;
            b := false;
          exception when no_data_found then null;
          end;
        end if;
        if b then
          plib.plp_warning(idx1,'NO_TABLE_COLUMN',str,v_crit);
        end if;
      elsif str not in ('ID','CLASS_ID','COLLECTION_ID','STATE_ID','NT$ID') then
        v_idx:= v_idx+1;
        str1 := str;
        if str1 like 'A$%' then
          str1 := 'C$'||v_idx;
        end if;
        fill_column_info(v_colinfo,str1,bSort);
        plib.expr_class(plib.ir(idx1).down,v_info,true,true);
        if v_info.is_reference then
          v_info.base_id := constant.REFERENCE;
          v_info.elem_class_id := nvl(v_info.elem_class_id,v_info.class_id);
        elsif v_info.is_collection then
          v_info.elem_class_id := nvl(v_info.elem_class_id,v_info.class_id);
        elsif v_info.base_type=plp$parser.ONE_ then
          v_info.elem_class_id := v_info.class_id;
        elsif v_info.kernel then
          if v_info.base_type=plp$parser.STRING_ then
            if v_info.class_id=constant.BOOLSTRING then
              v_info.base_id := constant.GENERIC_BOOLEAN;
            end if;
          elsif v_info.base_type=plp$parser.INTEGER_ then
            v_info.base_id := constant.GENERIC_NUMBER;
          elsif v_info.base_type in (plp$parser.TIMESTAMP_,plp$parser.INTERVAL_) then
            v_info.base_id := constant.GENERIC_DATE;
            v_info.elem_class_id := v_info.class_id;
          end if;
        end if;
        begin
          select target_class_id,reference_id into str2,str3 from criteria_columns
           where criteria_id=p_cr_id and alias=str1;
          if not v_colinfo.target_class_id is null then
              str2 := v_colinfo.target_class_id;
          end if;
          if not (str3 is null or str2 is null) and v_info.elem_class_id is null then
              v_info.elem_class_id := str2;
          elsif str2<>v_info.elem_class_id
            and (lib.is_parent(str2,v_info.elem_class_id) or lib.is_parent(v_info.elem_class_id,str2)) then
              v_info.elem_class_id := str2;
          end if;
-- no zB
if v_info.elem_class_id='ROWID' then
   if v_info.base_id='OLE' then
      v_info.base_id := 'VARCHAR2';
      v_info.elem_class_id := '';
   end if;
end if;
          update criteria_columns set
              position = v_idx, data_source=str, qual=str,
              reference_id=decode(ref_type,'0',null,'1',null,'2',null,null,null,reference_id),
              ref_type=decode(ref_type,'0',null,'1',null,'2',null,ref_type),
              data_precision=nvl(v_colinfo.data_precision,decode(v_info.base_id,constant.GENERIC_NUMBER,
                  decode(base_class_id,constant.GENERIC_NUMBER,data_precision,v_info.data_precision),data_precision)),
              base_class_id=v_info.base_id, target_class_id=v_info.elem_class_id,
              name  = nvl(v_colinfo.name,name), align = nvl(v_colinfo.align,align),
              sizeable = nvl(v_colinfo.sizeable,sizeable),
              unvisible= nvl(v_colinfo.unvisible,unvisible),
              width = nvl(v_colinfo.width,width),
              order_by_pos = nvl(abs(v_colinfo.orderby),order_by_pos),
              order_by_type= decode(sign(v_colinfo.orderby),1,'A',-1,'D',order_by_type)
           where criteria_id=p_cr_id and alias=str1;
        exception when no_data_found then
          if not v_colinfo.target_class_id is null then
            str2 := v_colinfo.target_class_id;
            if str2<>v_info.elem_class_id
              and (lib.is_parent(str2,v_info.elem_class_id) or lib.is_parent(v_info.elem_class_id,str2)) then
                v_info.elem_class_id := str2;
            end if;
          end if;
          if v_colinfo.name is null then
            str2 := message.gettext('PLP', 'COLUMN_NUMBER', v_idx);
          else
            str2 := v_colinfo.name;
          end if;
          if v_colinfo.align is null then
            if v_info.base_id=constant.GENERIC_NUMBER then
              v_colinfo.align := '1';
            elsif v_info.base_id=constant.GENERIC_DATE then
              v_colinfo.align := '2';
            else
              v_colinfo.align := '0';
            end if;
          end if;
          if v_colinfo.width is null then
            v_colinfo.width := least(length(str2),15);
          end if;
          if v_colinfo.data_precision is null and v_info.base_id=constant.GENERIC_NUMBER then
            v_colinfo.data_precision := v_info.data_precision;
          end if;
-- no zB
if v_info.elem_class_id='ROWID' then
   if v_info.base_id='OLE' then
      v_info.base_id := 'VARCHAR2';
      v_info.elem_class_id := '';
   end if;
end if;
          insert into criteria_columns(criteria_id,name,position,qual,data_source,alias,
                  base_class_id,target_class_id,width,data_precision,sizeable,unvisible,align,order_by_pos,order_by_type)
          values (p_cr_id,str2,v_idx,str,str,str1,v_info.base_id,v_info.elem_class_id,
                  v_colinfo.width,v_colinfo.data_precision,nvl(v_colinfo.sizeable,'1'),
                  nvl(v_colinfo.unvisible,'0'),v_colinfo.align,abs(v_colinfo.orderby),
                  decode(sign(v_colinfo.orderby),1,'A',-1,'D',null));
        end;
      end if;
      idx1 := plib.ir(idx1).right;
    end loop;
    delete criteria_columns where criteria_id=p_cr_id and position=0;
  else
    dist := plib.ir(idx).text1; -- distinct clause
    sel_idx  := plib.ir(v_set).right; -- select list head
    where_idx:= plib.ir(sel_idx).right;   -- where clause head
    sel_idx  := plib.ir(sel_idx).down; -- select list first entry
    group_idx:= plib.ir(where_idx).right; -- group clause head
    hav_idx  := plib.ir(group_idx).right; -- having clause head
    order_idx:= plib.ir(hav_idx).right;   -- order clause head
    if not order_idx is null then
      lock_idx := plib.ir(order_idx).right; -- for update clause head
      bSort := not plib.ir(order_idx).down is null;
    end if;

    v_idx := construct_cursor_text ( str,
                            C_DATA_VIEWS,
                            sel_idx,
                            v_set,
                            null,
                            where_idx,
                            hav_idx,
                            group_idx,
                            order_idx,
                            0,
                            typ,
                            lock_idx,
                            v_cursor,
                            p_from,
                            p_where,
                            p_next,
                            v_hint,
                            plib.ir(idx).text1
                          );

      -- сохраняем значения в дереве
    if crit_extension then
      t_crit_tree(p_cr_id) := sel_crit_tree;
    end if;

    if plib.plp$errors<>0 or crit_extension then
      goto Exiting;
    end if;

    v_hint:= ltrim(crit_hints);
    set_props;
    class_mgr.skip_changes(class_mgr.DCOT_CRITERIA, null);
--    class_mgr.skip_changes(class_mgr.DCOT_CRITERIA,class_mgr.DCCT_CRITERIA);
    update criteria set hints=v_hint, properties=v_props where id=p_cr_id;
--    class_mgr.skip_changes(class_mgr.DCOT_CRITERIA,class_mgr.DCCT_CRITERIA_COLUMNS);
    delete criteria_columns where criteria_id=p_cr_id and qual=alias
       and alias in ('ID','CLASS_ID','COLLECTION_ID','STATE_ID','NT$ID');
    update criteria_columns set position=0 where criteria_id=p_cr_id;
    v_idx:= 0;
    v_set:= sel_idx;
    while not sel_idx is null loop
      str := plib.ir(sel_idx).text;
      if str in ('ID','CLASS_ID','COLLECTION_ID','STATE_ID','NT$ID') or str like 'REF$_%' then null; else
        v_idx := v_idx+1;
        v_decl(v_idx) := str;
      end if;
      sel_idx := plib.ir(sel_idx).right;
    end loop;
    if not cur_nested is null then
      str := 'NT$ID';
      str3:= crit_cols(0);
      insert into criteria_columns(criteria_id,position,qual,data_source,alias,unvisible,width,name)
      values (p_cr_id,0,str,str3,str,'1',10,str);
    end if;
    v_idx:= 0;
    sel_idx := v_set;
    idx1 := plib.ir(idx1).down; -- fields description
    while not sel_idx is null loop
      str := plib.ir(sel_idx).text;
      str1:= plib.ir(sel_idx).text1;
      typ := plib.ir(sel_idx).down;
      --b:=expr2plsql ( typ, edecl, str2, str3, TAB );
      --eprog := eprog ||str2;
      str3 := crit_cols(sel_idx);
      if str in ('ID','CLASS_ID','COLLECTION_ID','STATE_ID') then
        begin
          insert into criteria_columns(criteria_id,position,qual,data_source,alias,unvisible,width,name)
          values (p_cr_id,0,str,str3,str,'1',10,str);
        exception when dup_val_on_index then
          plib.plp_warning(sel_idx,'ALREADY_DEFINED',str);
        end;
      elsif str='NT$ID' then
        null;
      else
        plib.expr_class(plib.ir(idx1).down,v_info,true,true);
        v_flags:= null;
        if v_info.is_reference then
          v_info.base_id := constant.REFERENCE;
          v_info.elem_class_id := nvl(v_info.elem_class_id,v_info.class_id);
          v_flags := '0';
        elsif v_info.is_collection then
          v_flags := rtl.bool_char(v_info.base_type=plp$parser.TABLE_,'2','1');
        elsif v_info.base_type=plp$parser.ONE_ then
          v_info.elem_class_id := v_info.class_id;
        elsif v_info.kernel then
          if v_info.base_type=plp$parser.STRING_ then
            if v_info.class_id=constant.BOOLSTRING then
              v_info.base_id := constant.GENERIC_BOOLEAN;
            end if;
          elsif v_info.base_type=plp$parser.INTEGER_ then
            v_info.base_id := constant.GENERIC_NUMBER;
          elsif v_info.base_type in (plp$parser.TIMESTAMP_,plp$parser.INTERVAL_) then
            v_info.base_id := constant.GENERIC_DATE;
            v_info.elem_class_id := v_info.class_id;
          end if;
        end if;
        str2 := null;
        v_hint := null;
        v_props:= null;
        if str1 is null then
          v_qual := str;
        else
          str1 := replace(str1,'<NULL>',' ');
          str1 := replace(str1,'< >',' ');
          typ  := instr(str1,'[');
          v_set:= instr(str1,']');
          etext:= nvl(substr(str1,typ+1,v_set-typ-1),'ID');
          v_hint := substr(str1,v_set+1);
          v_set:= instr(str1,':');
          v_props := substr(str1,1,v_set-1);
          str1:= substr(str1,v_set+1,typ-v_set-1);
          b := str1 like '@%';
          if b then
            str1 := substr(str1,2);
          end if;
          if str1 is null then
            str1 := v_props;
            if b then
              v_qual := '@'||etext;
              lib.correct_qual(v_props,v_qual);
            else
              v_qual := etext;
            end if;
            v_hint := null;
          else
            if str1='$$$.' then
              if b then
                v_qual := '@'||etext;
                lib.correct_qual(v_props,v_qual);
              else
                v_qual := etext;
              end if;
            else
              if b then
                str1 := '@'||str1;
              end if;
              v_set:= instr(str1,'.',-1);
              str2 := substr(str1,1,v_set-1);
              lib.correct_qual(v_props,str2);
              v_qual := str2||substr(str1,v_set)||etext;
              if substr(str1,length(str1),1)='@' then
                lib.correct_qual(v_props,v_qual);
              end if;
            end if;
            b := substr(etext,1,1)='%';
            if etext='%statename' then
              v_info.base_id := 'STATE';
              b := false;
            end if;
            if b or not v_info.elem_class_id is null and nvl(v_flags,'0')<>'2'
              or etext in ('ID','CLASS_ID','COLLECTION_ID','STATE_ID','ROWID','KEY')
            then
              v_hint := null;
            else
              v_set:= instr(v_hint,'*',-1);
              if v_set>2 then
                if v_flags='2' then null; else
                  v_info.elem_class_id := substr(v_hint,v_set+1);
                  v_flags:= substr(v_hint,1,1);
                end if;
                v_hint := substr(v_hint,2,v_set-2);
                v_set:= instr(p_next,TAB||'group by ');
                if v_set>0 then
                  typ := instr(p_next,TAB||'having ',v_set);
                  if typ=0 then
                    typ := length(p_next)+1;
                  end if;
                  if instr(substr(p_next,v_set,typ-v_set),v_hint)=0 then
                    v_hint:= null;
                  end if;
                end if;
              else
                v_hint := null;
              end if;
            end if;
          end if;
        end if;
        if str like 'REF$_%' then
          v_als:= str;
          str1 := substr(str,5);
          b := false;
        else
          v_idx := v_idx+1;
          if str like 'A$%' then
            if v_qual='ID' or v_qual like 'A$%' then
              v_als := check_alias(null,v_decl,v_idx);
            else
              v_als := check_alias('C_'||v_qual,v_decl,v_idx);
            end if;
            str := 'C$'||v_idx;
            plib.plp_warning(sel_idx,'ALIAS_GENERATE',v_als,v_idx,v_qual);
            if v_als<>str then
              update criteria_columns set alias=v_als
               where criteria_id=p_cr_id and alias=str and not exists
                 (select 1 from criteria_columns where criteria_id=p_cr_id and alias=v_als);
            end if;
          else
            v_als := check_alias(str,v_decl,v_idx);
          end if;
          b := true;
        end if;
        if v_props=v_class then null;
        else
          v_qual := v_props||':'||v_qual;
          if not str2 is null then
            str2 := v_props||':'||str2;
          end if;
        end if;
        if v_hint is null or str2 is null then
          v_nested := null;
        else
          v_nested := substr(v_qual,length(str2)+2);
        end if;
        fill_column_info(v_colinfo,v_als,bSort);
        begin
          if b then
            select target_class_id into str from criteria_columns
             where criteria_id=p_cr_id and alias=v_als;
          else
            if v_info.is_reference or v_info.is_collection then
              select target_class_id into str from criteria_columns
               where criteria_id=p_cr_id and alias=str1 and position<>0 and (ref_type is null or ref_type=v_flags);
            else
              raise no_data_found;
            end if;
          end if;
          if not v_colinfo.target_class_id is null then
            str := v_colinfo.target_class_id;
          end if;
          if str<>v_info.elem_class_id
            and (lib.is_parent(str,v_info.elem_class_id) or lib.is_parent(v_info.elem_class_id,str)) then
              v_info.elem_class_id := str;
          end if;
          if b then
-- zB exists
if v_info.elem_class_id='ROWID' then
   if v_info.base_id='OLE' then
      v_info.base_id := 'VARCHAR2';
      v_info.elem_class_id := '';
   end if;
end if;
            update criteria_columns set
                position = v_idx, data_source=str3, qual=v_qual,
                reference_id=v_hint, ref_qual=v_nested,
                ref_type=decode(ref_type,null,v_flags,'0',v_flags,'1',v_flags,'2',v_flags,ref_type),
                data_precision=nvl(v_colinfo.data_precision,decode(v_info.base_id,constant.GENERIC_NUMBER,
                    decode(base_class_id,constant.GENERIC_NUMBER,data_precision,v_info.data_precision),data_precision)),
                base_class_id=v_info.base_id, target_class_id=v_info.elem_class_id,
                name  = nvl(v_colinfo.name,name), align = nvl(v_colinfo.align,align),
                sizeable = nvl(v_colinfo.sizeable,sizeable),
                unvisible= nvl(v_colinfo.unvisible,unvisible),
                width = nvl(v_colinfo.width,width),
                order_by_pos = nvl(abs(v_colinfo.orderby),order_by_pos),
                order_by_type= decode(sign(v_colinfo.orderby),1,'A',-1,'D',order_by_type)
             where criteria_id=p_cr_id and alias=v_als;
          else
            update criteria_columns set
              reference_id=str3, target_class_id=v_info.elem_class_id, ref_type=v_flags
             where criteria_id=p_cr_id and alias=str1;
          end if;
        exception when no_data_found then
          if b then
            if not v_colinfo.name is null then
              str1 := v_colinfo.name;
            elsif not str1 is null then
              if substr(etext,1,1)='%' or etext in ('ID','CLASS_ID','COLLECTION_ID','STATE_ID','ROWID','KEY')
              then
                str1 := lib.qual_name(v_props,nvl(str2,' '),' # ')||' # '||etext;
              else
                str1 := lib.qual_name(v_props,v_qual,' # ');
              end if;
              str1 := substr(str1,1,64);
            end if;
            if str1 is null then
              str1 := message.gettext('PLP', 'COLUMN_NUMBER', v_idx);
            end if;
            if not v_colinfo.target_class_id is null then
              str := v_colinfo.target_class_id;
              if str<>v_info.elem_class_id
                and (lib.is_parent(str,v_info.elem_class_id) or lib.is_parent(v_info.elem_class_id,str)) then
                  v_info.elem_class_id := str;
              end if;
            end if;
            if v_colinfo.align is null then
              if v_info.base_id=constant.GENERIC_NUMBER then
                v_colinfo.align := '1';
              elsif v_info.base_id=constant.GENERIC_DATE then
                v_colinfo.align := '2';
              else
                v_colinfo.align := '0';
              end if;
            end if;
            if v_colinfo.width is null then
              v_colinfo.width := least(length(str1),30);
            end if;
            if v_colinfo.data_precision is null and v_info.base_id=constant.GENERIC_NUMBER then
              v_colinfo.data_precision := v_info.data_precision;
            end if;
-- zB exists
if v_info.elem_class_id='ROWID' then
   if v_info.base_id='OLE' then
      v_info.base_id := 'VARCHAR2';
      v_info.elem_class_id := '';
   end if;
end if;
            insert into criteria_columns(criteria_id,name,position,qual,data_source,alias,
                    base_class_id,target_class_id,width,data_precision,sizeable,unvisible,align,
                    reference_id,ref_type,ref_qual,order_by_pos,order_by_type)
            values (p_cr_id,str1,v_idx,v_qual,str3,v_als,v_info.base_id,v_info.elem_class_id,
                    v_colinfo.width,v_colinfo.data_precision,nvl(v_colinfo.sizeable,'1'),
                    nvl(v_colinfo.unvisible,'0'),v_colinfo.align,v_hint,v_flags,v_nested,
                    abs(v_colinfo.orderby),decode(sign(v_colinfo.orderby),1,'A',-1,'D',null));
          else
            plib.plp_warning(idx1,'NO_TABLE_COLUMN',v_als,v_crit);
          end if;
        end;
      end if;
      sel_idx := plib.ir(sel_idx).right;
      if not idx1 is null then
          idx1 := plib.ir(idx1).right;
      end if;
    end loop;
    delete criteria_columns where criteria_id=p_cr_id and position=0
       and nvl(alias,'X') not in ('ID','CLASS_ID','COLLECTION_ID','STATE_ID','NT$ID');
  end if;
  delete criteria_tries where criteria_id=p_cr_id;
  <<EXITING>>
  class_mgr.skip_changes(null,null);
  cur_nested := null;
  init(false);
  --plib.dump_ir(idx,0,0,false);
  crit_cols.delete;
  plib.ir.delete;
  v_decl.delete;
  sel_crit_tree.delete;
  idx := plib.plp$errors;
  if idx<>0 then
    idx := plib.plp$err_line-1;
    if idx>0 then
      idx := instr(p_text,NL,1,idx);
    else
      idx := 0;
    end if;
    idx := idx+plib.plp$err_pos-1;
    p_next := plib.plp$err_text;
  else
    p_text := dist;
  end if;
  return idx;
end criteria2plsql;
--
begin
--
    global_cache := upper(nvl(substr(rtl.setting('PLP_CACHE_OPTION'),1,1),'Y')) in ('Y','1');
    if global_cache then
      cache_class := upper(nvl(substr(rtl.setting('PLP_CACHE_CLASS'),1,1),'Y')) in ('Y','1');
    end if;
--
    plsql_reserved('SUM')  := null;
    plsql_reserved('USER') := null;
    plsql_reserved('COUNT'):= null;
    plsql_reserved('TIME') := null;
--
    calc_rtl('ABS') := null;
    calc_rtl('ASCII') := null;
    calc_rtl('BITAND') := null;
    calc_rtl('CEIL') := null;
    calc_rtl('FLOOR') := null;
    calc_rtl('INITCAP') := null;
    calc_rtl('INSTR') := null;
    calc_rtl('LENGTH') := null;
    calc_rtl('LOWER') := null;
    calc_rtl('LPAD') := null;
    calc_rtl('LTRIM') := null;
    calc_rtl('MOD') := null;
    calc_rtl('REPLACE') := null;
    calc_rtl('ROUND') := null;
    calc_rtl('RPAD') := null;
    calc_rtl('RTRIM') := null;
    calc_rtl('SIGN') := null;
    calc_rtl('SUBSTR') := null;
    calc_rtl('TO_CHAR') := null;
    calc_rtl('TO_NUMBER') := null;
    calc_rtl('TRANSLATE') := null;
    calc_rtl('TRIM') := null;
    calc_rtl('TRUNC') := null;
    calc_rtl('UPPER') := null;
--
    calc_rtl('RTL.BOOL_CHAR') := null;
    calc_rtl('RTL.BOOL_NUM') := null;
    calc_rtl('RTL.CHAR_BOOL') := null;
    calc_rtl('RTL.CLASS_PARENT') := null;
    calc_rtl('RTL.CLASS_ENTITY') := null;
    calc_rtl('RTL.SAFE_REPLACE') := null;
--
    calc_rtl('LIB.ATTR_NAME') := null;
    calc_rtl('LIB.CLASS_BASE') := null;
    calc_rtl('LIB.CLASS_NAME') := null;
    calc_rtl('LIB.CLASS_SIZE') := null;
    calc_rtl('LIB.CLASS_TABLE') := null;
    calc_rtl('LIB.SOFT_REPLACE') := null;
    calc_rtl('LIB.STATE_NAME') := null;
--
    init_counters;
end plp2plsql;
/
alter package plp2plsql compile body PLSQL_OPTIMIZE_LEVEL=0;
show errors package body plp2plsql
