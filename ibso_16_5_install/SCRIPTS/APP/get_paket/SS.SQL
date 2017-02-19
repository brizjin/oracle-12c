store set plusenv replace
spool &2
set arraysize 14
set newpage 0
set space 0
set linesize 200
set pagesize 0
set echo off
set feedback off
set heading off
set long 2000
set termout off
set verify off
set trimspool on
select decode(line, 1, 'Create or Replace ', '')||
  decode(line, 1,
    substr(text, 1, instr(rtrim(text), ' ', 1, decode(&3, 2, 2, 1)))||
      rtrim(user)||'.'||ltrim(substr(rtrim(text), instr(rtrim(text), ' ', 1, decode(&3, 2, 2, 1))+1)),
    text)
from user_source
where name = upper('&1') and type = decode(&3, 1, 'PACKAGE', 2, 'PACKAGE BODY', 3, 'PROCEDURE');
select '/'||chr(10)||'show errors' from dual;
spool off
start plusenv
quit
