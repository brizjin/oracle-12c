@@chk_hash

print v_equal
--print db_version

column xxx new_value inv_pkg noprint
select decode(:v_equal,'1','dummy','inv_packs') xxx from dual;
--select decode(:v_equal,'1','dummy',decode(sign(:db_version-10),1,'inv_packs','dummy')) xxx from dual;

@@&&inv_pkg


