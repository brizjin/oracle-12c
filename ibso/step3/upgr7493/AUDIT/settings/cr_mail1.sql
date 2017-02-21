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
define SMTPSRV = &&SMTPSRV --accept SMTPSRV  char format a30 prompt 'Email SMTP server [&&SMTPSRV]: ' default &&SMTPSRV
define ENCODING = &&ENCODING --accept ENCODING char format a30 prompt 'Encoding characterset [&&ENCODING]: ' default &&ENCODING
define SENDER = &&SENDER --accept SENDER   char format a30 prompt 'Default sender email [&&SENDER]: ' default &&SENDER
define SNAME = &&SENDER --accept SNAME    char format a30 prompt 'Default sender name  [&&SENDER]: ' default &&SENDER
define AUTH = &&AUTH --accept AUTH     char format a30 prompt 'Default email auth  [&&AUTH]: '  default &&AUTH
define SUSER = &&SUSER --accept SUSER    char format a30 prompt 'Default email user  [&&SUSER]: ' default &&SUSER
define PASS = &&PASS --accept PASS     char format a30 prompt 'Default email pass  [&&PASS]: '  default &&PASS

prompt
prompt Base settings
exec utils.set_value('&&Owner','MAIL_SERVER','&&Smtpsrv','������ �������� ����� (SMTP server)')
exec utils.set_value('&&Owner','MAIL_ENCODING','&&Encoding','��������� ������� email-���������')
exec utils.set_value('&&Owner','MAIL_DEF_SENDER','&&Sender','������������� email-����� ����������� ���������')
exec utils.set_value('&&Owner','MAIL_DEF_SENDER_NAME','&&Sname','������������� ��� ����������� ���������')
exec utils.set_value('&&Owner','MAIL_AUTH','&&AUTH' ,'����������� �� SMTP �������(YES/NO)')
exec utils.set_value('&&Owner','MAIL_USER','&&SUSER','����� ��� ����������� �� SMTP �������')
exec utils.set_value('&&Owner','MAIL_PASS','&&PASS' ,'������ ��� ����������� �� SMTP �������')

commit;       
                                               
select * from settings where name like 'MAIL%';

spool off
