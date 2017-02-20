PROMPT PACKAGE SecAdmin
CREATE OR REPLACE
PACKAGE SecAdmin IS
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/sa1.sql $
 *  $Author: pistomin $
 *  $Revision: 128882 $
 *  $Date:: 2016-11-25 15:15:45 #$
 */
---------------------------------------------------------------------
-- SecAdmin - Модуль администрирования пользователей
--         Copyright (c) 1996-2013, Financial Techologies Center Inc.
---------------------------------------------------------------
NO_VALUE constant varchar2(10) := '<NO VALUE>';
---------------------------------------------------------------
-- Проверка существования пользователя
---------------------------------------------------------------
SubType VCHAR2ARRAY is rtl.string40_table;
---------------------------------------------------------------
function get_version return varchar2;
---------------------------------------------------------------
-- Проверка существования пользователя
---------------------------------------------------------------
Function  CheckUser(UsrName IN VarChar2) return boolean;
function  check_object(p_user varchar2, p_object varchar2) return boolean;
function  check_roles( p_user varchar2 default null) return boolean;
function  check_role ( p_user varchar2, p_role varchar2) return boolean;
procedure CheckSystemUser(p_user varchar2);
procedure CheckDeleted(UserNameUpper IN varchar2, LockStatus IN varchar2 := NO_VALUE);
function  get_utype(p_user varchar2) return varchar2;
function  aud_setting(p_name varchar2) return varchar2;
Procedure ClearAvailablePrintingViews(UsrName IN VarChar2);
---------------------------------------------------------------------
-- Создание пользователя
---------------------------------------------------------------------
Procedure CreateUser(
    UsrName        varchar2,
    FullName       varchar2,
    UserType       char     := 'U',
    UserPass       varchar2 := null,
    Prop           varchar2 := null,
    LockStatus     varchar2 := null,
    LockDate       date     := null,
    UnLockDate     date     := null,
    SecurityDomain varchar2 := null,
    p_os_domain    varchar2 := NO_VALUE,
    p_os_user      varchar2 := NO_VALUE,
    p_check_3l     boolean  := true
    );
---------------------------------------------------------------------
-- Модификация пользователя
---------------------------------------------------------------------
Procedure EditUser(
    UsrName         varchar2,
    FullName        varchar2,
    UserType        char     := 'U',
    UserPass        varchar2 := null,
    Prop            varchar2 := NO_VALUE,
    LockStatus      varchar2 := null,
    LockDate        date     := null,
    UnLockDate      date     := null,
    p_os_domain     varchar2 := NO_VALUE,
    p_os_user       varchar2 := NO_VALUE,
    p_wait_status   boolean  := false
    );
---------------------------------------------------------------------
-- Удаление пользователя
---------------------------------------------------------------------
PROCEDURE DeleteUser(
    UsrName   IN VarChar2,
    UserType_ IN Char DEFAULT null);
---------------------------------------------------------------------
-- Модификация описания пользователя
---------------------------------------------------------------------
PROCEDURE EditUserDescription(UsrName  IN VarChar2,
                   UserType IN Char DEFAULT 'U',
                   Description IN VarChar2);
---------------------------------------------------------------
-- Добавление сетевого адреса
---------------------------------------------------------------
Procedure Insert_Address (
    Address_ IN VarChar2,
    Description_ IN VarChar2,
    Domain_      IN Varchar2 default Null);
---------------------------------------------------------------
-- Удаление сетевого адреса
---------------------------------------------------------------
Procedure Delete_Address (
    Address_ IN VarChar2,
    Description_ IN VarChar2 DEFAULT null,
    Domain_      IN Varchar2 default Null);
---------------------------------------------------------------
-- Изменение сетевого адреса
---------------------------------------------------------------
Procedure Change_Address (
    AddressOld IN VarChar2,
    AddressNew IN VarChar2,
    Description_ IN VarChar2,
    Domain_      IN Varchar2 default Null);
---------------------------------------------------------------
-- Удаление у User'a сетевого адреса
---------------------------------------------------------------
Procedure Delete_User_From_Address(
    UsrName  IN VarChar2,
    Address_ IN VarChar2);
