set feedback off
set heading off
set newpage 0
set pagesize 0
set echo off
set verify off
set serveroutput on size 1000000
set linesize 1000
set arraysize 1
set trimspool on
set trimout on

set termout off

exec stdio.enable_buf(1000000)

--��������� ���� �� ������ ����� �������� 3� ���������� � run_sessions
define third_p=''
column set_value new_value third_p;
SELECT :FLAG_ERROR set_value FROM dual
/
-- ������ ������� ����������
HOST run_sessions.bat &1 &2 &&third_p

/

declare
  pipe_name   varchar2(100) := nvl('&3','DEBUG$100');
  lError boolean;
  cnt_t    integer; --������� ��������
  cnt_s    integer; --������� ���. �����
  max_t_wait integer := 100000;

  procedure read_pipe(name varchar2) is 
  sDummy varchar2(32767);
  nDummy varchar2(32767);
  begin
     while true
     loop
        nDummy:= stdio.get_line_pipe(sDummy, name);
        if nDummy<>0 then
            exit;
        end if;
     end loop;
  end;
  -- ��������� ��� ���������� ������� � (���) ����������� ������� �������, ����� ������� ������������ �������� m_cursor
  -- � ������� �������������� ���������� ���� ����������� ������ ����� ����������: 
  -- with_dependencies (�� ��������� false) - ���������� ��� ������������ (��������� �������� ������� ������ UPDATED),
  -- ���� with_dependencies= true - ����������������� ������ �� ���� ������� ����������� � ������ ��������� ������������
  -- build_interface (�� ��������� true ) - ����������������� ������������ ����� ��������
  -- compile_method  (�� ��������� true ) - ����������������� ��������
  procedure methods_compile (with_dependencies boolean default false, 
                            build_interface boolean default true, compile_method boolean default true) is
   s   varchar2(32767);
   n   pls_integer;
   i   pls_integer;
   j   pls_integer;
   v_meth_id varchar2(256);
   name   varchar2(100);
   cnt pls_integer:=0;
   i_all integer := 0;
   m_rec    method.method_ref_t;
   m_cursor method.methods_cursor_t;
   w_d boolean;
   b_i boolean;
   c_m boolean;
   sParams varchar2(32767);
   type methodH_tbl_t is table of boolean index by binary_integer;
   methodH_tbl methodH_tbl_t;
   idx_h      pls_integer;

   type sessions is record (
      id  varchar2(50),
      status  varchar2(50),
      cnt_wait   pls_integer
    );
   type sessions_tbl  is table of sessions index by binary_integer;
   s_tbl sessions_tbl;
   idx pls_integer;
   cnt_thread pls_integer:=0;
   cntOp pls_integer:=0;
     
   /*------------------------------------------------------------------------------------------*/
   -- �������� ���������� ������ ������� ����������
   /*------------------------------------------------------------------------------------------*/
   function wait_compile return pls_integer is
   n pls_integer:=0;
   s varchar2(32767);
   cntSleep pls_integer:=0;
   i pls_integer:=0;
   wait pls_integer:=0;
   WAIT_TIME pls_integer:=5;
   MAX_WAITING pls_integer:=180;
   begin
      while true loop
         i:= 0;
         for idx in 1..cnt_thread loop
            if s_tbl(idx).status='COMPILE' then
                 n:= stdio.get_line_pipe(s, 'DEBUG$COMPILE$SERV$' || s_tbl(idx).id, wait);
                 s:= rtrim(s, constant.LF);
                 if s like 'COMPILE;%' then
                     cntOp:= cntOp+1;
                     s:= to_char(cntOp) || '/' || to_char(i_all) || '  ' || substr(s, 9);
                 elsif s = 'SLEEP' then
                     s_tbl(idx).status:= 'SLEEP';
                     cntSleep:= cntSleep+1;
                     s:= null;
                 end if;
                 if s is not null then 
                    stdio.put_line_pipe(s, pipe_name);
                 end if;
                 if n=0 then
                    i:= i+1;
                    s_tbl(idx).cnt_wait:= 0;
                 elsif wait is not null then
                    s_tbl(idx).cnt_wait:= s_tbl(idx).cnt_wait+1;
                    if s_tbl(idx).cnt_wait * WAIT_TIME >= MAX_WAITING then
                       s_tbl(idx).status:= 'SLEEP';
                       cntSleep:= cntSleep+1;
                    end if;
                 end if;
            end if;
         end loop;
         if cntSleep = cnt_thread then
             n:=1;
             exit;
         end if;
         -- ���� �� �� ����� �� ������ �� ������� ���������, �� ������ � ���������
         if i=0 then
            wait:= WAIT_TIME;
         else
            wait:= null;
         end if;
       end loop;
      return n;
   end;

   /*------------------------------------------------------------------------------------------*/
   -- ��������� ������ ������ ��
   /*------------------------------------------------------------------------------------------*/

   function get_version return number is
  ver varchar2(20);
   begin
     ver := inst_info.get_version;
     return to_number(substr(ver,1,instr(ver,'.',1,2)-1));
   end;
  begin
     idx:= 0;
     -- ����������� ������
     for  s$ in (select client_info from v$session where module='COMPILE$THREAD')
     loop
          stdio.put_line_pipe('INIT', stdio.STDIOPIPENAME || s$.client_info);
          n:= stdio.get_line_pipe(s, 'DEBUG$COMPILE$SERV$' || s$.client_info,5);
          if s='READY' then
             idx:= idx+1;
             s_tbl(idx).id:= s$.client_info;
             s_tbl(idx).status:= 'BEGIN';                      end if;
     end loop;

     cnt_thread:= idx;
     if cnt_thread=0 then 
        stdio.put_line_pipe('��������� ���������� - ��� ������ ��� ����������', pipe_name);
        lError:= true;
        return;
     end if;

     w_d:= nvl(with_dependencies, false);
     b_i:= nvl(build_interface, true);
     c_m:= nvl(compile_method, true);
     if w_d then 
        sParams:= '$$$WITH_DEPENDENCIES$$$';
     end if;
     if b_i then 
        sParams:= sParams || '$$$BUILD_INTERFACE$$$';
     end if;
     if c_m then 
        sParams:= sParams || '$$$COMPILE_METHODS$$$';
     end if;

     methodH_tbl.delete;
     -- ������� ���������� ������� � �������
     open m_cursor for &&cursor_description;
     loop
        fetch m_cursor into m_rec;
        exit when m_cursor%notfound;
        idx_h := method.hash_id(m_rec.id);
        if not methodH_tbl.exists(idx_h) then
            methodH_tbl(idx_h) := true;
        end if;
        --i_all := i_All + 1;
     end loop;
     i_all := methodH_tbl.count;
     close m_cursor;
     --stdio.put_line_pipe('count = '||i_all, pipe_name);
     if i_all>0 then
         open m_cursor for &&cursor_description;
         method.compile_methods(m_cursor,pipe_name,null);
         --stdio.put_line_pipe('method.compile_methods', pipe_name);
         n := 0; 
         cnt:= 0;
         loop
           -- �� ������ �� < 6.4 ���� ������ 1
           if cnt>0 and get_version<6.4 then 
              cnt:= cnt-1;
           end if;
           s := method.get_method_list(cnt);
           stdio.put_line_pipe(s, 'DEBUG$COMPILE');
           -- ������� ��������� �� ��������������� ����� - ������ ������ ������ ������ ������ DEBUG$COMPILE
           for idx in 1..cnt_thread loop
               if instr(s_tbl(idx).status, 'BEGIN')>0 or instr(s_tbl(idx).status, 'SLEEP')>0 then
                  stdio.put_line_pipe('BEGIN$COMPILE;' || sParams, stdio.STDIOPIPENAME || s_tbl(idx).id);
                  s_tbl(idx).status:= 'COMPILE';
                  s_tbl(idx).cnt_wait:= 0;
               end if;
           end loop;

           n:= wait_compile;
           if cnt=0 or n=0 then exit; end if;
         end loop;
     end if;

     -- �������� ��� �����
     for idx in 1..cnt_thread loop
         read_pipe('DEBUG$COMPILE$SERV$' || s_tbl(idx).id);
         read_pipe(stdio.STDIOPIPENAME || s_tbl(idx).id);
     end loop;

     return;
  end;

