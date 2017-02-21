prompt SC_MGR
create or replace package sc_mgr is
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/sc_mgr1.sql $
 *  $Author: kuvardin $
 *  $Revision: 44167 $
 *  $Date:: 2014-04-04 09:13:18 #$
 */

-- ����������� ����������� ��
function enabled return boolean;

-- ������� � ����� ������ �����
-- ��������� ���������� � ������ � ������� SC_SESSIONS:
-- � ������� mode_ses ���������� � ������ ������ ������:
-- REC - ������ �����
-- PLAY - ��������������� �����
-- RESTORE - ����� ���������
-- � ������� info1 - ID ��������, � info2 - ID ������
-- ���� � sc_sessions ��� ���������� � ������� ������, �� ��� ���������� ����� ��������� � ������� mode_ses='PLAY'
procedure start_rec(p_commit_mode boolean default false, p_do_rollback boolean default false, p_info1 varchar2, p_info2 varchar2);

-- ��������� ����� ������ �����
procedure stop_rec;
-- ������������� ����� ������ �����
procedure pause_rec;
-- ���������� ������ �����
procedure resume_rec;

-- ������� � ����� ��������������� �����
-- ���� � sc_sessions ��� ���������� � ������� ������, �� ��� ���������� ����� ��������� � ������� mode_ses='PLAY'
procedure start_play(p_commit_mode boolean default false, p_do_rollback boolean default false, p_info1 varchar2, p_info2 varchar2);

-- ��������� ����� ��������������� �����
procedure stop_play;

-- �������� ������ �����������
procedure start_protect;
-- ��������� ������ �����������
procedure stop_protect;
-- ���������� �������, ��� ������� ����� ������ �����������
function protected return boolean;
-- ��������� � ���������� ��������� �� ����������� � ������� p_arr ������ ID ���������� �����������
-- �������� ������ ���������� p_set(1-������� �� ���������, 0-����� ������ )
procedure set_ids(p_arr "CONSTANT".MEMO_TABLE, p_set varchar2 default '1');

-- �������� �������������� ������ � �������
procedure start_fio_logging;
-- ��������� �������������� ������ � �������
procedure stop_fio_logging;
-- ������������� �������������� ������ � �������
procedure pause_fio_logging;
-- ���������� �������������� ������ � �������
procedure resume_fio_logging;

-- ������� � ����� �������������� ������
-- ���� � sc_sessions ��� ���������� � �������� ������, �� ��� ���������� ����� ��������� � ������� mode_ses='RESTORE'
procedure start_restore(p_info1 varchar2, p_info2 varchar2);

-- ������������� �������������� ��������� � ��
procedure pause_repl;
-- ���������� �������������� ��������� � ��
procedure resume_repl;

-- ���������� �������, ��� � ������� ������ ������� ����� ������ �����
function is_recording return boolean;
-- ���������� �������, ��� � ������� ������ ������� ����� ��������������� �����
function is_playing return boolean;
-- ���������� �������, ��� � ������� ������ ������� ������ � �������
function is_testing return boolean;
-- ���������� �������, ��� � ������� ������ ������� �������������� ������ � �������
function is_fio_logging return boolean;


-- �������� ����������� ��������� ��� �� (������������ ������ ��� ��������� ��)
procedure install;


-- �������� ������� ������, � ������� ������������ ������ ��� ��������������� ������
-- ��� p_refresh==true ��������� ���������� � �������������������� �������
function rec_play (p_refresh boolean) return boolean;
-- ������ ���������� � �������������������� �������
procedure refresh_sessions;
-- �������� ���������� � ������� ������ �� ������� sc_sessions
-- ������ �������� ������ �� sc_sessions �� ��������� � ����������� ������ ������ � ���������������
-- �.�. ���������� ��������� ��������� �������� ��� ����� ���������� ������
procedure delete_session;

-- �������������� �������� ������������ ��� ������ �����
procedure write_log(mid varchar2, procname varchar2, aParams "CONSTANT".REFSTRING_TABLE, aValues "CONSTANT".STRING_TABLE,p_force boolean default false,
                    p_ext_logging boolean default false, p_t timestamp default null);
procedure write_log(mid varchar2, procname varchar2,
                    Param1 varchar2, Value1 varchar2,
                    Param2 varchar2 default null, Value2 varchar2  default null,
                    Param3 varchar2 default null, Value3 varchar2  default null,
                    Param4 varchar2 default null, Value4 varchar2  default null,
                    Param5 varchar2 default null, Value5 varchar2  default null,
                    p_force boolean default false, p_ext_logging boolean default false, p_t timestamp default null);

-- �������������� �������������� �������� ���������� ����������� �������� � �������� SET ��� ������ �����
procedure add_log(aParams "CONSTANT".REFSTRING_TABLE, aValues "CONSTANT".STRING_TABLE);
procedure add_log(  Param1 varchar2, Value1 varchar2,
                    Param2 varchar2 default null, Value2 varchar2  default null,
                    Param3 varchar2 default null, Value3 varchar2  default null,
                    Param4 varchar2 default null, Value4 varchar2  default null,
                    Param5 varchar2 default null, Value5 varchar2  default null);
-- ���������� ���������� �� ��������������� ��������������������� ��������� ��� ������ �����
procedure write_coll(p_coll varchar2, p_class varchar2, p_value varchar2);

-- ������� ��� ��������� �������� (������������� ����������� method_mgr)
function idx_by_qual(p_meth_id varchar2, p_qual varchar2, p_type varchar2 default null) return pls_integer;
function qual_by_var(p_meth_id varchar2, p_var varchar2) return varchar2;
procedure get_param(p_meth_id varchar2, p_action varchar2, p_parname varchar2,p_value varchar2,
                    aValues out "CONSTANT".MEMO_TABLE,
                    aTypes  out "CONSTANT".MEMO_TABLE,
                    aQuals  out "CONSTANT".MEMO_TABLE,
                    aIdx out "CONSTANT".INTEGER_TABLE);
procedure get_grid_param(p_meth_id varchar2, p_ind pls_integer, p_value in out NOCOPY varchar2,
                    p_command out varchar2,
                    aNames out "CONSTANT".MEMO_TABLE,
                    aValues out "CONSTANT".MEMO_TABLE);

-- ��������� ���������� ������������� ����� � ������ ��������
function get_num_lines(p_class varchar2, p_short_name varchar2) return pls_integer;

-- ������� ��� �������������� ������ � �������
procedure log_open_file (handle pls_integer, path varchar2, open_mode varchar2);
procedure log_close_file (handle pls_integer);
function  log_file_name(p_name varchar2, p_on_client varchar2) return varchar;
procedure set_name(p_on_client varchar2, p_name varchar2);
procedure clear_names;
procedure update_sessions(p_mode_ses varchar2,p_set boolean,p_info1 varchar2,p_info2 varchar2);

-- ������� ��� �������� ����������� ������� �����, ���� ��� ������� ������ ����
procedure clear_test_information(p_info1 varchar2, p_mode_ses varchar2 DEFAULT NULL);

-- ������� ��� ������� ������ ������ � ������ ������ ��� ��������������� ����� ��� ����� �������������� ������ ��� ��������������� �����(��.: ������� ���������� Oracle)
procedure deleteSession(p_sid number);
end SC_MGR;
/
show err

