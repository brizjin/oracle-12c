-- System constraints
@@sys_constr
-- System triggers
@@sys_trig

-- Перестроение системных ролей
spool LOG\grants.log
@@grants
@@setts
spool off

-- Измeнения от версии 7.2
spool log\after72.log
@v72\c_after
spool off

