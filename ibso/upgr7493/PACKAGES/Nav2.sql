PROMPT NAV body
CREATE OR REPLACE
PACKAGE BODY
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/Nav2.sql $
 *  $Author: pistomin $
 *  $Revision: 128882 $
 *  $Date:: 2016-11-25 15:15:45 #$
 */
NAV IS
--
---------------------------------------------------------------
-- Типы и переменные для обработки реквизитов типа OLE с kernel = true
---------------------------------------------------------------
BLOB_TYPE constant varchar2(20) := 'BLOB';
CLOB_TYPE constant varchar2(20) := 'CLOB';
BFILE_TYPE constant varchar2(20) := 'BFILE';
RAW_TYPE constant varchar2(20) := 'RAW';
LONG_RAW_TYPE constant varchar2(20) := 'LONG RAW';
LONG_TYPE constant varchar2(20) := 'LONG';
VERSION constant varchar2(10) := '1.0';
--
INVALID_HEX_VALUE exception;
pragma EXCEPTION_INIT(INVALID_HEX_VALUE, -01465);
--
type lob_t is record (
    obj_id    varchar2(128),
    obj_class varchar2(16),
    obj_type  varchar2(20),
    write_mode number,
    blocator blob,
    clocator clob,
    flocator bfile,
    long_cursor integer,
    query_get varchar2(1000),
    query_set varchar2(1000),
    query_del varchar2(1000)
);
type lob_tbl_t is table of lob_t index by binary_integer;
--
lobs lob_tbl_t;
--
---------------------------------------------------------------
-- Получение версии пакета
---------------------------------------------------------------
function get_version return varchar2 is
begin
  return VERSION;
end;
---------------------------------------------------------------
-- Можно ли работать через Навигатор
---------------------------------------------------------------
function Is_Novo_Allowed return boolean
is
begin
  return security.Is_Novo_Allowed;
end;
---------------------------------------------------------------
-- Создание/удаление синонимов
---------------------------------------------------------------
PROCEDURE CreateSynonyms (mId IN VARCHAR2) IS
    cls varchar2(16);
    sn  varchar2(16);
BEGIN
    return;
    select class_id,short_name into cls,sn from methods where id=mid;
    if security.mtd_accessible(cls,mid,rtl.USR)='0' then
        message.err(-20999,constant.EXEC_ERROR,'NOT_ACCESSIBLE',sn);
    end if;
    SecAdmin.CreateSynonyms (mId);
END CreateSynonyms;
--------------------------------------------------------------
-- Сохраняем в переменных сетевой адрес клиента
---------------------------------------------------------------
FUNCTION SetNetAddresses (cMAC IN VARCHAR2, cIP IN VARCHAR2) RETURN CHAR IS
BEGIN
    MAC := cMAC;
    IP := cIP;
    return '1';
END SetNetAddresses;
---------------------------------------------------------------
-- Возвращает признак того, что пароль является "боевым",
-- вход под ним запрещен.
---------------------------------------------------------------
FUNCTION Get_BattlePass RETURN VARCHAR2 IS
    BattlePass VARCHAR2(2000);
BEGIN
    select value into BattlePass from AUD.audit_settings where name = 'BATTLE_PASS' and owner=inst_info.gowner;
    return BattlePass;
exception when no_data_found then
    return null;
END Get_BattlePass;
---------------------------------------------------------------
-- Создание плана выполнения запроса (2.6)
---------------------------------------------------------------
PROCEDURE Explain_Plan (Statement_Id IN VARCHAR2, txtSQL IN VARCHAR2) IS
    cid INTEGER;
    res INTEGER;
    str VARCHAR2(32000);
