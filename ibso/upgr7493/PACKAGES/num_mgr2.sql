prompt num_mgr body
create or replace package body
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/num_mgr2.sql $
 *  $Author: Alexey $
 *  $Revision: 15072 $
 *  $Date:: 2012-03-06 13:41:17 #$
 */
num_mgr
is
  type seq_info_t is record (sequence_name    varchar2 (30),
                             min_value        number,
                             max_value        number,
                             start_value      number,
                             increment_by     number,
                             cycle_flag       varchar2 (1),
                             order_flag       varchar2 (1),
                             cache_size       number);

  function create_new(p_class_id in varchar2, p_attr_id in varchar2, p_step in number default null,
  p_startval in number default null, p_max_value in number default null, p_min_value in number default null,
  p_cache in number default null, p_ordered in varchar2 default 'N', p_cycled in varchar2 default 'N',
  p_restart_on_max in varchar2 default 'N') return varchar2;
  procedure restart_seq (p_seq in seq_info_t, p_start_value in number default null);
  function chk_name (p_name in varchar2) return varchar2;
  function get_group_no return integer;
  procedure exec_sql (p_sql in varchar2);
  function nxt(p_seqname in varchar2, p_limval in number) return number;
  procedure alter_seq(p_seq in seq_info_t, p_new_params seq_info_t);
  function is_system(p_id in varchar2, p_raise in boolean default true) return varchar2;
  procedure lock$ (p_id in varchar2);
  function get_sequence (p_increment in number, p_minvalue in number, p_maxvalue in number, p_startval in number,
    p_cache in number, p_cycle in varchar2, p_order in varchar2) return varchar2;

/*****************************************************************************************************************
Создание нового системного нумератора с заданными параметрами.
 Возвращает ID созданного объекта
 Параметры:
    p_class_id        класс,
    p_attr_id         реквизит,
    p_step            инкремент,
    p_startval        начальное значение,
    p_max_value       максимальное значение,
    p_min_value       минимальное значение,
    p_cache           кэш  (0 - нет кэша NOCACHE, число - CACHE  <число>, null - кэш по умолчанию Oracle),
    p_ordered         'Y' = 'ORDER' ,
    p_cycled          'Y' = 'CYCLE',
    p_restart_on_max  начинать заново при достижении максимального значения атрибута
    p_seq_only, p_seq если true, создать только последовательность p_seq
*****************************************************************************************************************/
function create_sys_numerator(p_class_id in varchar2, p_attr_id in varchar2, p_step in number default null,
  p_startval in number default null, p_min_value in number default null, p_max_value in number default null,
  p_cache in number default null, p_ordered in varchar2 default 'N', p_cycled in varchar2 default 'N',
  p_restart_on_max in varchar2 default 'N', p_seq in varchar2 default null, p_seq_only  in boolean default false)
 return varchar2
is
  v_status varchar2(1);
  v_num_id varchar2(30);
  v_seqname varchar2(30);

  cnt number;
begin

  if p_seq is not null and nvl(p_seq_only, false)  then

    v_seqname := p_seq;
    select count(1)
    into cnt
    from class_attributes
    where sequenced = p_seq and class_id <> p_class_id;
	  if cnt > 0 then
       select seq_id.nextval into v_seqname from dual;
       v_seqname := chk_name('SEQ_' || v_seqname);
    end if;
    select count(1) into cnt from dba_objects ao
    where ao.object_name=v_seqname and ao.object_type='SEQUENCE' and ao.owner=inst_info.gowner;
  	if cnt = 0 then
     create_seq(v_seqname, null, false);
  	end if;
    return  v_seqname;
  end if;

  select status, num_id
  into v_status, v_num_id
  from num_attributes
  where class_id = p_class_id and attr_id = p_attr_id;
  if v_status = 'D' then
    use_sys_numerator(p_class_id, p_attr_id, v_num_id);
    return v_num_id;
  else
    message.error('CLS', 'NUM_EXIST_CA', p_class_id, p_attr_id);
  end if;
exception
  when no_data_found then
    return create_new(p_class_id, p_attr_id, p_step, p_startval, p_max_value, p_min_value, p_cache, p_ordered, p_cycled,
           p_restart_on_max);
end;

/*****************************************************************************************************************
Создание нумераторов для уже существующих автонумеруемых реквизитов
 Параметры:
    p_class_id        класс
    p_attr_id         реквизит
Если параметры не заданы, то создаем для всех
****************************************************************************************************************/
procedure create_numerators(p_class_id in varchar2 default null, p_attr_id in varchar2 default null, p_rebuild in boolean default false)
is
  cursor attrs
  is
    select class_id, attr_id, sequenced,
    (select status from num_attributes na where ca.class_id = na.class_id and ca.attr_id = na.attr_id) status
    from class_attributes ca
    where sequenced is not null and class_id = nvl(p_class_id, class_id) and attr_id = nvl(p_attr_id, attr_id)
    order by class_id;

  v_sql varchar2(6000);
  v_seqname varchar2(30);
  v_add_seqname varchar2(30);
  v_id varchar2(30);
  v_startval number;
  v_step number;
  v_ordered varchar2(1);
  v_cycled varchar2(1);
  v_cache number;
  v_minvalue number;
  v_maxvalue number;
  v_group_no integer;
  v_exists number;
  v_class_id varchar2(16);
  v_res varchar2(4000);
