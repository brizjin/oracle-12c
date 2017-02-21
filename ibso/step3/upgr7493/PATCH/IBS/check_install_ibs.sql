set feedback off

var uVersion varchar2(1000);
var lVersion varchar2(100);
exec :uVersion := '&&UPGRADED_VERSION';
exec :lVersion := inst_info.Get_Version;

@@UTILS/check_version

var mess varchar2(1000)
begin
	if :can_run_patch = 0 then
		:mess := '!!!��������!!!'||chr(10)||
		'������� ������ �� '||:lVersion||' �� ��������� ��������� ���� �����-��������� IBSO!'||chr(10)||
		'��������� ������ �������.';
	else
		:mess := '������� ������ �� '||:lVersion||' ��������� ��������� ���� �����-��������� IBSO.';
	end if;
end;
/

set feedback on
