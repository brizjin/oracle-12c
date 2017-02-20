set echo on

prompt  printer_types
alter table printer_types add proxy varchar2(1);

alter table printer_types add constraint CHK_PRINTER_TYPES_PROXY
CHECK(PROXY IN ('0','1'));

@@cls_tab
@@crit_tab
@@c_sec

column xxx new_value oxxx noprint
select user xxx from dual;

@@lic_tab

@@rpt_rol

prompt create context for check access to change objects
create or replace context &&oxxx._access using executor;

set echo off

def conv_id=c_bld
var conv number;

begin
  if nvl(to_number('&&v_version','999.9'),1)>=6.5 then
    :conv := 1;
  end if;
end;
/


column xxx new_value conv_id noprint
select decode(:conv,1,'c_upd','c_bld') xxx from dual;

set echo on

@@&&conv_id

set echo off

