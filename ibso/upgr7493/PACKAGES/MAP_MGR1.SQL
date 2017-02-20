prompt mapex_mgr
create or replace
package mapex_mgr as
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/MAP_MGR1.SQL $
 *  $Author: Alexey $
 *  $Revision: 15072 $
 *  $Date:: 2012-03-06 13:41:17 #$
 */
    function  map_trigger_name(p_table varchar2) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( map_trigger_name, WNDS, WNPS, RNDS, RNPS );
    -- Есть колонки сдублированные из заданного типа
    function  needs_mapping(class_id_ varchar2) return boolean;
    -- Есть дублированные колонки в заданном типе
    function  needs_map_columns(class_id_ varchar2) return boolean;
    -- Создание триггера дублирования из заданного типа
    procedure create_map_trigger( pclass_id varchar2, p_table varchar2 default null );
    -- Удаление триггера дублирования из заданного типа
    procedure drop_map_trigger( pclass_id varchar2, p_table varchar2 default null );
    -- Создание триггеров дублирования в заданный тип
    procedure create_mapping_triggers( p_class_id varchar2 );
    -- Дублирование колонок
    procedure update_mapping(p_class_id  varchar2,
                             p_verbose   boolean  default false,
                             p_pipe_name varchar2 default 'DEBUG',
                             p_modify    boolean  default true,
                             p_self      boolean  default null);
end;
/
show err

