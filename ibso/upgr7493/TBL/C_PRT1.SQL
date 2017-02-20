rem *********************************************************
rem Генерация скриптов перестроения таблиц типов
rem Запускается из-под SQL*Plus
rem *********************************************************
set termout on
ACCEPT V_VERSION PROMPT 'IBSO version (&&v_version) :' default &&v_version
ACCEPT PATH   PROMPT 'Catalog for generating scripts (&&PATH) :' default &&PATH
ACCEPT GOWNER PROMPT 'Default IBSO tables global owner (IBS) :' default IBS
ACCEPT TSTAB  PROMPT 'USER  tablespace (T_USR):' default T_USR
ACCEPT TSIDX  PROMPT 'Index tablespace (I_USR):' default I_USR

@@c_prt
