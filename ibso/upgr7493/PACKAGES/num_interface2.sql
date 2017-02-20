prompt num_interface body
create or replace package body
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/num_interface2.sql $
 *  $Author: Alexey $
 *  $Revision: 15072 $
 *  $Date:: 2012-03-06 13:41:17 #$
 */
num_interface
is
  numerators num_info_tbl_c;

  c_event_code constant pls_integer  := 15;
  E_NUMERROR pls_integer := -20090;
  E_NUM_NOTEXIST pls_integer := -20091;
  v_err1 varchar2 (1000) :=message.get_text('CLS', 'NUM_VAL_ERROR');
  v_err2 varchar2 (1000) :=message.get_text('CLS', 'NUM_NOT_EXIST');

/*****************************************************************************************************************
 Получение параметров нумератора и обновление коллекции, в случае если нумератор существует, но еще не
 присутствует в коллекции
 Параметры:
 p_id               ID нумератора
 p_num_info  свойства нумератора
*****************************************************************************************************************/
procedure num_exist (p_id in varchar2, p_num_info in out nocopy num_info_t, p_class_id in varchar2 default null, p_attr_id in varchar2 default null)
is
begin
   if p_id is null or length(p_id)>30 then
       p_num_info := null;
       raise_application_error(E_NUM_NOTEXIST, v_err2);
   end if;
   rtl.read;
   if numerators.exists(p_id) then
       p_num_info := numerators(p_id);
       if p_num_info.id is not null then return;
       else
          raise_application_error(E_NUM_NOTEXIST, v_err2);
       end if;
   end if;
    select id, code, name, step, start_value, min_value, max_value, cache_size, order_flag, cycle_flag, restart_on_max,
    system, seq_name, group_no
    into p_num_info
    from numerators nm, sequences s
    where id= num_id
    and s.status = 'A'
    and id = p_id
    and (system = 'Y' and exists (select 1 from num_attributes na where class_id = nvl(p_class_id, class_id) and attr_id = nvl(p_attr_id, attr_id) and status = 'A') or system='N');

    numerators(p_id) := p_num_info;
exception when no_data_found then
    p_num_info := null;
    numerators(p_id) := p_num_info;
    raise_application_error(E_NUM_NOTEXIST, v_err2);
end;

/*****************************************************************************************************************
 Удаление заданного нумератора из коллекции/удаление всей коллекции
 Параметры:
 p_id         ID удаляемого объекта; если null, то удалять все
*****************************************************************************************************************/
procedure reset_numerator(p_id in varchar2)
is
begin
  if p_id is null then
    numerators.delete;
    return;
  end if;
  if numerators.exists(p_id) then
    numerators.delete(p_id);
  end if;
end;

/*****************************************************************************************************************
 Функция возвращает следующее значение нумератора. В случае, если возвращаемое значение больше
 указанной максимальной длины реквизита и у него установлено свойство restart_on_max, происходит
 сброс нумерации
 Параметры:
 p_class_id     класс
 p_attr_id      артибут
 p_id              ID нумератора
 p_max_len   максимальная длина реквизита
*****************************************************************************************************************/
function next$ (p_class_id in varchar2, p_attr_id in varchar2, p_id in varchar2, p_maxlen in pls_integer default null) return number
is
  v_numerator num_info_t;
  v_curval number;
  v_restart number;
begin
  num_exist(p_id, v_numerator, p_class_id, p_attr_id);
  v_curval := num_values.next$(v_numerator.seq_grp, v_numerator.seqname);
  if p_maxlen < 27 and length(v_curval) > p_maxlen and v_numerator.restart_on_max = 'Y' then
    num_mgr.restart_numerator(p_id, case when v_numerator.step < 0 then least(to_number(lpad('9', p_maxlen, '9')), v_numerator.max_value) end);
    num_exist(p_id, v_numerator, p_class_id, p_attr_id);
    v_curval := num_values.next$(v_numerator.seq_grp, v_numerator.seqname);
  end if;
  return v_curval;
