PROMPT  Package body SHORT_VIEWS
CREATE OR REPLACE Package Body
/*
 *	$HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/short2.sql $
 *	$Author: timur $
 *  $Revision: 16810 $
 *	$Date:: 2012-09-19 11:05:00 #$
 */
SHORT_VIEWS is
--
cid INTEGER; -- Id Dynamic SQL курсора
--
MSG_ACCOUNT constant varchar2(4) := 'Счет';
MSG_ADMIN constant varchar2(13) := 'Администратор';
MSG_BANK_PRODUCTS constant varchar2(19) := 'Банковские продукты';
MSG_CRITERIA constant varchar2(13) := 'Представления';
MSG_DATE constant varchar2(4) := 'Дата';
MSG_DOCUMENT constant varchar2(8) := 'Документ';
MSG_DOCUMENTS constant varchar2(9) := 'Документы';
MSG_FIN_ACCOUNTS constant varchar2(16) := 'Финансовые счета';
MSG_FIN_TOOLS constant varchar2(22) := 'Финансовые инструменты';
MSG_GROUPS constant varchar2(6) := 'Группы';
MSG_HAS_NO_GROUP constant varchar2(46) := 'Пользователь, не принадлежит ни к одной группе';
MSG_HAS_NO_USERS constant varchar2(22) := 'Не имеет пользователей';
MSG_METHODS constant varchar2(8) := 'Операции';
MSG_NAME constant varchar2(12) := 'Наименование';
MSG_NAV constant varchar2(8) := 'Оператор';
MSG_NAV_LOCKED constant varchar2(25) := 'Оператор БЛОКИРОВАН!!!';
MSG_PICKER constant varchar2(45) := 'Администратор проектов (Импорт/экспорт типов)';
MSG_PROCEDURES constant varchar2(9) := 'Процедуры';
MSG_PRODUCT constant varchar2(7) := 'Продукт';
MSG_REPORT_CRITERIA constant varchar2(25) := 'Представления для отчетов';
MSG_TOOL constant varchar2(10) := 'Инструмент';
MSG_TRANSITIONS constant varchar2(8) := 'Переходы';
MSG_UADMIN constant varchar2(21) := 'Администратор доступа';
MSG_UPICKER constant varchar2(44) := 'Администратор проектов (Импорт/экспорт прав)';
MSG_USERS constant varchar2(12) := 'Пользователи';
MSG_DEPARTS constant varchar2(15) := 'Подразделения';
MSG_PDADMIN constant varchar2(33) := 'Администратор персональных данных';
MSG_REVISOR constant varchar2(7) := 'Ревизор';
MSG_INIT_SESSION constant varchar2(40) := 'Сервер приложений (Инициализация сессий)';
MSG_OPEN_SESSION constant varchar2(35) := 'Сервер приложений (Создание сессий)';
MSG_2L_CONNECTION constant varchar2(13) := '2L соединение';
MSG_3L_CONNECTION constant varchar2(13) := '3L соединение';
MSG_2L3L_CONNECTION constant varchar2(18) := '2L и 3L соединение';
MSG_SYSUSER constant varchar2(39) := 'без доступа в Навигатор по всем каналам';
MSG_SYSUSER_2L constant varchar2(36) := 'без доступа в Навигатор по 2L каналу';
MSG_SYSUSER_3L constant varchar2(36) := 'без доступа в Навигатор по 3L каналу';
---------------------------------------------------------------------
-- Создание view для списка фин.счетов
PROCEDURE Create_Vw_Ac_Fin is
BEGIN
  cid := Dbms_Sql.Open_Cursor;
  Dbms_Sql.Parse(cid,'CREATE OR REPLACE VIEW Vw_Sht_Ac_Fin
		(  "ID",  "'||MSG_ACCOUNT||'", "'||MSG_NAME||'")
		AS (
		select a1.id, a1.c_main_v_id, a2.c_name from z#ac_fin A1, z#account A2
		where a1.id=a2.id )',
	Dbms_Sql.V7);
  Dbms_Sql.Parse(cid,'GRANT SELECT ON Vw_Sht_Ac_Fin TO ' || Inst_Info.Owner || '_UADMIN',Dbms_Sql.V7);
  Dbms_Sql.Close_Cursor(cid);
Exception when others then
  dbms_output.put_line(substr('Create_Vw_Ac_Fin: '||sqlerrm,1,255));
  if Dbms_Sql.Is_Open(cid) then Dbms_Sql.Close_Cursor(cid); end if;
