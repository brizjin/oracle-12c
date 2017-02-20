prompt rcs_lock body
create or replace package body
/*
 *	$HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/RCS_LCK2.SQL $
 *  $Author: Alexey $
 *  $Revision: 15072 $
 *  $Date:: 2012-03-06 13:41:17 #$
 */
rcs_lock is
type str_table is table of varchar2(128) index by binary_integer;
type int_table is table of binary_integer index by binary_integer;
names   str_table; ---- массив имен блокировок (индекс: 1 .. locks_count).
handles str_table; ---- массив handle'ов блокировок (индекс: 1 .. locks_count).
states  int_table; ---- массив состояний блокировок (индекс: 1 .. locks_count).
locks_count binary_integer := 0; ---- число блокировок.

MSG_ALREADY_LOCKED_RESOURCE constant varchar2(100) := 'Блокировка ресурса уже установлена пользователем';
MSG_DEAD_LOCK constant varchar2(128) := 'Тупиковая ситуация при блокировке. Ресурс заблокирован пользователем %1 (сессия %2, компьютер %3) %4 сек...';
MSG_INSTANCE constant varchar2(20) := 'Экземпляр';
MSG_INVALID_ARGS constant varchar2(50) := 'Ошибка в параметрах dbms_lock.request';
MSG_INVALID_HANDLE constant varchar2(100) := 'Неверный дескриптор блокировки при вызове DBMS_LOCK.RELEASE';
MSG_IS_EDITED_BY_USER constant varchar2(50) := ' редактируется пользователем ';
MSG_LOCK_IS_NOT_FOUND constant varchar2(100) := 'Не найдена информация о блокировке %1 при конфликте...';
MSG_METHOD constant varchar2(20) := 'Операция';
MSG_CRITERION constant varchar2(20) := 'Представление';
MSG_NOT_LOCKED_RESOURCE constant varchar2(100) := 'Блокировка ресурса не была установлена пользователем';
MSG_RESOURCE constant varchar2(20) := 'Ресурс';
MSG_TYPE constant varchar2(20) := 'Тип';
MSG_USER constant varchar2(50) := '%1 (сессия %2, компьютер %3) %4 сек...';

procedure request(
    lock_name   in varchar2,
    lock_mode   in integer  default X_MODE,
    timeout     in integer  default 0,
    release_on_commit in boolean default FALSE,
    p_skip_4    in boolean  default FALSE,
    p_prefix    in varchar2 default null
    )
is
	lock_num binary_integer;
	i binary_integer;
	lock_handle varchar2(128);
begin
	status := null;
	orauser := null;
	userid := null;
	sessionid := null;
	username := null;
	usermachine := null;
	locktime := null;
	message := null;
	lock_num := null;

	for i in 1 .. locks_count loop
		begin
			if lock_name = names(i) then
				lock_num := i; exit;
			end if;
		exception
			when no_data_found then
				null;
		end;
	end loop;

	if lock_num is null then
		dbms_lock.allocate_unique(inst_info.owner || lock_name, lock_handle);
		locks_count := locks_count + 1;
		lock_num := locks_count;
		names(lock_num) := lock_name;
		handles(lock_num) := lock_handle;
		states(lock_num) := 0;  -- лок инициализирован
	end if;

    status := dbms_lock.request(handles(lock_num), lock_mode, timeout, release_on_commit);

	if status = 0 then
		states(lock_num) := 1;    -- лок установлен
	end if;

	if status = 1 or status = 2 then
		begin
			select s.username, s.machine, l.ctime, s.sid
			into orauser, usermachine, locktime, sessionid
			from v$lock l, v$session s
			where s.sid = l.sid
			  and l.id1 = substr(handles(lock_num),1,10)
			  and l.type = 'UL'
			;
            usermachine := replace(usermachine,chr(0));
		exception
			when no_data_found then
				message := replace(MSG_LOCK_IS_NOT_FOUND, '%1', handles(lock_num));
				raise_application_error(-20999, message);
		end;
	end if;

	if orauser is not null then
		begin
			select u.name into username
			from users u
			where u.username = orauser;
		exception
			when no_data_found then
				username := orauser;
				/*
				message := 'Пользователь ' || orauser
					||'(сессия '|| to_char(sessionid) ||', компьютер '|| usermachine ||
					'), заблокировавший ресурс, не зарегистрирован в системе!!!';
				raise_application_error(-20999, message);
				*/
		end;
	end if;

    if status = 1 then
        if p_prefix is null then
          if substr(lock_name,1,2) = 'O#' then
			message := MSG_INSTANCE;
          elsif substr(lock_name,1,2) = 'M#' then
			message := MSG_METHOD;
          elsif substr(lock_name,1,2) = 'C#' then
			message := MSG_TYPE;
          elsif substr(lock_name,1,3) = 'VW#' then
			message := MSG_CRITERION;
          else
			message := MSG_RESOURCE;
          end if;
          message := message  || MSG_IS_EDITED_BY_USER;
        else
          message := p_prefix;
        end if;
        message := message || replace(replace(replace(replace(MSG_USER,
            '%1', username), '%2', to_char(sessionid)), '%3', usermachine), '%4', to_char(locktime));
	elsif status = 2 then
		message := replace(replace(replace(replace(MSG_DEAD_LOCK,
            '%1', username), '%2', to_char(sessionid)), '%3', usermachine), '%4', to_char(locktime));
	elsif status = 3 then
		message := MSG_INVALID_ARGS;
	elsif status = 4 then
        if p_skip_4 then
            status := 0;
        else
            message:= MSG_ALREADY_LOCKED_RESOURCE;
        end if;
	elsif status = 5 then
		message := MSG_INVALID_HANDLE;
	end if;
	if status <> 0 then
		raise_application_error(-20990 - status, message);
	end if;
end;

procedure release(lock_name varchar2, p_skip_4 boolean default FALSE) is
	i binary_integer;
	lock_handle varchar2(128);
	lock_num binary_integer;
begin
	status := null;
	orauser := null;
	userid := null;
	sessionid := null;
	username := null;
	usermachine := null;
	locktime := null;
	message := null;
	lock_num := null;
	for i in 1 .. locks_count loop
		begin
			if lock_name = names(i) then
				lock_num := i; exit;
			end if;
		exception
			when no_data_found then
				null;
		end;
	end loop;
	if lock_num is null then
		dbms_lock.allocate_unique(inst_info.owner || lock_name, lock_handle);
		locks_count := locks_count + 1;
		names(locks_count) := lock_name;
		handles(locks_count) := lock_handle;
		lock_num := locks_count;
	end if;
	status := dbms_lock.release(handles(lock_num));
	states(lock_num) := 0;  -- лок сброшен
    if status = 3 then
		message := MSG_INVALID_ARGS;
	elsif status = 4 then
        if p_skip_4 then
            status := 0;
        else
            message := MSG_NOT_LOCKED_RESOURCE;
        end if;
	elsif status = 5 then
		message := MSG_INVALID_HANDLE;
	end if;
	if status <> 0 then
		raise_application_error(-20990 - status, message);
	end if;
end;

procedure sleep(seconds number) is
begin
	dbms_lock.sleep(seconds);
end;

end;
/
sho err package body rcs_lock

