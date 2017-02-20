prompt delayed_action_mgr
create or replace package delayed_action_mgr is
  -- Пакет для работы с отложенными действиями

  -- Группы отложенных действий
  GROUP_FILL_SYSTEM_COLUMNS constant varchar2(20) := 'FILL_SYSTEM_COLUMNS'; -- Группа действий по заполнению системных колонок
  GROUP_CREATE_RESTRICTIONS constant varchar2(20) := 'CREATE_RESTRICTIONS'; -- Группа действий по созданию ограничений

  -- Тип отложенного действия
  FILL_COLLECTION constant varchar2(20) := 'FILL_COLLECTION'; -- Заполнение колонки-массива
  FILL_DUPLICATE  constant varchar2(20) := 'FILL_DUPLICATE';  -- Заполнение дублированной колонки
  SET_NOT_NULL    constant varchar2(20) := 'SET_NOT_NULL';    -- Создание констрейнта NOT_NULL
  CREATE_INDEX    constant varchar2(20) := 'CREATE_INDEX';    -- Создание индекса

  -- Результат выполнения отложенного действия
  ADDED   constant number(1) := 0;  -- Добавлено, не было попытки его выполнить
  SUCCESS constant number(1) := 1;  -- Успешное выполнение отложенного действия
  ERROR   constant number(1) := -1; -- Ошибка выполнения отложенного действия

  -- Приоритеты отложенных действий
  PRIOR_SET_NOT_NULL     constant number(2) := 20;
  PRIOR_FILL_DUPLICATE   constant number(2) := 10;
  PRIOR_FILL_COLLECTION  constant number(2) := 10;
  PRIOR_ADD_UNIQUE_INDEX constant number(2) := 20;
  PRIOR_COLLECTION_SET_NOT_NULL constant number(2) := 20;


  -- Версия пакета
  function get_version return varchar2;    
  
  -- Очистка журнала сообщений об отложенных действиях
  procedure clear_delayed_actions_log;

  -- Вывод в монитор коммуникационного канала сообщений о добавлении отложенных действий
  procedure show_delayed_actions_log(
      p_verbose boolean default false,     -- Выводит сообщение в pipe
      p_pipe_name varchar2 default 'DEBUG' -- Имя канала
  );

  -- Обработка записей в журнале отложенных действий
  -- Возвращает true, если все отложенные действия успешно выполнены, false - были ошибки выполнения
  function execute_delayed_actions(
      p_action_groups varchar2,             -- Группа действий
      p_verbose boolean default false,      -- Выводит сообщение в pipe
      p_pipe_name varchar2 default 'DEBUG', -- Имя канала
      p_error_msg out varchar2              -- Текст ошибки выполнения отложенного действия
  ) return boolean;

  -- Удаление записи из журнала отложенных действий
  procedure delete_delayed_action(
      p_action_type  varchar2,      -- Тип действия
      p_class_id     varchar2,      -- Короткое имя ТБП
      p_class_column_qual varchar2, -- Квалификатор колонки ТБП
      p_index_name   varchar2       -- Наименование индекса
  );
  
  -- Добавление записи в журнал отложенных действий
  procedure add_delayed_action(
      p_action_group varchar2,      -- Группа действий
      p_action_type  varchar2,      -- Тип действия
      p_priority     number,        -- Приоритет
      p_class_id     varchar2,      -- Короткое имя ТБП
      p_class_column_qual varchar2, -- Квалификатор колонки ТБП
      p_index_name   varchar2       -- Наименование индекса
  );

  -- Обновление статуса отложенного действия
  procedure update_delayed_action_status(
      p_action_type       varchar2, -- Тип действия
      p_class_id          varchar2, -- Короткое имя ТБП
      p_class_column_qual varchar2, -- Квалификатор колонки ТБП
      p_index_name        varchar2, -- Наименование индекса
      p_execute_success   number,   -- Результат выполнения
      p_execute_errors    varchar2  -- Текст ошибки
  );
  
  -- Возвращает количество отложенных действий, которые не выполнены, либо выполнены с ошибкой
  function get_num_actions_to_perform return number;
  
end delayed_action_mgr;
/
sho err
