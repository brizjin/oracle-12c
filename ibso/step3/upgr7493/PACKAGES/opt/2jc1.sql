var mess varchar2(1000)
var load_java varchar2(1)

declare
java_version  varchar2(100) := null;
begin
    :load_java := '1';
    :mess := '�� ����� �� ���������� ���������� "Java �����������".'||chr(10)||
             '������������� ����������� ����� PLP2JAVA �� ������������.';
           
	begin
		execute immediate '
			begin
				:result:= plp2java.get_version();
			end;' using out java_version;
	exception when others then null;
    end;
    
    if java_version is not null then
    	:load_java := '0';
        :mess := '�� ����� ���������� ���������� "Java �����������" ������ '||java_version||'.'||chr(10)||
                 '��������� ����� PLP2JAVA ��� ���������.';
	end if;
end;
/

column xxx new_value java_spec noprint
select decode(:load_java, '1', '2java1.sql','dummy') xxx from dual;

column xxx new_value java_body noprint
select decode(:load_java, '1', '2java2.sql','dummy') xxx from dual;

print mess
