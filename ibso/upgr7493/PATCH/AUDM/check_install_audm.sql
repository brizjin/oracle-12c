set feedback off

var uVersion varchar2(1000);
var lVersion varchar2(100);
exec :uVersion := '&&UPGRADED_VERSION';
exec :lVersion := &&IBSO_OWNER..inst_info.Get_Version;

@@UTILS\check_version

var mess varchar2(1000)
begin
	if :can_run_patch = 0 then
		:mess := '!!!ВНИМАНИЕ!!!'||chr(10)||
		'Текущая версия ТЯ '||:lVersion||' не позволяет выполнить патч схемы менеджера аудита!'||chr(10)||
		'Выполните полный апгрейд.';
	else
		:mess := 'Текущая версия ТЯ '||:lVersion||' позволяет выполнить патч схемы менеджера аудита.';
	end if;
end;
/

set feedback on
