prompt conv
create or replace package conv is
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/AUD/conv1.sql $
 *  $Author: Alexey $
 *  $Revision: 15071 $
 *  $Date:: 2012-03-06 13:38:04 #$
 */

procedure convert_table(owner varchar2, tab_type pls_integer,
                        start_date date, end_date date,
                        table_name in out varchar2, table_created out boolean,
                        old_fields varchar2 default null);

procedure object_state_history(owner varchar2, old_version varchar2, del_data varchar2, keeptime date, start_date date, end_date date, restore_idxs boolean);
procedure values_history(owner varchar2, old_version varchar2, del_data varchar2, keeptime date, start_date date, end_date date, restore_idxs boolean);
procedure diary_param(owner varchar2, old_version varchar2, del_data varchar2, keeptime date, start_date date, end_date date, restore_idxs boolean, drp in out boolean);
procedure diary_debug_exec(owner varchar2, old_version varchar2, del_data varchar2, keeptime date, start_date date, end_date date, restore_idxs boolean, drp in out boolean);
procedure diary_errors(owner varchar2, old_version varchar2, del_data varchar2, keeptime date, start_date date, end_date date, restore_idxs boolean, drp in out boolean);
procedure diary_uadmin(owner varchar2, old_version varchar2, del_data varchar2, keeptime date, start_date date, end_date date, restore_idxs boolean, drp in out boolean);
procedure diary_sessions(owner varchar2, old_version varchar2, del_data varchar2, keeptime date, start_date date, end_date date, restore_idxs boolean, drp in out boolean);
procedure diary_methods(owner varchar2, old_version varchar2, del_data varchar2, keeptime date, start_date date, end_date date, restore_idxs boolean, drp in out boolean);
procedure diary_storage(owner varchar2, old_version varchar2, del_data varchar2, keeptime date, start_date date, end_date date, restore_idxs boolean, drp in out boolean);
procedure diary_attrs(owner varchar2, old_version varchar2, del_data varchar2, keeptime date, start_date date, end_date date, restore_idxs boolean, drp in out boolean);
procedure diary_UNKNOWN(owner varchar2, old_version varchar2, del_data varchar2, keeptime date, start_date date, end_date date, restore_idxs boolean);
procedure diary_info(owner varchar2, old_version varchar2, del_data varchar2, keeptime date, start_date date, end_date date, restore_idxs boolean, drp in out boolean);
procedure diary_others(owner varchar2, old_version varchar2, del_data varchar2, keeptime date, start_date date, end_date date, restore_idxs boolean, drp in out boolean);
procedure object_collection_history(owner varchar2, old_version varchar2, del_data varchar2, keeptime date, start_date date, end_date date, restore_idxs boolean);
procedure system_events(owner varchar2, old_version varchar2, del_data varchar2, keeptime date, start_date date, end_date date, restore_idxs boolean);
procedure edoc_history(owner varchar2, old_version varchar2, del_data varchar2, keeptime date, start_date date, end_date date, restore_idxs boolean);

end;
/
show err

