def simple=0
column xxx new_value simple noprint
select owner xxx from project where name='SIMPLE' and type='SETTINGS';

column xxx new_value call noprint
select decode('&&simple','0','call','dummy') xxx from dual;

exec dbms_session.reset_package

@@&&call

exit

