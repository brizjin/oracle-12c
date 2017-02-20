prompt dbf header
create or replace package dbf is
/**
 * <hr/>
 * $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/dbf1.sql $<br/>
 * $Author: Alexey $<br/>
 * $Revision: 15072 $<br/>
 * $Date:: 2012-03-06 13:41:17 +#$<br/>
 * <hr/><br/>
 * DBF - чтение и запись DBF файлов.<br/>
 * Если нужно получить данные из какой-либо записи в файле:<br/>
 * <ol>
 *   <li>Выполняете go, gonext либо skip, чтобы переместиться на нужную запись
 *       и поместить ее в буфер редактирования.
 *   <li>с помощью fg, fgp, buffer_get, deleted читаете нужные данные.
 * </ol>
 * Если нужно изменить данные какой-либо записи в файле:<br/>
 * <ol>
 *   <li>Выполняете go, gonext либо skip, чтобы переместиться на нужную запись
 *     и поместить ее в буфер редактирования.
 *   <li>с помощью fp, fpp, buffer_put, delete_record изменяете нужные данные.
 *   <li>с помощью put_record с параметром n = null (по-умолчанию) записываете
 *     изменения в файл.
 * </ol>
 * Если нужно добавить данные в файл:
 * <ul>
 * <li>Вариант 1 (основной):
 *   <ol>
 *     <li>с помощью fp, fpp, buffer_put формируете нужную запись.
 *     <li>далее:
 *       <ul>
 *         <li>с помощью append_record добавляете сформированную запись в конец файла,
 *         <li>либо с помощью go, gonext либо skip перемещаетесь в нужную позицию,
 *           и с помощью add_record вставляете новую запись в эту позицию.
 *       </ul>
 *   </ol>
 * <li>Вариант 2 (для совместимости):
 *   <ol>
 *     <li>Выполняете append, в результате получаете:<br/>
 *       <ul>
 *         <li>чистый буфер редактирования<br/>
 *         <li>recno выдает rec_count + 1<br/>
 *         <li>lastrec выдает rec_count + 1
 *       </ul>
 *     <li>с помощью fp, fpp, buffer_put формируете нужную запись.
 *     <li>после следующих append, go, next, skip, dbflush, dbclose
 *       данные добавляются в конец файла.
 *   </ol>
 * </ul>
 * Примечания к варианту 2:
 * <ol>
 *   <li>Если шага 2 НЕ было, то шаг 3 файл НЕ меняет
 *   <li>Если НЕСКОЛЬКО раз позвать append - все будет выглядеть как будто
 *     произошел только ОДИН вызов.
 *   <li>Если вместо операций из 3 позвать put_record, add_record, или append_record
 *     файл изменяется в соответствии с назначением этих функций, несмотря на то,
 *     что перед этим был append
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
 *Константа формата dBASE5 для передачи в <a href="#dbcreate(varchar2,varchar2,varchar2,boolean,varchar2,boolean,pls_integer)">dbcreate</a>
 */
dBASE5 constant pls_integer := 3;

/**
 *Константа формата dBASE7 для передачи в <a href="#dbcreate(varchar2,varchar2,varchar2,boolean,varchar2,boolean,pls_integer)">dbcreate</a>
 */
dBASE7 constant pls_integer := 4;

/**
 *Константа формата VISUAL_FOXPRO для передачи в <a href="#dbcreate(varchar2,varchar2,varchar2,boolean,varchar2,boolean,pls_integer)">dbcreate</a>
 */
VISUAL_FOXPRO constant pls_integer := 48;

/**
 * Выставляет кодировки и направление слэша.
 * @param p_db_text кодировка базы данных (в которую происходит перекодировка)
 *   по-умолчанию из stdio, если там не задана, то stdio.UNXTEXT.
 * @param p_file_text кодировка файла (из которой происходит перекодировка).
 *   по-умолчанию stdio.DOSTEXT.
 * @param p_slash слэш. по-умолчанию из stdio, если там не задан, то '/'.
 */
procedure set_def_text(p_db_text   varchar2 default null,
                       p_file_text varchar2 default null,
                       p_slash     varchar2 default null);