begin
  
  lError:= :FLAG_ERROR is not null;
  if not lError then
      stdio.put_line_pipe('�������� �������� ������ ����������', pipe_name);
      cnt_t := 0;
      while true loop
        cnt_t := cnt_t + 1;
        select count(client_info) into cnt_s from v$session where module='COMPILE$THREAD';
        if cnt_s = &2 then
          exit;
        end if;
        if cnt_t > max_t_wait then
           stdio.put_line_pipe('�� '||max_t_wait||' ������ �� ������� ��������� '||&2||' ������. ����������� '||cnt_s||' !!!',pipe_name);
--          :FLAG_ERROR:= 'ERROR';
          exit;
        end if; 
      end loop;

      -- ����������� ������, ������������� �� 1 ������� �� ������
      --utils.sleep(&3);

      -- ���������: �������� ������� �� methods, ����� ���������� ������������ ������� ������ (��/���), ����������� ������������ ����� (��/���), 
      -- ������������� �������� (��/���)
      methods_compile (:WITH_DEPENDENCIES='true', :BUILD_INTERFACE='true', :COMPILE_METHODS='true');
      if not lError then 
          stdio.put_line_pipe('*** �������� ���������� ������ ����������',pipe_name);
      else
          :FLAG_ERROR:= 'ERROR';
      end if;
  end if;

  stdio.put_line_pipe('�������� ������ ����������', pipe_name);
  -- �������� ������
  for  s in (select client_info from v$session where module='COMPILE$THREAD')
  loop
     stdio.put_line_pipe('END$COMPILE', stdio.STDIOPIPENAME || s.client_info);
  end loop;

  cnt_t := 0;
  while true loop
    cnt_t := cnt_t + 1;
    select count(client_info) into cnt_s from v$session where module='COMPILE$THREAD';
    if cnt_s = 0 then
      exit;
    end if;
    if cnt_t > max_t_wait then
      stdio.put_line_pipe('�� '||max_t_wait||' ������ '||cnt_s||' ������ �� ���������. �������� ����� ��������� ���-�� ������ �������� (max_t_wait)!!!',pipe_name);
      :FLAG_ERROR:= 'ERROR';
      exit;
    end if; 
  end loop;

--      utils.sleep(&3);
  -- �������� �����
  read_pipe('DEBUG$COMPILE');

end;
/ 

set feedback on
set heading on
