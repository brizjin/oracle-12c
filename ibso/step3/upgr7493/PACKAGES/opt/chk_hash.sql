var v_const number
var v_equal number
var v_rtl1  number
var v_rtl2  number

declare
  v_const pls_integer := 448149549;
  v_rtl1  pls_integer := 296885115;
  v_rtl2  pls_integer := 1555360261;
  v_line  pls_integer;
  function get_user_source ( p_name varchar2, p_line in out pls_integer ) return varchar2 is
      l   pls_integer;
      v_text varchar2(32767);
      v_type varchar2(20);
  begin
      l := nvl(p_line,0);
      v_type := 'PACKAGE';
      for c in (
          select text,line from user_source
           where type=v_type and name=p_name and line>l 
           and instr(text, '$HeadURL:') = 0 -- не учитывать откуда был взят исходник 
           order by line)
      loop
          v_text := v_text||c.text;
          if length(v_text)>28000 then
              p_line := c.line;
              return v_text;
          end if;
      end loop;
      p_line := 0;
      return v_text;
  end;
begin
  :v_const:= dbms_utility.get_hash_value(get_user_source('CONSTANT',v_line),0,2147483647);
  :v_rtl1 := dbms_utility.get_hash_value(get_user_source('RTL',v_line),0,2147483647);
  :v_rtl2 := dbms_utility.get_hash_value(get_user_source('RTL',v_line),0,2147483647);
  if :v_const = v_const and :v_rtl1 = v_rtl1 and :v_rtl2 = v_rtl2 then
    :v_equal := 1;
  else
    :v_equal := 0;
  end if;
end;
/


