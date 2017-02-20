set feedback off

var uVersion varchar2(1000);
var lVersion varchar2(100);
exec :uVersion := '&&UPGRADED_VERSION';
exec :lVersion := clear.full_version;

@@UTILS\check_version

var mess varchar2(1000)
begin
	if :can_run_patch = 0 then
		:mess := '!!!ВНИМАНИЕ!!!'||chr(10)||
		'Текущая версия схемы ревизора '||:lVersion||' не позволяет установить патч!'||chr(10)||
		'Выполните полный апгрейд схемы ревизора.';
	else
		:mess := 'Текущая версия схемы ревизора '||:lVersion||' позволяет установить патч.';
	end if;
end;
/

set feedback on