BEGIN
    DELETE Plan_Table WHERE Statement_Id = Statement_Id;
    cid := Dbms_Sql.Open_Cursor;
    str := 'EXPLAIN PLAN SET Statement_Id = ''' || Statement_Id ||
        ''' INTO Plan_Table FOR ' || txtSQL;
    Dbms_Sql.Parse (cid, str, Dbms_Sql.V7);
    res := Dbms_Sql.Execute (cid);
    Dbms_Sql.Close_Cursor (cid);
    COMMIT;
EXCEPTION WHEN OTHERS THEN
    Dbms_Sql.Close_Cursor (cid);
    if Length (str) > 240 then
        str :=  SubStr (str, 1, 237) || '...';
    end if;
    Dbms_OutPut.Put_Line('Error during - ' || str);
END Explain_Plan;
---------------------------------------------------------------
-- Возвращает признак того, что пользователь привилегирован (2.2)
---------------------------------------------------------------
FUNCTION Get_PrivUser (UserName IN VARCHAR2 DEFAULT NULL) RETURN CHAR IS
    Chk CHAR(1);
    Usr varchar2(30) := nvl(rtrim(ltrim(upper(UserName))),rtl.USR);
BEGIN
    IF Usr in (Inst_Info.Owner,Inst_Info.GOwner) or
       Usr = rtl.USR and SYS_CONTEXT(Inst_Info.Owner||'_SYSTEM','ADMIN') = '1' THEN
        RETURN '1';
    END IF;
    RETURN '0';
END Get_PrivUser;
---------------------------------------------------------------
-- Возвращает признак, что "Тип контролируется по реквизиту"
---------------------------------------------------------------
FUNCTION Attr_Access_Check (ClassId IN VARCHAR2, UserName IN VARCHAR2 DEFAULT NULL) RETURN CHAR IS
    Result CHAR(1);
    UserNameUpper VARCHAR2(30) := nvl(rtrim(ltrim(upper(UserName))),rtl.USR);
BEGIN
    select count(1) into Result from object_rights_ex
     where class_id = ClassId and subj_id = UserNameUpper and rownum<2;
    RETURN Result;
    /*UserNameUpper := UPPER(UserName);
    IF UserNameUpper = Inst_Info.Owner OR UserNameUpper = 'ADMIN_GRP' THEN
        RETURN '0';
    END IF;
    BEGIN
        SELECT '1' INTO Result FROM ATTR_ACCESS_CHECK WHERE Subj_Id = UserNameUpper AND Class_Id = ClassId AND RowNum < 2;
        RETURN '1';
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN '0';
    END;*/
END Attr_Access_Check;
---------------------------------------------------------------
-- Возвращает доступность класса для показа в меню Навигатора (2.1)
---------------------------------------------------------------
FUNCTION In_Menu (ClassId IN VARCHAR2, UserName IN VARCHAR2 DEFAULT NULL, FULL IN CHAR DEFAULT '1') RETURN CHAR IS
    Result CHAR(1);
    UserNameUpper VARCHAR2(30) := nvl(rtrim(ltrim(upper(UserName))),rtl.USR);
BEGIN
    IF UserNameUpper in (Inst_Info.Owner,Inst_Info.GOwner) or
       UserNameUpper = rtl.USR and SYS_CONTEXT(Inst_Info.Owner||'_SYSTEM','ADMIN') = '1' THEN
        RETURN '1';
    END IF;
    IF FULL = '1' THEN
        SELECT '1' INTO Result FROM Class_Rights WHERE
            (Not_In_Menu = '0' OR Not_In_Menu is Null) AND
            Subj_Id IN (SELECT Equal_Id FROM Subj_Equal WHERE Subj_Id = UserNameUpper) AND
            Obj_Id = ClassId AND ROWNUM = 1;
    ELSE
        SELECT '1' INTO Result FROM Class_Rights WHERE
            (Not_In_Menu = '0' OR Not_In_Menu is Null) AND
            Subj_Id = UserNameUpper AND
            Obj_Id = ClassId AND ROWNUM = 1;
    END IF;
    RETURN '1';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN '0';
END In_Menu;
---------------------------------------------------------------
-- Возвращает доступность печати представления на принтер
---------------------------------------------------------------
FUNCTION Is_Print_View_Allowed (ClassId IN VARCHAR2, ViewId IN VARCHAR2, UserName IN VARCHAR2 DEFAULT NULL) RETURN CHAR IS
    Result Char(1);
    UserNameUpper VARCHAR2(30) := nvl(rtrim(ltrim(upper(UserName))),rtl.USR);
BEGIN
    IF UserNameUpper in (Inst_Info.Owner,Inst_Info.GOwner) or
       UserNameUpper = rtl.USR and SYS_CONTEXT(Inst_Info.Owner||'_SYSTEM','ADMIN') = '1' THEN
        RETURN '1';
    END IF;
    SELECT '1' INTO Result FROM Criteria_Rights WHERE
        To_Printer = '1' AND
        Subj_Id IN (SELECT Equal_Id FROM Subj_Equal WHERE Subj_Id = UserNameUpper) AND
        Class_Id = ClassId AND Obj_Id = ViewId AND ROWNUM = 1;

    RETURN '1';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN '0';
END Is_Print_View_Allowed;
---------------------------------------------------------------
-- Возвращает доступность печати представления в файл
---------------------------------------------------------------
FUNCTION Is_Print_View_To_File_Allowed (ClassId IN VARCHAR2, ViewId IN VARCHAR2, UserName IN VARCHAR2 DEFAULT NULL) RETURN CHAR IS
    Result Char(1);
    UserNameUpper VARCHAR2(30) := nvl(rtrim(ltrim(upper(UserName))),rtl.USR);
BEGIN
    IF UserNameUpper in (Inst_Info.Owner,Inst_Info.GOwner) or
       UserNameUpper = rtl.USR and SYS_CONTEXT(Inst_Info.Owner||'_SYSTEM','ADMIN') = '1' THEN
        RETURN '1';
    END IF;
    SELECT '1' INTO Result FROM Criteria_Rights WHERE
        To_File = '1' AND
        Subj_Id IN (SELECT Equal_Id FROM Subj_Equal WHERE Subj_Id = UserNameUpper) AND
        Class_Id = ClassId AND Obj_Id = ViewId AND ROWNUM = 1;

    RETURN '1';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN '0';
END Is_Print_View_To_File_Allowed;
---------------------------------------------------------------
-- Преобразование даты из внутреннего формата в стандартный
---------------------------------------------------------------
FUNCTION Date_Char(dDate IN DATE, Precision IN NUMBER DEFAULT NULL)
           RETURN VARCHAR2 IS
fmt Varchar2(30);
BEGIN
  IF Precision IS NULL OR Precision = 0 THEN
     fmt :=  'DD/MM/YYYY';
    ELSIF Precision = '1' THEN
     fmt := 'DD/MM/YYYY HH24:MI';
    ELSIF Precision = '2' THEN
     fmt := 'DD/MM/YYYY HH24:MI:SS';
    ELSE
     fmt :=  'DD/MM/YYYY';
  END IF;
  RETURN TO_CHAR(dDate, fmt);
END Date_Char;
---------------------------------------------------------------
-- Преобразование числа из внутреннего формата в стандартный
---------------------------------------------------------------
FUNCTION Number_Char(nNumber IN NUMBER,
                     Precision IN NUMBER DEFAULT NULL)
           RETURN VARCHAR2 IS
fmt Varchar2(40);
BEGIN
  IF Precision IS NULL OR Precision = 0 THEN
     fmt := '999999999999999999999';
    ELSE
     fmt := '999,999,999,999,999,999,990.' || RPAD('9', Precision, '9');
  END IF;
  RETURN LTRIM(TO_CHAR(nNumber, fmt));
END Number_Char;
---------------------------------------------------------------
-- Разыменовывает ссылку
---------------------------------------------------------------
FUNCTION Get_Reference_Value(ObjRef IN varchar2) RETURN VARCHAR2 IS
 test   VARCHAR2(16);
BEGIN
 IF ObjRef IS NULL THEN
    RETURN NULL;
 END IF;
 -- Проверим есть ли такой объект
 test := rtlobj.get_class(ObjRef);
 RETURN '(***)';
 EXCEPTION
   WHEN NO_DATA_FOUND THEN
    RETURN NULL;
END Get_Reference_Value;
---------------------------------------------------------------
-- Возвращает наименование состояни
---------------------------------------------------------------
FUNCTION Get_State_Name(StateId IN Varchar2)
         RETURN VARCHAR2 IS
Value States.Name%TYPE;
BEGIN
 SELECT Name INTO Value
  FROM States
  WHERE Id = StateId AND ROWNUM <= 1;
  RETURN Value;
 EXCEPTION
  WHEN NO_DATA_FOUND THEN RETURN NULL;
END Get_State_Name;
---------------------------------------------------------------
-- Получение уровня в иерархии классов
---------------------------------------------------------------
FUNCTION Class_Level(ClsId IN VARCHAR2) RETURN INTEGER IS
  res INTEGER; -- Результат
BEGIN
  SELECT COUNT(0) INTO res FROM CLASSES
  START WITH ID=ClsId CONNECT BY ID=PRIOR PARENT_ID;
  RETURN res;
END Class_Level;
---------------------------------------------------------------
-- Проверка на принадлежность родителю
---------------------------------------------------------------
FUNCTION Is_Child(prn_id IN VARCHAR2, child_id IN VARCHAR2)
 RETURN CHAR
IS
cnt NUMBER(1);
BEGIN
 SELECT COUNT(0) INTO cnt FROM DUAL
 WHERE SECURITY.Cls_Accessible(child_Id, rtl.Usr) = '1'
 AND SECURITY.Cls_Accessible(prn_Id, rtl.Usr) = '1'
 AND EXISTS
 (SELECT C.Id FROM Classes C
   WHERE C.Id = child_id
   START WITH C.Id = prn_id
   CONNECT BY PRIOR C.Id = C.Parent_Id);
 RETURN TO_CHAR(cnt);
END Is_Child;
---------------------------------------------------------------
-- Проверка на заполненность Collection
---------------------------------------------------------------
FUNCTION Check_Collection(ColId IN number)
 RETURN VARCHAR2 IS
BEGIN
  RETURN '{...}';
END Check_Collection;
---------------------------------------------------------------
-- Проверка на заполненность OLE-реквизита
---------------------------------------------------------------
FUNCTION Check_Ole(OleId IN number)
 RETURN VARCHAR2 IS
 tmp CHAR(1);
BEGIN
 IF OleId IS NULL THEN
    RETURN NULL;
 END IF;
 SELECT '1' INTO tmp FROM Long_Data
  WHERE Id = OleId;
  RETURN '<***>';
 EXCEPTION WHEN NO_DATA_FOUND THEN
  RETURN '<...>';
END Check_Ole;
---------------------------------------------------------------
-- Проверка на существования критериев
---------------------------------------------------------------
PROCEDURE Check_Criteria(ClsId IN Varchar2) IS
BEGIN
  -- Data_Views.Create_Crt_Def(ClsId, '1');
  NULL;
END Check_Criteria;
---------------------------------------------------------------
-- Возвращает текст View критери
---------------------------------------------------------------
FUNCTION Get_Vw_Crit(mId IN Varchar2)
 RETURN VARCHAR2 IS
 Text_View Varchar2(32000);
BEGIN
 SELECT Text INTO Text_View From User_Views
  WHERE View_Name = (select short_name from criteria where id = mId);
 RETURN Text_View;
 EXCEPTION WHEN NO_DATA_FOUND THEN
  RETURN NULL;
END Get_Vw_Crit;
---------------------------------------------------------------
-- Журналирование представлений
---------------------------------------------------------------
function log_view(p_crit in varchar2, p_action in varchar2 default 'VIEW') return number is
v_id  number;
begin
  select AUD.diary_id.nextval into v_id from dual;
  rtl.write_log('P',nvl(p_action,'VIEW'),v_id,p_crit);
  return v_id;
end;
procedure log_view_par(p_id number, p_name varchar2, p_value varchar2) is
begin
  AUD.dparam_ins(inst_info.gowner,p_id,p_name,substr(p_value,1,4000));
end;
---------------------------------------------------------------
-- Борьба с глюками
---------------------------------------------------------------
PROCEDURE Bug_Fix IS
  cid INTEGER; -- Id Dynamic SQL курсора
BEGIN
  cid := Dbms_Sql.Open_Cursor;
  Dbms_Sql.Parse(cid,'ALTER PACKAGE SECURITY COMPILE BODY',Dbms_Sql.V7);
  Dbms_Sql.Close_Cursor(cid);
EXCEPTION
  WHEN OTHERS THEN
    Dbms_Sql.Close_Cursor(cid);
    RAISE;
END Bug_Fix;
---------------------------------------------------------------
-- Возвращает значения системных установок
---------------------------------------------------------------
FUNCTION Get_SysInfo(Value_Name IN VARCHAR2) RETURN VARCHAR2 IS
BEGIN
    RETURN SysInfo.GetValue(Value_Name);
END;
---------------------------------------------------------------
-- Возвращает сетевое им
---------------------------------------------------------------
FUNCTION Get_UserShortName RETURN VARCHAR2 IS
BEGIN
    RETURN rtl.USR;
END;
---------------------------------------------------------------
FUNCTION Get_UserName RETURN VARCHAR2 IS
   Result  varchar2(100);
BEGIN
    Result := rtl.Usr;
    SELECT Name INTO Result FROM Users WHERE UserName=Result;
    RETURN Result;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        RETURN NULL;
END Get_UserName;
---------------------------------------------------------------
-- Возвращает свойства пользовател
---------------------------------------------------------------
FUNCTION Get_UserProp RETURN VARCHAR2 IS
   Result  varchar2(2000);
BEGIN
    Result := rtl.Usr;
    SELECT Properties INTO Result FROM Users WHERE UserName=Result;
    RETURN Result;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        RETURN NULL;
END Get_UserProp;
---------------------------------------------------------------
-- Устанавливает ID реквизита типа OLE
---------------------------------------------------------------
FUNCTION Set_Ole_Id(ObjId IN varchar2, ClassId IN Varchar2, Qual IN VARCHAR2)
     RETURN number IS
  NewId number;
BEGIN
    IF Security.Cls_Accessible(ClassId, rtl.USR) = '0' THEN
       RETURN NULL; -- Нет прав
    END IF;
    NewId:=rtl.get_value(ObjId,Qual,ClassId);
    IF NewId IS NULL THEN
       NewId:=rtl.next_value('SEQ_ID');
       rtl.set_value(ObjId,Qual,NewId,ClassId);
    END IF;
    RETURN NewId;
END Set_Ole_Id;
---------------------------------------------------------------
FUNCTION Del_Ole_Id(ObjId IN varchar2, ClassId IN Varchar2, Qual IN VARCHAR2)
     RETURN varchar2 IS
  NewId number;
BEGIN
    IF Security.Cls_Accessible(ClassId, rtl.USR) = '0' THEN
       RETURN '0'; -- Нет прав
    END IF;
    NewId:=rtl.get_value(ObjId,Qual,ClassId);
    IF NewId IS NOT NULL THEN
        delete long_data where id=NewId;
    END IF;
    rtl.set_value(ObjId,Qual,null,ClassId);
    RETURN '1';
END Del_Ole_Id;
---------------------------------------------------------------
-- Работа с реквизитами типа OLE с kernel = true
---------------------------------------------------------------
function open_ole(obj_id in varchar2, class_id in varchar2, qual in varchar2,
                  obj_type out varchar2, will_write in number default 0) return number is
    handle number;
    class_info lib.class_info_t;
    table_name varchar2(30);
    column_name varchar2(30);
    self_class_id varchar2(30);
    lob lob_t;
    features varchar2(2000);
    part varchar2(1); -- 1 - PARTITION,  2 - PARTVIEW
    upd_sn varchar2(100);
    key1 varchar2(100);
    key2 varchar2(100);
begin
    if security.cls_accessible(class_id, rtl.usr) = '0' then
        message.error(constant.EXEC_ERROR, 'CLASS_NOT_ACCESSIBLE', class_id, rtl.usr, 'OPEN_OLE:');
    end if;
    --features - c.base_class_id||'.'||c.target_class_id||'.'||c.props||v_qual||'.'||c.self_class_id||'.'||c.class_id;
    lib.qual_column(class_id, qual, table_name, column_name, features);
    if table_name is null or column_name is null then
        message.error(constant.PLP_ERROR, 'NO_TABLE_COLUMN', qual, class_id);
    end if;
    self_class_id:= substr(features,instr(features,'.',1,3)+1,instr(features,'.',1,4)-instr(features,'.',1,3)-1);
    if not lib.class_exist(self_class_id,class_info) then
        message.error(-20999, 'KRNL','CLASS_NOT_FOUND',self_class_id,'OPEN_OLE');
    end if;
    if class_info.base_id <> constant.OLE then
        message.error(constant.KERNEL_ERROR, 'BAD_BASE_ID', class_info.class_id);
    end if;
    upd_sn:= ', sn=nvl(sn,1)+1, su=sys_context('''||Inst_Info.Owner||'_SYSTEM'',''ID'') ';
    part:= substr(features,instr(features,'.',1,2)+5,1); -- c_props - position = 5@
    features:= null;
    if part in ('1','2') then
      key1:= 'key>='||valmgr.get_key(class_id) || ' and ';
      if part='1' then
        key2:= 'key=1000 and ';
        features:= ' partition('||table_name||'#0)';
      end if;
    end if;
    if class_info.kernel then
        obj_type := class_info.class_id;
        lob.obj_id := obj_id;
        lob.obj_class := class_id;
        lob.obj_type  := class_info.class_id;
        lob.write_mode:= nvl(will_write, 0);
        if class_info.class_id = BLOB_TYPE then
            if lob.write_mode <> 0 then
                lob.query_get := 'select ' || column_name || ' from ' || table_name || features ||
                    ' where ' || key2 || 'id = :1 for update nowait';
                lob.query_set := 'update ' || table_name || features || ' set ' ||
                    column_name || ' = empty_blob()' || upd_sn || ' where ' || key2 || 'id = :1 returning ' ||
                    column_name || ' into :2';
                lob.query_del := 'update ' || table_name || features || ' set ' ||
                    column_name || ' = null' || upd_sn || 'where ' || key2 || 'id = :1';
            else
                lob.query_get := 'select ' || column_name || ' from ' ||
                    table_name || case when part='2' then '#PRT' end ||
                    ' where ' || key1 || 'id = :1';
            end if;
            execute immediate lob.query_get into lob.blocator using lob.obj_id;
        elsif class_info.class_id = CLOB_TYPE then
            if lob.write_mode <> 0 then
                lob.query_get := 'select ' || column_name || ' from ' || table_name || features ||
                    ' where ' || key2 || 'id = :1 for update nowait';
                lob.query_set := 'update ' || table_name || features || ' set ' ||
                    column_name || ' = empty_clob()' || upd_sn || 'where ' || key2 || 'id = :1 returning ' ||
                    column_name || ' into :2';
                lob.query_del := 'update ' || table_name || features || ' set ' ||
                    column_name || ' = null' || upd_sn || 'where ' || key2 || 'id= :1';
            else
                lob.query_get := 'select ' || column_name || ' from ' ||
                    table_name || case when part='2' then '#PRT' end ||
                    ' where ' || key1 || 'id = :1';
            end if;
            execute immediate lob.query_get into lob.clocator using lob.obj_id;
        elsif class_info.class_id = BFILE_TYPE then
            if lob.write_mode <> 0 then
                message.error(constant.EXEC_ERROR, 'OLE_MODE', class_info.class_id, 'W');
            end if;
            execute immediate 'select ' || column_name || ' from ' ||
               table_name || case when part='2' then '#PRT' end ||
               ' where ' || key1 || 'id = :1' into lob.flocator using lob.obj_id;
            if lob.flocator is not null then
                dbms_lob.open(lob.flocator, dbms_lob.file_readonly);
            end if;
        elsif class_info.class_id = LONG_TYPE then
            if lob.write_mode <> 0 then
                lob.query_get := 'select ' || column_name || ' from ' ||
                    table_name || case when part='2' then '#PRT' end ||
                    ' where ' || key1 || 'id = :obj_id';
                lob.query_set := 'update ' || table_name || features || ' set ' ||
                    column_name || ' = :data' || upd_sn || 'where ' || key2 || 'id = :obj_id';
            else
                lob.long_cursor := dbms_sql.open_cursor;
                dbms_sql.parse(lob.long_cursor, 'select ' || column_name || ' from ' ||
                               table_name || case when part='2' then '#PRT' end ||
                               ' where ' || key1 || 'id = :1', dbms_sql.native);
                dbms_sql.bind_variable(lob.long_cursor, ':1', lob.obj_id, 128);
                dbms_sql.define_column_long(lob.long_cursor, 1);
                -- 'handle :=' only because execute is function and we need not additional variable
                handle := dbms_sql.execute(lob.long_cursor);
                if dbms_sql.fetch_rows(lob.long_cursor) <= 0 then
                    message.error(constant.CLASS_ERROR, 'OBJECT_NOT_FOUND', obj_id, class_id);
                end if;
            end if;
        elsif class_info.class_id = RAW_TYPE then
            lob.query_get := 'select ' || column_name || ' from ' ||
                table_name || case when part='2' then '#PRT' end ||
                ' where id ' || key1 || '= :obj_id';
            if lob.write_mode <> 0 then
                lob.query_set := 'update ' || table_name || features || ' set ' ||
                    column_name || ' = :data' || upd_sn || 'where ' || key2 || 'id = :obj_id';
            end if;
        elsif class_info.class_id = LONG_RAW_TYPE then
            lob.query_get := 'select ' || column_name || ' from ' ||
                table_name || case when part='2' then '#PRT' end ||
                ' where id ' || key1 || '= :obj_id';
            if lob.write_mode <> 0 then
                lob.query_set := 'update ' || table_name || features || ' set ' ||
                    column_name || ' = :data' || upd_sn || 'where ' || key2 || 'id = :obj_id';
            end if;
        else
            message.error(constant.EXEC_ERROR, 'OLE_UNSUPPORTED_CLASS', class_info.class_id);
        end if;
        handle := nvl(lobs.last + 1, 1);
        lobs(handle) := lob;
    else
        obj_type := constant.OLE;
        execute immediate 'select ' || column_name || ' from ' ||
                          table_name || case when part='2' then '#PRT' end ||
                          ' where ' || key1 || 'id = :1'
            into handle using obj_id;
    end if;
    return handle;
