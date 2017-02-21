rem *********************************************************
rem ��������� �������� ������������ ������ �����
rem ����������� ��-��� SQL*Plus
rem *********************************************************
set termout on
define V_VERSION = &&v_version --ACCEPT V_VERSION PROMPT 'IBSO version (&&v_version) :' default &&v_version
define PATH = &&PATH --ACCEPT PATH   PROMPT 'Catalog for generating scripts (&&PATH) :' default &&PATH
define GOWNER = IBS
define TSTAB = T_USR
define TSIDX = I_USR

@@c_prt
