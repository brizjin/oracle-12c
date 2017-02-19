REM �������������� ������� ��� ��������� ������ (��� I)
REM ��� I ����������� ����� ����� ������ ��������� �� ������� �������� �����������

set feedback off
exec executor.setnlsparameters
set feedback on

prompt _�������������� ������� ��� ��������� ������ (��� I)
prompt _��� I ����������� ����� ����� ������ ��������� �� ������� �������� �����������
rem ACCEPT name CHAR DEFAULT 'DEBUG$100' PROMPT '������� ��� ����������������� ������ (�� ��������� - DEBUG$100): '

define name = 'DEBUG$100'

variable WITH_DEPENDENCIES varchar2(10)
variable BUILD_INTERFACE varchar2(10)
variable COMPILE_METHODS varchar2(10)
variable FLAG_ERROR varchar2(10)
variable PIPE_NAME varchar2(128)


declare
  r   pls_integer;
begin
  :PIPE_NAME:= nvl('&&name','DEBUG$100');

    r := executor.lock_open(null, nvl(executor.get_system_id,dbms_session.unique_session_id));
    class_mgr.check_user(true);

  stdio.setup_pipes(null,null,null,300000);

--  rtl.set_debug_pipe(:PIPE_NAME);
--  rtl.set_debug(0,rtl.DEBUG2PIPE,300000);

  stdio.put_line_pipe(' ',:PIPE_NAME);
  stdio.put_line_pipe('**********************************************************',:PIPE_NAME);
  stdio.put_line_pipe('Started',:PIPE_NAME);
  stdio.put_line_pipe('�������������� ���� ������� ',:PIPE_NAME);
  stdio.put_line_pipe(TO_CHAR(SYSDATE,'DD/MM/YY HH24:MI:SS'),:PIPE_NAME);
  stdio.put_line_pipe('**********************************************************',:PIPE_NAME);
end;
/

@methods_info

exec stdio.put_line_pipe(' ', '&&name')
exec stdio.put_line_pipe(' ���������� � ���������� - ������������� rtl_idx. ���������...', '&&name')
@rtl_idx

-- ���������, ������� ��������� �������� �����, �� ������� �� ������������ �� ��������� ������������� �������� ������ NOT COMPILED
exec update -
     (select m.id, m.status -
      from methods m, methods m2-
      where m.FORM_ID=m2.id and m2.status='NOT COMPILED' and m.status<>'NOT COMPILED') m-
     set m.status='NOT COMPILED'

exec commit

define cursor_description = "select id, class_id, short_name from methods m where m.KERNEL='0' and m.status='INVALID' and exists -
(select 1 from errors e where e.METHOD_ID=m.id and e.text like 'PLP-OBJECT_NOT_FOUND%')"
begin
  :WITH_DEPENDENCIES:= 'false';
  :BUILD_INTERFACE:= 'true';
  :COMPILE_METHODS:= 'true';
  if :FLAG_ERROR is null then 
      stdio.put_line_pipe(' ',:PIPE_NAME);
      stdio.put_line_pipe(' 1. ���������� ������� � ��������� INVALID � �������� <OBJECT_NOT_FOUND>',:PIPE_NAME);
  end if;
end;
/
-- �� ������������� �����������, ����������� ������������ �����, ������������� ��������
@s_meth_recomp.sql &1 &2 &name


define cursor_description = "select id, class_id, short_name from methods m -
where m.KERNEL='0' and m.status='NOT COMPILED'"

begin
  :WITH_DEPENDENCIES:= 'false';
  :BUILD_INTERFACE:= 'true';
  :COMPILE_METHODS:= 'true';
  if :FLAG_ERROR is null then 
      stdio.put_line_pipe(' ',:PIPE_NAME);
      stdio.put_line_pipe(' 2. ���������� ������� � ��������� NOT COMPILED -  1-� ������',:PIPE_NAME);
  end if;
end;
/
-- �� ������������� �����������, ����������� ������������ �����, ������������� ��������
@s_meth_recomp.sql &1 &2 &name

