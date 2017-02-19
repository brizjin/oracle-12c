-- Перегенерация индекса в rtl_entries
-- Автор: Калугин Алексей
declare
  cur_idx pls_integer;
  n pls_integer := 0;
  m rtl.refstring_table;
procedure init_rtl_idx(p_mid varchar2,p_next in out nocopy pls_integer) is
  g_rtl_idx pls_integer;
  props   varchar2(100);
begin
  g_rtl_idx := null;
  for i in (select min(id) id from rtl_entries where method_id=p_mid)
  loop
      g_rtl_idx:=trunc(i.id,-2)+1;
      exit;
  end loop;
  if g_rtl_idx is null then
    g_rtl_idx:= method.get_property(p_mid,'RTLBASE');
    if g_rtl_idx is not null then
      begin
          select method_id into props from rtl_entries where id=g_rtl_idx;
          g_rtl_idx := null;
      exception when NO_DATA_FOUND then null;
          insert into rtl_entries(id,method_id,name,type,params,features)
          values(g_rtl_idx,p_mid,'<DUMMY>','P',0,'0');
      end;
    end if;
  end if;
  if nvl(g_rtl_idx,0)<1001 then
    g_rtl_idx := method.get_rtl_idx(p_next);
    p_next := g_rtl_idx+100;
    method.set_property(p_mid,'RTLBASE',g_rtl_idx);
    stdio.put_line_buf(p_mid||' - put new rtl index: '||g_rtl_idx);
    insert into rtl_entries(id,method_id,name,type,params,features)
    values(g_rtl_idx,p_mid,'<DUMMY>','P',0,'0');
  end if;
end;
begin
  select id bulk collect into m
    from methods x
    where kernel='0' and (
       status='NOT COMPILED'
       or exists(select 1 from rtl_entries r where r.method_id = x.id)
      )
      for update nowait;
  n := m.count;
  stdio.put_line_buf('Found '||n||' methods');
  for i in 1..n loop
    init_rtl_idx(m(i),cur_idx);
    --exit when i>99;
  end loop;
end;
/
