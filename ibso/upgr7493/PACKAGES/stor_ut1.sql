prompt storage_utils
create or replace package storage_utils as
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/stor_ut1.sql $
 *  $Author: vzhukov $
 *  $Revision: 124343 $
 *  $Date:: 2016-10-13 16:57:33 #$
 */
--
    verbose boolean := false;
    pipe_name varchar2(30) := 'DEBUG';
--
    --Поиск/удаление мусора в БД - потеряные коллекции, права на экземпляры, OLE-объекты
    procedure lost_collections(act_ varchar2 default 'SHOW',p_verbose boolean default true,p_pipe_name varchar2 default 'DEBUG',p_target varchar2 default null);
    procedure lost_rights(act_ varchar2 default 'SHOW',p_verbose boolean default true,p_pipe_name varchar2 default 'DEBUG');
    procedure lost_oles(act_ varchar2 default 'SHOW',p_verbose boolean default true,p_pipe_name varchar2 default 'DEBUG');

    -- Вычисление оптимальных параметров хранени
    function  optimal_param (p_size number, p_initial varchar2 default null) return varchar2 deterministic;
    pragma restrict_references(optimal_param,wnds,wnps);

    procedure optimal_params(p_size number, sp_init out varchar2 , sp_next out varchar2);
    pragma restrict_references(optimal_params,wnds,wnps);

    procedure get_optimal_param(seg_name in varchar2, sp_init out varchar2 , sp_next out varchar2, p_owner varchar2 default null);
    pragma restrict_references(get_optimal_param,wnds,wnps);

    function  optimal_group (p_size number,p_param varchar2 default null) return varchar2 deterministic;
    pragma restrict_references(optimal_group,wnds,wnps);
    
    function build_ref_constraint_name(p_table_name varchar2, p_postfix varchar2) return varchar2 deterministic;
    pragma restrict_references(build_ref_constraint_name,wnds,wnps);
    
    function build_parallel return pls_integer deterministic;
    pragma restrict_references(build_parallel,wnds,wnps);

    function build_nologging return varchar2 deterministic;
    pragma restrict_references(build_nologging,wnds,wnps);

    function direct_insert_hint return varchar2 deterministic;
    pragma restrict_references(direct_insert_hint,wnds,wnps);

    function build_online return varchar2 deterministic;
    pragma restrict_references(build_online,wnds,wnps);

    function build_novalidate return varchar2;
    pragma restrict_references(build_novalidate,wnds,wnps);

    function build_deferrable return varchar2;
    pragma restrict_references(build_deferrable,wnds,wnps);

    -- PLATFORM-3493 создание ограничений целостности вместе с индексами при партификации таблицы
    function build_constr_with_index return boolean;
    pragma restrict_references(build_constr_with_index,wnds,wnps);

    function  get_sql_type(p_type varchar2,p_size pls_integer,p_prec pls_integer,p_scale pls_integer) return varchar2 deterministic;
    pragma restrict_references(get_sql_type,wnds,wnps,rnds,rnps);

    function  get_column_type(p_table varchar2,p_column varchar2,p_prec varchar2,p_owner varchar2 default null) return varchar2 deterministic;
    pragma restrict_references(get_column_type,wnds,wnps);

    function  get_column_props(p_table varchar2,p_column varchar2,
              col_type  in out nocopy varchar2,
              col_len   in out nocopy pls_integer,
              col_prec  in out nocopy pls_integer,
              col_scale in out nocopy pls_integer,
              col_not_null in out nocopy varchar2,
              p_owner   varchar2 default null ) return boolean;
    pragma restrict_references(get_column_props,wnds,wnps);

    function  get_object_schema(p_object varchar2, p_type varchar2, p_all varchar2 default null) return varchar2 deterministic;
    pragma restrict_references(get_object_schema,wnds,wnps);

    function  get_project_owner(p_object varchar2, p_type varchar2) return varchar2 deterministic;
    pragma restrict_references(get_project_owner,wnds,wnps);

    procedure analyze_object(p_obj_name varchar2, p_subobject varchar2 default null,
                             p_option   varchar2 default null,
                             p_cascade  boolean  default null,
                             p_degree   pls_integer default null,
                             p_owner    varchar2 default null);

    --  Создание системных индексов
    procedure create_indexes(p_class_id varchar2,p_retry pls_integer, p_position pls_integer);

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
    procedure create_constraints(p_class_id varchar2, p_refs boolean, p_position pls_integer, p_force pls_integer,
                                 p_delayed_actions_mode  boolean default false -- Признак включенного режима отложенных действий
                                );
    --  Удаление системных индексов
    procedure drop_indexes(p_class_id varchar2,p_unused_only boolean, p_position pls_integer);

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
    procedure drop_constraints(p_class_id varchar2,p_unused_only boolean,p_position pls_integer);
    -- Триггеры для таблицы класса
    procedure create_triggers (p_class_id varchar2, p_refs boolean default false);
    procedure create_refced_triggers (p_class_id varchar2, p_ref_part boolean default false, p_refs boolean default false);
    procedure create_refcing_triggers(p_class_id varchar2, p_ref_part boolean default false, p_refs boolean default false);
    procedure create_unique_trigger  (p_class_id varchar2);
    procedure drop_triggers(p_class_id varchar2,p_type varchar2 default null);
    -- Процедура для обновления триггеров по ссылкам для типа не имеющего экземпляров
    procedure update_refced_triggers(p_class_id varchar2);

    /**
     * Преобразование типа колонки таблицы.
     * @param base1 Базовый тип колонки назначения
     * @param base2 Базовый тип колонки источника
     * @param type1 Тип колонки назначения
     * @param type2 Тип колонки источника
     * @param col Имя преобразуемой колонки
     * @param len Длина до которой обрезается преобразованное значение если
     *    <code>base1 in ('STRING','MEMO')</code>
     * @param krn1 Признак <code>kernel</code> типа колонки назначения
     * @param krn2 Признак <code>kernel</code> типа колонки источника
     * @return
     * <ul>
     *   <li>Если функция не "знает" как преобразовать, то возвращает <code>null</code>.
     *   <li>Если преобразование невозможно, то возвращает <code>'NULL'</code>.
     *   <li>Во всех остальных случаях возвращает SQL-выражение для преобразования
     *     типа колонки при выборке из таблицы. Например,
     *     <code>get_conv('STRING', 'DATE', 'VARCHAR2', 'DATE', 'my_col', 10, '0', '0')</code>
     *     вернет <code>'SUBSTR(TO_CHAR(my_col,''YYYY-MM-DD HH24:MI:SS''), 1, 10)'</code>.
     * </ul>
     */
    function  get_conv(base1 varchar2, base2 varchar2, type1 varchar2, type2 varchar2, col varchar2, len number) return varchar2;
    function  conv_ref_table(p_class varchar2,p_column varchar2,
                             p_context boolean default null,p_mirror varchar2 default null) return varchar2;
    function  find_id_column(p_class varchar2,p_attr in out nocopy varchar2,p_owner in out nocopy varchar2,p_column in out nocopy varchar2) return varchar2;

    --procedure rebuild_referencies;
    procedure rebuild_col2obj;
    procedure rebuild_refs;
    procedure rebuild_fkeys;

    -- Удаляет записи, у которых нет соответствия в родительских/дочерних таблицах
    procedure delete_stuff(p_parent boolean default false,p_class varchar2 default null);
    -- Добавляет отсутствующие записи в таблицы
    procedure add_missing_records(p_parent boolean default false,p_class varchar2 default null);

    /**
     * Инициализирует пустые коллекции.
     * Поиск коллекций происходит по всем колонкам всех таблиц классов.
     * При этом порядок поиска определяется алфавитной сортировкой
     * по имени таблицы и имени колонки. Начинается поиск с колонки следующей за
     * определяемой параметрами <code>p_table</code> и <code>p_column</code>.
     * Однако если задан <code>p_once</code>, то поиск начинается с самой колнки
     * определяемой параметрами <code>p_table</code> и <code>p_column</code>, и,
     * при этом, обрабатывается только первая найденая колонка-коллекция.
     * Если задан <code>p_class</code>, то колонка также должна принадлежать
     * таблице класса <code>p_class</code>.
     * @param p_table Имя таблицы,с которой начинать искать коллекции.
     *   Если не задано, рассматриваются все таблицы классов.
     * @param p_column Имя колонки,с которой(со следующей за которой) начинать
     *   искать коллекции. Работает только если задан <code>p_table</code>.
     * @param p_class Идентификатор класса, в таблице которого искать коллекции
     * @param p_once Если истина, то обрабатывается первая найденая коллекция.
     * @param p_position Смотрите описание
     *   <a href="#init_class_id(varchar2,boolean,pls_integer)">init_class_id</a>
     */
    procedure update_empty_collections (p_table varchar2 default NULL, p_column varchar2 default null,
                                        p_class varchar2 default NULL, p_once   boolean  default false,
                                        p_position pls_integer default null);

    /**
     * Обнуляет несуществующие ссылки.
     * Описание того, как происходит поиск ссылок, а также назначение параметров
     * <code>p_table</code>, <code>p_column</code>, <code>p_class</code> и
     * <code>p_once</code> смотрите в <a
     * href="#update_empty_collections(varchar2,varchar2,varchar2,boolean,pls_integer)">update_empty_collections</a>
     * @param p_ole Если истина, то ищутся ссылки на ole-объекты
     *   (т.е. на таблицу long_data). В противном случае ищутся ссылки на классы.
     * @param p_position Смотрите описание
     *   <a href="#init_class_id(varchar2,boolean,pls_integer)">init_class_id</a>
     */
    procedure update_invalid_references(p_table varchar2 default NULL, p_column varchar2 default null,
                                        p_class varchar2 default NULL, p_once   boolean  default false,
                                        p_ole boolean default false, p_position pls_integer default null);

    /**
     * Обнуляет колонку (заполняет пустую).
     * @param p_class Идентификатор класса, колонку которого нужно обнулить/заполнить
     * @param p_column Имя обнуляемой/заполняемой колонки
     * @param p_value Значение, которым заполняется колонка.
     * @param p_where Условие на строки таблицы, в которых изменяется колонка.
     *   Если не задано, то определяется в зависисмомти от <code>p_value</code>:
     *   <ul>
     *     <li><code>p_value is null</code>: <code>p_where := 'IS NOT NULL'</code> - колонка обнуляется
     *     <li><code>p_value is not null</code>: <code>p_where := 'IS NULL'</code> - колонка заполняется
     *   </ul>
     * @param p_position Смотрите описание
     *   <a href="#init_class_id(varchar2,boolean,pls_integer)">init_class_id</a>
     */
    procedure clear_column (p_class varchar2, p_column varchar2, p_value varchar2 default null,
                            p_where varchar2 default null, p_position pls_integer default null);

    /**
     * Преобразование значений колонки
     * @param p_class Идентификатор класса, колонку которого нужно преобразовать
     * @param p_column Имя преобразуемой колонки
     * @param p_updcol Имя результируюшей колонки
     * @param p_conv Выражение для преобразования значений колонки в формате результата
     *   <a href="storage_mgr.html#get_conv(varchar2,varchar2,varchar2,varchar2,varchar2,integer,varchar2,varchar2)">get_conv</a>
     * @param p_position Смотрите описание
     *   <a href="#init_class_id(varchar2,boolean,pls_integer)">init_class_id</a>
     */
    procedure move_column (p_class varchar2, p_column varchar2, p_updcol varchar2,
                           p_conv  varchar2, p_position pls_integer default null);

    procedure cons_indexes(p_table varchar2,p_column varchar2,p_drop boolean,p_cascade boolean,p_owner varchar2 default null);
    procedure convert_id_column(p_class varchar2,p_column varchar2,p_col_owner varchar2,p_qual varchar2);
    procedure convert_obj_id(p_class varchar2,p_set_rights boolean default true);

    /**
     * Инициализация <code>CLASS_ID</code> в поддереве иерархии наследования.
     * @param p_class Идентификатор класса, который является корнем поддерева
     *   иерархии наследования, в котором нужно обновить <code>CLASS_ID</code>
     * @param p_clear Если истина, то, перед инициализацией, в таблице класса
     *   <code>p_class</code> обнуляется колонка <code>CLASS_ID</code>
     * @param p_position Если не <code>null</code>, то, кроме основной таблицы,
     *   также инициализируются partviews и зеркала(если они есть).
     *   <ul>
     *     <li>Если <code>p_position = 0</code>, то инициализируются все partviews(зеркала)
     *     <li>Если <code>p_position > 0</code>, то инициализируется partview(зеркало)
     *       с указанным номером раздела.
     *   </ul>
     */
    procedure init_class_id (p_class varchar2, p_clear boolean default false,
                             p_position pls_integer default null);

    procedure clear_diarys;

    /**
     * Выводит сообщение в pipe.
     * Выводит только если <code><a href="#verbose">verbose</a> = true</code>.
     * Имя pipe определяется <a href="#verbose">pipe_name</a>.
     * @param msg_str Сообщение.
     */
    procedure ws(msg_str varchar2);

    /**
     * Выполняет SQL.
     * @param p_sql_block Текст SQL.
     * @param p_comment Текст, который выводится через <a href="#ws(varchar2)">ws</a>
     *   перед выполнением запроса.
     * @param p_silent Выводить ли в <a href="#ws(varchar2)">ws</a> описание
     *   исключений возникших во время выполнения SQL. Если <code>nvl(silent, false) = false</code>
     *   ошибки никуда не выводятся.
     */
    procedure execute_sql( p_sql_block clob, p_comment varchar2 default null,
                           p_silent boolean default false, p_owner varchar2 default null );

    /**
     * Выполняет SQL.
     * @param p_sql_block Текст SQL.
     * @param p_comment Текст, который выводится через <a href="#ws(varchar2)">ws</a>
     *   перед выполнением запроса.
     * @param p_silent Выводить ли в <a href="#ws(varchar2)">ws</a> описание
     *   исключений возникших во время выполнения SQL. Если <code>nvl(silent, false) = false</code>
     *   ошибки никуда не выводятся.
     * @return Количество затронутых запросом строк.
     */
    function  execute_sql( p_sql_block clob, p_comment varchar2 default null,
                           p_silent boolean default false, p_owner varchar2 default null ) return number;

    /**
     * Разбивает текст на части длиной <= 256 и помещает их в PL\SQL таблицу.
     * @param p_text Текст
     * @param p_buf PL\SQL таблица, куда помещается разбитый текст.
     * @param p_end Если <code>true</code>, добавлять разбитый текст в
     *   конец таблицы, в противном случае - в начало.
     */
    procedure put_text_buf(p_text varchar2,
                           p_buf in out nocopy dbms_sql.varchar2s,
                           p_end boolean := true);
    /**
     * Сравнивает текст, содержащийся в pl\sql таблицах.
     * Разбивка текста на строки не влияет на результаты сравнения,
     * т.е. текст может быть разбит на строки по-разному.
     * @param p_buf1 Первая таблица с текстом
     * @param p_buf2 Вторая таблица с текстом
     */
    function texts_equal(p_buf1 dbms_sql.varchar2s,
                        p_buf2 dbms_sql.varchar2s) return boolean;
    /**
     * Выполняет SQL (не выборку), длина которого может быть болше 32k.
     * @param p_sql_block Таблица с текстом SQL, который разбит на строки длиной до 256 символов.
     * @param comment Текст, который выводится через <a href="#ws(varchar2)">ws</a>
     *   перед выполнением запроса.
     * @param p_ins_nl Если <code>p_ins_nl = true</code>, то, при соединении строк таблицы,
     *   вставляет после каждой из них перевод строки.
     * @param silent Выводить ли в <a href="#ws(varchar2)">ws</a> описание
     *   исключений возникших во время выполнения SQL. Если <code>nvl(silent, false) = false</code>
     *   ошибки никуда не выводятся.
     */
    procedure execute_sql(p_sql_block dbms_sql.varchar2s, p_ins_nl boolean := false,
                          p_comment varchar2 := null, p_silent boolean := false);

    procedure drop_column(p_table varchar2,p_column varchar2,p_cascade boolean,p_silent boolean);
    function has_table(table_name varchar2) return boolean;

    /**
     * Выставляет значение свойства NULLABLE у колонки таблицы.
     * @param p_table  Наименование таблицы
     * @param p_column Колонка таблицы
     * @param p_class  Идентификатор класса
     * @param p_attr   Квалификатор колонки класса
     * @param p_nullable Значение свойства NULLABLE колонки таблицы
     */
    procedure set_column_nullable(p_table varchar2, p_column varchar2, p_class varchar2, p_qual varchar2, p_nullable boolean);

    /**
     * Получение значения свойства NULLABLE у колонки таблицы.
     * @param p_table  Наименование таблицы
     * @param p_column Колонка таблицы
     * @param p_owner  Владелец таблицы
     */
    function get_column_nullable(p_table varchar2, p_column varchar2, p_owner varchar2 default null) return boolean;

    /**
     * Переименование констрейнта
     * @param p_table  Наименование таблицы
     * @param p_constraint_name_old Старое наименование констрейнта
     * @param p_constraint_name_new Новое наименование констрейнта
     */
    procedure rename_constraint(p_table varchar2, p_constraint_name_old varchar2, p_constraint_name_new varchar2);

end;
/
show err

