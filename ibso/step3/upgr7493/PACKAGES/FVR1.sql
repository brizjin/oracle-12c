prompt fvr package
create or replace
package fvr is
/*
 *	$HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/FVR1.sql $
 *  $Author: Alexey $
 *  $Revision: 15072 $
 *	$Date:: 2012-03-06 13:41:17 #$
*/
---------------------------------------------------------------------
-- FVR - Работа с Favorites
--       Copyright (c), 1997-1999, FTC
---------------------------------------------------------------------
---------------------------------------------------------------------
-- Создание ярлыка
---------------------------------------------------------------------
function create_item(name in varchar2, classid in varchar2, critid in varchar2 default null,
    collectionid in varchar2 default null, newproperties in varchar2 default null,
    methodid in varchar2 default null, parentid in varchar2 default null,
    pos in integer default null, isadmin in integer default null) return varchar2;
---------------------------------------------------------------------
-- Удаление ярлыка
---------------------------------------------------------------------
procedure delete_item(itemid in favorites.id%type, csd in integer default 1,
    isadmin in integer default null);
---------------------------------------------------------------------
-- Переименование ярлыка
---------------------------------------------------------------------
procedure rename_item(itemid in favorites.id%type, newitemname in varchar2,
    newproperties in varchar2 default null, isadmin in integer default null);
--
procedure set_parent(itemid in favorites.id%type, newparentid in varchar2,
    csd in integer default 1, isadmin in integer default null);
--
procedure set_position(itemid in favorites.id%type, newposition in varchar2, isadmin in integer default null);
--
---------------------------------------------------------------------
-- Добавление элементов фильтра
---------------------------------------------------------------------
procedure create_filter(itemid in favorites.id%type,
    newind          in fvr_filters.ind%type,
    new_value_min   in fvr_filters.value_min%type default null,
    new_value_max   in fvr_filters.value_max%type default null,
    new_cond_min    in fvr_filters.cond_min%type default null,
    new_cond_max    in fvr_filters.cond_max%type default null,
    new_syst_name   in fvr_filters.syst_name%type default null,
    new_properties  in fvr_filters.properties%type default null,
    isadmin in integer default null,
    new_alias  in fvr_filters.alias%type default null);
---------------------------------------------------------------------
-- Заполняет поле alias таблицы fvr_filters используя значение поля ind
---------------------------------------------------------------------
procedure translate_fvr_filters_ind;
---
end fvr;
--
/
show err

