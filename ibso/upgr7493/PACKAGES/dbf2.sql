def ws=null;--stdio.put_line_buf
prompt dbf body
create or replace package body
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/dbf2.sql $
 *  $Author: Alexey $
 *  $Revision: 15072 $
 *  $Date:: 2012-03-06 13:41:17 #$
 */
dbf is
ERR_INVALID_PATH constant pls_integer := 1;
ERR_INVALID_OPERATION constant pls_integer := 2;
ERR_IO_ERROR constant pls_integer := 3;
ERR_BAD_FORMAT constant pls_integer := 4;
ERR_BAD_STRUCT constant pls_integer := 5;
ERR_TOO_MANY_FIELDS constant pls_integer := 6;
ERR_NO_SUCH_FIELD constant pls_integer := 7;
ERR_BAD_FIELD_VALUE constant pls_integer := 8;
ERR_INVALID_HANDLE constant pls_integer := 9;
ERR_INVALID_MEMO_HANDLE constant pls_integer := 10;

ENOENT constant pls_integer := -2;
BUF_SIZE constant pls_integer := 32767;
FULL_CACHE_BOUND  constant pls_integer := 1024*1024*2;

/*
 * Field Types.
 */
FLD_CHAR    constant varchar2(1) := 'C';
FLD_LOGICAL constant varchar2(1) := 'L';
FLD_NUMERIC constant varchar2(1) := 'N';
FLD_DATE    constant varchar2(1) := 'D';
FLD_MEMO    constant varchar2(1) := 'M';
FLD_FLOAT   constant varchar2(1) := 'F';
FLD_DOUBLE  constant varchar2(1) := 'O';

/*
 * Version mask: MSSSFVVV
 */
VER_NUMBER constant pls_integer           := 7;   /* bits 0-2 indicate version number                       */
VER_DBASE4_MEMO_FLAG constant pls_integer := 8;   /* Bit  3 indicate presence of a dBASE IV memo file       */
VER_DBASE4_SQL_TABLE constant pls_integer := 112; /* bits 4-6 indicate the presence of a dBASE IV SQL table */
VER_DBASE3_DBT_FLAG constant pls_integer  := 128; /* bit  7 indicates the presence of any .DBT memo file    */

subtype raw_buf is raw(32767);
subtype str_buf is varchar2(32767);

type file_rec is record (
    file_name varchar2(1000),
    mode_read boolean,
    mode_write boolean,
    mode_append boolean,
    fio_h pls_integer,

    file_encoding pls_integer,
    db_encoding pls_integer,

    /*
     * Byte(0) - Valid dBASE for Windows table file:
     *
     * bits 0-2 indicate version number: 3 for dBASE Level 5, 4 for dBASE Level 7.
     * Bit 3 and bit 7 indicate presence of a dBASE IV or dBASE for Windows memo file;
     * bits 4-6 indicate the presence of a dBASE IV SQL table;
     * bit 7 indicates the presence of any .DBT memo file (either a dBASE III PLUS type or a dBASE IV or dBASE for Windows memo file).
     */
    version pls_integer     := 0,
    dbf_version pls_integer := 0,
    memo_flag boolean       := false,
    dbt_flag boolean        := false,

    rec_count pls_integer,
    header_length pls_integer,
    rec_length pls_integer,
    lang_id pls_integer,
    lang_name varchar2(32),

    fields_offset pls_integer,
    field_length pls_integer,
    field_count pls_integer,

    field_sind pls_integer,
    rec_sind pls_integer,

    buf_full_file boolean,
    buf_size pls_integer,
    buf_ext_size pls_integer,
    rec_per_block pls_integer,
    buf_start_rec_no pls_integer,
    recs_in_buf_orig pls_integer,
    recs_in_buf pls_integer,
    rec_no pls_integer,
    buf_modified boolean,

    rec raw_buf,
    rec_dirty_read boolean,
    rec_appended boolean,
    rec_dirty_append boolean
);

type field_rec is record (
    name varchar2(32),
    tp varchar2(1),
    length pls_integer,
    scale pls_integer,

    offset pls_integer
);

/* memo block size */
DBT_BLOCK_SIZE constant pls_integer := 512;
DBT_SEPARATOR constant pls_integer := 26;
DBT_HEAD_SIZE constant pls_integer := 8;
DBT_HEAD_PREF constant pls_integer := 258;

/* memo file */
type file_memo_rec is record (
    file_name varchar2(1000),                 /* memo file name                 */
    fio_h pls_integer,                        /* memo file pointer              */
    version pls_integer    := dBASE5,         /* not sure,                      */
    block_size pls_integer := DBT_BLOCK_SIZE, /* memo file block size           */
    head_size pls_integer  := DBT_HEAD_SIZE,  /* dBase7 head size               */
    head_pref pls_integer  := DBT_HEAD_PREF,  /* dBase7 head pref               */
    next_block pls_integer := 1,              /* pointer to next block to write */
    offset pls_integer     := DBT_BLOCK_SIZE, /* block offset                   */
    block_sep pls_integer  := DBT_SEPARATOR   /* separator                      */
);

type cs_tbl is table of varchar2(30) index by binary_integer;
type file_tbl is table of file_rec index by binary_integer;
type file_memo_tbl is table of file_memo_rec index by binary_integer;
type field_tbl is table of field_rec index by binary_integer;
type rec_tbl is table of raw_buf index by binary_integer;

ffiles file_tbl; ffiles_memo file_memo_tbl;
ffields field_tbl;
frecs rec_tbl;
fcss cs_tbl;

slash varchar2(1);
file_encoding pls_integer;
db_encoding pls_integer;

----------------------------------------------------------
-- Errors Handling
----------------------------------------------------------
procedure handle_error(
    errno in pls_integer,
    raising in boolean,
    p1 varchar2 default NULL,
    p2 varchar2 default NULL,
    p3 varchar2 default NULL,
    p4 varchar2 default NULL,
    p5 varchar2 default NULL,
    p6 varchar2 default NULL,
    p7 varchar2 default NULL,
    p8 varchar2 default NULL,
    p9 varchar2 default NULL
);

procedure report_error(
    errno in pls_integer,
    p1 varchar2 default NULL,
    p2 varchar2 default NULL,
    p3 varchar2 default NULL,
    p4 varchar2 default NULL,
    p5 varchar2 default NULL,
    p6 varchar2 default NULL,
    p7 varchar2 default NULL,
    p8 varchar2 default NULL,
    p9 varchar2 default NULL
);

procedure raise_error(errno in pls_integer);

procedure check_handle(dbh in pls_integer, raising in boolean);
procedure check_memo_handle(dbh in pls_integer, raising in boolean);

----------------------------------------------------------
-- Internals
----------------------------------------------------------
function eof_(afl in out nocopy file_rec) return boolean;
function bof_(afl in out nocopy file_rec) return boolean;
function r2i(r in raw, b in integer, n in integer) return pls_integer;
function i2r(i in integer, n in pls_integer) return raw;
function r2s(r in raw, b in pls_integer, n in pls_integer) return varchar2;
function s2r(s in varchar2, n in pls_integer, b in char default ' ') return raw;
procedure parse_mode(afl in out nocopy file_rec, m in varchar2);
procedure parse_header(afl in out nocopy file_rec, b in raw);
procedure parse_field(afl in file_rec, afld in out nocopy field_rec, b in raw);
procedure make_struct(afl in out nocopy file_rec, aflds in out nocopy field_tbl, astr in varchar2, raising in boolean);
function get_header_buf(afl in file_rec) return raw;
function get_field_buf(afl in file_rec, afld in field_rec) return raw;
procedure write_struct(afl in file_rec, aflds in field_tbl, af in pls_integer, raising in boolean);
function get_next_recsind return pls_integer;
procedure flush_cache(afl in out nocopy file_rec, raising in boolean);
procedure flush_buffer(afl in out nocopy file_rec, do_append in boolean, raising in boolean);
procedure fill_buffer(afl in out nocopy file_rec, abuf in raw, abuf_pos in pls_integer, arec_no in pls_integer);
procedure load_buffer(afl in out nocopy file_rec, raising in boolean);
procedure add_(afl in out nocopy file_rec, raising in boolean);
procedure put_(afl in out nocopy file_rec, raising in boolean);
procedure parse_version(afl in out nocopy file_rec, b in raw);
procedure parse_version(afl in out nocopy file_rec);
function is_version_supported(version pls_integer) return boolean;
function get_header_memo_buf(afl in file_memo_rec) return raw;
procedure write_struct_memo(afl in out nocopy file_memo_rec, af in pls_integer, raising in boolean);
function append_memo(dbh dbf_file_info_t, v varchar2, raising in boolean default true) return pls_integer;
function get_memo_buf(dbh dbf_file_info_t, v varchar2) return raw;

procedure fill_format_specifics(afl in out nocopy file_rec) is
begin
    if afl.dbf_version = dBASE7 then
        afl.fields_offset := 69;
        afl.field_length := 48;

        afl.lang_id := 0; -- must be zero for BDE 5.0
        if afl.file_encoding = stdio.DOSTEXT then
            afl.lang_name := 'db866ru0'; -- Code Page: 866, cyrr - Paradox Cyrr 866, db866ru0 - dBASE RUS cp866
        elsif afl.file_encoding = stdio.WINTEXT then
            afl.lang_name := 'ancyrr'; -- Code Page: 1251, ancyrr - Pdox ANSI Cyrillic
        else --stdio.UNXTEXT, stdio.KOITEXT
            null;
        end if;
    else
        afl.fields_offset := 33;
        afl.field_length := 32;

        afl.lang_id := 0; -- for compatibility with old package
    end if;
end;
----------------------------------------------------------
-- Interface
----------------------------------------------------------

----------------------------------------------------------
procedure set_def_text( p_db_text   varchar2 default null,
                        p_file_text varchar2 default null,
                        p_slash     varchar2 default null) is
    v_txt varchar2(1);
begin
    v_txt := substr(p_slash, 1, 1);
    if v_txt is null then
        v_txt := substr(stdio.setting('DEF_SLASH'), 1, 1);
    end if;
    if v_txt='\' then
        slash := '\';
    else
        slash := '/';
    end if;
    v_txt  := upper(substr(p_file_text, 1, 1));
    if v_txt='W' then
        file_encoding := stdio.WINTEXT;
    elsif v_txt='U' then
        file_encoding := stdio.UNXTEXT;
    elsif v_txt='K' then
        file_encoding := stdio.KOITEXT;
    else
        file_encoding := stdio.DOSTEXT;
    end if;
    v_txt  := substr(p_db_text, 1, 1);
    if v_txt is null then
        v_txt := substr(stdio.setting('DEF_TEXT'), 1, 1);
    end if;
    v_txt := upper(v_txt);
    if v_txt='W' then
        db_encoding := stdio.WINTEXT;
    elsif v_txt='D' then
        db_encoding := stdio.DOSTEXT;
    elsif v_txt='K' then
        db_encoding := stdio.KOITEXT;
    else
        db_encoding := stdio.UNXTEXT;
    end if;
    stdio.set_def_text(v_txt, slash);
