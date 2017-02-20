prompt constant
create or replace
package constant is
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/CONSTNT1.SQL $
 *  $Author: Alexey $
 *  $Revision: 15072 $
 *  $Date:: 2012-03-06 13:41:17 #$
 */
--
	PRAGMA RESTRICT_REFERENCES ( constant, WNDS, WNPS, RNDS, RNPS );
-- TYPE declarations
    TYPE REPORT_CURSOR IS REF CURSOR;
--
 subtype STRING_TABLE     is dbms_sql.varchar2a;
    --type STRING_TABLE     is table of varchar2(32767)index by binary_integer;
    type STRING_TBL       is table of varchar2(8000) index by binary_integer;
    type MEMO_TABLE       is table of varchar2(4000) index by binary_integer;
    type REFSTRING_TABLE  is table of varchar2(128)  index by binary_integer;
    type BOOLSTRING_TABLE is table of varchar2(1)    index by binary_integer;
    type BOOLEAN_TABLE    is table of boolean        index by binary_integer;
    type INTEGER_TABLE    is table of pls_integer    index by binary_integer;
    type RAW_TABLE        is table of raw(32767)     index by binary_integer;
    type DEFRAW_TABLE     is table of raw(255)       index by binary_integer;
    type ROWID_TABLE      is table of rowid index by binary_integer;
 subtype DEFSTRING_TABLE  is dbms_sql.varchar2s;
 subtype VARCHAR2S        is dbms_sql.varchar2s;
 subtype VARCHAR2_TABLE   is dbms_sql.varchar2_table;
 subtype DATE_TABLE       is dbms_sql.date_table;
 subtype NUMBER_TABLE     is dbms_sql.number_table;
 subtype REFERENCE_TABLE  is dbms_sql.number_table;
 subtype BLOB_TABLE       is dbms_sql.blob_table;
 subtype CLOB_TABLE       is dbms_sql.clob_table;
 subtype BFILE_TABLE      is dbms_sql.bfile_table;
 subtype UROWID_TABLE     is dbms_sql.urowid_table;
 subtype TIMESTAMP_TABLE  is dbms_sql.timestamp_table;
 subtype INTERVAL_TABLE   is dbms_sql.interval_day_to_second_table;
 subtype TIMESTAMP_TZ_TABLE  is dbms_sql.timestamp_with_time_zone_table;
 subtype TIMESTAMP_LTZ_TABLE is dbms_sql.timestamp_with_ltz_table;
 subtype INTERVAL_YM_TABLE   is dbms_sql.interval_year_to_month_table;
 subtype LONG_TABLE       is STRING_TABLE;
 subtype LONG#RAW_TABLE   is RAW_TABLE;
--
    type STRING_TABLE_S     is table of varchar2(32767)index by varchar2(128);
    type STRING_TBL_S       is table of varchar2(8000) index by varchar2(128);
    type MEMO_TABLE_S       is table of varchar2(4000) index by varchar2(128);
    type VARCHAR2_TABLE_S   is table of varchar2(2000) index by varchar2(128);
    type DEFSTRING_TABLE_S  is table of varchar2(256)  index by varchar2(128);
    type REFSTRING_TABLE_S  is table of varchar2(128)  index by varchar2(128);
    type BOOLSTRING_TABLE_S is table of varchar2(1)    index by varchar2(128);
    type NUMBER_TABLE_S     is table of number         index by varchar2(128);
    type DATE_TABLE_S       is table of date           index by varchar2(128);
    type BOOLEAN_TABLE_S    is table of boolean        index by varchar2(128);
    type INTEGER_TABLE_S    is table of pls_integer    index by varchar2(128);
    type INDEX_TABLE_S      is table of pls_integer    index by varchar2(512);
--
	type archive_rec_t is record (
        id        varchar2(128),
        qual      varchar2(700),
        time      timestamp,
        username  varchar2(30),
        base_id   varchar2(16),
        value     varchar2(4000)
	);
	type archive_rec_tbl_t is table of archive_rec_t index by binary_integer;
--  Char constants
--
    TB  constant varchar2(1) := chr(9);
    LF  constant varchar2(1) := chr(10);
    CR  constant varchar2(1) := chr(13);
    ESC constant varchar2(1) := chr(27);
    NL  constant varchar2(2) := chr(13)||chr(10);
    NS  constant varchar2(2) := chr(1)||chr(255);
    NC  constant varchar2(2) := chr(1)||chr(127);
-- BOOLEAN values, how they are stored in DB
    NO  constant varchar2(1) := '0';
    YES constant varchar2(1) := '1';
-- Type Size constants
    REF_PREC  constant pls_integer  := 128;
    STR_PREC  constant pls_integer  := 128;
    RAW_PREC  constant pls_integer  := 255;
    MEMO_PREC constant pls_integer  := 2000;
    BOOL_PREC constant pls_integer  := 1;
-- methods.flags
    METHOD_STATIC    constant varchar2(1) := 'S';  /* method is static */
    METHOD_USUAL     constant varchar2(1) := 'M';  /* usual method */
    METHOD_NEW       constant varchar2(1) := 'C';  /* method is constructor */
    METHOD_DELETE    constant varchar2(1) := 'Y';  /* method is destructor */
    METHOD_CRITERION constant varchar2(1) := 'Z';  /* method is criterion */
    METHOD_REPORT    constant varchar2(1) := 'R';  /* method is report */
    METHOD_DUBLICATE constant varchar2(1) := 'D';  /* method is dublicate */
    METHOD_PRINT     constant varchar2(1) := 'P';  /* method is print */
    METHOD_OPERATION constant varchar2(1) := 'O';  /* method is select operation */
    METHOD_LIBRARY   constant varchar2(1) := 'L';  /* method is LIBRARY */
    METHOD_GROUP     constant varchar2(1) := 'G';  /* method is group(table) operaion*/
    METHOD_TRIGGER   constant varchar2(1) := 'T';  /* method is trigger*/
