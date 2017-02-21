PROMPT Security
CREATE OR REPLACE
PACKAGE Security IS
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/sec1.sql $
 *  $Author: minas $
 *  $Revision: 31457 $
 *  $Date:: 2013-08-29 12:16:42 #$
 */
--------------------------------------------------------------------------
-- SECURITY - Модуль администрирования прав доступа пользователей
--            Copyright (c) 1996-2013, Financial Techologies Center Inc.
---------------------------------------------------------------
-- Проверка эквивалентности субъектов доступа
FUNCTION Check_Equal( SubjId   IN VARCHAR2,
                      EqualId  IN VARCHAR2,
                      ChkAdmin IN VARCHAR2 DEFAULT '1') RETURN CHAR DETERMINISTIC;
--------------------------------------------------------------------------
-- Доступ к типу поняти
FUNCTION Cls_Accessible(
		ClassId  IN VARCHAR2,
		UserName IN VARCHAR2,
        ChkAdmin IN VARCHAR2 DEFAULT '1') RETURN CHAR DETERMINISTIC;
--------------------------------------------------------------------------
-- Доступ к методу
FUNCTION Mtd_Accessible(
		ClassId IN VARCHAR2,
		MethodId IN VARCHAR2, -- Methods.Id%TYPE,
		UserName IN VARCHAR2,
        ObjectId IN VARCHAR2 default NULL,
		AccessGroup IN VARCHAR2 default NULL,
        methACCESS  IN NUMBER default -1,
        BelongGroup IN VARCHAR2 default NULL,
        ChkAdmin IN VARCHAR2 DEFAULT '1') RETURN CHAR DETERMINISTIC;
--
FUNCTION Invocation_Accessible(MethodID VARCHAR2, Validator BOOLEAN, ReadOnly BOOLEAN := FALSE) RETURN VARCHAR2 DETERMINISTIC;
--
FUNCTION  Check_BelongGroup(BelongGroup IN VARCHAR2) RETURN VARCHAR2 DETERMINISTIC;
--
procedure CheckMethodsCall(SubjID   varchar2,
                           MethodID varchar2,
                           ObjID    varchar2,
                           ObjClass varchar2 default null,
                           CallMode varchar2 default null,
                           MethodClassID   varchar2 default null,
                           MethodShortName varchar2 default null);
---------------------------------------------------------------
-- Доступ к методам (by short_name)
FUNCTION Is_Method_Accessible(
	ClassId IN VARCHAR2,
	MethodShort IN VARCHAR2,
	UserName IN VARCHAR2,
	ObjectId IN VARCHAR2 default NULL,
	ClassIdOwner IN VARCHAR2 default NULL,
    ChkAdmin IN VARCHAR2 DEFAULT '1') RETURN boolean;
--------------------------------------------------------------------------
-- Доступ к представлениям
FUNCTION Crt_Accessible(
		ClassId IN VARCHAR2,
		CriteriaId IN VARCHAR2,
		UserName IN VARCHAR2,
        ChkAdmin IN VARCHAR2 DEFAULT '1') RETURN CHAR DETERMINISTIC;
--------------------------------------------------------------------------
-- Доступ к переходу
FUNCTION Trn_Accessible(
		ClassId IN VARCHAR2,
		TransitionId IN VARCHAR2,
		UserName IN VARCHAR2,
        ChkAdmin IN VARCHAR2 DEFAULT '1') RETURN CHAR DETERMINISTIC;
--------------------------------------------------------------------------
-- Доступ к хранимым процедурам
FUNCTION Prc_Accessible(
		ProcedureId IN VARCHAR2,
		UserName IN VARCHAR2,
        ChkAdmin IN VARCHAR2 DEFAULT '1') RETURN CHAR DETERMINISTIC;
---------------------------------------------------------------
-- Проверка доступа
FUNCTION Check_Rights(
		ClassId IN VARCHAR2,
		SubjId  IN VARCHAR2) RETURN VARCHAR2 DETERMINISTIC;
