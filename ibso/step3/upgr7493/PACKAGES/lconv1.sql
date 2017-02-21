prompt long_conv
create or replace package long_conv is
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/lconv1.sql $
 *  $Author: Alexey $
 *  $Revision: 15072 $
 *  $Date:: 2012-03-06 13:41:17 #$
 */
--
mode_readonly  constant pls_integer := dbms_lob.lob_readonly;
mode_readwrite constant pls_integer := dbms_lob.lob_readwrite;
--
NO_PRIVILEGES     exception;
PRAGMA EXCEPTION_INIT( NO_PRIVILEGES   , -1031 ); -- ORA-01031: insufficient privileges
--
procedure init_conversion(p_table varchar2, p_from_column varchar2, p_to_column varchar2, p_owner varchar2 default null);
procedure add_rowid(p_rowid rowid);
procedure convert_rows;
function open_data(p_id varchar2, p_mode pls_integer default mode_readonly, p_table varchar2, p_type varchar2 default 'BLOB') return pls_integer;
function get_data_size(p_handle pls_integer) return pls_integer;
function read_data (p_handle pls_integer, p_data in out nocopy raw, p_size pls_integer default null, p_pos pls_integer default null) return pls_integer;
function read_datac (p_handle pls_integer, p_datac in out nocopy varchar2, p_size pls_integer default null, p_pos pls_integer default null) return pls_integer;
function clear_data(p_handle pls_integer, p_size pls_integer default null) return pls_integer;
function write_data(p_handle pls_integer, p_data raw, p_size pls_integer default null, p_pos pls_integer default null) return pls_integer;
function write_datac(p_handle pls_integer, p_datac varchar2, p_size pls_integer default null, p_pos pls_integer default null) return pls_integer;
function close_data(p_handle pls_integer, p_commit boolean default true) return pls_integer;
--
end long_conv;
/
show err

