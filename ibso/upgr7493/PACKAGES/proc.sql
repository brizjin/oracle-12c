prompt open_session
create or replace
function open_session(p_os_user varchar2,
                      p_domain varchar2,
                      p_retry varchar2 := null,
                      p_lock_touch_service varchar2 := '1',
                      p_host_sid varchar2 := null,
                      p_host_name varchar2 := null) return pls_integer is
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/proc.sql $
 *  $Author: kurkin $
 *  $Revision: 56852 $
 *  $Date:: 2014-12-02 16:51:45 #$
 */
begin
    return session_service.open_session_3L(p_os_user, p_domain, p_retry, p_lock_touch_service, p_host_sid, p_host_name);
end;
/
sho err

prompt close_session
create or replace
procedure close_session(p_id pls_integer) is
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/proc.sql $
 *  $Author: kurkin $
 *  $Revision: 56852 $
 *  $Date:: 2014-12-02 16:51:45 #$
 */
begin
    session_service.close_session(p_id);
end;
/
sho err

prompt kill_session
create or replace
procedure kill_session(p_sid pls_integer, p_serial pls_integer) is
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/proc.sql $
 *  $Author: kurkin $
 *  $Revision: 56852 $
 *  $Date:: 2014-12-02 16:51:45 #$
 */
begin
    session_service.kill_session(p_sid, p_serial);
end;
/
sho err

prompt init_session
create or replace
procedure init_session(p_id pls_integer, p_os_user varchar2,
                       p_domain varchar2, p_class varchar2 default null, p_nls_init boolean:=false) is
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/proc.sql $
 *  $Author: kurkin $
 *  $Revision: 56852 $
 *  $Date:: 2014-12-02 16:51:45 #$
 */
begin
    session_initialization_service.init_session_heavy(p_id, p_os_user, p_domain, p_class, p_nls_init);
end;
/
sho err

prompt finit_session
create or replace
procedure finit_session(p_reset varchar2 default null) is
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/proc.sql $
 *  $Author: kurkin $
 *  $Revision: 56852 $
 *  $Date:: 2014-12-02 16:51:45 #$
 */
begin
    session_initialization_service.finit_session(p_reset);
end;
/
sho err

prompt finit_session_light
create or replace
procedure finit_session_light(p_reset varchar2 default null) is
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/proc.sql $
 *  $Author: kurkin $
 *  $Revision: 56852 $
 *  $Date:: 2014-12-02 16:51:45 #$
 */
begin
    session_initialization_service.finit_session_light(p_reset);
end;
/
sho err

