def owner=IBS

prompt
accept OWNER    char format a30 prompt 'IBSO OWNER [&&OWNER]: ' default IBS

column xxx new_value owner noprint
select upper('&&owner') xxx from dual;
