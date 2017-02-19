@echo off
if .%1==. goto f
if .%2==. goto f
 sqlplusw %1 @ss %2 %2_body.sql 2
 sqlplusw %1 @ss %2 %2_spec.sql 1
 goto e
:f
 @echo Выкачивает произвольный пакет 
 @echo Не указана строка входа или имя пакета
 @echo Пример: anypaket.bat rus/rus@ibso FDP
:e