/**
 * Открывает файл.
 * @param location каталог расположения файла.
 * @param filename имя файла.
 * @param raising если установлен в true, то при ошибках открытия файла
 *   возникают исключения INVALID_PATH, INVALID_MODE,
 *   INVALID_OPERATION, иначе выдаются сообщения об ошибке.
 * @param open_mode мода открытия файла ('r' - чтение, 'w' - запись,
 *   'a' - запись в конец файла, 'r+', 'rw', 'w+', 'wr' - чтение/запись
 *   'a+' - чтение/запись в конец файла).
 * @param buffered_io Операции ввода/вывода отложенные.
 * @param cnv_encs Преобразовывать текстовые поля из кодировки
 *   файла в кодировку базы и наоборот.
 * <ul>
 *   <li>Если установлен в false, то ввод/вывод происходит построчно,
 *     в кэше лежит только одна строка.
 *   <li>Если true - ввод/вывод блоками по 32767 байт. При этом, если
 *     размер файла <= 2M и файл открыт только для чтения, в буфер
 *     помещаются все прочитанные строки и повторного чтения не происходит.
 *   <li>Если размер файла > 2M или файл открыт на запись/добавление в кэше лежат
 *     до 32768/длина строки строк, при вставке и добавлении в кэше может
 *     оказаться до 2 * 32768/длина строки строк.
 * </ul>
 * @return значение типа dbf_file_info_t - дескриптор открытого файла.
 */
function dbopen(location in varchar2, filename in varchar2,
                raising in boolean := true,
                open_mode in varchar2 := 'r', buffered_io in boolean := true,
                cnv_encs in boolean := true) return dbf_file_info_t;
/**
 * Создает файл.
 * @param location см. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 * @param filename см. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 * @param struct структура файла.<br>
 *   Пример задания структуры: 'FLD1 C30, FLD2 N10.2, FLD3 D8, FLD4 M10'<br/>
 *   Имя поля, тип и размер должны быть заданы обязательно, точка и число десятичных
 *   знаков - опциональны. Разделитель описания полей - ','(запятая), возможны пробелы
 *   вокруг нее. Длина должна быть >= числу десятичных знаков, если оно задано. Длина
 *   поля не может быть >255. Длина memo-поля должна быть = 10. Других проверок,
 *   в том числе корректности заданных типов и их размерностей не делается,
 *   все переносится в заоловок dbf файла "как есть".
 *   Для получения структуры существующего файла можно использовать функцию dbstruct.
 * @param raising см. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 * @param open_mode -  см. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>,
 *   задавать 'r'(чтение) можно, файл будет создан, но нельзя будет манипулировать строками.
 * @param buffered_io см. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 * @param version формат создаваемого файла. Если передать что-нибудь кроме констант dBASE5 и dBASE7,
 *   будет сгенерировано исключение BAD_FORMAT.
 * @param cnv_encs Преобразовывать текстовые поля из кодировки
 *   файла в кодировку базы и наоборот.
 * @param memo_filename имя файла типа memo. По умолчанию формируется как filename.DBT.
 * @return значение типа dbf_file_info_t - дескриптор созданного файла.
 */
function dbcreate(location in varchar2, filename in varchar2, struct in varchar2,
                  raising in boolean := true, open_mode in varchar2 := 'a',
                  buffered_io in boolean := true, version pls_integer := dBASE5,
                  cnv_encs in boolean := true, memo_filename in varchar2 := null) return dbf_file_info_t;
/**
 * Закрывает файл.
 * @param dbh дескриптор файла, полученный от dbopen или dbcreate
 * @param raising см. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
procedure dbclose(dbh in dbf_file_info_t, raising in boolean default true);

/**
 * Возвращает структуру файла в формате dbcreate.
 * @param dbh дескриптор файла, полученный от dbopen или dbcreate
 * @param raising см. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
function dbstruct(dbh in dbf_file_info_t, raising in boolean default true) return varchar2;

/**
 * Выводит информацию о dbf файле через stdio.put_line_buf.
 * @param dbh дескриптор файла, полученный от dbopen или dbcreate
 * @param afields если true, плюс к основным данным, выводит данные о полях
 * @param arecs если true, плюс к основным данным, выводит строки их кэша.
 */
procedure dbdump(dbh in dbf_file_info_t, afields in boolean default false, arecs in boolean default false);

