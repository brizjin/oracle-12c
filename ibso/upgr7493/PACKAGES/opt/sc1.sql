var mess varchar2(1000)
var load_sc varchar2(1)

declare
sc_version  varchar2(100) := null;
begin
    :load_sc := '1';
    :mess := 'На схеме не установлен функционал "Машина тестирования".'||chr(10)||
             'Устанавливаем стандартный пакет SC_MGR из дистрибутива.';
             
	begin
		execute immediate '
			begin
				:result:= opt_mgr.calc_version(''CORE_MT'');
			end;' using out sc_version;
	exception when others then null;
	end;
             
	if sc_version is not null then
		:load_sc := '0';
		:mess := 'На схеме установлен функционал "Машина тестирования".'||chr(10)||
					'Оставляем пакет SC_MGR без изменений.';
	end if;
end;
/

column xxx new_value sc_spec noprint
select decode(:load_sc, '1', 'sc_mgr1.sql','dummy') xxx from dual;

column xxx new_value sc_body noprint
select decode(:load_sc, '1', 'sc_mgr2.sql','dummy') xxx from dual;

print mess
