prompt CONTEXT_INFORMATION
create or replace package CONTEXT_INFORMATION is
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/context_information1.sql $
 *  $Author: amarchenko $
 *  $Revision: 94745 $
 *  $Date:: 2016-02-19 14:55:46 #$
 */
--------------------------------------------------------------
-- CONTEXT_INFORMATION - ������ ������� ��� ������ ������������ ��������������
--            Copyright (c), 1996-2016, Financial Techologies Center Inc.
--------------------------------------------------------------
-- ���������
---------------------------------------------------------------
VERSION    constant varchar2(10):='1.0';
BUILD_NO   constant pls_integer := 1;
--------------------------------------------------------------
-- ����
---------------------------------------------------------------
type context_information_rec is record (
  control_id varchar2(4000),
  headline varchar2(4000),
  description varchar2(4000),
  link varchar2(4000),
  settings varchar2(4000),
  ctx varchar2(4000)
);

type context_information_tbl is table of context_information_rec;
---------------------------------------------------------------
-- �������
---------------------------------------------------------------
-- ��������� ������ ������
---------------------------------------------------------------
function Get_Version return varchar2;
function Is_Available return varchar2;
---------------------------------------------------------------
-- ��������� ������ ��� ������������ ��������������
---------------------------------------------------------------
function Get_Context_Information(p_class_id in varchar2, p_short_name in varchar2, p_method_id in varchar2, p_types in varchar2)
                  return context_information_tbl pipelined;
---------------------------------------------------------------
-- ���������� �������� �����, ���������� 1 ���� �������� ����� ������� ���������, ����� 0.
---------------------------------------------------------------
function Save_Feedback(p_class_id varchar2, p_short_name varchar2, p_control_id varchar2, 
                       p_feedback varchar2, p_feedback_other varchar2, p_rating number, p_context varchar2) return varchar2;
---------------------------------------------------------------
-- ��������� ������ ��������� ����������� �����������
---------------------------------------------------------------
procedure Remind_Later(p_class_id varchar2, p_short_name varchar2, p_control_id varchar2, p_context in varchar2);
---------------------------------------------------------------
-- ��������� ����������� ������������
---------------------------------------------------------------
function Get_Standard_Comments return varchar2;
---------------------------------------------------------------
end CONTEXT_INFORMATION;
/
show err
