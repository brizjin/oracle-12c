exec dbms_session.reset_package
exec executor.setnlsparameters
exec stdio.enable_buf(1000000)
exec stdio.put_line_buf(rtl.open)
PROMPT Проверка описания системы с перекомпиляцией pl/plus блоков (system_options.get_sql)
var s varchar2(2000);
exec opt_mgr.check_options(null,:s,true);
exec stdio.put_line_buf(:S);
PROMPT Проверка лицензионных ограничений
exec stdio.put_line_buf('STATUS CHECK_SUM - ' || opt_mgr.check_value(null,true));
