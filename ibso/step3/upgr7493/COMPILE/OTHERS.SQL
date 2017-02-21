exec dbms_session.reset_package
exec executor.setnlsparameters
exec stdio.enable_buf(1000000)
exec stdio.enable_buf(10000000)
exec stdio.put_line_buf(rtl.open)
PROMPT Переcтроение правил
select count(1) from object_rights;
alter table OBJECT_RIGHTS nologging;
alter index IDX_OBJECT_RIGHTS_CLASS_ID nologging;
alter index IDX_OBJECT_RIGHTS_SUBJ_ID nologging;
alter index PK_OBJECT_RIGHTS_OID_SID_ nologging;
truncate table object_rights;
exec Rules.Create_All_Packages(true);
alter table OBJECT_RIGHTS logging;
alter index IDX_OBJECT_RIGHTS_CLASS_ID logging;
alter index IDX_OBJECT_RIGHTS_SUBJ_ID logging;
alter index PK_OBJECT_RIGHTS_OID_SID_ logging;
select count(1) from object_rights;
PROMPT Пересоздание системных представлений
EXEC SVIEWS.CREATE_ALL_SVIEWS;
EXEC SHORT_VIEWS.CREATE_ALL;
PROMPT Пересоздание критериев
exec storage_utils.verbose := true
exec storage_utils.pipe_name := 'DEBUG0'
EXEC AFTER_INSTALL.RECREATE_VW_CRIT('1');
EXEC DATA_VIEWS.SET_USERCONTEXT_USED;

