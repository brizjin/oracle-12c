-- System constraints
@@sys_constr
-- System triggers
@@sys_trig

-- ������������ ��������� �����
spool LOG\grants.log
@@grants
@@setts
spool off

-- ���e����� �� ������ 7.0
spool log\after70.log
@v70\c_after
spool off

-- ���e����� �� ������ 7.1
spool log\after71.log
@v71\c_after
spool off

-- ���e����� �� ������ 7.2
spool log\after72.log
@v72\c_after
spool off

