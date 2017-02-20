create or replace package calendar_mgr is
/**
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/calen_mgr1.sql $<br/>
 *  $Author: verkhovskiy $<br/>
 *  $Revision: 50083 $<br/>
 *  $Date:: 2014-08-14 18:23:13 #$
 *  @headcom
 */

/* Не было попыток откомпилировать правило, т.е. о нем ничего не известно. */
ST_NOT_COMPILED constant pls_integer := 1;
/* Правило было откомпилированно. */
ST_VALID constant pls_integer := 2;
/* Правило содержит ошибки. */
ST_INVALID constant pls_integer := 3;

NIL constant varchar2(1) := chr(0);

/* Структура для кэширования информации о календаре. */
type calendar_rec_t is record (
  id number,
  has_exceptions boolean,
  status pls_integer,
  name varchar2(16),
  rule varchar2(32767)
);

/**
 * Преобразование строки статуса в числовое значение.
 * @return
 *   <ul>
 *     <li><code>'NOT COMPILED'</code>, если <code>p_status = </code><a href="#ST_NOT_COMPILED"><code>ST_NOT_COMPILED</code></a>
 *     <li><code>'VALID'</code>, если <code>p_status = </code><a href="#ST_VALID"><code>ST_VALID</code></a>
 *     <li><code>'INVALID'</code>, если <code>p_status = </code><a href="#ST_INVALID"><code>ST_INVALID</code></a>
 *     <li><code>null</code> в остальных случаях
 *   </ul>
 */
function status_str_to_num(p_status in varchar2) return pls_integer;
PRAGMA RESTRICT_REFERENCES(status_str_to_num, RNDS, WNDS, WNPS);

/**
 * Преобразование числового значение в строку статуса.
 * @return  если <code>p_staus</code> не из предопределенного набора.
 *   <ul>
 *     <li><a href="#ST_NOT_COMPILED"><code>ST_NOT_COMPILED</code></a>, если <code>p_status = 'NOT COMPILED'</code>
 *     <li><a href="#ST_VALID"><code>ST_VALID</code></a>, если <code>p_status = 'VALID'</code>
 *     <li><a href="#ST_INVALID"><code>ST_INVALID</code></a>, если <code>p_status = 'INVALID'</code>
 *     <li><code>null</code> в остальных случаях
 *   </ul>
 */
function status_num_to_str(p_status in pls_integer) return varchar2;
PRAGMA RESTRICT_REFERENCES(status_num_to_str, RNDS, WNDS, WNPS);

/**
 * Получение массива признаков за диапазон дат как строчку.
 */
function get_dates(p_calendar_name in varchar2,
       p_date in date, p_period in binary_integer) return varchar2;

/**
 * Синтаксическая проверка правила, с помощью dbms_sql.parse
 */
FUNCTION check_rule(rule IN VARCHAR2, bRaise IN VARCHAR2 DEFAULT NULL)
    RETURN BINARY_INTEGER;

/**
 * Разослать оповещение об изменении календаря.
 * Используется для оповещения других сессии о том, что она изменила
 * данные о календаре.
 * @param p_calendar_name Имя календаря.
 * <ul>
 *   <li> Если <code>p_calendar_name is not null</code>, то
 *     изменился календарь с таким именем.
 *   <li> Если <code>p_calendar_name is null</code>, то
 *     изменилось несколько календарей.
 * </ul>
 */
procedure update_cache_event(p_calendar_name in varchar2);

/**
 * Обновить информацию о календаре в кэше.
 * Используется при оповещении из другой сессии о том, что она изменила
 * данные о календаре. Если, на момент вызова, в кэше нет данных о календаре,
 * то, чтобы минимизировать объем данных в сессиях не использующих
 * этот календарь, они не добавляются.
 * @param p_calendar_name Имя календаря.
 * <ul>
 *   <li> Если <code>p_calendar_name is not null</code>, то
 *     из базы вычитывается информация о календаре с таким именем.
 *     Если такого календаря нет, то информация о нем удаляется из кэша
 *     и кидается исключение NO_DATA_FOUND.
 *   <li> Если <code>p_calendar_name is null</code>, то
 *     кэш полностью сбрасывается (нужно, если обновили несколько календарей).
 * </ul>
 */
procedure update_cache(p_calendar_name in varchar2);

