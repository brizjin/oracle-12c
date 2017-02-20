rem var uVersion varchar2(2000); -- must define before use this script
rem lVersion varchar2(100); -- must define before use this script

var can_run_patch number
declare
	upver varchar2(2000);
	locver varchar2(100);
	str varchar2(100);
begin
	locver := ','||:lVersion||',';
	upver := ','||:uVersion||',';
	:can_run_patch := 0;
	str := locver;
	while locver is not null loop
		if instr(upver,str) != 0 or upver = ',*,' then
			:can_run_patch := 1;
			exit;
		end if;
		locver := substr(locver,1,instr(locver,'.',-1)-1);
		str := locver||'.*,';
	end loop;
end;
/
