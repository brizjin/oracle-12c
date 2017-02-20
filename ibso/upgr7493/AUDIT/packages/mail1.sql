prompt mail_mgr
create or replace package mail_mgr is
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/AUD/mail1.sql $
 *  $Author: Alexey $
 *  $Revision: 15071 $
 *  $Date:: 2012-03-06 13:38:04 #$
 */
--
function  init_owner(p_owner varchar2) return pls_integer;
procedure reset_owner(p_owner varchar2);
--
procedure set_notification(p_owner   varchar2, p_event   varchar2,
                           p_subject varchar2, p_message varchar2,
                           p_sender  varchar2, p_sender_name varchar2,
                           p_description varchar2);
procedure set_notification_status(p_owner varchar2, p_event varchar2, p_status varchar2);
--
procedure set_recipient(p_owner varchar2, p_event varchar2,
                        p_email varchar2, p_name  varchar2);
procedure set_recipient_status(p_owner varchar2, p_event  varchar2,
                               p_email varchar2, p_status varchar2);
--
procedure send_notify(p_owner varchar2, p_event varchar2,
                      p_subj1 varchar2, p_subj2 varchar2, p_subj3 varchar2,
                      p_mes1  varchar2, p_mes2  varchar2, p_mes3  varchar2,
                      p_mes4  varchar2, p_mes5  varchar2, p_mes6  varchar2,
                      p_mes7  varchar2, p_mes8  varchar2, p_mes9  varchar2);
--
procedure send_notify(p_owner varchar2, p_event varchar2, p_subj varchar2, p_body CLOB);
--
end;
/
show err

