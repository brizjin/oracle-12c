-- Этот файл настроек рекомендуется использовать для
-- ОБНОВЛЕНИЯ (UPGRADE) существующей схемы IBS Object, хранящейся
-- табличных пространствах, перечисленных ниже или для
-- СОЗДАНИЯ НОВОЙ схемы IBS Object.

--up.sql
def UP_TSTAB='T_USR' --Default Tablespace for Tables
def UP_TSIDX='I_USR' --Default Tablespace for Indexes
def UP_TSLOB='T_USR' --Default Tablespace for Lobs
def UP_TPART='PART' --Archive Tablespace for Tables
def UP_TPARTI='PART' --Archive Tablespace for Indexes
def UP_TUSERS='T_DICT' --Tablespace for Dictionary Tables
def UP_TSPACEI='I_DICT' --Tablespace for Dictionary Indexes

--audit\audinit.sql
def AUD_TDEF='T_AUD' --Default tablespace
def AUD_TTMP='TEMP' --Temporary tablespace

--audit\upgrade\upgrade.sql
def AUD_SERVICE_TUSERS='T_AUD' --Tablespace for service TABLES (diary_tables, diary_indexes etc.)
def AUD_SERVICE_TSPACEI='I_AUD' --Tablespace for service INDEXES

--audit\settings\settings.sql
def AUD_TUSERS='T_AUD' --Tablespace for TABLES (diary1, diary2 ...)
def AUD_TSPACEI='I_AUD' --Tablespace for INDEXES

--AUDMGR\upgrade\audminit.sql
def AUDM_TDEF='T_AUD' --Default tablespace
def AUDM_TTMP='TEMP' --Temporary tablespace

--AUDMGR\upgrade\audm.sql
def AUDM_TUSERS='T_AUD' --Tablespace for tables

--AUDMGR\upgrade\audminit.sql and AUDMGR\upgrade\audm.sql
def AUDM_TSPACEI='I_AUD' --Tablespace for indexes
def AUDM_OWNER='AUDM' --Schema Name for AUDIT manager

--audit\a_defs.sql and AUDMGR\upgrade\audm.sql
def IBSO_OWNER='IBS' --IBSO schema owner name

-- Path to Oramon.exe utility
def oramon=''

