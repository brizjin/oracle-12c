var versionibs varchar2(2000);
exec :versionibs := '7.3.2.1,7.3.2.2,7.3.3.0,7.3.4.0,7.3.5.0,7.3.6.0,7.3.6.1,7.3.6.2,7.3.6.3,7.3.7.0,7.3.7.1,7.3.7.2,7.3.7.3,7.3.7.4,7.3.7.5,7.3.8.0,7.3.8.1,7.3.8.2,7.3.9.0,7.3.9.1,7.4.0.0,7.4.0.1,7.4.1.1,7.4.1.2,7.4.1.3,7.4.1.4,7.4.2.1,7.4.2.2,7.4.2.3,7.4.2.4,7.4.2.5,7.4.2.6,7.4.3.0,7.4.3.1,7.4.4.0,7.4.4.1,7.4.4.2,7.4.4.3,7.4.5.0,7.4.5.1,7.4.5.2,7.4.5.3,7.4.5.4,7.4.5.5,7.4.5.6,7.4.6.0,7.4.6.1,7.4.6.2,7.4.7.0,7.4.7.1,7.4.7.2,7.4.7.3,7.4.7.4,7.4.8.0,7.4.8.1,7.4.8.2,7.4.8.3,7.4.8.4,7.4.8.5,7.4.9.0,7.4.9.1,7.4.9.2,7.4.9.3'; 
column xxx new_value UPGRADED_VERSION noprint
select :versionibs xxx from dual;