begin
  for r in attrs loop
   stdio.put_line_buf(r.class_id||'.'||r.attr_id||':');
   if r.status = 'D' then
    update num_attributes
    set status = 'A'
    where class_id = r.class_id and attr_id = r.attr_id;
   elsif r.status is null then
    select count(*)
    into v_exists
    from num_attributes
    where num_id = r.sequenced;
    if v_exists > 0 then
     insert into num_attributes (class_id, attr_id, num_id, status)
     values (r.class_id, r.attr_id, r.sequenced, 'A');
    else
     select ' INCREMENT BY ' || increment_by || ' START WITH ' || nvl(case  when increment_by < 0 then max_value else min_value end, 1) ||
      case when max_value is not null then  ' MAXVALUE ' || max_value end ||
      case when min_value is not null then   ' MINVALUE ' || min_value  end ||
      case when cache_size = 0 then ' NOCACHE  ' when cache_size > 0 then  ' CACHE ' || cache_size  end ||
      case when cycle_flag = 'Y' then ' CYCLE ' end ||
      case when order_flag = 'Y' then  ' ORDER ' end,
      sequence_name, seq_id.nextval, nvl(case when increment_by < 0 then max_value else min_value end, 1),
      increment_by, cache_size, order_flag, cycle_flag, max_value, min_value
     into v_sql, v_seqname, v_add_seqname, v_startval, v_step, v_cache, v_ordered, v_cycled, v_maxvalue, v_minvalue
     from dba_sequences
     where sequence_owner = INST_INFO.GOWNER and sequence_name = r.sequenced;

     v_add_seqname := chk_name('SEQ_' || v_add_seqname);
     create_seq(v_add_seqname, v_sql);
     create_seq(v_seqname, null, true);
     insert into numerators(id, code, name, start_value, step, cache_size, order_flag, cycle_flag, max_value,
                            min_value, restart_on_max, system)
     values (v_seqname, v_seqname, v_seqname, v_startval, v_step, v_cache, v_ordered, v_cycled, v_maxvalue, v_minvalue,
             'N', 'Y');
     v_group_no := get_group_no;
     insert into sequences(num_id, seq_name, status, group_no)
     values (v_seqname, v_seqname, 'A', v_group_no);
     insert into sequences(num_id, seq_name, status, group_no)
     values (v_seqname, v_add_seqname, 'N', v_group_no);
     insert into num_attributes(class_id, attr_id, num_id, status)
     values (r.class_id, r.attr_id, v_seqname, 'A');
    end if;
    stdio.put_line_buf(r.class_id||'.'||r.attr_id||' created, id = '||v_seqname);
    if p_rebuild and (v_class_id is null or v_class_id <> r.class_id) then
     v_res := class_mgr.build_interface(r.class_id);
     stdio.put_line_buf(v_res);
    end if;
   end if;
   v_class_id := r.class_id;
  end loop;
  if p_rebuild then
   generate_num_values_pkg;
  end if;
end;

/*****************************************************************************************************************
Создание прикладного нумератора с заданными параметрами.
 Возвращает ID созданного объекта
 Параметры:
    p_code,  p_name   короткое имя (код), название
    p_step                    инкремент,
    p_startval             начальное значение,
    p_max_value         максимальное значение,
    p_min_value         минимальное значение,
    p_cache                кэш  (0 - нет кэша NOCACHE, число - CACHE  <число>, null - по умолчанию без кэша)
    p_ordered            'Y' = 'ORDER' по умолчанию Y
    p_cycled               'Y' = 'CYCLE'
    p_restart_on_max  начинать заново при достижении максимального значения атрибута
    p_seqname           можно задать название основной последовательности
*****************************************************************************************************************/
function create_user_numerator(p_code in varchar2, p_name in varchar2, p_step in number default null,
  p_startval in number default null, p_min_value in number default null, p_max_value in number default null,
  p_cache in number default 0, p_ordered in varchar2 default 'Y', p_cycled in varchar2 default 'N',
  p_restart_on_max in varchar2 default 'N',
  p_seqname in varchar2 default null)
  return varchar2
is
  v_sql varchar2(1000);
  v_id varchar2(30);
  v_code numerators.code%type := upper(trim(p_code));
  v_res_seqname varchar2(30);
  v_seqname varchar2(30);
  v_step number := nvl(p_step, INCREMENT_DEFAULT);
  v_max_value number := nvl(p_max_value, case when v_step < 0 then -1 else MAXVALUE_DEFAULT end);
  v_min_value number := nvl(p_min_value, case when v_step < 0 then MINVALUE_DEFAULT else 1 end);
  v_startval number := nvl(p_startval, case when v_step < 0 then v_max_value else v_min_value end);
  v_cache number := nvl(p_cache, 0);
  v_ordered varchar2(1) := nvl(upper(trim(p_ordered)), 'N');
  v_cycled varchar2(1) := nvl(upper(trim(p_cycled)), 'N');
begin

 v_sql := ' INCREMENT BY ' || v_step || ' START WITH ' || v_startval || ' MAXVALUE ' ||
           v_max_value || ' MINVALUE '   || v_min_value ||
           case when v_cache = 0 then ' NOCACHE  ' when v_cache > 0 then ' CACHE ' || v_cache end ||
           case when v_cycled = 'Y' then ' CYCLE ' end ||
           case when v_ordered = 'Y' then ' ORDER ' end;

  if p_seqname is not null then
    v_id := p_seqname;
    v_seqname := p_seqname;
  else
    v_seqname := get_sequence (v_step, v_min_value, v_max_value, v_startval, v_cache, v_cycled, v_ordered);
    if v_seqname is null then
      select seq_id.nextval into v_seqname from dual;
      v_seqname := chk_name('SEQ_APP_' || v_seqname);
      create_seq(v_seqname, v_sql);
    end if;
    v_id := v_seqname;
  end if;

  insert into numerators(id, code, name, start_value, step, cache_size, order_flag, cycle_flag, max_value, min_value, system, restart_on_max)
  values (v_id, nvl(v_code, v_id), nvl(p_name, v_id), v_startval, v_step, v_cache, v_ordered, v_cycled, v_max_value, v_min_value, 'N', nvl(p_restart_on_max, 'N'));

  insert into sequences(num_id, seq_name, status)
  values (v_id, v_seqname, 'A');

  -- вторая последовательность
  v_res_seqname := get_sequence (v_step, v_min_value, v_max_value, v_startval, v_cache, v_cycled, v_ordered);
  if v_res_seqname is null then
    select seq_id.nextval into v_res_seqname from dual;
    v_res_seqname := chk_name('SEQ_APP_' || v_res_seqname);
    create_seq(v_res_seqname, v_sql);
  end if;
  insert into sequences(num_id, seq_name, status)
  values (v_id, v_res_seqname, 'N');

  return v_id;