---------------------------------------------------------------
-- Добавление User'у сетевого адреса
---------------------------------------------------------------
Procedure Insert_User_To_Address(
    UsrName  IN VarChar2,
    Address_ IN VarChar2,
    Description_ IN VarChar2);
---------------------------------------------------------------
-- Установка проверки доступа пользователя на ссылку
---------------------------------------------------------------
PROCEDURE SetAttrAccessCheck(ClassId IN VarChar2,
          UsrName IN VarChar2);
---------------------------------------------------------------
-- Удаление проверки доступа пользователя на ссылку
---------------------------------------------------------------
PROCEDURE RemoveAttrAccessCheck(ClassId IN VarChar2,
          UsrName IN VarChar2);
---------------------------------------------------------------
-- Установка прав пользователя на тип данных
---------------------------------------------------------------
PROCEDURE SetClassRights(ClassId IN VarChar2,
          UsrName IN VarChar2,
          NotInMenu IN Char DEFAULT NULL);
---------------------------------------------------------------
-- Удаление прав пользователя на тип данных
---------------------------------------------------------------
PROCEDURE RemoveClassRights(ClassId IN VarChar2,
          UsrName IN VarChar2);
---------------------------------------------------------------
-- Установка прав пользователя на методы
---------------------------------------------------------------
Procedure SetMethodRights(
    ClassId IN VarChar2,
    MethId IN VarChar2,
    UsrName IN VarChar2,
    mkProcView boolean default null);
---------------------------------------------------------------
-- Удаление прав пользователя на методы
---------------------------------------------------------------
Procedure RemoveMethodRights(
    ClassId IN VarChar2,
    MethId IN VarChar2,
    UsrName IN VarChar2,
    mkProcView boolean default null);
---------------------------------------------------------------
-- Установка прав пользователя на критерии
---------------------------------------------------------------
Procedure SetCriteriaRights(
    ClassId IN VarChar2,
    CritId IN VarChar2,
    UsrName IN VarChar2,
    ToPrinter IN Varchar2 default NO_VALUE,
    ToFile IN Varchar2 default NO_VALUE);
---------------------------------------------------------------
-- Удаление прав пользователя на критерии
---------------------------------------------------------------
Procedure RemoveCriteriaRights(
    ClassId IN VarChar2,
    CritId IN VarChar2,
    UsrName IN VarChar2);
---------------------------------------------------------------
-- Установка прав пользователя на переходы
---------------------------------------------------------------
Procedure SetTransitionRights(
    ClassId IN VarChar2,
    TranId IN VarChar2,
    UsrName IN VarChar2);
---------------------------------------------------------------
-- Удаление прав пользователя на переходы
---------------------------------------------------------------
Procedure RemoveTransitionRights(
    ClassId IN VarChar2,
    TranId IN VarChar2,
    UsrName IN VarChar2);
---------------------------------------------------------------
-- Установка прав пользователя на хранимые процедуры
---------------------------------------------------------------
PROCEDURE SetProcRights(ProcName IN VarChar2,
          UsrName IN VarChar2);
---------------------------------------------------------------
-- Удаление прав пользователя на хранимые процедуры
---------------------------------------------------------------
PROCEDURE RemoveProcRights(ProcName IN VarChar2,
          UsrName IN VarChar2);
---------------------------------------------------------------
-- Массовая установка прав пользователя на объекты доступные по ссылке
--
-- Изменяется доступ каждому пользователю из UsrNameList на экземпляры из RefClsIdList
-- каждого объекта из ObjIdList
---------------------------------------------------------------
PROCEDURE SetObjRightsList(UsrNameList  IN rtl.STRING40_TABLE,
                           ObjIdList    IN rtl.REFSTRING_TABLE,
                           ClsId        IN VarChar2,
                           RefClsIdList IN rtl.STRING40_TABLE,
                           Sign         IN CHAR);
---------------------------------------------------------------
-- Установка прав пользователя на объекты доступные по ссылке
---------------------------------------------------------------
PROCEDURE SetObjRightsEx(UsrName IN VarChar2,
        ObjId IN VarChar2,
        ClsId IN VarChar2,
        RefClsId IN VarChar2,
        Sign IN CHAR);
