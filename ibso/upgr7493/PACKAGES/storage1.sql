prompt storage_mgr
create or replace package storage_mgr as
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/storage1.sql $
 *  $Author: petrushov $
 *  $Revision: 126198 $
 *  $Date:: 2016-10-31 11:06:44 #$
 */

    verbose boolean;
    v8_flag boolean;
    v9_flag boolean;
    v10_flag    boolean;
    Use_Context BOOLEAN;
    Use_Orascn  BOOLEAN;
    Prt_Actual  BOOLEAN;
    pipe_name   varchar2(30);
    max_string  pls_integer;
    max_nstring  pls_integer;

    PART_NONE constant varchar2(1) := '0'; -- Не секционирована
    PART_KEY  constant varchar2(1) := '1'; -- Архивирование (PARTITION)
    PART_VIEW constant varchar2(1) := '2'; -- Архивирование (PARTVIEW)
    PART_PROF constant varchar2(1) := '3'; -- Секционирование по профилю

    /**
     * Versioning.
     * @return   Версию сервиса.
     */
    function get_version return varchar2;    
    
    -- Создает или модифицирует таблицы
    procedure update_class_storage(p_class_id varchar2,
                                   p_verbose boolean default false,
                                   p_pipe_name varchar2 default 'DEBUG',
                                   p_self_only boolean default false,
                                   p_build     boolean default false,
                                   p_delayed_actions_mode  boolean default false -- Признак включенного режима отложенных действий
                                  );

    procedure update_storage_scheme(p_verbose boolean default false,
                                    p_pipe_name varchar2 default 'DEBUG'
                                   );
    procedure add_dependencies(p_class_id varchar2,p_depend varchar2);
    procedure add_dependent_classes(p_class_id varchar2,
                                    p_include_ref_arr boolean default false);-- включить ТБП, в которых есть реквизиты типов ссылка и массив с указанным целевым типом
    procedure create_dependent_classes(p_class  varchar2,
                                       p_pipe   varchar2 default null,
                                       p_compile boolean default true,
                                       p_mode    boolean default false,
                                       p_self    boolean default false,
                                       p_delayed_actions_mode  boolean default false, -- Признак включенного режима отложенных действий
                                       p_include_ref_arr boolean default false -- включить ТБП, в которых есть реквизиты типов ссылка и массив с указанным целевым типом
                                       );
    procedure check_user(p_change boolean default false);

    /**
     * Проверяет непротеворечивость описания класса.
     * <ol>
     *   <li>Временный класс не может быть наследником постоянного
     *   <li>Постоянный класс не может быть наследником временного
     *   <li>Временный класс не может иметь разделов (партифицирован)
     *   <li>Если у класса есть таблица, то ее признак
     *     temporary должен совпадать с описанием в classes (проверяется если
     *     <code>check_table = true</code>)
     * </ol>
     * @param p_class_id Идентификатор класса
     * @param check_table Сравнивать ли признак temporary в описании класса и в таблице.
     * @throws message.sys_error(...) Если не все эти условия выполнены
     */
    procedure check_class_description(p_class_id varchar2);
    procedure check_temp_description(p_class_id  varchar2, p_parent varchar2, p_part boolean,
                                     p_temp_type varchar2, p_check_table boolean);

    -- Перекомпиляция объекта
    procedure recompile_object(p_name varchar2, p_type varchar2);

    -- Перекомпиляция зависимых от объекта
    procedure recompile_dependent(p_obj_name varchar2, p_obj_type varchar2);
    procedure restore_child_fkeys(p_class_id varchar2);

    -- Анализ одного или всех объектов
    procedure analyze_object(p_obj_name varchar2 default NULL, p_option varchar2 default null, p_owner varchar2 default null);

    -- Создает статический экземпляр для класса
    procedure create_static_object(p_class_id varchar2 default NULL);

    -- Удаляет статический экземпляр для класса
    procedure delete_static_object(p_class_id varchar2 default NULL);

    -- Создает интерфейсный пакет (доступ к реквизитам, конструктор, деструктор, копирование структур)
    procedure create_class_interface(p_class_id varchar2, body_only boolean default false);
    procedure create_child_interfaces(p_class_id varchar2);

    -- Триггеры для таблицы класса
    procedure create_triggers(p_class_id varchar2);

    -- Упаковка таблицы
    procedure reconcile_class_table(p_class_id  varchar2,
                                p_verbose   boolean  default false,
                                p_pipe_name varchar2 default 'DEBUG',
                                p_build     boolean  default true,
                                p_ratio     number   default 1,
                                p_tspace    varchar2 default null,
                                p_init_     number   default null,
                                p_next_     number   default null,
                                p_ini_trans number   default null,
                                p_max_trans number   default null,
                                p_pct_free  number   default null,
                                p_pct_used  number   default null,
                                p_min_exts  number   default null,
                                p_max_exts  number   default null,
                                p_pct_incr  number   default null,
                                p_lists     number   default null,
                                p_groups    number   default null,
                                p_degree    number   default null,
                                p_id        number   default null,
                                p_condition varchar2 default null,
                                p_idxtspace varchar2 default null,
                                p_mode      pls_integer default null);

    -- Имя интерфейсного пакета для класса
    function interface_package(p_class_id varchar2) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( interface_package, WNDS, WNPS );

    -- Имя PL/SQL или SQL типа, соответствующего классу
    function global_host_type(p_class_id varchar2, p_prec boolean default false, p_sql boolean default false) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES (global_host_type, WNDS, WNPS );

    function make_nt_table_name(p_table varchar2, p_qual varchar2, i pls_integer) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES (make_nt_table_name, WNDS,WNPS);

    procedure create_fk_by_objid(class_id_ varchar2);
    -- No comments
    function  get_storage_parameter( group_ varchar2, name_ varchar2) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( get_storage_parameter, WNDS, WNPS );
    procedure set_storage_parameter( group_ varchar2, name_ varchar2, value_ varchar2);
    procedure get_globals(tab_tablespace out varchar2, idx_tablespace out varchar2,
                          tmp_tablespace out varchar2, dbblock out integer);
    procedure set_storage_group( class_ varchar2 default null, group_ varchar2 default null);
    procedure set_lob_storage_group( class_ varchar2 default null, group_ varchar2 default null);

    /**
     * Исполняет SQL-команду. <br>
     * Выставляет значения переменных <a href="storage_utils.html#verbose">verbose</a> и
     * <a href="storage_utils.html#pipe_name">pipe_name</a> пакета
     * <a href="storage_utils.html">storage_utils</a> равными значениям
     * соответствующих своих переменных и, после этого, вызывает
     * <a href="storage_utils.html#execute_sql(varchar2,varchar2,boolean)">storage_utils.execute_sql</a>
     */
    procedure execute_sql ( p_sql_block clob, comment varchar2 default null, silent boolean default false );
    -- Output to pipe
    procedure WS(msg_str varchar2);

    -- No comments
    function  qual2elem(qual varchar2, varname varchar2 default null) return varchar2;
    -- No comments
    function  mapped(class_id_ varchar2, qual_ varchar2, table_ varchar2 default null) return boolean;
    function  has_column(table_name_ varchar2, column_name_  varchar2) return boolean;

    -- Создание/удаление триггера мапинга колонок
    procedure create_map_trigger(p_class_id varchar2);

    procedure uncoord(act_ varchar2 default 'SHOW',p_verbose boolean,p_pipe_name varchar2 default 'DEBUG');
    procedure map_column_data(src varchar2, dst varchar2, col varchar2);

    -- Заполнение дублированной колонки с предварительным отключением индексов и констрейнтов
    procedure map_column_data_cons_indexes(src_class_id varchar2, dst_table_owner varchar2, dst_table_name varchar2, column_name varchar2);

    -- Создание ограничений уникальности/индексов
    procedure create_indexes(p_class_id varchar2,p_retry pls_integer default null, p_position pls_integer default null);

    /**
     * Создает системные ограничения целостности для таблицы, разделов(partview) и зеркал (partition) класса.
     * @param p_class_id Идентификатор класса, для которого нужно создать ограничения
     * @param p_refs ???
     * @param p_position Если таблица класса партифицированна, то это номер раздела,
     * для которого нужно создать ограничения(в случае partview) или для зеркала которого
     * нужно создать ограничения(в случае partition). Причем:
     * <ul>
     *   <li>Если <code>p_position is null</code>, то создавать только для основной таблицы
     *   <li>Если <code>p_position = 0</code>, то создавать для основной таблицы плюс для
     *     всех разделов(зеркал)
     *   <li>Если <code>p_position > 0</code>, то создавать для основной таблицы плюс для
     *     раздела(зеркала раздела) с номером <code>p_position</code>
     * </ul>
     * @param p_force Режим проверки состояния ограничений целостности (0 - не проверять, 1- проверять свойство DEFERRABLE)
     */
    procedure create_constraints(p_class_id varchar2, p_refs boolean default false,p_position pls_integer default null,p_force pls_integer default 0,
                                 p_delayed_actions_mode  boolean default false -- Признак включенного режима отложенных действий
                                 );
    procedure drop_indexes(p_class_id varchar2,p_unused_only boolean default true, p_position pls_integer default null);

    /**
     * Удаляет системные ограничения целостности для таблицы, разделов(partview) и зеркал (partition) класса.
     * @param p_class_id Смотрите описание <a
     *   href="#create_constraints(varchar2,boolean,pls_integer)">create_constraints</a>
     * @param p_unused_only Если истина, то удаляет только ограничения,
     *   колонки которых удалены или отмечены как удаленные, а также ограничения на
     *   колонки-коллекции и колонки-ссылки, для которых явно указано не создавать ограничения.
     * @param p_position Смотрите описание <a
     *   href="#create_constraints(varchar2,boolean,pls_integer)">create_constraints</a>
     */
    procedure drop_constraints(p_class_id varchar2,p_unused_only boolean default true,p_position pls_integer default null);
    procedure restore_constraints(p_class_id varchar2, p_init boolean default true, p_part boolean default null,
                                  p_delayed_actions_mode  boolean default false -- Признак включенного режима отложенных действий
                                 );
