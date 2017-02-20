prompt creating synonyms for sys views

set echo on
create or replace synonym DBA_OBJECTS         for SYS.DBA_OBJECTS;
create or replace synonym DBA_DATA_FILES      for SYS.DBA_DATA_FILES;
create or replace synonym DBA_LOCK_INTERNAL   for SYS.DBA_LOCK_INTERNAL;
create or replace synonym DBA_TABLES          for SYS.DBA_TABLES;
create or replace synonym DBA_INDEXES         for SYS.DBA_INDEXES;
create or replace synonym DBA_TRIGGERS        for SYS.DBA_TRIGGERS;
create or replace synonym DBA_SOURCE          for SYS.DBA_SOURCE;
create or replace synonym DBA_VIEWS           for SYS.DBA_VIEWS;
create or replace synonym DBA_TYPES           for SYS.DBA_TYPES;
create or replace synonym DBA_COLL_TYPES      for SYS.DBA_COLL_TYPES;
create or replace synonym DBA_TYPE_ATTRS      for SYS.DBA_TYPE_ATTRS;
create or replace synonym DBA_TYPE_METHODS    for SYS.DBA_TYPE_METHODS;
create or replace synonym DBA_METHOD_RESULTS  for SYS.DBA_METHOD_RESULTS;
create or replace synonym DBA_ALL_TABLES      for SYS.DBA_ALL_TABLES;
create or replace synonym DBA_TAB_COLUMNS     for SYS.DBA_TAB_COLUMNS;
create or replace synonym DBA_UNUSED_COL_TABS for SYS.DBA_UNUSED_COL_TABS;
create or replace synonym DBA_IND_COLUMNS     for SYS.DBA_IND_COLUMNS_1;
create or replace synonym DBA_IND_EXPRESSIONS for SYS.DBA_IND_EXPRESSIONS;
create or replace synonym DBA_TRIGGER_COLS    for SYS.DBA_TRIGGER_COLS;
create or replace synonym DBA_TAB_PARTITIONS  for SYS.DBA_TAB_PARTITIONS;
create or replace synonym DBA_IND_PARTITIONS  for SYS.DBA_IND_PARTITIONS;
create or replace synonym DBA_USERS           for SYS.DBA_USERS;
create or replace synonym DBA_DEPENDENCIES    for SYS.DBA_DEPENDENCIES;
create or replace synonym DBA_TAB_PRIVS       for SYS.DBA_TAB_PRIVS;
create or replace synonym DBA_SYS_PRIVS       for SYS.DBA_SYS_PRIVS;
create or replace synonym DBA_TABLESPACES     for SYS.DBA_TABLESPACES;
create or replace synonym DBA_SYNONYMS        for SYS.DBA_SYNONYMS;
create or replace synonym DBA_SEQUENCES       for SYS.DBA_SEQUENCES;
create or replace synonym DBA_EXTENTS         for SYS.DBA_EXTENTS;
create or replace synonym DBA_LOCK            for SYS.DBA_LOCK;
create or replace synonym DBA_LIBRARIES       for SYS.DBA_LIBRARIES;

create or replace synonym DBA_NESTED_TABLES   for SYS.DBA_NESTED_TABLES_SIMPLE;
create or replace synonym DBA_ROLE_PRIVS      for SYS.DBA_ROLE_PRIVS_SIMPLE;
create or replace synonym DBA_ERRORS          for SYS.DBA_ERRORS_SIMPLE;
create or replace synonym USER_NESTED_TABLES  for SYS.USER_NESTED_TABLES_SIMPLE;
create or replace synonym ALL_SYNONYMS_SIMPLE for SYS.ALL_SYNONYMS_SIMPLE;
create or replace synonym USER_ERRORS         for SYS.USER_ERRORS_SIMPLE;
create or replace synonym DBA_CONSTRAINTS     for SYS.DBA_CONSTRAINTS_1;
create or replace synonym DBA_CONS_COLUMNS    for SYS.DBA_CONS_COLUMNS_1;
create or replace synonym DBA_OBJECT_TABLES   for SYS.DBA_OBJECT_TABLES;
create or replace synonym DBA_TAB_COLS        for SYS.DBA_TAB_COLS;
create or replace synonym DBA_NESTED_TABLE_COLS for SYS.DBA_NESTED_TABLE_COLS;
create or replace synonym DBA_CONTEXT         for SYS.DBA_CONTEXT;

create or replace synonym V$DB_PIPES  for SYS.V_$DB_PIPES;
create or replace synonym V$SESSION_EVENT for SYS.V_$SESSION_EVENT;
create or replace synonym V$SESSION_WAIT  for SYS.V_$SESSION_WAIT;
create or replace synonym V$SYSTEM_EVENT  for SYS.V_$SYSTEM_EVENT;
create or replace synonym V$EVENT_NAME for SYS.V_$EVENT_NAME;
create or replace synonym V$SESS_IO for SYS.V_$SESS_IO;
create or replace synonym V$MYSTAT  for SYS.V_$MYSTAT;
create or replace synonym V$SGASTAT for SYS.V_$SGASTAT;
create or replace synonym V$SYSSTAT for SYS.V_$SYSSTAT;
create or replace synonym V$SQLTEXT for SYS.V_$SQLTEXT;
create or replace synonym V$SQLAREA for SYS.V_$SQLAREA;
create or replace synonym V$CONTEXT for SYS.V_$CONTEXT;
create or replace synonym V$GLOBALCONTEXT for SYS.V_$GLOBALCONTEXT;
create or replace synonym globalcontext for SYS.GLOBAL_CONTEXT;
create or replace synonym V$DATABASE for SYS.V_$DATABASE;
create or replace synonym V$OSSTAT   for SYS.V_$OSSTAT;
create or replace synonym V$LICENSE  for SYS.V_$LICENSE;

create or replace synonym GV$DB_PIPES  for SYS.GV_$DB_PIPES;
create or replace synonym GV$SESSION_EVENT for SYS.GV_$SESSION_EVENT;
create or replace synonym GV$SESSION_WAIT  for SYS.GV_$SESSION_WAIT;
create or replace synonym GV$SYSTEM_EVENT  for SYS.GV_$SYSTEM_EVENT;
create or replace synonym GV$EVENT_NAME for SYS.GV_$EVENT_NAME;
create or replace synonym GV$SESS_IO for SYS.GV_$SESS_IO;
create or replace synonym GV$MYSTAT  for SYS.GV_$MYSTAT;
create or replace synonym GV$SGASTAT for SYS.GV_$SGASTAT;
create or replace synonym GV$SYSSTAT for SYS.GV_$SYSSTAT;
create or replace synonym GV$SQLTEXT for SYS.GV_$SQLTEXT;
create or replace synonym GV$SQLAREA for SYS.GV_$SQLAREA;
create or replace synonym GV$CONTEXT for SYS.GV_$CONTEXT;
create or replace synonym GV$GLOBALCONTEXT for SYS.GV_$GLOBALCONTEXT;

create or replace synonym DBMS_SYSTEM for SYS.DBMS_SYSTEM;
create or replace synonym LICENSE_PARAMS for AUD.license_params;

set echo off