end set_def_text;
----------------------------------------------------------

----------------------------------------------------------
function dbopen(location in varchar2, filename in varchar2,
                raising in boolean := true,
                open_mode in varchar2 := 'r', buffered_io in boolean := true,
                cnv_encs in boolean := true) return dbf_file_info_t as
    h pls_integer;
    b raw_buf;
    s pls_integer;
    fl file_rec;
    flds field_tbl;
    find pls_integer;
    field_offset pls_integer;
    n pls_integer;
    p pls_integer;
    abs_p pls_integer;
begin
    parse_mode(fl, open_mode);
    if fl.mode_write or fl.mode_append then
        h := stdio.f_open(location || slash || filename, 'rb+');
    else
        h := stdio.f_open(location || slash || filename, 'rb');
    end if;

    --open file
    if h = ENOENT then
        handle_error(ERR_INVALID_PATH, raising, location || slash || filename);
    elsif h < 0 then
        handle_error(ERR_INVALID_OPERATION, raising);
    end if;
    --read 32k
    s := stdio.f_read(h, b, BUF_SIZE);
    if s < 0 then
        stdio.close(h);
        handle_error(ERR_IO_ERROR, raising);
    end if;
        if s < 1 then
        stdio.close(h);
        handle_error(ERR_BAD_FORMAT, raising);
    end if;

    parse_version(fl, b);

    if not is_version_supported(fl.dbf_version) then
        stdio.close(h);
        handle_error(ERR_BAD_FORMAT, raising);
    end if;

    fl.fio_h := h;
    fl.file_name := location || slash || filename;
    fl.file_encoding := file_encoding;
    if cnv_encs then
        fl.db_encoding := db_encoding;
    else
        fl.db_encoding := fl.file_encoding;
    end if;

    fill_format_specifics(fl);
    --parse header
    parse_header(fl, utl_raw.substr(b, 1, fl.fields_offset - 1));

    --get bufs of fields and parse fields
    field_offset := 1;
    n := 0;
    p := fl.fields_offset;
    abs_p := p;
    while n < fl.field_count loop
        while n < fl.field_count and p + fl.field_length - 1 <= s loop

            -- Terminator (0Dh)
            if r2i(b, p, 1) = 13 then
                fl.field_count := n;
                exit;
            end if;
            n := n + 1;
            flds(n).offset := field_offset;
            parse_field(fl, flds(n), utl_raw.substr(b, p, fl.field_length));
            field_offset := field_offset + flds(n).length;
            p := p + fl.field_length;
            abs_p := abs_p + fl.field_length;
        end loop;
        if p + fl.field_length - 1 > s and n < fl.field_count then
            if s - p > 0 then
                p := stdio.f_seek(h, -(s - p) - 1, 1);
            end if;
            s := stdio.f_read(h, b, BUF_SIZE);
            p := 1;
        end if;
    end loop;
    fl.field_sind := nvl(ffields.last + 1, 1);
    for i in 1..fl.field_count loop
        ffields(fl.field_sind + i - 1) := flds(i);
    end loop;

    fl.rec_sind := get_next_recsind;
    if buffered_io then
        if fl.mode_write or fl.mode_append or fl.rec_count * fl.rec_length > FULL_CACHE_BOUND then
            fl.buf_size := trunc(BUF_SIZE / fl.rec_length);
            fl.buf_ext_size := fl.buf_size;
            fl.rec_per_block := fl.buf_size;
            fl.buf_full_file := false;
        else
            fl.buf_size := fl.rec_count;
            fl.buf_ext_size := 0;
            fl.rec_per_block := trunc(BUF_SIZE / fl.rec_length);
            fl.buf_full_file := true;
        end if;
    else
        fl.buf_size := 1;
        fl.buf_ext_size := 0;
        fl.rec_per_block := fl.buf_size;
        fl.buf_full_file := false;
    end if;
    fl.recs_in_buf := 0;
    fl.recs_in_buf_orig := 0;
    fl.buf_modified := false;

    fl.rec := utl_raw.copies('20', fl.rec_length);
    fl.rec_dirty_read := true;
    fl.rec_appended := false;
    fl.rec_dirty_append := false;

      --fill recs been read
    if fl.rec_count > 0 then
        if abs_p > fl.header_length then
            handle_error(ERR_BAD_FORMAT, raising);
        end if;
        fill_buffer(fl, b, p + fl.header_length - abs_p + 1, 1);
    end if;

    find := nvl(ffiles.last + 1, 1);
    ffiles(find) := fl;

    return find;
end dbopen;
----------------------------------------------------------

----------------------------------------------------------
function dbcreate(location in varchar2, filename in varchar2, struct in varchar2,
                  raising in boolean := true, open_mode in varchar2 := 'a',
                  buffered_io in boolean := true, version pls_integer := dBASE5,
                  cnv_encs in boolean := true, memo_filename in varchar2 := null) return dbf_file_info_t is

    find pls_integer;
    fl file_rec;
    flds field_tbl;
    h pls_integer;

    flm file_memo_rec;
begin

    fl.version := version;
    parse_version(fl);

    if not is_version_supported(fl.dbf_version) then
        handle_error(ERR_BAD_FORMAT, raising);
    end if;

    fl.file_encoding := file_encoding;
    if cnv_encs then
        fl.db_encoding := db_encoding;
    else
        fl.db_encoding := fl.file_encoding;
    end if;

    fill_format_specifics(fl);
    make_struct(fl, flds, struct, raising);

    h := stdio.f_open(location || slash || filename, 'wb');
    if h = ENOENT then
        handle_error(ERR_INVALID_PATH, raising, location || slash || filename);
    elsif h < 0 then
        handle_error(ERR_INVALID_OPERATION, raising);
    end if;
    write_struct(fl, flds, h, raising);

    fl.fio_h := h;
    fl.file_name := location || slash || filename;
    parse_mode(fl, open_mode);

    fl.field_sind := nvl(ffields.last + 1, 1);
    for i in 1..fl.field_count loop
        ffields(fl.field_sind + i - 1) := flds(i);
    end loop;

    fl.rec_sind := get_next_recsind;
    if buffered_io then
        fl.buf_size := trunc(BUF_SIZE / fl.rec_length);
        fl.buf_ext_size := fl.buf_size;
    else
        fl.buf_size := 1;
        fl.buf_ext_size := 0;
    end if;
    fl.rec_per_block := fl.buf_size;
    fl.buf_full_file := false;
    fl.recs_in_buf := 0;
    fl.recs_in_buf_orig := 0;
    fl.buf_modified := false;

    fl.rec := utl_raw.copies('20', fl.rec_length);
    fl.rec_dirty_read := true;
    fl.rec_appended := false;
    fl.rec_dirty_append := false;

    find := nvl(ffiles.last + 1, 1);
    ffiles(find) := fl;

    if fl.dbt_flag then
        if not memo_filename is null then
            flm.file_name := location || slash || memo_filename;
        else
            flm.file_name := substr(fl.file_name, 1, instr(fl.file_name, '.', -1))||'DBT';
        end if;

        flm.version := fl.dbf_version;

        h := stdio.f_open(flm.file_name, 'wb');
        if h = ENOENT then
            handle_error(ERR_INVALID_PATH, raising, flm.file_name);
        elsif h < 0 then
            handle_error(ERR_INVALID_OPERATION, raising);
        end if;
        write_struct_memo(flm, h, raising);

        flm.fio_h := h;
        ffiles_memo(find) := flm;
    end if;		

    return find;
end dbcreate;
----------------------------------------------------------

----------------------------------------------------------
procedure dbclose(dbh in dbf_file_info_t, raising in boolean default true) as
    tmp    pls_integer;
    fl file_rec;
    flm file_memo_rec;
begin
    check_handle(dbh, raising);
    fl := ffiles(dbh);

    if fl.dbt_flag then
        check_memo_handle(dbh, raising);
        flm := ffiles_memo(dbh);
    end if;

    if fl.mode_write or fl.mode_append then
        flush_buffer(fl, true, raising);
        flush_cache(fl, raising);
        tmp := stdio.f_seek(fl.fio_h, 0, 2);
        if tmp >= 0 and tmp <> (fl.header_length +
           fl.rec_length * fl.rec_count + 1) then
            tmp := stdio.f_write(fl.fio_h, hextoraw('1A'), 1);
        end if;
        tmp := stdio.f_seek(fl.fio_h, 0, 0);
        tmp := stdio.f_write(fl.fio_h, get_header_buf(fl));

        if fl.dbt_flag then
            tmp := stdio.f_seek(flm.fio_h, 0, 0);
            tmp := stdio.f_write(flm.fio_h, get_header_memo_buf(flm));
        end if;
    end if;

    if fl.dbt_flag then
        stdio.close(flm.fio_h);
        ffiles_memo.delete(dbh);
    end if;

    stdio.close(fl.fio_h);
    frecs.delete(fl.rec_sind, fl.rec_sind + fl.buf_size + fl.buf_ext_size - 1);
    ffields.delete(fl.field_sind, fl.field_sind + fl.field_count - 1);
    ffiles.delete(dbh);
end dbclose;
----------------------------------------------------------

----------------------------------------------------------
function dbstruct(dbh in dbf_file_info_t, raising in boolean default true) return varchar2 as
    buf    str_buf;
    fl file_rec;
    fld    field_rec;
begin
    check_handle(dbh, raising);
    fl := ffiles(dbh);
    for i in 0..fl.field_count - 1 loop
        fld := ffields(fl.field_sind + i);
        if buf is not null then
            buf := buf || ', ';
        end if;
        buf := buf || fld.name || ' ' || fld.tp || fld.length || '.' || fld.scale;
    end loop;
    return buf;
end dbstruct;
----------------------------------------------------------

