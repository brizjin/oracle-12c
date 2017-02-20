prompt
prompt PARTITION TABLSPACES SETTINGS
prompt
prompt Please enter tablespace prefix for diary tables and indexes.
prompt For example if you enter prefix TAB, tablespace names will be
prompt TAB_01 .. TAB_11 TAB_12 for monthly diaries and
prompt TAB_A TAB_B TAB_C TAB_D for quarterly diaries.
prompt You MUST create tablspaces with SUCH NAMES before create diaries.
prompt
prompt Prefixes for MONTHLY diaries:
accept M_TBS_PREFIX char format a30 prompt 'Tablespace for TABLES [&&TUSER]: ' default &&TUSER
accept M_IDX_TBS_PREFIX char format a30 prompt 'Tablespace for INDEXES [&&TSPACEI]: ' default &&TSPACEI
prompt
prompt Prefixes for QUARTERLY diaries:
accept Q_TBS_PREFIX char format a30 prompt 'Tablespace for TABLES [&&TUSER]: ' default &&TUSER
accept Q_IDX_TBS_PREFIX char format a30 prompt 'Tablespace for INDEXES [&&TSPACEI]: ' default &&TSPACEI


define DIARY_STEP='M'
define STEP_NUMBER='0'
define DIARY_TBS='&&TUSER'
define DIARY_IDX_TBS='&&TSPACEI'
@settings\set_part

define DIARY_STEP='M'
define STEP_NUMBER='1'
define DIARY_TBS='&&M_TBS_PREFIX._01'
define DIARY_IDX_TBS='&&M_IDX_TBS_PREFIX._01'
@settings\set_part

define DIARY_STEP='M'
define STEP_NUMBER='2'
define DIARY_TBS='&&M_TBS_PREFIX._02'
define DIARY_IDX_TBS='&&M_IDX_TBS_PREFIX._02'
@settings\set_part

define DIARY_STEP='M'
define STEP_NUMBER='3'
define DIARY_TBS='&&M_TBS_PREFIX._03'
define DIARY_IDX_TBS='&&M_IDX_TBS_PREFIX._03'
@settings\set_part

define DIARY_STEP='M'
define STEP_NUMBER='4'
define DIARY_TBS='&&M_TBS_PREFIX._04'
define DIARY_IDX_TBS='&&M_IDX_TBS_PREFIX._04'
@settings\set_part

define DIARY_STEP='M'
define STEP_NUMBER='5'
define DIARY_TBS='&&M_TBS_PREFIX._05'
define DIARY_IDX_TBS='&&M_IDX_TBS_PREFIX._05'
@settings\set_part

define DIARY_STEP='M'
define STEP_NUMBER='6'
define DIARY_TBS='&&M_TBS_PREFIX._06'
define DIARY_IDX_TBS='&&M_IDX_TBS_PREFIX._06'
@settings\set_part

define DIARY_STEP='M'
define STEP_NUMBER='7'
define DIARY_TBS='&&M_TBS_PREFIX._07'
define DIARY_IDX_TBS='&&M_IDX_TBS_PREFIX._07'
@settings\set_part

define DIARY_STEP='M'
define STEP_NUMBER='8'
define DIARY_TBS='&&M_TBS_PREFIX._08'
define DIARY_IDX_TBS='&&M_IDX_TBS_PREFIX._08'
@settings\set_part

define DIARY_STEP='M'
define STEP_NUMBER='9'
define DIARY_TBS='&&M_TBS_PREFIX._09'
define DIARY_IDX_TBS='&&M_IDX_TBS_PREFIX._09'
@settings\set_part

define DIARY_STEP='M'
define STEP_NUMBER='10'
define DIARY_TBS='&&M_TBS_PREFIX._10'
define DIARY_IDX_TBS='&&M_IDX_TBS_PREFIX._10'
@settings\set_part

define DIARY_STEP='M'
define STEP_NUMBER='11'
define DIARY_TBS='&&M_TBS_PREFIX._11'
define DIARY_IDX_TBS='&&M_IDX_TBS_PREFIX._11'
@settings\set_part

define DIARY_STEP='M'
define STEP_NUMBER='12'
define DIARY_TBS='&&M_TBS_PREFIX._12'
define DIARY_IDX_TBS='&&M_IDX_TBS_PREFIX._12'
@settings\set_part

define DIARY_STEP='M'
define STEP_NUMBER='13'
define DIARY_TBS='&&TUSER'
define DIARY_IDX_TBS='&&TSPACEI'
@settings\set_part

define DIARY_STEP='Q'
define STEP_NUMBER='0'
define DIARY_TBS='&&TUSER'
define DIARY_IDX_TBS='&&TSPACEI'
@settings\set_part

define DIARY_STEP='Q'
define STEP_NUMBER='1'
define DIARY_TBS='&&Q_TBS_PREFIX._A'
define DIARY_IDX_TBS='&&Q_IDX_TBS_PREFIX._A'
@settings\set_part

define DIARY_STEP='Q'
define STEP_NUMBER='2'
define DIARY_TBS='&&Q_TBS_PREFIX._B'
define DIARY_IDX_TBS='&&Q_IDX_TBS_PREFIX._B'
@settings\set_part

define DIARY_STEP='Q'
define STEP_NUMBER='3'
define DIARY_TBS='&&Q_TBS_PREFIX._C'
define DIARY_IDX_TBS='&&Q_IDX_TBS_PREFIX._C'
@settings\set_part

define DIARY_STEP='Q'
define STEP_NUMBER='4'
define DIARY_TBS='&&Q_TBS_PREFIX._D'
define DIARY_IDX_TBS='&&Q_IDX_TBS_PREFIX._D'
@settings\set_part

define DIARY_STEP='Q'
define STEP_NUMBER='5'
define DIARY_TBS='&&TUSER'
define DIARY_IDX_TBS='&&TSPACEI'
@settings\set_part
