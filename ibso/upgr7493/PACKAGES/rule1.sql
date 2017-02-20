PROMPT  Package RULES
CREATE OR REPLACE
PACKAGE Rules IS
/*
 *	$HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/rule1.sql $
 *	$Author: Alexey $
 *  $Revision: 15072 $
 *	$Date:: 2012-03-06 13:41:17 #$
 */
--------------------------------------------------------------
-- Rules - ������ � ��������� ������� � ��������
---------------------------------------------------------------
--------------------------------------------------------------
-- �������� ������ �������� ������ �������
FUNCTION Create_Package(SubjId IN VARCHAR2,
          ClassId IN VARCHAR2,
          bSetRights IN BOOLEAN DEFAULT FALSE) RETURN VARCHAR2;
--------------------------------------------------------------
-- �������� ���� ������� �������� ������ �������
PROCEDURE Create_All_Packages (bSetRights IN BOOLEAN DEFAULT FALSE);
--------------------------------------------------------------
-- �������/�������� ���� �� ������ ������ ��� ���� ���������
PROCEDURE Set_Object_Rights( ClassId IN VARCHAR2,
          ObjId IN VARCHAR2, Flags IN VARCHAR2 DEFAULT NULL);
--------------------------------------------------------------
-- �������������� ������.
Procedure Upgrade_Rules;
--------------------------------------------------------------
-- ��������� ������
Procedure Set_Rules(
	ClassId_     in VarChar2,
	SubjId_      in VarChar2,
	AttrId_      in VarChar2,
	AttrValue_   in VarChar2,
	AttrLevel_   in Number,
	AccessGroup_ in VarChar2);
--------------------------------------------------------------
-- �������� ������
Procedure Remove_Rules(
	ClassId_     in VarChar2,
	SubjId_      in VarChar2);
---------------------------------------------------------------
-- �������� ����������� ������
Procedure PurgeRules(ClassId  VARCHAR2, SrcUpper VARCHAR2);
--------------------------------------------------------------
-- ������� ���� �� ������/����� ��� ��������
Procedure ApplyRules(
	ClassId in varchar2,
    ObjId   in varchar2,
	SubjId  in varchar2,
	AccessGrp in varchar2,
	curLevel in integer);
--------------------------------------------------------------
-- �������/�������� ���� �� ������� ������ ��� ��������
PROCEDURE Set_Subj_Class_Rights(SubjId IN VARCHAR2,
          ClassId IN VarChar2, Flags IN VARCHAR2 DEFAULT NULL);
---------------------------------------------------------------
-- �������� ���� �� ��� ������ ��� ��������
PROCEDURE Delete_Subj_Rights( SubjId IN VARCHAR2);
--------------------------------------------------------------
-- �������� ������
FUNCTION Check_Rule(Attr_Value IN VARCHAR2, Mask IN VARCHAR2) RETURN BOOLEAN;
FUNCTION Check_Rule(Attr_Value IN NUMBER, Mask IN VARCHAR2) RETURN BOOLEAN;
FUNCTION Check_Rule(Attr_Value IN DATE, Mask IN VARCHAR2) RETURN BOOLEAN;
--Function DistinctStr(str1 in varchar2, str2 in varchar2) return varchar2;
--PRAGMA RESTRICT_REFERENCES ( DistinctStr, WNDS );
---------------------------------------------------------------
-- �������� ���������� ���������
procedure Clear_Subject;
function  GetCheckSubject return varchar2;
---------------------------------------------------------------
END Rules;
/
sho err