---------------------------------------------------------------
-- Установка прав пользователя на объекты
---------------------------------------------------------------
PROCEDURE SetObjRights(ObjId IN VarChar2,
        UsrName IN VarChar2, Sign IN CHAR,
        AccessGrp IN varchar2 default null,
        ClassId   IN varchar2 default null);
---------------------------------------------------------------
-- Установка прав пользователя на операции и переходы
---------------------------------------------------------------
PROCEDURE SetAllRights(ClassId IN VarChar2,
        UsrName IN VarChar2,
    RightType IN VARCHAR2);
---------------------------------------------------------------
-- Копирование прав одного субъекта другому
---------------------------------------------------------------
--PROCEDURE CopyRights(SrcSubject VARCHAR2, DstSubject VARCHAR2, Rights_Mask VARCHAR2);
---------------------------------------------------------------
-- Копирование прав одного субъекта другому
PROCEDURE CopyRightsX(SrcSubject VARCHAR2, DstSubject VARCHAR2, Rights_Mask VARCHAR2);
---------------------------------------------------------------
-- Копирование выбранных прав одного субъекта другому
Procedure CopySelectedRights(
    SrcSubject VARCHAR2,
    DstSubject VARCHAR2,
    ClassId VARCHAR2,
    Component_Mask VARCHAR2,
    ArraySize INTEGER,
    Obj_List IN VCHAR2ARRAY);
---------------------------------------------------------------
-- Procedure PurgeRules(ClassId  VARCHAR2, SrcUpper VARCHAR2);
---------------------------------------------------------------
-- Ремонт подсистемы доступа
procedure SecurityCare(FullEqualClear BOOLEAN default false);
procedure update_subj_equal;
function  fill_userid return number;
---------------------------------------------------------------
-- Анализ системы доступа
function SecurityAnalise(
    SubjId in varchar2,
    ClassId in varchar2,
    ObjType in varchar2,
    AccessType in varchar2,
    ObjId in varchar2 default null,
    Options in varchar2 default null) return integer;
---------------------------------------------------------------
-- Создание/удаление синонимов
PROCEDURE CreateSynonyms (mId IN VARCHAR2,pUserName VARCHAR2 default null,p_rights boolean default true);
/* Созданные синонимы по умолчанию (например F, FD, FDP) кэшируются 
   на уровне пакета и при последующих вызовах в той же сессии не будут создаваться. 
   Для сброса кэша нужно вызвать reset_report_roles_cache */
PROCEDURE CreateSynonymsForSubject (pUserName IN VARCHAR2,pClear boolean default true,
                                    p_rpt_abs boolean default true,p_grant_check boolean default true);
