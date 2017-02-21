prompt enable restricted session
alter system enable restricted session;
exec dbms_lock.sleep(5);
alter system register;