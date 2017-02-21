prompt runproc_mgr
create or replace package runproc_mgr as
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/Run_mgr1.sql $
 *  $Author: Alexey $
 *  $Revision: 15072 $
 *  $Date:: 2012-03-06 13:41:17 #$
 */
--
    function  run_server(p_check boolean default true)  return pls_integer;
    function  find_job return number;
    procedure stop_job(p_quit boolean default false);
    procedure submit_job;
    procedure run_job ( p_job number, p_date in out nocopy date, p_broken in out nocopy boolean );
--
end runproc_mgr;
/
sho err