/**
 * Возвращает имя поля по номеру поля.
 * @param dbh дескриптор файла, полученный от dbopen или dbcreate
 * @param i номер поля, начиная с 1
 * @param raising см. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
function field(dbh in dbf_file_info_t, i pls_integer, raising in boolean default true) return varchar2;

/**
 * Возвращает номер поля по имени.
 * @param dbh дескриптор файла, полученный от dbopen или dbcreate
 * @param s имя поля
 * @param raising см. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
function fieldpos(dbh in dbf_file_info_t, s varchar2, raising in boolean default true) return pls_integer;



/**
 * Возвращает значение поля номер i из буфера записи. Поля типа D возвращаются
 * в формате DD/MM/YYYY, для полей типа С выполняется rtrim, для полей типа N
 * выполняется trim, поля остальных типов возвращаются "как есть".
 * @param dbh дескриптор файла, полученный от dbopen или dbcreate
 * @param i номер поля, начиная с 1
 * @param raising см. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
function fgp(dbh in dbf_file_info_t, i pls_integer, raising in boolean default true) return varchar2;

/**
 * Возвращает значение поля с именем s из буфера записи.
 * @param dbh дескриптор файла, полученный от dbopen или dbcreate
 * @param s имя поля
 * @param raising см. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
function fg(dbh in dbf_file_info_t, s varchar2, raising in boolean default true) return varchar2;

/**
 * Устанавливает в буфере записи значение поля с номером i равным v.
 * @param dbh дескриптор файла, полученный от dbopen или dbcreate
 * @param i номер поля, начиная с 1
 * @param v новое значение поля
 * @param raising см. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 * @param conv_string признак "Преобразовывать строку в соответствии с типом поля"
 */
procedure fpp(dbh in dbf_file_info_t, i pls_integer, v varchar2, raising in boolean default true,
               conv_string in boolean default true);

/**
 * Устанавливает в буфере записи значение поля с именем s равным v.
 * @param dbh дескриптор файла, полученный от dbopen или dbcreate
 * @param s имя поля
 * @param v новое значение поля
 * @param raising см. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 * @param conv_string признак "Преобразовывать строку в соответствии с типом поля"
 */
procedure fp(dbh in dbf_file_info_t, s varchar2, v varchar2, raising in boolean default true,
              conv_string in boolean default true);