PROCEDURE SetReportRights (mid in varchar2,pUserName varchar2 default null,pClear boolean default true,p_cascade boolean default true, p_synonyms boolean default false);
PROCEDURE SetReportRightsForSubject(pUserName IN VarChar2,pClear boolean default true,p_rpt_abs boolean default true,p_cascade boolean default true );
function  chk_reports(p_subj varchar2, p_rpt_abs boolean) return boolean;
procedure add_subj_list(p_subj varchar2,p_equal varchar2 default null,p_prop number default 0);
function  get_subj_list(p_list in out nocopy VCHAR2ARRAY) return pls_integer;
function  set_subj_list(p_list VCHAR2ARRAY) return pls_integer;
function  get_subj_count return pls_integer;
procedure reset_subj_list;
procedure ReportRightsCare(p_force boolean default false);
---------------------------------------------------------------
-- Создание спецролей для пакетов, используемых в отчетах OracleReports
procedure reset_report_roles_cache;
procedure set_max_report_roles(n pls_integer);
procedure set_group_report_roles(p_group boolean);
function  check_report_role(p_name in varchar2, p_grant_check boolean default true, p_subj varchar2 default null) return varchar2;
function  in_report_use(p_name varchar2,p_trim varchar2) return varchar2;
procedure drop_report_role(p_name in varchar2, p_role varchar2 default null, p_grant_check boolean default true);
procedure generate_report_roles (n pls_integer,p_grants boolean, pClear boolean default true,p_rpt_abs boolean default true,p_group boolean default null);
procedure ReportRolesCare(p_grant_check boolean default false);
procedure create_report_roles (p_drop boolean);
procedure create_all_reports_role(p_drop boolean);
procedure create_group_reports_roles(p_drop boolean);
---------------------------------------------------------------
-- Восстановление потерянных/испорченных групп ревизоров
function  GetRevisorGroup(p_domain varchar2, p_create boolean := false) return varchar2;
procedure RecoverRevisorGroups(pUserName varchar2 default null);
-- Восстановление потерянных групп ресурсов
function  GetResourceGroup(p_domain varchar2, p_create boolean := false) return varchar2;
procedure RecoverResourceGroups(pUserName varchar2 default null);
---------------------------------------------------------------
-- Задание пользователя системы доступа
procedure BecomeUser(UsrName IN VarChar2 default null);
---------------------------------------------------------------
-- Пользователь системы доступа
Function Usr return varchar2 deterministic;
pragma restrict_references(Usr, WNDS, WNPS);
---------------------------------------------------------------
-- Проверка обновления контекста
function  GetCheckSubject return varchar2;
procedure KillCheckSubject(p_kill boolean default false);
procedure InitSubjContext(p_ids "CONSTANT".NUMBER_TABLE);
---------------------------------------------------------------
--maximov
---------------------------------------------------------------
--Установка/снятие операции проверки на метод для субъекта
function GetCheckMethodMaxPos(SubjectID in varchar2, MethodID in varchar2) return integer;
pragma restrict_references(GetCheckMethodMaxPos,wnds,wnps);
function IsCheckMethodValid(CheckMethodID in varchar2) return integer;
pragma restrict_references(IsCheckMethodValid,wnds,wnps);
procedure SetCheckMethod(SubjectID in varchar2, MethodID in varchar2, CheckMethodID in varchar2, Pos in integer default null);
procedure DeleteCheckMethod(SubjectID in varchar2, MethodID in varchar2, CheckMethodID in varchar2);
procedure MoveCheckMethod(SubjectID in varchar2, MethodID in varchar2, CheckMethodID in varchar2, Pos in integer default null);
------------------------------------------------------------
--Копирование прав доступа к одному объекту другому
procedure DuplicateObjRights(SourceObjID in VarChar2, DestObjID in VarChar2,
                             SrcClassId varchar2 default null, DstClassId varchar2 default null);
procedure DuplicateObjRightsEx(SourceObjID in VarChar2, DestObjID in VarChar2, Sign varchar2 default null,
                               SrcClassId varchar2 default null, DstClassId varchar2 default null);
---------------------------------------------------------------
--добавить группу в группу
procedure Insert_Group_To_Group(GroupID in varchar2, TargetGroupID in varchar2);
---------------------------------------------------------------
--удалить группу из группы
procedure Delete_Group_From_Group(DelGroupID in varchar2, GroupID in varchar2 default null);
---------------------------------------------------------------
-- Запрос на модификацию Subj_Equal при удалении Usera из группы
---------------------------------------------------------------
procedure Delete_User_From_Group(UsrName IN VarChar2, GroupId IN VarChar2);
---------------------------------------------------------------
-- Запрос на модификацию Subj_Equal при добавлении Usera в группу(ы)
---------------------------------------------------------------
procedure Insert_User_To_Group(UsrName IN VarChar2, GroupId IN VarChar2);
---------------------------------------------------------------
-- Добавление пользователя DstSubject в группы пользователя/группы SrcSubject (PLTM00004263).
Procedure Copy_Groups(SrcSubject varchar2, DstSubject varchar2);
---------------------------------------------------------------
-- Временное копирование прав одного субъекта другому
procedure TempCopyRights(SrcSubject varchar2, DstSubject varchar2, Rights_Mask varchar2 default NULL);
---------------------------------------------------------------
-- Удаление временнх прав одного субъекта у другого
procedure TempDeleteRights(SelfSubject varchar2, OwnerSubject varchar2, Rights_Mask varchar2 default NULL);
---------------------------------------------------------------