END Create_Vw_Ac_Fin;
-- Финансовые инструменты по названию
PROCEDURE Create_Vw_Fintool is
BEGIN
  Dbms_Sql.Parse(cid,'CREATE OR REPLACE VIEW Vw_Sht_Fintool
		("ID",  "'||MSG_TOOL||'", "'||MSG_NAME||'")	AS (
  	SELECT Z1.Id, Z1.C_Name, Z1.C_Name FROM Z#FINTOOL Z1)',
	Dbms_Sql.V7);
	dbms_Sql.Parse(cid,'GRANT SELECT ON Vw_Sht_Fintool TO ' || Inst_Info.Owner || '_UADMIN',Dbms_Sql.V7);
Exception when others then
  dbms_output.put_line(substr('Create_Vw_Fintool: '||sqlerrm,1,255));
END Create_Vw_Fintool;
--Документы по номеру документа
PROCEDURE Create_Vw_Document is
  tbl   varchar2(200);
  whr   varchar2(200);
  procedure get_tbl(cls varchar2, prf varchar2) is
    t varchar2(100);
    w varchar2(100);
    g varchar2(30);
  begin
    begin
      select table_name, param_group into t, g from class_tables where class_id=cls;
    exception when no_data_found then
      t := 'Z#'||cls;
    end;
    if g='PARTITION' then
      t := t||' PARTITION('||t||'#0)';
      w := prf||'KEY=1000';
    end if;
    if tbl is not null then
      tbl := tbl||', ';
    end if;
    tbl := tbl||t||' '||replace(prf,'.');
    if w is not null then
      if whr is null then
        whr := ' WHERE ';
      else
        whr := whr||' AND ';
      end if;
      whr := whr||w;
    end if;
  end;
BEGIN
  get_tbl('DOCUMENT',null);
  Dbms_Sql.Parse(cid,'CREATE OR REPLACE VIEW Vw_Sht_Document
		("ID",  "'||MSG_DOCUMENT||'", "'||MSG_DATE||'") AS
		SELECT Id, TO_CHAR(C_DOCUMENT_NUM), TO_CHAR(C_DOCUMENT_DATE) FROM '||tbl||whr,
	Dbms_Sql.V7);
	dbms_Sql.Parse(cid,'GRANT SELECT ON Vw_Sht_Document TO ' || Inst_Info.Owner || '_UADMIN',Dbms_Sql.V7);
  tbl := null; whr := ' WHERE Z1.ID=Z2.ID';
  get_tbl('DOCUMENT','Z1.'); get_tbl('MAIN_DOCUM','Z2.');
  Dbms_Sql.Parse(cid,'CREATE OR REPLACE VIEW Vw_Sht_Main_Docum
		("ID", "'||MSG_DOCUMENT||'",  "'||MSG_DATE||'") AS
		SELECT Z1.Id, TO_CHAR(Z1.C_DOCUMENT_NUM), TO_CHAR(Z1.C_DOCUMENT_DATE)
		FROM '||tbl||whr,
	Dbms_Sql.V7);
	dbms_Sql.Parse(cid,'GRANT SELECT ON Vw_Sht_Main_Docum TO ' || Inst_Info.Owner || '_UADMIN',Dbms_Sql.V7);
  tbl := null; whr := ' WHERE Z1.ID=Z2.ID';
  get_tbl('DOCUMENT','Z1.'); get_tbl('SPRAV_0406007','Z2.');
  Dbms_Sql.Parse(cid,'CREATE OR REPLACE VIEW Vw_Sht_Sprav_0406007
		("ID", "'||MSG_DOCUMENT||'",  "'||MSG_DATE||'") AS
		SELECT Z1.Id, TO_CHAR(Z1.C_DOCUMENT_NUM), TO_CHAR(Z1.C_DOCUMENT_DATE)
		FROM '||tbl||whr,
	Dbms_Sql.V7);
	dbms_Sql.Parse(cid,'GRANT SELECT ON Vw_Sht_Sprav_0406007 TO ' || Inst_Info.Owner || '_UADMIN',Dbms_Sql.V7);
Exception when others then
  dbms_output.put_line(substr('Create_Vw_Document: '||sqlerrm,1,255));
END Create_Vw_Document;
--Банковские продукты
PROCEDURE Create_Vw_Product is
BEGIN
  Dbms_Sql.Parse(cid,'CREATE OR REPLACE VIEW Vw_Sht_Product
		("ID",  "'||MSG_PRODUCT||'", "'||MSG_NAME||'") AS (
  	SELECT Z1.Id, Z1.C_NUM_DOG Object, TO_CHAR(Z1.C_DATE_BEGIN)	FROM Z#PRODUCT Z1 )',
	Dbms_Sql.V7);
	dbms_Sql.Parse(cid,'GRANT SELECT ON Vw_Sht_Product TO ' || Inst_Info.Owner || '_UADMIN',Dbms_Sql.V7);
Exception when others then
  dbms_output.put_line(substr('Create_Vw_Product: '||sqlerrm,1,255));
END Create_Vw_Product;
---------------------------------------------------------------------
-- Создание view Group_Users
Procedure Create_Vw_Group_Users Is
Begin
dbms_Sql.Parse(cid,' CREATE OR REPLACE VIEW Group_Users  AS
    --Группы содержащие пользователей для отчета СПИСОК ГРУПП
    SELECT DISTINCT  G.UserName Subj_ID, G.Name GroupName, G.Description GroupDesc, U.name UserName, '''||MSG_USERS||''' Type
		FROM Users U, Users G, Subj_Equal GM
		WHERE U.UserName = GM.Subj_Id AND G.UserName = GM.Equal_Id
		    AND GM.Subj_Id=GM.Owner_Id AND GM.Subj_Id <> GM.Equal_Id
            AND G.type = ''G'' and nvl(instr(U.properties, ''|KERNEL''), 0) = 0
    --Группы, не имеющие пользователей для отчета СПИСОК ГРУПП
    UNION SELECT DISTINCT G.UserName Subj_ID, G.Name GroupName, G.Description GroupDesc, '''||MSG_HAS_NO_USERS||''' UserName, '''||MSG_USERS||''' Type
		FROM Users G
		WHERE G.UserName NOT IN (
                select se2.Equal_Id FROM Subj_Equal se2, Users U2
                    WHERE se2.Subj_Id=se2.Owner_Id AND se2.Subj_Id <> se2.Equal_Id
                        and se2.Subj_Id = U2.username and nvl(instr(U2.properties, ''|KERNEL''), 0) = 0
            ) AND G.Type = ''G''
    --Пользователи члены групп для отчета СПИСОК ПОЛЬЗОВАТЕЛЕЙ
    UNION SELECT DISTINCT U.UserName Subj_ID, G.Name GroupName, G.Description GroupDesc, U.Name UserName, '''||MSG_GROUPS||''' Type
		FROM Users U, Users G, Subj_Equal GM
		WHERE U.UserName = GM.Subj_Id AND G.UserName = GM.Equal_Id
		    AND GM.Subj_Id=GM.Owner_Id AND GM.Subj_Id <> GM.Equal_Id
		    AND U.Type = ''U'' and nvl(instr(G.properties, ''|KERNEL''), 0) = 0 -- ORDER BY Subj_Id
    --Пользователи, не состоящие в группах  для отчета СПИСОК ПОЛЬЗОВАТЕЛЕЙ
    UNION SELECT DISTINCT U.UserName Subj_ID, '''||MSG_HAS_NO_GROUP||''' GroupName, '''' GroupDesc, U.Name UserName, '''||MSG_GROUPS||''' Type
		FROM Users U
		WHERE U.UserName NOT IN (
                SELECT se2.Subj_Id FROM Subj_Equal se2, Users U2
                    WHERE se2.Subj_Id=se2.Owner_Id AND se2.Subj_Id <> se2.Equal_Id
                        and se2.Equal_Id = U2.username and nvl(instr(U2.properties, ''|KERNEL''), 0) = 0
            ) AND U.Type = ''U'''
  , Dbms_Sql.V7);
dbms_Sql.Parse(cid,'GRANT SELECT ON Group_Users TO ' || Inst_Info.Owner || '_UADMIN',Dbms_Sql.V7);
Exception when others then
  dbms_output.put_line(substr('Create_Vw_Group_Users: '||sqlerrm,1,255));
END Create_Vw_Group_Users;
---------------------------------------------------------------------
-- Создание view Object_Users
Procedure Create_Vw_Object_Users Is
Begin
dbms_Sql.Parse(cid,'CREATE OR REPLACE VIEW Object_Users AS
SELECT E.Subj_Id, C.Name Class, '' '' Object, null OBJECT_ID, r.obj_id CLASS_ID	--Список доступных классов
  FROM Subj_Equal E, Classes C, Class_Rights R, Users U
 WHERE E.Equal_Id=R.Subj_Id AND R.Obj_Id=C.Id
   AND E.Subj_Id=U.UserName AND nvl(instr(U.Properties,''|KERNEL''),0)=0
 UNION --Финансовые счета по номеру счета и названию
SELECT E.Subj_ID, '''||MSG_FIN_ACCOUNTS||''' Class, Z1.c_Main_v_Id || ''  '' || Z2.c_Name Object, r.obj_id OBJECT_ID, r.class_id
  FROM Subj_Equal E, Object_Rights R, Z#AC_FIN Z1, Z#ACCOUNT Z2, Users U
 WHERE E.Equal_Id=R.Subj_Id AND R.Obj_Id=to_char(Z1.Id) AND Z2.Id=Z1.Id AND R.Class_Id=''AC_FIN''
   AND E.Subj_Id=U.UserName AND nvl(instr(U.Properties,''|KERNEL''),0)=0
UNION --Подразделения по коду и названию
SELECT E.Subj_ID, '''||MSG_DEPARTS||''' Class, Z1.c_Code || ''  '' || Z1.c_Name Object, r.obj_id OBJECT_ID, r.class_id
  FROM Subj_Equal E, Object_Rights R, Z#DEPART Z1, Users U
 WHERE E.Equal_Id=R.Subj_Id AND R.Obj_Id=to_char(Z1.Id) AND R.Class_Id=''DEPART''
   AND E.Subj_Id=U.UserName AND nvl(instr(U.Properties,''|KERNEL''),0)=0'
/*
	--Финансовые инструменты по названию
	UNION SELECT DISTINCT E.Subj_ID, '''||MSG_FIN_TOOLS||''' Class, Z1.C_Name Object
		FROM Subj_Equal E, Object_Rights R, Z#FINTOOL Z1
		WHERE E.Equal_Id= R.Subj_Id AND R.Obj_Id = Z1.Id
	--Документы по номеру документа
	UNION SELECT DISTINCT E.Subj_ID, '''||MSG_DOCUMENTS||''' Class, TO_CHAR(Z1.C_DOCUMENT_NUM) Object
		FROM Subj_Equal E, Object_Rights R, Z#DOCUMENT Z1
		WHERE E.Equal_Id= R.Subj_Id AND R.Obj_Id = Z1.Id
	--Банковские продукты
	UNION SELECT DISTINCT E.Subj_ID, '''||MSG_BANK_PRODUCTS||''' Class, Z1.C_NUM_DOG Object
		FROM Subj_Equal E, Object_Rights R, Z#PRODUCT Z1
		WHERE E.Equal_Id= R.Subj_Id AND R.Obj_Id = Z1.Id
	--Процедуры
	UNION SELECT DISTINCT E.Subj_ID, '''||MSG_PROCEDURES||''' Class, Z1.NAME Object
		FROM Subj_Equal E, Procedure_Rights R, Procedures Z1
		WHERE E.Equal_Id= R.Subj_Id AND R.Obj_Id = Z1.Id
 */
    , Dbms_Sql.V7);
dbms_Sql.Parse(cid,'GRANT SELECT ON Object_Users  TO ' || Inst_Info.Owner || '_UADMIN',Dbms_Sql.V7);
dbms_Sql.Parse(cid,'GRANT SELECT ON Object_Users  TO ' || Inst_Info.Owner || '_USER',Dbms_Sql.V7);
Exception when others then
  dbms_output.put_line(substr('Create_Vw_Object_Users: '||sqlerrm,1,255));
End;
---------------------------------------------------------------------
-- Создание view для отчетов в Администраторе доступа
Procedure Create_Vw_Object_Cat_Users Is
Begin
dbms_Sql.Parse(cid,'CREATE OR REPLACE VIEW Object_Categoria_Users AS
SELECT E.Subj_ID, '''||MSG_FIN_ACCOUNTS||''' Class, ''(''||G.Id||'') ''||G.Description Category, Z1.c_Main_v_Id || ''  '' || Z2.c_Name Object, r.obj_id OBJECT_ID, r.class_id --Финансовые счета по номеру счета и названию
  FROM Subj_Equal E, Object_Rights R, Z#AC_FIN Z1, Z#ACCOUNT Z2, Access_Groups G, Users U
 WHERE E.Equal_Id=R.Subj_Id AND R.Obj_Id=to_char(Z1.Id) AND Z2.Id=Z1.Id AND instr(R.Access_Group,G.Id)>0 AND R.Class_Id=''AC_FIN''
   AND E.Subj_Id=U.UserName AND nvl(instr(U.Properties,''|KERNEL''),0)=0
 UNION
SELECT E.Subj_ID, '''||MSG_DEPARTS||''' Class, ''(''||G.Id||'') ''||G.Description Category, Z1.c_Code || ''  '' || Z1.c_Name Object, r.obj_id OBJECT_ID, r.class_id --Подразделения по коду и названию
  FROM Subj_Equal E, Object_Rights R, Z#DEPART Z1, Access_Groups G, Users U
 WHERE E.Equal_Id=R.Subj_Id AND R.Obj_Id=to_char(Z1.Id) AND instr(R.Access_Group,G.Id)>0 AND R.Class_Id=''DEPART''
   AND E.Subj_Id=U.UserName AND nvl(instr(U.Properties,''|KERNEL''),0)=0'
/*
	--Финансовые инструменты по названию
  UNION SELECT DISTINCT E.Subj_ID, '''||MSG_FIN_TOOLS||''' Class, ''(''||G.Id||'') ''||G.Description Category, Z1.C_Name Object
		FROM Subj_Equal E, Object_Rights R, Z#FINTOOL Z1, Access_Groups G
		WHERE E.Equal_Id= R.Subj_Id AND R.Obj_Id = Z1.Id AND instr(R.Access_Group, G.Id)>0
	--Документы по номеру документа
  UNION SELECT DISTINCT E.Subj_ID, '''||MSG_DOCUMENTS||''' Class, ''(''||G.Id||'') ''||G.Description Category, TO_CHAR(Z1.C_DOCUMENT_NUM) Object
		FROM Subj_Equal E, Object_Rights R, Z#DOCUMENT Z1, Access_Groups G
		WHERE E.Equal_Id= R.Subj_Id AND R.Obj_Id = Z1.Id AND instr(R.Access_Group, G.Id)>0
	--Банковские продукты
  UNION SELECT DISTINCT E.Subj_ID, '''||MSG_BANK_PRODUCTS||''' Class, ''(''||G.Id||'') ''||G.Description Category, Z1.C_NUM_DOG Object
		FROM Subj_Equal E, Object_Rights R, Z#PRODUCT Z1, Access_Groups G
		WHERE E.Equal_Id= R.Subj_Id AND R.Obj_Id = Z1.Id AND instr(R.Access_Group, G.Id)>0
 */
  , Dbms_Sql.V7);
dbms_sql.Parse(cid,'GRANT SELECT ON Object_Categoria_Users TO ' || Inst_Info.Owner || '_UADMIN',Dbms_Sql.V7);
dbms_sql.Parse(cid,'GRANT SELECT ON Object_Categoria_Users TO ' || Inst_Info.Owner || '_USER',Dbms_Sql.V7);
Exception when others then
  dbms_output.put_line(substr('Create_Vw_Object_Cat_Users: '||sqlerrm,1,255));
End;
---------------------------------------------------------------------
-- Создание view для отчетов в Администраторе доступа
Procedure Create_Vw_All_Rights_O Is
Begin
dbms_Sql.Parse(cid,' CREATE OR REPLACE VIEW All_Rights AS
    SELECT DISTINCT	E.Subj_Id, C.Name || '' ('' || C.Id || '')'' Class, '' '' Object, ''  '' Type
		FROM Classes C,	Class_Rights R, Subj_Equal E, Users U
		WHERE R.Subj_Id = E.Equal_Id AND C.Id = R.Obj_Id
            AND E.Subj_Id = U.UserName AND nvl(instr(U.Properties, ''|KERNEL''), 0) = 0
	union SELECT DISTINCT E.Subj_Id, C.Name Class, O.Name Object, '''||MSG_CRITERIA||''' Type
		FROM Classes C,	Criteria_Rights R, Criteria O, Subj_Equal E, Users U
		WHERE R.Subj_Id = E.Equal_Id AND O.Id = R.Obj_Id
    		AND	R.Class_Id = C.Id	AND	O.Flags = ''Z''
            AND E.Subj_Id = U.UserName AND nvl(instr(U.Properties, ''|KERNEL''), 0) = 0
	union SELECT DISTINCT E.Subj_Id, C.Name Class, O.Name Object, '''||MSG_TRANSITIONS||''' Type
		FROM Classes C,	Transition_Rights R, Transitions O, Subj_Equal E, Users U
		WHERE R.Subj_Id = E.Equal_Id AND O.Id = R.Obj_Id AND R.Class_Id = C.Id
            AND E.Subj_Id = U.UserName AND nvl(instr(U.Properties, ''|KERNEL''), 0) = 0
	union SELECT DISTINCT E.Subj_Id, C.Name Class, O.Name Object, '''||MSG_METHODS||''' Type
		FROM Classes C,	Method_Rights R, Methods O, Subj_Equal E, Users U
		WHERE R.Subj_Id = E.Equal_Id	AND	O.Id = R.Obj_Id
		    AND	R.Class_Id = C.Id AND O.Flags not in (''A'',''Z'')
            AND E.Subj_Id = U.UserName AND nvl(instr(U.Properties, ''|KERNEL''), 0) = 0'
    ,Dbms_Sql.V7);
dbms_sql.Parse(cid,'GRANT SELECT ON All_Rights  TO ' || Inst_Info.Owner || '_UADMIN',Dbms_Sql.V7);
dbms_sql.Parse(cid,'GRANT SELECT ON All_Rights  TO ' || Inst_Info.Owner || '_USER',Dbms_Sql.V7);
Exception when others then
  dbms_output.put_line(substr('Create_Vw_All_Rights_O: '||sqlerrm,1,255));
End Create_Vw_All_Rights_O;
--
Procedure Create_Vw_All_Rights Is
Begin
dbms_Sql.Parse(cid,' CREATE OR REPLACE VIEW VW_All_Rights AS
    SELECT E.Subj_Id, C.Name || '' ('' || C.Id || '')'' Class, '' '' Object, ''  '' Type,
           C.Id Class_Id, C.Id, ''1'' User_Driven, c.Entity_Id, c.Autonomous, 1 Accessibility
		FROM Classes C,	Class_Rights R,	Subj_Equal E, Users U
		WHERE	R.Subj_Id = E.Equal_Id AND C.Id = R.Obj_Id
          AND E.Subj_Id = U.UserName AND nvl(instr(U.Properties, ''|KERNEL''), 0) = 0
	union SELECT E.Subj_Id,	C.Name Class,	O.Name Object,	'''||MSG_CRITERIA||''' Type,
           O.Class_Id, O.Id, ''1'' User_Driven, c.Entity_Id, c.Autonomous, 1 Accessibility
		FROM Classes C,	Criteria_Rights R, Class_Relations CR, Criteria O, Subj_Equal E, Users U
		WHERE R.Subj_Id = E.Equal_Id   AND O.Id = R.Obj_Id
		  AND O.Class_Id= CR.Parent_Id AND C.Id = CR.Child_Id AND R.Class_Id = CR.Child_Id
          AND O.Flags = ''Z'' AND (CR.Distance = 0 OR O.Propagate = ''1'' )
          AND exists (select 1 from class_rights x where x.subj_id=e.equal_id and x.obj_id=c.id)
          AND E.Subj_Id = U.UserName AND nvl(instr(U.Properties, ''|KERNEL''), 0) = 0
	union SELECT E.Subj_Id,	C.Name Class,	O.Name Object,	'''||MSG_REPORT_CRITERIA||''' Type,
           O.Class_Id, O.Id, ''1'' User_Driven, c.Entity_Id, c.Autonomous, 1 Accessibility
		FROM Classes C,	Criteria_Rights R, Class_Relations CR, Criteria O, Subj_Equal E, Users U
		WHERE R.Subj_Id = E.Equal_Id   AND O.Id = R.Obj_Id
		  AND O.Class_Id= CR.Parent_Id AND C.Id = CR.Child_Id AND R.Class_Id = CR.Child_Id
          AND O.Flags = ''R'' AND (CR.Distance=0 OR O.Not_rights=''1'')
          AND exists (select 1 from class_rights x where x.subj_id=e.equal_id and x.obj_id=c.id)
          AND E.Subj_Id = U.UserName AND nvl(instr(U.Properties, ''|KERNEL''), 0) = 0
	union SELECT E.Subj_Id,	C.Name Class,	O.Name Object,	'''||MSG_TRANSITIONS||''' Type,
           O.Class_Id, O.Id, O.User_Driven, c.Entity_Id, c.Autonomous, 1 Accessibility
		FROM Classes C,	Transition_Rights R, Transitions O, Subj_Equal E, Users U
		WHERE R.Subj_Id = E.Equal_Id   AND O.Id = R.Obj_Id
          AND O.Class_Id= R.Class_Id   AND C.Id = R.Class_id
          AND exists (select 1 from class_rights x where x.subj_id=e.equal_id and x.obj_id=c.id)
          AND E.Subj_Id = U.UserName AND nvl(instr(U.Properties, ''|KERNEL''), 0) = 0
	union SELECT E.Subj_Id,	C.Name Class,	O.Name Object,	'''||MSG_METHODS||''' Type,
           O.Class_Id, O.Id, O.User_Driven, c.Entity_Id, c.Autonomous, O.Accessibility
		FROM Classes C,	Method_Rights R, Class_Relations CR, Methods O,	Subj_Equal E, Users U
		WHERE R.Subj_Id = E.Equal_Id   AND O.Id = R.Obj_Id    AND R.Class_Id = CR.Child_Id
		  AND O.Class_Id= CR.Parent_Id AND C.Id = CR.Child_Id AND O.Flags not in (''A'',''Z'')
          AND exists (select 1 from class_rights x where x.subj_id=e.equal_id and x.obj_id=c.id)
          AND E.Subj_Id = U.UserName AND nvl(instr(U.Properties, ''|KERNEL''), 0) = 0
	union SELECT E.Subj_Id,	C.Name Class,	O.Name Object,	'''||MSG_METHODS||''' Type,
           O.Class_Id, O.Id, O.User_Driven, c.Entity_Id, c.Autonomous, O.Accessibility
		FROM Classes C,	Class_Rights R, Class_Relations CR, Methods O,	Subj_Equal E, Users U
		WHERE R.Subj_Id = E.Equal_Id   AND C.Id = R.Obj_Id
		  AND O.Class_Id= CR.Parent_Id AND C.Id = CR.Child_Id
          AND O.Flags not in (''A'',''Z'') AND O.User_Driven=''1'' AND O.Accessibility=2
          AND E.Subj_Id = U.UserName AND nvl(instr(U.Properties, ''|KERNEL''), 0) = 0'
    ,Dbms_Sql.V7);
dbms_sql.Parse(cid,'GRANT SELECT ON VW_All_Rights  TO ' || Inst_Info.Owner || '_UADMIN',Dbms_Sql.V7);
dbms_sql.Parse(cid,'GRANT SELECT ON VW_All_Rights  TO ' || Inst_Info.Owner || '_USER',Dbms_Sql.V7);
Exception when others then
  dbms_output.put_line(substr('Create_Vw_All_Rights: '||sqlerrm,1,255));
End Create_Vw_All_Rights;
--
Procedure Create_Vw_All_Model Is
Begin
dbms_Sql.Parse(cid,' CREATE OR REPLACE VIEW All_Model AS
    SELECT C.Id Class_Id, C.Name Class, '' '' Object, '' '' Type, C.Has_Instances,
		''1'' User_Driven, c.Entity_Id, c.Autonomous, 1 Accessibility
		FROM Classes C
	union SELECT C.Id Class_Id, C.Name Class, O.Name Object, '''||MSG_CRITERIA||''' Type, C.Has_Instances,
		''1'' User_Driven, c.Entity_Id, c.Autonomous, 1 Accessibility
		FROM Classes C,	Criteria O
		WHERE	C.Id = O.Class_Id AND O.Flags = ''Z''
	union SELECT C.Id Class_Id, C.Name Class, O.Name Object, '''||MSG_TRANSITIONS||''' Type, C.Has_Instances,
		''1'' User_Driven, c.Entity_Id, c.Autonomous, 1 Accessibility
		FROM Classes C,	Transitions O
		WHERE C.Id = O.Class_Id
	union SELECT C.Id Class_Id, C.Name Class, O.Name Object, '''||MSG_METHODS||''' Type, C.Has_Instances,
		O.User_Driven, c.Entity_Id, c.Autonomous, O.Accessibility
		FROM Classes C,	Methods O
		WHERE C.Id = O.Class_Id AND O.Flags not in (''A'',''Z'')'
    ,Dbms_Sql.V7);
dbms_sql.Parse(cid,'GRANT SELECT ON All_Model  TO ' || Inst_Info.Owner || '_ADMIN',Dbms_Sql.V7);
dbms_sql.Parse(cid,'GRANT SELECT ON All_Model  TO ' || Inst_Info.Owner || '_UADMIN',Dbms_Sql.V7);
dbms_sql.Parse(cid,'GRANT SELECT ON All_Model  TO ' || Inst_Info.Owner || '_APPSRV',Dbms_Sql.V7);
Exception when others then
  dbms_output.put_line(substr('Create_Vw_All_Model: '||sqlerrm,1,255));
End Create_Vw_All_Model;
---------------------------------------------------------------------
-- Создание view для отчетов доступа "Права пользователя","Права группы","Объекты доступа"
Procedure Create_Vw_Nu Is
Begin
dbms_Sql.Parse(cid,' CREATE OR REPLACE VIEW Vw_Users
AS
SELECT UserName Id, U.* FROM Users U'
    ,Dbms_Sql.V7);
dbms_Sql.Parse(cid,' CREATE OR REPLACE VIEW Vw_NU_Users
(
Subj_Id,
Name_Id,
Type_Id,
Main_Id,
Main_Name,
Sub_Id,
Depart_Id,
Depart_Code,
Depart_Name
)
as
select U.UserName, U.Name, ''0_AWP'', Translate(Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(Properties,
    '' '',''''),
    ''|LOCK'','''||MSG_NAV_LOCKED||'; ''),
    ''|ADMIN'', '''||MSG_ADMIN||'; ''),
    ''|UADMIN'','''||MSG_UADMIN||'; ''),
    ''|PICKER'','''||MSG_PICKER||'; ''),
    ''|UPICKER'','''||MSG_UPICKER||'; ''),
    ''|PDADMIN'','''||MSG_PDADMIN||'; ''),
    ''|REVISOR'','''||MSG_REVISOR||'; ''),
    ''|INIT_SESSION'','''||MSG_INIT_SESSION||'; ''),
    ''|OPEN_SESSION'','''||MSG_OPEN_SESSION||'; ''),
    '';1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ_|'','';'') 
    || decode(instr(nvl(Properties,'';''), ''|LOCK''), 0, '''||MSG_NAV||'''
    || decode(instr(nvl(Properties,'';''), ''|2L_LOCK''), 0, decode(instr(Properties, ''|SESSION''), 0, '', '||MSG_2L_CONNECTION||''', '', '||MSG_2L3L_CONNECTION||'''), decode(instr(Properties, ''|SESSION''), 0, '''','', '||MSG_3L_CONNECTION||'''))
    || decode(instr(nvl(Properties,'';''), ''|SYSUSER 2L''), 0, decode(instr(Properties, ''|SYSUSER 3L''), 0, decode(instr(Properties, ''|SYSUSER''),0,'''','', '||MSG_SYSUSER||'''), ''''), '', '||MSG_SYSUSER_2L||''')
    || decode(instr(nvl(Properties,'';''), ''|SYSUSER 3L''), 0, '''', '', '||MSG_SYSUSER_3L||''')
    , '''')
    , '''', '''', zd.id, zd.c_code, zd.c_name
    from Users U, z#user zu, z#depart zd
    where Type = ''U'' and (Lock_Status is Null or Lock_Status <> ''DELETED'') and
        U.UserName = zu.c_username(+) and zu.c_depart=zd.id(+)
union
select distinct U.UserName, U.Name, ''1_NET'', AR.Address, '''', AR.Description, to_number(null), '''', ''''
    from Users U, Address_Rights AR
    where U.Type = ''U'' and (U.Lock_Status is Null or U.Lock_Status <> ''DELETED'') and
        AR.UserName in (select Equal_Id from Subj_Equal where Subj_Id = U.UserName)
union
select U.UserName, U.Name, ''2_GRP'', SE.Equal_Id, U2.Name, Decode(SE.Owner_Id,U.UserName,'''',SE.Owner_Id), to_number(null), '''', ''''
    from Users U, Subj_Equal SE, Users U2
    where U.Type = ''U'' and (U.Lock_Status is Null or U.Lock_Status <> ''DELETED'') and
        U.UserName = SE.Subj_Id and SE.Equal_Id in (
            select UserName from Users where Type = ''G'' and
                nvl(instr(Properties, ''|KERNEL''), 0) = 0
        ) and U2.UserName = SE.Equal_Id
union
select U.UserName, U.Name, ''3_USR'', SE.Equal_Id, U2.Name, Decode(SE.Owner_Id,Equal_Id,'''',SE.Owner_Id), to_number(null), '''', ''''
    from Users U, Subj_Equal SE, Users U2
    where U.Type = ''U'' and (U.Lock_Status is Null or U.Lock_Status <> ''DELETED'') and
        U.UserName = SE.Subj_Id and SE.Equal_Id in (
            select UserName from Users where Type = ''U'' and UserName <> U.UserName
        ) and U2.UserName = SE.Equal_Id'
    ,Dbms_Sql.V7);
dbms_Sql.Parse(cid,' CREATE OR REPLACE VIEW Vw_NU_User_Rights
(
Subj_Id,
Name_Id,
Owner,
Owner_Id,
Type_Id,
Class,
Class_Id,
Object,
Object_Id,
Object_UserDriven,
Object_Accessibility,
Prop
)
as
select U.UserName, U.Name, U2.Name, SE.Equal_Id, ''1_CRIT'', C.Name, C.Id, O.Name, O.Short_Name, ''1'' User_Driven, 1 Accessibility, ''''
    from Users U, Subj_Equal SE, Users U2, Classes C,	Criteria_Rights R, Criteria O
    where U.Type = ''U'' and (U.Lock_Status is Null or U.Lock_Status <> ''DELETED'')
        and U.UserName = SE.Subj_Id and
        R.Subj_Id = SE.Equal_Id and C.Id = O.Class_Id and O.Id = R.Obj_Id and
        U2.UserName = SE.Equal_Id
union
select U.UserName, U.Name, U2.Name, SE.Equal_Id, ''2_TRAN'', C.Name, C.Id, O.Name, O.Short_Name, O.User_Driven, 1 Accessibility, ''''
    from Users U, Subj_Equal SE, Users U2, Classes C,	Transition_Rights R, Transitions O
    where U.Type = ''U'' and (U.Lock_Status is Null or U.Lock_Status <> ''DELETED'')
        and U.UserName = SE.Subj_Id and
        R.Subj_Id = SE.Equal_Id and C.Id = O.Class_Id and O.Id = R.Obj_Id and
        U2.UserName = SE.Equal_Id
union
select U.UserName, U.Name, U2.Name, SE.Equal_Id, ''3_METH'', C.Name, C.Id, O.Name, O.Short_Name, O.User_Driven, O.Accessibility, ''''
    from Users U, Subj_Equal SE, Users U2, Classes C,	Method_Rights R, Methods O
    where U.Type = ''U'' and (U.Lock_Status is Null or U.Lock_Status <> ''DELETED'')
        and U.UserName = SE.Subj_Id and R.Subj_Id = SE.Equal_Id
        and C.Id = O.Class_Id and O.Id = R.Obj_Id and O.Flags<>''A''
        and U2.UserName = SE.Equal_Id
union
select U.UserName, U.Name, U2.Name, SE.Equal_Id, ''4_OBJS'', '''||MSG_FIN_ACCOUNTS||''', ''AC_FIN'', Z2.C_Name, Z1.C_Main_V_Id, ''1'' User_Driven, 1 Accessibility, '''' /*G.Description*/
    from Users U, Subj_Equal SE, Users U2, Object_Rights R, Z#AC_FIN Z1, Z#ACCOUNT Z2 /*, Access_Groups G*/
    where U.Type = ''U'' and (U.Lock_Status is Null or U.Lock_Status <> ''DELETED'')
        and U.UserName = SE.Subj_Id and
        R.Subj_Id = SE.Equal_Id and R.Obj_Id = to_char(Z1.Id)  and Z2.Id =Z1.Id /*and
        (Instr(R.Access_Group, G.Id)>0*/ and
        U2.UserName = SE.Equal_Id'
    ,Dbms_Sql.V7);
dbms_Sql.Parse(cid,' CREATE OR REPLACE VIEW Vw_NU_Groups
(
Subj_Id,
Name_Id,
Subj_Desc,
Type_Id,
Main_Id,
Main_Id_,
Main_Name,
Sub_Id,
Depart_Id,
Depart_Code,
Depart_Name
)
as
select U.UserName, U.Name, U.Description,''0_USR'', U1.Name || '' ('' || SE.Subj_Id || '')'', SE.Subj_Id, U1.Name, '''', zd.id, zd.c_code, zd.c_name
    from Users U, Subj_Equal SE, Users U1, z#user zu, z#depart zd
    where U.Type = ''G'' and
        nvl(instr(U.properties, ''|KERNEL''), 0) = 0 and
        U.UserName = SE.Equal_Id and SE.Subj_Id = SE.Owner_Id and
            SE.Subj_Id in (select UserName from Users where Type = ''U'') and
        SE.Subj_Id = U1.UserName and
        SE.Subj_Id = zu.c_username(+) and zu.c_depart=zd.id(+)
union
select U.UserName, U.Name, U.Description, ''1_JOIN'', U1.Name || '' ('' || SE.Subj_Id || '')'', SE.Subj_Id, U1.Name, SE.Owner_Id, to_number(null), '''', ''''
    from Users U, Subj_Equal SE, Users U1
    where U.Type = ''G'' and
        nvl(instr(U.properties, ''|KERNEL''), 0) = 0 and
        U.UserName = SE.Equal_Id and SE.Subj_Id <> SE.Owner_Id and
            SE.Subj_Id in (select UserName from Users where Type = ''U'') and
        SE.Subj_Id = U1.UserName
union
select U.UserName, U.Name, U.Description, ''2_RIGHTS'', '' '', '' '', '' '', '' '', to_number(null), '''', ''''
    from Users U
    where U.Type = ''G'' and nvl(instr(U.properties, ''|KERNEL''), 0) = 0'
    ,Dbms_Sql.V7);
dbms_Sql.Parse(cid,' CREATE OR REPLACE VIEW Vw_NU_Group_Rights
(
Subj_Id,
Name_Id,
Subj_Desc,
Type_Id,
Class,
Class_Id,
Object,
Object_Id,
Object_UserDriven,
Object_Accessibility,
Prop,
Flags
)
as
select U.UserName, U.Name, U.Description, ''1_CRIT'', C.Name, C.Id, O.Name, O.Short_Name, ''1'' User_Driven, 1 Accessibility, '''', O.Flags
    from Users U, Classes C,	Criteria_Rights R, Criteria O
    where Type = ''G'' and
        nvl(instr(U.Properties, ''|KERNEL''), 0) = 0 and
        R.Subj_Id = U.UserName and C.Id = O.Class_Id and O.Id = R.Obj_Id
union
select U.UserName, U.Name, U.Description, ''2_TRAN'', C.Name, C.Id, O.Name, O.Short_Name, O.User_Driven, 1 Accessibility, '''', '''' Flags
    from Users U, Classes C,	Transition_Rights R, Transitions O
    where Type = ''G'' and
        nvl(instr(U.Properties, ''|KERNEL''), 0) = 0 and
        R.Subj_Id = U.UserName and C.Id = O.Class_Id and O.Id = R.Obj_Id
union
select U.UserName, U.Name, U.Description, ''3_METH'', C.Name, C.Id, O.Name, O.Short_Name, O.User_Driven, O.Accessibility, '''', O.Flags
    from Users U, Classes C,	Method_Rights R, Methods O
    where Type = ''G'' and
        nvl(instr(U.Properties, ''|KERNEL''), 0) = 0 and
        R.Subj_Id = U.UserName and C.Id = O.Class_Id and O.Id = R.Obj_Id and O.Flags<>''A''
union
select U.UserName, U.Name, U.Description, ''4_OBJS'', '''||MSG_FIN_ACCOUNTS||''', ''AC_FIN'', Z2.C_Name, Z1.C_Main_V_Id, ''1'' User_Driven, 1 Accessibility, '''' /*G.Description*/, '''' Flags
    from Users U, Object_Rights R, Z#AC_FIN Z1, Z#ACCOUNT Z2 /*, Access_Groups G*/
    where Type = ''G'' and
        nvl(instr(U.Properties, ''|KERNEL''), 0) = 0 and
        R.Subj_Id = U.UserName and R.Obj_Id = to_char(Z1.Id)  and Z2.Id =Z1.Id /*and
        (Instr(R.Access_Group, G.Id)>0*/'
    ,Dbms_Sql.V7);
dbms_Sql.Parse(cid,' CREATE OR REPLACE VIEW Vw_NU_Rights
(
Class_Id,
Class,
Obj_Id,
Obj_Short,
Obj_Name,
Type_Id,
Subj,
Subj_Id,
Subj_Name,
Owner,
Owner_Name
)
as
select ''AC_FIN'', '''||MSG_FIN_ACCOUNTS||''', Z1.Id, Z1.C_Main_V_Id, Z2.C_Name, ''0_GRP'', U.Name || '' ('' || U.UserName || '')'', U.UserName, U.Name, '''', ''''
    from Z#AC_FIN Z1, Z#ACCOUNT Z2, Object_Rights R, Subj_Equal SE, Users U
    where Z1.Id = Z2.Id and to_char(Z2.Id) = R.Obj_Id and R.Subj_Id = SE.Equal_Id and SE.Subj_Id = SE.Owner_Id
        and SE.Subj_Id = U.UserName and U.Type = ''G'' and nvl(instr(U.properties, ''|KERNEL''), 0) = 0
union
select ''AC_FIN'', '''||MSG_FIN_ACCOUNTS||''', Z1.Id, Z1.C_Main_V_Id, Z2.C_Name, ''1_USR'', U.Name || '' ('' || U.UserName || '')'', U.UserName, U.Name, '''', ''''
    from Z#AC_FIN Z1, Z#ACCOUNT Z2, Object_Rights R, Subj_Equal SE, Users U
    where Z1.Id = Z2.Id and to_char(Z2.Id) = R.Obj_Id and R.Subj_Id = SE.Equal_Id and SE.Subj_Id = SE.Owner_Id
        and SE.Subj_Id = U.UserName and U.Type = ''U'' and (U.Lock_Status is Null or U.Lock_Status <> ''DELETED'')
union
select ''AC_FIN'', '''||MSG_FIN_ACCOUNTS||''', Z1.Id, Z1.C_Main_V_Id, Z2.C_Name, ''2_JOIN'', U.Name || '' ('' || U.UserName || '')'', U.UserName, U.Name, SE.Owner_Id, U2.Name
    from Z#AC_FIN Z1, Z#ACCOUNT Z2, Object_Rights R, Subj_Equal SE, Users U, Users U2
    where Z1.Id = Z2.Id and to_char(Z2.Id) = R.Obj_Id and R.Subj_Id = SE.Equal_Id and SE.Subj_Id <> SE.Owner_Id
        and SE.Subj_Id = U.UserName and SE.Owner_Id = U2.UserName and U.Type = ''U'' and (U.Lock_Status is Null or U.Lock_Status <> ''DELETED'')'
    ,Dbms_Sql.V7);
dbms_sql.Parse(cid,'GRANT SELECT ON Vw_Users TO ' || Inst_Info.Owner || '_USER',Dbms_Sql.V7);
dbms_sql.Parse(cid,'GRANT SELECT ON Vw_Users TO ' || Inst_Info.Owner || '_UADMIN',Dbms_Sql.V7);
dbms_sql.Parse(cid,'GRANT SELECT ON Vw_NU_Users TO ' || Inst_Info.Owner || '_USER',Dbms_Sql.V7);
dbms_sql.Parse(cid,'GRANT SELECT ON Vw_NU_Users TO ' || Inst_Info.Owner || '_UADMIN',Dbms_Sql.V7);
dbms_sql.Parse(cid,'GRANT SELECT ON Vw_NU_User_Rights TO ' || Inst_Info.Owner || '_USER',Dbms_Sql.V7);
dbms_sql.Parse(cid,'GRANT SELECT ON Vw_NU_User_Rights TO ' || Inst_Info.Owner || '_UADMIN',Dbms_Sql.V7);
dbms_sql.Parse(cid,'GRANT SELECT ON Vw_NU_Groups TO ' || Inst_Info.Owner || '_USER',Dbms_Sql.V7);
dbms_sql.Parse(cid,'GRANT SELECT ON Vw_NU_Groups TO ' || Inst_Info.Owner || '_UADMIN',Dbms_Sql.V7);
dbms_sql.Parse(cid,'GRANT SELECT ON Vw_NU_Group_Rights TO ' || Inst_Info.Owner || '_USER',Dbms_Sql.V7);
dbms_sql.Parse(cid,'GRANT SELECT ON Vw_NU_Group_Rights TO ' || Inst_Info.Owner || '_UADMIN',Dbms_Sql.V7);
dbms_sql.Parse(cid,'GRANT SELECT ON Vw_NU_Rights TO ' || Inst_Info.Owner || '_USER',Dbms_Sql.V7);
dbms_sql.Parse(cid,'GRANT SELECT ON Vw_NU_Rights TO ' || Inst_Info.Owner || '_UADMIN',Dbms_Sql.V7);
Exception when others then
  dbms_output.put_line(substr('Create_Vw_Nu: '||sqlerrm,1,255));
End Create_Vw_Nu;
---------------------------------------------------------------------
-- Создание всех view
PROCEDURE Create_All is
Begin
	Create_Vw_Ac_Fin;
    cid := Dbms_Sql.Open_Cursor;
	Create_Vw_Fintool;
	Create_Vw_Document;
	Create_Vw_Product;
	Create_Vw_Group_Users;
	Create_Vw_Object_Users;
	Create_Vw_Object_Cat_Users;
	Create_Vw_All_Rights_O;
	Create_Vw_All_Rights;
	Create_Vw_All_MOdel;
	Create_Vw_Nu;
	dbms_sql.Close_Cursor(cid);
End;
---------------------------------------------------------------
END;
/
sho err package body short_views
