prompt RUNPROC_MGR
create or replace package RUNPROC_MGR as
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/Core/Utils/RUNPROC/Run_mgr1.sql $
 *  $Author: Alexey $
 *  $Revision: 15078 $
 *  $Date:: 2012-03-06 14:53:24 #$
 */
--
    function  run_server(p_check boolean default true)  return pls_integer;
    function  find_job return number;
    procedure stop_job(p_quit boolean default false);
    procedure submit_job;
    procedure run_job ( p_job number, p_date in out nocopy date, p_broken in out nocopy boolean );
--
end RUNPROC_MGR;
/
sho err

