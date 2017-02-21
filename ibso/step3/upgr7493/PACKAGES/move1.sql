prompt move_obj
create or replace package move_obj is
/*
 *	$HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/move1.sql $
 *	$Author: Alexey $
 *  $Revision: 15072 $
 *	$Date:: 2012-03-06 13:41:17 #$
 */
--
-- Изменение ID представлений
    procedure rename_criterion(p_method_id varchar2, p_new_id varchar2, p_all boolean default true);
-- Изменение ID операций
    procedure rename_method(p_method_id varchar2, p_new_id varchar2, p_all boolean default true);
-- Изменение ID меню пользователей
    procedure init_favorites;
-- Изменение ID переходов
    procedure init_transitions;
-- Изменение ID групп операций
    procedure init_method_groups;
-- Изменение ID контролов
    procedure init_controls;
-- Изменение ID справочника процедур
    procedure init_procedures;
-- Изменение ID справочника представлений для отчетов
    procedure init_report_views;
-- Изменение ID таблицы LRAW
    procedure init_lraw;
-- Изменение ID всех представлений
    procedure init_criteria;
-- Изменение ID всех операций
    procedure init_methods;
-- Изменение ID прикладных последовательностей
    procedure init_sequences;
-- Изменение ID макросов печати
    procedure init_printer_macroses;
-- Изменение ID экземпляров класса
    procedure move_objects(p_class varchar2);
-- Изменение реквизитов-коллекций экземпляров класса
    procedure move_collections (p_class varchar2);
-- Изменение OLE-реквизитов экземпляров класса
    procedure move_ole (p_class varchar2);
end;
/
sho err