exception
    when NO_DATA_FOUND then
        message.error(constant.CLASS_ERROR, 'OBJECT_NOT_FOUND', obj_id, class_id);
    when rtl.RESOURCE_BUSY then
        message.err(message.LOCK_ERROR_NUMBER,constant.EXEC_ERROR, 'RESOURCE_BUSY', obj_id, class_id);
end open_ole;
---------------------------------------------------------------
function get_ole_data(ahandle in number, abbuffer out raw, acbuffer out varchar2,
                       aoffset in integer default null,
                       aamount in binary_integer default null) return binary_integer is
    offset integer := nvl(aoffset, 1);
    amount binary_integer := nvl(aamount, 32767);
begin
    if not lobs.exists(ahandle) then
        message.error(constant.EXEC_ERROR, 'OLE_HANDLE', ahandle);
    end if;
    if lobs(ahandle).write_mode <> 0 then
        message.error(constant.EXEC_ERROR, 'OLE_NOT_IN_READ_MODE', ahandle);
    end if;
    if offset < 1 then
        message.error(constant.EXEC_ERROR, 'OLE_OFFSET_LT_1', offset);
    end if;
    if amount < 0 then
        message.error(constant.EXEC_ERROR, 'OLE_AMOUNT_LT_0', amount);
    end if;
    if lobs(ahandle).obj_type = BLOB_TYPE then
        if lobs(ahandle).blocator is null then
            return 0;
        end if;
        if offset > dbms_lob.lobmaxsize then
            return 0;
        end if;
        if (offset + amount - 1) > dbms_lob.lobmaxsize then
            amount := dbms_lob.lobmaxsize - offset + 1;
        end if;
        if dbms_lob.isopen(lobs(ahandle).blocator) = 0 then
            execute immediate lobs(ahandle).query_get into lobs(ahandle).blocator using lobs(ahandle).obj_id;
        end if;
        begin
          dbms_lob.read(lobs(ahandle).blocator, amount, offset, abbuffer);
        exception when NO_DATA_FOUND then
          return 0;
        end;
    elsif lobs(ahandle).obj_type = CLOB_TYPE then
        if lobs(ahandle).clocator is null then
            return 0;
        end if;
        if offset > dbms_lob.lobmaxsize then
            return 0;
        end if;
        if (offset + amount - 1) > dbms_lob.lobmaxsize then
            amount := dbms_lob.lobmaxsize - offset + 1;
        end if;
        if dbms_lob.isopen(lobs(ahandle).clocator) = 0 then
            execute immediate lobs(ahandle).query_get into lobs(ahandle).clocator using lobs(ahandle).obj_id;
        end if;
        begin
          dbms_lob.read(lobs(ahandle).clocator, amount, offset, acbuffer);
        exception when NO_DATA_FOUND then
          return 0;
        end;
    elsif lobs(ahandle).obj_type = BFILE_TYPE then
        if lobs(ahandle).flocator is null then
            return 0;
        end if;
        if offset > dbms_lob.lobmaxsize then
            return 0;
        end if;
        if (offset + amount - 1) > dbms_lob.lobmaxsize then
            amount := dbms_lob.lobmaxsize - offset + 1;
        end if;
        begin
          dbms_lob.read(lobs(ahandle).flocator, amount, offset, abbuffer);
        exception when NO_DATA_FOUND then
          return 0;
        end;
    elsif lobs(ahandle).obj_type = LONG_TYPE then
        dbms_sql.column_value_long(lobs(ahandle).long_cursor, 1, amount, offset - 1, acbuffer, amount);
    elsif lobs(ahandle).obj_type = RAW_TYPE then
        declare
            bbuffer raw(2000);
        begin
            execute immediate lobs(ahandle).query_get into bbuffer using lobs(ahandle).obj_id;
            if bbuffer is null or offset > utl_raw.length(bbuffer) then
                return 0;
            end if;
            if (offset + amount - 1) > utl_raw.length(bbuffer) then
                amount := utl_raw.length(bbuffer) - offset + 1;
            end if;
            bbuffer := utl_raw.substr(bbuffer, offset, amount);
            abbuffer := bbuffer;
            amount := utl_raw.length(bbuffer);
        end;
    elsif lobs(ahandle).obj_type = LONG_RAW_TYPE then
        declare
            bbuffer raw(32767);
        begin
            begin
                execute immediate lobs(ahandle).query_get into bbuffer using lobs(ahandle).obj_id;
            exception when value_error then
                message.error(constant.EXEC_ERROR, 'OLE_DATA_TOO_LONG', lobs(ahandle).obj_type, 32767);
            end;
            if bbuffer is null or offset > utl_raw.length(bbuffer) then
                return 0;
            end if;
            if (offset + amount - 1) > utl_raw.length(bbuffer) then
                amount := utl_raw.length(bbuffer) - offset + 1;
            end if;
            bbuffer := utl_raw.substr(bbuffer, offset, amount);
            abbuffer := bbuffer;
            amount := utl_raw.length(bbuffer);
        end;
    end if;
    return amount;