define cursor_description = "select id, class_id, short_name from methods m -
where m.KERNEL='0' and m.status='NOT COMPILED'"


begin
  :WITH_DEPENDENCIES:= 'false';
  :BUILD_INTERFACE:= 'true';
  :COMPILE_METHODS:= 'true';
  if :FLAG_ERROR is null then 
      stdio.put_line_pipe(' ',:PIPE_NAME);
      stdio.put_line_pipe(' 3. ���������� ������� � ��������� NOT COMPILED -  2-� ������',:PIPE_NAME);
  end if;
end;
/

-- �� ������������� �����������, ����������� ������������ �����, ������������� ��������
@s_meth_recomp.sql &1 &2 &name
define cursor_description = "select id, class_id, short_name from methods m -
where m.KERNEL='0' and m.status='UPDATED'"

begin
  :WITH_DEPENDENCIES:= 'false';
  :BUILD_INTERFACE:= 'false';
  :COMPILE_METHODS:= 'true';
  if :FLAG_ERROR is null then 
      stdio.put_line_pipe(' ',:PIPE_NAME);
      stdio.put_line_pipe(' 4. ���������� ������� � ��������� UPDATED - 1-� ������ ',:PIPE_NAME);
  end if;
end;
/

@s_meth_recomp.sql &1 &2 &name

define cursor_description = "select id, class_id, short_name from methods m -
where m.KERNEL='0' and m.status='INVALID' and not exists  -
(select 1 from errors e where e.METHOD_ID=m.id and e.text like 'PLP-OBJECT_NOT_FOUND%')"

begin
  :WITH_DEPENDENCIES:= 'false';
  :BUILD_INTERFACE:= 'false';
  :COMPILE_METHODS:= 'true';
  if :FLAG_ERROR is null then 
      stdio.put_line_pipe(' ',:PIPE_NAME);
      stdio.put_line_pipe(' 5. ���������� ������� � ��������� INVALID ��� ������ <OBJECT_NOT_FOUND> - 1-� ������',:PIPE_NAME);
  end if;
end;
/

@s_meth_recomp.sql &1 &2 &name

define cursor_description = "select id, class_id, short_name from methods m -
where m.KERNEL='0' and m.status='PROCESSED'"

begin
  :WITH_DEPENDENCIES:= 'false';
  :BUILD_INTERFACE:= 'false';
  :COMPILE_METHODS:= 'true';
  if :FLAG_ERROR is null then 
      stdio.put_line_pipe(' ',:PIPE_NAME);
      stdio.put_line_pipe(' 6. ���������� ������� � ��������� PROCESSED',:PIPE_NAME);
  end if;
end;
/

@s_meth_recomp.sql &1 &2 &name

define cursor_description = "select id, class_id, short_name from methods m -
where m.KERNEL='0' and m.status='INVALID' and not exists (select 1 from errors e where e.METHOD_ID=m.id and e.text like 'PLP-OBJECT_NOT_FOUND%')"

begin
  :WITH_DEPENDENCIES:= 'false';
  :BUILD_INTERFACE:= 'false';
  :COMPILE_METHODS:= 'true';
  if :FLAG_ERROR is null then 
      stdio.put_line_pipe(' ',:PIPE_NAME);
      stdio.put_line_pipe(' 7. ���������� ������� � ��������� INVALID ��� ������ <OBJECT_NOT_FOUND> - 2-� ������',:PIPE_NAME);
  end if;
end;
/

@s_meth_recomp.sql &1 &2 &name

define cursor_description = "select id, class_id, short_name from methods m -
where m.KERNEL='0' and m.status='UPDATED'"

begin
  :WITH_DEPENDENCIES:= 'false';
  :BUILD_INTERFACE:= 'false';
  :COMPILE_METHODS:= 'true';
  if :FLAG_ERROR is null then 
      stdio.put_line_pipe(' ',:PIPE_NAME);
     stdio.put_line_pipe(' 8. ���������� ������� � ��������� UPDATED - 2-� ������ ',:PIPE_NAME);
  end if;
