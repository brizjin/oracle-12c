@echo ��ࠬ���� ����᪠
@echo start_compile.bat [��ப� �室�] [������⢮ ��⮪�� �������樨]
@echo ४��������� ��⠭�������� ������⢮  ��⮪�� �������樨, ࠢ�� ��� �����஢ �� �ࢥ� Oracle
@echo � ��஫� �������� ����� �ᯮ�짮���� ᨬ����-ࠧ����⥫� (�஡��, ������)
@echo ����室��� 䠩��:
@echo run_sessions.bat - �㦥��� bat 䠩� ��� ����᪠ ��⮪�� �������樨
@echo s_meth_recomp_all.sql - �᭮���� �ਯ� �������樨
@echo s_meth_recomp.sql - �ࠢ����� ��⮪��� �������樨
@echo compile1.sql - ���� ��⮪ ��������� 
@echo methods_info.sql - �뢮� ���ଠ樨 � ���������� ��⮤��
@echo rtl_idx.sql - �㦥��� �ਯ� ��� ���� ������ � rtl_entries

@echo off
if NOT "%1"=="" goto CHECK_P
@echo .
@echo �� 㪠���� ��ப� �室� {���_���������}/{������_���������}@{���_�����}
@echo �ਬ��: start_compile.bat ibs/pasw@ibso 4
exit

:CHECK_P
if NOT "%2"=="" goto OK
@echo .
@echo �� 㪠���� ������⢮ ��⮪�� �������樨
@echo �ਬ��: start_compile.bat ibs/pasw@ibso 4
exit

:OK
chcp 1251
sqlplus %1 @s_meth_recomp_all.sql %1 %2
