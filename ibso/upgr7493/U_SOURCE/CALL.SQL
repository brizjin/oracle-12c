spool c_all.log
prompt updating methods
update methods set status='NOT COMPILED' where status='UPDATED' and flags<>'Z';
commit;
spool off
@@u_ctls