--------------------------------------------------------------------------
-- Доступ к объекту
FUNCTION Obj_Accessible( ObjId IN VARCHAR2,
                         UserName IN VARCHAR2,
                         ClassId  IN VARCHAR2 DEFAULT NULL,
                         ChkAdmin IN VARCHAR2 DEFAULT '1') RETURN CHAR DETERMINISTIC;
FUNCTION Ref_Accessible( ObjId IN VARCHAR2,
                         UserName IN VARCHAR2,
                         RefClass IN VARCHAR2,
                         ClassId  IN VARCHAR2 DEFAULT NULL,
                         ChkAdmin IN VARCHAR2 DEFAULT '1') RETURN CHAR DETERMINISTIC;
---------------------------------------------------------------
-- Входит ли пользователь в корневое подразделение.
function IsRootUserDomain return varchar2;
--------------------------------------------------------------------------
-- Прагмы
--------------------------------------------------------------------------
PRAGMA RESTRICT_REFERENCES (Cls_Accessible, WNDS, WNPS);
PRAGMA RESTRICT_REFERENCES (Mtd_Accessible, WNDS, WNPS, TRUST);
PRAGMA RESTRICT_REFERENCES (Crt_Accessible, WNDS, WNPS);
PRAGMA RESTRICT_REFERENCES (Trn_Accessible, WNDS, WNPS);
PRAGMA RESTRICT_REFERENCES (Obj_Accessible, WNDS, WNPS);
PRAGMA RESTRICT_REFERENCES (Ref_Accessible, WNDS, WNPS);
PRAGMA RESTRICT_REFERENCES (Is_Method_Accessible, WNDS, WNPS, TRUST);
PRAGMA RESTRICT_REFERENCES (Check_BelongGroup, WNDS, WNPS);
PRAGMA RESTRICT_REFERENCES (Check_Rights, WNDS, WNPS);
PRAGMA RESTRICT_REFERENCES (Check_Equal,  WNDS, WNPS);
PRAGMA RESTRICT_REFERENCES (IsRootUserDomain, WNDS, WNPS, TRUST);
--------------------------------------------------------------------------
function check_method_rights( p_obj_tbl in constant.refstring_table,
                              p_cls_tbl in constant.refstring_table,
                              p_User    in varchar2,
                              p_Method  in varchar2,
                              p_Access  in varchar2 default NULL
                            ) return boolean;
function check_method_rights( p_obj_tbl in constant.number_table,
                              p_cls_tbl in constant.refstring_table,
                              p_User    in varchar2,
                              p_Method  in varchar2,
                              p_Access  in varchar2 default NULL
                            ) return boolean;
function check_object_rights( p_obj_tbl in rtl.refstring_table,
                              p_User    in varchar2,
                              p_Method  in varchar2,
                              p_Access  in varchar2 default NULL,
                              p_Class   in varchar2 default NULL,
                              m_ACCESS  in number   default -1,
                              p_Belong  in varchar2 default NULL
                             )return boolean;
function check_object_rights( p_obj_tbl in constant.number_table,
                              p_User    in varchar2,
                              p_Method  in varchar2,
                              p_Access  in varchar2 default NULL,
                              p_Class   in varchar2 default NULL,
                              m_ACCESS  in number   default -1,
                              p_Belong  in varchar2 default NULL
                             )return boolean;
function check_log(method_id_ varchar2) return boolean;
--------------------------------------------------------------------------
procedure clear_rights_context(p_user varchar2 default null);
procedure init_rights_context (p_user varchar2, p_force boolean default false);
procedure set_rights_context  (p_subj varchar2, p_obj varchar2, p_crit boolean, p_add boolean);
--------------------------------------------------------------------------
-- Можно ли работать через Навигатор
function Is_Novo_Allowed return boolean;
END Security;
/
sho err