end;
/
@s_meth_recomp.sql &1 &2 &name

define cursor_description = "select id, class_id, short_name from methods m -
where m.KERNEL='0' and m.status='UPDATED'"

begin
  :WITH_DEPENDENCIES:= 'false';
  :BUILD_INTERFACE:= 'false';
  :COMPILE_METHODS:= 'true';
  if :FLAG_ERROR is null then 
      stdio.put_line_pipe(' ',:PIPE_NAME);
      stdio.put_line_pipe(' 9. ���������� ������� � ��������� UPDATED - 3-� ������ ', :PIPE_NAME);
  end if;
end;
/
@s_meth_recomp.sql &1 &2 &name

define cursor_description = "select id, class_id, short_name from methods m, user_objects o -
where m.KERNEL='0' and o.STATUS != 'VALID' and o.object_name = m.package_name"

begin
  :WITH_DEPENDENCIES:= 'false';
  :BUILD_INTERFACE:= 'false';
  :COMPILE_METHODS:= 'true';
  if :FLAG_ERROR is null then 
      stdio.put_line_pipe(' ',:PIPE_NAME);
      stdio.put_line_pipe(' 10. ���������� �������, ����� ������� ����� ������ INVALID', :PIPE_NAME);
  end if;
end;
/
@s_meth_recomp.sql &1 &2 &name

define cursor_description = "select id, class_id, short_name from methods m -
where m.FLAGS <> 'Z' and m.KERNEL='0' and m.STATUS<>'VALID'"

begin
  :WITH_DEPENDENCIES:= 'false';
  :BUILD_INTERFACE:= 'true';
  :COMPILE_METHODS:= 'true';
  if :FLAG_ERROR is null then 
      stdio.put_line_pipe(' ',:PIPE_NAME);
      stdio.put_line_pipe(' 11. ���������� �������, ��������� ������� ���������� �� VALID', :PIPE_NAME);
  end if;
end;
/
@s_meth_recomp.sql &1 &2 &name

define cursor_description = "select id, class_id, short_name from methods m -
where m.KERNEL='0' and m.status='UPDATED'"

begin
  :WITH_DEPENDENCIES:= 'false';
  :BUILD_INTERFACE:= 'false';
  :COMPILE_METHODS:= 'true';
  if :FLAG_ERROR is null then 
      stdio.put_line_pipe(' ',:PIPE_NAME);
      stdio.put_line_pipe(' 12. ���������� ������� � ��������� UPDATED - 4-� ������ ', :PIPE_NAME);
  end if;
end;
/
@s_meth_recomp.sql &1 &2 &name


begin
    if :FLAG_ERROR is null then 
      stdio.put_line_pipe('**********************************************************', :PIPE_NAME);
      stdio.put_line_pipe('Finished',:PIPE_NAME);
      stdio.put_line_pipe('�������������� ���� �������', :PIPE_NAME);
      stdio.put_line_pipe(TO_CHAR(SYSDATE,'DD/MM/YY HH24:MI:SS'), :PIPE_NAME);
      stdio.put_line_pipe('**********************************************************', :PIPE_NAME);
      stdio.put_line_pipe(' ',:PIPE_NAME);
    else
      stdio.put_line_pipe('!!! �������� !!! ',:PIPE_NAME);
      stdio.put_line_pipe('���� ������ ��� ������ ������� ��� ���������� ', :PIPE_NAME);
      stdio.put_line_pipe('��������� ������ ��������, � ������ ���������� ������ ���������� � ������ ��������� ', :PIPE_NAME);
      stdio.put_line_pipe('!!! -------- !!! ',:PIPE_NAME);
      stdio.put_line_pipe(' ',:PIPE_NAME);
    end if;
end;
/

@methods_info

begin
    if :FLAG_ERROR is not null then 
      raise_application_error(-20000, '���� ������ ��� ������ ������� ��� ����������.'||chr(10)||'��������� ������ ��������, � ������ ���������� ������ ���������� � ������ ���������');
    end if;
end;
/