exception
  when dup_val_on_index then
    message.error('CLS', 'NUM_EXIST_CODE', v_code);
end;

/*****************************************************************************************************************
Рестарт нумератора.
 Параметры:
 p_id                 ID удаляемого объекта
 p_start_value        начальное значение
*****************************************************************************************************************/
procedure restart_numerator(p_id in varchar2, p_start_value in number)
is
  v_status varchar2(1);
  v_res_seqname varchar2(30);
  v_seq seq_info_t;
  v_seq1 seq_info_t;
  v_system varchar2(1);
  v_start number := p_start_value;
begin
  lock$(p_id);
  v_system := is_system(p_id);

  select status, seq_name
  into v_status, v_res_seqname
  from sequences
  where num_id = p_id
  and status <> 'A';

  select v_res_seqname, min_value, max_value, start_value, step, cycle_flag, order_flag, cache_size
  into v_seq1
  from numerators
  where id = p_id;

  if p_start_value is not null and not p_start_value between v_seq1.min_value and v_seq1.max_value then
    v_start := case when v_seq1.increment_by > 0 then v_seq1.min_value else v_seq1.max_value end;
  end if;

  if v_status = 'N' then /* резервная последовательность готова к использованию */
   if v_start is not null and v_seq1.start_value <> v_start then
    restart_seq(v_seq1, v_start);
   end if;
   update sequences
   set status = case status when 'A' then 'I' else 'A' end
   where num_id = p_id;
  else
   if v_status = 'I' then /* резервная последовательность была сдвинута */
    restart_seq(v_seq1, v_start);
    update sequences
    set status = case status when 'A' then 'I' else 'A' end
    where num_id = p_id;
   end if;
   if v_status = 'P' then /* у резервной последовательности нужно изменить параметры  */
     select v_res_seqname, min_value, max_value,
      case when increment_by > 0 then min_value else max_value end,
      increment_by, cycle_flag, order_flag, cache_size
     into v_seq
     from dba_sequences
     where sequence_owner = INST_INFO.GOWNER and sequence_name = v_res_seqname;
     alter_seq(v_seq, v_seq1);
     restart_seq(v_seq1, v_start);
     update sequences
     set status = case status when 'A' then 'I' else 'A' end
     where num_id = p_id;
   end if;
  end if;

  num_interface.reset_numerator(p_id);
  num_interface.send_event(p_id);

exception
  when others then
    message.raise_ (-20092, 'Ошибка при рестарте нумератора: ' || sqlerrm, true);
end;

/*****************************************************************************************************************
Изменение параметров последовательностей в нумераторе.
  Параметры:
    p_id              ID нумератора,
    p_step            инкремент,
    p_max_value       максимальное значение,
    p_min_value       минимальное значение,
    p_start_value     начальное значение,
    p_cache           кэш
    p_ordered         'Y' = 'ORDER'
    p_cycled          'Y' = 'CYCLE'
    p_restart_on_max  начинать заново при достижении максимального значения атрибута
Задаем только изменяемые параметры.
*****************************************************************************************************************/
procedure alter_numerator(p_id in varchar2, p_step in number default null, p_min_value in number default null,
  p_max_value in number default null, p_start_value in number default null,  p_cache in number default null, p_ordered in varchar2 default null,
  p_cycled in varchar2 default null, p_restart_on_max in varchar2 default null, p_restart in number default null)
is
  v_sql varchar2(1000);
  v_res_params seq_info_t;
  v_new_params seq_info_t;
  v_max_cache_size number;
