prompt move_obj
create or replace package move_obj is
/*
 *	$HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/move1.sql $
 *	$Author: Alexey $
 *  $Revision: 15072 $
 *	$Date:: 2012-03-06 13:41:17 #$
 */
--
-- ��������� ID �������������
    procedure rename_criterion(p_method_id varchar2, p_new_id varchar2, p_all boolean default true);
-- ��������� ID ��������
    procedure rename_method(p_method_id varchar2, p_new_id varchar2, p_all boolean default true);
-- ��������� ID ���� �������������
    procedure init_favorites;
-- ��������� ID ���������
    procedure init_transitions;
-- ��������� ID ����� ��������
    procedure init_method_groups;
-- ��������� ID ���������
    procedure init_controls;
-- ��������� ID ����������� ��������
    procedure init_procedures;
-- ��������� ID ����������� ������������� ��� �������
    procedure init_report_views;
-- ��������� ID ������� LRAW
    procedure init_lraw;
-- ��������� ID ���� �������������
    procedure init_criteria;
-- ��������� ID ���� ��������
    procedure init_methods;
-- ��������� ID ���������� �������������������
    procedure init_sequences;
-- ��������� ID �������� ������
    procedure init_printer_macroses;
-- ��������� ID ����������� ������
    procedure move_objects(p_class varchar2);
-- ��������� ����������-��������� ����������� ������
    procedure move_collections (p_class varchar2);
-- ��������� OLE-���������� ����������� ������
    procedure move_ole (p_class varchar2);
end;
/
sho err

