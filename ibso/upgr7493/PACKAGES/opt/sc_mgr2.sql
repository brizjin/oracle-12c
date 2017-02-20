prompt SC_MGR body
create or replace package body
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/sc_mgr2.sql $
 *  $Author: kuvardin $
 *  $Revision: 44167 $
 *  $Date:: 2014-04-04 09:13:18 #$
 */

SC_MGR is
--

function enabled return boolean is
begin
  return false;
end;

procedure start_rec(p_commit_mode boolean default false, p_do_rollback boolean default false, p_info1 varchar2, p_info2 varchar2) is
begin
  null;
end;

procedure stop_rec is
begin
  null;
end;

procedure pause_rec is
begin
  null;
end;

procedure resume_rec is
begin
  null;
end;

function is_recording return boolean is
begin
  return false;
end;

procedure start_play(p_commit_mode boolean default false, p_do_rollback boolean default false, p_info1 varchar2, p_info2 varchar2) is
begin
  null;
end;

procedure stop_play is
begin
  null;
end;

procedure set_ids(p_arr "CONSTANT".MEMO_TABLE, p_set varchar2 default '1') is
begin
  null;
end;

function protected return boolean is
begin
  return false;
end;

procedure start_protect is
begin
  null;
end;

procedure stop_protect is
begin
  null;
end;

procedure start_fio_logging is
begin
  null;
end;

procedure stop_fio_logging is
begin
  null;
end;

procedure pause_fio_logging is
begin
  null;
end;

procedure resume_fio_logging is
begin
  null;
end;

procedure start_restore(p_info1 varchar2, p_info2 varchar2) is
begin
  null;
end;

procedure pause_repl is
begin
  null;
end;

procedure resume_repl is
begin
  null;
end;

function is_playing return boolean is
begin
  return false;
end;

function is_testing return boolean is
begin
  return false;
end;

function is_fio_logging return boolean is
begin
  return false;
end;

procedure install is
begin
  null;
end;
function rec_play (p_refresh boolean) return boolean is
begin
  return false;
end;

procedure refresh_sessions is
begin
  null;
end;

procedure delete_session is
begin
  null;
end;

procedure write_log(mid varchar2, procname varchar2, aParams "CONSTANT".REFSTRING_TABLE, aValues "CONSTANT".STRING_TABLE,p_force boolean default false,
                    p_ext_logging boolean default false, p_t timestamp default null) is
begin
  null;
end;

procedure write_log(mid varchar2, procname varchar2,
                    Param1 varchar2, Value1 varchar2,
                    Param2 varchar2 default null, Value2 varchar2  default null,
                    Param3 varchar2 default null, Value3 varchar2  default null,
                    Param4 varchar2 default null, Value4 varchar2  default null,
                    Param5 varchar2 default null, Value5 varchar2  default null,
                    p_force boolean default false, p_ext_logging boolean default false, p_t timestamp default null) is
begin
  null;
end;

procedure add_log(aParams "CONSTANT".REFSTRING_TABLE, aValues "CONSTANT".STRING_TABLE) is
begin
  null;
end;
--
procedure add_log(  Param1 varchar2, Value1 varchar2,
                    Param2 varchar2 default null, Value2 varchar2  default null,
                    Param3 varchar2 default null, Value3 varchar2  default null,
                    Param4 varchar2 default null, Value4 varchar2  default null,
                    Param5 varchar2 default null, Value5 varchar2  default null) is
begin
  null;
end;
--
procedure write_coll(p_coll varchar2, p_class varchar2, p_value varchar2) is
begin
  null;
end;
--
function idx_by_qual(p_meth_id varchar2, p_qual varchar2, p_type varchar2 default null) return pls_integer is
begin
  return null;
end;

function qual_by_var(p_meth_id varchar2, p_var varchar2) return varchar2 is
begin
  return null;
end;

--
procedure get_param(p_meth_id varchar2, p_action varchar2, p_parname varchar2,p_value varchar2,
                    aValues out "CONSTANT".MEMO_TABLE,
                    aTypes  out "CONSTANT".MEMO_TABLE,
                    aQuals  out "CONSTANT".MEMO_TABLE,
                    aIdx out "CONSTANT".INTEGER_TABLE) is
begin
  null;
end;

procedure get_grid_param(p_meth_id varchar2, p_ind pls_integer, p_value in out NOCOPY varchar2,
                    p_command out varchar2,
                    aNames out "CONSTANT".MEMO_TABLE,
                    aValues out "CONSTANT".MEMO_TABLE) is
begin
  null;
end;



function get_num_lines(p_class varchar2, p_short_name varchar2) return pls_integer is
begin
  return 0;
end;

procedure log_open_file (handle pls_integer, path varchar2, open_mode varchar2)is
begin
  null;
end;

procedure log_close_file (handle pls_integer)is
begin
  null;
end;

function  log_file_name(p_name varchar2, p_on_client varchar2) return varchar is
begin
  return null;
end;

procedure set_name(p_on_client varchar2, p_name varchar2)is
begin
  null;
end;

procedure clear_names is
begin
  null;
end;

procedure update_sessions(p_mode_ses varchar2,p_set boolean,p_info1 varchar2,p_info2 varchar2) is
begin
  null;
end;

-- Фунцкии для проверки возможности запуска теста, если уже запущен другой тест
procedure clear_test_information(p_info1 varchar2, p_mode_ses varchar2 DEFAULT NULL) is
begin
  null;
end;

procedure deleteSession(p_sid number) is
begin
  null;
end;
--
end;
/
show err package body sc_mgr