begin
  lock$(p_id);
  select sequence_name, min_value, max_value,
  case when increment_by > 0 then min_value else max_value end,
  increment_by,  cycle_flag, order_flag, cache_size
  into v_res_params
  from dba_sequences, sequences
  where num_id = p_id
  and status <> 'A'
  and sequence_owner = INST_INFO.GOWNER
  and sequence_name = seq_name;

  select  v_res_params.sequence_name, nvl(p_min_value, min_value), nvl(p_max_value, max_value),
   nvl(p_start_value, start_value) start_value,
   nvl(p_step, step),
   nvl(p_cycled, cycle_flag), nvl(p_ordered, order_flag), nvl(p_cache, cache_size)
  into v_new_params
  from numerators
  where id = p_id;

    if v_new_params.max_value <= v_new_params.min_value then
   message.error('CLS', 'NUM_INVALID_MAXVAL');
  end if;
  if v_new_params.increment_by > v_new_params.max_value - v_new_params.min_value then
   message.error('CLS', 'NUM_INVALID_INCR');
  end if;
  v_max_cache_size := ceil(v_new_params.max_value - v_new_params.min_value) / abs(v_new_params.increment_by);
  if v_new_params.cycle_flag = 'Y' and v_new_params.cache_size > v_max_cache_size then
   message.error('CLS', 'NUM_INVALID_CACHE', trunc(v_max_cache_size));
  end if;
  if v_new_params.start_value < v_new_params.min_value then
   message.error('CLS', 'NUM_START_LESS_MINVAL');
  elsif v_new_params.start_value > v_new_params.max_value then
   message.error('CLS', 'NUM_START_MORE_MAXVAL');
  end if;
  alter_seq(v_res_params, v_new_params);
  update numerators
  set step = v_new_params.increment_by, max_value = v_new_params.max_value, min_value = v_new_params.min_value,
      cache_size = v_new_params.cache_size, order_flag = v_new_params.order_flag, cycle_flag = v_new_params.cycle_flag,
      restart_on_max = nvl(p_restart_on_max, restart_on_max),
      start_value = v_new_params.start_value
  where id = p_id;
  update sequences
  set status = 'I'
  where seq_name = v_res_params.sequence_name
  and status = 'N';

  restart_seq(v_new_params, nvl(p_restart, v_new_params.start_value));

  update sequences
  set status = case status when 'A' then 'P' else 'A' end
  where num_id = p_id;


  num_interface.reset_numerator(p_id);
  num_interface.send_event(p_id);

exception
  when no_data_found then
    message.error('CLS', 'NUM_NOT_EXIST');
end;

/*****************************************************************************************************************
Удаление нумератора
  Параметры:
    p_id              ID нумератора,
    p_class_id        класс
    p_attr_id         атрибут
    p_force           режим:
    если прикладной нумератор и p_force = false, не дропаем активную последовательность; иначе дропаем обе.
    если системный нумератор и не p_force, меняем статус на D, ничего не удаляя.
*****************************************************************************************************************/
procedure delete_numerator(p_id in varchar2, p_class_id in varchar2 default null, p_attr_id in varchar2 default null,
  p_force in boolean default false)
is
  v_system varchar2(1);
  v_used integer;
begin
  lock$(p_id);
  v_system :=  is_system(p_id, false);
  if v_system = 'Y' and (p_class_id is null or p_attr_id is null) then
    message.error('CLS', 'NUM_NOT_EXIST_CA', p_attr_id, p_class_id);
  end if;

  num_interface.reset_numerator(p_id);
  num_interface.send_event(p_id);

  if v_system = 'N' then
   if p_force then
    for s in (select seq_name from sequences where num_id = p_id) loop
     delete_seq(s.seq_name);
    end loop;
   else
    for s in (select seq_name from sequences where num_id = p_id and status <> 'A') loop
     delete_seq(s.seq_name);
    end loop;
   end if;
   delete sequences
   where num_id = p_id;
   delete numerators
   where id = p_id;
  else
   if not p_force then
    update num_attributes
    set status = 'D'
    where num_id = p_id and class_id = p_class_id and attr_id = p_attr_id;
    return;
   end if;
   select count(1)
   into v_used
   from num_attributes
   where num_id = p_id;
   if v_used > 1 then
    delete num_attributes
    where num_id = p_id and class_id = p_class_id and attr_id = p_attr_id;
    return;
   end if;
   -- если p_force = true и нет ссылок, то удаляем
   delete sequences
   where num_id = p_id;
   delete num_attributes
   where num_id = p_id;
   delete numerators
   where id = p_id;

   for s in (select seq_name  from sequences  where num_id = p_id) loop
    delete_seq(s.seq_name);
   end loop;

   -- перегенируем пакет, поскольку реально удалили последовательности и он стал невалидным
   generate_num_values_pkg;
  end if;

exception
  when no_data_found then
    -- если не нашли нумератор, пытаемся удалить последовательность
    select count(1)
    into v_used
    from dba_sequences
    where sequence_owner = inst_info.gowner
    and sequence_name = p_id;
    if v_used > 0 then
     delete_seq(p_id);
    else
     message.error('CLS', 'NUM_NOT_EXIST');
    end if;
end;

/*****************************************************************************************************************
Переименование прикладного нумератора
 Параметры:
  p_id                ID
  p_new_code          новый код
  p_new_name          новое название
*****************************************************************************************************************/
procedure rename_numerator(p_id in varchar2, p_new_code in varchar2, p_new_name in varchar2)
is
begin
  if is_system(p_id) = 'Y' then
    message.error('CLS', 'NUM_SYS');
  end if;
  lock$(p_id);
  update numerators
  set code = nvl(upper(trim(p_new_code)), code), name = nvl(trim(p_new_name), name)
  where id = p_id;
  num_interface.reset_numerator(p_id);
  num_interface.send_event(p_id);
exception
  when dup_val_on_index then
    message.error('CLS', 'NUM_DUB_CODE');
  when e_val_too_big then
    message.error('CLS', 'NUM_VAL_TOO_BIG');
end;

/*****************************************************************************************************************
Процедура подготавливает "испорченные" резервные последовательности (у которых статус I или P)
для дальнейшего использования.
*****************************************************************************************************************/
procedure prepare_res_sequences
is
  v_num seq_info_t;
  v_seq seq_info_t;
begin
  for ns  in (select num_id, status, seq_name from sequences where status in ('I', 'P')) loop
   begin
    lock$(ns.num_id);
    select ns.seq_name, min_value, max_value, start_value, step, cycle_flag, order_flag, cache_size
    into v_num
    from numerators
    where id = ns.num_id;
    if ns.status = 'P' then
     select ns.seq_name, min_value, max_value, case when increment_by > 0 then min_value else max_value end,
      increment_by, cycle_flag, order_flag, cache_size
     into v_seq
     from dba_sequences
     where sequence_owner = inst_info.gowner
     and sequence_name = ns.seq_name;
     alter_seq(v_seq, v_num);
    end if;
    restart_seq(v_num);
    update sequences
    set status = 'N'
    where num_id = ns.num_id and status = ns.status;
   exception
    when others then null;
   end;
  end loop;
