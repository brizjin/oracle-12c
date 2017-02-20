prompt dbf header
create or replace package dbf is
/**
 * <hr/>
 * $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/dbf1.sql $<br/>
 * $Author: Alexey $<br/>
 * $Revision: 15072 $<br/>
 * $Date:: 2012-03-06 13:41:17 +#$<br/>
 * <hr/><br/>
 * DBF - ������ � ������ DBF ������.<br/>
 * ���� ����� �������� ������ �� �����-���� ������ � �����:<br/>
 * <ol>
 *   <li>���������� go, gonext ���� skip, ����� ������������� �� ������ ������
 *       � ��������� �� � ����� ��������������.
 *   <li>� ������� fg, fgp, buffer_get, deleted ������� ������ ������.
 * </ol>
 * ���� ����� �������� ������ �����-���� ������ � �����:<br/>
 * <ol>
 *   <li>���������� go, gonext ���� skip, ����� ������������� �� ������ ������
 *     � ��������� �� � ����� ��������������.
 *   <li>� ������� fp, fpp, buffer_put, delete_record ��������� ������ ������.
 *   <li>� ������� put_record � ���������� n = null (��-���������) �����������
 *     ��������� � ����.
 * </ol>
 * ���� ����� �������� ������ � ����:
 * <ul>
 * <li>������� 1 (��������):
 *   <ol>
 *     <li>� ������� fp, fpp, buffer_put ���������� ������ ������.
 *     <li>�����:
 *       <ul>
 *         <li>� ������� append_record ���������� �������������� ������ � ����� �����,
 *         <li>���� � ������� go, gonext ���� skip ������������� � ������ �������,
 *           � � ������� add_record ���������� ����� ������ � ��� �������.
 *       </ul>
 *   </ol>
 * <li>������� 2 (��� �������������):
 *   <ol>
 *     <li>���������� append, � ���������� ���������:<br/>
 *       <ul>
 *         <li>������ ����� ��������������<br/>
 *         <li>recno ������ rec_count + 1<br/>
 *         <li>lastrec ������ rec_count + 1
 *       </ul>
 *     <li>� ������� fp, fpp, buffer_put ���������� ������ ������.
 *     <li>����� ��������� append, go, next, skip, dbflush, dbclose
 *       ������ ����������� � ����� �����.
 *   </ol>
 * </ul>
 * ���������� � �������� 2:
 * <ol>
 *   <li>���� ���� 2 �� ����, �� ��� 3 ���� �� ������
 *   <li>���� ��������� ��� ������� append - ��� ����� ��������� ��� �����
 *     ��������� ������ ���� �����.
 *   <li>���� ������ �������� �� 3 ������� put_record, add_record, ��� append_record
 *     ���� ���������� � ������������ � ����������� ���� �������, �������� �� ��,
 *     ��� ����� ���� ��� append
 * </ol>
 * @headcom
 */

INVALID_PATH exception;
INVALID_OPERATION exception;
IO_ERROR exception;
BAD_FORMAT exception;
BAD_STRUCT exception;
TOO_MANY_FIELDS exception;
NO_SUCH_FIELD exception;
BAD_FIELD_VALUE exception;
INVALID_HANDLE exception;
INVALID_MEMO_HANDLE exception;

subtype dbf_file_info_t is pls_integer;

/**
 *��������� ������� dBASE5 ��� �������� � <a href="#dbcreate(varchar2,varchar2,varchar2,boolean,varchar2,boolean,pls_integer)">dbcreate</a>
 */
dBASE5 constant pls_integer := 3;

/**
 *��������� ������� dBASE7 ��� �������� � <a href="#dbcreate(varchar2,varchar2,varchar2,boolean,varchar2,boolean,pls_integer)">dbcreate</a>
 */
dBASE7 constant pls_integer := 4;

/**
 *��������� ������� VISUAL_FOXPRO ��� �������� � <a href="#dbcreate(varchar2,varchar2,varchar2,boolean,varchar2,boolean,pls_integer)">dbcreate</a>
 */
