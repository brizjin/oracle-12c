declare
/*
    $Author: Alexey $
    Дополнительный скрипт, используется в U_METH.SQL
*/
n   pls_integer;
j   pls_integer;
s   varchar2(5000);
pipe   varchar2(100);
begin
    pipe := 'BUFFER$'||dbms_session.unique_session_id||'$'||USER;
    dbms_pipe.reset_buffer;
    j := dbms_pipe.receive_message(pipe||'$',0);
    if j=0 then
        dbms_pipe.unpack_message(s);
        stdio.put_line_buf(s);
    end if;
    dbms_pipe.reset_buffer;
    n := 0;
    while n<500000 loop
        j := dbms_pipe.receive_message(pipe,1);
        if j<>0 then exit; end if;
        dbms_pipe.unpack_message(s);
        stdio.put_line_buf(s);
        n := n+nvl(length(s),0)+1;
    end loop;
end;
/

