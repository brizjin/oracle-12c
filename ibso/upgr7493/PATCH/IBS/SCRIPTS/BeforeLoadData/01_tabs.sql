prompt Create system objects

set echo on

WHENEVER SQLERROR EXIT FAILURE

prompt create table update_journal
prompt 

begin
execute immediate 
'create table update_journal(
	id number,
	is_before varchar2(1),
	priority number,
	type_error varchar2(1),
	status varchar2(1),
	run_date date,
	version varchar2(24),
	action_name varchar2(100),
	script varchar2(4000)
)
  tablespace &&tusers';
exception when others then
	if SQLCODE <> -955 then	
		execute immediate 'alter system disable restricted session';
		raise; 
	end if;
end;
/

prompt create primary key pk_update_journal 
prompt 

begin
execute immediate 
	'alter table update_journal add constraint pk_update_journal primary key(id)';
exception when others then
	if SQLCODE <> -2260 then
		execute immediate 'alter system disable restricted session';
		raise; 
	end if;
end;
/

set echo off

WHENEVER SQLERROR CONTINUE NONE
