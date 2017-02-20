prompt Correcting rtl_parameters class_id/flag

update rtl_parameters
 set flag = decode(class_id,'%object','O','%rowtype','V','P'),
     siz =  decode(ascii(class_id),ascii('-'),to_number(class_id),siz),
     class_id = par_name
where flag='T' and ascii(class_id) in (ascii('%'),ascii('-'));

commit;

set serveroutput on size 1000000
exec stdio.enable_buf
exec stdio.enable_buf(1000000)

prompt Correcting Owner properties
begin
  for c in (select username,name from users where username=inst_info.owner) loop
    secadmin.edituser(c.username,c.name);
    exit;
  end loop;
end;
/
/

prompt Correcting settings
exec sysinfo.setvalue('CLS_STATIC_EVENT','1','Признак рассылки события обновления статического экземпляра в момент изменения');
exec sysinfo.setvalue('NOVO_LIGHT_WEIGHT','1',message.gettext('ADMIN', 'NOVO_LIGHT_WEIGHT'));
exec sysinfo.setvalue('CLS_STATIC_EVENT','1','Признак рассылки события обновления статического экземпляра в момент изменения');


prompt Converting Crit_Formula in method_parameters/variables
exec patch_tool.update_crit_formula;

@@calen_af

@@g_stat