exception
  when  num_mgr.e_seq_limit_value then
    if v_numerator.restart_on_max = 'Y' then
      if v_numerator.step < 0 then
        v_restart :=  least(to_number(lpad('9', nvl(p_maxlen, 27), '9')), v_numerator.max_value);
      else
        v_restart := v_numerator.min_value;
      end if;
      num_mgr.restart_numerator(p_id, v_restart);
      num_exist(p_id, v_numerator, p_class_id, p_attr_id);
      return num_values.next$(v_numerator.seq_grp, v_numerator.seqname);
    else
     message.err(-20998, 'CLS', 'NUM_MAX_CA',p_attr_id, p_class_id);
    end if;
    when  NUM_INTERFACE.E_NUM_NOT_EXIST then
    message.err(-20998, 'CLS', 'NUM_NOT_EXIST_CA', p_attr_id, p_class_id);
end;

/*****************************************************************************************************************
Определение активной последовательности нумератора.
 Параметры:
 p_id              ID нумератора
*****************************************************************************************************************/
function get_num_sequence(p_id in varchar2)
  return varchar2
is
  v_numerator num_info_t;
begin
  num_exist(p_id, v_numerator);
  return v_numerator.seqname;
end;

/*****************************************************************************************************************
 Отправка сообщения другим сессиям при изменении последовательности нумератора или его свойств
  Параметры:
    p_id     ID нумератора
*****************************************************************************************************************/
procedure send_event(p_id in varchar2)
is
begin
  rtl.send_events(c_event_code, p_id);
end;


/*****************************************************************************************************************
 Получение информации о нумераторе
  Параметры:
    p_id     ID нумератора
*****************************************************************************************************************/
procedure get_num_info(p_id in varchar2, p_num_info out num_info_t)
is
begin
  num_exist(p_id, p_num_info);
end;

/*****************************************************************************************************************
Функция возвращает ID нумератора по его коду или классу/атрибуту.
 Параметры:
    p_code            код нумератора
    p_class_id        класс
    p_attr_id         реквизит
*****************************************************************************************************************/
function get_num_id (p_code in varchar2 default null, p_class_id in varchar2 default null, p_attr_id in varchar2 default null,
                     p_raise in boolean default true) return varchar2
is
  v_id varchar2(30);
begin
  if p_code is not null then
    select id
    into v_id
    from numerators
    where code = p_code;
  else
    select num_id
    into v_id
    from num_attributes
    where class_id = p_class_id
    and attr_id = p_attr_id;
  end if;
  return v_id;
exception
  when no_data_found then
    if p_raise then
        message.error('CLS', 'NUM_NOT_EXIST');
    else
       return null;
    end if;
  end;

/*****************************************************************************************************************
Проверка близости к граничному значению
 Возвращает true, если текущее значение приблизилось к граничному менее чем на заданный процент
 Параметры:
 p_id                 ID нумератора
 p_percent            процент
*****************************************************************************************************************/
function is_close_to_max (p_id in varchar2, p_percent in number default 10)
return boolean
is
  v_curval number;
  v_num_info num_interface.num_info_t;
begin
  get_num_info(p_id, v_num_info);
  select last_number
  into v_curval
  from all_sequences
  where sequence_name = v_num_info.seqname
  and sequence_owner = inst_info.gowner;

  if v_num_info.step > 0 then
    return v_curval > v_num_info.max_value - (v_num_info.max_value - v_num_info.min_value) * p_percent/100;
  else
    return v_curval < v_num_info.min_value +   (v_num_info.max_value - v_num_info.min_value) * p_percent/100;
  end if;
end;

/*****************************************************************************************************************
Рестарт нумератора
 Параметры:
 p_id                 ID удаляемого объекта
 p_start_value        начальное значение
*****************************************************************************************************************/
procedure restart_numerator(p_id in varchar2, p_start_value in number)
is
begin
  num_mgr.restart_numerator(p_id, p_start_value);
end;

/*****************************************************************************************************************
Функция получения дополнительных свойств нумератора
  Параметры:
  p_id                ID нумератора
  p_property          название свойства
*****************************************************************************************************************/
function get_property(p_id in varchar2, p_property in varchar2)
  return varchar2
is
  v_properties varchar2(2000);
begin
  select properties
  into v_properties
  from numerators
  where id = p_id;
  return method.extract_property(v_properties, p_property);
exception
  when no_data_found then
    message.error('CLS', 'NUM_NOT_EXIST');
end;

end;
/
show err package body num_interface