----------------------------------------------------------
procedure dbdump(dbh in dbf_file_info_t, afields in boolean default false, arecs in boolean default false) as
begin
    stdio.put_line_buf('file:               ' || ffiles(dbh).file_name);
    if ffiles(dbh).mode_read then
        stdio.put_line_buf('mode_read:          true');
    else
        stdio.put_line_buf('mode_read:          false');
    end if;
    if ffiles(dbh).mode_write then
        stdio.put_line_buf('mode_write:         true');
    else
        stdio.put_line_buf('mode_write:         false');
    end if;
    if ffiles(dbh).mode_append then
        stdio.put_line_buf('mode_append:        true');
    else
        stdio.put_line_buf('mode_append:        false');
    end if;
    stdio.put_line_buf('fh:                 ' || ffiles(dbh).fio_h);
    stdio.put_line_buf('file_encoding:      ' || ffiles(dbh).file_encoding);
    stdio.put_line_buf('db_encoding:        ' || ffiles(dbh).db_encoding);
    stdio.put_line_buf('version:            ' || ffiles(dbh).version);
    stdio.put_line_buf('header_length       ' || ffiles(dbh).header_length);
    stdio.put_line_buf('field_count:        ' || ffiles(dbh).field_count);
    stdio.put_line_buf('rec_length:         ' || ffiles(dbh).rec_length);
    stdio.put_line_buf('rec_count:          ' || ffiles(dbh).rec_count);
    stdio.put_line_buf('lang_id:            ' || ffiles(dbh).lang_id);
    stdio.put_line_buf('lang_name:          ' || ffiles(dbh).lang_name);
    stdio.put_line_buf('field_sind:         ' || ffiles(dbh).field_sind);
    stdio.put_line_buf('rec_sind:           ' || ffiles(dbh).rec_sind);
    stdio.put_line_buf('');
    if ffiles(dbh).buf_full_file then
        stdio.put_line_buf('buf_full_file:      true');
    else
        stdio.put_line_buf('buf_full_file:      false');
    end if;
    stdio.put_line_buf('buf_size:           ' || ffiles(dbh).buf_size);
    stdio.put_line_buf('buf_ext_size:       ' || ffiles(dbh).buf_ext_size);
    stdio.put_line_buf('rec_per_block:      ' || ffiles(dbh).rec_per_block);
    stdio.put_line_buf('buf_start_rec_no:   ' || ffiles(dbh).buf_start_rec_no);
    stdio.put_line_buf('recs_in_buf_orig:   ' || ffiles(dbh).recs_in_buf_orig);
    stdio.put_line_buf('recs_in_buf:        ' || ffiles(dbh).recs_in_buf);
    stdio.put_line_buf('rec_no:             ' || ffiles(dbh).rec_no);
    if ffiles(dbh).buf_modified then
        stdio.put_line_buf('buf_modified:       true');
    else
        stdio.put_line_buf('buf_modified:       false');
    end if;
    if ffiles(dbh).rec_dirty_read then
        stdio.put_line_buf('rec_dirty_read:     true');
    else
        stdio.put_line_buf('rec_dirty_read:     false');
    end if;
    if ffiles(dbh).rec_appended then
        stdio.put_line_buf('rec_appended:       true');
    else
        stdio.put_line_buf('rec_appended:       false');
    end if;
    if ffiles(dbh).rec_dirty_append then
        stdio.put_line_buf('rec_dirty_append:   true');
    else
        stdio.put_line_buf('rec_dirty_append:   false');
    end if;

    if afields then
        stdio.put_line_buf('Fields:');
        stdio.put_line_buf('N'
        || chr(9) || 'Name'
        || chr(9) || 'Type'
        || chr(9) || 'Length'
        || chr(9) || 'Scale'
        || chr(9) || 'Offset');
        for i in 1..ffiles(dbh).field_count loop
            stdio.put_line_buf(
                          i
            || chr(9) || ffields(i - 1 + ffiles(dbh).field_sind).name
            || chr(9) || ffields(i - 1 + ffiles(dbh).field_sind).tp
            || chr(9) || ffields(i - 1 + ffiles(dbh).field_sind).length
            || chr(9) || ffields(i - 1 + ffiles(dbh).field_sind).scale
            || chr(9) || ffields(i - 1 + ffiles(dbh).field_sind).offset);
        end loop;
    end if;
    if arecs then
        stdio.put_line_buf('Records:');
        for i in 0..(ffiles(dbh).recs_in_buf - 1) loop
            if frecs.exists(ffiles(dbh).rec_sind + i) then
                stdio.put_line_buf((ffiles(dbh).buf_start_rec_no + i) || ':' || chr(9) || utl_raw.cast_to_varchar2(frecs(ffiles(dbh).rec_sind + i)));
            end if;
        end loop;
    end if;
exception
    when NO_DATA_FOUND then raise INVALID_OPERATION;
end dbdump;
----------------------------------------------------------

----------------------------------------------------------
function field(dbh in dbf_file_info_t, i pls_integer, raising in boolean default true) return varchar2 as
begin
    check_handle(dbh, raising);
    if i < 1 or ffiles(dbh).field_count < i then
        handle_error(ERR_NO_SUCH_FIELD, raising, i);
    end if;
    return ffields(ffiles(dbh).field_sind + i - 1).name;
end field;
----------------------------------------------------------

----------------------------------------------------------
function fieldpos(dbh in dbf_file_info_t, s varchar2, raising in boolean default true) return pls_integer as
begin
    check_handle(dbh, raising);
    for i in ffiles(dbh).field_sind..(ffiles(dbh).field_sind + ffiles(dbh).field_count - 1) loop
        if ffields(i).name = s then
            return i - ffiles(dbh).field_sind + 1;
        end if;
    end loop;
    handle_error(ERR_NO_SUCH_FIELD, raising, s);
end fieldpos;
----------------------------------------------------------

----------------------------------------------------------
function from_double(d raw, bBDE boolean, raising in boolean default true) return varchar2 as
  s number;
  e number;
  f number;
  n number;
  dd raw(8);
--
  function get_sign(d raw) return number is
  begin
    if to_number(utl_raw.bit_and(utl_raw.substr(d, 1, 1), '80'), 'FM0X')/128 = 0 then
      return 1;
    else
      return -1;
    end if;
  end;
--
  function get_exp(d raw) return number is
  begin
    return to_number(utl_raw.bit_and(utl_raw.substr(d, 1, 2), '7FF0'), 'FM000X')/16;
  end;
--
  function get_fraction(d raw) return number is
  begin
    return to_number(utl_raw.bit_and(d, '000FFFFFFFFFFFFF'), 'FM000000000000000X');
  end;
  function get_fraction2(d raw) return number is
  begin
    return to_number(utl_raw.bit_or(utl_raw.bit_and(d, '000FFFFFFFFFFFFF'), '0010000000000000'), 'FM000000000000000X');
  end;
--
begin
  if d is null then
      return null;
  end if;
  &&ws('d: '||d);
  s := get_sign(d);
  if bBDE then
    if s < 0 then
      s := 1;
      dd := d;
    else
      s := -1;
      dd := utl_raw.bit_complement(d);
    end if;
  else
    dd := d;
  end if;
  &&ws('dd: '||dd);
  e := get_exp(dd);
  &&ws('s: '||s||', e: '||e);
  if e = 0 then
    f := get_fraction(dd);
    if f = 0 then
      n := 0;
    else
      n := power(2, -1022 - 52) * f;
    end if;
  elsif e between 1 and 2046 then
    f := get_fraction2(dd);
    &&ws('f: '||f);
    n := power(2, e - 1023 + 1 - 53) * f;
  elsif f = 0 then
    --n := s || 'Infinity';
    n := null;
  else
    n := null;
    --n := s || 'NaN';
  end if;
  if n is null or n = 0 then
      return n;
  else
      declare
        l number;
        c number;
      begin
        l := log(10, n);
        c := ceil(l);
        if c = l then
          c := c + 1;
        end if;
        &&ws('l: '||l||', c: '||c);
        &&ws('n: '||n||', n shifted: '||(n * power(10, -c)));
        return s * round(n * power(10, -c), 15) * power(10, c);
      end;
  end if;
exception when VALUE_ERROR then
    handle_error(ERR_BAD_FIELD_VALUE, raising);
end;
----------------------------------------------------------
function fgp(dbh in dbf_file_info_t, i pls_integer, raising in boolean default true) return varchar2 as
    tmpr raw(255);
    tmps varchar2(255);
    fld field_rec;
begin
    check_handle(dbh, raising);
    if not ffiles(dbh).mode_read then
        handle_error(ERR_INVALID_OPERATION, raising);
    end if;

    if not ffiles(dbh).rec_appended and not ffiles(dbh).rec_dirty_append then
        load_buffer(ffiles(dbh), raising);
    end if;

    fld := ffields(ffiles(dbh).field_sind + i - 1);
    tmpr := utl_raw.substr(ffiles(dbh).rec, 1 + fld.offset, fld.length);
    if fld.tp = FLD_CHAR then
        return rtrim(utl_raw.cast_to_varchar2(tmpr), chr(0) || ' ');
    elsif fld.tp = FLD_NUMERIC then
        return trim(utl_raw.cast_to_varchar2(tmpr));
    elsif fld.tp = FLD_DATE then
        tmps := utl_raw.cast_to_varchar2(tmpr);
        if translate(tmps, '#0 ', '#') is null then
            return null;
        end if;
        return to_char(to_date(trim(tmps), 'YYYYMMDD'), 'DD/MM/YYYY');
    elsif fld.tp = FLD_DOUBLE then
        return from_double(tmpr, true, raising);
    else
        return utl_raw.cast_to_varchar2(tmpr);
    end if;
end fgp;
----------------------------------------------------------

----------------------------------------------------------
function fg(dbh in dbf_file_info_t, s varchar2, raising in boolean default true) return varchar2 as
begin
    return fgp(dbh, fieldpos(dbh, s, raising), raising);
end fg;
----------------------------------------------------------

----------------------------------------------------------
function to_double(n number, bBDE boolean) return raw is
  s number;
  e number;
  ee number;
  bf varchar2(53);
  be varchar2(53);
  bn varchar2(64);
  xn varchar2(16);
--
  procedure round_(bin in out nocopy varchar2, exp in out nocopy pls_integer) is
    bin2 varchar2(54) := bin;
    pos pls_integer;
  begin
    bin := substr(bin2, 1, 53);
    if substr(bin2, 54, 1) = '1' then
       &&ws('rounding');
       pos := instr(bin, '0', -1);
       &&ws('last zero pos: '||pos);
       if pos >= 1 then
         bin := substr(bin, 1, pos - 1) || '1' || rpad('0', 53 - pos, '0');
       else
         &&ws('no zero!!!');
         bin := '1' || rpad('0', 52, '0');
         exp := exp + 1;
       end if;
    end if;
  end;
--
  procedure to_bin(n number, bin in out nocopy varchar2, exp in out nocopy pls_integer) is
    bin2 varchar2(32767);
    n1 number := trunc(n);
    n2 number := n - n1;
    tmp number;
    cnt pls_integer;
    was_one boolean;
  begin
--
    exp := 0;
    while n1 > 0 loop
      tmp := n1 / 2;
      n1 := trunc(tmp);
      --&&ws('tmp: , '||tmp||', n1: '||n1);
      if tmp <> n1 then
        bin2 := '1' || bin2;
      else
        bin2 := '0' || bin2;
      end if;
      exp := exp + 1;
    end loop;