VISUAL_FOXPRO constant pls_integer := 48;

/**
 * ���������� ��������� � ����������� �����.
 * @param p_db_text ��������� ���� ������ (� ������� ���������� �������������)
 *   ��-��������� �� stdio, ���� ��� �� ������, �� stdio.UNXTEXT.
 * @param p_file_text ��������� ����� (�� ������� ���������� �������������).
 *   ��-��������� stdio.DOSTEXT.
 * @param p_slash ����. ��-��������� �� stdio, ���� ��� �� �����, �� '/'.
 */
procedure set_def_text(p_db_text   varchar2 default null,
                       p_file_text varchar2 default null,
                       p_slash     varchar2 default null);
/**
 * ��������� ����.
 * @param location ������� ������������ �����.
 * @param filename ��� �����.
 * @param raising ���� ���������� � true, �� ��� ������� �������� �����
 *   ��������� ���������� INVALID_PATH, INVALID_MODE,
 *   INVALID_OPERATION, ����� �������� ��������� �� ������.
 * @param open_mode ���� �������� ����� ('r' - ������, 'w' - ������,
 *   'a' - ������ � ����� �����, 'r+', 'rw', 'w+', 'wr' - ������/������
 *   'a+' - ������/������ � ����� �����).
 * @param buffered_io �������� �����/������ ����������.
 * @param cnv_encs ��������������� ��������� ���� �� ���������
 *   ����� � ��������� ���� � ��������.
 * <ul>
 *   <li>���� ���������� � false, �� ����/����� ���������� ���������,
 *     � ���� ����� ������ ���� ������.
 *   <li>���� true - ����/����� ������� �� 32767 ����. ��� ����, ����
 *     ������ ����� <= 2M � ���� ������ ������ ��� ������, � �����
 *     ���������� ��� ����������� ������ � ���������� ������ �� ����������.
 *   <li>���� ������ ����� > 2M ��� ���� ������ �� ������/���������� � ���� �����
 *     �� 32768/����� ������ �����, ��� ������� � ���������� � ���� �����
 *     ��������� �� 2 * 32768/����� ������ �����.
 * </ul>
 * @return �������� ���� dbf_file_info_t - ���������� ��������� �����.
 */
function dbopen(location in varchar2, filename in varchar2,
                raising in boolean := true,
                open_mode in varchar2 := 'r', buffered_io in boolean := true,
                cnv_encs in boolean := true) return dbf_file_info_t;
/**
 * ������� ����.
 * @param location ��. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 * @param filename ��. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 * @param struct ��������� �����.<br>
 *   ������ ������� ���������: 'FLD1 C30, FLD2 N10.2, FLD3 D8, FLD4 M10'<br/>
 *   ��� ����, ��� � ������ ������ ���� ������ �����������, ����� � ����� ����������
 *   ������ - �����������. ����������� �������� ����� - ','(�������), �������� �������
 *   ������ ���. ����� ������ ���� >= ����� ���������� ������, ���� ��� ������. �����
 *   ���� �� ����� ���� >255. ����� memo-���� ������ ���� = 10. ������ ��������,
 *   � ��� ����� ������������ �������� ����� � �� ������������ �� ��������,
 *   ��� ����������� � �������� dbf ����� "��� ����".
 *   ��� ��������� ��������� ������������� ����� ����� ������������ ������� dbstruct.
 * @param raising ��. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 * @param open_mode -  ��. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>,
 *   �������� 'r'(������) �����, ���� ����� ������, �� ������ ����� �������������� ��������.
 * @param buffered_io ��. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 * @param version ������ ������������ �����. ���� �������� ���-������ ����� �������� dBASE5 � dBASE7,
 *   ����� ������������� ���������� BAD_FORMAT.
 * @param cnv_encs ��������������� ��������� ���� �� ���������
 *   ����� � ��������� ���� � ��������.
 * @param memo_filename ��� ����� ���� memo. �� ��������� ����������� ��� filename.DBT.
 * @return �������� ���� dbf_file_info_t - ���������� ���������� �����.
 */
