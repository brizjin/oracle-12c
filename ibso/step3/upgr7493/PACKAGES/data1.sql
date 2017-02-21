PROMPT Data_Views
CREATE OR REPLACE
PACKAGE Data_Views IS
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/data1.sql $
 *  $Author: kuvardin $
 *  $Revision: 55235 $
 *  $Date:: 2014-11-13 14:34:19 #$
 */
TYPE RPT_CURSOR IS REF CURSOR;
--------------------------------------------------------------
-- Data_Views - �������� VIEW ��� ������� � ������
--------------------------------------------------------------
---------------------------------------------------------------
-- ���������� ������ ������ (��� ��������� ���������)
---------------------------------------------------------------
FUNCTION GetVersion RETURN VARCHAR2;
---------------------------------------------------------------
-- �������� view ��� ���������
---------------------------------------------------------------
PROCEDURE Create_Vw_Crit(CrId varchar2, Complex boolean default false,
                         p_recompile boolean default null, p_arch boolean default null);
function  conv_view_name ( p_name varchar2, p_arch  boolean) return varchar2;
---------------------------------------------------------------
-- ���������� �������������
---------------------------------------------------------------
function  set_extension(p_crit_id    varchar2,
                      p_ext_short_name varchar2,
                      p_ext_name   varchar2,
                        p_ext_id     varchar2 default null ) return varchar2;
procedure check_extension(p_ext_id varchar2,p_src_id varchar2,p_cols boolean default true,p_check boolean default false);
---------------------------------------------------------------
-- ��������� ����� ������� �� �� ������ (����� ������� Create_Vw_Crit)
---------------------------------------------------------------
FUNCTION Get_ColName_By_Position(CrId IN varchar2, Pos IN NUMBER) RETURN VARCHAR2;
---------------------------------------------------------------
-- �������� �������� ��� ������
---------------------------------------------------------------
PROCEDURE Delete_Criterion(CrId IN varchar2);
---------------------------------------------------------------
-- ��������� ������ ������ �������
---------------------------------------------------------------
PROCEDURE Set_Debug(dLevel IN VARCHAR2);
---------------------------------------------------------------
-- �������� �������� (������ ������ � ������� Criteria)
---------------------------------------------------------------
FUNCTION Create_Criterion(Id_ IN varchar2,
                          Name_ IN varchar2,
                          Class_Id_ IN varchar2,
                          Condition_ IN varchar2,
                          Propagate_ IN varchar2,
                          Object_Rights_ IN varchar2,
                          Hierarchy_Attr_ IN varchar2,
                          Def_ IN varchar2,
                          Cell_Style_ IN VARCHAR2 DEFAULT NULL,
                          Order_By_ IN  VARCHAR2 DEFAULT '|',
                          Access_group_ IN CHAR DEFAULT NULL,
                          Card_Condition_ IN VARCHAR2 DEFAULT NULL)
                          RETURN VARCHAR2;
---------------------------------------------------------------
-- �������� ��������, ������ Create_Criterion, �� � ShortName
---------------------------------------------------------------
FUNCTION Create_Criterion2(Id_ IN varchar2,
                          Name_ IN varchar2,
                          Short_Name_ IN varchar2,
                          Class_Id_ IN varchar2,
                          Condition_ IN varchar2,
                          Propagate_ IN varchar2,
                          Object_Rights_ IN varchar2,
                          Hierarchy_Attr_ IN varchar2,
                          Def_ IN varchar2)
                          RETURN VARCHAR2;
---------------------------------------------------------------
-- �������� ��������, ������ Create_Criterion2, �� � Properties
---------------------------------------------------------------
FUNCTION Create_Criterion3(Id_ IN varchar2,
                          Name_ IN varchar2,
                          Short_Name_ IN varchar2,
                          Class_Id_ IN varchar2,
                          Condition_ IN varchar2,
                          Propagate_ IN varchar2,
                          Object_Rights_ IN varchar2,
                          Hierarchy_Attr_ IN varchar2,
                          Def_ IN varchar2,
                          Props IN varchar2,
                          Cell_Style_ IN VARCHAR2 DEFAULT NULL,
                          Order_By_ IN VARCHAR2 DEFAULT '|',
                          Access_group_ IN CHAR DEFAULT NULL,
                          Card_Condition_ IN VARCHAR2 DEFAULT NULL)
                          RETURN VARCHAR2;
---------------------------------------------------------------
-- ���������� alias ������� ������������� �� �� ������ ����� �������
---------------------------------------------------------------
FUNCTION Get_Alias_By_Visible_Index$(Criteria_Id_ IN varchar2,
                                    Visible_Index_ IN pls_integer) RETURN varchar2;
---------------------------------------------------------------
-- ������������� ������� ������������� ��������� ��������������� �� ����� ����
---------------------------------------------------------------
procedure set_usercontext_used(p_class varchar2 default null);
---------------------------------------------------------------
-- ����������� �������� order_type � criteria_columns
-- ��������� ������ �� order_by � criteria (��� ���� �������)
---------------------------------------------------------------
PROCEDURE Translate_Criterion_Order_By;
---------------------------------------------------------------
-- ����������� �������� order_type � criteria_columns
-- ��������� ������ �� Order_By (��� ����� ������)
---------------------------------------------------------------
PROCEDURE Translate_Criterion_Order_By(Criteria_Id_ IN varchar2);
---------------------------------------------------------------
-- ����������� �������� order_type � criteria_columns
-- ��������� ������ �� Order_By (��� ����� ������; ������������
-- � �������� � ��. ����������)
---------------------------------------------------------------
PROCEDURE Translate_Criterion_Order_By$(Criteria_Id_ IN varchar2,
                                        Order_By IN varchar2,
                                        Properties IN varchar2);
