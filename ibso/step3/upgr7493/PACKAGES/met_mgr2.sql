prompt method_mgr body
CREATE OR REPLACE package body
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/met_mgr2.sql $
 *  $Author: vasiltsov $
 *  $Revision: 114298 $
 *  $Date:: 2016-07-12 13:38:09 #$
 */
method_mgr is
--
LF  constant varchar2(1) := chr(10);
TB  constant varchar2(1) := chr(9);
AMP constant varchar2(1) := chr(38);
LF2 constant varchar2(2) := LF||LF;
TB2 constant varchar2(2) := TB||TB;
OBJ_NAME    constant  varchar2(1) := 'O'; --varchar2(10) := 'V$OBJ_ID';
CLS_NAME    constant  varchar2(1) := 'C'; --varchar2(10) := 'V$CLASS_ID';
MSG_NAME    constant  varchar2(1) := 'M'; --varchar2(10) := 'V$MESSAGE';
INF_NAME    constant  varchar2(1) := 'I'; --varchar2(10) := 'V$INFO';
DBG_NAME    constant  varchar2(1) := 'D'; --varchar2(10) := 'V$DEBUG';
LCK_NAME    constant  varchar2(1) := 'L'; --varchar2(10) := 'V$CLEAR';
STC_NAME    constant  varchar2(1) := 'F';
REQ_NAME    constant  varchar2(1) := 'Y';
KEY_NAME    constant  varchar2(1) := 'K';
AP_MODE_NAME    constant  varchar2(2) := 'AP';  -- переменная - использовать архивный пакет
SYS_NAME    constant  varchar2(8) := 'SYS_ID';
DATE_FORMAT constant  varchar2(20):= 'YYYYMMDDHH24MISS';
TIME_FORMAT constant  varchar2(20):= 'YYYYMMDDHH24MISS.FF9';
GEN_TABLE   constant  varchar2(20):= constant.GENERIC_TABLE||'.%';
VERSION     constant  varchar2(10):= '1.0';
--
START_CTLS  constant  pls_integer := 10;
DBOBJECT    constant  pls_integer := 0;
DBREF       constant  pls_integer := 1;
DBROW       constant  pls_integer := 2;
DBTABLE     constant  pls_integer := 3;
--
ERR_CTL_NOT_FOUND     constant  pls_integer := 1;
ERR_CTL_BAD_DEPEND    constant  pls_integer := 2;
ERR_CTL_BAD_CLASS     constant  pls_integer := 3;
ERR_CTL_GRID_EMPTY    constant  pls_integer := 4;
ERR_CTL_NO_PARAM      constant  pls_integer := 5;
ERR_CTL_BAD_QUAL      constant  pls_integer := 6;
ERR_CTL_BAD_ASSIGN    constant  pls_integer := 7;
ERR_CTL_BAD_COMPARE   constant  pls_integer := 8;
ERR_BND_OPERATOR      constant  pls_integer := -100;
ERR_BND_DEFVAL        constant  pls_integer := -200;
ERR_BND_IN_COLUMN     constant  pls_integer := -300;
ERR_BND_IN_TYPES      constant  pls_integer := -400;
--
--Текущий метод
current_method_id    varchar2(16);
current_method_form  varchar2(16);
current_method_class varchar2(16);
current_method_sname varchar2(16);
current_src_id       varchar2(16);
current_ext_id       varchar2(16);
current_add_form     varchar2(16);
current_method_flags varchar2(30);
current_arch_pack    varchar2(30);
current_method_pack  varchar2(30);
current_buffer_size  varchar2(30);
current_method_name  varchar2(128);
current_access_group varchar2(1);
current_belong_group varchar2(1);
current_method_result    varchar2(16);
current_method_interface varchar2(30);
current_mtd_logparams    varchar2(2);
current_mtd_archive      varchar2(1);
current_method_priority  pls_integer;
current_accessibility    pls_integer;
current_check_obj        pls_integer;
current_mtd_critical     boolean;
current_method_obj       boolean;
--
type par_var is record  (
     self        varchar2(16),
     class       varchar2(16),
     base        varchar2(30),
     name        varchar2(30),
     fname       varchar2(128),
     qual        varchar2(700),
     binds       varchar2(2000),
     defs        varchar2(2000),
     dir         varchar2(1),
     flag        varchar2(1),
     parent      pls_integer,
     grid        pls_integer,--maximov: for grids = -1; for gridcols = grid index
     colnum      pls_integer,--maximov: for grids = number of cols; for gridcols = col index
     kind        pls_integer,--DBOBJECT, DBROW, DBTABLE
     var_idx     pls_integer,--par/var reference
     err_code    pls_integer --error code (bad control if <>0)
                        );
type par_var_arr is table of par_var index by binary_integer;
type tBinds  is record  (
     left        pls_integer,
     right       pls_integer,
     cond        varchar2(10),
     lqual       varchar2(700),
     rqual       varchar2(700)
                        );
type tQuals is record (
     q varchar2(2000),
     cl varchar2(32),
     base varchar2(32),
     arr boolean);
type log_qual_arr is table of tQuals index by pls_integer;
quals log_qual_arr;
type tBinds_arr  is table of tBinds index by binary_integer;
--
compile_errors exception;
pragma exception_init(compile_errors,-24344);
--
par par_var_arr;   --Параметры метода
var par_var_arr;   --Переменные метода
ctl par_var_arr;   --Контролы формы метода
bnd tBinds_arr;    --Зависимости параметров-переменных
dep class_mgr.ref_tab;
ctl_count   pls_integer;
txt_buf     dbms_sql.varchar2s;
err_buf     varchar2(32500);
--
sys_str     varchar2(100) := message.gettext('MTD','SYSTEM');
this_str    varchar2(100) := message.gettext('MTD','THIS');
sc_logging  boolean := substr(nvl(rtl.setting('SCRIPTS_LOGGING'),'NO'),1,1) in ('Y','1');
-------------------------------------------------------------------------------------------
--
procedure drop_package_quietly(package_name in varchar2) is
begin
    execute immediate 'drop package ' || package_name;
exception when others then null;
end;
--
procedure drop_package_body_quietly(package_name in varchar2) is
begin
    execute immediate 'drop package body ' || package_name;
exception when others then null;
end;
--
procedure drop_method_interface_quietly(method_id_ varchar2) is
    v_package_name varchar2(20);
begin
    v_package_name := interface_package_name(method_id_);
    drop_package_quietly(v_package_name);
    drop_package_body_quietly(v_package_name);
end;
--
procedure create_method_interface$(method_id_ varchar2, p_error boolean);
function build_interface(method_id_ varchar2) return varchar2 is
    ok      boolean;
    s       varchar2(4000);
begin
    ok := false;
    for c in (
      select id from methods m
       where kernel='0' and id=method_id_ and
         ( flags = constant.METHOD_OPERATION
           or ext_id is not null or form_id is not null
           or flags not in ('A','L','T') and (
             exists (select 1 from controls where meth_id = m.id)
             or src_id is not null and (
               exists (select 1 from methods s where s.id = m.src_id and s.form_id is not null)
               or exists (select 1 from controls where meth_id = src_id)
             )
           )
         )
    ) loop
        ok:= true;
    end loop;
    if ok then
        begin
          create_method_interface$(method_id_,true);
        exception when others then
          if sqlcode in (-6508,-4061) then raise; end if;
          err_buf := message.error_stack;
        end;
        return err_buf;
    else
        drop_package_quietly(interface_package_name(method_id_));
        return message.get_text(constant.METH_ERROR,'NO_INTERFACE',method_id_);
    end if;
end;
-------------------------------------------------------------------------------------------
procedure gen_method_body$(p_class_id varchar2, p_method_id varchar2, p_method_type varchar2,
                           src_body in out nocopy varchar2, src_validate in out nocopy varchar2) is
    cursor ca is
        select position, name, attr_id, self_class_id
          from class_attributes where class_id in (
            select id from classes
             where base_class_id = constant.STRUCTURE
            connect by prior parent_id = id
             start with id = p_class_id )
        union
        select  1 position, null name, null attr_id, id self_class_id
          from classes
         where base_class_id<>constant.STRUCTURE and id=p_class_id
        order by 1
        ;
    npar integer;
    pardv varchar2(128);
    parsn varchar2(30);
    cnt integer;
    attr_base_class varchar2(16);
    add_param boolean;
BEGIN
    if p_method_type <> constant.METHOD_DELETE then
        npar := 0;
        for a in ca loop
            select base_class_id into attr_base_class from classes where id = a.self_class_id;
            add_param := attr_base_class<>constant.GENERIC_TABLE;
            if add_param and P_METHOD_TYPE=constant.METHOD_STATIC then
                add_param := attr_base_class not in (constant.COLLECTION, constant.STRUCTURE);
            end if;
            if add_param then
                npar := npar + 1;
                if a.attr_id is null then
                    parsn := 'P_VALUE';
                    pardv := '%THIS%. ';
                    a.name:= message.gettext(constant.METH_ERROR,'VALUE');
                else
                    parsn := class_mgr.make_valid_literal('P_' || a.attr_id);
                    pardv := '%THIS%.'||a.attr_id;
                end if;
                if P_METHOD_TYPE = constant.METHOD_STATIC then
                    pardv := null;
                end if;
                insert into method_parameters (
                    method_id, position, name, short_name, class_id,
                    defval, direction, changes, flag
                ) values (
                    p_method_id, npar, a.name, parsn, a.self_class_id,
                    pardv, 'I', '1', constant.RTL_DBOBJECT
                );
                if attr_base_class<>constant.COLLECTION then
                    src_body := src_body||TB||'-- '||message.gettext(constant.METH_ERROR,'SET_ATTR',a.name)||LF||TB;
                    if P_METHOD_TYPE = constant.METHOD_STATIC then
                      src_validate := src_validate || TB2 || '-- ' || message.gettext(constant.METH_ERROR,'SET_PARAM',a.name) || LF ||
                                      TB2 || parsn || ' := [' || p_class_id || ']::[' || a.attr_id || '];' || LF;
                      -- Обращение к статическим реквизитам
                      src_body := src_body || '[' ||p_class_id || ']::';
                    end if;
                    src_body := src_body || '[' || a.attr_id || '] := ' || parsn || ';' || LF;
                end if;
            end if;
        end loop;
        if not src_body is null then
            src_body := 'begin' || LF || src_body || 'end;' || LF;
        end if;
        if not src_validate is null then
            src_validate :=
                'begin' || LF ||
                TB||'if p_message = ''DEFAULT'' then' || LF ||
                src_validate ||
                TB||'end if;' || LF ||
                'end;' || LF;
        end if;
    end if;
end;
--
procedure gen_delegate_method_body$(p_class_id varchar2, p_method_id varchar2, p_delegate_id varchar2,
                                    src_body in out nocopy varchar2, src_validate in out nocopy varchar2) is
BEGIN
    insert into method_parameters (
        method_id, position, name, short_name, class_id,
        /*defval,*/ direction, changes, flag
    ) select
        p_method_id, a.position, a.name, a.short_name, a.class_id,
        /*a.defval,*/ a.direction, a.changes, a.flag
       from method_parameters a
      where method_id = p_delegate_id
    ;
    src_body :=
      TB||'v_this ref ['||p_class_id||'];'||LF||
      'begin'||LF||
      TB||'if this is not null then'||LF||
      TB2||'v_this := this;'||LF||
      TB2||AMP||'BASE$SETVARS;'||LF;
    src_validate := src_body||
      TB2||AMP||'BASE$VALIDATE(v_this);'||LF||
      TB2||AMP||'BASE$GETVARS;'||LF||
      TB||'end if;'||LF||
      'end;'||LF;
    src_body := src_body||
      TB2||'v_this := '||AMP||'BASE$EXECUTE(v_this);'||LF||
      TB||'end if;'||LF||
      'end;'||LF;
end;
--
function create_method(p_class_id varchar2, p_method_type varchar2, p_meth_sn varchar2, p_meth_nm varchar2, use_new varchar2 := null, use_new_meth_sn varchar2 := null) return varchar2 is -- @METAGS create_method
  v_method_id varchar2(16);
  v_form_id varchar2(16);
  v_delegate_method_id varchar2(16);
  v_user_driven varchar2(1);
  src_body varchar2(32000);
  src_validate varchar2(32000);
  add_param boolean;
  base_class varchar2(16);
  u_info  rtl.users_info;
  cnt integer;
  v_New_Auto varchar2(16);
  v_properties methods.properties%type;
BEGIN
    -- Проверим, нет ли уже такой операции
    select count(*) into cnt from methods
    where class_id = p_class_id
        and short_name = p_meth_sn;
    if cnt > 0 then return null; end if;
    if (p_meth_sn like 'EDIT_AUTO' or ltrim(use_new_meth_sn) is not null) and use_new = 'Y' then
        v_New_Auto := nvl(ltrim(use_new_meth_sn),'NEW_AUTO');
        begin
            select nvl(form_id, id), id, user_driven
                into v_form_id, v_delegate_method_id, v_user_driven
                from methods where class_id = p_class_id and short_name = v_New_Auto;
        exception when NO_DATA_FOUND then
            v_user_driven := '0';
        end;
    else
        v_user_driven := '0';
    end if;
    add_param := rtl.get_user_info(u_info);
  select base_class_id into base_class from classes where id = p_class_id;
  select seq_id.nextval into v_method_id from dual;

  /**
   * Для операций в типе с идентификацией по ROWID
   * убираем генерацию PL/SQL пакета
   */
  if lib.pk_is_rowid(p_class_id) then
      if length(plib.def_options) < 19 then
          method.put_property(v_properties, 'COMPILER', plib.def_options||'20');
      else
          method.put_property(v_properties, 'COMPILER', substr(plib.def_options, 1, 18) || '2' || substr(plib.def_options, 20));
      end if;
  end if;

  insert into methods (
    CLASS_ID,
    ID,
    SHORT_NAME,
    NAME,
    USER_DRIVEN,
    ACCESSIBILITY,
    RESULT_CLASS_ID,
        FLAGS,
        TEXT_TYPE,
        CREATED,
        USER_CREATED,
        MODIFIED,
        USER_MODIFIED,
        PROPERTIES,
        TAG,
        FORM_ID
    ) values (
        p_class_id,
        v_method_id,
        p_meth_sn,
        p_meth_nm,
        v_user_driven,
        '1',
        decode(p_method_type,constant.METHOD_NEW, p_class_id, NULL),
        p_method_type,
        method.PLPLUS_TEXT,
        sysdate,
        u_info.os_user,
        sysdate,
        u_info.os_user,
        v_properties,
        'CREATED',
        v_form_id
    );
    if v_form_id is null then
        gen_method_body$(p_class_id, v_method_id, p_method_type, src_body, src_validate);
    else
        gen_delegate_method_body$(p_class_id, v_method_id, v_delegate_method_id, src_body, src_validate);
    end if;
    -- Генерация метода
    declare
        res integer;
    begin
        method.set_source(v_method_id, 'VALIDATE', src_validate);
        method.set_source(v_method_id, 'EXECUTE', src_body);
        res := method.generate(v_method_id);
    end;
    return v_method_id;
end;
--
procedure create_default_methods(p_class_id varchar2) is
  id varchar2(16); cnt number;
begin
    id := create_method(p_class_id
                       ,constant.METHOD_NEW
                       ,'NEW_AUTO'
                       ,message.gettext(constant.METH_ERROR,'NEW'));
    id := create_method(p_class_id
                       ,constant.METHOD_USUAL
                       ,'EDIT_AUTO'
                       ,message.gettext(constant.METH_ERROR,'EDIT')
                       ,'Y'
                       ,'NEW_AUTO');
    id := create_method(p_class_id
                       ,constant.METHOD_DELETE
                       ,'DELETE_AUTO'
                       ,message.gettext(constant.METH_ERROR,'DELETE'));
    select count(1) into cnt from class_tab_columns
    where rownum=1 and class_id in
        (select parent_id from class_relations where child_id = p_class_id)
    and deleted = '0';
    if cnt > 0 then
        id := create_method(p_class_id
                           ,constant.METHOD_STATIC
                           ,'STATIC_AUTO'
                           ,message.gettext(constant.METH_ERROR,'STATIC'));
    end if;
end;
--
procedure copy_form(src_method_id varchar2, dst_method_id varchar2) is
    type id_corr is record (src varchar2(16), dst varchar2(16));
    type id_corr_list is table of id_corr index by binary_integer;
    ids id_corr_list;
    dst_parent_id varchar2(16);
    dst_depend_id varchar2(16);
    v_form  varchar2(16);
    v_caption varchar2(128);
begin
    select form_id into v_form from methods where id=src_method_id;
    delete controls where meth_id=dst_method_id;
    if not v_form is null then
        update methods set form_id=v_form where id=dst_method_id;
        return;
    end if;
    for c in (select id src_id, position from controls where meth_id = src_method_id order by position) loop
        ids(c.position).src := c.src_id;
        select seq_id.nextval into ids(c.position).dst from dual;
    end loop;
    for c in (select * from controls where meth_id = src_method_id order by position) loop
        dst_parent_id := null;
        dst_depend_id := null;
        if not c.depend is null then
            for n in ids.first .. ids.last loop
                begin
                    if ids(n).src = c.depend then
                        dst_depend_id := ids(n).dst; exit;
                    end if;
                exception
                    when no_data_found then null;
                end;
            end loop;
        end if;
        if not c.parent is null then
            for n in ids.first .. ids.last loop
                begin
                    if ids(n).src = c.parent then
                        dst_parent_id := ids(n).dst; exit;
                    end if;
                exception
                    when no_data_found then null;
                end;
            end loop;
        elsif v_caption is null and c.control='FORM' then
            v_caption := nvl(c.caption,src_method_id);
        end if;
        insert into controls (
            METH_ID, ID, QUALIFIER, CONTROL, TOP, LEFT, HEIGHT, WIDTH, CAPTION,
            PARENT, TAB_INDEX, PROPERTIES, CLASS_ID, DEPEND, TIPS, POSITION, VALIDATE_NAME, CRIT_ID, CRIT_ALIAS, CRIT_CLASS_ID)
        values (
            dst_method_id, ids(c.position).dst, c.QUALIFIER, c.CONTROL, c.TOP, c.LEFT, c.HEIGHT, c.WIDTH, c.CAPTION,
            dst_parent_id, c.TAB_INDEX, c.PROPERTIES, c.CLASS_ID, dst_depend_id, c.TIPS, c.POSITION, c.VALIDATE_NAME, c.CRIT_ID, c.CRIT_ALIAS, c.CRIT_CLASS_ID)
        ;
    end loop;
    if not v_caption is null then
        rtl.write_log('F','CREATE: '||v_caption,null,dst_method_id);
    end if;
end;
--
procedure overlap_method(p_class_id varchar2, p_short_name varchar2) is
    cursor cls(p_cls_id varchar2) is
        select * from classes
        connect by prior parent_id = id
        start with id = p_cls_id;
    cursor param(p_meth_id varchar2) is
        select * from method_parameters
        where method_id = p_meth_id;
    cnt integer;
    npar integer;
    v_parent_id Varchar2(16);
    v_par_meth_id Varchar2(16);
    v_method_id Varchar2(16);
    body varchar2(2000);
    b   boolean;
    u_info  rtl.users_info;
BEGIN
    select count(*) into cnt from methods where short_name = P_SHORT_NAME and class_id = P_CLASS_ID;
    if cnt <> 0 then
        message.sys_error(constant.KERNEL_ERROR,'METHOD_EXISTS',P_SHORT_NAME);
    end if;
    select parent_id into v_parent_id from classes where id = P_CLASS_ID;
    b := rtl.get_user_info(u_info);
    for c in cls(v_parent_id) loop
        select count(*) into cnt from methods where short_name = P_SHORT_NAME and class_id = c.id;
        if cnt = 1 then
            select id into v_par_meth_id from methods where short_name = P_SHORT_NAME and class_id = c.id;
            select seq_id.nextval into v_method_id from dual;
            insert into methods (
                    CLASS_ID,      ID,       SHORT_NAME, NAME, USER_DRIVEN,
                    ACCESSIBILITY, RESULT_CLASS_ID, FLAGS, TEXT_TYPE,
                    CREATED,USER_CREATED,MODIFIED,USER_MODIFIED,TAG
                )
                (select
                    P_CLASS_ID, v_method_id, SHORT_NAME, NAME, USER_DRIVEN, ACCESSIBILITY,
                    decode(FLAGS,constant.METHOD_NEW,P_CLASS_ID,RESULT_CLASS_ID),
                    FLAGS, TEXT_TYPE,sysdate,u_info.os_user,sysdate,u_info.os_user,'OVERLAPPED'
                from methods
                where id = v_par_meth_id
                )
            ;
            insert into method_parameters (
                    METHOD_ID, POSITION, NAME, SHORT_NAME, FLAG,
                    CLASS_ID, DEFVAL, DIRECTION, CHANGES, BINDINGS,
                    CRIT_FORMULA, CRIT_ID, CRIT_CLASS_ID
                )
                (select
                    v_method_id, POSITION, NAME, SHORT_NAME, FLAG,
                    CLASS_ID, DEFVAL, DIRECTION, CHANGES, BINDINGS,
                    CRIT_FORMULA, CRIT_ID, CRIT_CLASS_ID
                from method_parameters
                where method_id = v_par_meth_id
                )
            ;
            insert into method_variables (
                    METHOD_ID, POSITION, NAME, SHORT_NAME, FLAG,
                    CLASS_ID, DEFVAL, BINDINGS,
                    CRIT_FORMULA, CRIT_ID, CRIT_CLASS_ID
                )
                (select
                    v_method_id, POSITION, NAME, SHORT_NAME, FLAG,
                    CLASS_ID, DEFVAL, BINDINGS,
                    CRIT_FORMULA, CRIT_ID, CRIT_CLASS_ID
                from method_variables
                where method_id = v_par_meth_id
                )
            ;
            copy_form(v_par_meth_id, v_method_id);
            select count(*) into cnt from method_parameters where method_id = v_method_id;
            npar := 0;
            body := 'begin' || LF ||
                TB||'-- '|| message.gettext(constant.METH_ERROR,'PARENT') || LF ||
                TB||'[' || c.id || ']::[' || P_SHORT_NAME || ']';
            if cnt > 0 then
                body := body || ' (' || LF;
                for p in param(v_method_id) loop
                    npar := npar + 1;
                    body := body || TB2 || p.short_name;
                    if npar < cnt then
                        body := body || ',';
                    end if;
                    body := body || TB || '-- ' || p.name || LF;
                end loop;
                body := body || TB2 || ')';
            end if;
            body := body || ';' || LF || 'end;' || LF;
            -- Генерация метода
            declare
                res integer;
            begin
                method.set_source(v_method_id, 'VALIDATE', '');
                method.set_source(v_method_id, 'EXECUTE', body);
                res := method.generate(v_method_id);
                b := build_interface(v_method_id) is null;
                if res <> 0 then
                    message.sys_error(constant.EXEC_ERROR,'COMPILE_ERROR',res);
                end if;
            end;
            exit;
        end if;
    end loop;
end;
--
procedure copy_method( p_method_id  varchar2,
                       p_class_id   varchar2,
                       p_short_name varchar2,
                       p_name       varchar2,
                       p_new_id out varchar2,
                       p_compile    varchar2 default '0',
                       p_copy_form  varchar2 default '1',
                       p_copy_bindings varchar2 default '1',
                       p_id         varchar2 default null
                     ) is
BEGIN
    p_new_id:=copy_method(p_method_id,p_class_id,p_short_name,p_name,p_compile,p_copy_form,p_copy_bindings,p_id);
    commit;
END;
--
function copy_method( p_method_id  varchar2,
                      p_class_id   varchar2,
                      p_short_name varchar2,
                      p_name       varchar2,
                      p_compile    varchar2 default '0',
                      p_copy_form  varchar2 default '1',
                      p_copy_bindings varchar2 default '1',
                      p_id         varchar2 default null) return varchar2 IS
    cnt integer;
    v_method_id Varchar2(16) := p_id;
    v_props Varchar2(2000);
    CurFlag Varchar2(30);
    b   boolean;
    u_info  rtl.users_info;