function dbcreate(location in varchar2, filename in varchar2, struct in varchar2,
                  raising in boolean := true, open_mode in varchar2 := 'a',
                  buffered_io in boolean := true, version pls_integer := dBASE5,
                  cnv_encs in boolean := true, memo_filename in varchar2 := null) return dbf_file_info_t;
/**
 * ��������� ����.
 * @param dbh ���������� �����, ���������� �� dbopen ��� dbcreate
 * @param raising ��. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
procedure dbclose(dbh in dbf_file_info_t, raising in boolean default true);

/**
 * ���������� ��������� ����� � ������� dbcreate.
 * @param dbh ���������� �����, ���������� �� dbopen ��� dbcreate
 * @param raising ��. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
function dbstruct(dbh in dbf_file_info_t, raising in boolean default true) return varchar2;

/**
 * ������� ���������� � dbf ����� ����� stdio.put_line_buf.
 * @param dbh ���������� �����, ���������� �� dbopen ��� dbcreate
 * @param afields ���� true, ���� � �������� ������, ������� ������ � �����
 * @param arecs ���� true, ���� � �������� ������, ������� ������ �� ����.
 */
procedure dbdump(dbh in dbf_file_info_t, afields in boolean default false, arecs in boolean default false);

/**
 * ���������� ��� ���� �� ������ ����.
 * @param dbh ���������� �����, ���������� �� dbopen ��� dbcreate
 * @param i ����� ����, ������� � 1
 * @param raising ��. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
function field(dbh in dbf_file_info_t, i pls_integer, raising in boolean default true) return varchar2;

/**
 * ���������� ����� ���� �� �����.
 * @param dbh ���������� �����, ���������� �� dbopen ��� dbcreate
 * @param s ��� ����
 * @param raising ��. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
function fieldpos(dbh in dbf_file_info_t, s varchar2, raising in boolean default true) return pls_integer;



/**
 * ���������� �������� ���� ����� i �� ������ ������. ���� ���� D ������������
 * � ������� DD/MM/YYYY, ��� ����� ���� � ����������� rtrim, ��� ����� ���� N
 * ����������� trim, ���� ��������� ����� ������������ "��� ����".
 * @param dbh ���������� �����, ���������� �� dbopen ��� dbcreate
 * @param i ����� ����, ������� � 1
 * @param raising ��. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
function fgp(dbh in dbf_file_info_t, i pls_integer, raising in boolean default true) return varchar2;

/**
 * ���������� �������� ���� � ������ s �� ������ ������.
 * @param dbh ���������� �����, ���������� �� dbopen ��� dbcreate
 * @param s ��� ����
 * @param raising ��. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
function fg(dbh in dbf_file_info_t, s varchar2, raising in boolean default true) return varchar2;

/**
 * ������������� � ������ ������ �������� ���� � ������� i ������ v.
 * @param dbh ���������� �����, ���������� �� dbopen ��� dbcreate
 * @param i ����� ����, ������� � 1
 * @param v ����� �������� ����
 * @param raising ��. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 * @param conv_string ������� "��������������� ������ � ������������ � ����� ����"
 */
procedure fpp(dbh in dbf_file_info_t, i pls_integer, v varchar2, raising in boolean default true,
               conv_string in boolean default true);

/**
 * ������������� � ������ ������ �������� ���� � ������ s ������ v.
 * @param dbh ���������� �����, ���������� �� dbopen ��� dbcreate
 * @param s ��� ����
 * @param v ����� �������� ����
 * @param raising ��. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 * @param conv_string ������� "��������������� ������ � ������������ � ����� ����"
 */
procedure fp(dbh in dbf_file_info_t, s varchar2, v varchar2, raising in boolean default true,
              conv_string in boolean default true);


