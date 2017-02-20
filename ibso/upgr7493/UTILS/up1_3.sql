set feedback on
set term on

-- Обновление словарей компилятора
spool LOG\updtbl.lst
@@upd_tbl
@@alt_sys_disable_restricted_session
spool off

-- Загрузка словарей компилятора
column xxx new_value ConnStr noprint
select :constr xxx from dual;
host tblload.bat &&ConnStr
undef ConnStr

-- Измeнения от версии 7.0
spool log\v70.log
@@alt_sys_enable_restricted_session
@v70\c_all
spool off

-- Измeнения от версии 7.1
spool log\v71.log
@v71\c_all
spool off

-- Измeнения от версии 7.2
spool log\v72.log
@v72\c_all
spool off

define path=compile
@tbl\c_prt

--
-- Выполнение скриптов до обновления пакетов
@packages\opt\before_install_pkg

--
-- Обновление пакетов
spool LOG\kernpkg.lst
@@syn
@packages\kernpkg
spool off

--
-- Выполнение скриптов после обновления пакетов
@packages\opt\after_install_pkg

rem prompt optional pause
rem pause
