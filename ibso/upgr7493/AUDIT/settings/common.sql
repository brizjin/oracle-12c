prompt
prompt PARTITION TABLSPACES SETTINGS
prompt
prompt Please enter tablespaces for MONTHLY diary tables and indexes:
accept DIARY_TBS char format a30 prompt 'Tablespace for TABLES [&&TUSER]: ' default &&TUSER
accept DIARY_IDX_TBS char format a30 prompt 'Tablespace for indexes [&&TSPACEI]: ' default &&TSPACEI
prompt
prompt Please enter tablespaces for QUARTERLY diaries tables and indexes:
accept Q_DIARY_TBS char format a30 prompt 'Tablespace for TABLES [&&TUSER]: ' default &&TUSER
accept Q_DIARY_IDX_TBS char format a30 prompt 'Tablespace for indexes [&&TSPACEI]: ' default &&TSPACEI


define DIARY_STEP='M'
define STEP_NUMBER='0'
@settings/set_part

define DIARY_STEP='M'
define STEP_NUMBER='1'
@settings/set_part

define DIARY_STEP='M'
define STEP_NUMBER='2'
@settings/set_part

define DIARY_STEP='M'
define STEP_NUMBER='3'
@settings/set_part

define DIARY_STEP='M'
define STEP_NUMBER='4'
@settings/set_part

define DIARY_STEP='M'
define STEP_NUMBER='5'
@settings/set_part

define DIARY_STEP='M'
define STEP_NUMBER='6'
@settings/set_part

define DIARY_STEP='M'
define STEP_NUMBER='7'
@settings/set_part

define DIARY_STEP='M'
define STEP_NUMBER='8'
@settings/set_part

define DIARY_STEP='M'
define STEP_NUMBER='9'
@settings/set_part

define DIARY_STEP='M'
define STEP_NUMBER='10'
@settings/set_part

define DIARY_STEP='M'
define STEP_NUMBER='11'
@settings/set_part

define DIARY_STEP='M'
define STEP_NUMBER='12'
@settings/set_part

define DIARY_STEP='M'
define STEP_NUMBER='13'
@settings/set_part



define DIARY_STEP='Q'
define STEP_NUMBER='0'
define DIARY_TBS=&&Q_DIARY_TBS
define DIARY_IDX_TBS=&&Q_DIARY_IDX_TBS
@settings/set_part

define DIARY_STEP='Q'
define STEP_NUMBER='1'
@settings/set_part

define DIARY_STEP='Q'
define STEP_NUMBER='2'
@settings/set_part

define DIARY_STEP='Q'
define STEP_NUMBER='3'
@settings/set_part

define DIARY_STEP='Q'
define STEP_NUMBER='4'
@settings/set_part

define DIARY_STEP='Q'
define STEP_NUMBER='5'
@settings/set_part
