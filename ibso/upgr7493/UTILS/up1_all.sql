set feedback on
set term on

-- ���������� �������� �����������
spool LOG\updtbl.lst
@@upd_tbl
@@alt_sys_disable_restricted_session
spool off

-- �������� �������� �����������
column xxx new_value ConnStr noprint
select :constr xxx from dual;
host tblload.bat &&ConnStr
undef ConnStr

-- ���e����� �� ������ 6.X
spool log\v6X.log
@@alt_sys_enable_restricted_session
@v6X/c_all
spool off

-- ���e����� �� ������ 7.0
spool log\v70.log
@v70/c_all
spool off

-- ���e����� �� ������ 7.1
spool log\v71.log
@v71/c_all
spool off

-- ���e����� �� ������ 7.2
spool log\v72.log
@v72/c_all
spool off

define path=compile
@tbl/c_prt

--
-- ���������� �������� �� ���������� �������
@packages/opt/before_install_pkg

--
-- ���������� �������
spool LOG\kernpkg.lst
@@syn
@packages/kernpkg
spool off

--
-- ���������� �������� ����� ���������� �������
@packages/opt/after_install_pkg

rem prompt optional pause
rem pause
