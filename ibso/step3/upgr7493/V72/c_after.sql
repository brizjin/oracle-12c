set echo on

exec storage_mgr.verbose:=true
exec storage_mgr.pipe_name:='DEBUG';
exec storage_utils.verbose:=true
exec storage_utils.pipe_name:='DEBUG';

exec secadmin.update_subj_equal;
exec storage_utils.ws('Last USER ID = '||secadmin.fill_userid);
commit;

exec Security.init_rights_context('<ALL>');
exec secadmin.ReportRightsCare;

var s varchar2(1000)
exec :s := 'ORSA_JOBS rows deleted: '||report_mgr.clear_orsa_jobs(null)
commit;
exec storage_utils.ws(:s)
print s

delete orsa_jobs j where not exists
  (select 1 from users u where u.username=j.username);
commit;

delete orsa_jobs j where not exists
  (select 1 from classes c where c.id=j.class_id);
commit;

delete orsa_jobs j where not exists
  (select 1 from methods m where m.id=j.method_id);
commit;

delete orsa_jobs_par p where not exists
  (select 1 from orsa_jobs j where j.job=p.job and j.pos=p.pos);
commit;

delete orsa_jobs_out o where not exists
  (select 1 from orsa_jobs j where j.job=o.job and j.pos=o.pos);
commit;

set echo off

