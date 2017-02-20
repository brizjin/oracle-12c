prompt attr_mgr
create or replace package attr_mgr is
/*
 *	$HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/ATR_MGR1.SQL $
 *  $Author: petrushov $
 *  $Revision: 93492 $
 *	$Date:: 2016-02-10 10:29:48 #$
 */
--
-- Возвращает признак, что реквизит содержит хотя бы один идентификатор коллекции
    function attr_has_colls(p_class_id varchar2, p_attr_id varchar2) return boolean;
--
    procedure set_class_attr(
    				p_class_id varchar2,
    				p_attr_id   varchar2,
    				p_attr_name varchar2,
    				p_self_class_id varchar2,
    				p_position  integer  default null,
    				p_required  varchar2 default '0',
    				p_sequenced varchar2 default null,
    				p_compile   boolean  default null,
    				p_chk_name  boolean  default true,
				    p_chk_only  boolean  default false
    			);

	procedure del_class_attr( p_class_id     varchar2,
                              p_attr_id      varchar2,
                              wclear         boolean default true,
                              p_compile      boolean default null,
                              p_crt_sys_view boolean default true
              );

	procedure set_attr_group(
							p_class_id varchar2,
							p_attr_id varchar2,
							p_group_id varchar2
							);
	procedure change_attr_id(
							p_class_id varchar2,
							p_attr_id  varchar2,
                            p_new_id   varchar2,
                            p_update_src boolean default null,
							p_compile    boolean default null
							);
    procedure move_class_attr(
                             p_attr_id varchar2,
                             p_source  varchar2,
                             p_target  varchar2,
                             p_pipe    varchar2,
                             p_compile boolean default null
                             );

end;
/
show err