BEGIN
    select count(*) into cnt from methods where short_name = p_short_name and class_id = p_class_id;
    if cnt <> 0 then
        message.sys_error(constant.KERNEL_ERROR,'METHOD_EXISTS',P_SHORT_NAME);
    end if;
    Select flags,properties into CurFlag,v_props from methods where id=p_method_id;
    if instr(CurFlag,constant.METHOD_ATTRIBUTE)>0 then
      CurFlag := constant.METHOD_USUAL;
    end if;
    method.put_property(v_props,'SYNONYM','|');
    method.put_property(v_props,'RTLBASE','|');
    if v_method_id is null then
      select seq_id.nextval into v_method_id from dual;
    end if;
    b := rtl.get_user_info(u_info);
    insert into methods (
            CLASS_ID,BODY_WHERE,     ID,       SHORT_NAME, NAME, USER_DRIVEN,
            ACCESSIBILITY, RESULT_CLASS_ID, FLAGS, TEXT_TYPE,
            FORMULA,PROPERTIES,ACCESS_GROUP,DEF_DESTRUCTOR,CHECK_METHOD,
            REPORT, REPORT_ON_PROC, REPORT_OBJECT, REPORT_TYPE,
            CREATED,USER_CREATED,MODIFIED,USER_MODIFIED,TAG,SCRIPT_ID
        )
        (select
            p_class_id,BODY_WHERE, v_method_id, p_short_name, p_name, USER_DRIVEN, ACCESSIBILITY,
            decode(FLAGS,constant.METHOD_NEW,P_CLASS_ID,RESULT_CLASS_ID),
            CurFlag, TEXT_TYPE, FORMULA,v_props,ACCESS_GROUP,DEF_DESTRUCTOR,CHECK_METHOD,
            REPORT, REPORT_ON_PROC, REPORT_OBJECT, REPORT_TYPE,
            sysdate,u_info.os_user,sysdate,u_info.os_user,'COPIED',
            decode(SCRIPT_ID,'SOURCES','SOURCES',null)
        from methods
        where id = p_method_id
        )
    ;
    insert into method_parameters (
            METHOD_ID, POSITION, NAME, SHORT_NAME, FLAG,
            CLASS_ID, DEFVAL, DIRECTION, CHANGES, BINDINGS,
            CRIT_FORMULA, CRIT_ID, CRIT_CLASS_ID
        )
        (select
            v_method_id, POSITION, NAME, SHORT_NAME, FLAG,
            CLASS_ID, DEFVAL, DIRECTION, CHANGES, decode(p_copy_bindings,'0', NULL, BINDINGS),
            CRIT_FORMULA, CRIT_ID, CRIT_CLASS_ID
        from method_parameters
        where method_id = p_method_id
        )
    ;
    insert into method_variables (
            METHOD_ID, POSITION, NAME, SHORT_NAME, FLAG,
            CLASS_ID, DEFVAL, BINDINGS,
            CRIT_FORMULA, CRIT_ID, CRIT_CLASS_ID
        )
        (select
            v_method_id, POSITION, NAME, SHORT_NAME, FLAG,
            CLASS_ID, DEFVAL,  decode(p_copy_bindings, '0', NULL, BINDINGS),
            CRIT_FORMULA, CRIT_ID, CRIT_CLASS_ID
        from method_variables
        where method_id = p_method_id
        )
    ;
    insert into sources (
            NAME, TYPE, LINE, TEXT
        )
        (select
            v_method_id, TYPE, LINE, TEXT
        from sources
        where NAME = p_method_id
        )
    ;
    if p_copy_form <> '0' then
        copy_form(p_method_id, v_method_id);
    end if;
  -----------------------Поддержка методов печати------------------------
  if instr(CurFlag,constant.METHOD_REPORT)>0 then
   INSERT INTO Report_Formula(Method_Id, Formula, Report_Name)
        (select v_method_id, Formula, Report_Name
        from Report_Formula
        where method_id = p_method_id
        );
   INSERT INTO Report_Param_Relations (Method_Id, Method_Param, Report_Param, Proc_Param, Report_Name)
        (select v_method_id, Method_Param, Report_Param, Proc_Param, Report_Name
        from Report_Param_Relations
        where method_id = p_method_id
        );
   INSERT INTO Report_Objects (Method_Id,Name,Type)
        (select v_method_id, Name, Type from Report_Objects where method_id = p_method_id);
  end if;
   ----------------------------------------------------------------------
    if p_compile <> '0' then
        b := method.generate(v_method_id) <> 0;
        b := build_interface(v_method_id) is null;
    end if;
    RETURN v_method_id;
end;
--

function set_extension$( p_method_id  varchar2,
                        p_ext_short_name varchar2,
                        p_ext_name   varchar2,
                        p_ext_id     varchar2 default null ) return varchar2 is
    v_new_id Varchar2(16);
    v_ext_id Varchar2(16);
    v_src_id Varchar2(16);
    v_res_id Varchar2(16);
    v_class  Varchar2(16);
    v_sname  Varchar2(16);
    v_name   Varchar2(128);
    v_Flag   Varchar2(30);
    v_exec   Varchar2(300);
    b   boolean;
    cnt pls_integer;
    u_info  rtl.users_info;
BEGIN
  select class_id,short_name,flags,ext_id,src_id,result_class_id,kernel
    into v_class,v_sname,v_flag,v_ext_id,v_src_id,v_res_id,v_new_id
    from methods where id=p_method_id;
  if v_flag in (constant.METHOD_LIBRARY,constant.METHOD_REPORT,constant.METHOD_PRINT,constant.METHOD_ATTRIBUTE) or v_new_id<>'0' then
    if not v_ext_id is null then
      update methods set ext_id=null where id=p_method_id;
      update methods set ext_id=null,src_id=null where id=v_ext_id;
      update method_parameters  set src_pos=null where method_id=v_ext_id and src_pos is not null;
      update method_variables   set src_pos=null where method_id=v_ext_id and src_pos is not null;
    end if;
    if not v_src_id is null then
      update methods set src_id=null where id=p_method_id;
      update method_parameters  set src_pos=null where method_id=p_method_id and src_pos is not null;
      update method_variables   set src_pos=null where method_id=p_method_id and src_pos is not null;
      update methods set ext_id=null,src_id=null where id=v_src_id;
      method.compile_referencing(v_src_id,p_compile=>false,p_commit=>false);
    end if;
    method.compile_referencing(p_method_id,p_compile=>false,p_commit=>false);
    return null;
  elsif not v_src_id is null then
    message.sys_error(constant.KERNEL_ERROR,'CANNOT_EXTEND_EXTENSION',v_class,v_sname);
  elsif not v_ext_id is null and (p_ext_id is null or v_ext_id<>p_ext_id) then
    update methods set ext_id=null,src_id=null where id=v_ext_id;
    update method_parameters  set src_pos=null where method_id=v_ext_id and src_pos is not null;
    update method_variables   set src_pos=null where method_id=v_ext_id and src_pos is not null;
    if p_ext_id is null then
      update methods set ext_id=null,src_id=null where id=p_method_id;
      method.compile_referencing(p_method_id,p_compile=>false,p_commit=>false);
      return null;
    end if;
    v_ext_id := null;
  end if;
  if not p_ext_id is null then
    begin
      select src_id,ext_id,class_id,short_name
        into v_src_id,v_exec,v_new_id,v_name
        from methods where id = p_ext_id;
      if not v_exec is null then
        message.sys_error(constant.KERNEL_ERROR,'CANNOT_EXTEND_BY_EXTENDED',v_class,v_sname,v_new_id,v_name);
      end if;
      if v_src_id<>p_method_id then
        message.sys_error(constant.KERNEL_ERROR,'CANNOT_EXTEND_BY_EXTENSION',v_class,v_sname,v_new_id,v_name);
      end if;
      if v_new_id<>v_class then
        message.sys_error(constant.KERNEL_ERROR,'CLASS_EXTENSION',v_new_id,v_name,v_class);
      end if;
      update methods set ext_id=p_ext_id where id=p_method_id;
      method.check_extension(p_ext_id,p_method_id);
      if p_ext_id=v_ext_id then null;
      else
        method.compile_referencing(p_ext_id,p_compile=>false,p_commit=>false);
        method.compile_referencing(p_method_id,p_compile=>false,p_commit=>false);
      end if;
      return p_ext_id;
    exception when no_data_found then null;
    end;
  end if;
  v_ext_id := p_ext_short_name;
  if v_ext_id is null then
    v_ext_id := substr(v_sname||'#E',1,16);
  end if;
  select count(*) into cnt from methods
   where short_name = v_ext_id and class_id = v_class;
  if cnt<>0 then
    message.sys_error(constant.KERNEL_ERROR,'METHOD_EXISTS',v_ext_id);
  end if;
  v_name := nvl(p_ext_name,v_ext_id);
  v_new_id := p_ext_id;
  v_src_id := p_method_id;
  if v_new_id is null then
    select seq_id.nextval into v_new_id from dual;
  end if;
  b := rtl.get_user_info(u_info);
  insert into methods (
          CLASS_ID,ID,SHORT_NAME, NAME, SRC_ID, USER_DRIVEN,
          ACCESSIBILITY, RESULT_CLASS_ID, FLAGS, TEXT_TYPE,
          PROPERTIES,ACCESS_GROUP,DEF_DESTRUCTOR,CHECK_METHOD,
          CREATED,USER_CREATED,MODIFIED,USER_MODIFIED,TAG
      )
      (select
          v_class,v_new_id,v_ext_id,v_name,v_src_id,USER_DRIVEN, ACCESSIBILITY,
          decode(FLAGS,constant.METHOD_NEW,v_class,RESULT_CLASS_ID),
          FLAGS, TEXT_TYPE, PROPERTIES,ACCESS_GROUP,DEF_DESTRUCTOR,CHECK_METHOD,
          sysdate,u_info.os_user,sysdate,u_info.os_user,'EXTENSION'
      from methods
      where id = p_method_id
      )
  ;
  insert into method_parameters (
          METHOD_ID, POSITION, SRC_POS, NAME, SHORT_NAME, FLAG,
          CLASS_ID, DEFVAL, DIRECTION, CHANGES, BINDINGS,
          CRIT_FORMULA, CRIT_ID, CRIT_CLASS_ID
      ) select
          v_new_id, p.POSITION, p.POSITION, p.NAME, p.SHORT_NAME, p.FLAG,
          p.CLASS_ID, p.DEFVAL, p.DIRECTION, p.CHANGES, p.BINDINGS,
          p.CRIT_FORMULA, p.CRIT_ID, p.CRIT_CLASS_ID
          from method_parameters p where method_id = p_method_id
      ;
  insert into method_variables (
          METHOD_ID, POSITION, SRC_POS, NAME, SHORT_NAME, FLAG,
          CLASS_ID, DEFVAL, BINDINGS,
          CRIT_FORMULA, CRIT_ID, CRIT_CLASS_ID
      ) select
          v_new_id, p.POSITION, p.POSITION, p.NAME, p.SHORT_NAME, p.FLAG,
          p.CLASS_ID, p.DEFVAL, p.BINDINGS,
          p.CRIT_FORMULA, p.CRIT_ID, p.CRIT_CLASS_ID
          from method_variables p where method_id = p_method_id
      ;
  v_exec := 'begin'||LF||TB||AMP||'BASE$SETVARS;'||LF||TB;
  if v_flag=constant.METHOD_TRIGGER then
    method.check_trigger_method(v_new_id);
  else
    method.set_source(v_new_id,method.VALIDATE_SECTION,
      v_exec||AMP||'BASE$VALIDATE;'||LF||TB||AMP||'BASE$GETVARS;'||LF||'end;'||LF);
    if not v_res_id is null and instr(v_flag,constant.METHOD_NEW)=0 then
      v_exec := v_exec||'return ';
    end if;
  end if;
  method.set_source(v_new_id,method.EXECUTE_SECTION,
    v_exec||AMP||'BASE$EXECUTE;'||LF||'end;'||LF);
  update methods set ext_id=v_new_id,src_id=null where id=p_method_id;
  method.compile_referencing(p_method_id,p_compile=>false,p_commit=>false);
  return v_new_id;
end set_extension$;


function set_extension( p_method_id  varchar2,
                        p_ext_short_name varchar2,
                        p_ext_name   varchar2,
                        p_ext_id     varchar2 default null,
                        p_standalone varchar2 default null ) return varchar2 is

is_new_ext boolean := p_ext_id is null;
ext_id varchar2(100) := p_ext_id;
is_standalone boolean;
BEGIN
  ext_id := set_extension$(p_method_id, p_ext_short_name, p_ext_name, p_ext_id);

  -- опция должна быть enabled
  -- проверка служит в основном для того, чтобы выпускать версии c не до конца готовыми фичами
  -- ну и для возможности лицензирвоания, понятно

  if opt_mgr.option_enabled(method.EXT_V2_OPTION) then
  -- есть поддержка
    null;
  else
    return ext_id;
  end if;

  -- при преобразовании в расширение существуюших операций а так же при импорте расширений
  -- режим генерации не меняем
  -- предполагаем, что клиент сначала превратит расширеие в UNION на тестовой схеме, после чего
  -- накатит на боевую. Накат на боевую схему с преобразованием типа расширения может привести
  -- к большим разрушениям

  if not is_new_ext then
    return ext_id;
  end if;

  if p_standalone is null then
  -- если режим создания не указан при вызове, то используем глобальную настройку
    is_standalone := substr(upper(nvl(rtl.setting('PLP_' || method.STANDALONE_EXTENSION_PROPERTY),'1')),1,1) in ('1','Y');
  else
    is_standalone := substr(upper(p_standalone),1,1) in ('1','Y');
  end if;

  if not is_standalone then
    method.set_property(ext_id, method.STANDALONE_EXTENSION_PROPERTY, '0');
  end if;

  return ext_id;
end set_extension;
-------------------------------------------------------------------------
------------------------ИНТЕРФЕЙСНЫЕ ПАКЕТЫ------------------------------
-------------------------------------------------------------------------
function  check_log(method_id_ varchar2) return boolean is
begin
    return security.check_log(method_id_);
end;
function interface_package_name(method_id_ varchar2) return varchar2 is
begin
    return 'Z$U$' || method_id_; --'Z$U$INTERFACE$' || method_id_;
end;
function par2var(method_id_ varchar2, position_ integer) return varchar2 is
begin
    return 'P' || position_; --'P_' || method_id_ || '_' || to_char(position_);
end;
function var2var(method_id_ varchar2, position_ integer) return varchar2 is
begin
    return 'V' || position_; --'V_' || method_id_ || '_' || to_char(position_);
end;
function validate_name(method_id_ varchar2, p_pack boolean default false) return varchar2 is
begin
    if p_pack then
        return interface_package_name(method_id_)||'.V'; --'.VALIDATE$'||method_id_;
    end if;
    return 'V'; --'VALIDATE$'||method_id_;
end;
function execute_name(method_id_ varchar2, p_pack boolean default false) return varchar2 is
begin
    if p_pack then
        return interface_package_name(method_id_)||'.E'; --'.EXECUTE$'||method_id_;
    end if;
    return 'E'; --'EXECUTE$'||method_id_;
end;
function result_name(method_id_ varchar2, p_pack boolean default false) return varchar2 is
begin
    if p_pack then
        return interface_package_name(method_id_)||'.R'; --'.RESULT$'||method_id_;
    end if;
    return 'R'; --'RESULT$'||method_id_;
end;
function zap_param_name(method_id_ varchar2, p_pack boolean default false) return varchar2 is
begin
    if p_pack then
        return interface_package_name(method_id_)||'.Z'; --'.ZAP$PARAM$'||method_id_;
    end if;
    return 'Z'; --'ZAP$PARAM$'||method_id_;
end;
function log_param_name(method_id_ varchar2, p_pack boolean default false) return varchar2 is
begin
    if p_pack then
        return interface_package_name(method_id_)||'.W'; --'.LOG$PARAM$'||method_id_;
    end if;
    return 'W'; --'LOG$PARAM$'||method_id_;
end;
function set_param_name(method_id_ varchar2, p_pack boolean default false) return varchar2 is
begin
    if p_pack then
        return interface_package_name(method_id_)||'.S'; --'.SET$PARAM$'||method_id_;
    end if;
    return 'S'; --'SET$PARAM$'||method_id_;
end;
function get_param_name(method_id_ varchar2, p_pack boolean default false) return varchar2 is
begin
    if p_pack then
        return interface_package_name(method_id_)||'.G'; --'.GET$PARAM$'||method_id_;
    end if;
    return 'G'; --'GET$PARAM$'||method_id_;
end;
function get_param_qual(method_id_ varchar2, p_pack boolean default false) return varchar2 is
begin
    if p_pack then
        return interface_package_name(method_id_)||'.Q'; --'.GET$PARAM$'||method_id_;
    end if;
    return 'Q'; --'GET$PARAM$'||method_id_;
end;
function process_name(method_id_ varchar2, p_pack boolean default false) return varchar2 is
begin
    if p_pack then
        return interface_package_name(method_id_)||'.P'; --'.PROCESS$'||method_id_;
    end if;
    return 'P'; --'PROCESS$'||method_id_;
end;
function chk_controls_name(method_id_ varchar2, p_pack boolean default false) return varchar2 is
begin
    if p_pack then
        return interface_package_name(method_id_)||'.A';
    end if;
    return 'A';
end;
function get_controls_name(method_id_ varchar2, p_pack boolean default false) return varchar2 is
begin
    if p_pack then
        return interface_package_name(method_id_)||'.B';
    end if;
    return 'B';
end;
function var_obj_name(method_id_ varchar2 default null) return varchar2 is
begin
    if method_id_ is null then
      return OBJ_NAME;
    end if;
    return interface_package_name(method_id_)||'.'||OBJ_NAME;
end;
function var_cls_name(method_id_ varchar2 default null) return varchar2 is
begin
    if method_id_ is null then
      return CLS_NAME;
    end if;
    return interface_package_name(method_id_)||'.'||CLS_NAME;
end;
function var_msg_name(method_id_ varchar2 default null) return varchar2 is
begin
    if method_id_ is null then
      return MSG_NAME;
    end if;
    return interface_package_name(method_id_)||'.'||MSG_NAME;
end;
function var_inf_name(method_id_ varchar2 default null) return varchar2 is
begin
    if method_id_ is null then
      return INF_NAME;
    end if;
    return interface_package_name(method_id_)||'.'||INF_NAME;
end;
function var_dbg_name(method_id_ varchar2 default null) return varchar2 is
begin
    if method_id_ is null then
      return DBG_NAME;
    end if;
    return interface_package_name(method_id_)||'.'||DBG_NAME;
end;
function var_lck_name(method_id_ varchar2 default null) return varchar2 is
begin
    if method_id_ is null then
      return LCK_NAME;
    end if;
    return interface_package_name(method_id_)||'.'||LCK_NAME;
end;
function class2type(class_ varchar2, flag_ varchar2, package_ varchar2) return varchar2 is
begin
    if flag_ = constant.RTL_REFERENCE then
        if lib.has_stringkey(class_) then
            return 'VARCHAR2('||constant.REF_PREC||')';
        end if;
        return 'NUMBER';
    elsif flag_ = constant.RTL_TABLE then
        return package_||'.'||class_mgr.make_valid_literal(class_||'_TABLE');
    elsif flag_ = constant.RTL_COLLECTION then
        return package_||'.'||class_mgr.make_valid_literal(class_||'_TBLROW');
    elsif flag_ = constant.RTL_DBTABLE then
        return class_mgr.interface_package(class_)||'.'||class_mgr.make_record_tables(class_);
    else
        return plp2plsql.class2plsql(class_,true,null,flag_=constant.RTL_DBROW);
    end if;
end;
--
procedure fill_class(p_class varchar2,p_base out nocopy varchar2, p_target out nocopy varchar2) is
    v_class lib.class_info_t;
begin
  if lib.class_exist(p_class,v_class) then
    p_base := v_class.base_class_id;
    p_target := nvl(v_class.class_ref,p_class);
  end if;
end;
--
procedure get_def_qual(p_class varchar2, p_qual out nocopy varchar2, --@METAGS get_def_attr
                       p_self  out nocopy varchar2, p_base out nocopy varchar2,
                       p_targ  out nocopy varchar2, p_kern out nocopy varchar2,
                       p_owner in out nocopy varchar2) is
  v_class lib.class_info_t;
  v_attr  lib.attr_info_t;
  v_qual  varchar2(1000);
begin
  if lib.find_def_attr(p_class,v_attr,v_class,true) > 0 then
    if v_class.base_id = constant.STRUCTURE then
      v_qual := lib.get_def_qual(v_attr.self_class_id,v_class,true);
      if v_qual is not null then
        v_qual := v_attr.attr_id||'.'||v_qual;
      end if;
    else
      v_qual := v_attr.attr_id;
    end if;
  end if;
  if v_qual is null then
    p_owner := null;
  else
    p_owner:= v_attr.class_id;
    p_qual := v_qual;
    p_self := v_class.class_id;
    p_base := v_class.base_class_id;
    p_targ := v_class.class_ref;
    if v_class.kernel then
      p_kern := '1';
    else
      p_kern := '0';
    end if;
  end if;
end;
--
procedure get_def_attr(p_class varchar2, p_qual out nocopy varchar2, --@METAGS get_def_attr
                       p_self  out nocopy varchar2, p_base out nocopy varchar2) is
    v_attr lib.class_info_t;
begin
    p_qual := lib.get_def_qual(p_class,v_attr,true);
    p_self := v_attr.class_id;
    p_base := v_attr.base_class_id;
end;
--
function get_err_code(p_code pls_integer) return varchar2 is
begin
  if p_code=ERR_CTL_NOT_FOUND then
    return 'ERR_CTL_NOT_FOUND';
  elsif p_code=ERR_CTL_BAD_DEPEND then
    return 'ERR_CTL_BAD_DEPEND';
  elsif p_code=ERR_CTL_BAD_CLASS then
    return 'ERR_CTL_BAD_CLASS';
  elsif p_code=ERR_CTL_GRID_EMPTY then
    return 'ERR_CTL_GRID_EMPTY';
  elsif p_code=ERR_CTL_NO_PARAM then
    return 'ERR_CTL_NO_PARAM';
  elsif p_code=ERR_CTL_BAD_QUAL then
    return 'ERR_CTL_BAD_QUAL';
  elsif p_code=ERR_CTL_BAD_ASSIGN then
    return 'ERR_CTL_BAD_ASSIGN';
  elsif p_code=ERR_CTL_BAD_COMPARE then
    return 'ERR_CTL_BAD_COMPARE';
  elsif p_code=ERR_BND_OPERATOR then
    return 'ERR_BND_OPERATOR';
  elsif p_code=ERR_BND_DEFVAL then
    return 'ERR_BND_DEFVAL';
  elsif p_code=ERR_BND_IN_COLUMN then
    return 'ERR_BND_IN_COLUMN';
  elsif p_code=ERR_BND_IN_TYPES then
    return 'ERR_BND_IN_TYPES';
  end if;
  return null;
end;
--
procedure add_pars is --@METAGS add_pars
    buf par_var;
    q "CONSTANT".varchar2_table;
    t "CONSTANT".refstring_table;
    i pls_integer:=0;
    j pls_integer;
    s varchar2(2000);
begin
    par.delete;var.delete;quals.delete;
    for c in (
            select '1' typ,class_id,short_name,name,flag,position,defval,bindings,direction
              from method_parameters where method_id = current_method_id
            UNION ALL
            select '0' typ,class_id,short_name,name,flag,position,defval,bindings,'B'
              from method_variables where method_id = current_method_id
             )
    loop
        buf.qual := upper(c.short_name);
        buf.fname:= c.name;
        buf.kind := DBOBJECT;
        buf.self := c.class_id;
        buf.binds:= c.bindings;
        buf.defs := c.defval;
        buf.dir  := c.direction;
        buf.flag := c.flag;
        if c.flag=constant.RTL_REFERENCE then
          buf.base := constant.REFERENCE;
          buf.class:= c.class_id;
          buf.kind := DBREF;
        else
          fill_class(buf.self,buf.base,buf.class);
          if c.flag=constant.RTL_DBROW then
            buf.kind := DBROW;
          elsif c.flag=constant.RTL_DBTABLE then
            buf.base  := constant.GENERIC_TABLE||'.'||buf.base;
            buf.kind  := DBTABLE;
          elsif c.flag=constant.RTL_COLLECTION then
            buf.base  := constant.GENERIC_TABLE||'.'||buf.base;
            buf.kind  := DBROW;
          elsif c.flag=constant.RTL_TABLE then
            buf.base  := constant.GENERIC_TABLE||'.'||buf.base;
          end if;
        end if;
        if c.typ='1' then
            buf.name := par2var(current_method_id,c.position);
            par(c.position) := buf;
            s:= 'P';
        else
            buf.name := var2var(current_method_id,c.position);
            var(c.position) := buf;
            s:= 'V';
        end if;
        if sc_logging then
          s:= s||c.position;
          if buf.base in (constant.COLLECTION,'REFERENCE','BOOLEAN','NUMBER','MEMO','DATE','STRING') then
            i:= i+1;
            quals(i).q:= case when c.typ='0' then '%VAR%.' end ||
                       buf.qual||';'||s;
            quals(i).arr:= buf.base=constant.COLLECTION;
            quals(i).cl:= buf.self;
            quals(i).base:= buf.base;
          elsif buf.base='STRUCTURE' then
            s:= s || '.';
            lib.get_fields(q,t,buf.class,true,8);
            j:= q.first;
            while not j is null loop
              if j>0 and lib.class_base(t(j)) not in ('OLE','TABLE') then
                s:= replace(s || substr(q(j),instr(q(j),'.')+1), '.','.A#');
                if t(j)='BOOLSTRING' then
                  t(j):= 'BOOLEAN';
                end if;
                i:= i+1;
                quals(i).base:= lib.class_base(t(j));
                quals(i).arr:= quals(i).base=constant.COLLECTION;
                quals(i).q:= case when c.typ='0' then '%VAR%.' end ||
                           buf.qual || '.' || substr(q(j),instr(q(j),'.')+1)||';'||s;
                quals(i).cl:= t(j);
                s:= substr(s,1,instr(s,'.'));
              end if;
              j:= q.next(j);
            end loop;
          end if;
        end if;
    end loop;
end add_pars;
--
function chk_class(p_var par_var) return boolean is
    v_base  varchar2(16) := p_var.base;
    v_cls   varchar2(16) := p_var.class;
begin
    if v_base like GEN_TABLE then
        v_base := substr(v_base,instr(v_base,'.')+1);
    end if;
    if v_base=constant.OLE then
        return not lib.is_kernel(v_cls);
    elsif v_base=constant.GENERIC_TABLE then
        return false;
    end if;
    return true;
