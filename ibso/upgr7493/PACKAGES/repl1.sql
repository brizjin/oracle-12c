prompt repl_mgr
create or replace package repl_mgr as
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/repl1.sql $
 *  $Author: Alexey $
 *  $Revision: 15072 $
 *  $Date:: 2012-03-06 13:41:17 #$
 */
--
    -- Создание триггеров журналирования изменений и "запретительных" триггеров
    procedure create_triggers(p_pipe varchar2 default null, p_class  varchar2 default null,
                              p_kernel boolean default false, p_bulk_repl boolean default false);
    -- Удаление триггеров
    procedure drop_triggers(p_pipe varchar2 default null, p_class  varchar2 default null, p_kernel boolean default true, p_only_adding boolean default false);
    -- Включение режима "только чтение" (запрет изменений в прикладных таблицах)
    procedure read_only_mode(p_pipe varchar2 default null);
    -- Остановка режима репликации
    procedure stop_repl_mode(p_pipe varchar2 default null);
--
end;
/
show err

