-- System constraints
@@sys_constr
-- System triggers
@@sys_trig

-- ������������ ��������� �����
spool LOG\grants.log
@@grants
@@setts
spool off

-- ���e����� �� ������ 7.2
spool log\after72.log
@v72/c_after
spool off

