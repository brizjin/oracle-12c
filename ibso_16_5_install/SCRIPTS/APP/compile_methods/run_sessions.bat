rem �� �㦥��� bat-䠩�, ����᪠���� ��⮬���᪨
rem ��� ����᪠ �������⮪���� �������樨 ����室��� ����᪠�� start_compile.bat
@echo ��ࠬ���� ����᪠
@echo run_sessions.bat [��ப� �室�] [������⢮ ��⮪�� �������樨]

@echo off
if NOT "%1"=="" goto CHECK
@echo �� 㪠���� ��ப� �室�
@echo �ਬ��: run_sessions.bat ibs/pasw@ibso 4
exit

:CHECK
if NOT "%2"=="" goto CHECK2
@echo �� 㪠���� ������⢮ ��⮪�� �������樨
@echo �ਬ��: run_sessions.bat ibs/pasw@ibso 4
exit

:CHECK2
if NOT "%3"=="" goto OK
for /L %%F in (1,1,%2) do start /MIN sqlplus %1 @compile1.sql

:OK