--
    &&ws('full bin2 (no frac): '||bin2);
--
    if exp > 52 then
      bin2 := substr(bin2, 1, 54);
      round_(bin2, exp);
      bin := bin2;
      return;
    end if;
--
    cnt := exp;
    if exp > 0 then
       was_one := true;
       &&ws('was_one := true');
    else
       was_one := false;
       &&ws('was_one := false');
    end if;
--
    while cnt <= 53 loop
      n2 := n2 * 2;
      --&&ws('n2: '||n2);
      if n2 < 1 then
        if was_one then
          bin2 := bin2 || '0';
        else
          &&ws('skipped');
        end if;
      else
        bin2 := bin2 || '1';
        n2 := n2 - 1;
        was_one := true;
      end if;
      if was_one then
        cnt := cnt + 1;
      else
        exp := exp - 1;
      end if;
    end loop;
    &&ws('bin2 (with frac): '||bin2);
    round_(bin2, exp);
    &&ws('bin2 (rounded): '||bin2);
    bin := bin2;
  end;
--
  procedure to_hex(bin in out nocopy varchar2, hex in out nocopy varchar2) is
    bin_len pls_integer := length(bin);
    hex_len pls_integer := bin_len / 4;
    digit varchar2(4);
  begin
    if hex_len * 4 <> bin_len then
      hex_len := hex_len + 1;
      bin := lpad('0', hex_len * 4, '0');
    end if;
    for i in 1..hex_len loop
       digit := substr(bin, (i - 1) * 4 + 1, 4);
       if digit = '0000' then
         hex := hex || '0';
       elsif digit = '0001' then
         hex := hex || '1';
       elsif digit = '0010' then
         hex := hex || '2';
       elsif digit = '0011' then
         hex := hex || '3';
       elsif digit = '0100' then
         hex := hex || '4';
       elsif digit = '0101' then
         hex := hex || '5';
       elsif digit = '0110' then
         hex := hex || '6';
       elsif digit = '0111' then
         hex := hex || '7';
       elsif digit = '1000' then
         hex := hex || '8';
       elsif digit = '1001' then
         hex := hex || '9';
       elsif digit = '1010' then
         hex := hex || 'A';
       elsif digit = '1011' then
         hex := hex || 'B';
       elsif digit = '1100' then
         hex := hex || 'C';
       elsif digit = '1101' then
         hex := hex || 'D';
       elsif digit = '1110' then
         hex := hex || 'E';
       elsif digit = '1111' then
         hex := hex || 'F';
       end if;
    end loop;
  end;
--
begin
  if n >= 0 then
    &&ws('calulating bf');
    to_bin(n, bf, e);
    s := 0;
  else
    &&ws('calulating bf');
    to_bin(-n, bf, e);
    s := 1;
  end if;
  if length(bf) > 52 then
    bf := substr(bf, 2, 52);
    e := e - 1;
  end if;

  if bBDE then
    if n >= 0 then
      s := 1;
    end if;
  end if;

  if e >= 1024 then -- Infinity
    bn := s || rpad('1', 11, '1') || rpad('0', 52, '0');
  elsif e <= -1023 then -- Zero
    bn := s || rpad('0', 11, '0') || rpad('0', 52, '0');
  else
    e := e + 1023;
    &&ws('calulating be');
    to_bin(e, be, ee);
    bn := s || lpad(substr(be, 1, ee), 11, '0') || rpad(bf, 52, '0');
  end if;

  if bBDE then
    if n < 0 then
      bn := translate(bn, '10', '01');
      s := 1;
    end if;
  end if;

  &&ws('bf: '||bf);
  &&ws('be: '||be);
  &&ws('bn: '||bn);
  to_hex(bn, xn);
  &&ws('xn: '||xn);
  return xn;
end;
----------------------------------------------------------
procedure fpp(dbh in dbf_file_info_t, i pls_integer, v varchar2, raising in boolean default true,
               conv_string in boolean default true) as
    tmpr raw(255);
    tmps varchar2(255);
    rec str_buf;
    fld    field_rec;
    rind pls_integer;
    v_conv_string boolean:= nvl(conv_string, true);
begin
    check_handle(dbh, raising);
    if not ffiles(dbh).mode_write and not ffiles(dbh).mode_append then
        handle_error(ERR_INVALID_OPERATION, raising);
    end if;

    if ffiles(dbh).rec_appended then
        ffiles(dbh).rec_appended := false;
        ffiles(dbh).rec_dirty_append := true;
    elsif not ffiles(dbh).rec_dirty_append then
        load_buffer(ffiles(dbh), raising);
    end if;

    fld := ffields(ffiles(dbh).field_sind + i - 1);
    if v is null then
        tmpr := utl_raw.copies('20', fld.length);
    elsif not v_conv_string then
        if fld.length=length(v) then
            tmpr := utl_raw.cast_to_raw(v);
        else
            handle_error(ERR_BAD_FIELD_VALUE, raising);
        end if;
    elsif fld.tp = FLD_CHAR then
        tmpr := utl_raw.cast_to_raw(rpad(v, fld.length, ' '));
    elsif fld.tp = FLD_DATE then
        begin
            tmpr := utl_raw.cast_to_raw(rpad(to_char(to_date(v, 'DD/MM/YYYY'), 'YYYYMMDD'), fld.length, ' '));
        exception
            when OTHERS then tmpr := utl_raw.cast_to_raw(rpad(v, fld.length, ' '));
        end;
    elsif fld.tp = FLD_NUMERIC then
        begin
            if fld.scale > 0 then
                tmps := to_char(to_number(v),
                    'FM'||rpad('9', fld.length-fld.scale-2, '9')||'0.'||rpad('0', fld.scale, '0'));
            else
                tmps := to_char(to_number(v), 'FM'||rpad('9', fld.length-1, '9')||'0');
                if length(tmps) > fld.length then
                    tmps := '#';
                end if;
            end if;
        exception
            when OTHERS then tmps := v;
        end;
        if instr(tmps, '#')>0 then
           tmps := rpad(' ', fld.length, ' ');
        else
           tmps := lpad(tmps, fld.length, ' ');
        end if;
        tmpr := utl_raw.cast_to_raw(tmps);
    elsif fld.tp = FLD_DOUBLE then
        tmpr := to_double(v, true);
    elsif fld.tp = FLD_MEMO then
        tmpr := utl_raw.cast_to_raw(lpad(to_char(append_memo(dbh, v, raising)), 10, ' '));
    else
        tmpr := utl_raw.cast_to_raw(rpad(v, fld.length, ' '));
    end if;
    if i < ffiles(dbh).field_count then
        ffiles(dbh).rec := utl_raw.concat(utl_raw.substr(ffiles(dbh).rec, 1, fld.offset),
            tmpr, utl_raw.substr(ffiles(dbh).rec, fld.offset + fld.length + 1));
    else
        ffiles(dbh).rec := utl_raw.concat(utl_raw.substr(ffiles(dbh).rec, 1, fld.offset),
            tmpr);
    end if;
end fpp;
----------------------------------------------------------

----------------------------------------------------------
procedure fp(dbh in dbf_file_info_t, s varchar2, v varchar2, raising in boolean default true,
              conv_string in boolean default true) as
begin
    fpp(dbh, fieldpos(dbh, s, raising), v, raising, conv_string);
end fp;
----------------------------------------------------------

----------------------------------------------------------
function deleted(dbh in dbf_file_info_t, raising in boolean default true) return boolean as
begin
    check_handle(dbh, raising);
    if not ffiles(dbh).rec_appended and not ffiles(dbh).rec_dirty_append then
        load_buffer(ffiles(dbh), raising);
    end if;
    return utl_raw.substr(ffiles(dbh).rec, 1, 1) <> '20';
end deleted;
----------------------------------------------------------

----------------------------------------------------------
procedure append(dbh in dbf_file_info_t, raising in boolean default true) as
begin
    check_handle(dbh, raising);
    if not ffiles(dbh).mode_write and not ffiles(dbh).mode_append then
        handle_error(ERR_INVALID_OPERATION, raising);
    end if;
    flush_buffer(ffiles(dbh), true, raising);
    if ffiles(dbh).rec_count = 0 then
        ffiles(dbh).buf_start_rec_no := 1;
        ffiles(dbh).rec_no :=  0;
    else
        ffiles(dbh).rec_no :=  ffiles(dbh).rec_count - (ffiles(dbh).buf_start_rec_no - 1);
    end if;
    ffiles(dbh).rec_count := ffiles(dbh).rec_count + 1;
    ffiles(dbh).rec_appended := true;
    buffer_clear(dbh, raising);
end append;
----------------------------------------------------------

----------------------------------------------------------
procedure append_record(dbh in dbf_file_info_t, raising in boolean default true) as
begin
    check_handle(dbh, raising);
    if not ffiles(dbh).mode_write and not ffiles(dbh).mode_append then
        handle_error(ERR_INVALID_OPERATION, raising);
    end if;
    flush_buffer(ffiles(dbh), false, raising);
    if ffiles(dbh).rec_count = 0 then
        ffiles(dbh).buf_start_rec_no := 1;
        ffiles(dbh).rec_no :=  0;
    else
        ffiles(dbh).rec_no :=  ffiles(dbh).rec_count - (ffiles(dbh).buf_start_rec_no - 1);
    end if;
    add_(ffiles(dbh), raising);
end append_record;

function append_memo(dbh dbf_file_info_t, v varchar2, raising in boolean default true) return pls_integer is
    block_num    pls_integer := 0;
    block_offset pls_integer := 0;
    r            raw_buf;
begin
    check_memo_handle(dbh, raising);
    if not ffiles(dbh).mode_write and not ffiles(dbh).mode_append then
        handle_error(ERR_INVALID_OPERATION, raising);
    end if;

    block_offset := mod(ffiles_memo(dbh).offset, ffiles_memo(dbh).block_size);
    if block_offset > 0 then
        block_offset := ffiles_memo(dbh).block_size - block_offset;
    end if;

    r := utl_raw.concat(rpad('0', block_offset * 2, '0'), get_memo_buf(dbh, v));

    if stdio.f_write(ffiles_memo(dbh).fio_h, r, utl_raw.length(r)) <> utl_raw.length(r) then
        handle_error(ERR_IO_ERROR, raising);
    end if;

    block_num := ffiles_memo(dbh).next_block;

    if ffiles_memo(dbh).version = dBase7 then
        ffiles_memo(dbh).offset := length(v) + ffiles_memo(dbh).head_size;
    else
        ffiles_memo(dbh).offset := length(v) + 1;
    end if;

    ffiles_memo(dbh).next_block := ffiles_memo(dbh).next_block +
                        trunc(((ffiles_memo(dbh).offset + ffiles_memo(dbh).block_size - 1) / ffiles_memo(dbh).block_size));

    return block_num;