/**
 * ���������� true, ���� ����� ������ ����� ������� "�������".
 * @param dbh ���������� �����, ���������� �� dbopen ��� dbcreate
 * @param raising ��. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
function deleted(dbh in dbf_file_info_t, raising in boolean default true) return boolean;



/**
 * ������� ����� ������. ���� ���� ����� ����� ���������� (buffer_put, fp, fpp),
 * �� ��� ��������� append, go, gonext ���� skip �� ����� �������� � ����� �����.
 * @param dbh ���������� �����, ���������� �� dbopen ��� dbcreate
 * @param raising ��. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
procedure append(dbh in dbf_file_info_t, raising in boolean default true);

/**
 * ��������� ����� ������ � ����� �����. ����� ������ �� ����������.
 * ����������� ������ ���������� �������.
 * @param dbh ���������� �����, ���������� �� dbopen ��� dbcreate
 * @param raising ��. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
procedure append_record(dbh in dbf_file_info_t, raising in boolean default true);

/**
 * �������� ������ � ������� � �� ����� ����� �� ���� �������. ��������� ����� ������
 * � ������� ������� �����. ���� ������� � ��������� bof = true ��� eof = true - ���������
 * ������ � ������ ��� ����� ����� ��������������. ����� ������ �� ����������.
 * @param dbh ���������� �����, ���������� �� dbopen ��� dbcreate
 * @param raising ��. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
procedure add_record(dbh in dbf_file_info_t, raising in boolean default true);

/**
 * ���������� ����� ������ � ������� ����� n. ����� ������ �� ����������.
 * @param dbh ���������� �����, ���������� �� dbopen ��� dbcreate
 * @param n ����� ������ ������� ����� ����������, ������� � 1.
 *   ���� null �� ������� ������� �������, ���� �� null, �� �������
 *   ���������� ������ � ������� n.
 *   ���� ����� ������ < 1, �� ����������:<br/>
 *     go(dbh, 1);<br/>
 *     add_record(dbh);<br/>
 *   ���� ����� ������ > lastrec(dbh), �� ����������:<br/>
 *     append_record(dbh);
 * @param raising ��. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
procedure put_record(dbh in dbf_file_info_t, n in pls_integer default null, raising in boolean default true);

/**
 * �������� ����� ������ ��� ���������.
 * @param dbh ���������� �����, ���������� �� dbopen ��� dbcreate
 * @param raising ��. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
procedure delete_record(dbh in dbf_file_info_t, raising in boolean default true);

/**
 * ���������� ���������� ������ ������. ���� ������� buffer_get/buffer_set �����
 * �������������� ��� ����������� ������ ���������� ��������� �� ������ �������.
 * @param dbh ���������� �����, ���������� �� dbopen ��� dbcreate
 * @param raising ��. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
function buffer_get(dbh in dbf_file_info_t, raising in boolean default true) return varchar2;

/**
 * ������������� ���������� ������ ������.
 * @param dbh ���������� �����, ���������� �� dbopen ��� dbcreate
 * @param raising ��. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
procedure buffer_put(dbh in dbf_file_info_t, s varchar2, raising in boolean default true);

/**
 * ������� ���������� ������ ������.
 * @param dbh ���������� �����, ���������� �� dbopen ��� dbcreate
 * @param raising ��. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
procedure buffer_clear(dbh in dbf_file_info_t, raising in boolean default true);

/**
 * ���������� ���������� ���� �� ����. ����� ������ ������ �� �����������.
 * @param dbh ���������� �����, ���������� �� dbopen ��� dbcreate
 * @param raising ��. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
procedure dbflush(dbh in dbf_file_info_t, raising in boolean default true);



/**
 * ���������� ����� ������� ������ ����� dbh.
 * @param dbh ���������� �����, ���������� �� dbopen ��� dbcreate
 * @param raising ��. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
function recno(dbh in dbf_file_info_t, raising in boolean default true) return pls_integer;

/**
 * �������� ��������� ������� ������ �� �������� ������. �� ����� ������ ����������� ��������
 * ������ � ������� ������, ������� ������ ���������� � ����� ������.
 * ��� ������� ������ �� ��������� �����, ��������������� ���������������
 * ������� (bof/eof) � ���������� ������ ������ �� �� ����������.
 * @param dbh ���������� �����, ���������� �� dbopen ��� dbcreate
 * @param nn ����� ����� ������� ������, ������� � 1
 * @param raising ��. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
procedure go(dbh in dbf_file_info_t, nn pls_integer, raising in boolean default true);

/**
 * �������� ��������� ������� ������ �� �������� ����� �������. �� ����� ������ �����������
 * �������� ������ � ������� ������, ������� ������ ���������� � ����� ������. n ����� ����
 * ��� �������������, ��� � �������������. ��� ������� ������ �� ��������� �����,
 * ��������������� ��������������� ������� (bof/eof) � ���������� ������ ������ �� �� ����������.
 * ������ go(dbh, recno(dbh) + n)
 * @param dbh ���������� �����, ���������� �� dbopen ��� dbcreate
 * @param n �������� ����� ������� ������ �� �������
 * @param raising ��. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
procedure skip(dbh in dbf_file_info_t, n in pls_integer, raising in boolean default true);

/**
 * �������� ��������� ������� ������ �� ��������� ������. �� ����� ������ ����������� ��������
 * ������ � ������� ������, ������� ������ ���������� � ����� ������. ��� ������� ������ �����
 * ����� ������������� ������� eof � ���������� ������ ������ �� �� ����������.
 * ������ skip(dbh, 1) � go(dbh, recno(dbh) + 1).
 * @param dbh ���������� �����, ���������� �� dbopen ��� dbcreate
 * @param raising ��. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
procedure gonext(dbh in dbf_file_info_t, raising in boolean default true);

/**
 * ���������� ������� ����� �����. ������� ��������������� ��� ������� ���������
 * � ������ � ������� > lastrec, ������� ��� ���������������� ������ �����
 * � ����� � ������� dbnext(dbh) ��� skip(dbh,1). ���� ���� �������� 0 �������,
 * �� ������� ��������������� ����� ����� �������� �����.
 * @param dbh ���������� �����, ���������� �� dbopen ��� dbcreate
 * @param raising ��. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
function eof(dbh in dbf_file_info_t, raising in boolean default true) return boolean;

/**
 * ���������� ������� ������ �����. ������� ��������������� ��� �������
 * ��������� � ������ � ������� < 1, �������� ��� ������ ����� � �������� �������
 * � ������� skip(dbh,-1). ���� ���� �������� 0 �������, �� ������� ���������������
 * ����� ����� �������� �����.
 * @param dbh ���������� �����, ���������� �� dbopen ��� dbcreate
 * @param raising ��. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
function bof(dbh in dbf_file_info_t, raising in boolean default true) return boolean;

/**
 * ���������� ����� ����� � �����.
 * @param dbh ���������� �����, ���������� �� dbopen ��� dbcreate
 * @param raising ��. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
function fcount(dbh in dbf_file_info_t, raising in boolean default true) return pls_integer;

/**
 * ���������� ������ ������.
 * @param dbh ���������� �����, ���������� �� dbopen ��� dbcreate
 * @param raising ��. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
function recsize(dbh in dbf_file_info_t, raising in boolean default true) return pls_integer;

/**
 * ���������� ����� ��������� �����.
 * @param dbh ���������� �����, ���������� �� dbopen ��� dbcreate
 * @param raising ��. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
function header(dbh in dbf_file_info_t, raising in boolean default true) return pls_integer;

/**
 * ���������� ����� ������� � �����.
 * @param dbh ���������� �����, ���������� �� dbopen ��� dbcreate
 * @param raising ��. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
function lastrec(dbh in dbf_file_info_t, raising in boolean default true) return pls_integer;


/**
 * ��������� ��� �������� �����.
 * @param raising ��. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
procedure close_all(raising in boolean default true);

end;
/
show err

