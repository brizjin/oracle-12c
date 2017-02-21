set echo on

@@nums
@@seqs
@@nattrs
@@cls_tab
@@long_tab
@@orsa_tab
set echo off

column xxx new_value up noprint
select decode(sign(to_number('&&v_version','999.9')-7.1),-1,'@alter_tab','utils/dummy') xxx from dual;

@&&up