end;
--
procedure add_ctls is --@METAGS add_ctls
    ct      par_var;
    xlat_   "CONSTANT".integer_table; --Трансляция для отслеживания зависимостей
    i       pls_integer := START_CTLS;
  procedure select_controls(p_form varchar2,p_offset pls_integer) is
  begin
    for c in (
        select control, qualifier, depend, class_id, position, parent--maximov
          from controls
         where meth_id = p_form and class_id is not null
           and control in ('ARRAY','CHECK','DATE','DEPEND','MEMO','NUMBER',
                'OBJECT','OLE','TEXT','VARIANT','BTNOLE','LABEL','TABLE',
                'GRID','GRIDCOL')--maximov
         order by position
             )
    loop
        ct.parent := null;
        if not c.depend is null then
            select position into ct.parent
              from controls where id = c.depend;
            ct.parent := ct.parent+p_offset;
        elsif instr(c.qualifier,'%THIS%.')=1 then
            ct.parent := -1;
        elsif instr(c.qualifier,'%SYSTEM%.')=1 then
            xlat_(0) := 0;
            ct.parent := 0;
        end if;
        i := i+1;
        xlat_(c.position+p_offset) := i; --Трансляция для отслеживания зависимостей
        ct.qual := upper(c.qualifier);
        ct.name := 'CT('||i||')';
        ct.self := c.class_id;
        fill_class(ct.self,ct.base,ct.class);
        if c.control='TABLE' then
            ct.base  := constant.GENERIC_TABLE||'.'||ct.base;
        elsif c.control in ('OBJECT','LABEL') then
            ct.base  := constant.REFERENCE;
        end if;
        if    c.control = 'GRID' then
          ct.grid := -1;
          ct.colnum := 0;
        elsif c.control = 'GRIDCOL' then
          select position into ct.grid from controls where id = c.parent;
          ct.grid := ct.grid+p_offset;
        else
          ct.grid := null;
          ct.colnum := null;
        end if;
        ctl(i) := ct;
    end loop;
  end;
begin
    ctl.delete; dep.delete;
    ct.kind := DBOBJECT;
    ct.err_code := 0;
    if not current_method_result is null then
        ct.self := current_method_result;
        if current_method_flags = constant.METHOD_NEW then
            ct.base := constant.REFERENCE;
            ct.class:= current_method_result;
        else
            fill_class(ct.self,ct.base,ct.class);
        end if;
        if ct.base<>constant.STRUCTURE then
            ct.qual := '%RESULT%';
            ct.name := result_name(current_method_id);
            ctl(i):=ct;
        end if;
    end if;
--
    ct.qual := '%THIS%';
    ct.name := OBJ_NAME;
    ct.base := constant.REFERENCE;
    ct.self := current_method_class;
    ct.class:= current_method_class;
    ctl(1) := ct;
--
    ct.qual := '%MESSAGE%';
    ct.name := MSG_NAME;
    ct.base := constant.GENERIC_STRING;
    ct.self := constant.GENERIC_STRING;
    ct.class:= constant.GENERIC_STRING;
    ctl(2) := ct;
--
    ct.qual := '%INFO%';
    ct.name := INF_NAME;
    ct.base := constant.GENERIC_STRING;
    ct.self := constant.GENERIC_STRING;
    ct.class:= constant.GENERIC_STRING;
    ctl(3) := ct;
--
/*    ct.qual := '%CLASS%';
    ct.name := CLS_NAME;
    ct.base := constant.GENERIC_STRING;
    ct.class:= constant.GENERIC_STRING;
    ctl(4) := ct;
--
    ct.qual := '%DEBUG%';
    ct.name := DBG_NAME;
    ct.base := constant.GENERIC_NUMBER;
    ct.class:= constant.GENERIC_NUMBER;
    ctl(5) := ct;
--
    ct.qual := '%CLEAR%';
    ct.name := LCK_NAME;
    ct.base := constant.GENERIC_BOOLEAN;
    ct.class:= constant.GENERIC_BOOLEAN;
    ctl(6) := ct;
--
    ct.qual := '%STAT%';
    ct.name := STC_NAME;
    ct.base := constant.GENERIC_NUMBER;
    ct.class:= constant.GENERIC_NUMBER;
    ctl(7) := ct;*/
--
    xlat_(-1) := 1;
    select_controls(current_method_form,0);
    if not current_add_form is null then
      select_controls(current_add_form,1000000);
    end if;
    if xlat_.exists(0) then
        ct.parent := null;
        ct.qual := '%SYSTEM%';
        ct.name := SYS_NAME;
        ct.base := constant.REFERENCE;
        ct.self := constant.SYSTEM;
        ct.class:= constant.SYSTEM;
        ctl(0) := ct;
    end if;
    --Расстановка
    ctl_count := i;
    for j in START_CTLS+1..ctl_count loop
        if ctl(j).grid >= 0 then
          i := ctl(j).grid;
          if xlat_.exists(i) then
            i := xlat_(i);
            if ctl(i).grid = -1 then
              ctl(j).grid := i;
              ctl(i).colnum := ctl(i).colnum + 1;
              ctl(j).colnum := ctl(i).colnum;
            else
              ctl(j).err_code := ERR_CTL_NOT_FOUND;--column references non grid control?
            end if;
          else
            ctl(j).err_code := ERR_CTL_NOT_FOUND;--control not found?
          end if;
        end if;
        if ctl(j).err_code=0 then
          ct := ctl(j);
          if not ct.parent is null then
            i := ct.parent;
            if xlat_.exists(i) then
              i := xlat_(i);
              if instr(ct.qual,ctl(i).qual||'.')=1 then
                null;
              else
                ct.self := ctl(i).class;
                fill_class(ct.self,ct.base,ct.class);
                if ct.base=constant.STRUCTURE then
                    ct.self := ct.class;
                    get_def_attr(ct.self,ct.qual,ct.class,ct.base);
                    if ct.qual is null then
                      ct.self := ctl(i).class;
                    end if;
                    fill_class(ct.self,ct.base,ct.class);
                end if;
                ct.qual := ctl(i).qual||'.'||nvl(ct.qual,' ');
              end if;
              if ct.qual is null then
                ctl(j).err_code := ERR_CTL_BAD_DEPEND;
              else
                ct.parent := i;
                if dep.exists(i) then
                    dep(i) := dep(i)||j||',';
                else
                    dep(i) := j||',';
                end if;
                ctl(j) := ct;
              end if;
            else
              ctl(j).err_code := ERR_CTL_NOT_FOUND;--control not found?
            end if;
          end if;
          if ctl(j).err_code=0 then
            if chk_class(ct) then
              ctl(j) := ct;
            else
              ctl(j).err_code := ERR_CTL_BAD_CLASS;
            end if;
          end if;
        end if;
    end loop;
    for j in START_CTLS+1..ctl.last loop
      if ctl(j).err_code=0 and ctl(j).grid = -1 and ctl(j).colnum = 0 then
        ctl(j).err_code := ERR_CTL_GRID_EMPTY;--delete grids without any columns
      end if;
    end loop;
    xlat_.delete;
end add_ctls;
--
function qual2var_idx(arr in par_var_arr, qual_ in varchar2) return pls_integer is --@METAGS qual2var_idx
    i   pls_integer;
    txt varchar2(100);
begin
    i := instr(qual_,'.');
    if i>0 then
        txt := substr(qual_,1,i-1);
    else
        txt := qual_;
    end if;
    i := arr.first;
    while not i is null loop
        if arr(i).qual = txt then return i; end if;
        i := arr.next(i);
    end loop;
    return null;
end;
--
function get_class(p_qual varchar2, p_var in out nocopy par_var, p_ref in out nocopy varchar2) return boolean is
    v_targ  varchar2(16);
begin
  p_ref := null;
  if lib.qualprop(p_var.class,p_qual,p_var.self,p_var.base,v_targ,p_ref,null) is null then
    if p_var.base in (constant.REFERENCE,constant.COLLECTION) and not v_targ is null then
      p_var.class := v_targ;
    else
      p_var.class := p_var.self;
    end if;
    return true;
  end if;
  return false;
end;
--
procedure add_binds is
    i   pls_integer;
    j   pls_integer;
    idx pls_integer;
    cnt pls_integer := 0;
    err pls_integer;
    b   boolean;
    bs  boolean;
    typ boolean;
    buf tBinds;
    c   par_var;
    lft par_var;
    rht par_var;
    nam varchar2(30);
    empty   par_var;
    qual    varchar2(700);
    qref    varchar2(700);
    procedure get_bind(p_bind varchar2) is
        ii  pls_integer;
        jj  pls_integer;
    begin
        jj:= instr(p_bind,'|',i);
        ii:= instr(p_bind,' ',jj+1);
        b := true; bs := false;
        if ii>jj and jj>0 then
          buf := null;
          buf.cond := substr(p_bind,jj+1,ii-jj-1);
          jj:= instr(p_bind,' ',ii+1);
          j := instr(p_bind,'|',jj+1);
          if jj>0 then
            if j>jj then
              i := j;
            else
              i := length(p_bind)+1;
            end if;
            lft := empty;
            rht := empty;
            lft.qual := upper(substr(p_bind,ii+1,jj-ii-1));
            rht.qual := upper(substr(p_bind,jj+1, i-jj-1));
            if substr(rht.qual,1,5)='%RTF%' then
              return;
            end if;
            b := false;
          end if;
        end if;
    end;
    procedure add_ctl(p_var in out nocopy par_var) is
        ii  pls_integer;
        jj  pls_integer := 0;
        ct  pls_integer;
    begin
        ct := ctl.next(START_CTLS);
        qual := p_var.qual;
        if not p_var.var_idx is null then
          p_var.qual := substr(qual,instr(qual,'.')+1);
        end if;
        if not ct is null then
          while not ct is null loop
            if ctl(ct).var_idx is null then
              if qual=ctl(ct).qual then
                j := ct;
                if not p_var.fname is null then
                  ctl(j).fname := p_var.fname;
                end if;
                return;
              elsif instr(qual,ctl(ct).qual||'.')=1 then
                ii:= length(ctl(ct).qual);
                if jj<ii then
                  p_var.parent := ct;
                  jj := ii;
                end if;
              end if;
            elsif ctl(ct).var_idx=p_var.var_idx then
              if p_var.qual=ctl(ct).qual then
                j := ct;
                if not p_var.fname is null then
                  ctl(j).fname := p_var.fname;
                end if;
                return;
              elsif instr(p_var.qual,ctl(ct).qual||'.')=1 then
                ii:= length(ctl(ct).qual);
                if jj<ii then
                  p_var.parent := ct;
                  jj := ii;
                end if;
              end if;
            end if;
            ct := ctl.next(ct);
          end loop;
          ct := ctl.last;
        else
          ct := START_CTLS;
        end if;
        j := ct+1;
        p_var.name:= 'CT('||j||')';
        jj := p_var.parent;
        if not jj is null then
          if dep.exists(jj) then
            dep(jj) := dep(jj)||j||',';
          else
            dep(jj) := j||',';
          end if;
        end if;
        ctl(j) := p_var;
    end;
begin
    bnd.delete;
    empty.kind := DBOBJECT;
    empty.err_code := 0;
    idx := 0; typ := true;
    loop
      if typ then
        idx := par.next(idx);
        if idx is null then
          typ := false;
          idx := 0;
        else
          c := par(idx);
        end if;
      end if;
      if not typ then
        idx := -var.next(-idx);
        exit when idx is null;
        c := var(-idx);
      end if;
      if not c.binds is null and c.flag in (constant.RTL_DBOBJECT,constant.RTL_REFERENCE,constant.RTL_DBROW) then
        i := 1;
        loop
          get_bind(c.binds);
          exit when b;
          b := buf.cond in ('DEF','EQ','EQN','NEQ','LIKE','GT','GEQ','LT','LEQ','IN');
          err := 0;
          if b then
            b := lft.qual like c.qual||'.%';
            if c.qual=lft.qual or b then
              lft.base := c.base;
              lft.self := c.self;
              lft.class:= c.class;
              lft.var_idx := idx;
              if b then
                qual := substr(lft.qual,instr(lft.qual,'.')+1);
                b := get_class(qual,lft,buf.lqual);
              else
                b := true;
              end if;
              if b then
                b:=chk_class(lft);
                if not b then
                  lft.err_code := ERR_CTL_BAD_CLASS;
                end if;
              else
                lft.err_code := ERR_CTL_BAD_QUAL;
              end if;
            else
              lft.err_code := ERR_CTL_NO_PARAM;
            end if;
          else
            err := ERR_BND_OPERATOR;
          end if;
          if b then
            if typ then
              lft.qual := '%PARAM%.'||lft.qual;
            else
              lft.qual := '%VAR%.'||lft.qual;
            end if;
            qual := rht.qual;
            if instr(qual,'%THIS%.')=1 then
              if buf.cond='DEF' and qual=c.defs then
                b := false;
                err := ERR_BND_DEFVAL;
              else
                qual := substr(qual,8);
                rht.base := constant.REFERENCE;
                rht.self := current_method_class;
                rht.class:= current_method_class;
                rht.parent := 1;
              end if;
            elsif instr(qual,'%SYSTEM%.')=1 then
              if buf.cond='DEF' and qual=c.defs then
                b := false;
                err := ERR_BND_DEFVAL;
              else
                qual := substr(qual,10);
                rht.base := constant.REFERENCE;
                rht.self := constant.SYSTEM;
                rht.class:= constant.SYSTEM;
                rht.parent := 0;
                bs := true;
              end if;
            else
              b := false;
              if instr(qual,'%PARAM%.')=1 then
                qual := substr(qual,9);
                j := qual2var_idx(par,qual);
                b := not j is null;
                if b then
                  rht.base := par(j).base;
                  rht.self := par(j).self;
                  rht.class:= par(j).class;
                  rht.var_idx := j;
                end if;
              elsif instr(qual,'%VAR%.')=1 then
                qual := substr(qual,7);
                j := qual2var_idx(var,qual);
                b := not j is null;
                if b then
                  rht.base := var(j).base;
                  rht.self := var(j).self;
                  rht.class:= var(j).class;
                  rht.var_idx := -j;
                end if;
              end if;
              if b then
                j := instr(qual,'.');
                if j>0 then
                  qual := substr(qual,j+1);
                else
                  qual := null;
                end if;
              else
                rht.err_code := ERR_CTL_NO_PARAM;
              end if;
            end if;
            if b then
              if b and not qual is null then
                b := get_class(qual,rht,buf.rqual);
              end if;
              if b then
                b:=chk_class(rht);
                if not b then
                  rht.err_code := ERR_CTL_BAD_CLASS;
                end if;
              else
                rht.err_code := ERR_CTL_BAD_QUAL;
              end if;
            end if;
          end if;
          if b and buf.cond='IN' then
            lib.qual_column(rht.class,'COLLECTION_ID',rht.fname,nam,qual,'2');
            b := lft.base=constant.REFERENCE and rht.base=constant.COLLECTION and not nam is null;
            if b then
              rht.fname := rht.fname||'.'||qual;
              b := lib.is_parent(lft.class,rht.class) or lib.is_parent(rht.class,lft.class);
              if b then null; else
                fill_class(rht.class,nam,qual);
                b := nam=constant.REFERENCE and (lib.is_parent(lft.class,qual) or lib.is_parent(qual,lft.class));
                if b then
                  lft.fname := 'REF@'||rht.class;
                else
                  err := ERR_BND_IN_TYPES;
                end if;
              end if;
            else
              err := ERR_BND_IN_COLUMN;
            end if;
          end if;
          if b then
            add_ctl(lft);
            buf.left := j;
            add_ctl(rht);
            buf.right:= j;
            if bs and not ctl.exists(0) then
              rht := empty;
              rht.qual := '%SYSTEM%';
              rht.name := SYS_NAME;
              rht.base := constant.REFERENCE;
              rht.self := constant.SYSTEM;
              rht.class:= constant.SYSTEM;
              ctl(0) := rht;
            end if;
          else
            if err=0 then
              buf.left := -lft.err_code;
              buf.right:= -rht.err_code;
            else
              buf.left := err;
              buf.right:= err;
            end if;
            buf.lqual:= lft.qual;
            buf.rqual:= rht.qual;
          end if;
          cnt := cnt+1;
          bnd(cnt) := buf;
        end loop;
      end if;
    end loop;
