VER2
REM Список элементов
REM IBS@CORE2PLP
REM Версия ТЯ: 7.3.0.0
REM Версия Администратора проектов: 6.87.0.11

CRIT USER VW_CRIT_USER_GROUPS
CRIT USER VW_CRIT_USER_USERS
IDX USER IDX_Z#USER_USERNAME
METH USER OP_UA_GROUP
METH USER OP_UA_USER
TYPE USERS   'Субъекты доступа
ATTR USERS NAME
ATTR USERS PROPERTIES
ATTR USERS TYPE
ATTR USERS USERNAME
TYPE USERS_ES   'Субъекты доступа (Входящие)
CRIT USERS_ES VW_CRIT_EQUAL_SUBJ
TYPE USERS_ES_REF   'Ссылка на "Субъекты доступа (Входящие)"
TYPE USERS_G   'Субъекты доступа (Группы)
CRIT USERS_G VW_CRIT_GROUPS
TYPE USERS_G_REF   'Ссылка на "Субъекты доступа (Группы)"
TYPE USERS_SE   'Субъекты доступа (Включающие)
CRIT USERS_SE VW_CRIT_SUBJ_EQUAL
TYPE USERS_SE_REF   'Ссылка на "Субъекты доступа (Включающие)"
TYPE USERS_U   'Субъекты доступа (Пользователи)
CRIT USERS_U VW_CRIT_USERS
TYPE USERS_U_REF   'Ссылка на "Субъекты доступа (Пользователи)"
