prompt
prompt PARTITION TABLSPACES SETTINGS
prompt
prompt Now you will be prompted about tablspace for each MONTHLY partition

define DIARY_TBS=&&TUSER
define DIARY_IDX_TBS=&&TSPACEI

define DIARY_STEP='M'
define STEP_NUMBER='0'
prompt
prompt Enter tablspaces for MONTHLY partition &&STEP_NUMBER
accept DIARY_TBS char format a30 prompt 'Tablspace for TABLE [&&DIARY_TBS]: ' default &&DIARY_TBS
accept DIARY_IDX_TBS char format a30 prompt 'Tablespace for INDEX [&&DIARY_IDX_TBS]: ' default &&DIARY_IDX_TBS
@settings/set_part

define DIARY_STEP='M'
define STEP_NUMBER='1'
prompt
prompt Enter tablspaces for MONTHLY partition &&STEP_NUMBER
accept DIARY_TBS char format a30 prompt 'Tablespace for TABLE [&&DIARY_TBS]: ' default &&DIARY_TBS
accept DIARY_IDX_TBS char format a30 prompt 'Tablespace for INDEX [&&DIARY_IDX_TBS]: ' default &&DIARY_IDX_TBS
@settings/set_part

define DIARY_STEP='M'
define STEP_NUMBER='2'
prompt
prompt Enter tablspaces for MONTHLY partition &&STEP_NUMBER
accept DIARY_TBS char format a30 prompt 'Tablespace for TABLE [&&DIARY_TBS]: ' default &&DIARY_TBS
accept DIARY_IDX_TBS char format a30 prompt 'Tablespace for INDEX [&&DIARY_IDX_TBS]: ' default &&DIARY_IDX_TBS
@settings/set_part

define DIARY_STEP='M'
define STEP_NUMBER='3'
prompt
prompt Enter tablspaces for MONTHLY partition &&STEP_NUMBER
accept DIARY_TBS char format a30 prompt 'Tablespace for TABLE [&&DIARY_TBS]: ' default &&DIARY_TBS
accept DIARY_IDX_TBS char format a30 prompt 'Tablespace for INDEX [&&DIARY_IDX_TBS]: ' default &&DIARY_IDX_TBS
@settings/set_part

define DIARY_STEP='M'
define STEP_NUMBER='4'
prompt
prompt Enter tablspaces for MONTHLY partition &&STEP_NUMBER
accept DIARY_TBS char format a30 prompt 'Tablespace for TABLE [&&DIARY_TBS]: ' default &&DIARY_TBS
accept DIARY_IDX_TBS char format a30 prompt 'Tablespace for INDEX [&&DIARY_IDX_TBS]: ' default &&DIARY_IDX_TBS
@settings/set_part

define DIARY_STEP='M'
define STEP_NUMBER='5'
prompt
prompt Enter tablspaces for MONTHLY partition &&STEP_NUMBER
accept DIARY_TBS char format a30 prompt 'Tablespace for TABLE [&&DIARY_TBS]: ' default &&DIARY_TBS
accept DIARY_IDX_TBS char format a30 prompt 'Tablespace for INDEX [&&DIARY_IDX_TBS]: ' default &&DIARY_IDX_TBS
@settings/set_part

define DIARY_STEP='M'
define STEP_NUMBER='6'
prompt
prompt Enter tablspaces for MONTHLY partition &&STEP_NUMBER
accept DIARY_TBS char format a30 prompt 'Tablespace for TABLE [&&DIARY_TBS]: ' default &&DIARY_TBS
accept DIARY_IDX_TBS char format a30 prompt 'Tablespace for INDEX [&&DIARY_IDX_TBS]: ' default &&DIARY_IDX_TBS
@settings/set_part

define DIARY_STEP='M'
define STEP_NUMBER='7'
prompt
prompt Enter tablspaces for MONTHLY partition &&STEP_NUMBER
accept DIARY_TBS char format a30 prompt 'Tablespace for TABLE [&&DIARY_TBS]: ' default &&DIARY_TBS
accept DIARY_IDX_TBS char format a30 prompt 'Tablespace for INDEX [&&DIARY_IDX_TBS]: ' default &&DIARY_IDX_TBS
@settings/set_part

define DIARY_STEP='M'
define STEP_NUMBER='8'
prompt
prompt Enter tablspaces for MONTHLY partition &&STEP_NUMBER
accept DIARY_TBS char format a30 prompt 'Tablespace for TABLE [&&DIARY_TBS]: ' default &&DIARY_TBS
accept DIARY_IDX_TBS char format a30 prompt 'Tablespace for INDEX [&&DIARY_IDX_TBS]: ' default &&DIARY_IDX_TBS
@settings/set_part

define DIARY_STEP='M'
define STEP_NUMBER='9'
prompt
prompt Enter tablspaces for MONTHLY partition &&STEP_NUMBER
accept DIARY_TBS char format a30 prompt 'Tablespace for TABLE [&&DIARY_TBS]: ' default &&DIARY_TBS
accept DIARY_IDX_TBS char format a30 prompt 'Tablespace for INDEX [&&DIARY_IDX_TBS]: ' default &&DIARY_IDX_TBS
@settings/set_part