end add_binds;
--
function var2txt(p_var  par_var, p_par par_var, p_err_code in out nocopy pls_integer,
                 p_name varchar2 default null,
                 p_obj  boolean  default false,
                 p_colidx in varchar2 default null,
                 p_parentval in varchar2 default null
                 ) return varchar2 is
    pref    varchar2(30);
    suff    varchar2(30);
    func    varchar2(30);
    v_idx   varchar2(20);
    v_cls   varchar2(16);
    o_cls   varchar2(16);
    v_base  varchar2(16);
    v_attr  varchar2(100);
    v_qual  varchar2(700);
    qual    varchar2(700);
    txt     varchar2(1000);
    inobj   boolean := p_obj;
    v_get   boolean := p_name is null;
    v_kern  boolean;
    v_type  pls_integer;
    attr_info  lib.attr_info_t;
    class_info lib.class_info_t;
    function process_qual return boolean is
        i   pls_integer;
        b   boolean;
    begin
        i := instr(qual,'.');
        if i>0 then
            v_attr := substr(qual,1,i-1);
            qual := substr(qual,i+1);
        else
            v_attr := qual;
        end if;
        b := lib.find_attr(v_attr,v_cls,attr_info,class_info);
        if not class_info.class_id is null then
          if b then
            if v_base=constant.REFERENCE then
                if not v_qual is null then
                    if inobj then
                      suff := ',key_=>'||KEY_NAME||')';
                      if lib.field_exist(v_qual,o_cls,true) then
                        func := lower(substr(v_qual,instr(v_qual,'.')+1));
                        if instr(func,'c_') = 1 then
                          func := substr(func,3);
                        end if;
                        txt := '.g#'||func||'('||txt;
                      else
                        txt := '.get_ref('||txt||','''||v_qual||'''';
                      end if;
                      txt := class_mgr.interface_package(o_cls)||txt||suff;
                    elsif v_type in (DBROW,DBTABLE) or v_cls=constant.OBJECT then
                      if lib.field_exist(v_qual,v_cls,v_type=DBTABLE) then
                        txt := txt||substr(v_qual,instr(v_qual,'.'));
                      else
                        return true;
                      end if;
                    else
                      txt := class_mgr.qual2elem(v_qual,txt);
                    end if;
                    v_qual:= null;
                    o_cls := v_cls;
                elsif p_par.parent is null and v_type in (DBROW,DBTABLE) then
                    txt := txt||'.C_VALUE';
                end if;
                inobj := true;
                v_type:= DBOBJECT;
            end if;
            if v_qual is null then
              v_qual := v_attr;
            else
              v_qual := v_qual||'.'||v_attr;
            end if;
            v_base:= class_info.base_class_id;
            v_kern:= class_info.kernel;
            if i>0 then
                v_cls := nvl(class_info.class_ref,class_info.class_id);
                return process_qual;
            end if;
            if inobj then
                suff := ',key_=>'||KEY_NAME||')';
                b := false;
                if attr_info.position<0 then
                    func := 'object('; suff := suff||'.'||attr_info.name;
                else
                  b := lib.field_exist(v_qual,o_cls,true);
                  if b then
                    func := lower(substr(v_qual,instr(v_qual,'.')+1));
                    if instr(func,'c_') = 1 then
                      func := substr(func,3);
                    end if;
                  elsif v_base=constant.GENERIC_STRING then
                    func := 'str(';
                  elsif v_base=constant.GENERIC_NUMBER then
                    func := 'num(';
                  elsif v_base=constant.GENERIC_DATE then
                    func := 'date(';
                    if v_kern then
                      if    v_cls = 'TIMESTAMP' then
                        func := 'ts(';
                      elsif v_cls = 'TIMESTAMP_TZ' then
                        func := 'tstz(';
                      elsif v_cls = 'TIMESTAMP_LTZ' then
                        func := 'tsltz(';
                      elsif v_cls = 'INTERVAL' then
                        func := 'dsi(';
                      elsif v_cls = 'INTERVAL_YM' then
                        func := 'ymi(';
                      end if;
                    end if;
                  elsif v_base=constant.REFERENCE then
                    func := 'ref(';
                  elsif v_base=constant.GENERIC_BOOLEAN then
                    func := 'bool_char(';
                  elsif v_base=constant.MEMO then
                    func := 'memo(';
                  elsif v_base=constant.COLLECTION then
                    func := 'coll(';
                  elsif v_base=constant.OLE then
                    func := 'ole(';
                  end if;
                end if;
                if b then
                  txt := '.g#'||func||'('||txt;
                else
                  txt := '.get_'||func||txt||','''||v_qual||'''';
                end if;
                txt := class_mgr.interface_package(o_cls)||txt||suff;
            elsif attr_info.position<0 then
                txt := txt||'.'||attr_info.name;
            elsif v_type in (DBROW,DBTABLE) or v_cls=constant.OBJECT then
              if lib.field_exist(v_qual,v_cls,v_type=DBTABLE) then
                txt := txt||substr(v_qual,instr(v_qual,'.'));
              else
                return true;
              end if;
            else
                txt := class_mgr.qual2elem(v_qual,txt);
            end if;
            v_cls := nvl(class_info.class_ref,class_info.class_id);
          else
            v_base:= constant.SELF;
            v_qual:= v_attr;
          end if;
          return false;
        end if;
        return true;
    end;
begin
    p_err_code := 0;
    v_type:= p_var.kind;
    if    p_par.grid is null then
      txt := p_var.name;
    elsif p_par.parent is null then
      txt := p_var.name;
      if p_colidx is null then
        return txt;
      else
        if v_type=DBTABLE then
          v_idx := '(' || p_colidx || ')';
        else
          txt := txt || '(' || p_colidx || ')';
        end if;
        if p_par.grid = -1 then return txt; end if;
      end if;
    elsif p_parentval is null then
      txt := 'lib.get_row_val(GV'||p_var.grid||'('||p_colidx||'),'||p_var.colnum||')';
    else
      txt := p_parentval;
    end if;
    qual:= p_var.qual||'.';
    v_base:= p_var.base;
    if instr(p_par.qual,qual)=1 then
        if p_par.grid is null then
          if v_type=DBREF then
            v_cls:= p_var.self;
          else
            v_cls:= p_var.class;
          end if;
        elsif p_par.parent is null then
          v_cls := ctl(p_par.grid).class;
        else
          v_cls := ctl(p_par.parent).class;
        end if;
        o_cls:= v_cls;
        qual := substr(p_par.qual,length(qual)+1);
        if process_qual then
          p_err_code := ERR_CTL_BAD_QUAL;
          return null;
        end if;
    else
        if not p_par.grid is null then
          fill_class(p_var.self,v_base,v_cls);
        elsif v_type=DBREF then
          v_cls:= p_var.self;
        else
          v_cls:= p_var.class;
        end if;
        v_kern:= lib.is_kernel(v_cls);
        if p_par.parent is null and v_type in (DBROW,DBTABLE) then
          txt := txt||'.C_VALUE';
        end if;
    end if;
    pref := null; suff := null;
    if v_base=constant.GENERIC_DATE then
        if v_get then
            pref := 'to_char(';
        else
            pref := 'to_date(';
            if v_kern then
              if v_cls='INTERVAL_YM' then
                pref := 'to_yminterval(';
              elsif v_cls='INTERVAL' then
                pref := 'to_dsinterval(';
              elsif v_cls='TIMESTAMP_TZ' then
                pref := 'to_timestamp_tz(';
              else
                pref := 'to_timestamp(';
              end if;
            end if;
        end if;
        suff := ','''||DATE_FORMAT||''')';
        if v_kern then
          if v_cls like 'INTERVAL%' then
            suff := ')';
          else
            suff := ','''||TIME_FORMAT||''')';
          end if;
        end if;
    elsif v_base=constant.GENERIC_BOOLEAN then
        if v_get then
            pref := 'valmgr.bool2char(';
        else
            pref := 'valmgr.char2bool(';
        end if;
        suff := ')';
    elsif v_base in (constant.STRUCTURE,constant.GENERIC_TABLE) then
        p_err_code := ERR_CTL_BAD_CLASS;
        return null;
    elsif v_kern and v_base=constant.OLE then
        p_err_code := ERR_CTL_BAD_CLASS;
        return null;
    end if;
    if inobj then
        if not v_get or v_qual is null then
          if current_method_flags<>constant.METHOD_PRINT then
            p_err_code := ERR_CTL_BAD_ASSIGN;
          end if;
          return null;
        end if;
    end if;
    if not v_idx is null then
      txt := txt||v_idx;
    end if;
    if v_get then
      return pref||txt||suff;
    end if;
    return txt||':='||pref||p_name||suff;
end;
--
function ctl2txt(p_idx  pls_integer,
                 p_name varchar2 default null,
                 p_colidx in varchar2 default null,
                 p_parentval in varchar2 default null
  ) return varchar2 is  --@METAGS ctl2txt
    i   pls_integer;
    j   pls_integer;
    err pls_integer := 0;
    txt varchar2(2000);
    ct  par_var := ctl(p_idx);
begin
    i := ct.parent;
    if i is null then
      if p_idx<=START_CTLS then
        txt := var2txt(ct,ct,err,p_name);
      else
        i := ct.var_idx;
        if i is null then
          i := ct.grid;
          if instr(ct.qual,'%PARAM%.')=1 then
            ct.qual := substr(ct.qual,9);
            if i is null or i < 0 then
              i := qual2var_idx(par,ct.qual);
            --elsif instr(ctl(i).qual,'%PARAM%.')=1 then
            --  i := qual2var_idx(par,substr(ctl(i).qual,9));
            else
              i := qual2var_idx(par,ctl(i).qual);
            end if;
          elsif instr(ct.qual,'%VAR%.')=1 then
            ct.qual := substr(ct.qual,7);
            if i is null or i < 0 then
              i := -qual2var_idx(var,ct.qual);
            --elsif instr(ctl(i).qual,'%VAR%.')=1 then
            --  i := -qual2var_idx(var,substr(ctl(i).qual,7));
            else
              i := -qual2var_idx(var,ctl(i).qual);
            end if;
          else
            i := qual2var_idx(par,ct.qual);
            if i is null then
              i := -qual2var_idx(var,ct.qual);
            end if;
          end if;
          if not i is null then
            if i>0 then
              ct.kind := par(i).kind;
            else
              ct.kind := var(-i).kind;
            end if;
            ct.var_idx := i;
            ctl(p_idx) := ct;
          end if;
        end if;
        if i>0 then
          if ct.grid is null then
            txt := var2txt(par(i),ct,err,p_name);
          else
            txt := var2txt(par(i),ct,err,p_name,p_colidx=>p_colidx);
          end if;
        elsif i<0 then
          if ct.grid is null then
            txt := var2txt(var(-i),ct,err,p_name);
          else
            txt := var2txt(var(-i),ct,err,p_name,p_colidx=>p_colidx);
          end if;
        else
          err := ERR_CTL_NO_PARAM;
        end if;
      end if;
    elsif p_name is null then
      j := ctl(i).var_idx;
      if not j is null and ct.var_idx is null then
        if instr(ct.qual,'%PARAM%.')=1 then
          ct.qual := substr(ct.qual,9);
        elsif instr(ct.qual,'%VAR%.')=1 then
          ct.qual := substr(ct.qual,7);
        end if;
        ct.var_idx := j;
        ctl(p_idx) := ct;
      end if;
      txt := var2txt(ctl(i),ct,err,null,true,p_colidx,p_parentval);
    end if;
    if err<>0 and ct.err_code=0 then
      if err<>ERR_CTL_BAD_ASSIGN or p_idx<=ctl_count then
        ctl(p_idx).err_code := err;
      end if;
    end if;
    return txt;
end;
--
procedure get_deps(p_tbl in out nocopy constant.integer_table, p_idx pls_integer) is
    i   pls_integer;
    j   pls_integer;
    txt varchar2(1000);
begin
    if dep.exists(p_idx) then
        i := nvl(p_tbl.last,0);
        lib.set_index_list(dep(p_idx),p_tbl,false);
        j := nvl(p_tbl.last,0);
        for jj in i+1..j loop
            get_deps(p_tbl,p_tbl(jj));
        end loop;
    end if;
end;
--
procedure build_grid_utils(atext in out nocopy dbms_sql.varchar2s) is
ss_vl varchar2(32000);
ss_vl_p varchar2(32000);
ss_ch1 varchar2(32000);
ss_ch2 varchar2(32000);
s_s dbms_sql.varchar2a;
s_ss varchar2(32000);
sg_s varchar2(32000);
sg_s2 varchar2(32000);
s_ctl varchar2(1000);
i pls_integer;
j pls_integer;
n pls_integer;
b boolean;
--s_out varchar2(32000);--debug
grid_par_name varchar2(100);
grid_var_name varchar2(100);
grid_flags varchar2(256);
grid_par par_var;
grid_ctl par_var;
grid_idx pls_integer;
grid_elem_type varchar2(100);
--
 procedure set_grid_vals(aind in pls_integer) is
 j pls_integer;
 begin
   grid_idx := aind;
   grid_par_name := ctl2txt(grid_idx);
   grid_ctl := ctl(grid_idx);
   grid_flags := rpad('0',grid_ctl.colnum,'0');
   j := grid_ctl.var_idx;
   if not j is null then
     if j>0 then
       grid_par := par(j);
     else
       grid_par := var(-j);
     end if;
     grid_elem_type:= constant.RTL_DBOBJECT;
     if grid_par.kind=DBROW then
       grid_elem_type:= constant.RTL_DBROW;
     elsif grid_par.kind=DBTABLE then
       grid_var_name := grid_par_name;
       grid_par_name := grid_par_name||'.ID';
     elsif grid_ctl.base = constant.REFERENCE then
       grid_elem_type:= constant.RTL_REFERENCE;
     end if;
     grid_elem_type := class2type(grid_ctl.self,grid_elem_type,null);
   end if;
 end;
--
 function build_check_vals(actl in pls_integer) return varchar2 is
 cf varchar2(256);
 pf varchar2(256);
 sf varchar2(20);
 n pls_integer;
 i pls_integer;
 result varchar2(32000);
 dt "CONSTANT".integer_table;
 begin
   if actl = grid_idx then
     cf := grid_flags;
     n := 0;
     i := ctl.next(START_CTLS);
     while n < ctl(actl).colnum and not i is null loop
       if ctl(i).grid=actl and ctl(i).parent is null and ctl(i).err_code=0 then
         n := n + 1;
         lib.set_flag(cf,ctl(i).colnum,'1');
         if dep.exists(i) then
           result := result || build_check_vals(i);
         end if;
       end if;
       i := ctl.next(i);
     end loop;
     result :=
        TB2 || TB || 'bff := VL' || actl || '(i,'''||cf||''');' || LF
     || TB2 || TB || 'if GV' || actl || '(i) = bff then' || LF
     || TB2 || TB2 || 'bf := GF' || actl || '(i); GF' || actl || '(i) := '''||grid_flags||''';' || LF
     || TB2 || TB || 'else' || LF
     || TB2 || TB2 || 'lib.check_vals(GV' || actl || '(i),bff,GF' || actl || '(i),' || ctl(actl).colnum || ',bf,'''||cf||''');' || LF
     || TB2 || TB || 'end if;' || LF
     || result;
   elsif ctl(actl).err_code=0 then
     get_deps(dt,actl);
     if dt.count = 0 then return null; end if;
     cf := grid_flags;
     for j in dt.first..dt.last loop
       if ctl(dt(j)).parent = actl then
         lib.set_flag(cf,ctl(dt(j)).colnum,'1');
         if dep.exists(dt(j)) then
           result := result || build_check_vals(dt(j));
         end if;
       end if;
     end loop;
     if ctl(actl).parent is null then
       pf := TB2 || TB || 'if lib.check_flag(bf,' || ctl(actl).colnum || ') then' || LF;
       sf := TB2 || TB || 'end if;' || LF;
     end if;
     result := pf
     || TB2 || TB2 || 'bff := VL' || grid_idx || '(i,'''||cf||''');' || LF
     || TB2 || TB2 || 'lib.check_vals(GV' || grid_idx || '(i),bff,GF' || grid_idx || '(i),' || grid_ctl.colnum || ',bf,'''||cf||''');' || LF
     || result
     || sf;
   /*elsif ctl(actl).err_code=0 then
     get_deps(dt,actl);
     if dt.count = 0 then return null; end if;
     cf := grid_flags;
     for j in dt.first..dt.last loop
       if ctl(dt(j)).parent = actl then
         lib.set_flag(cf,ctl(dt(j)).colnum,'1');
         if dep.exists(dt(j)) then
           result := result || build_check_vals(dt(j));
         end if;
       end if;
     end loop;
     result :=
        TB2 || TB2 || 'bff := VL' || grid_idx || '(i,'''||cf||''');' || LF
     || TB2 || TB2 || 'lib.check_vals(GV' || grid_idx || '(i),bff,GF' || grid_idx || '(i),' || grid_ctl.colnum || ',bf,'''||cf||''');' || LF
     || result;*/
   end if;
   return result;
 end;
--
 procedure build_grid_set is
 begin
   s_ss := s_ss
   || 'procedure D' || grid_idx || '(astart in pls_integer, aend in pls_integer) is' || LF
   || 'tmp1 pls_integer;' || LF
   || 'tmp2 pls_integer;' || LF
   || 'begin' || LF
   || TB || 'if ' || grid_par_name || '.count = 0 then return; end if;' || LF
   || TB || 'if astart is null then' || LF
   || TB2 || 'tmp1 := ' || grid_par_name || '.first;' || LF
   || TB2 || 'tmp2 := nvl(aend,' || grid_par_name || '.last);' || LF
   || TB || 'else' || LF
   || TB2 || 'tmp1 := astart;' || LF
   || TB2 || 'tmp2 := nvl(aend,tmp1);' || LF
   || TB || 'end if;' || LF
   || TB || grid_par_name || '.delete(tmp1,tmp2);' || LF
   || TB || 'GV' || grid_idx || '.delete(tmp1,tmp2);' || LF
   || TB || 'GF' || grid_idx || '.delete(tmp1,tmp2);' || LF
   || 'end;' || LF2;
   s_ss := s_ss
   || 'procedure I' || grid_idx || '(astart in pls_integer, acount in pls_integer) is' || LF
   || 'tmp pls_integer;' || LF
   || 'buf ' || grid_elem_type || ';' || LF
   || 'begin' || LF
   || TB || 'tmp := nvl(astart,1);' || LF
   || TB || 'for i in 0..nvl(acount,1)-1 loop' || LF;
   if grid_par.kind=DBTABLE then
     s_ss := s_ss
     ||TB2||class_mgr.interface_package(grid_ctl.self)||'.set$rectbl('||grid_var_name||',buf,true,tmp+i);'||LF;
   else
     if grid_par.kind=DBROW then
       if class_mgr.needs_oracle_type(grid_ctl.self)='1' then
        s_ss := s_ss||TB2||'if buf is null then '||class_mgr.interface_package(grid_ctl.self)||'.set$row(buf,null); end if;'||LF;
       end if;
       s_ss := s_ss||TB2||'if (tmp+i)>nvl('||grid_par_name||'.last,0) then '||grid_par_name||'.extend(tmp+i-nvl('||grid_par_name||'.last,0)); end if;'||LF;
     end if;
     s_ss := s_ss||TB2||grid_par_name||'(tmp+i) := buf;'||LF;
   end if;
   s_ss := s_ss
   || TB2 || 'GV' || grid_idx || '(tmp+i) := rpad(lib.GRID_CHAR,' || (grid_ctl.colnum - 1) || ',lib.GRID_CHAR);' || LF
   --|| TB2 || 'GF' || grid_idx || '(tmp+i) := ''I'';' || LF
   || TB || 'end loop;' || LF
   || 'end;' || LF2;
   s_ss := s_ss
   || 'procedure A' || grid_idx || '(acount in pls_integer) is' || LF
   || 'begin' || LF
   || TB || 'I' || grid_idx || '(' || grid_par_name || '.last+1,acount);' || LF
   || 'end;' || LF2;
   s_ss := s_ss
   || 'procedure M' || grid_idx || '(astart in pls_integer, anewpos in pls_integer) is' || LF
   || 'st pls_integer;' || LF
   || 'np pls_integer;' || LF;
   if grid_par.kind=DBTABLE then
     s_ss := s_ss|| 'buf ' || grid_elem_type || ';' || LF;
   end if;
   s_ss := s_ss
   || 'begin' || LF
   || TB || 'if ' || grid_par_name || '.count = 0 then return; end if;' || LF
   || TB || 'st := nvl(astart,' || grid_par_name || '.first);' || LF
   || TB || 'np := nvl(anewpos,1);' || LF
   || TB || 'if    st > np then' || LF
   || TB2 || 'for i in st..' || grid_par_name || '.last loop' || LF
   || TB2 || TB || 'if ' || grid_par_name || '.exists(i) then'  || LF
   || TB2 || TB2 || 'I' || grid_idx || '(np+i-st,1);' || LF;
   if grid_par.kind=DBTABLE then
     s_ss := s_ss
     ||TB2||class_mgr.interface_package(grid_ctl.self)||'.get$rectbl(buf,'||grid_var_name||',true,i);'||LF
     ||TB2||class_mgr.interface_package(grid_ctl.self)||'.set$rectbl('||grid_var_name||',buf,true,np+i-st);'||LF;
   else
     s_ss := s_ss
     || TB2 || TB2 || grid_par_name || '(np+i-st) := ' || grid_par_name || '(i);' || LF;
   end if;
   s_ss := s_ss
   || TB2 || TB || 'end if;' || LF
   || TB2 || TB || 'if GV' || grid_idx || '.exists(i) then GV' || grid_idx || '(np+i-st) := GV' || grid_idx || '(i); end if;' || LF
   || TB2 || TB || 'D' || grid_idx || '(i,i);' || LF
   || TB2 || 'end loop;' || LF
   || TB || 'else' || LF
   || TB2 || 'for i in reverse st..' || grid_par_name || '.last loop' || LF
   || TB2 || TB || 'if ' || grid_par_name || '.exists(i) then' || LF
   || TB2 || TB2 || 'I' || grid_idx || '(np+i-st,1);' || LF;
   if grid_par.kind=DBTABLE then
     s_ss := s_ss
     ||TB2||class_mgr.interface_package(grid_ctl.self)||'.get$rectbl(buf,'||grid_var_name||',true,i);'||LF
     ||TB2||class_mgr.interface_package(grid_ctl.self)||'.set$rectbl('||grid_var_name||',buf,true,np+i-st);'||LF;
   else
     s_ss := s_ss
     || TB2 || TB2 || grid_par_name || '(np+i-st) := ' || grid_par_name || '(i);' || LF;
   end if;
   s_ss := s_ss
   || TB2 || TB || 'end if;' || LF
   || TB2 || TB || 'if GV' || grid_idx || '.exists(i) then GV' || grid_idx || '(np+i-st) := GV' || grid_idx || '(i); end if;' || LF
   || TB2 || TB || 'D' || grid_idx || '(i,i);' || LF
   || TB2 || 'end loop;' || LF
   || TB || 'end if;' || LF
   || 'end;' || LF2;
   if not sg_s2 is null then
     sg_s2 := TB || 'if GF' || grid_idx || '(tmp) <> ''I'' then' || LF
     || sg_s2 || TB || 'end if;' || LF;
   end if;
   s_ss := s_ss
   || 'procedure S' || grid_idx || '(arow in pls_integer, adata in varchar2) is' || LF
   || 'tmp pls_integer := nvl(arow,1);' || LF
   || 'begin' || LF
   || TB || 'if not ' || grid_par_name || '.exists(tmp) then' || LF
   || TB2 || 'I' || grid_idx || '(tmp,1); GF' || grid_idx || '(tmp) := ''I'';' || LF
   || TB || 'end if;' || LF
   || sg_s
   || TB || 'GV' || grid_idx || '(tmp) := replace(adata,rtl.esc$,lib.GRID_CHAR);' || LF
   || TB || 'if not GF' || grid_idx || '.exists(tmp) then' || LF
   || TB2 || 'GF' || grid_idx || '(tmp) := '''||grid_flags||''';' || LF
   || TB || 'end if;' || LF
   || sg_s2
   || 'end;' || LF2;
   s_ss := s_ss
   || 'procedure SG' || grid_idx || '(acmd in varchar2) is' || LF
   || 'cmd pls_integer;' || LF
   || 'tmp pls_integer;' || LF
   || 'p pls_integer;' || LF
   || 'i pls_integer;' || LF
   || 's varchar2(32500);' || LF
   || 'begin' || LF
   || TB || 'i := 0;' || LF
   || TB || 'while not i is null loop' || LF
   || TB2 || 'cmd := ascii(substr(acmd,i+1,1));' || LF
   || TB2 || 'tmp := instr(acmd,'';'',i+1);' || LF
   || TB2 || 'if cmd = '||ascii('S')||' or tmp = 0 then' || LF
   || TB2 || TB || 's := substr(acmd,i+1);' || LF
   || TB2 || TB || 'i := null;' || LF
   || TB2 || 'else' || LF
   || TB2 || TB || 's := substr(acmd,i+1,tmp-i-1);' || LF
   || TB2 || TB || 'i := tmp;' || LF
   || TB2 || 'end if;' || LF
   || TB2 || 'tmp := instr(s,'','',3);' || LF
   || TB2 || 'if    cmd = '||ascii('A')||' or tmp = 0 then' || LF
   || TB2 || TB || 'p := substr(s,3);' || LF
   || TB2 || TB || 's := null;' || LF
   || TB2 || 'else' || LF
   || TB2 || TB || 'p := substr(s,3,tmp-3);' || LF
   || TB2 || TB || 's := substr(s,tmp+1);' || LF
   || TB2 || 'end if;' || LF
   || TB2 || 'if    cmd = '||ascii('A')||' then' || LF
   || TB2 || TB || 'A' || grid_idx || '(p);' || LF
   || TB2 || 'elsif cmd = '||ascii('D')||' then' || LF
   || TB2 || TB || 'D' || grid_idx || '(p,s);' || LF
   || TB2 || 'elsif cmd = '||ascii('I')||' then' || LF
   || TB2 || TB || 'I' || grid_idx || '(p,s);' || LF
   || TB2 || 'elsif cmd = '||ascii('M')||' then' || LF
   || TB2 || TB || 'M' || grid_idx || '(p,s);' || LF
   || TB2 || 'elsif cmd = '||ascii('S')||' then' || LF
   || TB2 || TB || 'S' || grid_idx || '(p,s);' || LF
   || TB2 || 'end if;' || LF
   || TB || 'end loop;' || LF
   || 'end;' || LF2;
 end;
--
 procedure build_gridcol_set(aind in pls_integer) is
 s_par_name varchar2(1000);
 begin
   if lib.is_nvarchar_based(ctl(aind).base) then
       s_ctl := ctl2txt(aind,'lib.decode_national_string(tbl(i))','i');
   else 
       s_ctl := ctl2txt(aind,'tbl(i)','i');
   end if;
   if not s_ctl is null then
     s_ctl := TB2||s_ctl||';'||LF;
   end if;
   if sc_logging then
     s_par_name:= ctl2txt(aind,p_colidx=>'i');
   end if;
   s_s(s_s.count + 1) := 
   'procedure SC' || aind || '(avl in varchar2) is' || LF
   || 'tbl rtl.string_table;' || LF
   || 'i pls_integer;' || LF
   || 'begin' || LF
   || TB || 'lib.set_string_list(avl,tbl,true,rtl.esc$);' || LF
   || TB || 'i := tbl.first;' || LF
   || TB || 'while not i is null loop' || LF ||
   case when sc_logging then
   TB2 || 'b_eq:= null;' || LF
   end
   || TB2 || 'if not ' || grid_par_name || '.exists(i) or not GV' || grid_idx || '.exists(i) then' || LF
   || TB2 || TB || 'I' || grid_idx || '(i,1); GF' || grid_idx || '(i) := ''I'';' || LF ||
   case when sc_logging then
      TB2 || TB || 'b_eq:= true;' || LF
   || TB2 || 'else' || LF
   || TB2 || TB || 'b_eq:= tbl(i)='|| s_par_name ||' or (tbl(i) is null and ' || s_par_name||' is null);' || LF
   end
   || TB2 || 'end if;' || LF ||
   case when sc_logging then
      TB2 || 'GRID_EQ(i):= rtl.bool_char(b_eq,''1'',null,null);' || LF
   end
   || TB2 || 'if not ' || 'GF' || grid_idx || '.exists(i) then' || LF
   || TB2 || TB || 'GF' || grid_idx || '(i) := '''||grid_flags||''';' || LF
   || TB2 || 'end if;' || LF
   || s_ctl
   || TB2 || 'lib.set_row_val(GV' || grid_idx || '(i),' || ctl(aind).colnum || ',tbl(i));' || LF
   || TB2 || 'if GF' || grid_idx || '(i) <> ''I'' then lib.set_flag(GF' || grid_idx || '(i),' || ctl(aind).colnum || ',''1''); end if;' || LF
   || TB2 || 'i := tbl.next(i);' || LF
   || TB || 'end loop;' || LF
   || 'end;' || LF2;
 end;
--
 procedure build_vl(aind in pls_integer) is
 i pls_integer;
 n pls_integer;
 dp "CONSTANT".integer_table;
 ct par_var;
 pt par_var;
  procedure put_deps(p_start pls_integer,p_parent pls_integer) is
    i pls_integer;
  begin
    for j in p_start..dp.last loop
      i := dp(j);
      if ctl(i).parent = p_parent then
        for x in j+1..dp.last loop
          if ctl(dp(x)).parent = i then
            s_ctl := s_ctl||TB||TB2||'bb'||ctl(i).colnum||' := false;'||LF;
            put_deps(j+1,i);
            exit;
          end if;
        end loop;
      end if;
    end loop;
  end;
 begin
   if    aind is null or aind = grid_idx then
     i := ctl.next(START_CTLS);
     n := 0;
     while n < ctl(grid_idx).colnum and not i is null loop
       if ctl(i).grid=grid_idx and ctl(i).err_code=0 then
         n := n + 1;
         build_vl(i);
       end if;
       i := ctl.next(i);
     end loop;
   elsif ctl(aind).grid = grid_idx then
     get_deps(dp,aind);
     ct := ctl(aind);
     if ct.parent is null then
       ss_vl := ss_vl
       || TB || 'if amask is null or lib.check_flag(amask,' || ct.colnum || ') then' || LF;
       s_ctl := nvl(ctl2txt(aind,p_colidx=>'aind'),'null');
       if dp.count > 0 then
         ss_vl := ss_vl
         || TB2 || 'vv' || ct.colnum || ' := ' || s_ctl || ';' || LF
         || TB2 || 'result := result || vv' || ct.colnum || ' || lib.GRID_CHAR;' || LF
         || TB2 || 'bb' || ct.colnum || ' := false;' || LF;
         s_ctl := null;
         put_deps(dp.first,aind);
         if not s_ctl is null then
           ss_vl := ss_vl||TB2||'if vv'|| ct.colnum||' is null then'||LF||s_ctl||TB2||'end if;'||LF;
         end if;
       else
		 if lib.is_nvarchar_based(ctl(aind).base) then
	       s_ctl := 'lib.encode_national_string(' || s_ctl || ')';
		 end if; 
         ss_vl := ss_vl
         || TB2 || 'result := result || ' || s_ctl || ' || lib.GRID_CHAR;' || LF;
       end if;
     else
       pt := ctl(ct.parent);
       ss_vl := ss_vl
       || TB || 'if (amask is null or lib.check_flag(amask,'||ct.colnum||')) and (bb'||pt.colnum||' or not vv'||pt.colnum||' is null) then'||LF;
       i := pt.parent;
       pt.parent := ct.parent;
       s_ctl := var2txt(pt,pt,n,p_colidx=>'aind');
       if s_ctl is null then
         if pt.err_code=0 then
           ctl(ct.parent).err_code := n;
         end if;
         s_ctl := 'null';
       end if;
       ss_vl := ss_vl
        || TB2 || 'if bb'||pt.colnum||' then vv'||pt.colnum||' := '||s_ctl||'; bb'||pt.colnum||' := false; end if;' || LF;
       pt.parent := i;
       if dp.count > 0 then
         s_ctl := nvl(ctl2txt(aind,p_colidx=>'aind',p_parentval=>'vv' || pt.colnum),'null');
         ss_vl := ss_vl
         || TB2 || 'vv' || ct.colnum || ' := ' || s_ctl || ';' || LF
         || TB2 || 'result := result || vv' || ct.colnum || ' || lib.GRID_CHAR;' || LF
         || TB2 || 'bb' || ct.colnum || ' := false;' || LF;
         s_ctl := null;
         put_deps(dp.first,aind);
         if not s_ctl is null then
           ss_vl := ss_vl||TB2||'if vv'|| ct.colnum||' is null then'||LF||s_ctl||TB2||'end if;'||LF;
         end if;
       else
         s_ctl := nvl(ctl2txt(aind,p_parentval=>'vv' || pt.colnum),'null');
         ss_vl := ss_vl
          || TB2 || 'result := result || ' || s_ctl || ' || lib.GRID_CHAR;' || LF;
       end if;
     end if;
     ss_vl := ss_vl
     || TB || 'else' || LF
     || TB2 || 'result := result || lib.GRID_CHAR;' || LF
     || TB || 'end if;' || LF;
     if dp.count > 0 then
       ss_vl_p := ss_vl_p
       || 'vv' || ct.colnum || ' varchar2(128);' || LF
       || 'bb' || ct.colnum || ' boolean := true;' || LF;
     end if;
   end if;
 end;
--
begin
  i := ctl.next(START_CTLS);
  b := false;
  while not i is null loop
   if ctl(i).grid=-1 and ctl(i).err_code=0 then
     --package variables
    set_grid_vals(i);
    ss_vl := null; ss_vl_p := null;
    build_vl(i);
    if grid_ctl.err_code=0 then
      lib.put_buf('GF' || i || ' RTL.DEFSTRING_TABLE;' || LF2,atext, false);
      lib.put_buf('GV' || i || ' RTL.STRING_TABLE;' || LF,atext, false);
      s_ss := null; s_s.delete; ss_ch1 := null; ss_ch2 := null; sg_s := null; sg_s2 := null;
      n := 0;
      j := ctl.next(START_CTLS);
      while not j is null and n < ctl(i).colnum loop
        if ctl(j).grid=i and ctl(j).err_code=0 then
          n := n + 1;
          ss_ch1 := ss_ch1
          || TB || 'CH.delete(' || j || ');' || LF;
          ss_ch2 := ss_ch2
          || TB || 'if lib.check_flag(bf,' || ctl(j).colnum || ') then CH(' || j || ') := true; end if;' || LF;
          if ctl(j).parent is null then
			s_ctl := 'lib.get_row_val(adata,' || ctl(j).colnum || ',rtl.esc$)';
            if lib.is_nvarchar_based(ctl(j).base) then
                s_ctl := 'lib.decode_national_string(' || s_ctl || ')';
            end if;           
            s_ctl:= ctl2txt(j, s_ctl, 'tmp');
            if not s_ctl is null then
              sg_s := sg_s || TB || s_ctl || ';' || LF;
              sg_s2 := sg_s2 || TB2 || 'lib.set_flag(GF' || i || '(tmp),' || ctl(j).colnum || ',''1'');' || LF;
            end if;
            build_gridcol_set(j);
          end if;
        end if;
        j := ctl.next(j);
      end loop;
      build_grid_set;
      ss_vl := 'function VL' || i || '(aind in pls_integer, amask in varchar2 default null) return varchar2 is' || LF
      || 'result varchar2(32000);' || LF
      || ss_vl_p
      || 'begin' || LF || ss_vl
      || TB || 'return substr(result,1,length(result)-1);' || LF
      || 'end;' || LF2;
      --check procedure
      sg_s := 'procedure GC' || i || ' is' || LF
      || 'bf varchar2(' || ctl(i).colnum || ');' || LF
      || 'bff varchar2(32767);' || LF
      || 'i pls_integer; idx1 pls_integer; idx2 pls_integer;' || LF
      || 'begin' || LF
      || TB || 'idx1 := GV' || i || '.first; idx2 := ' || grid_par_name || '.first;' || LF
      || TB || 'while not (idx1 is null and idx2 is null) loop' || LF
      || TB2 || 'if idx1 is null then i := idx2;' || LF
      || TB2 || 'elsif idx2 is null then i := idx1;' || LF
      || TB2 || 'else i := least(idx1,idx2); end if;' || LF
      || TB2 || 'if not ' || grid_par_name || '.exists(i) then' || LF
      || TB2 || TB || 'if GV' || i || '.exists(i) then' || LF
      || TB2 || TB2 || 'GV' || i || '.delete(i);' || LF
      || TB2 || TB2 || 'GF' || i || '(i) := ''D'';' || LF
      || TB2 || TB || 'elsif GF' || i || '.exists(i) and GF' || i || '(i) <> ''D'' then' || LF
      || TB2 || TB2 || 'GF' || i || '.delete(i);' || LF
      || TB2 || TB || 'end if;' || LF
      || TB2 || 'elsif not GV' || i || '.exists(i) or GF' || i || '.exists(i) and GF' || i || '(i) = ''I'' then' || LF
      || TB2 || TB || 'GV' || i || '(i) := VL' || i || '(i);' || LF
      || TB2 || TB || 'GF' || i || '(i) := ''I'';' || LF
      || TB2 || 'else' || LF
      || TB2 || TB || 'if not GF' || i || '.exists(i) then GF' || i || '(i) := '''||grid_flags||'''; end if;' || LF
      || TB2 || TB || 'bf := '''||grid_flags||''';' || LF
      || build_check_vals(i)
      || TB2 || TB || 'if instr(GF' || i || '(i),''1'') = 0 then GF' || i || '.delete(i); end if;' || LF
      || TB2 || 'end if;' || LF
      || TB2 || 'if not idx1 is null then idx1 := GV' || i || '.next(i); end if;' || LF
      || TB2 || 'if not idx2 is null then idx2 := ' || grid_par_name || '.next(i); end if;' || LF
      || TB || 'end loop;' || LF
      || TB || 'SCH' || i || ';' || LF
      || 'end;' || LF2;
      ss_ch1 := 'procedure SCH' || i || ' is' || LF
      || TB|| 'bf varchar2(' || ctl(i).colnum || '); i pls_integer;' || LF
      || 'begin' || LF
      || TB || 'CH.delete(' || i || ');' || LF
      || ss_ch1
      || TB || 'if GF' || i || '.count = 0 then return; end if;' || LF
      || TB || 'i := GF' || i || '.first;' || LF
      || TB || 'while not i is null loop' || LF
      || TB2 || 'if GF' || i || '(i) in (''I'',''D'') then' || LF
      || TB2 || TB || 'CH(' || i || ') := true; exit;' || LF
      || TB2 || 'end if;' || LF
      || TB2 || 'i := GF' || i || '.next(i);' || LF
      || TB || 'end loop;' || LF
      || TB || 'bf  := lib.flags_or(GF' || i || ',' || ctl(i).colnum || ');' || LF
      || TB || 'if instr(bf,''1'') = 0 then return; end if;' || LF
      || ss_ch2
      || 'end;' || LF2;
/*
      --debug {
      s_out := s_out
      || 'procedure out' || i || ' is' || LF
      || 'begin' || LF
      || TB || 'dbms_output.put_line(''values' || i || ':'');' || LF
      || TB || 'if GV' || i || '.count > 0 then' || LF
      || TB2 || 'for i in GV' || i || '.first..GV' || i || '.last loop' || LF
      || TB2 || TB || 'if GV' || i || '.exists(i) then' || LF
      || TB2 || TB2 || 'dbms_output.put_line(i || '': '' || replace(substr(GV' || i || '(i),1,200),lib.GRID_CHAR,'',''));' || LF
      || TB2 || TB || 'else' || LF
      || TB2 || TB2 || 'dbms_output.put_line(i || '': no data'');' || LF
      || TB2 || TB || 'end if;' || LF
      || TB2 || 'end loop;' || LF
      || TB || 'end if;' || LF
      || TB || 'dbms_output.put_line(''flags' || i || ':'');' || LF
      || TB || 'if GF' || i || '.count > 0 then' || LF
      || TB2 || 'for i in GF' || i || '.first..GF' || i || '.last loop' || LF
      || TB2 || TB || 'if GF' || i || '.exists(i) then' || LF
      || TB2 || TB2 || 'dbms_output.put_line(i || '': '' || GF' || i || '(i));' || LF
      || TB2 || TB || 'else' || LF
      || TB2 || TB2 || 'dbms_output.put_line(i || '': no data'');' || LF
      || TB2 || TB || 'end if;' || LF
      || TB2 || 'end loop;' || LF
      || TB || 'end if;' || LF
      || 'end;'|| LF2;
      --} debug
*/
      lib.put_buf(s_ss,atext);
      for i in 1..s_s.count
        loop
          lib.put_buf(s_s(i),atext);
        end loop;
      lib.put_buf(ss_ch1,atext);
      lib.put_buf(ss_vl,atext);
      lib.put_buf(sg_s,atext);
    --class_mgr.put_text_buf(s_out,atext);--debug
      b := true;
    end if;
   end if;
   i := ctl.next(i);
  end loop;
  if b then
    lib.put_buf('OUTBUF varchar2(32504); SAVIND pls_integer;' || LF2, atext, false);
    if sc_logging then
      lib.put_buf('GRID_EQ RTL.DEFSTRING_TABLE; b_eq boolean;' || LF, atext, false);
    end if;
  end if;
end build_grid_utils;
--
procedure build_get_params(p_buf in out nocopy dbms_sql.varchar2s) is --@METAGS build_get_params
    s   varchar2(100);
    ss  varchar2(4000);
    s1  varchar2(100);
    s2  varchar2(500);
    sd  varchar2(100);
    d   varchar2(8000);
    gc  dbms_sql.varchar2s;
    b   boolean := false;
    i   pls_integer;
    cnt pls_integer;
    procedure add_temp_var(p_class varchar2) is
      i pls_integer;
      j pls_integer;
    begin
      sd:= TB||class2type(p_class,constant.RTL_DBOBJECT,null)||';'||LF;
      i := instr(d,sd);
      if i>0 then
        j := instr(d,TB,i-length(d)-2);
        s1:= substr(d,j+1,i-j-1);
        return;
      end if;
      cnt := cnt+1;
      s1:= 'v$'||cnt;
      d := d||TB||s1||sd;
    end;
    procedure make_call(p_var varchar2,p_flag varchar2,p_class varchar2,p_qual varchar2) is
    begin
      if p_flag=constant.RTL_REFERENCE then
        ss := 'if v_qual is null then return '||p_var||'; else return '||class_mgr.interface_package(p_class)||'.get$value('||p_var||',v_qual'||s2||' end if;';
      elsif p_flag=constant.RTL_DBROW then
        add_temp_var(p_class);
        ss := class_mgr.interface_package(p_class)||'.set$rec('||s1||','||p_var||'); return '||class_mgr.interface_package(p_class)||'.get$rec_value('||s1||',v_qual'||s2;
      elsif p_flag=constant.RTL_DBTABLE then
        add_temp_var(p_class);
        ss := 'if '||p_var||'.id.exists(p_idx) then '||class_mgr.interface_package(p_class)||'.get$rectbl('||s1||','||p_var||',true,p_idx); return '||
           class_mgr.interface_package(p_class)||'.get$rec_value('||s1||',v_qual'||s2||' end if;';
      elsif p_flag=constant.RTL_COLLECTION then
        add_temp_var(p_class);
        ss := 'if '||p_var||'.exists(p_idx) then '||class_mgr.interface_package(p_class)||'.set$rec('||s1||','||p_var||'(p_idx)); return '||
           class_mgr.interface_package(p_class)||'.get$rec_value('||s1||',v_qual'||s2||' end if;';
      elsif p_flag=constant.RTL_TABLE then
        ss := 'if '||p_var||'.exists(p_idx) then return '||class_mgr.interface_package(p_class)||'.get$rec_value('||p_var||'(p_idx),v_qual); end if;';
      else
        ss := 'return '||class_mgr.interface_package(p_class)||'.get$rec_value('||p_var||',v_qual'||s2;
      end if;
      lib.put_buf('if v_str='''||p_qual||''' then'||LF||
         TB2||ss||LF||TB||'els',gc);
    end;
begin
    i := ctl.next(START_CTLS);
    while not i is null loop
      if not ctl(i).grid is null and ctl(i).err_code=0 then
        b := true;
        if ctl(i).grid = -1 then
          ss := '(GV'||i||',GF'||i;
        else
          cnt:= ctl(i).grid;
          b := ctl(cnt).err_code=0;
          if b then
            ss := '_col(GV'||cnt||',GF'||cnt;
          end if;
        end if;
        if b then
          lib.put_buf('if i='||i||' then OUTBUF := lib.grid_get'||ss||
            ',cind,'||ctl(i).colnum||');'||LF||TB2||'els',gc);
        end if;
      end if;
      i := ctl.next(i);
    end loop;
    b := gc.count>0;
    if b then
      ss := 'e OUTBUF := replace(ct(i),rtl.esc$,constant.nc);'||LF||TB2||'end if;';
    end if;
    if ctl.last>127 then
      s := ' ii pls_integer; b boolean:=false;';
      s1:= TB||' if ch.last>127 then b:=true; vl:=chr(3); end if;'||LF;
      if b then
        ss:= ss||LF||TB2||'if b then ii:=trunc(i/127)+1; OUTBUF:=rtl.esc$||chr((i mod 127)+1)||chr(ii)||OUTBUF; else OUTBUF:=rtl.esc$||chr(i)||OUTBUF; end if;';
      else
        ss:= 'if b then ii:=trunc(i/127)+1; vl:=vl||rtl.esc$||chr((i mod 127)+1)||chr(ii)||replace(ct(i),rtl.esc$,constant.nc); else vl:=vl||rtl.esc$||chr(i)||replace(ct(i),rtl.esc$,constant.nc); end if;';
      end if;
    else
      if b then
        ss := ss||LF||TB2||'OUTBUF := rtl.esc$||chr(i)||OUTBUF;';
      else
        ss:= 'vl:=vl||rtl.esc$||chr(i)||replace(ct(i),rtl.esc$,constant.nc);';
      end if;
    end if;
    if b then s := s||' cind pls_integer;'; end if;
    sd := 'ch.delete(i);';
    if b then sd := 'if cind is null then ' || sd || ' else j := i; end if;'; end if;
    sd := TB || sd || LF;
    if b then
      ss := ss || LF
      --|| TB2 || 'stdio.put_line_pipe(i||''.GET<''||OUTBUF||''>'',''XXX'');'||LF
      || TB2 || 'begin' || LF
      || TB2 || sd
      || TB2 || TB || 'vl := vl||OUTBUF;' || LF
      || TB2 || TB || 'OUTBUF := null;' || LF
      || TB2 || 'exception' || LF
      || TB2 || TB || 'when VALUE_ERROR then ok:=''0''; SAVIND:=cind; return vl;' || LF
      || TB2 || 'end;';
      sd := null;
      if not s1 is null then
        sd := 'vl||';
      end if;
      s2 := TB||'if not OUTBUF is null then vl:='||sd||'OUTBUF; OUTBUF:=null; cind:=SAVIND; end if;'||LF;
      sd := null;
    --else
    --  ss := ss || LF
    --  || TB2 || 'stdio.put_line_pipe(i||''.GET<''||ct(i)||''>'',''XXX'');';
    end if;
    lib.put_buf(
      'function '||get_param_name(current_method_id)||'(ok out varchar2) return varchar2 is'||LF
      ||TB||'vl varchar2(32504);'||s||' i pls_integer; j pls_integer:=ch.first;'||LF
      ||'begin'||LF||TB||'ok:=''1'';'||LF||s1||s2
      ||TB||'while not j is null loop'||LF||TB||'i:=j; j:=ch.next(j);'||LF
      ||TB||'if ch(i) then'||LF||TB2,p_buf);
    ss := ss||LF
    ||TB||'end if;'||LF||sd
    ||TB||'end loop; return vl;'||LF;
    if b then
      lib.add_buf(gc,p_buf);
      gc.delete;
    else
      ss := ss||'exception when value_error then'||LF||TB||'ok:=''0'';  return vl;'||LF;
    end if;
    lib.put_buf(ss||'end;'||LF2||
    'function '||get_param_qual(current_method_id)||'(p_qual varchar2, p_idx pls_integer default null) return varchar2 is'||LF||
    TB||'v_str varchar2(100); v_qual varchar2(700); i pls_integer;'||LF,p_buf);
    s2 := ',key_=>'||KEY_NAME||');';
    d := null; cnt := 0;
    i := par.first;
    while not i is null loop
      make_call(par(i).name,par(i).flag,par(i).self,'%PARAM%.'||par(i).qual);
      i := par.next(i);
    end loop;
    if not current_method_result is null then
        if current_method_flags = constant.METHOD_NEW then
          s := constant.RTL_REFERENCE;
        else
          s := constant.RTL_DBOBJECT;
        end if;
        make_call(result_name(current_method_id),s,current_method_result,'%PARAM%.<RESULT>');
    end if;
    i := var.first;
    while not i is null loop
      make_call(var(i).name,var(i).flag,var(i).self,'%VAR%.'||var(i).qual);
      i := var.next(i);
    end loop;
    lib.put_buf(d||'begin i:=instr(p_qual,''.'',1,2);'||LF||
    TB||'if i>0 then v_str:=upper(substr(p_qual,1,i-1)); v_qual:=substr(p_qual,i+1);'||LF||
    TB||'else v_str:=upper(p_qual); end if;'||LF||
    TB||'if PF is null then PF:='||current_mtd_archive||'; '||KEY_NAME||':=valmgr.init_key(PF); end if;'||LF||TB,p_buf);
    ss := 'message.err(-20999,''PLP'',''VAR_NOT_FOUND'',v_str);'||LF;
    if gc.count>0 then
      lib.add_buf(gc,p_buf);
      gc.delete;
      ss := 'e'||LF||TB2||ss||TB||'end if;'||LF||TB||'return null;'||LF;
    end if;
    lib.put_buf(ss||'end;'||LF2,p_buf);
end;
--
function table_func(p_base varchar2) return varchar2  is
    v_base varchar2(16);
begin
    v_base := substr(p_base,instr(p_base,'.')+1);
    if v_base in (constant.REFERENCE,constant.COLLECTION,constant.OLE) then
        return 'refs';
    elsif v_base in (constant.GENERIC_STRING,constant.MEMO) then
        return 'string';
    elsif v_base = constant.GENERIC_NUMBER then
        return 'number';
    elsif v_base = constant.GENERIC_DATE then
        return 'date';
    elsif v_base = constant.GENERIC_BOOLEAN then
        return 'bool';
    end if;
    return null;
end;
--
/**
 *   Формирует текст процедуры S.
 *   @param    p_buf    Буффер.
 */
procedure build_set_params(p_buf in out nocopy dbms_sql.varchar2s) is
    s   varchar2(100);
    ss  varchar2(1000);
    i   pls_integer := 1;
    j   pls_integer;
    b   boolean;
    bb  boolean;
    sc  dbms_sql.varchar2s;
    gc  dbms_sql.varchar2s;
begin
    /* put s */
    lib.put_buf(LF2||'procedure '||set_param_name(current_method_id)||'(par_ varchar2) is'||LF||
        TB||'vl varchar2(32767); val rtl.string_table; j pls_integer;'||LF||
        case when sc_logging then
        TB||'ii pls_integer; par_eq varchar2(32767); s_gr_ch varchar2(4000); sTmp varchar2(4000);'||LF
        end ||
        'begin'||LF||TB||'lib.set_string_list(par_,val,true,rtl.esc$); '||LF||TB||'j:=val.first;'||LF||
        TB||'while not j is null loop vl:=val(j);'||LF
        --||TB2||'stdio.put_line_pipe(j||''.SET<''||vl||''>'',''XXX'');'||LF
        , p_buf);
    if sc_logging then
      lib.put_buf(TB2||'sTmp:= null;'||LF, p_buf);
      lib.put_buf(
        TB2||'if j>'||START_CTLS||' then'||LF||
        TB2||TB||'sTmp:= rtl.bool_char(ct.exists(j) and (ct(j)=vl or (ct(j) is null and vl is null)),''1'',null,null);'||LF||
        TB2||TB||'if sTmp is not null then '||LF||
        TB2||TB||TB||'sTmp:= rtl.esc$||chr(mod(j,127)+1)||chr(trunc(j/127)+1)||sTmp;'||LF||
        TB2||TB||'end if;'||LF||
        TB2||'end if;'||LF
        , sc);
    end if;

    lib.put_buf(
        TB2||'if j=4 then v$self := true; '||CLS_NAME||':=vl; v$lck := vl; elsif j=5 then '||DBG_NAME||
        ':=vl; elsif j=6 then '||LCK_NAME||':=bitand(vl,1)>0; RO:=bitand(vl,2)>0;'||LF||
        TB2||'elsif j=7 then '||STC_NAME||':=vl; elsif j=8 then v$self := false; if vl like ''%rowtype'' then v$lck := null; else v$lck := vl; end if;'||LF||
        TB2||'elsif j=9 then PF:=nvl(vl,'||current_mtd_archive||'); '||KEY_NAME||':=valmgr.init_key(PF);',sc);
    b := true;
    while not i is null loop
     if ctl(i).err_code=0 then
      if ctl(i).grid is null then
        ss := ctl2txt(i,'vl');
        if not ss is null and i<>START_CTLS then
          s := LF||TB2||'elsif j='||i||' then ';
          if ctl(i).base like GEN_TABLE then
              ss := 'lib.set_'||table_func(ctl(i).base)||'_list(vl,'||ctl2txt(i)||')';
		  elsif lib.is_nvarchar_based(ctl(i).base) then
			  ss := ctl2txt(i,'lib.decode_national_string(vl)');
          elsif ctl(i).fname like 'REF@_%' then
              ss := 'if substr(vl,1,1)=''R'' then '
                 ||ctl2txt(i,class_mgr.interface_package(substr(ctl(i).fname,5))||'.g#value(substr(vl,2),key_=>'||KEY_NAME||')')
                 ||'; else '||ss||'; end if';
          end if;
          lib.put_buf(s||ss||';',sc);
        end if;
      else
        if ctl(i).grid = -1 then
          j := i;
          bb:= true;
        else
          j := ctl(i).grid;
          if ctl(i).err_code=0 then
            bb := false;
          else
            bb := null;
          end if;
        end if;
        if not bb is null then
          if ctl(i).parent is null then
            if b then
              lib.put_buf('e'||LF,sc,false);
              b := false;
            end if;
            if bb then ss:='SG'; else ss:='SC'; end if;
            lib.put_buf('if j='||i||' then '||ss||i||'(vl);'||LF||TB2||'els',sc,false);
          end if;
          ss := 'if p_ctl='||i||' then if GV'||j||'.exists(p_idx) then return ';
          if bb then
            ss := ss||'replace(GV'||j||'(p_idx),lib.GRID_CHAR,rtl.esc$);';
          else
            ss := ss||'lib.get_row_val(GV'||j||'(p_idx),'||ctl(i).colnum||');';
          end if;
          lib.put_buf(ss||' end if;'||LF||TB||'els',gc);
        end if;
      end if;
     end if;
     i := ctl.next(i);
    end loop;
    if b then
      ss := null;
      if sc_logging then
        ss := TB2||'if sTmp is not null then'||LF||
              TB2||TB||'par_eq:=par_eq||sTmp;'||LF||
              TB2||'end if;'||LF;
      end if;
    else
      lib.put_buf(TB2,sc,false);
      ss := TB2||'end if;'||LF;
      if sc_logging then
        ss:= ss||
             TB2||'ii:= GRID_EQ.first;'||LF||
             TB2||'s_gr_ch:= null;'||LF||
             TB2||'while ii is not null'||LF||
             TB2||'loop'||LF||
             TB2||TB||'if GRID_EQ(ii)=''1'' then'||LF||
             TB2||TB||TB||'s_gr_ch:= s_gr_ch||rtl.esc$||chr(mod(ii,127)+1)||chr(trunc(ii/127)+1)||GRID_EQ(ii);'||LF||
             TB2||TB||'end if;'||LF||
             TB2||TB||'ii:= GRID_EQ.next(ii);'||LF||
             TB2||'end loop;'||LF||
             TB2||'if s_gr_ch is not null then'||LF||
             TB2||TB||'par_eq:= par_eq||rtl.esc$||chr(mod(j,127)+1)||chr(trunc(j/127)+1)||chr(3)||replace(s_gr_ch,rtl.esc$,constant.nc);'||LF||
             TB2||'elsif sTmp is not null then'||LF||
             TB2||TB||'par_eq:=par_eq||sTmp;'||LF||
             TB2||'end if;'||LF;
        lib.put_buf(TB2||'GRID_EQ.delete;'||LF,sc,false);
      end if;
    end if;
    lib.add_buf(sc,p_buf);
    lib.put_buf(LF||TB2||'end if;'||LF||
       TB2||'if (j<4 or j>'||START_CTLS||') then'||LF||
       TB2||TB||'ch(j):=true; ct(j):=vl;'||LF||
       TB2||'end if;'||LF||ss||
       TB2||'j:=val.next(j);'||LF||
        TB||'end loop;'||LF||
        case when sc_logging then
             TB||'sc_mgr.write_log('''||current_method_id||''', ''S'',''par_'', par_);'||LF||
             TB||'if par_eq is not null then'||LF||
             TB||TB||'par_eq:= chr(3)||par_eq;'||LF||
             TB||TB||'sc_mgr.add_log(''par_eq'',par_eq);'||LF||
             TB||'end if;'||LF
        end ||
        'end;'||LF2||
        'function '||get_controls_name(current_method_id)||'(p_ctl pls_integer, p_idx pls_integer default null) return varchar2 is'||LF||
        'begin'||LF||TB,p_buf);
    if gc.count>0 then
      lib.add_buf(gc,p_buf);
      gc.delete;
    end if;
    lib.put_buf('if ct.exists(p_ctl) then return ct(p_ctl); end if;'||LF||
        TB||'return null;'||LF||
        'end;'||LF2,p_buf);
    sc.delete;
end;
--
procedure build_check_params(p_def boolean, p_buf in out nocopy dbms_sql.varchar2s) is --@METAGS build_check_params
    s   varchar2(32767);
    ss  varchar2(1000);
    s1  varchar2(15);
    s2  varchar2(15);
    cnd varchar2(15);
    par varchar2(75);
    j   pls_integer;
    l   pls_integer;
    i   pls_integer := ctl.first;
    dps "CONSTANT".integer_table;
    ok  boolean;
begin
    if p_def then
        par:= '(def_ boolean default false, do_gc boolean default false)';
        cnd:= 'def_ or ';
        s1 := ' cc(j):=true;';
        s2 := ' cc:=ch;';
    end if;
    lib.put_buf(
        'procedure check$'||par||' is'||LF||
        TB||'j pls_integer; b boolean;'||LF||
        'procedure chk(val varchar2,j pls_integer) is'||LF||
        'begin b:=ct.exists(j);'||LF||
        TB||'if b and nvl(val,constant.ns)=nvl(ct(j),constant.ns) then if ch.exists(j) then ch.delete(j); else b:=false; end if;'||LF||
        TB||'else if b or not val is null then ch(j):=true;'||s1||' b:=true; end if; ct(j):=val; end if;'||LF||
        'end;'||LF||
        'begin'||s2||LF,p_buf);
    while not i is null loop
      if ctl(i).err_code=0 then
        if ctl(i).parent is null and (i<4 or i>=START_CTLS) then
          if ctl(i).grid is null then
            ss := ctl2txt(i);
            if not ss is null then
                s := TB;
                if ctl(i).base like GEN_TABLE then
                    ss := 'lib.get_'||table_func(ctl(i).base)||'_list('||ss||',j)';
                    s := s||'j:=null; ';
                end if;
                if lib.is_nvarchar_based(ctl(i).base) then
                    ss:= 'lib.encode_national_string('||ss||')';
                end if;
                s := s||'chk('||ss||','||i||');';
                dps.delete;
                get_deps(dps,i);
                if dps.count>0 then
                    l := length(s);
                    s := s||' if '||cnd||'b then'||LF;
                    ok:= false;
                    for jj in 1..dps.count loop
                        j := dps(jj);
                        ss:= ctl2txt(j);
                        if not ss is null then
                            ok:= true;
							if lib.is_nvarchar_based(ctl(j).base) then
								ss:= 'lib.encode_national_string('||ss||')';
							end if;
                            s := s||TB2||'chk('||ss||','||j||');'||LF;
                        end if;
                    end loop;
                    if ok then
                        s := s||TB||'end if;';
                    else
                        s := substr(s,1,l);
                    end if;
                end if;
                s := s||LF;
                lib.put_buf(s,p_buf);
            end if;
          elsif ctl(i).grid = -1 then
            if p_def then
                lib.put_buf(TB||'if do_gc then'||LF||TB,p_buf);
            end if;
            lib.put_buf(TB||'GC'||i||';'||LF,p_buf);
            if p_def then
                lib.put_buf(TB||'end if;'||LF,p_buf);
            end if;
          end if;
        end if;
      end if;
      i := ctl.next(i);
    end loop;
    dps.delete;
    lib.put_buf('end;'||LF2,p_buf);
end;
--
function get_qual_name(p_ctl pls_integer) return varchar2 is
    i   pls_integer;
    j   pls_integer;
    str varchar2(2000);
    cls varchar2(16);
    qual varchar2(700);
begin
    cls := ctl(p_ctl).class;
    qual:= ctl(p_ctl).qual;
    j := ctl(p_ctl).var_idx;
    i := instr(qual,'.');
    str := substr(qual,1,i-1);
    if str='%THIS%' then
        cls := current_method_class;
        str := nvl(this_str,str);
    elsif str='%SYSTEM%' then
        cls := constant.SYSTEM;
        str := nvl(sys_str,str);
    elsif j is null and str in ('%PARAM%','%VAR%') then
        str := null;
        qual:= substr(qual,i+1);
        if i>6 then
          j := qual2var_idx(par,qual);
        else
          j := -qual2var_idx(var,qual);
        end if;
        if not j is null then
          ctl(p_ctl).var_idx := j;
          ctl(p_ctl).qual := qual;
        end if;
        i := instr(qual,'.');
        if i=0 then
            i := length(qual)+1;
        end if;
        if str is null then
            str := substr(qual,1,i-1);
        end if;
    end if;
    if j>0 then
      cls := par(j).class;
      qual:= par(j).fname;
    elsif j<0 then
      cls := var(-j).class;
      qual:= var(-j).fname;
    end if;
    str := lib.qual_name(cls,substr(qual,i+1),'\');
    if str is null then
      return qual;
    end if;
    return qual||'/'||str;
end;
--
function build_bindings(p_buf in out nocopy dbms_sql.varchar2s) return boolean is
    ss  varchar2(4000);
    s1  varchar2(1000);
    cc  varchar2(10);
    cmp varchar2(30);
    prf varchar2(30);
    suf varchar2(30);
    j   pls_integer;
    l   pls_integer;
    r   pls_integer;
    p   pls_integer;
    i   pls_integer := bnd.first;
    b   boolean := false;
    procedure check_parent_ctl(p_ctl pls_integer,p_qual varchar2) is
      ct  par_var;
      pr  par_var;
    begin
      ct := ctl(p_ctl);
      if ct.var_idx<>0 and ct.parent is null then
        if ct.var_idx>0 then
          pr := par(ct.var_idx);
        else
          pr := var(-ct.var_idx);
        end if;
        j := 0;
        if pr.base=constant.REFERENCE then
          j := instr(ct.qual,'.',2);
        elsif not p_qual is null then
          j := instr(ct.qual,p_qual,-1);
        end if;
        if j>0 then
          s1 := substr(ct.qual,1,j-1);
          j := ctl.next(p);
          while not j is null loop
            if ctl(j).qual=s1 then
              exit;
            end if;
            j := ctl.next(j);
          end loop;
          if j is null then
            ct.qual := s1;
            if instr(s1,pr.qual||'.')=1 then
              s1:= substr(s1,length(pr.qual)+2);
              b := get_class(s1,pr,pr.qual);
              pr.kind := DBOBJECT;
              pr.qual := ct.qual;
            end if;
            j := ctl.last+1;
            pr.name := 'CT('||j||')';
            pr.err_code := 0;
            ctl(j) := pr;
          end if;
          ctl(p_ctl).parent := j;
          if dep.exists(j) then
            dep(j) := dep(j)||p_ctl||',';
          else
            dep(j) := p_ctl||',';
          end if;
        end if;
      end if;
    end;
begin
    while not i is null loop
      l := bnd(i).left;
      r := bnd(i).right;
      if l>0 and r>0 then
        cc:= bnd(i).cond;
        ss:= null;
        if ctl(l).parent is null then
          s1 := ctl2txt(l,'CT('||r||')');
        else
          s1 := null;
        end if;
        if cc='DEF' then
          if not s1 is null then
            ss := ' then'||LF||TB||'if b and CT('||l||') is null then '||s1||'; end if;'||LF;
          end if;
        else
          prf := 'CT('; suf := ')';
          if cc='LIKE' then
            cmp := ' not like '; ss := '|| ''%''';
          elsif cc='EQ'  then
            cmp := ' != ';
          elsif cc='EQN' then
            cmp := ' != '; prf := 'nvl(CT(';suf := '),constant.ns)';
          elsif cc='NEQ' then
            cmp := ' = ';
          else
            if ctl(l).base =constant.GENERIC_NUMBER then
              prf := 'to_number(CT(';   suf := '))';
            end if;
            if cc='GT'  then
              cmp := ' <= ';
            elsif cc='GEQ' then
              cmp := ' < ';
            elsif cc='LT'  then
              cmp := ' >= ';
            elsif cc='LEQ' then
              cmp := ' > ';
            end if;
          end if;
          if cc='IN' then
            if ctl(l).fname like 'REF@_%' then
              cmp := 'C_VALUE';
            else
              cmp := 'ID';
            end if;
            prf:= '0';
            p := instr(ctl(r).fname,'.');
            if p>0 then
              suf := substr(ctl(r).fname,1,p-1);
              p := instr(ctl(r).fname,'.',p+1,2);
              if p>0 then
                prf := substr(ctl(r).fname,p+5,1);
              end if;
            else
              suf := ctl(r).fname;
            end if;
            ss := cmp||'=CT('||l||') and collection_id=CT('||r||') and rownum=1;';
            if prf<>'0' then
              cmp:= nvl(substr(ctl(r).fname,instr(ctl(r).fname,'.',-1)+1),ctl(r).class);
              ss := TB||'if '||KEY_NAME||' is null then'||LF||
                   TB2||'select count(1) into n from '||suf||
                      case when prf='1' then ' partition('||suf||'#0) where key=1000 and ' else ' where ' end||ss||LF||
                    TB||'else if '||KEY_NAME||'<0 then n:=valmgr.get_key('''||cmp||'''); else n:='||KEY_NAME||'; end if;'||LF||
                   TB2||'select count(1) into n from '||suf||
                      case when prf='2' then '#PRT' end||' where key>=n and '||ss||LF||
                    TB||'end if;';
            else
              ss := TB||'select count(1) into n from '||suf||' where '||ss;
            end if;
            ss := TB||'if not (CT('||l||') is null or CT('||r||') is null) then'||LF
               || ss||LF||TB||'if n=0 then';
            cmp:= ' not in ';
            suf:= ' end if;';
          else
            ss := TB||'if '||prf||l||suf||cmp||prf||r||suf||ss||' then';
            suf:= null;
          end if;
          if not s1 is null then
            if cc in ('IN','NEQ','GT','LT') then
              s1 := replace(s1,'CT('||r||')','null');
            end if;
            ss := ss||' if u or b and cc.exists('||r||') then '||s1||'; else';
            suf:= suf||' end if;';
          end if;
          ss := ss||LF||
               TB2||'s := s||''('||get_qual_name(l)||')'||cmp||'('||get_qual_name(r)||')''||rtl.LF$;'||LF||
               TB2||'ss:=ss||'''||l||',''; bb('||l||'):=true;'||suf;
          if not (s1 is null or cc in('IN','EQN','NEQ')) then
            ss := ss||LF||TB||'elsif b and CT('||l||') is null and not CT('||r||') is null then '||s1||';';
          end if;
          if cc='EQ' then
            s1 := ctl2txt(r,'CT('||l||')');
            if not s1 is null then
              ss := ss||LF||TB||'elsif b and CT('||r||') is null and not CT('||l||') is null then '||s1||';';
            end if;
          end if;
          ss := 'or bb.exists('||l||') then bb.delete('||l||');'||LF||ss||' end if;'||LF;
        end if;
        if ss is null then
          --stdio.put_line_buf(i||':'||ctl(l).err_code||'.'||ctl(r).err_code);
          --stdio.put_line_buf(l||'.'||ctl(l).qual||' '||bnd(i).cond||' '||r||'.'||ctl(r).qual);
          j := ctl(l).err_code;
          if j=0 then
            j := ERR_CTL_BAD_COMPARE;
            --ctl(l).err_code := j;
          end if;
          bnd(i).left := -j;
          bnd(i).lqual:= ctl(l).qual;
          j := ctl(r).err_code;
          if j=0 then
            j := ERR_CTL_BAD_COMPARE;
            --ctl(r).err_code := j;
          end if;
          bnd(i).right := -j;
          bnd(i).rqual := ctl(r).qual;
        else
          if not b then
            lib.put_buf(
              'CC RTL.BOOLEAN_TABLE;'||LF||
              'BB RTL.BOOLEAN_TABLE;'||LF2, p_buf, false);
            lib.put_buf(
              'procedure check$(def_ boolean default false, do_gc boolean default false);'||LF||
              'procedure binds$(set_ varchar2) is'||LF||
              TB||'s varchar2(30000); ss varchar2(10000); b boolean; u boolean; n number;'||LF||
              'begin if set_<>''1'' then b:=set_<>''3''; u:=set_=''4'';'||LF,p_buf);
            b := true;
          end if;
          lib.put_buf('if cc.exists('||l||') or cc.exists('||r||') '||ss||'end if;'||LF,p_buf);
        end if;
      end if;
      i := bnd.next(i);
    end loop;
    if b then
      lib.put_buf(
        TB||'check$; ch:=cc; if not s is null then ct(8):=ss; ch(8):=true; ct(9):=s; ch(9):=true; end if;'||LF||
        'end if;'||LF||
        'end;'||LF2,p_buf);
      i := bnd.first;
      p := ctl.last;
      if p>ctl_count then
        while not i is null loop
          l := bnd(i).left;
          r := bnd(i).right;
          if l>ctl_count and r>0 then
            check_parent_ctl(l,bnd(i).lqual);
          end if;
          if r>ctl_count and l>0 then
            check_parent_ctl(r,bnd(i).rqual);
          end if;
          i := bnd.next(i);
        end loop;
      end if;
    end if;
    return b;
