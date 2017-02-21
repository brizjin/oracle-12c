prompt package vfs_admin
create or replace package vfs_admin as
/*
 *	$HeadURL: http://hades.ftc.ru:7382/svn/pltm2/Core/Utils/EXT/vfs_adm1.sql $
 *	$Author: Alexey $
 *	$Revision: 15082 $
 *	$Date:: 2012-03-06 17:34:34 #$
 */

 ACCESS_PARENT    constant pls_integer := -1;
 ACCESS_NONE      constant pls_integer :=  0;
 ACCESS_READ      constant pls_integer :=  1;
 ACCESS_WRITE     constant pls_integer :=  2;
 ACCESS_EXCLUSIVE constant pls_integer :=  4;
 ACCESS_R         constant pls_integer :=  ACCESS_READ;
 ACCESS_W         constant pls_integer :=  ACCESS_WRITE;
 ACCESS_X         constant pls_integer :=  ACCESS_EXCLUSIVE;
 ACCESS_RW        constant pls_integer :=  ACCESS_R + ACCESS_W;
 ACCESS_RX        constant pls_integer :=  ACCESS_R + ACCESS_X;
 ACCESS_WX        constant pls_integer :=  ACCESS_W + ACCESS_X;
 ACCESS_RWX       constant pls_integer :=  ACCESS_R + ACCESS_W + ACCESS_X;
 ACCESS_FULL      constant pls_integer :=  ACCESS_RWX;

 ----------------------------------------------------------
 function current_user return varchar2;
 ----------------------------------------------------------

 ----------------------------------------------------------
 function is_admin(asubject_id in varchar2 default current_user) return boolean;
 ----------------------------------------------------------
 function is_owner(aid in integer, asubject_id in varchar2 default current_user) return boolean;
 ----------------------------------------------------------

 ----------------------------------------------------------
 function get_storage_access(asubject_id in varchar2 default current_user) return pls_integer;
 ----------------------------------------------------------
 function check_storage_access(asubject_id in varchar2 default current_user) return pls_integer;
 ----------------------------------------------------------
 function set_storage_access(asubject_id in varchar2, aaccess_mask in pls_integer default ACCESS_FULL) return pls_integer;
 ----------------------------------------------------------

 ----------------------------------------------------------
 function get_others_access(aid in integer) return pls_integer;
 ----------------------------------------------------------
 function get_subject_access(aid in integer, asubject_id in varchar2 default current_user) return pls_integer;
 ----------------------------------------------------------
 function check_access(aid in integer, aaccess_request in pls_integer, asubject_id in varchar2 default current_user) return pls_integer;
 ----------------------------------------------------------
 function is_accessible(aid in integer, asubject_id in varchar2 default current_user) return boolean;
 ----------------------------------------------------------
 function set_others_access(aid in integer, aaccess_mask in pls_integer default ACCESS_PARENT) return pls_integer;
 ----------------------------------------------------------
 function set_subject_access(aid in integer, asubject_id in varchar2,
  aaccess_mask in pls_integer default ACCESS_PARENT, ainclude_subfolders in integer default 0) return pls_integer;
 ----------------------------------------------------------
 function set_owner(aid in integer, anew_owner_id in varchar2) return pls_integer;
 ----------------------------------------------------------

 ----------------------------------------------------------
 function can_make_dir(asubject_id in varchar2 default current_user) return boolean;
 ----------------------------------------------------------

end;
/
sho err
