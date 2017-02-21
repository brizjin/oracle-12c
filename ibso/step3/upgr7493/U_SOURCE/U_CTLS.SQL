exec stdio.enable_buf
set serveroutput on size 1000000
spool u_ctls.log
exec patch_tool.variants_fix;
spool off