end;

/*****************************************************************************************************************
Процедура устанавливает дополнительные свойства нумератора
  Параметры:
  p_id                ID нумератора
  p_property          название свойства
  p_value             значение свойства
*****************************************************************************************************************/
procedure set_property(p_id in varchar2, p_property in varchar2, p_value in varchar2)
is
  v_properties varchar2(2000);
  p_errm varchar2(1000);
begin
  lock$(p_id);
  select properties
  into v_properties
  from numerators
  where id = p_id;
  method.put_property(v_properties, p_property, p_value);
  update numerators
  set properties = v_properties
  where id = p_id;
exception
  when no_data_found then
    message.error('CLS', 'NUM_NOT_EXIST');
end;

/*****************************************************************************************************************
Процедура перевода нумератора в обычную последовательность
  Параметры:
    p_id              ID нумератора
    p_class_id        класс
    p_attr_id         реквизит
    p_rebuild         перестраивать интерфейсный пакет
*****************************************************************************************************************/
procedure num_to_sequence (p_id in varchar2, p_class_id in varchar2, p_attr_id in varchar2, p_rebuild in boolean default false)
is
  v_seqname varchar2(30);
  v_res_seqname varchar2(30);
  v_used pls_integer;
  v_res varchar2(4000);
begin
  if is_system(p_id) = 'N' then
    message.error('CLS', 'NUM_NOT_EXIST');
  end if;
  select count(1)
  into v_used
  from num_attributes
  where num_id = p_id;
  if v_used > 1 then
    message.error('CLS', 'NUM_IS_USED');
  end if;

  for s in (select seq_name, status from sequences where num_id = p_id) loop
    if s.status = 'A' then
     v_seqname := s.seq_name;
    else
     v_res_seqname := s.seq_name;
    end if;
  end loop;

  update class_attributes
  set sequenced =v_seqname
  where class_id = p_class_id
  and attr_id = p_attr_id;

  delete num_attributes
  where num_id = p_id
  and class_id = p_class_id
  and attr_id = p_attr_id;

  delete sequences
  where num_id = p_id;

  delete numerators
  where id = p_id;

  delete_seq(v_res_seqname);
  generate_num_values_pkg;
  if p_rebuild then
    v_res := class_mgr.build_interface(p_class_id);
    stdio.put_line_buf(v_res);
  end if;
end;


/*****************************************************************************************************************
Функция ищет свободный неиспользуемый секвенс и преобразует его согласно заданным параметрам
  Параметры:
    p_increment    инкремент; по умолчанию 1
    p_minvalue      минимальное значение (или максимальное, если инкремент отрицательный)
    p_maxvalue     максимальное значение (или минимальное, если инкремент отрицательный)
    p_startval        начальное значение; если не задано, то минимальное
    p_cache            кэш, по умолчанию 0
    p_cycle             циклическая; по умолчанию если не задан максимум/минимум, то  'N' иначе 'Y'
    p_order            флаг упорядоченности
*****************************************************************************************************************/
function get_sequence (p_increment in number, p_minvalue in number, p_maxvalue in number, p_startval in number,
                        p_cache in number, p_cycle in varchar2, p_order in varchar2) return varchar2
is
  sequences SYS_REFCURSOR;
  v_exist number;
  v_sql varchar2(1000) :=
   'select  sequence_name, min_value, max_value,
    case when increment_by > 0 then min_value else max_value end,
    increment_by,  cycle_flag, order_flag, cache_size
    from all_sequences
    where sequence_owner = ''' || INST_INFO.GOWNER ||
    '''and sequence_name like ''SEQ_APP_%''
   and substr(sequence_name, 9) is not null
    and not exists
    (select 1
     from sequences
      where seq_name = sequence_name)
    and rownum <= 10';

  v_seqname varchar2(30);
  v_seq seq_info_t;
  v_new_params seq_info_t;
begin
  -- проверим существование класса COUNTERS
  select count(1)
  into v_exist
  from classes
  where id = 'COUNTERS';
  if v_exist > 0 then
    v_sql := v_sql || ' and not exists
                                (select 1
                                from z#counters
                                where c_seq_name = sequence_name)';
  end if;

  open sequences for v_sql;
  fetch sequences into v_seq;
  loop
    begin
      v_new_params.increment_by := p_increment;
      v_new_params.min_value  := p_minvalue;
      v_new_params.max_value := p_maxvalue;
      v_new_params.start_value := p_startval;
      v_new_params.cache_size  := p_cache;
      v_new_params.cycle_flag   :=  p_cycle;
      v_new_params.order_flag  :=  p_order;
      v_new_params.sequence_name := v_seq.sequence_name;

      alter_seq(v_seq, v_new_params);
      restart_seq(v_new_params, v_new_params.start_value);
      return v_seq.sequence_name;
    exception
      when others then null;
    end;
    fetch sequences into v_seq;
    exit when sequences%notfound;
  end loop;
  return null;
end;

--


procedure use_sys_numerator(p_class_id in varchar2, p_attr_id in varchar2, p_num_id in varchar2)
is
  v_class_id varchar2(16) := upper(trim(p_class_id));
  v_attr_id varchar2(16) := upper(trim(p_attr_id));
  v_num_id varchar2(30) := upper(trim(p_num_id));
