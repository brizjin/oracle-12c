rem Это служебный bat-файл, запускается автоматически
rem Для запуска многопотоковой компиляции необходимо запускать start_compile.bat
@echo Параметры запуска
@echo run_sessions.bat [строка входа] [количество потоков компиляции]

@echo off
if NOT "%1"=="" goto CHECK
@echo Не указана строка входа
@echo Пример: run_sessions.bat ibs/pasw@ibso 4
exit

:CHECK
if NOT "%2"=="" goto CHECK2
@echo Не указано количество потоков компиляции
@echo Пример: run_sessions.bat ibs/pasw@ibso 4
exit

:CHECK2
if NOT "%3"=="" goto OK
for /L %%F in (1,1,%2) do start /MIN sqlplus %1 @compile1.sql

:OK