---------------------------------------------------------------
-- ��������� ��� ��������� ������ ������� criteria_prints
---------------------------------------------------------------
procedure edit_criteria_print(criteria_id_ varchar2, name_ varchar2, header_ varchar2,
                              font_name_ varchar2, outfile_ varchar2, keys_ varchar2,
                              delimiter_ varchar2, quote_ varchar2, page_ varchar2);
---------------------------------------------------------------
-- ������� ������ ������� criteria_prints
---------------------------------------------------------------
procedure delete_criteria_print(criteria_id_ varchar2, name_ varchar2);
---------------------------------------------------------------
-- ��������� ��� ��������� ������ ������� criteria_print_columns
---------------------------------------------------------------
procedure edit_criteria_print_column(criteria_id_ varchar2, print_name_ varchar2,
                                     alias_ varchar2, position_ number, width_ number,
                                     oper_ varchar2 default null,
                                     quote_ varchar2 default null,
                                     align_ varchar2 default null);
---------------------------------------------------------------
-- ������� ������/������ ������� criteria_print_columns
---------------------------------------------------------------
procedure delete_criteria_print_column(criteria_id_ varchar2, print_name_ varchar2,
                                     alias_ varchar2 default null);
---------------------------------------------------------------
-- ��������� ������� criteria_print_columns
-- ��������� ������ �� format � criteria_prints
---------------------------------------------------------------
PROCEDURE Translate_Crit_Prints_Format;
---------------------------------------------------------------
-- ��������� ������� criteria_print_columns
-- ��������� ������ �� Format
---------------------------------------------------------------
PROCEDURE Translate_Crit_Prints_Format$(Criteria_Id_ IN varchar2,
                                       Name_ IN varchar2,
                                       Format varchar2);
---------------------------------------------------------------
-- �������� ������ (������ ������ � ������� Criteria)
---------------------------------------------------------------
FUNCTION Create_Report(Id_ IN varchar2,
                       Name_ IN varchar2,
                       Short_Name_ IN varchar2,
                       Class_Id_ IN varchar2,
                       Condition_ IN varchar2,
                       Object_Rights_ IN varchar2,
                       Not_Objects_  IN varchar2,
                       Not_Rights_  IN varchar2)
                       RETURN VARCHAR2;
---------------------------------------------------------------
-- �������� ������, ������ Create_Report, �� � Properties
---------------------------------------------------------------
FUNCTION Create_Report3(Id_ IN varchar2,
                       Name_ IN varchar2,
                       Short_Name_ IN varchar2,
                       Class_Id_ IN varchar2,
                       Condition_ IN varchar2,
                       Object_Rights_ IN varchar2,
                       Not_Rights_  IN varchar2,
                       Props IN varchar2,
                       Access_group_ IN CHAR DEFAULT NULL,
                       Card_Condition_ IN VARCHAR2 DEFAULT NULL)
                       RETURN VARCHAR2;
---------------------------------------------------------------
-- ����������� �������
---------------------------------------------------------------
FUNCTION Copy_Criterion(CrId IN  VARCHAR2,
                        NewName  IN VARCHAR2 DEFAULT NULL,
                        NewClass IN VARCHAR2 DEFAULT NULL,
                        NewSName IN VARCHAR2 DEFAULT NULL)
                        RETURN VARCHAR2;
---------------------------------------------------------------
-- �������� �� ������������� ���������
---------------------------------------------------------------
FUNCTION Is_Object_Exists(ObjectName IN VARCHAR2, ObjectType IN VARCHAR2) RETURN VARCHAR2;
---------------------------------------------------------------
-- �������� ��������� ��� ������
---------------------------------------------------------------
PROCEDURE CREATE_RPT_PROC (CrId in varchar2, Name_ in varchar2,
  Cr_Rep in varchar2, Hints IN varchar2, description_ in varchar2 default null);
---------------------------------------------------------------
-- �������������� ��������� ��� ������������� ��� ������
---------------------------------------------------------------
Procedure Edit_Object(Name_ in varchar2, Type_ in varchar2, Text in varchar2, bLastLine in varchar2 := '1');
--------------------------------------------------------------
-- ��������� ����� �� �����
---------------------------------------------------------------
FUNCTION Key2Number(Key IN VARCHAR2) RETURN NUMBER DETERMINISTIC;
PRAGMA RESTRICT_REFERENCES (Key2Number, RNDS, RNPS, WNDS, WNPS);
--------------------------------------------------------------
procedure rename_alias(p_crit_id varchar2,p_new varchar2,p_old varchar2);
function  check_aliases(p_crit_id varchar2, p_correct boolean default false) return varchar2;
procedure put_aliases(p_als rtl.defstring_table,p_quals rtl.memo_table,p_start pls_integer default null);
function  get_aliases(p_als in out nocopy rtl.defstring_table,p_start pls_integer default null,p_count pls_integer default null) return pls_integer;
procedure process_aliases;
--------------------------------------------------------------
procedure put_dependence(p_crid varchar2,p_view varchar2,p_type varchar2,p_alias varchar2 default null,p_prop boolean default true);
procedure check_props;
procedure check_criteria(inserting boolean, deleting boolean,
                         p_old criteria%rowtype,
                         p_new criteria%rowtype);
procedure check_criteria_columns(inserting boolean, deleting boolean,
                         p_old criteria_columns%rowtype,
                         p_new criteria_columns%rowtype);
procedure check_criteria_prints(inserting boolean, deleting boolean,
                         p_old criteria_prints%rowtype,
                         p_new criteria_prints%rowtype);
procedure check_criteria_methods(inserting boolean, deleting boolean, criteria_id in varchar2);
--------------------------------------------------------------
END Data_Views;
/
show err

