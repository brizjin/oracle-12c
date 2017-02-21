var lic_del varchar2(2000);

prompt license_settings: check license version

declare
n pls_integer;
bDelete boolean;
o varchar2(30);
begin
  o := upper(trim('&&owner'));
  begin
    execute immediate
    'select lic_version from owners where schema_owner=:o' into n using o;
    bDelete:= nvl(n,1)<>2;
  exception when others then bDelete:= true;
  end;
  if bDelete then
    execute immediate
    'begin lic_mgr.delete_license(:owner); end;' using o;
    :lic_del := 'License information for '||o||' is deleted';
  else
    :lic_del := 'License information for '||o||' is not deleted';
  end if;
exception when others then
  :lic_del:= substr('License information is not deleted:'||chr(10)||sqlerrm,1,2000);
end;
/

print lic_del

