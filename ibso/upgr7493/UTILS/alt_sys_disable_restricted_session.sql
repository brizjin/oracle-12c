prompt disable restricted session
alter system disable restricted session;
exec dbms_lock.sleep(5);
alter system register;