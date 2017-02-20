prompt fvr body
create or replace
package body
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/FVR2.sql $
 *  $Author: Alexey $
 *  $Revision: 15072 $
 *  $Date:: 2012-03-06 13:41:17 #$
 */
fvr is
procedure check_access(ausr in varchar2, aisadmin in integer) as
begin
    if  rtl.usr in (Inst_Info.Owner,Inst_Info.GOwner) or (ausr='%SYSTEM%' and nvl(aisadmin,0)<>0) or ausr=rtl.usr then
        null;
    else
        message.error('UADMIN','CANNOT_CHANGE_OTHERS_OPTIONS');
    end if;
end check_access;
--
function create_item(name in varchar2, classid in varchar2, critid in varchar2 default null,
    collectionid in varchar2 default null, newproperties in varchar2 default null,
    methodid in varchar2 default null, parentid in varchar2 default null,
    pos in integer default null, isadmin in integer default null) return varchar2 as
keyid favorites.id%type;
usr    varchar2(30);
begin
    select seq_id.nextval into keyid from dual;
    if nvl(isadmin,0) = 0 then
        usr := rtl.usr;
    else
        usr := '%SYSTEM%';
    end if;
    insert into favorites (username, id, name, class_id, criterion_id, collection_id, properties, method_id, parent_id, position)
    values (usr, keyid, name, classid, critid, collectionid, newproperties, methodid, parentid, pos);
    return keyid;
end create_item;
--
procedure delete_item(itemid in favorites.id%type, csd in integer default 1,
    isadmin in integer default null) is
usr         varchar2(30);
v_parent_id varchar2(16);
begin
    select parent_id,username into v_parent_id,usr from favorites where id = itemid;
    check_access(usr,isadmin);
    if nvl(csd,0) = 0 then
        update favorites set parent_id = v_parent_id where parent_id = itemid;
    end if;
    delete from favorites where id = itemid;
exception
    when NO_DATA_FOUND then null;
end delete_item;
--
procedure rename_item (itemid in favorites.id%type, newitemname in varchar2,
    newproperties in varchar2 default null, isadmin in integer default null) is
usr    varchar2(30);
begin
    select username into usr from favorites where id = itemid;
    check_access(usr,isadmin);
    update favorites set name = newitemname, properties = newproperties where id = itemid;
exception
    when NO_DATA_FOUND then null;
end rename_item;
--
procedure set_parent(itemid in favorites.id%type, newparentid in varchar2,
    csd in integer default 1, isadmin in integer default null) as
usr varchar2(30);
v_parent_id varchar2(16);
begin
    select username,parent_id into usr,v_parent_id from favorites where id = itemid;
    check_access(usr,isadmin);
    if nvl(csd,0) = 0 then
        update favorites set parent_id = v_parent_id where parent_id = itemid;
    end if;
    update favorites set parent_id = newparentid where id = itemid;
exception
    when NO_DATA_FOUND then null;
end set_parent;
--
procedure set_position(itemid in favorites.id%type, newposition in varchar2,
    isadmin in integer default null) as
usr varchar2(30);
begin
    select username into usr from favorites where id = itemid;
    check_access(usr,isadmin);
    update favorites set position = newposition where id = itemid;
exception
    when NO_DATA_FOUND then null;
end set_position;
---------------------------------------------------------------
-- Возвращает alias колонки представления по ее номеру среди видимых
---------------------------------------------------------------
FUNCTION Get_Alias_By_Visible_Index$(Criteria_Id_ IN Criteria_Prints.Criteria_Id%TYPE,
                                    Visible_Index_ IN pls_integer) RETURN varchar2 IS
    i pls_integer := Visible_Index_;
BEGIN
    for col in (select alias, unvisible from criteria_columns
                  where criteria_id = criteria_id_ and position > 0 order by position) loop
        if nvl(col.unvisible, '0') = 0 then
            i := i - 1;
        end if;
        if i = 0 then
            return col.alias;
            exit;
        end if;
    end loop;
    return null;
END Get_Alias_By_Visible_Index$;
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
    new_alias  in fvr_filters.alias%type default null)
is
    usr varchar2(30);
    new_alias_ fvr_filters.alias%type := new_alias;
    criteria_id_ criteria.id%type;
begin
    select username into usr from favorites where id = itemid;
    check_access(usr,isadmin);
    if new_alias_ is null and newind >= 0 then
        select criterion_id into criteria_id_ from favorites where id = itemid;
        new_alias_ := Get_Alias_By_Visible_Index$(criteria_id_, mod(newind, 1000) + 1);
    end if;
    insert into fvr_filters (fvr_id, ind, value_min, value_max, cond_min, cond_max, syst_name, properties, alias)
    values (itemid, newind, new_value_min, new_value_max, new_cond_min, new_cond_max, new_syst_name, new_properties, new_alias_);
exception
    when NO_DATA_FOUND then null;
end create_filter;
---------------------------------------------------------------------
-- Заполняет поле alias таблицы fvr_filters используя значение поля ind
---------------------------------------------------------------------
procedure translate_fvr_filters_ind is
    new_alias fvr_filters.alias%type;
begin
    for f in (select ff.fvr_id, ff.ind, ff.alias, f.criterion_id
                from fvr_filters ff, favorites f
                where f.id = ff.fvr_id and ff.alias is null and ff.ind >= 0) loop
        new_alias := Get_Alias_By_Visible_Index$(f.criterion_id, mod(f.ind, 1000) + 1);
        if new_alias is not null then
            update fvr_filters set alias = new_alias where fvr_id = f.fvr_id and ind = f.ind;
        end if;
    end loop;
    commit;
end translate_fvr_filters_ind;
---
end fvr;
/
sho err package body fvr