end;
--
procedure dump(p_tbl par_var_arr,p_text varchar2,p_add boolean default false) is
    i   pls_integer := p_tbl.first;
    txt varchar2(1000);
begin
    stdio.put_line_buf('******** '||p_text);
    while not i is null loop
      stdio.put_line_buf(rpad(i,3)||rpad(p_tbl(i).err_code,3)||rpad(nvl(p_tbl(i).kind,0),2)||rpad(p_tbl(i).self,16)||rpad(p_tbl(i).base,16)||rpad(p_tbl(i).class,16)||p_tbl(i).qual,false);
      if p_add then
        if not p_tbl(i).parent is null then
            stdio.put_line_buf(' - '||p_tbl(i).parent,false);
        end if;
        if dep.exists(i) then
            stdio.put_line_buf(' * '||dep(i),false);
        end if;
        txt := ctl2txt(i);--nvl(ctl2txt(i),p_tbl(i).name);
      else
        txt := p_tbl(i).name;
      end if;
      stdio.put_line_buf(' <'||txt||'>');
      i :=  p_tbl.next(i);
    end loop;
end;
--
procedure initialize(p_meth_id varchar2)  is --@METAGS initialize
    v_prop  varchar2(2000);
    v_pack  varchar2(30);
    v_sname varchar2(16);
    v_text  varchar2(1);
    b boolean;