exception
    when NO_DATA_FOUND then
        message.error(constant.CLASS_ERROR, 'OBJECT_NOT_FOUND', lobs(ahandle).obj_id, lobs(ahandle).obj_type);
end get_ole_data;
---------------------------------------------------------------
function get_ole_datab(ahandle in number, abuffer out raw,
                       aoffset in integer default null,
                       aamount in binary_integer default null) return binary_integer is
    amount binary_integer;
    cbuffer varchar2(32767);
begin
    amount := get_ole_data(ahandle, abuffer, cbuffer, aoffset, aamount);
    if amount = 0 then
        return 0;
    end if;
    if abuffer is not null then
        return amount;
    elsif cbuffer is not null then
        abuffer := utl_raw.cast_to_raw(cbuffer);
        return amount;
    else
        return 0;
    end if;
end get_ole_datab;
---------------------------------------------------------------
function get_ole_datac(ahandle in number, abuffer out varchar2,
                       aoffset in integer default null,
                       aamount in binary_integer default null) return binary_integer is
    amount binary_integer;
    bbuffer raw(32767);
begin
    amount := get_ole_data(ahandle, bbuffer, abuffer, aoffset, aamount);
    if amount = 0 then
        return 0;
    end if;
    if abuffer is not null then
        return amount;
    elsif bbuffer is not null then
        if amount > 16383 then
            amount := 16383;
            bbuffer := utl_raw.substr(bbuffer, 1, amount);
        end if;
        abuffer := rawtohex(bbuffer);
        return amount;
    else
        return 0;
    end if;
end get_ole_datac;
---------------------------------------------------------------
procedure set_ole_data(ahandle in number, abbuffer in raw, acbuffer in varchar2,
                        aoffset in integer default null,
                        aamount in binary_integer default null) is
    offset integer := nvl(aoffset, 1);
    amount binary_integer := nvl(aamount, 32767);