begin
  insert into num_attributes(class_id, attr_id, num_id, status)
  values (v_class_id, v_attr_id, v_num_id, 'A');
exception
  when dup_val_on_index then
    update num_attributes
    set status = 'A'
    where class_id = v_class_id and attr_id = v_attr_id and num_id = v_num_id;
end;

--
function create_new(p_class_id in varchar2, p_attr_id in varchar2, p_step in number default null,
  p_startval in number default null, p_max_value in number default null, p_min_value in number default null,
  p_cache in number default null, p_ordered in varchar2 default 'N', p_cycled in varchar2 default 'N',
  p_restart_on_max in varchar2 default 'N')
  return varchar2
is
  v_sql varchar2(1000);
  v_seqname varchar2(30);
  v_res_seqname varchar2(30);
  v_step number := nvl(p_step, INCREMENT_DEFAULT);
  v_max_value number := nvl(p_max_value, case when v_step < 0 then -1 else MAXVALUE_DEFAULT end);
  v_min_value number := nvl(p_min_value, case when v_step < 0 then MINVALUE_DEFAULT else 1 end);
  v_startval number := nvl(p_startval, case when v_step < 0 then v_max_value else v_min_value end);
  v_cache number := nvl(p_cache, CACHE_DEFAULT);
  v_ordered varchar2(1) := upper(trim(p_ordered));
  v_cycled varchar2(1) := upper(trim(p_cycled));
  v_class_id varchar2(16) := upper(trim(p_class_id));
  v_attr_id varchar2(16) := upper(trim(p_attr_id));
  v_used number;
  v_id varchar2(30);
  v_group_no integer;
begin
  select seq_id.nextval into v_seqname from dual;
  v_seqname := chk_name('SEQ_' || v_seqname);
  insert into numerators(id, code, name, start_value, step, cache_size, order_flag, cycle_flag, max_value, min_value,
   restart_on_max, system)
  values (v_seqname, v_seqname, v_seqname, v_startval, v_step, v_cache, v_ordered, v_cycled, v_max_value, v_min_value,
   upper(trim(p_restart_on_max)), 'Y');
  insert into num_attributes(class_id, attr_id, num_id, status)
  values (v_class_id, v_attr_id, v_seqname, 'A');
  v_group_no := get_group_no;
  insert into sequences(num_id, seq_name, status, group_no)
  values (v_seqname, v_seqname, 'A', v_group_no);
  select seq_id.nextval into v_res_seqname from dual;
  v_res_seqname := chk_name('SEQ_' || v_res_seqname);
  insert into sequences(num_id, seq_name, status, group_no)
  values (v_seqname, v_res_seqname, 'N', v_group_no);

  v_sql := ' INCREMENT BY ' || v_step || ' START WITH ' || v_startval || ' MAXVALUE ' || v_max_value || ' MINVALUE '
           || v_min_value || case
             when v_cache = 0 then ' NOCACHE  '
             when v_cache > 0 then ' CACHE ' || v_cache
           end || case when v_cycled = 'Y' then ' CYCLE ' end || case
             when v_ordered = 'Y' then ' ORDER '
           end;

  create_seq(v_seqname, v_sql);
  create_seq(v_res_seqname, v_sql);
  generate_num_values_pkg;
  return v_seqname;
end;
--
function chk_name(p_name in varchar2)
  return varchar2
is
  v_name varchar2(30);
begin
  if length(p_name) > 30 then
   v_name := case substr(p_name, 1, instr(p_name, '_', -1, 1)) when 'SEQ_' then 'SE' else 'SA' end ||
             substr(p_name,  1+instr (p_name, '_', -1, 1));
   return v_name;
  end if;
  return p_name;
end;
--
procedure create_seq(p_name in varchar2, p_sql in varchar2, p_grants_only boolean default false)
is
  pragma autonomous_transaction;
begin
  if not p_grants_only then
    storage_utils.execute_sql('create sequence ' || p_name || ' ' || p_sql, p_owner => INST_INFO.GOWNER);
  end if;
  class_mgr.check_grant(p_name, INST_INFO.GOWNER, false);
end;
--
function get_group_no return integer
is
  v_cnt number;
  v_group integer;
begin
  select nvl(max(group_no), 0)
  into v_group
  from sequences;
  if v_group < SEQ_GROUPS_QTY then
   return v_group + 1;
  else
   select gp
   into v_group
   from (select gp, count(group_no)
         from sequences s,  (select level gp from dual connect by level <= SEQ_GROUPS_QTY) grps
         where group_no(+) = gp
         group by gp
         order by 2, 1)
   where rownum = 1;
   return v_group;
  end if;
end;
--
procedure generate_num_values_pkg
is
  v_spec_sql varchar2(4000)
    := 'PACKAGE num_values is ' || NL ||
       ' FUNCTION next$(p_group IN pls_integer,p_seqname IN varchar2) RETURN number;' || NL ||
       'END;';
  v_sql clob;
  gr_cnt number;
  cur_gr number := 1;
  first_if number := 1;
  sql_text integer;
  rows_processed integer;