end;
----------------------------------------------------------

----------------------------------------------------------
procedure add_record(dbh in dbf_file_info_t, raising in boolean default true) as
begin
    check_handle(dbh, raising);
    if not ffiles(dbh).mode_write then
        handle_error(ERR_INVALID_OPERATION, raising);
    end if;
    flush_buffer(ffiles(dbh), false, raising);
    if ffiles(dbh).rec_count = 0 then
        ffiles(dbh).buf_start_rec_no := 1;
        ffiles(dbh).rec_no :=  0;
    else
        if bof_(ffiles(dbh)) then
            ffiles(dbh).rec_no := 1 - ffiles(dbh).buf_start_rec_no;
        elsif  eof_(ffiles(dbh))  then
            ffiles(dbh).rec_no :=  ffiles(dbh).rec_count - (ffiles(dbh).buf_start_rec_no - 1);
        end if;
    end if;
    add_(ffiles(dbh), raising);
end add_record;
----------------------------------------------------------

----------------------------------------------------------
procedure put_record(dbh in dbf_file_info_t, n in pls_integer default null, raising in boolean default true) as
begin
    check_handle(dbh, raising);
    if not ffiles(dbh).mode_write and not ffiles(dbh).mode_append then
        handle_error(ERR_INVALID_OPERATION, raising);
    end if;

    flush_buffer(ffiles(dbh), false, raising);

    if ffiles(dbh).rec_count = 0 then
        add_record(dbh, raising);
        return;
    end if;

    if n is not null then
        ffiles(dbh).rec_no := n - ffiles(dbh).buf_start_rec_no;
    end if;

    if bof_(ffiles(dbh)) or eof_(ffiles(dbh)) then
        add_record(dbh, raising);
    else
        put_(ffiles(dbh), raising);
    end if;
end put_record;
----------------------------------------------------------

----------------------------------------------------------
procedure delete_record(dbh in dbf_file_info_t, raising in boolean default true) as
    rind pls_integer;
begin
    check_handle(dbh, raising);
    if not ffiles(dbh).mode_write then
        handle_error(ERR_INVALID_OPERATION, raising);
    end if;
    if ffiles(dbh).rec_appended then
        ffiles(dbh).rec_appended := false;
        ffiles(dbh).rec_dirty_append := true;
    elsif not ffiles(dbh).rec_dirty_append then
        load_buffer(ffiles(dbh), raising);
    end if;
    ffiles(dbh).rec := utl_raw.concat(utl_raw.cast_to_raw('D'), utl_raw.substr(ffiles(dbh).rec, 2));
end delete_record;
----------------------------------------------------------

----------------------------------------------------------
function buffer_get(dbh in dbf_file_info_t, raising in boolean default true) return varchar2 as
begin
    check_handle(dbh, raising);
    if not ffiles(dbh).mode_read then
        handle_error(ERR_INVALID_OPERATION, raising);
    end if;
    if not ffiles(dbh).rec_appended and not ffiles(dbh).rec_dirty_append then
        load_buffer(ffiles(dbh), raising);
    end if;
    return utl_raw.cast_to_varchar2(ffiles(dbh).rec);
end buffer_get;
----------------------------------------------------------

----------------------------------------------------------
procedure buffer_put(dbh in dbf_file_info_t, s varchar2, raising in boolean default true) as
begin
    check_handle(dbh, raising);
    if ffiles(dbh).rec_appended then
        ffiles(dbh).rec_appended := false;
        ffiles(dbh).rec_dirty_append := true;
    end if;
    ffiles(dbh).rec_dirty_read := false;
    ffiles(dbh).rec := utl_raw.cast_to_raw(s);
end buffer_put;
----------------------------------------------------------

----------------------------------------------------------
procedure buffer_clear(dbh in dbf_file_info_t, raising in boolean default true) as
begin
    check_handle(dbh, raising);
    if ffiles(dbh).rec_dirty_append then
        ffiles(dbh).rec_appended := true;
        ffiles(dbh).rec_dirty_append := false;
    end if;
    ffiles(dbh).rec_dirty_read := false;
    ffiles(dbh).rec := utl_raw.copies('20', ffiles(dbh).rec_length);
end buffer_clear;
----------------------------------------------------------

----------------------------------------------------------
procedure dbflush(dbh in dbf_file_info_t, raising in boolean default true) as
begin
    check_handle(dbh, raising);
    if not ffiles(dbh).mode_write and not ffiles(dbh).mode_append then
        handle_error(ERR_INVALID_OPERATION, raising);
    end if;
    flush_buffer(ffiles(dbh), true, raising);
    flush_cache(ffiles(dbh), raising);
end dbflush;
----------------------------------------------------------

----------------------------------------------------------
function recno(dbh in dbf_file_info_t, raising in boolean default true) return pls_integer as
begin
    check_handle(dbh, raising);
    if ffiles(dbh).rec_count = 0 then
        handle_error(ERR_INVALID_OPERATION, raising);
    end if;
    return ffiles(dbh).buf_start_rec_no + ffiles(dbh).rec_no;
end recno;
----------------------------------------------------------

----------------------------------------------------------
procedure go(dbh in dbf_file_info_t, nn pls_integer, raising in boolean default true) as
begin
    check_handle(dbh, raising);
    if not ffiles(dbh).mode_read and not ffiles(dbh).mode_write then
        handle_error(ERR_INVALID_OPERATION, raising);
    end if;
    if nn is null then
        handle_error(ERR_INVALID_OPERATION, raising);
    end if;
    flush_buffer(ffiles(dbh), true, raising);
    if ffiles(dbh).rec_count > 0 then
        ffiles(dbh).rec_no := nn - ffiles(dbh).buf_start_rec_no;
        ffiles(dbh).rec_dirty_read := true;
    end if;
end go;
----------------------------------------------------------

----------------------------------------------------------
procedure skip(dbh in dbf_file_info_t, n in pls_integer, raising in boolean default true) as
begin
    check_handle(dbh, raising);
    if not ffiles(dbh).mode_read and not ffiles(dbh).mode_write then
        handle_error(ERR_INVALID_OPERATION, raising);
    end if;
    if n is null then
        handle_error(ERR_INVALID_OPERATION, raising);
    end if;
    flush_buffer(ffiles(dbh), true, raising);
    if ffiles(dbh).rec_count > 0 then
        ffiles(dbh).rec_no := ffiles(dbh).rec_no + n;
        ffiles(dbh).rec_dirty_read := true;
    end if;
end skip;
----------------------------------------------------------

----------------------------------------------------------
procedure gonext(dbh in dbf_file_info_t, raising in boolean default true) as
begin
    check_handle(dbh, raising);
    if not ffiles(dbh).mode_read and not ffiles(dbh).mode_write then
        handle_error(ERR_INVALID_OPERATION, raising);
    end if;
    flush_buffer(ffiles(dbh), true, raising);
    if ffiles(dbh).rec_count > 0 then
        ffiles(dbh).rec_no := ffiles(dbh).rec_no + 1;
        ffiles(dbh).rec_dirty_read := true;
    end if;
end gonext;
----------------------------------------------------------

----------------------------------------------------------
function eof(dbh in dbf_file_info_t, raising in boolean default true) return boolean as
begin
    check_handle(dbh, raising);
    return eof_(ffiles(dbh));
end eof;
----------------------------------------------------------

----------------------------------------------------------
function bof(dbh in dbf_file_info_t, raising in boolean default true) return boolean as
begin
    check_handle(dbh, raising);
    return bof_(ffiles(dbh));
end bof;
----------------------------------------------------------

----------------------------------------------------------
function fcount(dbh in dbf_file_info_t, raising in boolean default true) return pls_integer as
begin
    check_handle(dbh, raising);
    return ffiles(dbh).field_count;
end fcount;
----------------------------------------------------------

----------------------------------------------------------
function recsize(dbh in dbf_file_info_t, raising in boolean default true) return pls_integer as
begin
    check_handle(dbh, raising);
    return ffiles(dbh).rec_length;
end recsize;
----------------------------------------------------------

----------------------------------------------------------
function header(dbh in dbf_file_info_t, raising in boolean default true) return pls_integer as
begin
    check_handle(dbh, raising);
    return ffiles(dbh).header_length;
end header;
----------------------------------------------------------

----------------------------------------------------------
function lastrec(dbh in dbf_file_info_t, raising in boolean default true) return pls_integer as
begin
    check_handle(dbh, raising);
    return ffiles(dbh).rec_count;
end lastrec;
----------------------------------------------------------

----------------------------------------------------------
procedure close_all(raising in boolean default true) as
    i pls_integer;
begin
    i := ffiles.first;
    while i is not null loop
        dbclose(i, raising);
        i := ffiles.next(i);
    end loop;
end;
----------------------------------------------------------

----------------------------------------------------------
-- Internals
----------------------------------------------------------

----------------------------------------------------------
function eof_(afl in out nocopy file_rec) return boolean as
begin
    return (afl.rec_count = 0) or (afl.buf_start_rec_no + afl.rec_no) > afl.rec_count;
end eof_;
----------------------------------------------------------

----------------------------------------------------------
function bof_(afl in out nocopy file_rec) return boolean as
begin
    return (afl.rec_count = 0) or (afl.buf_start_rec_no + afl.rec_no) < 1;
end bof_;
----------------------------------------------------------

----------------------------------------------------------
function convert_buf(afl in out nocopy file_rec, buf_in in raw_buf,
                        adest_cs in varchar2, asource_cs in varchar2) return raw as
    buf_out raw_buf := utl_raw.substr(buf_in, 1, 1);
begin
    if adest_cs = asource_cs then
        return buf_in;
    end if;

    for i in afl.field_sind..(afl.field_sind + afl.field_count - 1) loop
        if ffields(i).tp = FLD_CHAR then
            buf_out := utl_raw.concat(buf_out,
                utl_raw.cast_to_raw(
                    convert(
                        utl_raw.cast_to_varchar2(
                            utl_raw.substr(buf_in, 1 + ffields(i).offset, ffields(i).length)
                        ),
                        adest_cs, asource_cs
                    )
                )
            );
        else
            buf_out := utl_raw.concat(buf_out, utl_raw.substr(buf_in, 1 + ffields(i).offset, ffields(i).length));
        end if;
    end loop;
    return buf_out;
end convert_buf;
----------------------------------------------------------

----------------------------------------------------------
function r2i(r in raw, b in integer, n in integer) return pls_integer as
begin
    return to_number(rawtohex(utl_raw.reverse(utl_raw.substr(r, b, n))), rpad('X', n * 2, 'X'));
