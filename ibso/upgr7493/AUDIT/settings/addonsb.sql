update settings set value = '2' where owner='&&OWNER'   and name='UADMINS_MAX_COUNT';

update settings set value = 'N' where owner='&&OWNER'   and name='ADMIN_GRP_ENABLED';

update settings set value = 'Y' where owner='&&AUDITOR' and name='REVISOR_DISABLED';
