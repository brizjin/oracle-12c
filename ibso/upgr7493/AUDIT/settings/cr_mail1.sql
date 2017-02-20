def smtpsrv=smtphost
def encoding=CL8KOI8R
def sender=AUD@AUD
def AUTH=NO

spool cr_mail_settings.log


set termout off
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
set termout on

prompt
accept SMTPSRV  char format a30 prompt 'Email SMTP server [&&SMTPSRV]: ' default &&SMTPSRV
accept ENCODING char format a30 prompt 'Encoding characterset [&&ENCODING]: ' default &&ENCODING
accept SENDER   char format a30 prompt 'Default sender email [&&SENDER]: ' default &&SENDER
accept SNAME    char format a30 prompt 'Default sender name  [&&SENDER]: ' default &&SENDER
accept AUTH     char format a30 prompt 'Default email auth  [&&AUTH]: '  default &&AUTH
accept SUSER    char format a30 prompt 'Default email user  [&&SUSER]: ' default &&SUSER
accept PASS     char format a30 prompt 'Default email pass  [&&PASS]: '  default &&PASS

prompt
prompt Base settings
exec utils.set_value('&&Owner','MAIL_SERVER','&&Smtpsrv','Сервер отправки почты (SMTP server)')
exec utils.set_value('&&Owner','MAIL_ENCODING','&&Encoding','Кодировка текстов email-сообщений')
exec utils.set_value('&&Owner','MAIL_DEF_SENDER','&&Sender','Умолчательный email-адрес отправителя сообщений')
exec utils.set_value('&&Owner','MAIL_DEF_SENDER_NAME','&&Sname','Умолчательное имя отправителя сообщений')
exec utils.set_value('&&Owner','MAIL_AUTH','&&AUTH' ,'Авторизация на SMTP сервере(YES/NO)')
exec utils.set_value('&&Owner','MAIL_USER','&&SUSER','Логин для авторизации на SMTP сервере')
exec utils.set_value('&&Owner','MAIL_PASS','&&PASS' ,'Пароль для авторизации на SMTP сервере')

commit;       
                                               
select * from settings where name like 'MAIL%';

spool off
