prompt javac_mgr body
create or replace package body 
  /*
   *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/javac_mgr2.sql $
   *  $Author: kirgintsev $
   *  $Revision: 19890 $
   *  $Date:: 2012-12-20 12:06:24 #$
   */
  javac_mgr is
  --
  VERSION   constant varchar2(10) := '1.1';
  JAVA_TYPE constant varchar2(4) := 'JAVA';
  --
  function get_version return varchar2 is
  begin
    return VERSION;
  end;
  --
  function get_host_source(p_method_id varchar2) return clob is
    sourceCode clob;
  begin
    select s.code
      into sourceCode
      from host_sources s
     where s.id = p_method_id
       and s.type = JAVA_TYPE;
    return sourceCode;
  exception
    when no_data_found then
      return '';
  end;
  --
  function get_compile_date return date is
    compile_d   date;
  begin
    select nvl(max(compile_date), sysdate)
      into compile_d
      from host_errors_hist;
    return compile_d;
  end;
  --
  procedure get_host_errors(p_method_id varchar2, p_host_errors in out nocopy host_errors_cursor_t) is
    compiled_d   date;
  begin
    compiled_d := get_compile_date();

    open p_host_errors for
      select he.*
        from host_errors he, methods m
       where he.method_id = m.id
         and he.method_id = p_method_id
         and nvl(m.modified, compiled_d) <= compiled_d
       order by he.line, he.pos;
  end;
  --
  function get_source_status(p_method_id varchar2) return varchar2 is
    modified_d        date;
    compiled_d        date;
    error_count       integer;
    status            varchar2(12);
    java_code_length  number;
  begin
    status := STATUS_NOT_EXISTS;
    
    begin
   
      select s.status
        into status
        from host_sources s
      where s.id = p_method_id
         and s.type = JAVA_TYPE;
    exception
      when no_data_found then
        null;        
    end;
    return status;   
  end;
  --
end javac_mgr;
/
show err package body javac_mgr