---------------------------------------------------------------
-- Если поддержка ADMIN_GRP включена (настройка ADMIN_GRP_ENABLED
-- на схеме аудита), то проверяет является/входит ли SubjId в
-- ADMIN_GRP. В противном случае, всегда возвращает false.
function IsAdminGrp(SubjId varchar2) return boolean;
PRAGMA RESTRICT_REFERENCES (IsAdminGrp, WNDS, WNPS);
---------------------------------------------------------------
-- Включена ли поддержка ADMIN_GRP (настройка ADMIN_GRP_ENABLED
-- на схеме аудита)
function IsAdminGrpEnabled return boolean;
PRAGMA RESTRICT_REFERENCES (IsAdminGrpEnabled, WNDS, WNPS, TRUST);
---------------------------------------------------------------
--
--
function IsUAdminsCountRestricted return boolean;
PRAGMA RESTRICT_REFERENCES (IsUAdminsCountRestricted, WNDS, WNPS, TRUST);
---------------------------------------------------------------
--
--
function GetUAdminsMaxCount return pls_integer;
PRAGMA RESTRICT_REFERENCES (GetUAdminsMaxCount, WNDS, WNPS);
---------------------------------------------------------------
-- Кидает исключение, если IsReadOnly возвращает true.
procedure CheckReadOnly;
---------------------------------------------------------------
-- Возвращает '1', если включен режим UADMIN_READ_ONLY или
-- текущему пользователю дана роль REVISOR
function IsReadOnly return varchar2;
---------------------------------------------------------------
-- Возвращает true, если текущему пользователю дана роль REVISOR
function IsRevisor(bRoot boolean := null) return boolean;
PRAGMA RESTRICT_REFERENCES (IsRevisor, WNDS, WNPS, TRUST);
function IsRootRevisor(p_UserName in varchar2) return boolean;
PRAGMA RESTRICT_REFERENCES (IsRootRevisor, WNDS, WNPS);
---------------------------------------------------------------
function  IsRootUAdmin return varchar2;
function  AreRightsAccessible(p_username varchar2) return varchar2;
procedure CheckRightsAccessible(p_username varchar2);
---------------------------------------------------------------
procedure ModifyProps(cProperties in out nocopy varchar2, PropName in varchar2, bSet in boolean);
function NextProp(props varchar2, pos in out pls_integer) return varchar2;
function PropsMinus(props1 varchar2, props2 varchar2) return varchar2;
function PropsDiff(props1 varchar2, props2 varchar2) return varchar2;
---------------------------------------------------------------
function  GetDomainName(p_domain varchar2) return varchar2;
procedure CreateDomain(p_id varchar2, p_parent_id varchar2, p_name varchar2, p_app_id varchar2);
procedure EditDomain(p_id varchar2, p_name varchar2 := NO_VALUE, p_app_id varchar2 := NO_VALUE);
procedure ChangeDomainId(p_id varchar2, p_new_id varchar2);
procedure ChangeDomainParent(p_domain varchar2, p_parent varchar2);
procedure DeleteDomain(p_id varchar2);

function  AppIdToDomain(p_app_id varchar2) return varchar2;
procedure CreateDomainApp(p_app_id varchar2, p_parent_app_id varchar2, p_name varchar2, p_id varchar2 := null);
procedure EditDomainApp(p_app_id varchar2, p_name varchar2);
procedure DeleteDomainApp(p_app_id varchar2);
--
procedure AddGroupToDomain(p_group varchar2, p_domain varchar2);
procedure RemoveGroupFromDomain(p_group varchar2, p_domain varchar2);
procedure ChangeUserDomain(p_user varchar2, p_domain varchar2, p_exec_date date := null, p_change_dept varchar2 := '1');
procedure CancelUserDomainChange(p_user varchar2);
procedure ChangeAdminPrivs(p_user varchar2, p_privs varchar2);
--
procedure ChangeUserDomains;
---------------------------------------------------------------
procedure RevokePrivs;
---------------------------------------------------------------
-- Удаляет права доступа на представления, которые больше не наследуются дочерними типами.
procedure RemoveOldInheritedCritAccess(p_row_limit integer := null);
---------------------------------------------------------------
END SecAdmin;
/
sho err
