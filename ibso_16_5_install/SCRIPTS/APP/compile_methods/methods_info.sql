declare 
n pls_integer;
begin
    select count(1) into n from methods m where m.KERNEL='0' and m.status='NOT COMPILED' and flags<>'Z';
    if n>0 then
        stdio.put_line_pipe('���������� ������� � ��������� NOT COMPILED -  ' || n, :PIPE_NAME);
    end if;

    select count(1) into n from methods m where m.KERNEL='0' and m.status='INVALID' and flags<>'Z';
    if n>0 then
        stdio.put_line_pipe('���������� ������� � ��������� INVALID -  ' || n, :PIPE_NAME);
        select count(1) into n from methods m where m.KERNEL='0' and m.status='INVALID' and flags<>'Z' and exists
                    (select 1 from errors e where e.METHOD_ID=m.id and e.text like 'PLP-OBJECT_NOT_FOUND%');
        if n>0 then
           stdio.put_line_pipe('     � �.�. � �������� <OBJECT_NOT_FOUND> -  ' || n, :PIPE_NAME);
        end if;
    end if;

    select count(1) into n from methods m where m.KERNEL='0' and m.status='PROCESSED' and flags<>'Z';
    if n>0 then
        stdio.put_line_pipe('���������� ������� � ��������� PROCESSED -  ' || n, :PIPE_NAME);
    end if;

    select count(1) into n from methods m where m.KERNEL='0' and m.status='UPDATED' and flags<>'Z';
    if n>0 then
        stdio.put_line_pipe('���������� ������� � ��������� UPDATED -  ' || n, :PIPE_NAME);
    end if;

end;
/
