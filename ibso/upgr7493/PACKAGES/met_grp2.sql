prompt  package body method_group
create or replace
package body
/*
 *	$HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/met_grp2.sql $
 *  $Author: Alexey $
 *  $Revision: 15072 $
 *	$Date:: 2012-03-06 13:41:17 #$
*/
method_group is
procedure check_access(ausr in varchar2, aisadmin in integer) as
begin
    if  rtl.usr in (Inst_Info.Owner,Inst_Info.GOwner) or (ausr='%SYSTEM%' and nvl(aisadmin,0)<>0) or ausr=rtl.usr then
        null;
    else
        message.error('UADMIN','CANNOT_CHANGE_OTHERS_OPTIONS');
    end if;
end check_access;
--
function add_group(new_name in method_groups.name%type, new_class_id in method_groups.class_id%type,
    new_parent_id in method_groups.parent_id%type default null,
    new_position in method_groups.position%type default null,
    isadmin in integer default null) return method_groups.id%type as
new_id numeric;
usr varchar2(30);
begin
    select seq_id.nextval into new_id from dual;
    if nvl(isadmin,0) = 0 then
        usr := rtl.usr;
    else
        usr := '%SYSTEM%';
    end if;
    insert into method_groups (class_id, id, name, username, parent_id, position)
        values (new_class_id, new_id, new_name, usr, new_parent_id, new_position);
    return new_id;
end add_group;
--
procedure rename_group(grp_id in method_groups.id%type, new_name in method_groups.name%type,
    isadmin in integer default null) as
usr varchar2(30);
begin
    select username into usr from method_groups where id = grp_id;
    check_access(usr,isadmin);
    update method_groups set  name = new_name where id = grp_id;
exception
    when NO_DATA_FOUND then null;
end rename_group;
--
procedure remove_group(grp_id in method_groups.id%type, csd in integer default 1,
    isadmin in integer default null) as
usr varchar2(30);
v_parent_id varchar2(16);
begin
    select username,parent_id into usr,v_parent_id from method_groups where id = grp_id;
    check_access(usr,isadmin);
    if nvl(csd,0) = 0 then
        update method_groups set parent_id = v_parent_id where parent_id = grp_id;
    end if;
    delete from method_groups where id = grp_id;
exception
    when NO_DATA_FOUND then null;
end remove_group;
--
procedure set_parent(grp_id in method_groups.id%type, new_parent_id in method_groups.parent_id%type,
    csd in integer default 1, isadmin in integer default null) as
usr varchar2(30);
v_parent_id varchar2(16);
begin
    select username,parent_id into usr,v_parent_id from method_groups where id = grp_id;
    check_access(usr,isadmin);
    if nvl(csd,0) = 0 then
        update method_groups set parent_id = v_parent_id where parent_id = grp_id;
    end if;
    update method_groups set parent_id = new_parent_id where id = grp_id;
exception
    when NO_DATA_FOUND then null;
end set_parent;
--
procedure set_position(grp_id in method_groups.id%type, new_position in method_groups.position%type,
    isadmin in integer default null) as
usr varchar2(30);
begin
    select username into usr from method_groups where id = grp_id;
    check_access(usr,isadmin);
    update method_groups set position = new_position where id = grp_id;
exception
    when NO_DATA_FOUND then null;
end set_position;
--
procedure add_method(new_meth_id in method_group_members.method_id%type,
    grp_id in method_group_members.group_id%type,
    new_position in method_groups.position%type default null,
    isadmin in integer default null) as
usr varchar2(30);
begin
    select username into usr from method_groups where id = grp_id;
    check_access(usr,isadmin);
    insert into method_group_members (group_id, method_id, position)
    values (grp_id, new_meth_id, new_position);
exception
    when NO_DATA_FOUND then null;
end add_method;
--
procedure remove_method(removed_meth_id in method_group_members.method_id%type,
                        grp_id in method_group_members.group_id%type,
                        isadmin in integer default null) as
usr varchar2(30);
begin
    select username into usr from method_groups where id = grp_id;
    check_access(usr,isadmin);
    delete from method_group_members where method_id = removed_meth_id and group_id = grp_id;
exception
    when NO_DATA_FOUND then null;
end remove_method;
--
procedure set_method_position(meth_id in method_group_members.method_id%type,
    grp_id in method_group_members.group_id%type, new_position in integer,
    isadmin in integer default null) as
usr varchar2(30);
begin
    select username into usr from method_groups where id = grp_id;
    check_access(usr,isadmin);
    update method_group_members set position = new_position where method_id = meth_id and group_id = grp_id;
exception
    when NO_DATA_FOUND then null;
end set_method_position;
--
end method_group;
/
show err package body method_group