begin
  v_sql := 'CREATE OR REPLACE PACKAGE BODY num_values ' || NL || 'IS ' || NL || TB || 'FUNCTION next$ ' || NL || TB
           || TB || '(p_group in pls_integer, ' || NL || TB || TB || 'p_seqname in varchar2) ' || NL || TB ||
           'RETURN number ' || NL || 'IS ' || NL || TB || 'v_next number;  ' || NL || 'BEGIN ' || NL ||
           TB||' IF p_group is null then '||NL||TB||TB||
           ' execute immediate ''SELECT '' || p_seqname || ''.NEXTVAL from dual'' into v_next;'||NL||TB||
             'return v_next;'||NL||TB||'END IF;';
  select min(group_no)
  into cur_gr
  from sequences, numerators
  where id = num_id
  and system = 'Y';

  if cur_gr is null then
    v_sql := v_sql || ' execute immediate ''SELECT '' || p_seqname || ''.NEXTVAL from dual'' into v_next;'||NL||TB||
             'return v_next;'||NL||'END;'||NL||'END;';
  else
    v_sql := v_sql || 'IF p_group = ' || cur_gr || ' THEN ' || NL;
    for s in (select seq_name, group_no gr,
              ' p_seqname =''' || seq_name || ''' then ' || NL || TB || TB || TB || 'Select ' || seq_name ||
              '.nextval into v_next from dual;' || NL || TB || TB || TB || 'return v_next;' || NL if_text
              from sequences, numerators
              where id = num_id
              and system = 'Y'
              order by gr, to_number(substr(seq_name, instr(seq_name, '_', -1) + 1))) loop
     if cur_gr <> s.gr then
      v_sql := v_sql || TB || TB || 'END IF; ' || NL || TB || 'END IF;' || NL;
      v_sql := v_sql || TB || 'IF p_group = ' || s.gr || ' then IF ' || s.if_text;
      first_if := 0;
     else
      if first_if = 1 then
       v_sql := v_sql || TB || TB || 'IF ' || s.if_text;
       first_if := 0;
      else
       v_sql := v_sql || TB || TB || 'ELSIF ' || s.if_text;
      end if;
     end if;
     cur_gr := s.gr;
    end loop;
    v_sql := v_sql || TB || TB || 'END IF; ' || NL || TB || 'END IF; ' || NL || TB ||
             'EXECUTE IMMEDIATE ''SELECT '' || p_seqname || ''.NEXTVAL from dual'' into v_next;' || NL || TB ||
             'RETURN v_next;' || NL || 'END;' || NL || 'END;';
  end if;
  sql_text := dbms_sql.open_cursor;
  -- package cpec
  if trim(translate(v_spec_sql,NL,'  ')) <> nvl(trim(translate(method.get_user_source('NUM_VALUES', 'PACKAGE'),NL,'  ')), ' ') then
    dbms_sql.PARSE(sql_text, 'CREATE OR REPLACE '||v_spec_sql, dbms_sql.NATIVE);
    rows_processed := dbms_sql.execute(sql_text);
  end if;
  -- package body
  dbms_sql.PARSE(sql_text, v_sql, dbms_sql.NATIVE);
  rows_processed := dbms_sql.execute(sql_text);
  dbms_sql.close_cursor(sql_text);
exception
  when others then
   if dbms_sql.is_open(sql_text) then
      dbms_sql.close_cursor(sql_text);
   end if;
   raise;
end;
--
procedure alter_seq(p_seq in seq_info_t, p_new_params in seq_info_t)
is
  v_curval number;
  v_delta number;
  v_seqname varchar2(61) := INST_INFO.GOWNER || '.' || p_seq.sequence_name;
  v_limval number;
begin
  -- если отменяем цикл, сделаем это прежде всего
  /*if p_new_params.cycle_flag = 'N' and p_seq.cycle_flag = 'Y' then
   exec_sql('ALTER SEQUENCE ' || v_seqname || ' NOCYCLE');
  end if;*/

  exec_sql('ALTER SEQUENCE ' || v_seqname || ' NOCYCLE');

  v_limval := case when p_seq.increment_by > 0 then p_seq.max_value else p_seq.min_value end;
  v_curval := nxt(p_seq.sequence_name, v_limval);

  if p_seq.max_value = p_new_params.min_value and v_curval = p_seq.max_value then
    exec_sql('ALTER SEQUENCE ' || v_seqname || ' INCREMENT BY 1');
    v_curval := nxt(p_seq.sequence_name, v_limval);
  end if;

  --если текущее значение больше минимального делаем альтер минимум = новый минимум
  -- и инкремент такой, чтобы спозиционироваться на новом минимуме
  if v_curval > p_new_params.min_value then
    begin
      exec_sql('ALTER SEQUENCE ' || v_seqname || ' MINVALUE ' || p_new_params.min_value || ' INCREMENT BY ' || (p_new_params.min_value - v_curval));
    exception
     when E_INC_TOO_BIG then
      v_delta := p_new_params.min_value - v_curval;
      if v_delta < 0 then
       exec_sql('ALTER SEQUENCE ' || v_seqname || ' MINVALUE ' || p_new_params.min_value);
       while 1 = 1 loop
        exec_sql('ALTER SEQUENCE ' || v_seqname || ' INCREMENT BY ' || MIN_INCREMENT);
        v_curval := nxt(p_seq.sequence_name, v_limval);
        v_delta := p_new_params.min_value - v_curval;
        exit when v_delta > MIN_INCREMENT;
       end loop;
       if v_delta <> 0 then
         exec_sql('ALTER SEQUENCE ' || v_seqname || ' MINVALUE ' || p_new_params.min_value || ' INCREMENT BY ' || v_delta);
       end if;
      end if;
    end;
    v_curval := nxt(p_seq.sequence_name, v_limval);
  elsif v_curval < p_new_params.min_value then
   --если текущее значение меньше нового минимального делаем альтер максимум = новый максимум
   -- и инкремент такой, чтобы спозиционироваться на новом минимуме
   exec_sql('ALTER SEQUENCE ' || v_seqname || ' MAXVALUE ' || p_new_params.max_value || ' INCREMENT BY ' || (p_new_params.min_value - v_curval));
   v_curval := nxt(p_seq.sequence_name, v_limval);
  end if;
  -- теперь после этих манипуляций можем установить все требуемые значения
  exec_sql('ALTER SEQUENCE ' || v_seqname || ' MAXVALUE ' || p_new_params.max_value || ' MINVALUE ' || p_new_params.min_value ||
           ' INCREMENT BY  ' || p_new_params.increment_by || case when p_new_params.order_flag = 'Y' then ' ORDER ' end ||
           case when p_new_params.cycle_flag = 'Y' then ' CYCLE ' else ' NOCYCLE ' end ||
           case when p_new_params.cache_size = 0 then ' NOCACHE ' else ' CACHE ' || p_new_params.cache_size end);
end;
--
procedure restart_seq(p_seq in seq_info_t, p_start_value in number default null)
is
  v_seqname varchar2(61) := INST_INFO.GOWNER || '.' || p_seq.sequence_name;
  v_curval number;
  v_startval number;
  v_delta number;
  v_limval number;
begin

  v_limval := case when p_seq.increment_by > 0 then p_seq.max_value else p_seq.min_value end;
  if p_seq.cycle_flag = 'Y' and ((p_seq.increment_by > 0 and p_start_value < p_seq.min_value + p_seq.increment_by)
                                 or
                                 (p_seq.increment_by < 0 and p_start_value > p_seq.max_value + p_seq.increment_by)) then
   v_startval := p_seq.start_value;
   --v_startval := nvl(p_start_value, p_seq.start_value);
  else
   v_startval := nvl(p_start_value, p_seq.start_value);
  end if;
  if v_startval < p_seq.min_value and p_seq.increment_by > 0 then
   message.error('CLS', 'START_LESS_MINVAL');
  elsif v_startval > p_seq.max_value and p_seq.increment_by < 0 then
   message.error('CLS', 'START_MORE_MAXVAL');
  end if;
  v_curval := nxt(p_seq.sequence_name, v_limval);
  v_delta := v_startval - v_curval - p_seq.increment_by;

  if p_seq.cycle_flag = 'Y' and abs(v_delta) > abs(p_seq.max_value - p_seq.min_value) then
    v_delta :=  p_seq.min_value - p_seq.max_value;
  end if;

  if v_delta <> 0 then
   exec_sql ('ALTER SEQUENCE ' || v_seqname || ' NOCACHE INCREMENT BY ' || v_delta ||
             case when p_seq.cycle_flag <> 'Y' then
              case when p_seq.increment_by > 0 then ' MINVALUE ' || least(p_seq.min_value, v_curval +v_delta-p_seq.increment_by)
                   else ' MAXVALUE ' || greatest (p_seq.max_value, v_curval +v_delta-p_seq.increment_by)
                  end
             end);
   v_curval := nxt(p_seq.sequence_name, v_limval);
   if p_seq.cycle_flag <> 'Y' and v_curval <> (v_startval - p_seq.increment_by) then  /* может быть, если вышли за границы */
     exec_sql('ALTER SEQUENCE ' || v_seqname || ' INCREMENT BY  ' || - (v_curval - (v_startval - p_seq.increment_by)));
     v_curval := nxt(p_seq.sequence_name, v_limval);
   end if;

   exec_sql('ALTER SEQUENCE ' || v_seqname || ' INCREMENT BY ' || p_seq.increment_by ||
            case when p_seq.cache_size <> 0 then ' CACHE ' || p_seq.cache_size end ||
            case when p_seq.cycle_flag <> 'Y' then
                 case when p_seq.increment_by > 0 then ' MINVALUE ' || greatest((p_seq.min_value-p_seq.increment_by), MINVALUE_DEFAULT)
                      else ' MAXVALUE ' || least((p_seq.max_value-p_seq.increment_by), MAXVALUE_DEFAULT)
                 end
            end);
  end if;
end;
--
procedure exec_sql(p_sql in varchar2)
is
  pragma autonomous_transaction;
begin
  execute immediate (p_sql);
end;
--
function nxt(p_seqname in varchar2, p_limval in number)
  return number
is
  v_rs number;
  v_sql varchar2(1000);
begin
  v_sql := 'SELECT ' || p_seqname || '.NEXTVAL FROM dual';

  execute immediate v_sql  into v_rs;
  return v_rs;
exception
  when E_SEQ_LIMIT_VALUE then
    v_rs := p_limval;
    return v_rs;
end;
--
function is_system(p_id in varchar2, p_raise in boolean default true)
  return varchar2
is
  v_system varchar2(1);
begin
  select system
  into v_system
  from numerators
  where id = p_id;
  return v_system;
exception
  when no_data_found then
   if p_raise then
    message.error('CLS', 'NUM_NOT_EXIST');
   else
    raise;
   end if;
end;
--
procedure lock$(p_id in varchar2)
is
  cursor p_lock
  is
   select *
   from numerators, sequences s, num_attributes na
   where id = p_id and id = s.num_id and id = na.num_id
   for update nowait;
begin
  open p_lock;
  close p_lock;
exception
  when rtl.resource_busy then
    message.error('CLS', 'NUM_LOCKED');
end;
--
procedure delete_seq(p_seqname in varchar2)
is
 pragma autonomous_transaction;
begin
  if p_seqname is not null then
      storage_utils.execute_sql('drop sequence ' || p_seqname, p_owner => inst_info.gowner, p_silent => true);
      if inst_info.owner <> inst_info.gowner then
        storage_utils.execute_sql('drop synonym '||p_seqname, p_owner=>inst_info.owner, p_silent => true);
      end if;
  end if;
end;

end;
/
show err package body num_mgr

