prompt job_wrapper
create or replace package
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/job_wrapper1.sql $
 *  $Author: minas $
 *  $Revision: 26379 $
 *  $Date:: 2013-04-09 15:30:17 #$
 */
job_wrapper is
    
JOB_ERROR_NUMBER constant integer := -20001;
JOB_ERROR exception;
PRAGMA EXCEPTION_INIT(JOB_ERROR, -20001);

/** тип задания */
subtype job_type is pls_integer;

JOB_REFRESH constant job_type := 0;
JOB_EVENTS  constant job_type := 1;

type job_list is table of dba_jobs%rowtype index by binary_integer;

function submit(p_job_type job_type, p_instance pls_integer := null, p_single_mode boolean := true, p_autonomous boolean := false) return job_list;

function get(p_job dba_jobs.job%type) return dba_jobs%rowtype;
function get(p_job_type job_type, 
             p_instance pls_integer) return dba_jobs%rowtype;

procedure remove(p_job dba_jobs.job%type);
function remove(p_job_type job_type, 
                p_skip_job dba_jobs.job%type := null, 
                p_instance pls_integer := null) return job_list;

procedure hold(p_job dba_jobs.job%type);
function hold(p_job_type job_type, 
              p_skip_job dba_jobs.job%type := null, 
              p_instance pls_integer := null) return job_list;

procedure unhold(p_job dba_jobs.job%type);
function unhold(p_job_type job_type, 
                p_skip_job dba_jobs.job%type := null, 
                p_instance pls_integer := null) return job_list;

procedure lock_job(p_job_type job_type, p_instance pls_integer := null);
procedure release_job(p_job_type job_type, p_instance pls_integer := null);

end job_wrapper;
/
show errors
