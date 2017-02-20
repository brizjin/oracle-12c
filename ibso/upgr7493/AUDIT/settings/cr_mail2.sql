def smtpsrv=smtphost
def encoding=CL8KOI8R
def sender=AUD@AUD
def recpt=Revisor@AUD
def status=INACTIVE

spool cr_mail_note.log

set termout off
column xxx new_value owner noprint
select upper('&&owner') xxx from dual;
column xxx new_value SMTPSRV noprint
select value xxx from settings where owner='&&owner' and name='MAIL_SERVER';
column xxx new_value ENCODING noprint
select value xxx from settings where owner='&&owner' and name='MAIL_ENCODING';
column xxx new_value SENDER noprint
select value xxx from settings where owner='&&owner' and name='MAIL_DEF_SENDER';
column xxx new_value SNAME noprint
select value xxx from settings where owner='&&owner' and name='MAIL_DEF_SENDER_NAME';
column xxx new_value AUTH noprint
select value xxx from settings where owner='&&owner' and name='MAIL_AUTH';
column xxx new_value SUSER noprint
select value xxx from settings where owner='&&owner' and name='MAIL_USER';
column xxx new_value PASS noprint
select value xxx from settings where owner='&&owner' and name='MAIL_PASS';
column xxx new_value STATUS noprint
select status xxx from notifications where owner='&&owner' and event='CONNECT';
set termout on

rem prompt
rem prompt Base settings
rem select * from settings where name like 'MAIL%';

accept RECPT    char format a30 prompt 'Main recipient email [&&RECPT]: '  default &&RECPT
accept RNAME    char format a30 prompt 'Main recipient name  [&&RECPT]: '  default &&RECPT

prompt
prompt CONNECT notifications

accept STATUS   char format a30 prompt 'Status for CONNECT notifications [&&STATUS]: '  default &&STATUS

exec mail_mgr.set_notification('&&Owner','CONNECT','LOGON_SUCCESS','LOGON_SUCCESS','&&Sender','&&Sname','Событие входа привилегированным пользователем')
exec mail_mgr.set_notification_status('&&Owner','CONNECT','&&Status')
exec mail_mgr.set_recipient('&&Owner','CONNECT','&&Recpt','&&Rname')

exec mail_mgr.set_notification('&&Owner','BAD_CONNECT','LOGON_ERROR','LOGON_ERROR','&&Sender','&&Sname','Событие ошибки входа привилегированным пользователем')
exec mail_mgr.set_notification_status('&&Owner','BAD_CONNECT','&&Status')
exec mail_mgr.set_recipient('&&Owner','BAD_CONNECT','&&Recpt','&&Rname')

exec mail_mgr.set_notification('&&Owner','LOGON_WARNING','LOGON_WARNING','LOGON_WARNING','&&Sender','&&Sname','Отчёт о неуспешных входах')
exec mail_mgr.set_notification_status('&&Owner','LOGON_WARNING','&&Status')
exec mail_mgr.set_recipient('&&Owner','LOGON_WARNING','&&Recpt','&&Rname')

prompt
prompt EDOC_BAD_PKDB notification

accept STATUS   char format a30 prompt 'Status for EDOC_BAD_PKDB notification [&&STATUS]: '  default &&STATUS

exec mail_mgr.set_notification('&&Owner','EDOC_BAD_PKDB','EDOC_BAD_PKDB','EDOC_BAD_PKDB','&&Sender','&&Sname','Событие ошибки проверки целостности БОК')
exec mail_mgr.set_notification_status('&&Owner','EDOC_BAD_PKDB','&&Status')
exec mail_mgr.set_recipient('&&Owner','EDOC_BAD_PKDB','&&Recpt','&&Rname')

commit;

select * from notifications order by owner,event;
select * from recipients order by owner,event;

spool off