--  Создание комментариев
    procedure create_comments( p_class varchar2 );

--Для новой технологии без OBJECTS
    function  view_col2obj_name( p_class_id varchar2, p_part varchar2 default null ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( view_col2obj_name, WNDS, WNPS );

    /**
     * Выполняет SQL (не выборку), длина которого может быть болше 32k.
     * @param p_sql Таблица с текстом SQL, который разбит на строки длиной до 256 символов.
     * @param comment Текст, который выводится через <a href="storage_utils.html#ws(varchar2)">storage_utils.ws</a>
     *   перед выполнением запроса.
     * @param p_err Выводить ли в <a href="storage_utils.html#ws(varchar2)">storage_utils.ws</a> описание
     *   исключений возникших во время выполнения SQL. Если <code>nvl(p_err, false) = false</code>
     *   ошибки никуда не выводятся.
     * @param p_nl Если <code>p_nl = true</code>, то, при соединении строк таблицы,
     *   вставляет после каждой из них перевод строки.
     */
    procedure create_object(p_sql   dbms_sql.varchar2s,
                            comment varchar2 default null,
                            p_err   boolean  default true,
                            p_nl    boolean  default false);
    procedure create_view_col2obj(p_class_id varchar2);
    procedure create_objects_view(p_err boolean default false);
    procedure create_collection_views(p_err boolean default false,p_build boolean default false);

    /**
     * Подсчет числа записей в таблице.
     * p_param - выражение для подсчета, если не задано, то равно 1.
     */
    function  rec_count( p_table varchar2, p_param varchar2 default null ) return integer;

    /**
     * Подсчет числа экземпляров класса.
     */
    function  obj_count( p_class varchar2 ) return integer;

    /**
     * Является ли тип системным.
     */
    function  is_kernel( p_class varchar2 ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( is_kernel, WNDS, WNPS );

    -- Партифицирована ли таблица ТБП
    function is_partitioned ( p_class  varchar2 ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( is_partitioned, WNDS, WNPS );

    /**
     * Является ли таблица класса временной.
     * @param p_class Идентификатор класса
     * @param p_type Если таблица класса временная, то через этот параметр возвращается ее тип:
     * <ul>
     *   <li>'D' - transaction-specific
     *   <li>'P' - session-specific
     * </ul>
     * @return '1' для временной таблицы и '0' в противном случае.
     */
    function is_temporary (p_class varchar2, p_type out varchar2) return varchar2;
    pragma RESTRICT_REFERENCES ( is_temporary, WNDS, WNPS );

    /**
     * Является ли таблица класса временной.
     * @param p_class Идентификатор класса
     * @return '1' для временной таблицы и '0' в противном случае.
     */
    function is_temporary (p_class varchar2) return varchar2;
    pragma RESTRICT_REFERENCES ( is_temporary, WNDS, WNPS );

    --Нужна ли классу таблица
    function class_needs_table(p_class_id varchar2, p_refs boolean default null) return boolean;
    function needs_log_table(p_class_id varchar2, p_self boolean default true) return boolean;
    --Нужна ли колонка таблице класса
    function needs_collection_id(class_id_ varchar2,p_self boolean default true,p_temp boolean default true) return boolean;
    function needs_state_id(class_id_ varchar2,p_self boolean default true) return boolean;
    function needs_class_id(class_id_ varchar2) return boolean;
    --Обновление описаний колонок
    procedure refresh_columns(p_class varchar2);
    --Проверка флага has_instances
    procedure check_has_instances( p_class varchar2 default null, p_pipe varchar2 default null, p_modify boolean default false );
    --
    procedure alter_tablespace (p_name varchar2, p_option varchar2 default null);

    /**
     * Определение идентификатора класса по имени его таблицы.
     * @param p_table Имя таблицы
     * @return Идентификатор класса, либо <code>null</code> если в
     *   <code>class_tab_columns</code> нет этой информации
     */
    function  table2class(p_table varchar2) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( table2class, WNDS, WNPS );

    procedure class2table(p_table out nocopy varchar2, p_owner out nocopy varchar2, p_class varchar2, p_arch varchar2);
    pragma RESTRICT_REFERENCES ( class2table, WNDS, WNPS );

    /**
     * Определение имени таблицы класса.
     * @param p_class Идентификатор класса
     * @param p_arch  Признак архива значений реквизитов (при значении '1')
     * @return Имя таблицы, либо <code>null</code> если в
     *   <code>class_tab_columns</code> нет этой информации
     */
    function  class2table(p_class varchar2,p_arch varchar2 default null,p_schema varchar2 default null) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( class2table, WNDS, WNPS );

    procedure delete_arc_table(p_class varchar2,p_drop boolean default false);
    procedure convert_obj_id(p_class varchar2,p_set_rights boolean default true);

    function check_trigger_events return boolean;
    function check_states(p_class_id class_attributes.class_id%type, p_check_state_exists boolean:=true) return boolean;
    procedure set_changes;

    -- Возвращает значение параметра хранения REBUILD.STORAGE_TEMPLATE
    function get_rebuild_storage_template(p_group varchar2) return varchar2;

	procedure actualize_transition_methods;
end;
/
sho err
