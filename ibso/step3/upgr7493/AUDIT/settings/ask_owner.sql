def owner=IBS

prompt
define OWNER = IBS

column xxx new_value owner noprint
select upper('&&owner') xxx from dual;
