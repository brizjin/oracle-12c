prompt package vfs_mgr
create or replace package vfs_mgr as
/*
 *	$HeadURL: http://hades.ftc.ru:7382/svn/pltm2/Core/Utils/EXT/vfs_mgr1.sql $
 *	$Author: Alexey $
 *	$Revision: 15082 $
 *	$Date:: 2012-03-06 17:34:34 #$
 */

 --vfs item types
 VFS_FOLDER constant integer := 0;
 VFS_FILE   constant integer := -1;

 --file open modes
 MODE_READ      constant char := 'R';
 MODE_WRITE     constant char := 'W';
 MODE_FULL      constant char := 'F';
 MODE_READWRITE constant char := MODE_FULL;
 MODE_APPEND    constant char := 'A';

 LF constant char := chr(10);
 CR constant char := chr(13);
 EOLN varchar2(2) := CR || LF;

 --error codes
 ERR_SUCCESS                  constant pls_integer :=    0;
 ERR_INVALID_PATH             constant pls_integer :=   -2;
 ERR_INVALID_HANDLE           constant pls_integer :=   -9;
 ERR_NOT_ENOUGH_PRIVILEGE     constant pls_integer :=  -13;
 ERR_LOCKED                   constant pls_integer :=  -16;
 ERR_NAME_EXISTS              constant pls_integer :=  -17;
 ERR_INVALID_MODE             constant pls_integer :=  -22;
 ERR_VFS_BASE                 constant pls_integer := -100;
 ERR_UNKNOWN                  constant pls_integer := ERR_VFS_BASE;
 ERR_NOT_EMPTY                constant pls_integer := ERR_VFS_BASE - 01;
 ERR_INVALID_NAME             constant pls_integer := ERR_VFS_BASE - 02;
 ERR_NO_STATIC_FOLDER_IN_TEMP constant pls_integer := ERR_VFS_BASE - 03;
 ERR_INVALID_PARAMETER        constant pls_integer := ERR_VFS_BASE - 04;
 ERR_NOT_IN_READ_MODE         constant pls_integer := ERR_VFS_BASE - 05;
 ERR_NOT_IN_WRITE_MODE        constant pls_integer := ERR_VFS_BASE - 06;
 ERR_NOT_IN_READWRITE_MODE    constant pls_integer := ERR_VFS_BASE - 07;
 ERR_BUSY                     constant pls_integer := ERR_VFS_BASE - 08;
 ERR_INVALID_CHARSET          constant pls_integer := ERR_VFS_BASE - 09;
 ERR_NO_DATA                  constant pls_integer := ERR_VFS_BASE - 10;
 ERR_DROP_DEFAULT_STORAGE     constant pls_integer := ERR_VFS_BASE - 11;
 ERR_NOT_SUPPORTED            constant pls_integer := ERR_VFS_BASE - 13;

 --exceptions
 E_INVALID_PATH             exception;
 E_INVALID_HANDLE           exception;
 E_NOT_ENOUGH_PRIVILEGE     exception;
 E_LOCKED                   exception;
 E_NAME_EXISTS              exception;
 E_INVALID_MODE             exception;
 E_UNKNOWN                  exception;
 E_NOT_EMPTY                exception;
 E_INVALID_NAME             exception;
 E_NO_STATIC_FOLDER_IN_TEMP exception;
 E_INVALID_PARAMETER        exception;
 E_NOT_IN_READ_MODE         exception;
 E_NOT_IN_WRITE_MODE        exception;
 E_NOT_IN_READWRITE_MODE    exception;
 E_BUSY                     exception;
 E_INVALID_CHARSET          exception;
 E_NO_DATA                  exception;
 E_DROP_DEFAULT_STORAGE     exception;
 E_NOT_SUPPORTED            exception;

 ORA_RESOURCE_BUSY         constant pls_integer := -00054;--ORA-00054 - resource busy and acquire with NOWAIT specified
 ORA_FETCH_OUT_OF_SEQUENCE constant pls_integer := -01002;--ORA-01002 - fetch out of sequence
 ORA_FETCH_MANY_ROWS       constant pls_integer := -01422;--ORA-01422: exact fetch returns more than requested number of rows
 ORA_CHILD_RECORD          constant pls_integer := -02292;--ORA-02292 - child record found
 ORA_ARGUMENT_INVALID      constant pls_integer := -21560;--ORA-21560 - argument string is null, invalid, or out of range
 ORA_INVALID_LOCATOR       constant pls_integer := -22275;--ORA-22275 - invalid LOB locator specified

 E_ORA_RESOURCE_BUSY         exception;
 E_ORA_FETCH_OUT_OF_SEQUENCE exception;
 E_ORA_FETCH_MANY_ROWS       exception;
 E_ORA_CHILD_RECORD          exception;
 E_ORA_ARGUMENT_INVALID      exception;
 E_ORA_INVALID_LOCATOR       exception;
 pragma exception_init(E_ORA_RESOURCE_BUSY,          -00054);
 pragma exception_init(E_ORA_FETCH_OUT_OF_SEQUENCE,  -01002);
 pragma exception_init(E_ORA_FETCH_MANY_ROWS,        -01422);
 pragma exception_init(E_ORA_CHILD_RECORD,           -02292);
 pragma exception_init(E_ORA_ARGUMENT_INVALID,       -21560);
 pragma exception_init(E_ORA_INVALID_LOCATOR,        -22275);

 --most used charsets
 CS_DOS  constant varchar2(20) := 'RU8PC866';
 CS_UNIX constant varchar2(20) := 'CL8ISO8859P5';
 CS_WIN  constant varchar2(20) := 'CL8MSWIN1251';
 CS_KOI  constant varchar2(20) := 'CL8KOI8R';

 --dir_flag bit values (см. get_file_list)
 DF_NONE       constant pls_integer := 0;
 DF_FILE       constant pls_integer := 1;
 DF_FOLDER     constant pls_integer := 2;
 DF_ACCESSIBLE constant pls_integer := 4;

 --seek base
 SB_BEGIN   constant pls_integer := 0;--from beginning of file
 SB_CURRENT constant pls_integer := 1;--from current position
 SB_END     constant pls_integer := 2;--from end of file

 subtype HFILE is binary_integer;
 subtype HFOLDER is binary_integer;

 PATH_SEPARATOR char;
 CASE_SENSITIVE boolean;
 CURRENT_CHARSET varchar2(30);
 SILENT_OVERWRITE boolean;

 ----------------------------------------------------------
 function current_user return varchar2;
 ----------------------------------------------------------
 function can_make_dir(asubject_id in varchar2 default current_user) return boolean;
 ----------------------------------------------------------
 function root_dir return varchar2;
 ----------------------------------------------------------
 function home_dir return varchar2;
 ----------------------------------------------------------
 function replace_dir return varchar2;
 ----------------------------------------------------------
 function base_dir return varchar2;
 ----------------------------------------------------------

 ----------------------------------------------------------
 function get_profile(p_user varchar2 default current_user) return varchar2;
 ----------------------------------------------------------
 function get_resource(p_profile varchar2, p_name varchar2) return varchar2;
 ----------------------------------------------------------

 ----------------------------------------------------------
 function user_lock(aid in integer) return pls_integer;
 ----------------------------------------------------------
 function user_unlock(aid in integer) return pls_integer;
 ----------------------------------------------------------
 procedure clear_dead_locks;
 ----------------------------------------------------------

 ----------------------------------------------------------
 function create_folder$(aname in varchar2,
  aparent_id in integer default null, astorage_id in integer default null,
  aothers_access_mask in pls_integer default vfs_admin.ACCESS_PARENT,
  alifetime in number default null,
  acharset in varchar2 default null,
  adescription in varchar2 default null,
  aautonomous in boolean default true) return integer;
 ----------------------------------------------------------
 function create_file$(aname in varchar2,
  aparent_id in integer default null, astorage_id in integer default null,
  aothers_access_mask in integer default vfs_admin.ACCESS_PARENT,
  acharset in varchar2 default null,
  adescription in varchar2 default null,
  aautonomous in boolean default true) return integer;
 ----------------------------------------------------------
 function remove$(aid in integer, acascade in boolean default false, aautonomous in boolean default true) return pls_integer;
 ----------------------------------------------------------
 function move$(aid in integer, anew_parent_id in integer, anew_name in varchar2 default null,
  aautonomous in boolean default true) return pls_integer;
 ----------------------------------------------------------
 function store$(aid in integer, anew_storage_id in integer, acascade in boolean default false,
  aautonomous in boolean default true) return pls_integer;
 ----------------------------------------------------------
 function rename$(aid in integer, anew_name in varchar2, aautonomous in boolean default true) return pls_integer;
 ----------------------------------------------------------
 function copy$(aid in integer, aparent_id in integer, aname in varchar2 default null,
  aautonomous in boolean default true) return integer;
 ----------------------------------------------------------
 function set_description$(aid in integer, adescription in varchar2, aautonomous in boolean default true) return pls_integer;
 ----------------------------------------------------------
 function remove_temporary$(aautonomous in boolean default true) return pls_integer;
 ----------------------------------------------------------

 ----------------------------------------------------------
 function is_folder$(aid in integer) return boolean;
 ----------------------------------------------------------
 function get_id_by_name$(apath in varchar2, apath_separator in char default PATH_SEPARATOR) return integer;
 ----------------------------------------------------------
 function get_name_by_id$(aid in integer, apath_separator in char default PATH_SEPARATOR) return varchar2;
 ----------------------------------------------------------
 function get_parent$(aid in integer) return integer;
 ----------------------------------------------------------
 function info$(aid in integer,
  aname out varchar2,
  atype out number,
  aowner out varchar2,
  asize out number,
  aothers_access_mask out pls_integer,
  asubject_access_mask out pls_integer,
  acreate_date out date,
  amodify_date out date,
  acharset out varchar2,
  aparent_id out integer,
  astorage_id out integer,
  adescription out varchar2) return pls_integer;
 ----------------------------------------------------------

 ----------------------------------------------------------
 function is_open$(afile in HFILE) return boolean;
 ----------------------------------------------------------
 function size$(afile in HFILE) return integer;
 ----------------------------------------------------------
 function eof$(afile in integer) return boolean;
 ----------------------------------------------------------
 function open$(aid in integer, amode in char default MODE_READ,
  aexclusive in boolean default false,
  aautonomous in boolean default true) return HFILE;
 ----------------------------------------------------------
 function close$(afile in HFILE) return pls_integer;
 ----------------------------------------------------------
 procedure close_all$;
 ----------------------------------------------------------
 function seek$(afile in HFILE, aoffset in integer, aorigin in integer default SB_BEGIN) return pls_integer;
 ----------------------------------------------------------
 function read$(afile in HFILE, abuffer out raw, acount in integer default null) return pls_integer;
 ----------------------------------------------------------
 function write$(afile in HFILE, abuffer in raw, acount in integer default null) return pls_integer;
 ----------------------------------------------------------
 function get_file_name$(afile in HFILE) return varchar2;
 ----------------------------------------------------------
 function get_file_id$(afile in HFILE) return integer;
 ----------------------------------------------------------

 ----------------------------------------------------------
 function cread$(afile in HFILE, abuffer out varchar2, acount in integer default null) return pls_integer;
 ----------------------------------------------------------
 function cwrite$(afile in HFILE, abuffer in varchar2, acount in integer default null) return pls_integer;
 ----------------------------------------------------------
 function cread_str$(afile in HFILE, abuffer out varchar2, aeoln in varchar2 default EOLN) return pls_integer;
 ----------------------------------------------------------
 function cwrite_str$(afile in HFILE, abuffer in varchar2, aeoln in varchar2 default EOLN) return pls_integer;
 ----------------------------------------------------------

 ----------------------------------------------------------
 function get_file_list(aid in integer, amask in varchar2 default null,
  adir_flag in pls_integer default 0, asort in boolean default null) return varchar2;
 ----------------------------------------------------------
 function get_file_list(alist out varchar2, aid in integer, amask in varchar2 default null,
  adir_flag in pls_integer default 0, asort in boolean default null) return pls_integer;
 ----------------------------------------------------------
 function out_file_list(aid in integer, amask in varchar2 default null,
  adir_flag in pls_integer default 0, asort in boolean default null) return pls_integer;
 ----------------------------------------------------------
 function open_folder(aid in integer, amask in varchar2 default null,
  adir_flag in pls_integer default 0, asort in boolean default null) return HFOLDER;
 ----------------------------------------------------------
 function get_folder_name(afolder in HFOLDER) return varchar2;
 ----------------------------------------------------------
 function read_folder(afolder in HFOLDER,
  aid out integer,
  aname out varchar2,
  atype out number,
  aowner out varchar2,
  asize out number,
  aothers_access_mask out pls_integer,
  asubject_access_mask out pls_integer,
  acreate_date out date,
  amodify_date out date,
  acharset out varchar2,
  aparent_id out integer,
  astorage_id out integer,
  adescription out varchar2) return pls_integer;
 ----------------------------------------------------------
 function read_folder(afolder in HFOLDER,
  aid out integer,
  aname out varchar2) return pls_integer;
 ----------------------------------------------------------
 function reset_folder(afolder in HFOLDER) return pls_integer;
 ----------------------------------------------------------
 function close_folder(afolder in HFOLDER) return pls_integer;
 ----------------------------------------------------------
 procedure close_all_folders;
 ----------------------------------------------------------

 ----------------------------------------------------------
 function find_env(aname in varchar2) return pls_integer;
 ----------------------------------------------------------
 function get_env(aname in varchar2) return varchar2;
 ----------------------------------------------------------
 function put_env(aname in varchar2, avalue in varchar2) return number;
 ----------------------------------------------------------
 procedure clear_env;
 ----------------------------------------------------------

 ----------------------------------------------------------
 procedure vfs_open;
 ----------------------------------------------------------
 procedure vfs_close;
 ----------------------------------------------------------
 procedure check_open;
 ----------------------------------------------------------

 ----------------------------------------------------------
 function error_message(acode in pls_integer) return varchar2;
 ----------------------------------------------------------
 function process_error(acode in pls_integer, araising in boolean default false) return pls_integer;
 ----------------------------------------------------------

end;
/
sho err
