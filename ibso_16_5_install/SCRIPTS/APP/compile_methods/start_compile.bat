@echo Параметры запуска
@echo start_compile.bat [строка входа] [количество потоков компиляции]
@echo рекомендуется устанавливать количество  потоков компиляции, равным числу процессоров на сервере Oracle
@echo В пароле владельца нельзя использовать символы-разделители (пробел, запятая)
@echo Необходимые файлы:
@echo run_sessions.bat - служебный bat файл для запуска потоков компиляции
@echo s_meth_recomp_all.sql - основной скрипт компиляции
@echo s_meth_recomp.sql - управление потоками компиляции
@echo compile1.sql - один поток компиляция 
@echo methods_info.sql - вывод информации о невалидных методах
@echo rtl_idx.sql - служебный скрипт для расчета индекса в rtl_entries

@echo off
if NOT "%1"=="" goto CHECK_P
@echo .
@echo Не указана строка входа {ИМЯ_ВЛАДЕЛЬЦА}/{ПАРОЛЬ_ВЛАДЕЛЬЦА}@{ИМЯ_СХЕМЫ}
@echo Пример: start_compile.bat ibs/pasw@ibso 4
exit

:CHECK_P
if NOT "%2"=="" goto OK
@echo .
@echo Не указано количество потоков компиляции
@echo Пример: start_compile.bat ibs/pasw@ibso 4
exit

:OK
chcp 1251
sqlplus %1 @s_meth_recomp_all.sql %1 %2