end r2i;
----------------------------------------------------------

----------------------------------------------------------
function i2r(i in integer, n in pls_integer) return raw as
begin
    return utl_raw.reverse(hextoraw(lpad(to_char(i, 'FM' || rpad('X', n * 2, 'X')), n * 2, '0')));
end i2r;
----------------------------------------------------------

----------------------------------------------------------
function r2s(r in raw, b in pls_integer, n in pls_integer) return varchar2 as
begin
    return rtrim(utl_raw.cast_to_varchar2(utl_raw.substr(r, b, n)), chr(0) || ' ');
end r2s;
----------------------------------------------------------

----------------------------------------------------------
function s2r(s in varchar2, n in pls_integer, b in char default ' ') return raw as
begin
    return utl_raw.cast_to_raw(rpad(s, n, b));
end s2r;
----------------------------------------------------------

----------------------------------------------------------
procedure parse_mode(afl in out nocopy file_rec, m in varchar2) as
    mo varchar(4);
    tmp varchar(1);
begin
    afl.mode_read := false;
    afl.mode_append := false;
    afl.mode_write := false;
    if m is null then
        afl.mode_read := true;
        return;
    end if;
    if length(trim(m)) > 4 then
        mo := upper(substr(trim(m), 1, 4));
    else
        mo := upper(trim(m));
    end if;
    if substr(mo, 1, 1) = 'R' then
        afl.mode_read := true;
        if instr(mo, '+') <> 0 or instr(mo, 'W') <> 0 then
            afl.mode_write := true;
        end if;
    elsif substr(mo, 1, 1) = 'W' then
        afl.mode_write := true;
        if instr(mo, '+') <> 0 or instr(mo, 'R') <> 0 then
            afl.mode_read := true;
        end if;
    elsif substr(mo, 1, 1) = 'A' then
        afl.mode_append := true;
        if instr(mo, '+') <> 0 or instr(mo, 'R') <> 0 then
            afl.mode_read := true;
        end if;
    else
        afl.mode_read := true;
    end if;
end parse_mode;
----------------------------------------------------------

----------------------------------------------------------
function is_version_supported(version pls_integer) return boolean is
begin
    return version in (dBASE5, dBASE7, VISUAL_FOXPRO);
end;

procedure parse_version(afl in out nocopy file_rec, b in raw) is
begin
    afl.version := r2i(b, 1, 1);
    parse_version(afl);
end;

procedure parse_version(afl in out nocopy file_rec) is
begin
    /* visual foxpro/dbase IV/... */
    if bitand(afl.version, VER_DBASE4_MEMO_FLAG + VER_DBASE4_SQL_TABLE) > 0 then
        afl.dbf_version := bitand(afl.version, VER_DBASE4_SQL_TABLE);
        afl.memo_flag := bitand(afl.version, VER_DBASE4_MEMO_FLAG) > 0;

    /* dbase 3, 5, 7 */
    else
        afl.dbf_version := bitand(afl.version, VER_NUMBER);
        afl.dbt_flag := bitand(afl.version, VER_DBASE3_DBT_FLAG) > 0;
    end if;
end;
----------------------------------------------------------

----------------------------------------------------------
procedure parse_header(afl in out nocopy file_rec, b in raw) as
begin
    afl.rec_count := r2i(b, 5, 4);
    afl.header_length := r2i(b, 9, 2);
    afl.rec_length := r2i(b, 11, 2);
    afl.field_count := trunc((afl.header_length - 1) / afl.field_length) - 1;
    afl.lang_id := r2i(b, 30, 1);
    if afl.dbf_version = dBASE7 then
       afl.lang_name :=  r2s(b, 33, 32);
    end if;
end parse_header;
----------------------------------------------------------

----------------------------------------------------------
procedure parse_field(afl in file_rec, afld in out nocopy field_rec, b in raw) as
    p pls_integer;
begin
    if afl.dbf_version = dBASE7 then
        afld.name := r2s(b, 1, 32);
        afld.tp := r2s(b, 33, 1);
        afld.length := r2i(b, 34, 1);
        afld.scale := r2i(b, 35, 1);
    else
        afld.name := r2s(b, 1, 11);
        afld.tp := r2s(b, 12, 1);
        afld.length := r2i(b, 17, 1);
        afld.scale := r2i(b, 18, 1);
    end if;

    p := instr(afld.name, chr(0));
    if p > 0 then
        afld.name := substr(afld.name, 1, p - 1);
    end if;
end parse_field;
----------------------------------------------------------

----------------------------------------------------------
procedure make_struct(afl in out nocopy file_rec, aflds in out nocopy field_tbl, astr in varchar2, raising in boolean) as
    p1 pls_integer;
    p2 pls_integer := 0;
    tmp    varchar2(100);
    f pls_integer;
    p pls_integer;
begin
    if astr is null then
        handle_error(ERR_BAD_STRUCT, raising);
    end if;
    aflds.delete;
    afl.rec_length := 1;
    loop
        p1 := p2;
        p2 := instr(astr, ',', p1 + 1);
        if p2 > 0 then
            tmp := trim(substr(astr, p1 + 1, p2 - p1 - 1));
        else
            tmp := trim(substr(astr, p1 + 1));
        end if;
        f := nvl(aflds.last + 1, 1);
        p := instr(tmp, ' ');
        if p = 0 then
            handle_error(ERR_BAD_STRUCT, raising, p1, tmp);
        end if;
        if (afl.dbf_version <> dBASE7 and p - 1 > 11) or (afl.dbf_version = dBASE7 and p - 1 > 32) then
            handle_error(ERR_BAD_STRUCT, raising, p1, tmp);
        end if;
        aflds(f).name := substr(tmp, 1, p - 1);
        tmp := trim(substr(tmp, p));
        aflds(f).tp := substr(tmp, 1, 1);

        /* need dbt memo flag */
        if ((aflds(f).tp = FLD_MEMO) and (not afl.dbt_flag)) then
            if afl.dbf_version != VISUAL_FOXPRO then
                afl.version := afl.version + VER_DBASE3_DBT_FLAG;

                if afl.dbf_version = dBASE7 then
                    afl.version := afl.version + VER_DBASE4_MEMO_FLAG;
                end if;
                afl.dbt_flag := true;
            end if;
        end if;

        p := instr(tmp, '.', 2);
        if p = 0 then
            aflds(f).length := substr(tmp, 2);
            aflds(f).scale := 0;
        else
            aflds(f).length := substr(tmp, 2, p - 2);
            aflds(f).scale := substr(tmp, p + 1);
        end if;
        aflds(f).offset := afl.rec_length;
        afl.rec_length := afl.rec_length + aflds(f).length;
        exit when p2 = 0;
    end loop;
    afl.field_count := aflds.count;
    afl.header_length := (afl.fields_offset - 1) + afl.field_length * (afl.field_count) + 1;
    afl.rec_count := 0;
end make_struct;
----------------------------------------------------------

----------------------------------------------------------
function get_header_buf(afl in file_rec) return raw as
    buf raw(12);
begin
    buf := utl_raw.concat(
        i2r(afl.version, 1),
        i2r(to_number(to_char(sysdate, 'YYYY')) - 1900, 1),
        i2r(to_number(to_char(sysdate, 'MM')), 1),
        i2r(to_number(to_char(sysdate, 'DD')), 1),
        i2r(afl.rec_count, 4),
        i2r(afl.header_length, 2),
        i2r(afl.rec_length, 2));

    if afl.dbf_version = dBASE7 then
        return utl_raw.overlay(
            utl_raw.concat(
                buf,
                rpad('0', 34, '0') || i2r(afl.lang_id, 1), -- Lanuage ID
                '0000' || s2r(afl.lang_name, 32, chr(0)) -- Lanuage name
            ),
            '00', 1, afl.fields_offset - 1, '00');
    else
        return utl_raw.overlay(
            utl_raw.concat(
                buf,
                rpad('0', 34, '0') || i2r(afl.lang_id, 1) -- Lanuage ID
            ),
            '00', 1, afl.fields_offset - 1, '00');
    end if;
end get_header_buf;

function get_header_memo_buf(afl in file_memo_rec) return raw as
    buf raw(32);
begin
    buf := i2r(afl.next_block, 4);

    if afl.version = dBase7 then
        buf := utl_raw.concat(buf, rpad('0', 28, '0'), i2r(afl.head_pref, 2), i2r(afl.block_size, 2));
    end if;

    return utl_raw.overlay(
        buf,
        '00', 1, afl.block_size, '00');
end get_header_memo_buf;
----------------------------------------------------------

----------------------------------------------------------
function get_field_buf(afl in file_rec, afld in field_rec) return raw as
begin
    if afl.dbf_version = dBASE7 then
        return utl_raw.overlay(
            utl_raw.concat(
                s2r(afld.name, 32, chr(0)),
                s2r(afld.tp, 1),
                i2r(afld.length, 1),
                i2r(afld.scale, 1)),
            '00', 1, afl.field_length, '00');
    else
        return utl_raw.overlay(
            utl_raw.concat(
                s2r(afld.name, 11, chr(0)),
                s2r(afld.tp, 1),
                i2r(afld.offset, 4),
                i2r(afld.length, 1),
                i2r(afld.scale, 1)),
            '00', 1, afl.field_length, '00');
    end if;
end get_field_buf;

function get_memo_buf(dbh dbf_file_info_t, v varchar2) return raw is
begin
    if ffiles_memo(dbh).version = dBase7 then
        return utl_raw.concat(
                'FFFF0800',
                i2r(length(v) + ffiles_memo(dbh).head_size, 4),
                s2r(
                    convert(v, fcss(ffiles(dbh).file_encoding), fcss(ffiles(dbh).db_encoding)),
                    length(v),
                    chr(0)
                ));
    else
        return utl_raw.concat(
                s2r(
                    convert(v, fcss(ffiles(dbh).file_encoding), fcss(ffiles(dbh).db_encoding)),
                    length(v),
                    chr(0)
                ),
                i2r(ffiles_memo(dbh).block_sep, 1)
            );
    end if;
end get_memo_buf;
----------------------------------------------------------

----------------------------------------------------------
procedure write_struct(afl in file_rec, aflds in field_tbl, af in pls_integer, raising in boolean) as
    r raw_buf;
begin
    r := get_header_buf(afl);
    for i in 1..aflds.count loop
        r := utl_raw.concat(r, get_field_buf(afl, aflds(i)));
        if i = aflds.count then
            r := utl_raw.concat(r, '0D');
        end if;
        if utl_raw.length(r) + afl.field_length > BUF_SIZE or i = aflds.count then
            if stdio.f_write(af, r, utl_raw.length(r)) <> utl_raw.length(r) then
                handle_error(ERR_IO_ERROR, raising);
            end if;
            r := null;
        end if;
    end loop;