begin
    err_buf := null;
    select class_id,short_name,name,result_class_id,flags,package_name,
           access_group,accessibility,properties,text_type,nvl(form_id,id),belong_group,
           src_id,ext_id,propagate
      into current_method_class,current_method_sname,current_method_name,
           current_method_result,current_method_flags,current_method_pack,
           current_access_group,current_accessibility,v_prop,v_text,
           current_method_form,current_belong_group,current_src_id,current_ext_id,current_mtd_archive
      from methods where id = p_meth_id;
    if current_src_id is null then
      current_add_form := null;
      if current_method_pack is null then
        current_method_pack := method.make_pack_name(current_method_class,current_method_sname,p_meth_id);
      end if;
    else
      current_add_form := current_method_form;
      select nvl(form_id,id), short_name, package_name
        into current_method_form, v_sname, v_pack
        from methods where id = current_src_id;
      if current_method_pack is null then
        if v_pack is null then
          current_method_pack := method.make_pack_name(current_method_class,v_sname,current_src_id);
        else
          current_method_pack := v_pack;
        end if;
      end if;
    end if;
    current_method_id := p_meth_id;
    current_method_interface := interface_package_name(p_meth_id);
    current_method_obj := current_method_flags not in (constant.METHOD_STATIC,constant.METHOD_CRITERION,constant.METHOD_GROUP);
    current_buffer_size:= method.extract_property(v_prop,'BUF');
    current_method_priority := method.extract_property(v_prop,'PRIORITY');
    if current_buffer_size>'0' then
        current_buffer_size := current_buffer_size||'*1024';
    else
        current_buffer_size := '16384+8192*'||DBG_NAME;
    end if;
    current_mtd_logparams:= substr(nvl(method.extract_property(v_prop,'PARAMS'),'N'),1,1);
    current_mtd_critical := method.extract_property(v_prop,'CRITICAL')='Y';
    current_check_obj := -1;
    if nvl(substr(method.extract_property(v_prop,'COMPILER'),9,1),'1')<>'0' then
      current_check_obj := v_text;
    end if;
    b := current_mtd_critical;
    if current_method_flags = constant.METHOD_REPORT then
      if current_method_priority is null then
        current_method_priority := 1000;
      else
        b := b or current_method_priority < 1000;
      end if;
    elsif current_method_priority is null then
      current_method_priority := 100;
    else
      b := b or current_method_priority < 100;
    end if;
    if b then
      current_mtd_logparams := '+'||current_mtd_logparams;
    end if;
    if current_mtd_archive = '1' then
      current_arch_pack := method.conv_pack_name(current_method_pack,true);
    else
      current_arch_pack := null;
    end if;
    current_mtd_archive := nvl(substr(method.extract_property(v_prop,'COMPILER'),12,1),'1');
    if current_ext_id is null then
      add_pars;
      add_ctls;
      add_binds;
    end if;
end initialize;
--
function build_var_declarations return varchar2 is --@METAGS build_var_declarations
    d varchar2(32757);
    procedure put_pars(p_par par_var_arr) is
      i pls_integer := p_par.first;
    begin
      while not i is null loop
          if i=1 then
              d := d || LF;
          end if;
          d := d  || TB || p_par(i).name || TB ||
               class2type( p_par(i).self, p_par(i).flag, current_method_pack ) || ';' || LF;
          i := p_par.next(i);
      end loop;
    end;
begin
    if current_method_flags = constant.METHOD_GROUP then
        d := '32767';
    else
        d := constant.REF_PREC;
    end if;
    d :=TB||OBJ_NAME||TB||'VARCHAR2('||d||');'  || LF ||
        TB||CLS_NAME||TB||'VARCHAR2('||constant.REF_PREC||');'  || LF ||
        TB||MSG_NAME||TB||'VARCHAR2(128);' || LF ||
        TB||INF_NAME||TB||'VARCHAR2(8000);'|| LF ||
        TB||STC_NAME||TB||'PLS_INTEGER;'|| LF ||
        TB||DBG_NAME||TB||'PLS_INTEGER;'   || LF ||
        TB||KEY_NAME||TB||'NUMBER;'   || LF ||
        TB||LCK_NAME||TB||'BOOLEAN;' || LF ||
        case when current_arch_pack is not null then
        TB||AP_MODE_NAME||TB||'BOOLEAN;'||LF
        end;
    put_pars(par);
    put_pars(var);
    return d||LF;
end;
--
/**
 *   Формирует спецификацию интерфейсного пакета операции.
 */
function build_interface_definition return varchar2 is
    d varchar2(32757);
    r varchar2(61);
begin
    if current_method_flags = constant.METHOD_LIBRARY then
        message.sys_error(constant.KERNEL_ERROR,'LIBRARY',current_method_sname);
    elsif current_method_flags = constant.METHOD_TRIGGER then
        message.sys_error(constant.KERNEL_ERROR,'TRIGGER',current_method_sname);
    elsif not current_method_result is null then
        if current_method_flags = constant.METHOD_NEW then
          r := constant.RTL_REFERENCE;
        else
          r := constant.RTL_DBOBJECT;
        end if;
        r := class2type(current_method_result,r,null);
    end if;
    d := 'PACKAGE ' || current_method_interface || ' IS' || LF2 ||
        build_var_declarations;
    if not r is null then
        d := d ||TB||
             result_name(current_method_id)|| TB || r || ';' || LF2;
    end if;
    return d ||
         TB||'PROCEDURE '|| validate_name(current_method_id)||';' || LF ||
         TB||'PROCEDURE '|| execute_name (current_method_id)||';' || LF ||
         TB||'PROCEDURE '|| process_name (current_method_id)||'(EXE_ VARCHAR2,GET_ OUT VARCHAR2,SET_ VARCHAR2 DEFAULT NULL);' || LF ||
         TB||'PROCEDURE '||zap_param_name(current_method_id)||'(SET_ VARCHAR2 DEFAULT NULL);' || LF ||
         TB||'PROCEDURE '||log_param_name(current_method_id)||';' || LF ||
         TB||'PROCEDURE '||set_param_name(current_method_id)||'(PAR_ VARCHAR2);' || LF ||
         TB||'PROCEDURE '||REQ_NAME||'(OBJ_ VARCHAR2,CLS_ VARCHAR2,SELF_ BOOLEAN DEFAULT TRUE,CHK_ BOOLEAN DEFAULT TRUE,KEY_ NUMBER DEFAULT NULL,INFO_ VARCHAR2 DEFAULT NULL);'||LF||
         TB||'FUNCTION  '||get_param_name(current_method_id)||'(OK OUT VARCHAR2) RETURN VARCHAR2;' || LF ||
         TB||'FUNCTION  '||get_param_qual(current_method_id)||'(P_QUAL VARCHAR2, P_IDX PLS_INTEGER DEFAULT NULL) RETURN VARCHAR2;' || LF ||
         TB||'FUNCTION  '||get_controls_name(current_method_id)||'(P_CTL PLS_INTEGER, P_IDX PLS_INTEGER DEFAULT NULL) RETURN VARCHAR2;'||LF||
         TB||'FUNCTION  '||chk_controls_name(current_method_id)||'(C_FIRST OUT PLS_INTEGER,C_SEP OUT PLS_INTEGER,C_LAST OUT PLS_INTEGER,C_ERR OUT PLS_INTEGER,B_COUNT OUT PLS_INTEGER,B_ERR OUT PLS_INTEGER) RETURN VARCHAR2;'||LF2||
        'END;';
end;
--
procedure build_zap_params(p_bnd boolean, p_buf in out nocopy dbms_sql.varchar2s) is --@METAGS build_zap_params
    b varchar2(32757);
    f varchar2(1);
    i pls_integer;
    procedure make_null(p_var varchar2,p_flag varchar2,p_class varchar2) is
    begin
      if p_flag=constant.RTL_DBROW then
        if class_mgr.needs_oracle_type(p_class)='1' then
          b := b||TB||class_mgr.interface_package(p_class)||'.set$row('||p_var||',null);'||LF;
        else
          b := b||TB||p_var||':=null;'||LF;
        end if;
      elsif p_flag=constant.RTL_DBTABLE then
        b := b||TB||class_mgr.interface_package(p_class)||'.clear$rectbl('||p_var||');'||LF;
      elsif p_flag=constant.RTL_COLLECTION then
        b := b||TB||p_var||':=';
        if class_mgr.needs_oracle_type(p_class)='1' then
          b := b||class_mgr.make_otype_table(p_class);
        else
          b := b||class_mgr.interface_package(p_class)||'.'||class_mgr.make_table_rowname(p_class);
        end if;
        b := b||'();'||LF;
      elsif p_flag=constant.RTL_TABLE then
        b := b||TB||p_var||'.delete;'||LF;
      else
        b := b||TB||p_var||':=null;'||LF;
      end if;
    end;