begin
    if not lobs.exists(ahandle) then
        message.error(constant.EXEC_ERROR, 'OLE_HANDLE', ahandle);
    end if;
    if lobs(ahandle).write_mode = 0 then
        message.error(constant.EXEC_ERROR, 'OLE_NOT_IN_WRITE_MODE', ahandle);
    end if;
    if amount < 0 then
        message.error(constant.EXEC_ERROR, 'OLE_AMOUNT_LT_0', amount);
    end if;
    if offset < 1 and amount>0 then
        message.error(constant.EXEC_ERROR, 'OLE_OFFSET_LT_1', offset);
    end if;
    if amount = 0 and (abbuffer is not null or acbuffer is not null) then
        return;
    end if;
    if abbuffer is not null then
        if amount > utl_raw.length(abbuffer) then
            amount := utl_raw.length(abbuffer);
        end if;
    end if;
    if lobs(ahandle).obj_type = BLOB_TYPE then
        if acbuffer is not null or abbuffer is not null then
            if acbuffer is not null then
                if mod(length(acbuffer), 2) = 1 then
                    raise INVALID_HEX_VALUE;
                end if;
                if amount > length(acbuffer) / 2 then
                    amount := length(acbuffer) / 2;
                end if;
            end if;
            if (offset + amount - 1) > dbms_lob.lobmaxsize then
                message.error(constant.EXEC_ERROR, 'OLE_RIGHT_BOUND_GT_MAX_SIZE', offset, amount, dbms_lob.lobmaxsize);
            end if;
        else
            if offset > dbms_lob.lobmaxsize then
                message.error(constant.EXEC_ERROR, 'OLE_RIGHT_BOUND_GT_MAX_SIZE', offset, 0, dbms_lob.lobmaxsize);
            end if;
            if lobs(ahandle).blocator is null then
                return;
            end if;
        end if;
        -- PLATFORM-11755 Если offset = 1, значит начинается перезапись старого содержимого -> сбросим в empty_blob()
        if lobs(ahandle).blocator is null or offset = 1 then
            execute immediate lobs(ahandle).query_set
                using lobs(ahandle).obj_id returning into lobs(ahandle).blocator;
        elsif dbms_lob.isopen(lobs(ahandle).blocator) = 0 then
            execute immediate lobs(ahandle).query_get
                into lobs(ahandle).blocator using lobs(ahandle).obj_id;
        end if;
        if abbuffer is not null then
            dbms_lob.write(lobs(ahandle).blocator, amount, offset, abbuffer);
        elsif acbuffer is not null then
            declare
                bbuffer raw(16383);
            begin
                bbuffer := hextoraw(acbuffer);
                dbms_lob.write(lobs(ahandle).blocator, amount, offset, bbuffer);
            end;
        else
            if offset=0 and amount=0 then
              if lobs(ahandle).blocator is not null and dbms_lob.isopen(lobs(ahandle).blocator) > 0 then
                dbms_lob.close(lobs(ahandle).blocator);
              end if;
              execute immediate lobs(ahandle).query_del using lobs(ahandle).obj_id;
              lobs(ahandle).blocator:= null;
            else
              dbms_lob.trim(lobs(ahandle).blocator, offset - 1);
            end if;
        end if;
    elsif lobs(ahandle).obj_type = CLOB_TYPE then
        if acbuffer is not null or abbuffer is not null then
            if acbuffer is not null then
                if amount > length(acbuffer) then
                    amount := length(acbuffer);
                end if;
            end if;
            if (offset + amount - 1) > dbms_lob.lobmaxsize then
                message.error(constant.EXEC_ERROR, 'OLE_RIGHT_BOUND_GT_MAX_SIZE', offset, amount, dbms_lob.lobmaxsize);
            end if;
        else
            if offset > dbms_lob.lobmaxsize then
                message.error(constant.EXEC_ERROR, 'OLE_RIGHT_BOUND_GT_MAX_SIZE', offset, 0, dbms_lob.lobmaxsize);
            end if;
            if lobs(ahandle).clocator is null then
                return;
            end if;
        end if;
        if lobs(ahandle).clocator is null then
            execute immediate lobs(ahandle).query_set
                using lobs(ahandle).obj_id returning into lobs(ahandle).clocator;
        elsif dbms_lob.isopen(lobs(ahandle).clocator) = 0 then
            execute immediate lobs(ahandle).query_get
                into lobs(ahandle).clocator using lobs(ahandle).obj_id;
        end if;
        if abbuffer is not null then
            dbms_lob.write(lobs(ahandle).clocator, amount, offset, utl_raw.cast_to_varchar2(abbuffer));
        elsif acbuffer is not null then
            dbms_lob.write(lobs(ahandle).clocator, amount, offset, acbuffer);
        else
            if offset=0 and amount=0 then
              if lobs(ahandle).clocator is not null and dbms_lob.isopen(lobs(ahandle).clocator) > 0 then
                dbms_lob.close(lobs(ahandle).clocator);
              end if;
              execute immediate lobs(ahandle).query_del using lobs(ahandle).obj_id;
              lobs(ahandle).clocator:= null;
            else
              dbms_lob.trim(lobs(ahandle).clocator, offset - 1);
            end if;
        end if;
    elsif lobs(ahandle).obj_type = LONG_TYPE then
        if acbuffer is not null or abbuffer is not null then
            if acbuffer is not null then
                if amount > length(acbuffer) then
                    amount := length(acbuffer);
                end if;
            end if;
            if (offset + amount - 1) > 32767 then
                message.error(constant.EXEC_ERROR, 'OLE_RIGHT_BOUND_GT_MAX_SIZE', offset, amount, 32767);
            end if;
            declare
                cbuffer varchar2(32767);
                cbuffer1 varchar2(32767);
            begin
                begin
                    execute immediate lobs(ahandle).query_get into cbuffer using lobs(ahandle).obj_id;
                exception when value_error then
                    message.error(constant.EXEC_ERROR, 'OLE_DATA_TOO_LONG', lobs(ahandle).obj_type, 32767);
                end;
                if abbuffer is not null then
                    cbuffer1 := utl_raw.cast_to_varchar2(abbuffer);
                else
                    cbuffer1 := acbuffer;
                end if;
                if amount < length(cbuffer1) then
                    cbuffer1 := substr(cbuffer1, 1, amount);
                end if;
                if cbuffer is null then
                    cbuffer := lpad(nvl(cbuffer1,' '), offset);
                elsif offset > length(cbuffer) + 1 then
                    cbuffer1 := lpad(nvl(cbuffer1,' '), offset - length(cbuffer));
                    cbuffer := cbuffer || cbuffer1;
                elsif offset = length(cbuffer) + 1 then
                    cbuffer := cbuffer || cbuffer1;
                else
                    cbuffer := substr(cbuffer, 1, offset-1) || cbuffer1 || substr(cbuffer, offset + amount);
                end if;
                execute immediate lobs(ahandle).query_set using cbuffer, lobs(ahandle).obj_id;
            end;
        else
            if offset > 32767 then
                message.error(constant.EXEC_ERROR, 'OLE_RIGHT_BOUND_GT_MAX_SIZE', offset, 0, 32767);
            end if;
            if offset = 1 or (offset = 0 and amount=0) then
                execute immediate lobs(ahandle).query_set using to_char(null), lobs(ahandle).obj_id;
                return;
            end if;
            declare
                cbuffer varchar2(32767);
            begin
                begin
                    execute immediate lobs(ahandle).query_get into cbuffer using lobs(ahandle).obj_id;
                exception when value_error then
                    message.error(constant.EXEC_ERROR, 'OLE_DATA_TOO_LONG', lobs(ahandle).obj_type, 32767);
                end;
                cbuffer := substr(cbuffer, 1, offset-1);
                execute immediate lobs(ahandle).query_set using cbuffer, lobs(ahandle).obj_id;
            end;
        end if;
    elsif lobs(ahandle).obj_type = RAW_TYPE then
        if acbuffer is not null or abbuffer is not null then
            if acbuffer is not null then
                if mod(length(acbuffer), 2) = 1 then
                    raise INVALID_HEX_VALUE;
                end if;
                if amount > length(acbuffer) / 2 then
                    amount := length(acbuffer) / 2;
                end if;
            end if;
            if (offset + amount - 1) > 2000 then
                message.error(constant.EXEC_ERROR, 'OLE_RIGHT_BOUND_GT_MAX_SIZE', offset, amount, 2000);
            end if;
            declare
                bbuffer raw(2000);
            begin
                execute immediate lobs(ahandle).query_get into bbuffer using lobs(ahandle).obj_id;
                if bbuffer is null or utl_raw.length(bbuffer) = 0 then
                    bbuffer := hextoraw('00');
                end if;
                if abbuffer is not null then
                    bbuffer := utl_raw.overlay(abbuffer, bbuffer, offset, amount);
                else
                    bbuffer := utl_raw.overlay(hextoraw(substr(acbuffer, 1, amount * 2)), bbuffer, offset, amount);
                end if;
                execute immediate lobs(ahandle).query_set using bbuffer, lobs(ahandle).obj_id;
            end;
        else
            if offset > 2000 then
                message.error(constant.EXEC_ERROR, 'OLE_RIGHT_BOUND_GT_MAX_SIZE', offset, 0, 2000);
            end if;
            if offset = 1 or (offset = 0 and amount=0) then
                execute immediate lobs(ahandle).query_set using hextoraw(null), lobs(ahandle).obj_id;
                return;
            end if;
            declare
                bbuffer raw(2000);
            begin
                execute immediate lobs(ahandle).query_get into bbuffer using lobs(ahandle).obj_id;
                if bbuffer is null or utl_raw.length(bbuffer) <= offset - 1 then
                    return;
                end if;
                execute immediate lobs(ahandle).query_set using utl_raw.substr(bbuffer, 1, offset - 1), lobs(ahandle).obj_id;
            end;
        end if;
    elsif lobs(ahandle).obj_type = LONG_RAW_TYPE then
        if acbuffer is not null or abbuffer is not null then
            if acbuffer is not null then
                if mod(length(acbuffer), 2) = 1 then
                    raise INVALID_HEX_VALUE;
                end if;
                if amount > length(acbuffer) / 2 then
                    amount := length(acbuffer) / 2;
                end if;
            end if;
            if (offset + amount - 1) > 32767 then
                message.error(constant.EXEC_ERROR, 'OLE_RIGHT_BOUND_GT_MAX_SIZE', offset, amount, 32767);
            end if;
            declare
                bbuffer raw(32767);
            begin
                begin
                    execute immediate lobs(ahandle).query_get into bbuffer using lobs(ahandle).obj_id;
                exception when value_error then
                    message.error(constant.EXEC_ERROR, 'OLE_DATA_TOO_LONG', lobs(ahandle).obj_type, 32767);
                end;
                if bbuffer is null or utl_raw.length(bbuffer) = 0 then
                    bbuffer := hextoraw('00');
                end if;
                if abbuffer is not null then
                    bbuffer := utl_raw.overlay(abbuffer, bbuffer, offset, amount);
                else
                    bbuffer := utl_raw.overlay(hextoraw(acbuffer), bbuffer, offset, amount);
                end if;
                execute immediate lobs(ahandle).query_set using bbuffer, lobs(ahandle).obj_id;
            end;
        else
            if offset > 32767 then
                message.error(constant.EXEC_ERROR, 'OLE_RIGHT_BOUND_GT_MAX_SIZE', offset, 0, 32767);
            end if;
            if offset = 1 or (offset = 0 and amount=0) then
                execute immediate lobs(ahandle).query_set using hextoraw(null), lobs(ahandle).obj_id;
                return;
            end if;
            declare
                bbuffer raw(32767);
            begin
                execute immediate lobs(ahandle).query_get into bbuffer using lobs(ahandle).obj_id;
                if bbuffer is null or utl_raw.length(bbuffer) <= offset - 1 then
                    return;
                end if;
                execute immediate lobs(ahandle).query_set using utl_raw.substr(bbuffer, 1, offset - 1), lobs(ahandle).obj_id;
            end;
        end if;
    end if;
exception
    when NO_DATA_FOUND then
        message.error(constant.CLASS_ERROR, 'OBJECT_NOT_FOUND', lobs(ahandle).obj_id, lobs(ahandle).obj_type);
    when rtl.RESOURCE_BUSY then
        message.err(message.LOCK_ERROR_NUMBER,constant.EXEC_ERROR, 'RESOURCE_BUSY', lobs(ahandle).obj_id, lobs(ahandle).obj_class);
end set_ole_data;
---------------------------------------------------------------
procedure set_ole_datab(ahandle in number, abuffer in raw,
                        aoffset in integer default null,
                        aamount in binary_integer default null) is
begin
    set_ole_data(ahandle, abuffer, null, aoffset, aamount);
end set_ole_datab;
---------------------------------------------------------------
procedure set_ole_datac(ahandle in number, abuffer in varchar2,
                        aoffset in integer default null,
                        aamount in binary_integer default null) is
begin
    set_ole_data(ahandle, null, abuffer, aoffset, aamount);
end set_ole_datac;
---------------------------------------------------------------
function get_blocator(ahandle in number) return blob is
begin
  if not lobs.exists(ahandle) then
      message.error(constant.EXEC_ERROR, 'OLE_HANDLE', ahandle);
  end if;
  return lobs(ahandle).blocator;
end;
--
function get_clocator(ahandle in number) return clob is
begin
  if not lobs.exists(ahandle) then
      message.error(constant.EXEC_ERROR, 'OLE_HANDLE', ahandle);
  end if;
  return lobs(ahandle).clocator;
end;
--
function get_flocator(ahandle in number) return bfile is
begin
  if not lobs.exists(ahandle) then
      message.error(constant.EXEC_ERROR, 'OLE_HANDLE', ahandle);
  end if;
  return lobs(ahandle).flocator;