end write_struct;

procedure write_struct_memo(afl in out nocopy file_memo_rec, af in pls_integer, raising in boolean) is
    r raw_buf;
begin
    r := get_header_memo_buf(afl);

    if stdio.f_write(af, r, utl_raw.length(r)) <> utl_raw.length(r) then
        handle_error(ERR_IO_ERROR, raising);
    end if;
end write_struct_memo;
----------------------------------------------------------

----------------------------------------------------------
function get_next_recsind return pls_integer as
    fl file_rec;
    sind pls_integer;
begin
    sind := ffiles.last;
    if sind is not null then
        fl := ffiles(sind);
        sind := fl.rec_sind + fl.buf_size + fl.buf_ext_size;
    end if;
    return nvl(sind, 1);
end get_next_recsind;
----------------------------------------------------------

----------------------------------------------------------
procedure flush_buffer(afl in out nocopy file_rec, do_append in boolean, raising in boolean) as
begin
    if afl.rec_dirty_append then
        afl.rec_dirty_append := false;
        afl.rec_count := afl.rec_count - 1;
        if do_append then
            add_(afl, raising);
        end if;
    elsif afl.rec_appended then
        afl.rec_appended := false;
        afl.rec_count := afl.rec_count - 1;
        if afl.rec_count = 0 then
            afl.buf_start_rec_no := null;
            afl.rec_no :=  null;
        end if;
    end if;
end flush_buffer;
----------------------------------------------------------

----------------------------------------------------------
procedure flush_cache(afl in out nocopy file_rec, raising in boolean) as
begin
    if not afl.buf_modified then
        return;
    end if;

    if afl.recs_in_buf < afl.recs_in_buf_orig then
        declare
            buf raw_buf;
            block_size pls_integer := BUF_SIZE;
            diff pls_integer := (afl.recs_in_buf_orig - afl.recs_in_buf) * afl.rec_length;
            fl_end pls_integer;
            fl_start pls_integer;
            fl_cur pls_integer;
        begin
            fl_end := stdio.f_seek(afl.fio_h, 0, 2);
            if fl_end < 0 then
                handle_error(ERR_IO_ERROR, raising);
            end if;
            fl_start := afl.header_length + (afl.buf_start_rec_no + afl.recs_in_buf_orig - 1) * afl.rec_length;
            fl_cur := fl_start;
            while fl_cur + block_size < fl_end loop
                if stdio.f_seek(afl.fio_h, fl_cur, 0) < 0 then
                    handle_error(ERR_IO_ERROR, raising);
                end if;
                if stdio.f_read(afl.fio_h, buf, block_size) <> block_size then
                    handle_error(ERR_IO_ERROR, raising);
                end if;
                if stdio.f_seek(afl.fio_h, fl_cur - diff, 0) < 0 then
                    handle_error(ERR_IO_ERROR, raising);
                end if;
                if stdio.f_write(afl.fio_h, buf, block_size) <> block_size then
                    handle_error(ERR_IO_ERROR, raising);
                end if;
                fl_cur := fl_cur + block_size;
            end loop;
            block_size := fl_end - fl_cur;
            if stdio.f_seek(afl.fio_h, fl_cur, 0) < 0 then
                handle_error(ERR_IO_ERROR, raising);
            end if;
            if stdio.f_read(afl.fio_h, buf, block_size) <> block_size then
                handle_error(ERR_IO_ERROR, raising);
            end if;
            if stdio.f_seek(afl.fio_h, fl_cur - diff, 0) < 0 then
                handle_error(ERR_IO_ERROR, raising);
            end if;
            if stdio.f_write(afl.fio_h, buf, block_size) <> block_size then
                handle_error(ERR_IO_ERROR, raising);
            end if;
        end;
    elsif afl.recs_in_buf > afl.recs_in_buf_orig then
        declare
            buf raw_buf;
            block_size pls_integer := BUF_SIZE;
            diff pls_integer := (afl.recs_in_buf - afl.recs_in_buf_orig) * afl.rec_length;
            tmp pls_integer;
            fl_end pls_integer;
            fl_start pls_integer;
            fl_cur pls_integer;
        begin
            fl_end := stdio.f_seek(afl.fio_h, 0, 2);
            if fl_end < 0 then
                handle_error(ERR_IO_ERROR, raising);
            end if;
            fl_start := afl.header_length + (afl.buf_start_rec_no + afl.recs_in_buf_orig - 1) * afl.rec_length;
            if fl_start <> fl_end then
                tmp := diff;
                while tmp >= block_size loop
                    if stdio.f_write(afl.fio_h, buf, block_size) < 0 then
                        handle_error(ERR_IO_ERROR, raising);
                    end if;
                    tmp := tmp - block_size;
                end loop;
                if stdio.f_write(afl.fio_h, buf, tmp) < 0 then
                    handle_error(ERR_IO_ERROR, raising);
                end if;

                fl_cur := fl_end - block_size;
                while fl_cur > fl_start loop
                    if stdio.f_seek(afl.fio_h, fl_cur, 0) < 0 then
                        handle_error(ERR_IO_ERROR, raising);
                    end if;
                    if stdio.f_read(afl.fio_h, buf, block_size) <> block_size then
                        handle_error(ERR_IO_ERROR, raising);
                    end if;
                    if stdio.f_seek(afl.fio_h, fl_cur + diff, 0) < 0 then
                        handle_error(ERR_IO_ERROR, raising);
                    end if;
                    if stdio.f_write(afl.fio_h, buf, block_size) <> block_size then
                        handle_error(ERR_IO_ERROR, raising);
                    end if;
                    fl_cur := fl_cur - block_size;
                end loop;
                block_size := (fl_cur + block_size) - fl_start;
                if stdio.f_seek(afl.fio_h, fl_start, 0) < 0 then
                    handle_error(ERR_IO_ERROR, raising);
                end if;
                if stdio.f_read(afl.fio_h, buf, block_size) <> block_size then
                    handle_error(ERR_IO_ERROR, raising);
                end if;
                if stdio.f_seek(afl.fio_h, fl_start + diff, 0) < 0 then
                    handle_error(ERR_IO_ERROR, raising);
                end if;
                if stdio.f_write(afl.fio_h, buf, block_size) <> block_size then
                    handle_error(ERR_IO_ERROR, raising);
                end if;
            end if;
        end;
    end if;
    declare
        r raw_buf;
        fl_start pls_integer;
        fl_cur pls_integer;
        mid pls_integer;
    begin
        if stdio.f_seek(afl.fio_h, afl.header_length + (afl.buf_start_rec_no - 1) * afl.rec_length, 0) < 0 then
            handle_error(ERR_IO_ERROR, raising);
        end if;
        if afl.recs_in_buf < afl.buf_size then
            mid := afl.recs_in_buf;
        else
            mid := afl.buf_size;
        end if;
        for i in 0..(mid - 1) loop
            r := utl_raw.concat(r, convert_buf(afl, frecs(afl.rec_sind + i),
                fcss(afl.file_encoding), fcss(afl.db_encoding)));
        end loop;
        if stdio.f_write(afl.fio_h, r, afl.rec_length * mid) < 0 then
            handle_error(ERR_IO_ERROR, raising);
        end if;
        r := null;
        for i in mid..(afl.recs_in_buf - 1) loop
            r := utl_raw.concat(r, convert_buf(afl, frecs(afl.rec_sind + i),
                fcss(afl.file_encoding), fcss(afl.db_encoding)));
        end loop;
        if stdio.f_write(afl.fio_h, r, afl.rec_length * (afl.recs_in_buf - mid)) < 0 then
            handle_error(ERR_IO_ERROR, raising);
        end if;
    end;
    afl.recs_in_buf_orig := afl.recs_in_buf;
    afl.buf_modified := false;
end flush_cache;
----------------------------------------------------------

----------------------------------------------------------
procedure fill_buffer(afl in out file_rec, abuf in raw, abuf_pos in pls_integer, arec_no in pls_integer) as
    buf_pos pls_integer := abuf_pos;
    buf_length pls_integer := utl_raw.length(abuf);
    rec_ind pls_integer;
    max_rec_ind pls_integer;
begin
    if not afl.buf_full_file then
        rec_ind := 0;
        max_rec_ind := afl.rec_count - arec_no + 1;
        if max_rec_ind > afl.buf_size then
          max_rec_ind := afl.buf_size;
        end if;
        loop
            exit when buf_pos + afl.rec_length - 1 > buf_length or rec_ind >= max_rec_ind;
            frecs(afl.rec_sind + rec_ind) := convert_buf(afl,
                utl_raw.substr(abuf, buf_pos, afl.rec_length), fcss(afl.db_encoding), fcss(afl.file_encoding));
            buf_pos := buf_pos + afl.rec_length;
            rec_ind := rec_ind + 1;
        end loop;
        afl.recs_in_buf_orig := rec_ind;
        afl.recs_in_buf := rec_ind;
        if afl.buf_start_rec_no is null then
            afl.buf_start_rec_no := arec_no;
            afl.rec_no := 0;
        else
            afl.rec_no := afl.buf_start_rec_no + afl.rec_no - arec_no;
            afl.buf_start_rec_no := arec_no;
        end if;
    else
        buf_pos := abuf_pos;
        rec_ind := arec_no - 1;
        loop
            exit when buf_pos + afl.rec_length - 1 > buf_length or rec_ind >= afl.rec_count;
            frecs(afl.rec_sind + rec_ind) := convert_buf(afl,
                utl_raw.substr(abuf, buf_pos, afl.rec_length), fcss(afl.db_encoding), fcss(afl.file_encoding));
            buf_pos := buf_pos + afl.rec_length;
            rec_ind := rec_ind + 1;
        end loop;
        if afl.buf_start_rec_no is null then
            afl.recs_in_buf_orig := rec_ind;
            afl.recs_in_buf := rec_ind;
            afl.buf_start_rec_no := arec_no;
            afl.rec_no := 0;
        else
            afl.recs_in_buf := afl.recs_in_buf + rec_ind - arec_no + 1;
        end if;
    end if;
end fill_buffer;
----------------------------------------------------------

----------------------------------------------------------
procedure load_buffer(afl in out nocopy file_rec, raising in boolean) as
    nbl pls_integer;
    sbl pls_integer;
    pbl pls_integer;
    b raw_buf;