begin
    if not current_method_result is null then
        if current_method_flags = constant.METHOD_NEW then
          f := constant.RTL_REFERENCE;
        else
          f := constant.RTL_DBOBJECT;
        end if;
        make_null(result_name(current_method_id),f,current_method_result);
    end if;
    -- Инициализация переменных
    i := var.first;
    while not i is null loop
      make_null(var(i).name,var(i).flag,var(i).self);
      i := var.next(i);
    end loop;
    -- Инициализация параметров
    i := par.first;
    while not i is null loop
      make_null(par(i).name,par(i).flag,par(i).self);
      i := par.next(i);
    end loop;
    --
    b := b || TB ||'if set_ != ''0'' then'||LF||
              TB2||'rtl.set_debug('||DBG_NAME||',''B'','||current_buffer_size||');'||LF||
              TB2||'ch.delete; ct.delete(5,ct.last);';
    if p_bnd then
        b := b||' bb.delete; cc.delete;';
    end if;
    if ctl.exists(0) then
        b := b||LF||TB2||SYS_NAME||' := valmgr.static(''SYSTEM'',true); ct(0) := '||SYS_NAME||'; ch(0) := true;';
    end if;
    b := b||LF||TB2||'ct(1) := '||OBJ_NAME||'; ch(1) := true; ct(2) := '||MSG_NAME||'; ct(3) := '||INF_NAME||';'||LF;
    -- grid controls initialization
    i := ctl.next(START_CTLS);
    while not i is null loop
      if ctl(i).grid=-1 and ctl(i).err_code=0 then
        b := b || TB2 || 'GV' || i || '.delete; GF' || i || '.delete;' || LF;
      end if;
      i := ctl.next(i);
    end loop;
    b := b ||
        TB ||'end if;'||LF||
        TB ||'BF:=valmgr.init_class('||CLS_NAME||'); dbms_session.free_unused_user_memory;'||LF||
        case when sc_logging then
            TB ||'C$.delete;'||LF||
            TB ||'sc_mgr.write_log('''||current_method_id||''', ''Z'',''set_'', set_);'||LF
        end;
    if current_method_flags = constant.METHOD_GROUP then
        b := b ||TB||'lib.set_refs_list('||OBJ_NAME||',V$OBJ_TBL);'||LF;
    elsif current_method_flags = constant.METHOD_REPORT then
        b := b ||TB||'--secadmin.createsynonyms('''||current_method_id||''');'||LF;
    end if;
    lib.put_buf(
      'procedure '||zap_param_name(current_method_id)||'(set_ varchar2 default null) is'||LF||
      'begin'||LF,p_buf);
    lib.put_buf(b,p_buf);
    lib.put_buf('end;',p_buf);
end;
--
procedure process_log(par_   varchar2, qual_ varchar2,
                      class_ varchar2, flag_ varchar2,
                      text_  in out nocopy dbms_sql.varchar2s,
                      pref_  varchar2,
                      suff_  varchar2,
                      sysfields_ boolean) is
    i       pls_integer;
    j       pls_integer;
    v_pref  varchar2(20);
    v_suff  varchar2(30);
    v_par   varchar2(1000);
    v_qual  varchar2(1000);
    v_text  varchar2(8000);
    v_flag  varchar2(1);
    v_tbl   boolean;
    v_mode  boolean;
    v_class lib.class_info_t;
    v_quals "CONSTANT".varchar2_table;
    v_types "CONSTANT".refstring_table;
begin
    if flag_ = constant.RTL_REFERENCE then
      v_text :=  'rtl.log_param(v,'''||par_||''','
        ||class_utils.attr_vals_field_name(constant.REFERENCE, qual_, null, null, class_, true, true)
        ||','''||constant.REFERENCE||''');';
      if instr(v_text,'.class$(')>0 then
        v_text := 'begin '||v_text||' exception when rtl.CLASS_PROCESSING then rtl.log_param(v,'''
          ||par_||''','||qual_||','''||constant.REFERENCE||'''); end;';
      end if;
      lib.put_buf(TB||v_text||LF,text_);
    else
      v_par := par_; v_qual:= qual_; v_flag:= flag_;
      v_tbl := v_flag in (constant.RTL_TABLE,constant.RTL_COLLECTION,constant.RTL_DBTABLE);
      if v_tbl then
        if v_flag=constant.RTL_DBTABLE then
          v_pref:= '.id';
        else
          v_par := v_par||'(''||i||'')';
          v_qual:= v_qual||'(i)';
          if v_flag=constant.RTL_COLLECTION then
            lib.put_buf(
                 TB||'if '||qual_||' is null then rtl.log_param(v,'''||pref_||par_||'.COUNT'',null,'''||constant.GENERIC_NUMBER||'''); else'||LF,text_);
            v_flag := constant.RTL_DBROW;
          end if;
        end if;
        lib.put_buf(
               TB||'rtl.log_param(v,'''||pref_||par_||'.COUNT'','||qual_||v_pref||'.count,'''||constant.GENERIC_NUMBER||''');'||LF||
               TB||'i := '||qual_||v_pref||'.first;'||LF||
               TB||'while not i is null loop'||LF,text_);
      end if;
      if lib.class_exist(class_,v_class) then
        if v_class.base_class_id=constant.STRUCTURE
          or v_flag in (constant.RTL_DBROW,constant.RTL_DBTABLE)
        then
          v_suff := null;
          if v_flag=constant.RTL_DBTABLE then
            v_suff := '(''||i||'')';
            v_mode := null;
          else
            v_mode := not v_flag=constant.RTL_DBROW;
          end if;
          lib.get_fields(v_quals,v_types,class_,v_mode);
          if sysfields_ then
            i := v_quals.first;
          else
            i := v_quals.next(0);
          end if;
          while not i is null loop
            j := instr(v_quals(i),'.');
            if v_mode and i>0 then
              v_text := class_mgr.qual2elem(substr(v_quals(i),j+1),v_qual);
            else
              v_text := v_qual||'.'||substr(v_quals(i),1,j-1);
            end if;
            process_log(v_par||substr(v_quals(i),j),v_text,v_types(i),constant.RTL_DBOBJECT,text_,pref_,v_suff,false);
            i := v_quals.next(i);
          end loop;
        else
          v_suff := null;
          if not suff_ is null then
            if substr(v_qual,length(v_qual)-2,3)<>'.ID' then
              v_suff := ' end if;';
            end if;
            v_qual := v_qual||'(i)';
          end if;
          v_text := 'rtl.log_param(v,'''||pref_||v_par||suff_||''','
            ||class_utils.attr_vals_field_name(v_class.base_class_id,v_qual,v_class.class_id,rtl.bool_char(v_class.kernel),v_class.class_ref,true,true)
            ||','''||v_class.base_class_id||''');';
          if v_class.base_class_id=constant.REFERENCE and instr(v_text,'.class$(')>0 then
            v_text := 'begin '||v_text||' exception when rtl.CLASS_PROCESSING then rtl.log_param(v,'''
              ||pref_||v_par||suff_||''','||v_qual||','''||v_class.base_class_id||'''); end;';
          end if;
          if v_suff is not null then
            v_text := 'if '||substr(v_qual,1,length(v_qual)-3)||'.exists(i) then '||v_text||v_suff;
          end if;
          lib.put_buf(TB||v_text||LF,text_);
        end if;
      end if;
      if v_tbl then
        v_suff := null;
        if flag_=constant.RTL_COLLECTION then
          v_suff := ' end if;';
        end if;
        lib.put_buf(
           TB||'i := '||qual_||v_pref||'.next(i);'||LF||
           TB||'end loop;'||v_suff||LF, text_);
      end if;
    end if;
end;
--
procedure build_log_params(p_buf in out nocopy dbms_sql.varchar2s) is --@METAGS build_log_params
    v varchar2(1000);
    i pls_integer;
begin
    if current_method_flags = constant.METHOD_GROUP then
        v := 'TABLE';
    else
        v := constant.REFERENCE;
    end if;
    lib.put_buf(
         'procedure '||log_param_name(current_method_id)||' is' || LF ||
          TB||'v integer; i pls_integer;'||LF||
          'begin'||LF||
          TB||'select '||inst_info.auditor||'.diary_id.nextval into v from dual;'||LF||
          TB||'rtl.write_log(''P'',null,v,'''||current_method_id||''');'||LF||
          TB||'rtl.log_param(v,''%THIS%'','||OBJ_NAME||','''||v||''');'||LF||
          TB||'rtl.log_param(v,''%CLASS%'','||CLS_NAME||','''||constant.GENERIC_STRING||''');'||LF,
         p_buf);
    -- Журналирование параметров
    i := par.first;
    while not i is null loop
      if par(i).dir='O' then null;
      else
         process_log(par(i).qual,par(i).name,par(i).self,par(i).flag,p_buf,null,null,true);
      end if;
      i := par.next(i);
    end loop;
    -- Журналирование переменных
    i := var.first;
    while not i is null loop
      process_log(var(i).qual,var(i).name,var(i).self,var(i).flag,p_buf,'%VAR%.',null,true);
      i := var.next(i);
    end loop;
    lib.put_buf('end;',p_buf);
end;
--
procedure build_log_vals(p_buf in out nocopy dbms_sql.varchar2s) is
i pls_integer;
begin
  lib.put_buf(LF2 ||
       'procedure save_vals (vals in out nocopy rtl.string_table, b boolean) is' || LF ||
       'begin' || LF ||
       TB || 'vals.delete;' || LF,p_buf);
  -- Сохранение скалярных параметров и переменных операции
  i:= quals.first;
  while not i is null loop
    lib.put_buf(
      TB || 'vals(' || i || '):= ' ||
      class_utils.attr_vals_field_name(quals(i).base,
                                       substr(quals(i).q,instr(quals(i).q,';',-1)+1),
                                       null,'0','0',false,true)||';'||LF,
      p_buf);
    i := quals.next(i);
  end loop;
  i := quals.first;
  if not i is null then
    lib.put_buf(TB || 'if b then' || LF, p_buf);
    while not i is null loop
      lib.put_buf(TB2 || 'Q$('||i||'):= '''|| substr(quals(i).q,1,instr(quals(i).q,';')-1)|| ''';'||LF, p_buf);
      i := quals.next(i);
    end loop;
    lib.put_buf(TB || 'end if;' || LF, p_buf);
  end if;
  lib.put_buf(
      'end;' || LF ||
      'procedure log_vals is' || LF ||
      'i pls_integer;' || LF ||
      'begin' || LF ||
      TB || 'save_vals(V$2,false);' || LF ||
      TB || 'i:= V$2.first;'  || LF ||
      TB || 'while not i is null loop' || LF ||
      TB2   || 'if V$1(i) is null and V$2(i) is null or V$1(i)=V$2(i) then null; else ' || LF ||
      TB2   || TB || 'sc_mgr.write_log('''||current_method_id||''', ''PLPCALL'',Q$(i),V$2(i));' || LF ||
      TB2   || 'end if;' || LF ||
      TB2   || 'i:= V$2.next(i);' || LF ||
      TB || 'end loop;' || LF ||
      TB || 'V$1.DELETE;V$2.DELETE;Q$.DELETE;' || LF ||
      TB || 'dbms_session.free_unused_user_memory;' || LF ||
      'end;',p_buf);
end;
--
procedure build_log_colls(p_buf in out nocopy dbms_sql.varchar2s) is
i pls_integer;
b boolean:= false;
name_var varchar2(1000);
qual varchar2(1000);
t varchar2(32);
begin
  lib.put_buf(LF2 ||
      'procedure log_colls is' || LF ||
      'i pls_integer:=0;' || LF ||
      'begin' || LF,p_buf);
  -- Журналирование изменившихся идентификаторов коллекций
  i:= quals.first;
  while not i is null loop
    if quals(i).arr then
      b:= true; -- qual.q(i) == qual,name_var;
      name_var:= substr(quals(i).q,instr(quals(i).q,';')+1);
      qual:= substr(quals(i).q,1,instr(quals(i).q,';')-1);
      if qual like '/%VAR/%.%' escape '/' then
        t:= '%VAR%.';
        qual:= substr(qual,length(t)+1);
      else
        t:= '%PAR%.';
        if qual like '/%PAR/%.%' escape '/' then
          qual:= substr(qual,length(t)+1);
        end if;
      end if;
      lib.put_buf(
      TB || 'i:= i+1;' || LF ||
      TB || 'if (not C$.exists(i) and ' || name_var || ' is not null) or (C$.exists(i) and not (C$(i) is null and ' || name_var || ' is null or C$(i)=' || name_var || ')) then' || LF ||
      TB || TB || 'C$(i):= ' || name_var || ';' || LF ||
      TB || TB || 'sc_mgr.write_coll(' || name_var || ',''' || lib.class_target(quals(i).cl) ||  ''', ''' ||
                t || current_method_class || '.' || current_method_sname ||'.' || qual ||''');'|| LF ||
      TB || 'end if;' || LF,p_buf);
    end if;
    i := quals.next(i);
  end loop;
  if not b then
    lib.put_buf(TB || 'null;' || LF,p_buf);
  end if;
  lib.put_buf('end;',p_buf);
end;
--
procedure add_err_text(p_code pls_integer,p_mes1 varchar2, p_mes2 varchar2) is
  s varchar2(30);
begin
  s := get_err_code(p_code);
  if not s is null then
    err_buf := err_buf||message.get_text(constant.METH_ERROR,s,p_mes1,p_mes2)||LF;
  end if;
exception when value_error then null;
end;
--
procedure get_errors(d in out nocopy varchar2, c in out nocopy pls_integer, b in out nocopy pls_integer) is
  i pls_integer;
  l pls_integer;
  r pls_integer;
begin
  err_buf := null;
  d := null;
  c := 0;
  i := ctl.first;
  while not i is null loop
    l := ctl(i).err_code;
    if l<>0 then
      add_err_text(l,ctl(i).name,ctl(i).qual||' - '||ctl(i).self);
      d := d||','||i;
      c := c+1;
    end if;
    i := ctl.next(i);
  end loop;
  i := bnd.first;
  b := 0;
  while not i is null loop
    l := bnd(i).left;
    r := bnd(i).right;
    if l<ERR_BND_DEFVAL then
      add_err_text(l,bnd(i).lqual||' '||bnd(i).cond||'('||i||') '||bnd(i).rqual, null);
      b := b+1;
    else
      if l<0 and l>ERR_BND_OPERATOR then
        add_err_text(-l,bnd(i).cond||'('||i||')',bnd(i).lqual);
        b := b+1;
      end if;
      if r<0 and l<>r and r>ERR_BND_OPERATOR then
        add_err_text(-r,bnd(i).cond||'('||i||')',bnd(i).rqual);
        if l>=0 then
          b := b+1;
        end if;
      end if;
    end if;
    i := bnd.next(i);
  end loop;
  if not err_buf is null then
    err_buf := '---------------------------------------------------'||LF
      ||'*** '||current_method_class||'.'||current_method_sname||': Controls ('
      ||ctl.first||' - '||ctl_count||' - '||ctl.last||' - '||c||'), Bindings: ('||bnd.count||' - '||b||')'||LF
      ||err_buf||'---------------------------------------------------'||LF;
  end if;
  if d is null then
    d := 'null';
  else
    d := ''''||substr(d,2)||'''';
  end if;
end;
--
/**
 *   Формирует тело интерфейсного пакета операции.
 */
procedure build_interface_body is
    v   varchar2(32000);
    e   varchar2(32000);
    e_  varchar2(32000);
    d   varchar2(32000);
    s   varchar2(50);
    c   varchar2(50);
    p   varchar2(50);
    b   boolean;
    is_constructor boolean;
    is_group boolean;
    i   pls_integer;
    j   pls_integer;
    buf dbms_sql.varchar2s;
begin
    d := LF2||
        'procedure '||process_name(current_method_id)||'(exe_ varchar2, get_ out varchar2, set_ varchar2 default null) is'||LF||
        TB||'cls_ varchar2('||constant.REF_PREC||'); obj_ varchar2('||constant.REF_PREC||'); msg_ varchar2(1000);'||LF||
        TB||'def_ boolean; run_ number; b boolean; x pls_integer; g number; s pls_integer;'||
        case when sc_logging then ' save_ boolean;' end ||
        'begin get_:=''0''; b:=set_<>''0''; def_:=false; x:=exe_;'||LF||
        case when sc_logging then
            TB||'save_:= bitand(x,1)=0 and I=''%PLPCALL%'' and M=''DEFAULT'';'||LF||
            TB||'if I=''%PLPCALL%'' and M=''VALIDATE'' and x>=0 and x<=5 and bitand(x,2)=0 and bitand(x,1)=0 then log_vals; end if;'||LF||
            TB||'sc_mgr.write_log('''||current_method_id||''', ''P'',''exe_set_'', exe_||set_);'||LF
        end ||
        TB||'if x>=0 and x<=5 and bitand(x,2)=0 then'||LF||
        TB||'def_ := bitand(x,1)=0 and '||MSG_NAME||'=''DEFAULT'';'||LF||
        TB||'if PF is null then PF:='||current_mtd_archive||'; '||KEY_NAME||':=valmgr.init_key(PF); end if;'||LF||
        case when current_arch_pack is null or not dict_mgr.option_enabled('ORM.ARC.PACK') then
            null
        when current_method_obj then
          rtl.bool_char(current_method_flags = constant.METHOD_OPERATION, '', TB||'if def_ and '||INF_NAME||' is null then'||LF)||
          TB||TB||AP_MODE_NAME||':=false;'||LF||         -- для пустого списка экземпляров - по умолчанию используется актуальный пакет
          TB||TB||'if '||OBJ_NAME||' is not null then '||LF||
          TB||TB||TB||AP_MODE_NAME||':=nvl('||class_mgr.interface_package(current_method_class)||'.key$('||OBJ_NAME||'),1000)<>1000;'||LF||
          TB||TB||'end if;'||LF||
          rtl.bool_char(current_method_flags = constant.METHOD_OPERATION, '', TB||'end if;'||LF)
        when current_method_flags<>constant.METHOD_GROUP then
          TB||'if def_ and '||INF_NAME||' is null then'||LF||
          TB||TB||AP_MODE_NAME||':=false;'||LF||
          TB||'end if;'||LF
        end ||
        TB||'cls_:='||CLS_NAME||';';
    if current_method_obj then
        d := d ||' obj_:='||OBJ_NAME||';'|| LF;
        is_constructor := current_method_flags=constant.METHOD_NEW;
        if is_constructor then
            d := d||TB||'if instr(cls_,''$$$_'')=1 then cls_:=substr(cls_,5); obj_:=null; end if;'||LF;
        end if;
        d := d||TB||'if not obj_ is null and cls_ is null then cls_:='||
               class_mgr.interface_package(current_method_class)||'.class$(obj_,true,key_=>'||KEY_NAME||'); end if;';
    else
        is_group := current_method_flags=constant.METHOD_GROUP;
    end if;
    if not (nvl(is_group,false) and current_arch_pack is not null and dict_mgr.option_enabled('ORM.ARC.PACK')) then
      d := d ||LF||
           TB||'if def_ and '||INF_NAME||' is null then ' ||
           zap_param_name(current_method_id)||'(set_); end if;' || LF;
    else
      -- для списочных операций просматривается весь список экземпляров,
      -- если будет найден хотя бы один экземпляр, не находящийся в актуальном разделе, будет запускаться архивный пакет
      d := d ||LF||
           TB||'if def_ and '||INF_NAME||' is null then '||LF||
           TB||TB||zap_param_name(current_method_id)||'(set_);'||LF||
           TB||TB||AP_MODE_NAME||':=false;'||LF||         -- для пустого списка экземпляров - по умолчанию используется актуальный пакет
           TB||TB||'for ii in 1..v$obj_tbl.count loop'||LF||
           TB||TB||TB||AP_MODE_NAME||':=nvl('||class_mgr.interface_package(current_method_class)||'.key$(v$obj_tbl(ii)),1000)<>1000;'||LF||
           TB||TB||TB||'if ' ||AP_MODE_NAME||' then exit; end if;'||LF||
           TB||TB||'end loop;'||LF||
           TB||'end if;'||LF;
    end if;
    --Если операция абсолютно доступна и может быть активизирована пользователем,то
    --не надо проверять sequrity
    if current_accessibility = 2 then null;
    else
      if is_group then
        d := d || TB ||'obj_:=''$TABLE$'';'||LF||TB||
           'if not security.check_object_rights(v$obj_tbl,rtl.USR,'''||nvl(current_src_id,current_method_id)||''','''||current_access_group||''',cls_,'||
           current_accessibility||') then' || LF ;
      elsif current_method_flags = constant.METHOD_CRITERION then
        d := d || TB ||
            'if security.crt_accessible(cls_, ''' ||nvl(current_src_id,current_method_id)|| ''', rtl.USR)=''0'' then' || LF;
      else
        d := d || TB ||
            'if security.mtd_accessible(cls_,'''||nvl(current_src_id,current_method_id)||''',rtl.USR,obj_,'''||current_access_group||''','||
            current_accessibility||')=''0'' then' || LF;
      end if;
      d := d ||
            TB2||'rtl.writelog(''L'',obj_||''.''||cls_||''.ACCESS_DENIED'',null,'''||nvl(current_src_id,current_method_id)||''');'||LF||
            TB2||'message.err(-20999,''EXEC'',''NOT_ACCESSIBLE'','''||current_method_sname||''');'||LF||
            TB ||'end if;'|| LF;
    end if;
    if not current_belong_group is null then
        d := d || TB ||
            'if security.Check_BelongGroup('''||current_belong_group||''')=''0'' then' || LF||
            TB2||'message.err(-20999,''EXEC'',''LOCKED_BELONG_GROUP'','''||current_belong_group||''');'||LF||
            TB ||'end if;'|| LF;
    end if;
    if current_method_flags in (constant.METHOD_PRINT,constant.METHOD_REPORT) then
      p := 'message.get_text(''EXEC'',''READ_ONLY''),2';
    else
      p := 'valmgr.set_readonly(true),1';
    end if;
    lib.put_buf(d ||
      TB||'valmgr.check_priority('||current_method_priority||');'||LF||
      TB||'if security.invocation_accessible('''||current_method_id||''',null,RO)=''0'' then' || LF ||
      TB2||'rtl.debug('||p||');'||LF||
      TB||'end if;'|| LF, buf);
    -- Установка/чтение глобальных переменных
    i := var.first;
    while not i is null loop
        v := v || TB || current_method_pack || '.' || var(i).qual || ' := ' || var(i).name || ';'||LF;
        e := e || TB || var(i).name || ' := ' || current_method_pack || '.' || var(i).qual || ';'||LF;
        i := var.next(i);
    end loop;
    if v is not null then
      if current_arch_pack is not null then
        lib.put_buf(TB||'if not nvl('||AP_MODE_NAME||',false) then'||LF||v,buf);
        e := TB||'if not nvl('||AP_MODE_NAME||',false) then'||LF||e;
        v := TB||'else'||LF;
        e_:= TB||'else'||LF;
        i := var.first;
        while not i is null loop
            v := v || TB || current_arch_pack || '.' || var(i).qual || ' := ' || var(i).name || ';'||LF;
            e_:= e_|| TB || var(i).name || ' := ' || current_arch_pack || '.' || var(i).qual || ';'||LF;
            i := var.next(i);
        end loop;
        v := v ||TB||'end if;'||LF;
        e_:= e_||TB||'end if;'||LF;
      end if;
      lib.put_buf(v,buf);
    end if;
    v := null;
    i := par.first;
    while not i is null loop
        v := v || ',' || par(i).name;
        i := par.next(i);
    end loop;
    if is_group then
        s := 'V$OBJ_TBL,';
    else
        s := OBJ_NAME||',';
    end if;
    d := TB||'if bitand(x,1)=0 then'|| LF;
    if current_method_obj then
        d := d ||TB2||'if def_ then security.CheckMethodsCall(rtl.USR,'''||current_method_id||''',obj_,cls_,''VALIDATE'','''
           ||current_method_class||''','''||current_method_sname||'''); end if;'||LF;
    end if;
    if current_check_obj>=0 then
      if current_method_obj then
        d := d ||TB2||'if def_ then set_locks(obj_,cls_,';
        if current_method_flags in (constant.METHOD_PRINT, constant.METHOD_REPORT) then
          d := d ||'null); end if;'||LF;
        elsif current_check_obj>0 then
          d := d ||'true); elsif '||INF_NAME||'=''CANCEL'' then null; else set_locks(obj_,cls_,false); end if;'||LF;
        else
          d := d ||'true); end if;'||LF;
        end if;
      elsif is_group then
        d := d ||TB2||'if def_ then set_locks('||OBJ_NAME||',cls_,true); end if;'||LF;
      end if;
    end if;
    d := d||
      TB2||'s := '||STC_NAME||';'||LF||
      TB2||'if s is null then if stat_lib.disabled then s:=0; else if st is null then st:=stat_lib.check_run('''||current_method_id||'''); end if; s:=st; end if;'||LF||
      TB||TB2||'if bitand(s,2)>0 then g:=stat_lib.set_group_id('''||current_method_id||''',''METHOD'',rtl.bool_char(def_,''DEFAULT'',''VALIDATE''),'''||
      current_method_class||''','''||current_method_sname||''','''||replace(current_method_name,'''','''''')||'''); end if;'||LF||
      TB2||'end if;'||LF||
      TB2||'if bitand(s,2)>0 then msg_:=stat_lib.start_prec(g); if not msg_ is null then rtl.debug(msg_,0); end if; end if;'||LF;
    if current_method_obj and (current_check_obj>0 or is_constructor) then
      d := d||TB2||'obj_ := nvl('||OBJ_NAME||',''0'');'||LF;
    end if;
    lib.put_buf(d,buf);
    d := TB2||method.make_proc_name(current_method_sname,true,current_method_pack)||
      '('||s||CLS_NAME||','||MSG_NAME||','||INF_NAME||v||');'||LF;
    if current_arch_pack is not null then
      d := TB2||'if not nvl('||AP_MODE_NAME||',false) then'||LF||d||
        TB2||'else'||LF||replace(d,current_method_pack,current_arch_pack)||
        TB2||'end if;'||LF;
    end if;
    if current_method_obj and current_check_obj>0 then
      if bitand(current_check_obj,2)=0 then
        d := d||TB2||'if '||OBJ_NAME||'<>obj_ then set_locks('||OBJ_NAME||',cls_,null);';
        if is_constructor then
          d := d||' if '||CLS_NAME||'<>cls_ then '||CLS_NAME||':=cls_; end if;';
        end if;
      elsif is_constructor then
        d := d||TB2||'if '||OBJ_NAME||'=obj_ and '||CLS_NAME||'<>cls_ then null; elsif not '||
          OBJ_NAME||' is null then set_locks('||OBJ_NAME||',cls_,null); '||CLS_NAME||':=cls_;';
      else
        d := d||TB2||'if not '||OBJ_NAME||' is null then set_locks('||OBJ_NAME||',cls_,null);';
      end if;
      d := d||' end if;'||LF;
    elsif is_constructor then
      d := d||TB2||'if '||OBJ_NAME||'<>obj_ and '||CLS_NAME||'<>cls_ then '||CLS_NAME||':=cls_; end if;'||LF;
    end if;
    if current_mtd_critical then
      p := 'then executor';
      c := 'executor.lock_read(true)';
    else
      p := 'and x<2 then rtl';
      c := 'rtl.read';
    end if;
    d := d || TB||'else if b then '||c||'; end if;'||LF||TB2;
    if current_method_obj then
      d := d ||'security.CheckMethodsCall(rtl.USR,'''||current_method_id||''',obj_,cls_,''EXECUTE'','''
         ||current_method_class||''','''||current_method_sname||''');'||LF||TB2;
      if current_check_obj>0 then
        d := d ||'begin if v$chk then set_locks(obj_,cls_,false); end if;'||LF||TB2;
      end if;
    end if;
    d := d ||'if security.check_log('''||current_mtd_logparams||''') then '||
         log_param_name(current_method_id)||'; end if;'||LF||TB2;
    b := edoc_mgr.is_as_meth(current_method_class, current_method_sname);
    if b then
        d := d||'edoc_mgr.enable_as_sign('''||current_method_class||''', '''||current_method_sname||''');'||LF||TB2;
    else
        d := d||'edoc_mgr.disable_as_sign;'||LF||TB2;
    end if;
    lib.put_buf(d||
      's := '||STC_NAME||';'||LF||
      TB2||'if s is null then if stat_lib.disabled then s:=0; else if st is null then st:=stat_lib.check_run('''||current_method_id||'''); end if; s:=st; end if;'||LF||
      TB||TB2||'if bitand(s,2)>0 then g:=stat_lib.set_group_id('''||current_method_id||''',''METHOD'',''EXECUTE'','''||
      current_method_class||''','''||current_method_sname||''','''||replace(current_method_name,'''','''''')||'''); end if;'||LF||
      TB2||'end if;'||LF||
      TB2||'if bitand(s,2)>0 then msg_:=stat_lib.start_prec(g); if not msg_ is null then rtl.debug(msg_,0); end if; end if;'||LF,buf);
    d := TB2;
    if (not current_method_result is null) or is_constructor then
        d := d || result_name(current_method_id)||' := ';
    end if;
    if current_method_flags = constant.METHOD_DELETE then
        c := 'NULL';
    else
        c := CLS_NAME;
    end if;
    d := d ||method.make_proc_name(current_method_sname,false,current_method_pack)||
        '('||s||c||v||');' || LF;
    if current_arch_pack is not null then
      d := TB2||'if not nvl('||AP_MODE_NAME||',false) then'||LF||d||
        TB2||'else'||LF||replace(d,current_method_pack,current_arch_pack)||
        TB2||'end if;'||LF;
    end if;
    if b then
        d := d||TB2||'edoc_mgr.disable_as_sign;'||LF;
    end if;
    if current_method_obj and current_check_obj>0 then
        d := d||TB2||'if nvl(set_,''0'')=''0'' or '||LCK_NAME||' then v$chk := false; end if;'||LF||
          TB2||'exception when RTL.CANNOT_LOCK then v$chk:=false; raise;'||LF||
          TB2||'end;'||LF ;
    end if;
    txt_buf.delete;
    b := build_bindings(txt_buf);
    if b then
        c := 'check$(def_, true); binds$(set_); ';
    else
        c := 'check$; ';
    end if;
    lib.put_buf(d ||TB||'end if;' || LF ||
         TB||'if bitand(s,2)>0 then stat_lib.stop_prec; end if;'||LF, buf);
    if e is not null then
      lib.put_buf(e,buf);
      if e_ is not null then
        lib.put_buf(e_,buf);
      end if;
    end if;
    d := case when sc_logging then
         TB||'log_colls;'||LF||
         TB||'if save_ then save_vals(V$1,true); end if;'||LF
         end ||
         TB||'if b '||p||'.lock_clear('||LCK_NAME||' and x=1); end if;'||LF||
         TB||'end if;'||LF||
         TB||'if b then '||c||'get_:=valmgr.bool2char(ch.count>0); end if;'||LF||
         'end;' || LF2;
    e := null; v := null; p := null;
    if is_group then --Групповая(т.е. списочная) операци
      if lib.has_stringkey(current_method_class) then
        v := 'V$OBJ_TBL RTL.REFSTRING_TABLE;' || LF;
      else
        v := 'V$OBJ_TBL RTL.REFERENCE_TABLE;' || LF;
      end if;
      e := 'dbms_session.free_unused_user_memory; ';
    end if;
    if (current_method_obj or is_group) and current_check_obj>0 then
      v := v||'V$CHK  BOOLEAN := FALSE;' || LF;
    end if;
    build_grid_utils(txt_buf);--maximov
    build_check_params(b,txt_buf);
    build_log_params(txt_buf);
    if sc_logging then
      build_log_vals(txt_buf);
      build_log_colls(txt_buf);
    end if;
    /* put set_locks */
    if (current_method_obj or is_group) and current_check_obj>=0 then
      lib.put_buf(LF2||
      'procedure set_locks(obj_ varchar2, cls_ varchar2, set_ boolean) is'||LF||
      'begin if rtl.db_readonly then return; end if;'||LF||
      TB||'if not set_ then'||LF||
      TB2||'if v$self then '||class_mgr.interface_package(current_method_class)||'.check_lock(obj_,cls_,key_=>'||KEY_NAME||'); else rtl.check_obj(obj_,true,v$lck); end if;'||LF||
      TB2||'return;'||LF||
      TB||'end if;'||(case when current_check_obj > 0 then ' v$chk := true;' else '' end)||LF||
      TB||'if RO then RO := false; return; end if;'||LF||
      TB||'if v$self then v$lck := cls_; end if;'||LF||
      TB||REQ_NAME||'(obj_,v$lck,v$self,set_,'||KEY_NAME||',''RUN: '');'||LF||
      'end;', txt_buf);
    end if;
    lib.add_buf(buf,txt_buf,true,true);
    lib.put_buf(d ||
      'procedure '||validate_name(current_method_id)||' is'||LF||
      'begin '|| LF ||
      case when sc_logging then
          TB||'sc_mgr.write_log('''||current_method_id||''', ''V'',''set_'',null);'||LF
      end ||
      TB || process_name(current_method_id)||'(''0'',bf); '||e||LF||
      'end;'||LF2||
      'procedure '||execute_name(current_method_id)||' is'||LF||
      'begin '|| LF ||
      case when sc_logging then
          TB||'sc_mgr.write_log('''||current_method_id||''', ''E'',''set_'',null);'||LF
      end ||
      TB || process_name(current_method_id)||'(''1'',bf); '||e||LF||
      'end;'||LF2,txt_buf);
    build_zap_params(b,txt_buf);
    build_set_params(txt_buf);
    build_get_params(txt_buf);
    get_errors(d,i,j);
    p := 's := '||class_mgr.interface_package(current_method_class)||'.request_lock';
    s := '''['||current_method_class||']::['||current_method_sname||']'';';
    lib.put_buf('function '||chk_controls_name(current_method_id)||'(c_first out pls_integer,c_sep out pls_integer,c_last out pls_integer,c_err out pls_integer,b_count out pls_integer,b_err out pls_integer) return varchar2 is'||LF||
      'begin'||LF||
      TB||'c_first := '||ctl.first||';'||LF||
      TB||'c_sep := '||ctl_count||';'||LF||
      TB||'c_last:= '||ctl.last||';'||LF||
      TB||'c_err := '||i||';'||LF||
      TB||'b_count := '||bnd.count||';'||LF||
      TB||'b_err := '||j||';'||LF||
      TB||'return '||d||';'||LF||
      'end;'||LF2||
      'procedure '||REQ_NAME||'(obj_ varchar2,cls_ varchar2,self_ boolean default true,chk_ boolean default true,key_ number default null,info_ varchar2 default null) is'||LF||
      TB||'s varchar2(10000); i varchar2(100);'||LF||
      case when sc_logging then
        TB||'aPar RTL.REFSTRING_TABLE; aVal RTL.STRING_TABLE;'||LF
      end ||
      'begin if rtl.db_readonly then return; end if;'||LF||
      TB||'i := info_||'||s||LF||
      case when sc_logging then
        TB||'aPar(1):= ''obj_'';  aVal(1):= obj_;'||LF||
        TB||'aPar(2):= ''cls_'';  aVal(2):= cls_;'||LF||
        TB||'aPar(3):= ''self_''; aVal(3):= rtl.bool_char(self_);'||LF||
        TB||'aPar(4):= ''chk_'';  aVal(4):= rtl.bool_char(chk_);'||LF||
        TB||'aPar(5):= ''key_'';  aVal(5):= key_;'||LF||
        TB||'aPar(6):= ''info_''; aVal(6):= info_;'||LF||
        TB||'sc_mgr.write_log('''||current_method_id||''', ''Y'',aPar,aVal);'||LF
      end ||
      TB||'if PF is null and key_ is null then PF:='||current_mtd_archive||'; '||KEY_NAME||':=valmgr.init_key(PF); end if;'||LF||
      TB||'if self_ then if instr(obj_,'','') > 0 then'||LF||
      TB2||p||'s(obj_,i,nvl(key_,'||KEY_NAME||'));'||LF||
      TB||'else'||LF||
      TB2||p||'(obj_,cls_,i,nvl(key_,'||KEY_NAME||'));'||LF||
      TB||'end if;'||LF||
      TB||'else s := rtl.lock_request(obj_,i,-1,cls_); end if;'||LF||
      TB||'if chk_ then'||LF||
      TB2||'if not s is null then message.raise_(-20400,s,true); end if;'||LF||
      TB||'end if;'||LF||
      'end;'||LF2||
      'END;',txt_buf);
    lib.put_buf('CREATE OR REPLACE PACKAGE BODY '||current_method_interface||' IS'||LF2||v||
      'V$SELF BOOLEAN := TRUE; V$LCK VARCHAR2('||constant.REF_PREC||'); RO boolean;'||LF||
      'BF VARCHAR2(1); '||SYS_NAME||' NUMBER; ST PLS_INTEGER; PF PLS_INTEGER;'||LF||
      'CT RTL.STRING_TABLE;'||LF||
      'CH RTL.BOOLEAN_TABLE;'||
      case when sc_logging then
        LF || 'V$1 RTL.STRING_TABLE;'||LF||
        'V$2 RTL.STRING_TABLE;'||LF||
        'Q$ RTL.STRING_TABLE;'||LF||
        'C$ RTL.STRING_TABLE;'
      end
      ||LF2,txt_buf,false);
end;
--
procedure create_method_interface$(method_id_ varchar2, p_error boolean) is
    b boolean;
    i pls_integer;
    v_action varchar2(100);
    v_spec   varchar2(32000);
begin
    initialize(method_id_);
    if current_method_flags in (constant.METHOD_LIBRARY,constant.METHOD_TRIGGER,constant.METHOD_ATTRIBUTE)
    then return; end if;
    if method.get_target(method_id_) in (method.PLSQL_TEXT, method.PLPLUS_TEXT) then
        null;
    else
        drop_package_quietly(current_method_interface);
        drop_package_body_quietly(current_method_interface);
        return;
    end if;
    if p_error is null then
      if not current_ext_id is null then
        initialize(current_ext_id);
      end if;
      v_spec := build_interface_definition;
      build_interface_body;
    else
      if not current_ext_id is null then
          drop_package_quietly(current_method_interface);
          return;
      end if;
      dbms_application_info.read_module( v_action, v_action );
      dbms_application_info.set_action( to_char(rtl.getdate,'HH24:MI:')||'Interface '||method_id_ );
      storage_utils.ws(message.gettext(constant.EXEC_ERROR,'CREATING_IFACE_PACK',current_method_class||']::['||current_method_sname,'- '||current_method_interface));
      v_spec := build_interface_definition;
      if trim(translate(v_spec,TB||LF,'  ')) = trim(translate(method.get_user_source(current_method_interface,'PACKAGE'),TB||LF,'  ')) then
        b := true;
      else
        begin
          storage_utils.ws('  '||current_method_interface||' - SPECIFICATION...');
          execute immediate 'CREATE OR REPLACE '||v_spec;
          b := true;
        exception when compile_errors then
          b := false;
        end;
      end if;
      build_interface_body;
      if b then
        storage_mgr.create_object(txt_buf,null,true);
        v_spec := inst_info.owner || '_USER';
        if not secadmin.check_object(v_spec,current_method_interface) then
          storage_utils.ws('  '||current_method_interface||' - GRANT...');
          execute immediate 'GRANT EXECUTE ON ' || current_method_interface || ' TO ' || v_spec;
        end if;
        if err_buf is null then
          storage_utils.ws('  '||current_method_interface||' - OK.');
        else
          storage_utils.ws(message.gettext(constant.EXEC_ERROR,'ERRORS_WERE_DETECTED',null,'  '||current_method_interface||': '));
        end if;
      else
        drop_package_body_quietly(current_method_interface);
        storage_utils.ws(class_mgr.package_errors(current_method_interface));
      end if;
      dbms_application_info.set_action( v_action );
    end if;
    /*declare
      l pls_integer;
      r pls_integer;
      s varchar2(1000);
    begin
      dump(par,'Parameters');
      dump(var,'Variables');
      dump(ctl,'Controls',true);
      stdio.put_line_buf('******** Bindings');
      i := bnd.first;
      while not i is null loop
        l := bnd(i).left;
        r := bnd(i).right;
        if ctl.exists(l) then
          s := '.'||ctl(l).qual;
        else
          s := null;
        end if;
        s := l||s||' '||bnd(i).cond||' '||r;
        if ctl.exists(r) then
          s := s||'.'||ctl(r).qual;
        end if;
        stdio.put_line_buf(s);
        i := bnd.next(i);
      end loop;
    end;*/
    if nvl(p_error,true) then
      err_buf := err_buf||class_mgr.package_errors(current_method_interface);
    end if;
    par.delete;
    var.delete;
    quals.delete;
    ctl.delete;
    bnd.delete;
    txt_buf.delete;
    dbms_session.free_unused_user_memory;
end;
--
function  check_method_interface(method_id_ varchar2) return varchar2 is
begin
  create_method_interface$(method_id_,null);
  return err_buf;
end;
--
procedure create_form_referencing(p_method_id varchar2,p_error boolean) is
  v_mtd rtl.string40_table;
begin
  select id bulk collect into v_mtd
    from methods where form_id=p_method_id or src_id=p_method_id;
  for i in 1..v_mtd.count loop
    create_method_interface(v_mtd(i),p_error,true);
  end loop;
  v_mtd.delete;
end;
--
procedure create_method_interface(method_id_ varchar2, p_error boolean := false, p_refcing boolean := true) is
begin
    create_method_interface$(method_id_, p_error);
    if nvl(p_error,true) then
      stdio.put_line_buf(err_buf);
    end if;
    if p_refcing then
      create_form_referencing(method_id_,p_error);
    end if;
end;
--
procedure rebuild_method_interfaces(p_pipe varchar2 default null,
                                    p_list varchar2 default null) is
    mt  class_mgr.ID_TAB;
    nm  pls_integer;
    l   pls_integer;
    i   pls_integer;
    ii  pls_integer;
    v_id    varchar2(300);
    v_str   varchar2(300);
    v_pipe  varchar2(100);
    to_pipe boolean default FALSE;
    procedure put_pipe(msg varchar2) is
    begin
        if to_pipe then
            stdio.put_line_pipe(to_char(sysdate,' - HH24:MI:SS > ')||msg);
        end if;
    end;
begin
    v_pipe := Inst_Info.Owner||'.PROCESS_METHODS';
    stdio.setup_pipes(v_pipe,p_pipe,-1,100000);
    to_pipe:= method.check_stop_flag(v_pipe);
    to_pipe:= not p_pipe is null;
    put_pipe('++ ' || message.gettext('EXEC', 'CREATING_METH_IFACES_STARTED'));
    stdio.put_line_buf(message.gettext('EXEC', 'CREATING_METH_IFACES_STARTED')||' - '||TO_CHAR(SYSDATE,'DD/MM/YY (HH24:MI:SS)'));
    nm := 0;
    if p_list is null then
      for c in (
        select id,class_id,short_name
          from methods m
         where kernel='0' and
          ( flags = constant.METHOD_OPERATION
            or ext_id is not null or form_id is not null
            or flags not in ('A','L','T') and (
              exists (select 1 from controls where meth_id = m.id)
              or src_id is not null and (
                exists (select 1 from methods s where s.id = m.src_id and s.form_id is not null)
                or exists (select 1 from controls where meth_id = src_id)
              )
            )
          )
         order by class_id,short_name
      ) loop
          nm := nm + 1;
          mt(nm).id:=c.id;
          mt(nm).name:=c.class_id||'.'||c.short_name;
      end loop;
    else
      ii := 1; l := length(p_list);
      while ii<l loop
        i := instr(p_list,LF,ii);
        if i>0 then
            v_id := substr(p_list,ii,i-ii);
        else
            i := l;
            v_id := substr(p_list,ii);
        end if;
        v_id := upper(ltrim(rtrim(v_id)));
        if not v_id is null then
          begin
            select id,class_id||'.'||short_name
              into v_id,v_str from methods m
             where id=v_id and kernel='0' and flags not in ('A','L','T');
            nm := nm + 1;
            mt(nm).id:=v_id;
            mt(nm).name:=v_str;
          exception when no_data_found then null;
          end;
        end if;
        ii := i+1;
      end loop;
    end if;
    put_pipe('++ ' || message.gettext('EXEC', 'METHODS_WERE_FOUND', nm));
    for n in 1 .. nm loop
      if method.check_stop_flag(v_pipe) then
        put_pipe('*** '||n||'.'||sqlerrm(-1013));
        exit;
      end if;
      put_pipe(message.gettext('EXEC', 'CREATING_IFACE', n, nm, mt(n).id, mt(n).name));
      begin
        create_method_interface$(mt(n).id, true);
        if not err_buf is null then
            put_pipe('>> '||n||'. '||message.gettext('EXEC', 'CREATED_WITH_ERRORS'));
            stdio.put_line_buf('----');
            stdio.put_line_buf('*** '||message.gettext('EXEC', 'ERRORS_FOR_IFACE', mt(n).id, mt(n).name));
            stdio.put_line_buf(err_buf);
        end if;
      exception when others then
        if sqlcode in (-6508,-4061) then raise; end if;
        put_pipe('>> '||n||'. '||message.gettext('EXEC', 'NOT_CREATED', message.error_stack));
        stdio.put_line_buf('----');
        stdio.put_line_buf('*** '||message.gettext('EXEC', 'NOT_CREATED2', mt(n).id, mt(n).name));
        stdio.put_line_buf(message.gettext('EXEC', 'EXCEPTION', message.error_stack));
      end;
    end loop;
    put_pipe('++ '||message.gettext('EXEC', 'CREATING_METH_IFACES_FINISHED'));
    stdio.put_line_buf(LF||message.gettext('EXEC', 'CREATING_METH_IFACES_FINISHED')||' - '||TO_CHAR(SYSDATE,'DD/MM/YY (HH24:MI:SS)'));
    mt.delete;
    dbms_session.free_unused_user_memory;
end;
--
procedure recreate_deleted_interfaces(p_pipe varchar2 default null) is
    v_buff varchar2(32767) := null;
	v_max_entry_len number;
begin
	v_max_entry_len := 32767 - 128 - length(LF);
    for meth in (select m.id, m.ext_id from methods m where 
        exists (select 1 from controls c where c.meth_id = m.id or c.meth_id = m.form_id)
        and Method.get_obj_status(interface_package_name(nvl(m.ext_id, m.id)), 'PACKAGE') is null
    )
    Loop
        v_buff := v_buff || nvl(meth.ext_id, meth.id) || LF;
		if (length(v_buff) >= v_max_entry_len) then
			rebuild_method_interfaces(p_pipe, v_buff);
			v_buff := '';
		end if;
    end loop;
    if v_buff is not null then
       rebuild_method_interfaces(p_pipe, v_buff);
    end if;
end;
--
function is_interface_deleted(method_id_ varchar2) return boolean is
    v_result integer;
begin
    select count(1) into v_result from methods m where 
        m.id = method_id_
		and m.ext_id is null
        and exists(select 1 from controls c where c.meth_id = m.id or c.meth_id = m.form_id)
        and method.get_obj_status(interface_package_name(m.id), 'PACKAGE') is null;
        
    return (v_result > 0);
end;
--
procedure delete_collection (collection_id_ number, class_id_ varchar2 ) is
    v_table  varchar2(100);
    v_group  varchar2(30);
    v_table1 varchar2(30);
    v_column varchar2(30);
    v_id     varchar2(128);
    v_key    number;
    v_class  varchar2(16) := class_id_;
    v_cursor "CONSTANT".report_cursor;
    v_rows   integer;
    ok       boolean;
    v_rowid varchar2(5);
begin
    if collection_id_ is null then
        return;
    end if;
    if v_class is null then
        v_class := rtlobj.coll2class(collection_id_);
        if v_class is null then return; end if;
    end if;
    begin
        select table_name, param_group, current_key
          into v_table, v_group, v_key
          from class_tables where class_id=v_class;
    exception when NO_DATA_FOUND then return;
    end;
    lib.attr_column(v_class,'CLASS_ID',v_table1,v_column,'2');
    ok := v_table=v_table1;
    if not ok and v_table1='OBJECTS' then
        v_column := ''''||class_id_||''''; ok := true;
    end if;
    v_rowid := case when lib.pk_is_rowid(v_class) then 'ROWID' else 'ID' end;
    if v_group='PARTITION' then
      v_group := null;
      if storage_mgr.prt_actual then
        v_table := v_table||' PARTITION('||v_table||'#0)';
      elsif v_key>0 then
        if ok then
          v_group := ' AND KEY>='||v_key;
        else
          v_group := ' AND A.KEY>='||v_key;
        end if;
      end if;
    else
      v_group := null;
    end if;
    if ok then
        open v_cursor for 'SELECT '||v_rowid||','||v_column||' FROM '||v_table||
                          ' WHERE COLLECTION_ID=:COLL'||v_group
             using collection_id_;
    else
        open v_cursor for 'SELECT A.ID,B.CLASS_ID FROM '||v_table1||' B, '||v_table||
                          ' A WHERE B.ID=A.ID AND A.COLLECTION_ID=:COLL'||v_group
             using collection_id_;
    end if;
    loop
        fetch v_cursor into v_id,v_class;
        exit when v_cursor%notfound;
        rtl.destructor(v_id,v_class,v_class);
    end loop;
    close v_cursor;
exception when OTHERS then
    if v_cursor%isopen then
        close v_cursor;
    end if;
    raise;
end;
--
procedure delete_collections(obj_id_ varchar2,
                             qual_   varchar2 default null,
                             class_  varchar2 default null,
                             value_  number   default null) is
    obj_class_ varchar2(16);
    v_obj_id   varchar2(128);
    v_exec  varchar2(1000);
begin
    v_obj_id := obj_id_;
    obj_class_ := rtl.get_class(v_obj_id,class_,'DELETE_COLLECTIONS');
    v_exec := 'BEGIN '||class_mgr.interface_package(obj_class_)||'.DELETE_COLLECTION(:OBJ,:QUAL,:COLL); END;';
    if qual_ is null then
      for c in (
        select qual
          from class_tab_columns, class_relations
         where class_id = parent_id
           and child_id = obj_class_
           and deleted  = '0'
           and base_class_id = 'COLLECTION'
               )
      loop
        execute immediate v_exec using v_obj_id, c.qual, value_;
      end loop;
    else
      execute immediate v_exec using v_obj_id, qual_, value_;
    end if;
end;
--
procedure delete_object_collections(obj_id_ varchar2) is
begin delete_collections(obj_id_,null); end;
--
procedure delete_object_collection(obj_id_ varchar2,qual_ varchar2) is
begin delete_collections(obj_id_,qual_); end;
--
procedure clear_object_refcing(obj_id_           varchar2
                              ,p_class           varchar2 default null
                              ,p_new_id          varchar2 default null
                              /* Параметр означает, что реквизиты, у которых в Администраторе выставлен
                              признак "Не создавать ограничения", не будут обновлены значением p_new_id
                              '1' - не обновлять значения реквизита с выставленным признаком
                              '0' - обновлять значения всех реквизиты (старая логика)*/
                              ,p_consider_constr varchar2 default '0') is
    v_class varchar2(16);
    v_objid varchar2(128);
    v_part  varchar2(30);
    v_table varchar2(100);
    i   integer;
    v_consider_constr varchar2(1) := nvl(p_consider_constr, '0');
begin
    v_objid := obj_id_;
    v_class := rtl.get_class(v_objid,p_class,'CLEAR_OBJECT_REFCING');
    rtl.read(null); valmgr.check_readonly;
    for r in (
        select distinct ctc.column_name, ctc.qual,
               ct.table_name, ct.class_id, ct.param_group, ct.current_key, ctc.indexed
          from class_tables ct, class_tab_columns ctc, class_relations cr
         where cr.child_id = v_class
           and ctc.target_class_id = cr.parent_id
           and ctc.base_class_id = 'REFERENCE'
           and ctc.column_name is not null
           and ctc.deleted = '0' and ctc.flags is null
           and ct.class_id = ctc.class_id
           --and mapped_from is null
             )
    loop
      -- Если передан параметр "Учитывать выставленные ограничения" v_consider_constr = '1' и
      -- для данного реквизита признак "Не создавать ограничения" выставлен (indexed = '1'),
      -- то пропускаем этот реквизит и переходим к следующему
      if not (v_consider_constr = '1' and r.indexed = '1') then
        v_part := null;
        v_table:= r.table_name;
        if r.param_group='PARTITION' then
          if storage_mgr.prt_actual then
            v_table:= v_table||' PARTITION('||v_table||'#0)';
          elsif r.current_key>0 then
            v_part := ' AND KEY>='||r.current_key;
          end if;
        end if;
        begin
          execute immediate 'UPDATE '||v_table||' SET '||r.column_name || '=:NEW WHERE '
           ||r.column_name||'=:OBJ'||v_part
           using p_new_id,v_objid;
          i := sql%rowcount;
        exception when others then i:=-abs(sqlcode);
        end;
        if i>=0 then
          storage_utils.ws(message.gettext('EXEC', 'REFERENCES_UPDATED', r.class_id, r.qual, i));
        else
          storage_utils.ws(message.gettext('EXEC', 'REFERENCES_UPDATE_FAILED', r.class_id, r.qual, i));
        end if;
      end if;
    end loop;
end clear_object_refcing;
--
function  move_object(p_obj_id varchar2, p_class varchar2 default null,
                      p_new_id varchar2 default null, p_clear boolean default true
                     ) return varchar2 is
    v_id    varchar2(128) := p_new_id;
    v_objid varchar2(128) := p_obj_id;
    v_class varchar2(16);
    v_suff  varchar2(20);
    v_stat  varchar2(10);
    v_qual  varchar2(10);
    v_chk   varchar2(10);
    v_key   varchar2(30);
    v_info  lib.class_info_t;
    p   varchar2(50);
    t   varchar2(100);
    q   varchar2(2000);
begin
    v_class := rtl.get_class(v_objid,p_class);
    rtl.read(null);
    if not lib.class_exist(v_class,v_info) then
      return null;
    end if;
    if v_id is null then
        select seq_id.nextval into v_id from dual;
    end if;
    p := class_mgr.interface_package(v_class);
    v_qual := ','' ''';
    if v_info.base_class_id=constant.GENERIC_NUMBER then
        v_suff := 'num';       t := 'number';
    elsif v_info.base_class_id=constant.GENERIC_STRING then
        v_suff := 'str';       t := 'varchar2(4000)';
    elsif v_info.base_class_id=constant.MEMO then
        v_suff := 'memo';      t := 'varchar2(4000)';
    elsif v_info.base_class_id=constant.GENERIC_DATE then
      if v_info.kernel then
        t := lower(v_info.interface);
        t := substr(t,instr(t,'|')+1);
        if    p_class = 'TIMESTAMP' then
          v_suff := 'ts';
        elsif p_class = 'TIMESTAMP_TZ' then
          v_suff := 'tstz';
        elsif p_class = 'TIMESTAMP_LTZ' then
          v_suff := 'tsltz';
        elsif p_class = 'INTERVAL' then
          v_suff := 'dsi';
        elsif p_class = 'INTERVAL_YM' then
          v_suff := 'ymi';
        else
          v_suff := 'date';
        end if;
      else
        v_suff := 'date';      t := 'date';
      end if;
    elsif v_info.base_class_id=constant.GENERIC_BOOLEAN then
        v_suff := 'bool_char'; t := 'varchar2('||constant.BOOL_PREC||')';
    elsif v_info.base_class_id=constant.COLLECTION then
        v_suff := 'coll';      t := 'number';
    elsif v_info.base_class_id=constant.REFERENCE then
        v_suff := 'ref';       t := lower(v_info.interface);
        if t like 'var%' then  t := 'varchar2('||constant.REF_PREC||')'; end if;
    elsif v_info.base_class_id=constant.OLE then
      if v_info.kernel then
        t := lower(v_info.interface);
        v_suff := lower(replace(p_class,' '));
        if p_class='RAW' then
          t := 'raw(4000)';
        end if;
      else
        v_suff := 'ole';       t := 'number';
      end if;
    elsif v_info.base_class_id=constant.GENERIC_TABLE then
        t := v_info.interface;
        v_suff:= 'tbl_'||lower(class_mgr.make_valid_literal(v_info.class_ref));
    else
        t := v_info.interface;
        v_chk := ',false';
        v_stat:= ',false';
        v_qual:= ',null';
        v_suff:= lower(class_mgr.make_valid_literal(v_class));
    end if;
    if not storage_mgr.prt_actual then
      v_key := ', key_ => -1';
    end if;
    q := TB||p||'.insert$(rec_,o,false,false);'||LF||
         TB||'if :oid<>:id then'||LF||
         TB2||'method_mgr.clear_object_refcing(:oid,o.class_id,o.id);'||LF||
         TB2||'if valmgr.static(o.class_id)=:oid then valmgr.del_static(o.class_id); valmgr.put_static(o.class_id,o.id); end if;'||LF||
         TB2||'update object_rights set obj_id=o.id where obj_id=:oid and class_id=o.class_id;'||LF||
         TB2||'update object_rights_ex set obj_id=o.id where obj_id=:oid and class_id=o.class_id;'||LF||
         TB2||'update object_rights_list set obj_id=o.id where obj_id=:oid and class_id=o.class_id;'||LF||
         TB2||'update long_data set object_id=o.id where object_id=:oid and class_id=o.class_id;'||LF||
         TB||'end if;'||LF;
    if p_clear then
        q := TB||p||'.init(new_,false);'||LF||
             TB||p||'.set_'||v_suff||'(:oid'||v_qual||',new_'||v_stat||v_chk||v_key||');'||LF||
              q||TB||p||'.delete$(:oid,false,o.class_id'||v_key||');'||LF;
    end if;
    q := 'declare o rtl.object_rec;'||LF||
         TB||'rec_ '||t||'; new_ '||t||';'||LF||
         'begin o:='||p||'.get_object(:oid'||v_key||'); o.id:=:id;'||LF||
         TB||'rec_:='||p||'.get_'||v_suff||'(:oid'||v_qual||v_stat||v_key||');'||LF||
          q||'end;';
    storage_utils.ws('Moving '||v_objid||'.'||v_class||' to '||v_id);
    --storage_utils.ws(q);
    execute immediate q using v_objid,v_id;
    return v_id;
end move_object;
--
function get_version return varchar2 is
begin
    return VERSION;
end;
--
end;
/
show err package body method_mgr
