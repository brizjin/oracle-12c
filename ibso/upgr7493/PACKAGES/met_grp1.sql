prompt  package method_group
create or replace
package method_group is
/*
 *	$HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/met_grp1.sql $
 *  $Author: Alexey $
 *  $Revision: 15072 $
 *	$Date:: 2012-03-06 13:41:17 #$
*/
function add_group(new_name in method_groups.name%type, new_class_id in method_groups.class_id%type,
    new_parent_id in method_groups.parent_id%type default null,
    new_position in method_groups.position%type default null,
    isadmin in integer default null) return method_groups.id%type;
--
procedure rename_group(grp_id in method_groups.id%type, new_name in method_groups.name%type,
    isadmin in integer default null);
--
procedure remove_group(grp_id in method_groups.id%type, csd in integer default 1,
    isadmin in integer default null);
--
procedure set_parent(grp_id in method_groups.id%type, new_parent_id in method_groups.parent_id%type,
    csd in integer default 1, isadmin in integer default null);
--
procedure set_position(grp_id in method_groups.id%type, new_position in method_groups.position%type,
    isadmin in integer default null);
--
procedure add_method(new_meth_id in method_group_members.method_id%type,
    grp_id in method_group_members.group_id%type,
    new_position in method_groups.position%type default null,
    isadmin in integer default null);
--
procedure remove_method(removed_meth_id in method_group_members.method_id%type,
                        grp_id in method_group_members.group_id%type,
                        isadmin in integer default null);
--
procedure set_method_position(meth_id in method_group_members.method_id%type,
    grp_id in method_group_members.group_id%type, new_position in integer,
    isadmin in integer default null);
--
end method_group;
/
show err

