prompt method_mgr
CREATE OR REPLACE package method_mgr is
/*
 *	$HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/met_mgr1.sql $
 *  $Author: vasiltsov $
 *  $Revision: 114298 $
 *	$Date:: 2016-07-12 13:38:09 #$
 */
    --
    function  build_interface(method_id_ varchar2) return varchar2;
    procedure rebuild_method_interfaces(p_pipe varchar2 default null,
                                        p_list varchar2 default null);
	procedure recreate_deleted_interfaces(p_pipe varchar2 default null);
    function is_interface_deleted(method_id_ varchar2) return boolean;
    --
    function  create_method(p_class_id varchar2, p_method_type varchar2, p_meth_sn varchar2, p_meth_nm varchar2, use_new varchar2 := null, use_new_meth_sn varchar2 := null) return varchar2;
	procedure create_default_methods(p_class_id varchar2);
	procedure overlap_method(p_class_id varchar2, p_short_name varchar2);
	procedure copy_method(p_method_id varchar2,
						  p_class_id varchar2,
						  p_short_name varchar2,
						  p_name varchar2,
						  p_new_id out varchar2,
						  p_compile varchar2 default '0',
						  p_copy_form varchar2 default '1',
						  p_copy_bindings varchar2 default '1',
                          p_id  varchar2 default null);
    function  copy_method(p_method_id varchar2,
						  p_class_id varchar2,
						  p_short_name varchar2,
						  p_name varchar2,
						  p_compile varchar2 default '0',
						  p_copy_form varchar2 default '1',
                          p_copy_bindings varchar2 default '1',
                          p_id  varchar2 default null) return varchar2;
    procedure copy_form(src_method_id varchar2, dst_method_id varchar2);
    function  set_extension(p_method_id  varchar2,
    	                    p_ext_short_name varchar2,
    	                    p_ext_name   varchar2,
                            p_ext_id     varchar2 default null,
                            p_standalone varchar2 default null ) return varchar2;
	-- —оздает интерфейсный пакет дл€ вызова операции с клиента
    procedure create_method_interface(method_id_ varchar2, p_error boolean := false, p_refcing boolean := true);
    function  check_method_interface(method_id_ varchar2) return varchar2;
    --
	procedure drop_method_interface_quietly(method_id_ varchar2);
    function  interface_package_name(method_id_ varchar2) return varchar2 deterministic;
    function  par2var(method_id_ varchar2, position_ integer) return varchar2 deterministic;
    function  var2var(method_id_ varchar2, position_ integer) return varchar2 deterministic;
    function  validate_name (method_id_ varchar2, p_pack boolean default false) return varchar2 deterministic;
    function  execute_name  (method_id_ varchar2, p_pack boolean default false) return varchar2 deterministic;
    function  process_name  (method_id_ varchar2, p_pack boolean default false) return varchar2 deterministic;
    function  result_name   (method_id_ varchar2, p_pack boolean default false) return varchar2 deterministic;
    function  zap_param_name(method_id_ varchar2, p_pack boolean default false) return varchar2 deterministic;
    function  log_param_name(method_id_ varchar2, p_pack boolean default false) return varchar2 deterministic;
    function  set_param_name(method_id_ varchar2, p_pack boolean default false) return varchar2 deterministic;
    function  get_param_name(method_id_ varchar2, p_pack boolean default false) return varchar2 deterministic;
    function  get_param_qual(method_id_ varchar2, p_pack boolean default false) return varchar2 deterministic;
    function  chk_controls_name(method_id_ varchar2, p_pack boolean default false) return varchar2 deterministic;
    function  get_controls_name(method_id_ varchar2, p_pack boolean default false) return varchar2 deterministic;
    function  var_obj_name  (method_id_ varchar2 default null) return varchar2 deterministic;
    function  var_cls_name  (method_id_ varchar2 default null) return varchar2 deterministic;
    function  var_msg_name  (method_id_ varchar2 default null) return varchar2 deterministic;
    function  var_inf_name  (method_id_ varchar2 default null) return varchar2 deterministic;
    function  var_dbg_name  (method_id_ varchar2 default null) return varchar2 deterministic;
    function  var_lck_name  (method_id_ varchar2 default null) return varchar2 deterministic;
    function  class2type(class_ varchar2, flag_ varchar2, package_ varchar2) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( interface_package_name, WNDS, WNPS );
    pragma RESTRICT_REFERENCES ( par2var, WNDS, WNPS );
    pragma RESTRICT_REFERENCES ( var2var, WNDS, WNPS );
    pragma RESTRICT_REFERENCES ( validate_name, WNDS, WNPS );
    pragma RESTRICT_REFERENCES ( execute_name,  WNDS, WNPS );
    pragma RESTRICT_REFERENCES ( process_name,  WNDS, WNPS );
    pragma RESTRICT_REFERENCES ( result_name,   WNDS, WNPS );
    pragma RESTRICT_REFERENCES ( zap_param_name,WNDS, WNPS );
    pragma RESTRICT_REFERENCES ( get_param_name,WNDS, WNPS );
    pragma RESTRICT_REFERENCES ( set_param_name,WNDS, WNPS );
    pragma RESTRICT_REFERENCES ( var_obj_name,  WNDS, WNPS );
    pragma RESTRICT_REFERENCES ( var_cls_name,  WNDS, WNPS );
    pragma RESTRICT_REFERENCES ( var_msg_name,  WNDS, WNPS );
    pragma RESTRICT_REFERENCES ( var_inf_name,  WNDS, WNPS );
    pragma RESTRICT_REFERENCES ( var_dbg_name,  WNDS, WNPS );
    pragma RESTRICT_REFERENCES ( var_lck_name,  WNDS, WNPS );
    function  check_log(method_id_ varchar2) return boolean;
    --
    procedure get_def_attr(p_class varchar2, p_qual out nocopy varchar2,
                           p_self  out nocopy varchar2, p_base out nocopy varchar2);
    pragma RESTRICT_REFERENCES ( get_def_attr,  WNDS, WNPS );
    procedure get_def_qual(p_class varchar2, p_qual out nocopy varchar2,
                           p_self  out nocopy varchar2, p_base out nocopy varchar2,
                           p_targ  out nocopy varchar2, p_kern out nocopy varchar2,
                           p_owner in out nocopy varchar2);
    pragma RESTRICT_REFERENCES ( get_def_qual,  WNDS, WNPS );
    --
    procedure delete_object_collections(obj_id_ varchar2);
    procedure delete_object_collection (obj_id_ varchar2,qual_ varchar2);
    procedure delete_collection (collection_id_ number, class_id_ varchar2 );
    procedure delete_collections(obj_id_ varchar2,
                                 qual_   varchar2 default null,
                                 class_  varchar2 default null,
                                 value_  number   default null);
    --
    procedure clear_object_refcing(obj_id_        varchar2
                                  ,p_class        varchar2 default null
                                  ,p_new_id       varchar2 default null
                                  /* ѕараметр означает, что реквизиты, у которых в јдминистраторе выставлен
                                  признак "Ќе создавать ограничени€", не будут обновлены значением p_new_id
                                  '1' - не обновл€ть значени€ реквизита с выставленным признаком
                                  '0' - обновл€ть значени€ всех реквизиты (стара€ логика)*/
                                  ,p_consider_constr varchar2 default '0');

    function  move_object(p_obj_id varchar2, p_class varchar2 default null,
                          p_new_id varchar2 default null, p_clear boolean default true
                         ) return varchar2;
    --
	function get_version return varchar2;
	--
end;
/
sho err