/**
 * Получение информацию о календаре.
 * Если в кэше нет данных о календаре, то они вычитываются из базы,
 * при этом, если в базе этих данных нет, то кидается NO_DATA_FOUND.
 * @param p_calendar_name Имя календаря.
 * @param p_info Сюда копируются данные о календаре.
 */
procedure get_info(p_calendar_name in varchar2, p_info out calendar_rec_t);

/**
 * Создание календаря.
 * @param p_calendar_name Имя календаря.
 * @param p_rule Правило проверки принадлежности даты.
 * @param p_description Описание календаря
 */
procedure create_calendar(p_calendar_name in varchar2,
                          p_rule in varchar2, p_description in varchar2);
/**
 * Редактирование календаря. Если значение параметра равно NIL
 *   то соответствующая колонка не меняется.
 * @param p_calendar_name Имя календаря.
 * @param p_rule Правило проверки принадлежности даты.
 * @param p_description Описание календаря.
 */
procedure edit_calendar(p_calendar_name in varchar2,
                        p_rule in varchar2 := NIL, p_description in varchar2 := NIL);
/**
 * Удаление календаря.
 * Исключения/записи о выполненной работе, относящиеся к календарю, удаляются тоже.
 * @param p_calendar_name Имя календаря. Если <code>p_description is null</code>,
 *   то удаляются все календари.
 */
procedure delete_calendar(p_calendar_name in varchar2);

/**
 * Создание исключения/записи о выполненной работе.
 */
procedure insert_value(p_calendar_name in varchar2,
                       p_value in date, p_type in varchar2);

/**
 * Удаление исключения/записи о выполненной работе.
 * Если какой-либо из аргументов <code>is not null</code>,
 * то удаляются только исключения со знаяением соответствующего
 * поля равным этому аргументу. Если больше чем один аргумент
 * <code>is not null</code> то соответствующие условия
 * на значения полей комбинируются по <code>and</code>.
 */
procedure delete_value(p_calendar_name in varchar2,
                       p_value in date, p_type in varchar2);
/**
 * Прверка существования исключения/записи о выполненной работе.
 * Влияние значения аргументов на проверку аналогично
 * <a href="#delete_value(varchar2,date,varchar2)">delete_value</a>
 * @return
 * <ul>
 *   <li> '1' - если существует
 *   <li> '0' - если не существует
 * </ul>
 */
function has_value(p_calendar_name in varchar2,
                    p_value in date, p_type in varchar2) return varchar2;

/**
 * Модификация исключения.
 */
procedure set_exception(p_calendar_name in varchar2, p_date in date, p_type in varchar2);

/**
 * Очистка исключений.
 */
procedure delete_exception(p_calendar_name in varchar2, p_date in date);

/**
 * Установка правила и исключений, и перекомпиляция.
 */
procedure set_rule_and_excs(p_calendar_name in varchar2,
        p_rule in varchar2, p_compile in boolean, p_values in varchar2);

/**
 * Создает интерфейс пакета calendar_rules. Более подробное описание см. в
 * <a href="#build_calendar_rules_body">build_calendar_rules_body</a>
 */
PROCEDURE build_calendar_rules_iface;

/**
 * Создает тело пакета calendar_rules.
 * Пакет содержит всего одну функцию
 * <code>function check_date(id number, d date) return varchar2;</code>,
 * которая проверяет принадлежит ли дата <code>d</code> календарю <code>id</code>.
 * Пакет нужен чтобы не выполнять проверки через динамический sql.
 * @return
 * <ul>
 *   <li> '1' - если принадлежит
 *   <li> '0' - если не принадлежит
 *   <li> null - если на момент генерации пакета календаря <code>id</code>
 *     не существовало, либо он содержал синтаксически неверное условие
 *     на принадлежность дат.
 * </ul>
 */
PROCEDURE build_calendar_rules_body;

/**
 * TOOLS\CALENDAR\c_undo.sql
 */
procedure register_calendar;
/**
 * TOOLS\CALENDAR\c_first.sql
 */
procedure unregister_calendar;
/**
 * Проверка даты в календаре
 */
function check_date(CALENDAR IN OUT NOCOPY CALENDAR_REC_T,D IN date,RULEONLY IN varchar2) return varchar2;
END calendar_mgr;
/
sho err