-- special attributes
    METHOD_ATTRIBUTE constant varchar2(1) := 'A';  /* method is attribute/property*/
    PRIMARY_ATTR     constant varchar2(1) := 'P';  /* primary key attribute*/
-- method_parameters.direction
    PARAM_IN         constant varchar2(1) := 'I';
    PARAM_OUT        constant varchar2(1) := 'O';
    PARAM_IN_OUT     constant varchar2(1) := 'B';
    PARAM_DEFAULT    constant varchar2(1) := 'D';
-- rtl_entries.type
    RTL_PROCEDURE    constant varchar2(1) := 'P';
    RTL_FUNCTION     constant varchar2(1) := 'F';
    RTL_CONSTANT     constant varchar2(1) := 'C';
    RTL_VARIABLE     constant varchar2(1) := 'V';
    RTL_TYPE         constant varchar2(1) := 'T';
    RTL_MACRO        constant varchar2(1) := 'M';
    RTL_GLOBALMACRO  constant varchar2(1) := 'G';
-- rtl_parameters.flag
    RTL_GENERIC      constant varchar2(1) := 'G';
    RTL_REFERENCE    constant varchar2(1) := 'R';
    RTL_DBOBJECT     constant varchar2(1) := 'D';
    RTL_COLLECTION   constant varchar2(1) := 'C';
    RTL_TABLE        constant varchar2(1) := 'T';
    RTL_DBROW        constant varchar2(1) := 'A';
    RTL_DBTABLE      constant varchar2(1) := 'B';
    RTL_OBJECT       constant varchar2(1) := 'O';
-- classes.base_class_id
	GENERIC_STRING  constant varchar2(20) := 'STRING';
	GENERIC_NUMBER  constant varchar2(20) := 'NUMBER';
	GENERIC_INTEGER constant varchar2(20) := 'INTEGER';
	GENERIC_DATE    constant varchar2(20) := 'DATE';
	GENERIC_TIMESTAMP	constant varchar2(20) := 'TIMESTAMP';--maximov
	GENERIC_INTERVAL	constant varchar2(20) := 'INTERVAL';--maximov
	GENERIC_BOOLEAN constant varchar2(20) := 'BOOLEAN';
    GENERIC_NULL    constant varchar2(20) := 'NULL';
    GENERIC_TABLE   constant varchar2(20) := 'TABLE';
    GENERIC_EXCEPTION constant varchar2(20):='EXCEPTION';
--  reserved classes
	STRUCTURE  constant varchar2(20) := 'STRUCTURE';
	COLLECTION constant varchar2(20) := 'COLLECTION';
	REFERENCE  constant varchar2(20) := 'REFERENCE';
    OBJECT     constant varchar2(20) := 'OBJECT';
    MEMO       constant varchar2(20) := 'MEMO';
    OLE        constant varchar2(20) := 'OLE';
    SELF       constant varchar2(20) := 'SELF';
    RUNTIME    constant varchar2(20) := 'RUNTIME';
    SYSTEM     constant varchar2(20) := 'SYSTEM';
    METACLASS  constant varchar2(20) := 'METACLASS';
	BOOLSTRING constant varchar2(20) := 'BOOLSTRING';
	REFSTRING  constant varchar2(20) := 'REFSTRING';
--
    DATE_FORMAT  constant varchar2(21) := 'YYYY-MM-DD HH24:MI:SS';
    SHORT_FORMAT constant varchar2(12) := 'YYYYDDDSSSSS';
	TIMESTAMP_FORMAT constant varchar2(25) := 'YYYY-MM-DD HH24:MI:SS.FF9';--maximov
--
	FUNC_RESULT_TAG constant varchar2(30) := '''0R''';
    STATUS_TAG      constant varchar2(30) := '0S';
-- messages.topic
    TIPS_TOPIC  constant varchar2(16) := 'TIP';
    EXEC_ERROR  constant varchar2(16) := 'EXEC';
    PLP_ERROR   constant varchar2(16) := 'PLP';
    ADMIN_ERROR constant varchar2(16) := 'ADMIN';
    APP_ERROR   constant varchar2(16) := 'APP';
    LOCK_ERROR  constant varchar2(16) := 'LOCK';
    CLASS_ERROR constant varchar2(16) := 'CLS';
    METH_ERROR  constant varchar2(16) := 'MTD';
    WWW_ERROR   constant varchar2(16) := 'WWW';
    KERNEL_ERROR constant varchar2(16):= 'KRNL';
    UADMIN_ERROR constant varchar2(16):= 'UADMIN';
-- dependencies.referencing_type/dependencies.referenced_type
    CLASS_REF_TYPE  constant varchar2(1) := 'C';
    ATTR_REF_TYPE   constant varchar2(1) := 'A';
    METHOD_REF_TYPE constant varchar2(1) := 'M';
    OBJECT_REF_TYPE constant varchar2(1) := 'O';    -- hardcoded object reference
    VIEW_REF_TYPE   constant varchar2(1) := 'V';
-- errors.class
    ERROR_CLASS   constant varchar2(1) := 'E';
    WARNING_CLASS constant varchar2(1) := 'W';
-- maximum date
	DATE_MAX constant date := to_date('31/12/4012','DD/MM/YYYY');
--
end constant;
/
sho err

