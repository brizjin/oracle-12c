create or replace procedure &&audmgr..ora_user_password_set(
  p_user_name varchar2,
  p_password  varchar2
) is
  v_user    &&ibso_owner..rtl.users_info;
  v_success boolean;
begin
  v_success := &&ibso_owner..rtl.get_user_info(v_user, p_init => false);
  if not v_success then
    return;
  end if;
  if &&ibso_owner..rtl_utils.is_session_3l(v_user.id) then
    aud_mgr.get_settings;
  end if;
  aud_mgr.ora_user_password_set(p_user_name, p_password);
end;
/
grant execute on &&audmgr..ora_user_password_set to &&ibso_owner;