rem Строка запуска Sql Plus 
rem параметры   - имя скрипта, параметр скрипта (если есть)
@echo off
sqlplusw ibs@test @%1 %2
