VER2
REM ������ ���������
REM IBS@CORE2PLP
REM ������ ��: 7.3.0.0
REM ������ �������������� ��������: 6.87.0.11

CRIT USER VW_CRIT_USER_GROUPS
CRIT USER VW_CRIT_USER_USERS
IDX USER IDX_Z#USER_USERNAME
METH USER OP_UA_GROUP
METH USER OP_UA_USER
TYPE USERS   '�������� �������
ATTR USERS NAME
ATTR USERS PROPERTIES
ATTR USERS TYPE
ATTR USERS USERNAME
TYPE USERS_ES   '�������� ������� (��������)
CRIT USERS_ES VW_CRIT_EQUAL_SUBJ
TYPE USERS_ES_REF   '������ �� "�������� ������� (��������)"
TYPE USERS_G   '�������� ������� (������)
CRIT USERS_G VW_CRIT_GROUPS
TYPE USERS_G_REF   '������ �� "�������� ������� (������)"
TYPE USERS_SE   '�������� ������� (����������)
CRIT USERS_SE VW_CRIT_SUBJ_EQUAL
TYPE USERS_SE_REF   '������ �� "�������� ������� (����������)"
TYPE USERS_U   '�������� ������� (������������)
CRIT USERS_U VW_CRIT_USERS
TYPE USERS_U_REF   '������ �� "�������� ������� (������������)"