/**
 * Возвращает true, если буфер записи имеет признак "удалена".
 * @param dbh дескриптор файла, полученный от dbopen или dbcreate
 * @param raising см. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
function deleted(dbh in dbf_file_info_t, raising in boolean default true) return boolean;



/**
 * Очищает буфер записи. Если поле этого буфер изменяется (buffer_put, fp, fpp),
 * то при следующем append, go, gonext либо skip он будет добавлен в конец файла.
 * @param dbh дескриптор файла, полученный от dbopen или dbcreate
 * @param raising см. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
procedure append(dbh in dbf_file_info_t, raising in boolean default true);

/**
 * Добавляет буфер записи в конец файла. Буфер записи не изменяется.
 * Добавленная запись становится текущей.
 * @param dbh дескриптор файла, полученный от dbopen или dbcreate
 * @param raising см. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
procedure append_record(dbh in dbf_file_info_t, raising in boolean default true);

/**
 * Сдвигает записи с текущей и до конца файла на одну позицию. Вставляет буфер записи
 * в текущую позицию файла. если вызвана в состоянии bof = true или eof = true - добавляет
 * запись в начало или конец файла соответственно. Буфер записи не изменяется.
 * @param dbh дескриптор файла, полученный от dbopen или dbcreate
 * @param raising см. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
procedure add_record(dbh in dbf_file_info_t, raising in boolean default true);

/**
 * Записывает буфер записи в позицию файла n. Буфер записи не изменяется.
 * @param dbh дескриптор файла, полученный от dbopen или dbcreate
 * @param n номер записи которую нужно переписать, начиная с 1.
 *   Если null то берется текущая позиция, если не null, то текущей
 *   становится запись с номером n.
 *   Если номер записи < 1, то происходит:<br/>
 *     go(dbh, 1);<br/>
 *     add_record(dbh);<br/>
 *   Если номер записи > lastrec(dbh), то происходит:<br/>
 *     append_record(dbh);
 * @param raising см. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
procedure put_record(dbh in dbf_file_info_t, n in pls_integer default null, raising in boolean default true);

/**
 * Помечает буфер записи как удаленный.
 * @param dbh дескриптор файла, полученный от dbopen или dbcreate
 * @param raising см. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
procedure delete_record(dbh in dbf_file_info_t, raising in boolean default true);

/**
 * Возвращает содержимое буфера записи. Пара функций buffer_get/buffer_set может
 * использоваться для копирования файлов одинаковой структуры на уровне записей.
 * @param dbh дескриптор файла, полученный от dbopen или dbcreate
 * @param raising см. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
function buffer_get(dbh in dbf_file_info_t, raising in boolean default true) return varchar2;

/**
 * Устанавливает содержимое буфера записи.
 * @param dbh дескриптор файла, полученный от dbopen или dbcreate
 * @param raising см. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
procedure buffer_put(dbh in dbf_file_info_t, s varchar2, raising in boolean default true);

/**
 * Очищает содержимое буфера записи.
 * @param dbh дескриптор файла, полученный от dbopen или dbcreate
 * @param raising см. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
procedure buffer_clear(dbh in dbf_file_info_t, raising in boolean default true);

/**
 * Сбрасывает содержимое кэша на диск. Буфер записи никуда не сохраняется.
 * @param dbh дескриптор файла, полученный от dbopen или dbcreate
 * @param raising см. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
procedure dbflush(dbh in dbf_file_info_t, raising in boolean default true);



/**
 * Возвращает номер текущей записи файла dbh.
 * @param dbh дескриптор файла, полученный от dbopen или dbcreate
 * @param raising см. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
function recno(dbh in dbf_file_info_t, raising in boolean default true) return pls_integer;

/**
 * Сдвигает указатель текущей записи на заданную запись. Во время первой последующей операции
 * работы с буфером записи, текущая запись помещается в буфер записи.
 * При попытке чтения за границами файла, устанавливается соответствующий
 * признак (bof/eof) и содержимое буфера записи не не изменяется.
 * @param dbh дескриптор файла, полученный от dbopen или dbcreate
 * @param nn номер новой текущей записи, начиная с 1
 * @param raising см. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
procedure go(dbh in dbf_file_info_t, nn pls_integer, raising in boolean default true);

/**
 * Сдвигает указатель текущей записи на заданное число записей. Во время первой последующей
 * операции работы с буфером записи, текущая запись помещается в буфер записи. n может быть
 * как положительным, так и отрицательным. При попытке чтения за границами файла,
 * устанавливается соответствующий признак (bof/eof) и содержимое буфера записи не не изменяется.
 * Аналог go(dbh, recno(dbh) + n)
 * @param dbh дескриптор файла, полученный от dbopen или dbcreate
 * @param n смещение новой текущей записи от текущей
 * @param raising см. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
procedure skip(dbh in dbf_file_info_t, n in pls_integer, raising in boolean default true);

/**
 * Сдвигает указатель текущей записи на следующую запись. Во время первой последующей операции
 * работы с буфером записи, текущая запись помещается в буфер записи. При попытке чтения после
 * конца устанавливает признак eof и содержимое буфера записи не не изменяется.
 * Аналог skip(dbh, 1) и go(dbh, recno(dbh) + 1).
 * @param dbh дескриптор файла, полученный от dbopen или dbcreate
 * @param raising см. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
procedure gonext(dbh in dbf_file_info_t, raising in boolean default true);

/**
 * Возвращает признак конца файла. Признак устанавливается при попытке обратится
 * к записи с номером > lastrec, напрмер при последовательном чтении файла
 * в цикле с помощью dbnext(dbh) или skip(dbh,1). Если файл содержит 0 записей,
 * то признак устанавливается сразу после открытия файла.
 * @param dbh дескриптор файла, полученный от dbopen или dbcreate
 * @param raising см. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
function eof(dbh in dbf_file_info_t, raising in boolean default true) return boolean;

/**
 * Возвращает признак начала файла. Признак устанавливается при попытке
 * обратится к записи с номером < 1, например при чтении файла в обратном порядке
 * с помощью skip(dbh,-1). Если файл содержит 0 записей, то признак устанавливается
 * сразу после открытия файла.
 * @param dbh дескриптор файла, полученный от dbopen или dbcreate
 * @param raising см. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
function bof(dbh in dbf_file_info_t, raising in boolean default true) return boolean;

/**
 * Возвращает число полей в файле.
 * @param dbh дескриптор файла, полученный от dbopen или dbcreate
 * @param raising см. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
function fcount(dbh in dbf_file_info_t, raising in boolean default true) return pls_integer;

/**
 * Возвращает размер записи.
 * @param dbh дескриптор файла, полученный от dbopen или dbcreate
 * @param raising см. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
function recsize(dbh in dbf_file_info_t, raising in boolean default true) return pls_integer;

/**
 * Возвращает рамер заголовка файла.
 * @param dbh дескриптор файла, полученный от dbopen или dbcreate
 * @param raising см. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
function header(dbh in dbf_file_info_t, raising in boolean default true) return pls_integer;

/**
 * Возвращает число записей в файле.
 * @param dbh дескриптор файла, полученный от dbopen или dbcreate
 * @param raising см. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
function lastrec(dbh in dbf_file_info_t, raising in boolean default true) return pls_integer;


/**
 * Закрывает все открытые файлы.
 * @param raising см. <a href="#dbopen(varchar2,varchar2,boolean,varchar2,boolean)">dbopen</a>
 */
procedure close_all(raising in boolean default true);

end;
/
show err

