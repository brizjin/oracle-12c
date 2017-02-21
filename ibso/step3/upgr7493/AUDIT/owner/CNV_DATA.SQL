set termout off
define deldata='NO'
column yyy new_value deldata noprint
select 'YES' yyy from audit_settings where owner!='&&owner' and rownum<2;
set termout on

prompt
define KEPTIME = '01/01/2000' --accept KEPTIME char format a30 prompt 'Convert DIARIES starting from DATE (format DD/MM/YYYY):'
define DELDATA = &&DELDATA --accept DELDATA char format a30 prompt 'Delete data from DIARIES [&&DELDATA]:' default &&DELDATA
define OLD_VER = &&OLD_VER --accept OLD_VER char format a30 prompt 'IBSO OWNER "&&owner" Old Version [&&OLD_VER]: ' default &&OLD_VER

prompt
prompt Stop all background processes and press ENTER to continue...
--pause

set serveroutput on size 100000

var cnv varchar2(100);
var drp varchar2(100);
var del varchar2(100);

define START_DATE='add_months(sysdate, -6)'
define END_DATE='add_months(sysdate, 6)'

prompt converting object_state_history
exec conv.object_state_history('&&owner', '&&old_ver', '&&deldata', to_date(nvl('&&KEPTIME','01/01/1900') ,'DD/MM/YYYY'), &&START_DATE, &&END_DATE, false)

prompt converting values_history
exec conv.values_history('&&owner', '&&old_ver', '&&deldata', to_date(nvl('&&KEPTIME','01/01/1900') ,'DD/MM/YYYY'), &&START_DATE, &&END_DATE, false)

prompt converting diary_param
declare
  drp boolean;
begin
  conv.diary_param('&&owner', '&&old_ver', '&&deldata', to_date(nvl('&&KEPTIME','01/01/1900') ,'DD/MM/YYYY'), &&START_DATE, &&END_DATE, false, drp);
  if drp then :drp := '1'; end if;
end;
/

prompt converting diary_debug_exec
declare
  drp boolean := (:drp = '1');
begin
  conv.diary_debug_exec('&&owner', '&&old_ver', '&&deldata', to_date(nvl('&&KEPTIME','01/01/1900') ,'DD/MM/YYYY'), &&START_DATE, &&END_DATE, false, drp);
  if drp then :drp := '1'; end if;
end;
/

prompt converting diary_errors
declare
  drp boolean := (:drp = '1');
begin
  conv.diary_errors('&&owner', '&&old_ver', '&&deldata', to_date(nvl('&&KEPTIME','01/01/1900') ,'DD/MM/YYYY'), &&START_DATE, &&END_DATE, false, drp);
  if drp then :drp := '1'; end if;
end;
/

prompt converting diary_uadmin
declare
  drp boolean := (:drp = '1');
begin
  conv.diary_uadmin('&&owner', '&&old_ver', '&&deldata', to_date(nvl('&&KEPTIME','01/01/1900') ,'DD/MM/YYYY'), &&START_DATE, &&END_DATE, false, drp);
  if drp then :drp := '1'; end if;
end;
/

prompt converting diary_sessions
declare
  drp boolean := (:drp = '1');
begin
  conv.diary_sessions('&&owner', '&&old_ver', '&&deldata', to_date(nvl('&&KEPTIME','01/01/1900') ,'DD/MM/YYYY'), &&START_DATE, &&END_DATE, false, drp);
  if drp then :drp := '1'; end if;
end;
/

prompt converting diary_methods
declare
  drp boolean := (:drp = '1');
begin
  conv.diary_methods('&&owner', '&&old_ver', '&&deldata', to_date(nvl('&&KEPTIME','01/01/1900') ,'DD/MM/YYYY'), &&START_DATE, &&END_DATE, false, drp);
  if drp then :drp := '1'; end if;
end;
/

prompt converting diary_storage
declare
  drp boolean := (:drp = '1');
begin
  conv.diary_storage('&&owner', '&&old_ver', '&&deldata', to_date(nvl('&&KEPTIME','01/01/1900') ,'DD/MM/YYYY'), &&START_DATE, &&END_DATE, false, drp);
  if drp then :drp := '1'; end if;
end;
/

prompt converting diary_attrs
declare
  drp boolean := (:drp = '1');
begin
  conv.diary_attrs('&&owner', '&&old_ver', '&&deldata', to_date(nvl('&&KEPTIME','01/01/1900') ,'DD/MM/YYYY'), &&START_DATE, &&END_DATE, false, drp);
  if drp then :drp := '1'; end if;
end;
/

prompt converting diary_UNKNOWN
exec conv.diary_UNKNOWN('&&owner', '&&old_ver', '&&deldata', to_date(nvl('&&KEPTIME','01/01/1900') ,'DD/MM/YYYY'), &&START_DATE, &&END_DATE, false)

prompt converting diary_info
declare
  drp boolean := (:drp = '1');
begin
  conv.diary_info('&&owner', '&&old_ver', '&&deldata', to_date(nvl('&&KEPTIME','01/01/1900') ,'DD/MM/YYYY'), &&START_DATE, &&END_DATE, false, drp);
  if drp then :drp := '1'; end if;
end;
/

prompt converting diary_others
declare
  drp boolean := (:drp = '1');
begin
  conv.diary_others('&&owner', '&&old_ver', '&&deldata', to_date(nvl('&&KEPTIME','01/01/1900') ,'DD/MM/YYYY'), &&START_DATE, &&END_DATE, false, drp);
  if drp then :drp := '1'; end if;
end;
/

prompt converting object_collection_history
exec conv.object_collection_history('&&owner', '&&old_ver', '&&deldata', to_date(nvl('&&KEPTIME','01/01/1900') ,'DD/MM/YYYY'), &&START_DATE, &&END_DATE, false)

prompt converting system_events
exec conv.system_events('&&owner', '&&old_ver', '&&deldata', to_date(nvl('&&KEPTIME','01/01/1900') ,'DD/MM/YYYY'), &&START_DATE, &&END_DATE, false)

prompt converting edoc_history
exec conv.edoc_history('&&owner', '&&old_ver', '&&deldata', to_date(nvl('&&KEPTIME','01/01/1900') ,'DD/MM/YYYY'), &&START_DATE, &&END_DATE, false)


prompt adding partitions
exec clear.add_partitions('&&OWNER', utils.DIARY1, &&END_DATE);
exec clear.add_partitions('&&OWNER', utils.DIARY2, &&END_DATE);
exec clear.add_partitions('&&OWNER', utils.DIARY3, &&END_DATE);
exec clear.add_partitions('&&OWNER', utils.DIARY4, &&END_DATE);
exec clear.add_partitions('&&OWNER', utils.DIARY5, &&END_DATE);
exec clear.add_partitions('&&OWNER', utils.DIARY6, &&END_DATE);
exec clear.add_partitions('&&OWNER', utils.DIARY7, &&END_DATE);
exec clear.add_partitions('&&OWNER', utils.VALSH, &&END_DATE);
exec clear.add_partitions('&&OWNER', utils.OSH, &&END_DATE);
exec clear.add_partitions('&&OWNER', utils.OCH, &&END_DATE);
exec clear.add_partitions('&&OWNER', utils.DP, &&END_DATE);
exec clear.add_partitions('&&OWNER', utils.EDH, &&END_DATE);

@@cr_idx