end;
---------------------------------------------------------------
procedure close_ole(handle in number) is
begin
    if not lobs.exists(handle) then
        message.error(constant.EXEC_ERROR, 'OLE_HANDLE', handle);
    end if;
    if lobs(handle).blocator is not null and dbms_lob.isopen(lobs(handle).blocator) > 0 then
        dbms_lob.close(lobs(handle).blocator);
    elsif lobs(handle).clocator is not null and dbms_lob.isopen(lobs(handle).clocator) > 0 then
        dbms_lob.close(lobs(handle).clocator);
    elsif lobs(handle).flocator is not null and dbms_lob.isopen(lobs(handle).flocator) > 0 then
        dbms_lob.close(lobs(handle).flocator);
    elsif lobs(handle).long_cursor is not null then
        dbms_sql.close_cursor(lobs(handle).long_cursor);
    end if;
    lobs.delete(handle);
end close_ole;
---------------------------------------------------------------
-- Работа с данными типа BLOB в таблицах LONG_DATA, LRAW, ORSA_JOBS_OUT
---------------------------------------------------------------
-- open lob for LONG_DATA, LRAW
function open_lob(p_table in varchar2, p_id in varchar2, p_mode in number default 0) return number is
begin
  if (p_table in ('LRAW','LICENSE_DATA') and p_mode=0) or p_table='LONG_DATA' then
    return long_conv.open_data(p_id,p_mode,p_table,'BLOB');
  end if;
  raise rtl.NO_PRIVILEGES;
end;
-- open lob for ORSA_JOBS_OUT
function open_lob(p_job number, p_pos number, p_out_type varchar2  default 'out', p_mode in number default 0) return number is
begin
  return long_conv.open_data(p_job||','||p_pos||','||p_out_type,p_mode,'ORSA_JOBS_OUT','BLOB');
end;
-- open BLOB|CLOB for ORSA_PAR_LOB
function open_lob(p_job number, p_pos number, p_param varchar2, p_type varchar2, p_mode in number default 0) return number is
begin
  return long_conv.open_data(p_job||','||p_pos||','||p_param,p_mode,'ORSA_PAR_LOB',p_type);
end;
--
function get_lob_data(p_handle in number, p_data out raw, p_pos pls_integer default null,
                      p_size pls_integer default null) return pls_integer is
begin
  return long_conv.read_data(p_handle, p_data, p_size, p_pos);
end;

function get_lob_datac(p_handle in number, p_data out varchar2, p_pos pls_integer default null,
                      p_size pls_integer default null) return pls_integer is
begin
  return long_conv.read_datac(p_handle, p_data, p_size, p_pos);
end;
--
function set_lob_data(p_handle in number, p_data in raw, p_pos pls_integer default null,
                      p_size pls_integer default null) return pls_integer is
begin
  return long_conv.write_data(p_handle, p_data, p_size, p_pos);
end;
--
function set_lob_datac(p_handle in number, p_data in varchar2, p_pos pls_integer default null,
                       p_size pls_integer default null) return pls_integer is
begin
  return long_conv.write_datac(p_handle, p_data, p_size, p_pos);
end;
--
function clear_lob_data(p_handle number, p_size pls_integer default null) return pls_integer is
begin
  return long_conv.clear_data(p_handle,p_size);
end;
--
function close_lob(p_handle number, p_commit boolean default true) return number is
begin
  return long_conv.close_data(p_handle,p_commit);
end;
--
procedure find_sul(p_list in out nocopy  varchar2) is
begin
  opt_mgr.find_data(p_list,null,'L','VALID');
end;
---------------------------------------------------------------
-- Работа с шаблонами печати представлений
---------------------------------------------------------------
procedure check_criteria_prints_access is
    b boolean;
    u varchar2(30);
begin
    b := true;
    u := rtl.USR;
    if u in (Inst_Info.Owner,Inst_Info.GOwner) or dbms_session.is_role_enabled(inst_info.owner||'_ADMIN') then
        b := false;
    elsif dbms_session.is_role_enabled(inst_info.owner||'_USER') then
        begin
            select '1' into u from users where username=u and instr(properties,'|SENIOR')>0;
            b := false;
        exception when no_data_found then null;
        end;
    end if;
    if b then
        message.err(-20999, constant.UADMIN_ERROR, 'NO_RIGHTS');
    end if;
end check_criteria_prints_access;
---------------------------------------------------------------
procedure edit_criteria_print(criteria_id varchar2, name varchar2, header varchar2,
                              font_name varchar2, outfile varchar2, keys varchar2,
                              delimiter varchar2, quote varchar2, page varchar2) is
begin
    check_criteria_prints_access;
    data_views.edit_criteria_print(criteria_id, name, header,
        font_name, outfile, keys, delimiter, quote, page);
end;
---------------------------------------------------------------
procedure delete_criteria_print(criteria_id varchar2, name varchar2) is
begin
    check_criteria_prints_access;
    data_views.delete_criteria_print(criteria_id, name);
end;
---------------------------------------------------------------
procedure edit_criteria_print_column(criteria_id varchar2, print_name varchar2,
                                     alias varchar2, position number, width number,
                                     oper varchar2 default null,
                                     quote varchar2 default null,
                                     align varchar2 default null) is
begin
    check_criteria_prints_access;
    data_views.edit_criteria_print_column(criteria_id, print_name,
        alias, position, width, oper, quote, align);
end;
---------------------------------------------------------------
procedure delete_criteria_print_column(criteria_id varchar2, print_name varchar2,
                                     alias varchar2 default null) is
begin
    check_criteria_prints_access;
    data_views.delete_criteria_print_column(criteria_id, print_name, alias);
end;
---------------------------------------------------------------
-- Работа с Электронным Документооборотом.
---------------------------------------------------------------
function get_attrs(p_edt_id varchar2) return varchar2 is
begin
    return edoc_mgr.get_attrs(p_edt_id);
end;
---
procedure add_sign(p_edt_id varchar2, p_obj_id varchar2,
    p_block raw, p_sign raw, p_state_id varchar2 := null) is
begin
    edoc_mgr.add_sign(p_edt_id, p_obj_id, p_state_id, p_block, p_sign);
end;
---
procedure check_sign(id number, code out number, key_id out varchar2, error out varchar2) is
    code_ number;
    key_id_ edoc_mgr.KEY_ID_TYPE;
begin
    edoc_mgr.check_sign(id, code_, key_id_);
    code := code_;
    key_id := edoc_mgr.key2str(key_id_);
    if code_ <> 0 then
        error := edoc_mgr.get_err_msg;
    end if;
end;
---
procedure log_edoc(p_obj_id varchar2, p_class_id varchar2,
    p_edt_id varchar2, p_code varchar2, p_text varchar2 := null) is
begin
    edoc_mgr.log_edoc(p_obj_id, p_class_id, p_edt_id, p_code, p_text);
end;
--
procedure disable_as_sign is
begin
    edoc_mgr.disable_as_sign;
end;
---------------------------------------------------------------
-- Переходник в FORMS_MGR: Если нет формы, то создает ее
---------------------------------------------------------------
PROCEDURE Frm_Touch(meth in varchar2) IS
BEGIN
    Forms_Mgr.Frm_Touch (meth, true, true);
END Frm_Touch;
--  Переходники
function value_ext(p_obj_id varchar2, p_xqual varchar2, p_meth_id varchar2 default null,p_class_id varchar2 default null) return varchar2 is
begin
    return bindings.get_value_ext(p_obj_id,p_xqual,p_meth_id,p_class_id);
exception when others then
    if sqlcode in (-6508,-4061) then raise; end if;
    return null;
end;
function obj_name(p_obj_id varchar2, p_class_id varchar2 default null) return varchar2 is
begin
    return valmgr.get_obj_name(p_obj_id,p_class_id);
exception when others then
    if sqlcode in (-6508,-4061) then raise; end if;
    return null;
end;
---------------------------------------------------------------
function qual2names(aclass_id in varchar2, aqual in varchar2) return varchar2 as
res varchar2(30000);
tmp varchar2(1000);
cls varchar2(16) := aclass_id;
nm  varchar2(2000);
i pls_integer;
j pls_integer;
begin
    i := 0;
    loop
        j := instr(aqual,'.',i + 1);
        if j > 0 then
            tmp := substr(aqual,i + 1,j - 1);
        else
            tmp := substr(aqual,i + 1);
        end if;
        select name,self_class_id into nm,cls from class_attributes
        where class_id = cls and attr_id = tmp;
        if res is not null then res := res || '.'; end if;
        res := res || nm;
        exit when j = 0;
        i := j;
    end loop;
    return res;
exception
    when others then return aqual;
end qual2names;
--
function Check_Error_Message(p_message in out nocopy varchar2) return varchar2 is
    v_code  varchar2(10);
    v_cons  varchar2(100);
    v_tbl   varchar2(30);
    v_own   varchar2(30);
    v_col   varchar2(30);
    v_qual  varchar2(700);
    v_names varchar2(30000);
    v_cls   varchar2(128);
    v_cur   "CONSTANT".REPORT_CURSOR;
    i   pls_integer;
    j   pls_integer;
    l   pls_integer;
    b   boolean;
