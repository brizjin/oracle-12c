prompt cache_mgr
CREATE OR REPLACE
package cache_mgr as
    /**
     * <hr/>
     *	$HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/CACHE_MGR1.sql $<br/>
     *	$Author: sasa $<br/>
     *	$Revision: 50609 $<br/>
     *	$Date:: 2014-08-27 16:44:23 #$<br/>
     *
     * <hr/><br/>
     * <h1>Пакет для организации кэширования экземпляров.</h1>
     *
     * <h2>1 Функционал для оповещения чужих сессий об изменении кэшируемых экземпляров. (Служебный интерфейс)</h2>
     * Регистрация событий изменения экземпляров:
     * <ul>
     *   <li><a href="#reg_obj_change(varchar2,varchar2,boolean)">reg_obj_change</a>
     *   <li><a href="#reg_change(varchar2,boolean)">reg_change</a>
     *   <li><a href="#reg_event(pls_integer,varchar2,pls_integer)">reg_event</a>
     * </ul>
     *
     * Управление транзакциями из АРМ Навигатор  и из сгенерированного из PL+ кода:
     * <ul>
     *   <li><a href="#cache_commit">cache_commit</a>
     *   <li><a href="#cache_set_savepoint(varchar2)">cache_set_savepoint</a>
     *   <li><a href="#cache_rollback(varchar2)">cache_rollback</a>
     * </ul>
     *
     * <h2>2 Утилиты (Можно использовать в прикладном коде)</h2>
     *
     * <h3>2.1 Вычисление хэшей для хранения элементов в pl\sql таблице.<A NAME="hashes"></A></h3>
     * <i>Этот функционал нужен только в Oracle 8. В девятке есть возможность индексировать
     * pl\sql таблицу строковым типом. На Oracle 9 устанавливается версия cache_mgr,
     * которая использует эту возможность.</i><br><br>
     * Если есть необходимость сохранять в pl\sql таблице элементы со строковыми
     * или number ключами с возможностью быстрого поиска, можно воспользоваться
     * следующими функциями для вычисления индексов:
     * <ul>
     *   <li><a href="#Hash_Id(number)">Hash_Id</a> для чисел (number),
     *   <li><a href="#Hash_Str(varchar2)">Hash_Str</a> для строк.
     * </ul>
     * Нужно учитывать, что обе эти функции могут возвращать одинаковые значения
     * для разных входных данных. Поэтому нужно хранить в элементе его исходный
     * ключ, перед обращением к элементу сравнивать его ключ с ключом, по которому
     * вычислен хэш, и, как минимум, выдавать ошибку, если ключи разные.
     * Вместо ошибки можно придумать алгоритм перевычисления ключа. Например (простейший
     * вариант), можно к исходному хэш значению добавлять по 1 пока не найдем пустое место
     * для добавления. При поиске тоже добавляем по 1 пока не найдем
     * совпадающий ключ (элемент найден), либо не попадем на пустое место
     * (элемента нет в таблице). Если перед прибавлением 1 хэш имеет максимальное
     * значение, сбрасывает его в 0.
     * <h3>2.2 Вспомогательные функции для отслеживания элемента множества
     * с момента использования, которого прошло наибольшее время.</h3>
     * Исходная задача: нужно организовать кэширование N последних использовавшихся
     * экземпляров ТБП. Сами экземпляры храним в pl\sql таблице в виде записей.
     * Индексы экземпляров в pl\sql таблице вычисляются из id с использованием
     * <a href="#hashes">Hash_Id</a> или <a href="#hashes">Hash_Str</a>.
     * Как только кол-во экземпляров в таблице достигает N, перед добавлением
     * еще одного, нужно определить какой из N экземпляров использовался раньше всех
     * и удалить его, чтобы общее кол-во оставалось N. Реализуется это так:
     * <ul>
     *   <li>Создается переменная типа <a href="#lru_list_t(varchar2(128),varchar2(128),pls_integer_table_t,pls_integer_table_t)">lru_list_t</a>
     *   <li>При добавлении очередного экземпляра или обращении к ранее добавленному
     *       вызывается <a href="#lru_touch(varchar2,lru_list_t)">lru_touch</a> с индексом этого
     *       экземпляра в pl\sql таблице.
     *   <li>Перед добавлением очередного экземпляра проверяем их общее кол-во.
     *       Если оно равно N, то вызываем <a href="#lru_remove(lru_list_t)">lru_remove(lru_list_t)</a>
     *       и удаляем из таблицы экземпляр с возвращенным этой функцией индексом.
     *   <li>Если нужно сбросить кэш или удалить определенный его экземпляр, то нужно позвать
     *       <a href="#lru_clear(lru_list_t)">lru_clear</a> или
     *       <a href="#lru_remove(varchar2,lru_list_t)">lru_remove(varchar2,lru_list_t)</a>
     *       соответственно.
     * <ul>
     * @headcom
     */

    /**
     * Таблица строк. Используется в
     * <a href="#lru_list_t(varchar2(128),varchar2(128),pls_integer_table_t,pls_integer_table_t)">lru_list_t</a>.
     * Название осталось от 8i пакета, где нельзя было использовать varchar2 для индексации.

    type pls_integer_table_t is table
        of varchar2(128) index by varchar2(128);*/
    subtype pls_integer_table_t is constant.refstring_table_s;

    /**
     * Структура данных для алгоритма отслеживания элемента
     * с момента использования, которого прошло наибольшее время.
     */
    type lru_list_t is record (
        first varchar2(128),
        last  varchar2(128),
        prev pls_integer_table_t,
        next pls_integer_table_t
    );

    /**
     * Вычисление хэш для чисел (number).
     * Может возвращать одинаковые значения для разных чисел, более подробно см.
     * <A href="#hashes">Вычисление хэшей для хранения элементов в pl\sql таблице</A>.
     * @param p_num число.
     * @return Хэш переданного числа.
     */
    function Hash_Id (p_num number  ) return pls_integer;

    /**
     * Вычисление хэш для строк.
     * Hash_Str возвращает отрицательные значения (-1..-2147483647)
     * Hash_Id  возвращает неотрицательные значения (0..2147483646)
     * Может возвращать одинаковые значения для разных строк, более подробно см.
     * <A href="#hashes">Вычисление хэшей для хранения элементов в pl\sql таблице</A>.
     * @param p_str строка.
     * @return Хэш переданной строки.
     */
    function Hash_Str(p_str varchar2) return pls_integer;
    function Hash_Id (p_str varchar2) return pls_integer;

    /**
     * Регистрация изменения экземпляра ТБП. Используется при точечных обновлениях.
     * @param class_id Идентификатор ТБП.
     * @param obj_id Идентификатор экземпляра.
     * @param cascade Затрагивает ли изменение поля родительских типов (Для каскадного сброса кэшей родителей).
     */
    procedure reg_obj_change(class_id varchar2, obj_id varchar2, cascade boolean);

    /**
     * Регистрация изменения экземпляров ТБП. Используется при batch обновлениях.
     * @param class_id Идентификатор ТБП.
     * @param cascade Затрагивает ли изменение поля родительских типов (Для каскадного сброса кэшей родителей).
     */
    procedure reg_change(class_id varchar2, cascade boolean);

    /**
     * Планирование/отсылка события.
     * Если настройка CLS_STATIC_EVENT in ('Y', '1'), то во время вызова рассылается событие p_event с кодом 0.
     * В противном случае, запоминаются код и событие, и отсылка происходит в <a href="#cache_commit">cache_commit</a>
     * @param p_code Код события.
     * @param p_event Тело события.
     * @param p_pipe Имя пайпы для адресной рассылки события (пустое значение - адресная рассылка не будет использоваться)
     */
    procedure reg_event (p_code pls_integer, p_event varchar2, p_pipe varchar2 default null);

    /**
     * Очистка списка событий для рассылки при выполнении фиксации транзакции.
     * @param p_code Код события, которое следует очистить (пустое значение означает очистку всех событий.
     */
    procedure reg_clear (p_code pls_integer default null);

    /**
     * Фиксация транзакции. Рассылка остальным сессиям уведомлений об изменениях кэшируемых экземпляров.
     * Рассылка остальным сессиям запланированных событий.
     * Если для одного ТБП модифицировано меньше max_cnt экземпляров,
     * то для каждого экземпляра рассылается уведомление о том, что его нужно сбросить из кэша.
     * Если для одного ТБП модифицировано >= max_cnt экземпляров,
     * то рассылается уведомление о том, что нужно сбросить кэш этого ТБП полностью.
     */
    procedure cache_commit(p_autonom boolean default false);

    /**
     * Установка точки сохранения.
     * @param savepointname Имя точки сохранения.
     */
    procedure cache_set_savepoint(savepointname varchar2);

    /**
     * Откат транзакции (возможно до точки отката).
     * Сброс кэшей измененных типов. Если откатывается вся транзакция, то сброс информации об изменениях.
     * @param savepointname Имя точки сохранения. Если не задано, то откатывается вся транзакция.
     */
    procedure cache_rollback(savepointname varchar2 default null,p_autonom boolean default false);

    /**
     * Не используется (java placeholders).
     */
    procedure write_cache;
    procedure cache_flush(info varchar2 default null);
    procedure cache_clear(info varchar2 default null);
    procedure cache_refresh_class(classId varchar2);
    procedure cache_refresh(id number);
    procedure cache_refresh(id varchar2);

    /**
     * Отметить, что элемент с заданным индексом использовался последним.
     * @param idx Индекс элемента.
     * @param lru_list Список.
     * @return Индекс удаленного элемента.
     */
    procedure lru_touch(idx varchar2, lru_list in out nocopy lru_list_t);
    pragma restrict_references(lru_touch, WNDS, WNPS, RNDS, RNPS);

    /**
     * Удалить из списка информацию об элементе с момента использования,
     * которого прошло наибольшее время, и вернуть его индекс.
     * @param lru_list Список.
     * @return Индекс удаленного элемента.
     */
    function lru_remove(lru_list in out nocopy lru_list_t) return varchar2;
    pragma restrict_references(lru_remove, WNDS, WNPS, RNDS, RNPS);

    /**
     * Удалить из списка информацию об элементе с заданным индексом.
     * @param idx Индекс элемента.
     * @param lru_list Список.
     * @return Индекс удаленного элемента.
     */
    procedure lru_remove(idx varchar2, lru_list in out nocopy lru_list_t);
    pragma restrict_references(lru_remove, WNDS, WNPS, RNDS, RNPS);

    /**
     * Очистить список. Накопление информации начинается сначала.
     * @param lru_list Список.
     */
    procedure lru_clear(lru_list in out nocopy lru_list_t);
    pragma restrict_references(lru_clear, WNDS, WNPS, RNDS, RNPS);

    /**
     * Добавить/удалить свою сессию в список рассылки событий.
     * Используется для подписки/отписки сессий на событие обновления
     * кэша интерфейсных пакетов типов.
     * @param p_pipe Пайпа для хранения списка сессий.
     * @param p_add Признак добавления(true)/удаления(false) сессии.
     */
    procedure reg_pipe_events (p_pipe varchar2, p_add boolean);
    pragma restrict_references(reg_pipe_events, WNDS, WNPS, TRUST);

    /**
     * Разослать событие по заданному списку рассылки.
     * Используется для рассылки события обновления кэша интерфейсных
     * пакетов типов по cache_commit.
     * @param p_pipe Пайпа для хранения списка сессий для рассылки.
     * @param p_code Код события (пустое значение просто нормализует список рассылки).
     * @param p_event Тело события.
     */
    procedure send_pipe_events(p_pipe varchar2, p_code pls_integer, p_event varchar2);

    /**
     * Обновление списков сессий в пайповых кэшах
     * @param p_init_classes
     * - null (по умолчанию)  - обновление пайп для кэшируемых типов
     * - true - обновление и инициализация пайп для кэшируемых типов
     * - false - обновление существующих кэш-пайп
     */
    procedure refresh_cache_pipes(p_init_classes boolean default null);

    /**
     * Установка признака запрета выполнения commit/rollback в операциях
     * @param p_disable
     * - true - установить запрет
     * - null,false - снять запрет
     */
    procedure set_commit_disabled(p_disable boolean);

    /**
     * Получение признака запрета выполнения commit/rollback в операциях
     */
    function  get_commit_disabled return boolean;

    /**
     * Проверка признака запрета выполнения commit/rollback в операциях
     * При наличии запрета выдается ошибка с соответствующим текстом
     * @param p_commit_msg
     * - true (по умолчанию) - сообщение о запрете выполнения commit
     * - null,false - сообщение о запрете выполнения rollback
     */
    procedure check_commit(p_commit_msg boolean default true);
	
    /**
     * Сброс кэша для экземпляра или всего ТБП
     * @param p_class - класс экземпляра
     * @param p_cascade - каскадное обновление кэшей ТБП от p_class до самого верхнего
     * @param p_id - идентификатор экземпляра (если не указан - сброс всего кэша ТБП)
     */
    procedure cache_reset(p_class in varchar2, p_cascade boolean, p_id in varchar2);
end cache_mgr;
/
show err

