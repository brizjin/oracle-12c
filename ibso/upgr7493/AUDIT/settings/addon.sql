set termout off
column yyy new_value AUDITOR noprint;
select USER yyy from dual;

insert into settings (OWNER, NAME, VALUE, DESCRIPTION)
    values('&&OWNER', 'UADMINS_MAX_COUNT', '0', '');

insert into settings (OWNER, NAME, VALUE, DESCRIPTION)
    values('&&OWNER', 'ADMIN_GRP_ENABLED', 'Y', '');

insert into settings (OWNER, NAME, VALUE, DESCRIPTION)
    values('&&AUDITOR', 'REVISOR_DISABLED', 'N', '');

set termout on
