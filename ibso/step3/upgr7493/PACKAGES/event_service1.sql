prompt event_service
create or replace package
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/event_service1.sql $
 *  $Author: VKazakov $
 *  $Revision: 16948 $
 *  $Date:: 2012-10-01 17:30:09 #$
 */
event_service is

EVENT_ERROR_NUMBER constant integer := -20001;
EVENT_ERROR exception;
PRAGMA EXCEPTION_INIT(EVENT_ERROR, -20001);

procedure send(pipe_name varchar2, p_repeat boolean := false);

procedure sendevent(p_node pls_integer, p_time date, p_user_id pls_integer,
                    p_post_uid pls_integer, p_post_sid pls_integer, p_post_node pls_integer,
                    p_id pls_integer, p_event varchar2, p_autonom boolean);
                    
procedure job;

end event_service;
/
show errors