define DIARY_STEP='M'
define STEP_NUMBER='10'
prompt
prompt Enter tablspaces for MONTHLY partition &&STEP_NUMBER
accept DIARY_TBS char format a30 prompt 'Tablespace for TABLE [&&DIARY_TBS]: ' default &&DIARY_TBS
accept DIARY_IDX_TBS char format a30 prompt 'Tablespace for INDEX [&&DIARY_IDX_TBS]: ' default &&DIARY_IDX_TBS
@settings/set_part

define DIARY_STEP='M'
define STEP_NUMBER='11'
prompt
prompt Enter tablspaces for MONTHLY partition &&STEP_NUMBER
accept DIARY_TBS char format a30 prompt 'Tablespace for TABLE [&&DIARY_TBS]: ' default &&DIARY_TBS
accept DIARY_IDX_TBS char format a30 prompt 'Tablespace for INDEX [&&DIARY_IDX_TBS]: ' default &&DIARY_IDX_TBS
@settings/set_part

define DIARY_STEP='M'
define STEP_NUMBER='12'
prompt
prompt Enter tablspaces for MONTHLY partition &&STEP_NUMBER
accept DIARY_TBS char format a30 prompt 'Tablespace for TABLE [&&DIARY_TBS]: ' default &&DIARY_TBS
accept DIARY_IDX_TBS char format a30 prompt 'Tablespace for INDEX [&&DIARY_IDX_TBS]: ' default &&DIARY_IDX_TBS
@settings/set_part

define DIARY_STEP='M'
define STEP_NUMBER='13'
prompt
prompt Enter tablspaces for MONTHLY partition &&STEP_NUMBER
accept DIARY_TBS char format a30 prompt 'Tablespace for TABLE [&&DIARY_TBS]: ' default &&DIARY_TBS
accept DIARY_IDX_TBS char format a30 prompt 'Tablespace for INDEX [&&DIARY_IDX_TBS]: ' default &&DIARY_IDX_TBS
@settings/set_part

prompt
prompt Now you will be prompted about tablspace for each QUARTERLY partition

define DIARY_STEP='Q'
define STEP_NUMBER='0'
prompt
prompt Enter tablspaces for QUARTERLY partition &&STEP_NUMBER
accept DIARY_TBS char format a30 prompt 'Tablespace for TABLE [&&DIARY_TBS]: ' default &&DIARY_TBS
accept DIARY_IDX_TBS char format a30 prompt 'Tablespace for INDEX [&&DIARY_IDX_TBS]: ' default &&DIARY_IDX_TBS
@settings/set_part

define DIARY_STEP='Q'
define STEP_NUMBER='1'
prompt
prompt Enter tablspaces for QUARTERLY partition &&STEP_NUMBER
accept DIARY_TBS char format a30 prompt 'Tablespace for TABLE [&&DIARY_TBS]: ' default &&DIARY_TBS
accept DIARY_IDX_TBS char format a30 prompt 'Tablespace for INDEX [&&DIARY_IDX_TBS]: ' default &&DIARY_IDX_TBS
@settings/set_part

define DIARY_STEP='Q'
define STEP_NUMBER='2'
prompt
prompt Enter tablspaces for QUARTERLY partition &&STEP_NUMBER
accept DIARY_TBS char format a30 prompt 'Tablespace for TABLE [&&DIARY_TBS]: ' default &&DIARY_TBS
accept DIARY_IDX_TBS char format a30 prompt 'Tablespace for INDEX [&&DIARY_IDX_TBS]: ' default &&DIARY_IDX_TBS
@settings/set_part

define DIARY_STEP='Q'
define STEP_NUMBER='3'
prompt
prompt Enter tablspaces for QUARTERLY partition &&STEP_NUMBER
accept DIARY_TBS char format a30 prompt 'Tablespace for TABLE [&&DIARY_TBS]: ' default &&DIARY_TBS
accept DIARY_IDX_TBS char format a30 prompt 'Tablespace for INDEX [&&DIARY_IDX_TBS]: ' default &&DIARY_IDX_TBS
@settings/set_part

define DIARY_STEP='Q'
define STEP_NUMBER='4'
prompt
prompt Enter tablspaces for QUARTERLY partition &&STEP_NUMBER
accept DIARY_TBS char format a30 prompt 'Tablespace for TABLE [&&DIARY_TBS]: ' default &&DIARY_TBS
accept DIARY_IDX_TBS char format a30 prompt 'Tablespace for INDEX [&&DIARY_IDX_TBS]: ' default &&DIARY_IDX_TBS
@settings/set_part

define DIARY_STEP='Q'
define STEP_NUMBER='5'
prompt
prompt Enter tablspaces for QUARTERLY partition &&STEP_NUMBER
accept DIARY_TBS char format a30 prompt 'Tablespace for TABLE [&&DIARY_TBS]: ' default &&DIARY_TBS
accept DIARY_IDX_TBS char format a30 prompt 'Tablespace for INDEX [&&DIARY_IDX_TBS]: ' default &&DIARY_IDX_TBS
@settings/set_part