begin
    if bof_(afl) or eof_(afl) then
        return;
    end if;

    if not afl.buf_full_file then
        if afl.rec_no < 0  or afl.recs_in_buf <= afl.rec_no then
            flush_cache(afl, raising);

            --get block start rec
    /*        if afl.rec_no >= 0 then
                sbl :=  afl.buf_start_rec_no + afl.rec_no;
            else
                sbl :=  afl.buf_start_rec_no + afl.rec_no - (afl.buf_size - 1);
                if sbl < 1 then
                    sbl := 1;
                end if;
            end if;*/
            sbl :=  afl.buf_start_rec_no + afl.rec_no - trunc((afl.buf_size - 1) / 2);
            if sbl < 1 then
                sbl := 1;
            end if;

            --get block start file pos
            pbl := afl.header_length + (sbl - 1) * afl.rec_length;

            --seek
            if stdio.f_seek(afl.fio_h, pbl, 0) < 0 then
                handle_error(ERR_IO_ERROR, raising);
            end if;

            --read
            if stdio.f_read(afl.fio_h, b, afl.buf_size * afl.rec_length) < 0 then
                handle_error(ERR_IO_ERROR, raising);
            end if;

            fill_buffer(afl, b, 1, sbl);
        end if;
    elsif not frecs.exists(afl.rec_sind + afl.rec_no) then
        --get block index
        nbl := trunc((afl.rec_no + 1 - afl.recs_in_buf_orig) / afl.rec_per_block) + 1;
        --get block start rec
        sbl := (nbl - 1) * afl.rec_per_block + afl.recs_in_buf_orig;
        --get block start file pos
        pbl := afl.header_length + (sbl - 1) * afl.rec_length;

        --seek
        if stdio.f_seek(afl.fio_h, pbl, 0) < 0 then
            handle_error(ERR_IO_ERROR, raising);
        end if;

        --read
        if stdio.f_read(afl.fio_h, b, afl.rec_per_block * afl.rec_length) < 0 then
            handle_error(ERR_IO_ERROR, raising);
        end if;

        fill_buffer(afl, b, 1, sbl);
    end if;

    if afl.rec_dirty_read then
        afl.rec := frecs(afl.rec_sind + afl.rec_no);
        afl.rec_dirty_read := false;
    end if;

end load_buffer;
----------------------------------------------------------

----------------------------------------------------------
procedure add_(afl in out nocopy file_rec, raising in boolean) as
begin
    if afl.rec_no < 0 or afl.recs_in_buf < afl.rec_no then
        flush_cache(afl, raising);
        frecs.delete(afl.rec_sind, afl.rec_sind + afl.recs_in_buf - 1);
        frecs(afl.rec_sind) := afl.rec;
        afl.rec_count := afl.rec_count + 1;
        afl.recs_in_buf := 1;
        afl.recs_in_buf_orig := 0;
        afl.buf_start_rec_no := afl.buf_start_rec_no + afl.rec_no;
        afl.rec_no := 0;
    else
        if afl.recs_in_buf = afl.buf_size + afl.buf_ext_size then
            flush_cache(afl, raising);
            afl.recs_in_buf := afl.buf_size;
            afl.recs_in_buf_orig := afl.buf_size - 1;
            if afl.rec_no < afl.buf_size then
                frecs.delete(afl.rec_sind + afl.buf_size - 1, afl.rec_sind + afl.buf_size + afl.buf_ext_size - 1);
                for i in reverse (afl.rec_sind + afl.rec_no)..(afl.rec_sind + afl.buf_size - 2) loop
                    frecs(i + 1) := frecs(i);
                end loop;
                frecs(afl.rec_sind + afl.rec_no) := afl.rec;
                afl.rec_count := afl.rec_count + 1;
            else
                frecs.delete(afl.rec_sind, afl.rec_sind + afl.buf_ext_size);
                for i in (afl.rec_sind + afl.buf_ext_size + 1)..(afl.rec_sind + afl.buf_size + afl.buf_ext_size - 1) loop
                    frecs(i - afl.buf_ext_size - 1) := frecs(i);
                    frecs.delete(i);
                end loop;
                afl.buf_start_rec_no := afl.buf_start_rec_no + afl.buf_ext_size + 1;
                afl.rec_no := afl.rec_no - afl.buf_ext_size - 1;

                for i in reverse (afl.rec_sind + afl.rec_no)..(afl.rec_sind + afl.recs_in_buf_orig - 1) loop
                    frecs(i + 1) := frecs(i);
                end loop;
                frecs(afl.rec_sind + afl.rec_no) := afl.rec;
                afl.rec_count := afl.rec_count + 1;
            end if;
        else
            for i in reverse (afl.rec_sind + afl.rec_no)..(afl.rec_sind + afl.recs_in_buf - 1) loop
                frecs(i + 1) := frecs(i);
            end loop;
            frecs(afl.rec_sind + afl.rec_no) := afl.rec;
            afl.rec_count := afl.rec_count + 1;
            afl.recs_in_buf := afl.recs_in_buf + 1;
        end if;
    end if;
    afl.buf_modified := true;
    afl.rec_dirty_read := false;
end add_;
----------------------------------------------------------

----------------------------------------------------------
procedure put_(afl in out nocopy file_rec, raising in boolean) as
begin
    if afl.rec_no < 0 or afl.recs_in_buf <= afl.rec_no then
        flush_cache(afl, raising);
        frecs.delete(afl.rec_sind, afl.rec_sind + afl.recs_in_buf - 1);
        afl.recs_in_buf := 1;
        afl.recs_in_buf_orig := 1;
        afl.buf_start_rec_no := afl.buf_start_rec_no + afl.rec_no;
        afl.rec_no := 0;
    end if;
    frecs(afl.rec_sind + afl.rec_no) := afl.rec;
    afl.buf_modified := true;
    afl.rec_dirty_read := false;
end put_;
----------------------------------------------------------

----------------------------------------------------------
-- Errors Handling
----------------------------------------------------------

----------------------------------------------------------
procedure handle_error(
    errno in pls_integer,
    raising in boolean,
    p1 varchar2 default NULL,
    p2 varchar2 default NULL,
    p3 varchar2 default NULL,
    p4 varchar2 default NULL,
    p5 varchar2 default NULL,
    p6 varchar2 default NULL,
    p7 varchar2 default NULL,
    p8 varchar2 default NULL,
    p9 varchar2 default NULL) as
begin
    if not raising then
        report_error(errno, p1, p2, p3, p4, p5, p6, p7, p8, p9);
    else
        raise_error(errno);
    end if;
end handle_error;
----------------------------------------------------------

----------------------------------------------------------
procedure report_error(
    errno in pls_integer,
    p1 varchar2 default NULL,
    p2 varchar2 default NULL,
    p3 varchar2 default NULL,
    p4 varchar2 default NULL,
    p5 varchar2 default NULL,
    p6 varchar2 default NULL,
    p7 varchar2 default NULL,
    p8 varchar2 default NULL,
    p9 varchar2 default NULL) as
begin
    if errno = ERR_INVALID_PATH then
        message.error(constant.EXEC_ERROR, 'FILEPATH', p1, p2, p3, p4, p5, p6, p7, p8, p9);

    elsif errno = ERR_INVALID_OPERATION then
        message.error(constant.EXEC_ERROR, 'DBF_INVALID_OPERATION', p1, p2, p3, p4, p5, p6, p7, p8, p9);

    elsif errno = ERR_IO_ERROR then
        message.error(constant.EXEC_ERROR, 'DBF_IO_ERROR', p1, p2, p3, p4, p5, p6, p7, p8, p9);

    elsif errno = ERR_BAD_FORMAT then
        message.error(constant.EXEC_ERROR, 'DBF_BAD_FORMAT', p1, p2, p3, p4, p5, p6, p7, p8, p9);

    elsif errno = ERR_BAD_STRUCT then
        message.error(constant.EXEC_ERROR, 'DBF_BAD_STRUCT', p1, p2, p3, p4, p5, p6, p7, p8, p9);

    elsif errno = ERR_TOO_MANY_FIELDS then
        message.error(constant.EXEC_ERROR, 'DBF_TOO_MANY_FIELDS', p1, p2, p3, p4, p5, p6, p7, p8, p9);

    elsif errno = ERR_NO_SUCH_FIELD then
        message.error(constant.EXEC_ERROR, 'DBF_NO_SUCH_FIELD', p1, p2, p3, p4, p5, p6, p7, p8, p9);

    elsif errno = ERR_BAD_FIELD_VALUE then
        message.error(constant.EXEC_ERROR, 'DBF_BAD_FIELD_VALUE', p1, p2, p3, p4, p5, p6, p7, p8, p9);

    elsif errno = ERR_INVALID_HANDLE then
        message.error(constant.EXEC_ERROR, 'DBF_INVALID_HANDLE', p1, p2, p3, p4, p5, p6, p7, p8, p9);

    elsif errno = ERR_INVALID_MEMO_HANDLE then
        message.error(constant.EXEC_ERROR, 'ERR_INVALID_MEMO_HANDLE', p1, p2, p3, p4, p5, p6, p7, p8, p9);
    end if;
end report_error;
----------------------------------------------------------

----------------------------------------------------------
procedure raise_error(errno in pls_integer) as
begin
    if errno = ERR_INVALID_PATH then
        raise INVALID_PATH;

    elsif errno = ERR_INVALID_OPERATION then
        raise INVALID_OPERATION;

    elsif errno = ERR_IO_ERROR then
        raise IO_ERROR;

    elsif errno = ERR_BAD_FORMAT then
        raise BAD_FORMAT;

    elsif errno = ERR_BAD_STRUCT then
        raise BAD_STRUCT;

    elsif errno = ERR_TOO_MANY_FIELDS then
        raise TOO_MANY_FIELDS;

    elsif errno = ERR_NO_SUCH_FIELD then
        raise NO_SUCH_FIELD;

    elsif errno = ERR_BAD_FIELD_VALUE then
        raise BAD_FIELD_VALUE;

    elsif errno = ERR_INVALID_HANDLE then
        raise INVALID_HANDLE;

    elsif errno = ERR_INVALID_MEMO_HANDLE then
        raise INVALID_MEMO_HANDLE;

    end if;
end raise_error;
----------------------------------------------------------

----------------------------------------------------------
procedure check_handle(dbh in pls_integer, raising in boolean) as
begin
    if not ffiles.exists(dbh) then
        handle_error(ERR_INVALID_HANDLE, raising, dbh);
    end if;
end check_handle;

procedure check_memo_handle(dbh in pls_integer, raising in boolean) as
begin
    if not ffiles_memo.exists(dbh) then
        handle_error(ERR_INVALID_MEMO_HANDLE, raising, dbh);
    end if;
end check_memo_handle;
----------------------------------------------------------

begin
    set_def_text;
    fcss(stdio.DOSTEXT) := 'RU8PC866';
    fcss(stdio.UNXTEXT) := 'CL8ISO8859P5';
    fcss(stdio.WINTEXT) := 'CL8MSWIN1251';
    fcss(stdio.KOITEXT) := 'CL8KOI8R';
end;
/
show err package body dbf