begin
    v_code := substr(p_message,1,10);
    if p_message is null or v_code not in ('ORA-00001:','ORA-02290:','ORA-02291:','ORA-02292:') then
        return '0';
    end if;
    i := instr(p_message,'(');
    if i=0 then return '0'; end if;
    j := instr(p_message,'.',i);
    if j=0 then return '0'; end if;
    v_own := substr(p_message,i+1,j-i-1);
    l := length(v_own)+2;
    j := instr(p_message,')',j);
    if j<=i+l then return '0'; end if;
    v_cons := substr(p_message,i+l,j-i-l);
    v_code := substr(v_code,5,5);
    b := v_code='00001';
    begin
      select table_name into v_tbl from dba_constraints
       where owner=v_own and constraint_name=v_cons;
    exception when others then
      if b then
        begin
          select table_name, table_owner into v_tbl, v_own from dba_indexes
           where owner=v_own and index_name=v_cons;
        exception when others then
          return '0';
        end;
      else
        return '0';
      end if;
    end;
    v_cls := storage_mgr.table2class(v_tbl);
    if v_cls is null then
      v_cls := v_tbl;
      if b then
        v_names := part_mgr.get_ind_cols(v_cons,v_tbl,v_own);
      else
        for c in (
          select column_name from dba_cons_columns
           where owner=v_own and table_name=v_tbl and constraint_name=v_cons
           order by position
        ) loop
          v_names := v_names||','||c.column_name;
        end loop;
      end if;
    else
      if b then
        open v_cur for
          select ui.column_name,ct.qual
            from class_tab_columns ct, dba_ind_columns ui
           where ct.class_id(+)=v_cls and ct.column_name(+)=ui.column_name
             and ui.index_name=v_cons and ui.table_name=v_tbl and ui.table_owner=v_own
           order by ui.column_position;
      else
        open v_cur for
          select uc.column_name,ct.qual
            from class_tab_columns ct, dba_cons_columns uc
           where ct.class_id(+)=v_cls and ct.column_name(+)=uc.column_name
             and uc.constraint_name=v_cons and uc.table_name=v_tbl and uc.owner=v_own
           order by uc.position;
      end if;
      loop
        fetch v_cur into v_col,v_qual;
        exit when v_cur%notfound;
        if v_qual is null then
          v_names := v_names||','||v_col;
        else
          v_names := v_names||','||nvl(types.qual_name(v_cls,v_qual,'.'),v_col);
        end if;
      end loop;
      close v_cur;
    end if;
    p_message := message.get_text('ORA',v_code,v_cls,substr(v_names,2))||chr(10)||p_message;
    return '1';
end;
---------------------------------------------------------------
-- Select-ы из системных таблиц
---------------------------------------------------------------
procedure Select_Cursor(CURSOR_NAME IN varchar2, P_CURSOR IN OUT nocopy constant.REPORT_CURSOR) is
    usr varchar2(100):= rtl.Usr;
begin
    if CURSOR_NAME = 'ADDRESS_RIGHTS' then
        OPEN P_CURSOR FOR SELECT
        ADDRESS, DESCRIPTION
        FROM ADDRESS_RIGHTS
        WHERE UserName = Usr;
/*
    elsif CURSOR_NAME = 'ADDRESS_RIGHTS_LIST' then
        OPEN P_CURSOR FOR SELECT
        DISTINCT ADDRESS, DESCRIPTION
        FROM ADDRESS_RIGHTS ORDER BY DESCRIPTION DESC, ADDRESS;
    elsif CURSOR_NAME = 'ADDRESS_RIGHTS_ALL' then
        OPEN P_CURSOR FOR SELECT
        *
        FROM ADDRESS_RIGHTS
        ORDER BY USERNAME;
 */
    else
        null;
    end if;
end Select_Cursor;
--
procedure Select_History(p_obj_id    varchar2,
                         p_class_id  varchar2,
                         p_qual      varchar2,
                         p_like_qual varchar2,
                         p_cursor in out nocopy constant.report_cursor) is
  v_tbl lib.table_info_t;
begin
  if p_class_id is null then
    open p_cursor for
      select h.user_id, to_char(h.time,'DD/MM/YYYY HH24:MI:SS') time, u.name, h.value
        from values_history h , users u
       where h.obj_id=p_obj_id
         and (h.qual=p_qual or h.qual like p_like_qual)
         and u.username(+) = nvl(substr(h.user_id,1,instr(h.user_id,'.')-1),h.user_id)
       order by h.time;
  elsif lib.table_exist(p_class_id,v_tbl,true) and v_tbl.log_table is not null then
    open p_cursor for
'select h.username user_id, to_char(h.time,''DD/MM/YYYY HH24:MI:SS'') time, u.name, h.value
  from '||v_tbl.log_table||' h , users u
 where h.id=:obj_id
   and (h.qual=:qual or h.qual like :like_qual)
   and u.username(+) = h.username
 order by h.time'
    using p_obj_id,p_qual,p_like_qual;
  else
    message.err(-20999,constant.CLASS_ERROR,'NO_ARCHIVING',p_class_id);
  end if;
end;
---------------------------------------------------------------
-- Доступ к адресу
---------------------------------------------------------------
FUNCTION Address_Accessible (
    Address_ IN VARCHAR2,
    UserName_ IN VARCHAR2) RETURN CHAR IS
  Result CHAR(1);
BEGIN
 IF UserName_ in (Inst_Info.Owner,Inst_Info.GOwner)  THEN
    RETURN '1';
 END IF;
 BEGIN
   SELECT --+ first_rows ordered
          '1' INTO Result
     FROM Subj_Equal, Address_Rights
    WHERE UserName=Equal_Id and Subj_Id=UserName_ and rownum=1
      AND (Address=Address_ OR Address='000000000000');
   RETURN '1';
 EXCEPTION
   WHEN NO_DATA_FOUND THEN
   NULL;
 END;
 RETURN '0';
END Address_Accessible;
---------------------------------------------------------------
-- Возвращает тип которому принадлежит объект
---------------------------------------------------------------
FUNCTION Object_Class (p_object_id IN varchar2,
    p_class varchar2) RETURN VarChar2 IS
v_class varchar2(16);
BEGIN
  v_class:= Rtl.object_class (p_object_id, p_class);
  if v_class is null and lib.has_partitions(p_class)<>'0' then
    v_class:= Rtl.object_class (p_object_id, p_class, -1);
  end if;
  RETURN v_class;
END Object_Class;
---------------------------------------------------------------
function get_class ( p_object_id in out nocopy varchar2,
                     p_class varchar2 default NULL,
                     p_info  varchar2 default NULL
                   ) return varchar2 is
begin
    return rtl.get_class (p_object_id,p_class,p_info);
end;
function get_key  ( p_object_id IN varchar2,
                    p_class varchar2 default NULL
                  ) return varchar2 is
begin
    return rtl.get_key (p_object_id,p_class);
end;
procedure get_class_key ( p_object_id IN varchar2,
                          p_class in out varchar2,
                          p_key out number
                        ) is
v_class varchar2(16);
begin
  v_class:= Rtl.object_class (p_object_id, p_class);
  if lib.has_partitions(nvl(v_class,p_class)) <> '0' then
    if v_class is null then
      v_class:= Rtl.object_class (p_object_id, p_class, -1);
    end if;
    if v_class is not null then
      begin
        p_key:= rtl.get_key (p_object_id,v_class);
      exception when others then
        if sqlcode<>-20999 then
          raise;
        end if;
      end;
    end if;
  end if;
  p_class:= v_class;
end;
---------------------------------------------------------------
function needs_collection_id(class_id_ varchar2,p_self varchar2 default '1') return varchar2 is
begin
  if lib.has_collection_id(class_id_,p_self='1') then
    return '1';
  end if;
  return '0';
end;
---------------------------------------------------------------
-- Чтение клиент-скрипта из SOURCES
---------------------------------------------------------------
function get_client_script ( p_method IN varchar2 ) return varchar2 is
begin
    return method.get_source(p_method,'VBSCRIPT');
end;
---------------------------------------------------------------
function get_client_script ( p_class IN varchar2, p_short_name varchar2) return varchar2 is
begin
  return get_client_script(get_method_id(p_class,p_short_name));
end;
---------------------------------------------------------------
-- Проверка интерфейсного пакета операции
---------------------------------------------------------------
function check_method_interface( p_method IN varchar2 ) return varchar2 is
begin
    return method_mgr.check_method_interface(p_method);
end;
---------------------------------------------------------------
-- Получение ID операции для выполняемого интерфейсного пакета
---------------------------------------------------------------
function current_form_method_id return varchar2 is
s varchar2(32767);
n number;
m_id varchar2(100) := null;
begin
  s := utils.call_stack;
  n := instr(s, 'Z$U$', 1);
  if n <> 0 then
    s:= substr(s, n+4);
    n:= instr(s, chr(10));
    if n<>0 then
      s:= substr(s, 1, n-1);
      begin
        m_id:= s;
      exception when others then null;
      end;
    end if;
  end if;
  return m_id;
end;
---------------------------------------------------------------
-- Получение ID операции по CLASS_ID, SHORT_NAME c учетом наследования
---------------------------------------------------------------
function get_method_id(p_class varchar2, p_short_name varchar2) return varchar2 is
v_meth_id varchar2(100);
begin
  for m in (select  m.ID
        from METHODS m, CLASS_RELATIONS CR
        where m.SHORT_NAME = p_short_name and m.CLASS_ID = CR.PARENT_ID and CR.CHILD_ID = p_class
      order by CR.DISTANCE
    )
  loop
    v_meth_id:= m.id;
    exit;
  end loop;
  return v_meth_id;
end;
---------------------------------------------------------------
-- Установка полей module и action в v$session
---------------------------------------------------------------
procedure SetModule (p_module IN varchar2, p_action varchar2) IS
BEGIN
    dbms_application_info.set_module(p_module,to_char(rtl.getdate,'HH24:MI:')||p_action);
    dbms_session.clear_identifier;
END;
---------------------------------------------------------------
-- Чтение-установка properties
---------------------------------------------------------------
function extract_property(p_string   in varchar2,
                          p_property in varchar2 default NULL
                         ) return varchar2 is
begin
    return method.extract_property(p_string,p_property);
end;
procedure put_property(p_string in out nocopy varchar2,
                       p_property  in varchar2 default null,
                       p_value  in varchar2 default null) is
begin
    method.put_property(p_string,p_property,p_value);
end;
---------------------------------------------------------------
procedure Check_Report_Rights(p_username varchar2) IS
begin
  report_mgr.Check_Report_Rights(p_username);
end;
---------------------------------------------------------------
procedure Check_Report_User(p_username  in out nocopy varchar2,
                            p_os_user   varchar2, p_os_domain varchar2) is
begin
  report_mgr.Check_Report_User(p_username,p_os_user, p_os_domain);
end;
---------------------------------------------------------------
-- Создание задания для сервера отчетов. Отчеты Навигатора
---------------------------------------------------------------
procedure Create_Report(p_job in out nocopy number, p_pos in out nocopy number,
                        p_username varchar2, p_os_user   varchar2, p_os_domain varchar2,
                        p_class_id varchar2, p_method_id varchar2, p_params    varchar2,
                        p_rpt_name varchar2, p_out_name  varchar2, p_props     varchar2,
                        p_rpt_drv  varchar2, p_trace_opt varchar2, p_schedule  date,
                        p_priority number ) is
begin
  report_mgr.Create_Report(p_job, p_pos, p_username, p_os_user, p_os_domain, p_class_id,
                           p_method_id, p_params, p_rpt_name, p_out_name, p_props,
                           p_rpt_drv, p_trace_opt, p_schedule, p_priority);
end;
---------------------------------------------------------------
-- Создание задания для сервера отчетов. Отчеты Администратора доступа
---------------------------------------------------------------
procedure Create_Report_UAdmin(p_job       in out nocopy number
                              ,p_username  varchar2
                              ,p_params    varchar2
                              ,p_rpt_name  varchar2
                              ,p_out_name  varchar2
                              ,p_props     varchar2
                              ,p_rpt_drv   varchar2
                              ,p_trace_opt varchar2
                              ,p_schedule  date
                              ,p_priority  number)
is
  vPos number;
begin
    report_mgr.Create_Report(p_job
                            ,vPos
                            ,p_username
                            ,null
                            ,null
                            ,null
                            ,null
                            ,p_params
                            ,p_rpt_name
                            ,p_out_name
                            ,p_props
                            ,p_rpt_drv
                            ,p_trace_opt
                            ,p_schedule
                            ,p_priority
                            ,p_rpt_type => report_mgr.REPORT_UADMIN);
end;
---------------------------------------------------------------
-- Создание задания для сервера отчетов. Отчеты Администратора ИСПДН
---------------------------------------------------------------
procedure Create_Report_PDAdmin(p_job       in out nocopy number
                               ,p_username  varchar2
                               ,p_params    varchar2
                               ,p_rpt_name  varchar2
                               ,p_out_name  varchar2
                               ,p_props     varchar2
                               ,p_rpt_drv   varchar2
                               ,p_trace_opt varchar2
                               ,p_schedule  date
                               ,p_priority  number)
is
  vPos number;
begin
    report_mgr.Create_Report(p_job
                            ,vPos
                            ,p_username
                            ,null
                            ,null
                            ,null
                            ,null
                            ,p_params
                            ,p_rpt_name
                            ,p_out_name
                            ,p_props
                            ,p_rpt_drv
                            ,p_trace_opt
                            ,p_schedule
                            ,p_priority
                            ,p_rpt_type => report_mgr.REPORT_PDADMIN);
end;
---------------------------------------------------------------
-- Блокировка задания сервера отчетов
---------------------------------------------------------------
function Lock_Report(p_username varchar2, p_job number, p_pos number) return number is
begin
  return report_mgr.Lock_Report(p_username, p_job, p_pos);
end;
---------------------------------------------------------------
-- Удаление задания сервера отчетов
---------------------------------------------------------------
procedure Delete_Report(p_username varchar2, p_job number, p_pos number) is
begin
  report_mgr.Delete_Report(p_username, p_job, p_pos);
end;
---------------------------------------------------------------
-- Перезапуск задания сервера отчетов
---------------------------------------------------------------
procedure Rerun_Report(p_username varchar2, p_job number, p_pos number) is
begin
  report_mgr.Rerun_Report(p_username, p_job, p_pos);
end;
---------------------------------------------------------------
-- Отмена задания сервера отчетов
---------------------------------------------------------------
procedure Cancel_Report(p_username varchar2, p_job number, p_pos number) is
begin
  report_mgr.Cancel_Report(p_username, p_job, p_pos);
end;
--
procedure network_register_node(p_nodeType pls_integer, p_name varchar2, p_ip varchar2,
                                p_osUser   varchar2, p_module varchar2 default null) is
  regCode   varchar2(20);
begin
  if p_nodeType = NODE_TYPE_CLIENT then
    regCode := 'REG_CLIENT';
  elsif p_nodeType = NODE_TYPE_AS then
    regCode := 'REG_APPSRV';
  elsif p_nodeType = NODE_TYPE_TS then
    regCode := 'REG_TERMSRV';
  end if;
  rtl.write_log('I',p_name||'-'||p_ip||' ('||rtl.usr||' - '||p_osUser||' - '||User||')',
                null,regCode,p_module);
end;
-----------------------------------------------------
function change_state_request (
                         p_object_id   varchar2,
                         p_new_state   varchar2,
                         p_method_name varchar2,
                         p_class_id    varchar2,
                         p_obj_locks   varchar2,
                         p_info        varchar2
                        ) return varchar2 is
  v_cls varchar2(16);
  v_obj varchar2(128);
  v_req varchar2(32000);
  v_pck varchar2(30);
begin
  if SecAdmin.IsRevisor then
    message.err(-20999,constant.EXEC_ERROR,'READ_ONLY');
  end if;
  if p_object_id is null then
    return rtl.request_lock(p_obj_locks,p_class_id,p_info);
  end if;
  v_obj := p_object_id;
  v_cls := rtl.get_class(v_obj,p_class_id,'CHANGE_STATE_REQUEST');
  v_pck := class_mgr.interface_package(v_cls);
  if p_obj_locks is null then
    execute immediate 'BEGIN '||v_pck||'.CHECK_LOCK(:OBJ_ID,:CLASS); '||
        v_pck||'.CHANGE_STATE(:OBJ_ID,:STATE,:METH,:CLASS,TRUE); END;'
        using v_obj,v_cls,p_new_state,nvl(p_method_name,'<NULL>');
    return null;
  end if;
  if p_obj_locks=v_obj then
    execute immediate 'BEGIN :REQ:='||v_pck||'.REQUEST_LOCK(:OBJ_ID,:CLASS,:INFO); IF :REQ IS NULL THEN '||
        v_pck||'.CHANGE_STATE(:OBJ_ID,:STATE,:METH,:CLASS,TRUE); END IF; END;'
        using in out v_req,v_obj,v_cls,p_info,p_new_state,nvl(p_method_name,'<NULL>');
    return v_req;
  end if;
  v_req := trim(',' from p_obj_locks);
  if v_obj='<CHANGE_STATE>' then
    execute immediate
'DECLARE O "CONSTANT".REFSTRING_TABLE;
BEGIN LIB.SET_REFS_LIST(:REQ,O);
  FOR I IN 1..O.COUNT LOOP
    '||v_pck||'.CHECK_LOCK(O(I),:CLASS);
    '||v_pck||'.CHANGE_STATE(O(I),:STATE,:METH,:CLASS,TRUE);
  END LOOP;
END;'
      using v_req,v_cls,p_new_state,nvl(p_method_name,'<NULL>');
    return null;
  end if;
  if instr(','||v_req||',',','||v_obj||',')=0 then
    v_req := v_obj||','||v_req;
  end if;
  execute immediate
'DECLARE O "CONSTANT".REFSTRING_TABLE; S VARCHAR2(1000);
BEGIN LIB.SET_REFS_LIST(:REQ,O);
  FOR I IN 1..O.COUNT LOOP
    S := '||v_pck||'.REQUEST_LOCK(O(I),:CLASS,:INFO);
    EXIT WHEN S IS NOT NULL;
  END LOOP;
  IF S IS NULL THEN
    FOR I IN 1..O.COUNT LOOP
      '||v_pck||'.CHANGE_STATE(O(I),:STATE,:METH,:CLASS,TRUE);
    END LOOP;
  END IF;
  :REQ := S;
END;'
    using in out v_req,v_cls,p_info,p_new_state,nvl(p_method_name,'<NULL>');
  return v_req;
end;
------------------------------------------------------
procedure write_action(p_meth varchar2, p_action varchar2, p_param1 varchar2, p_value1 varchar2,
p_param2 varchar2 default null, p_value2 varchar2 default null,
p_param3 varchar2 default null, p_value3 varchar2 default null,
p_param4 varchar2 default null, p_value4 varchar2 default null,
p_param5 varchar2 default null, p_value5 varchar2 default null) is
begin
    sc_mgr.write_log(p_meth, p_action, nvl(p_param1,p_action), p_value1,
                     p_param2, p_value2, p_param3, p_value3,
                     p_param4, p_value4, p_param5, p_value5);
end;
-----------------------------------------------------
END NAV;
/
sho err package body nav
