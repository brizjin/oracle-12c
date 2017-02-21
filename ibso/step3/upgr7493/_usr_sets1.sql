-- Ётот файл настроек рекомендуетс€ использовать дл€ всех случаев, кроме
-- ќЅЌќ¬Ћ≈Ќ»я (UPGRADE) существующей схемы IBS Object, хран€щейс€
-- в иных табличных пространствах, а также кроме случа€
-- —ќ«ƒјЌ»я Ќќ¬ќ… схемы IBS Object.

--up.sql
def UP_TSTAB='USERS' --Default Tablespace for Tables
def UP_TSIDX='IDX' --Default Tablespace for Indexes
def UP_TSLOB='USERS' --Default Tablespace for Lobs
def UP_TPART='PART' --Archive Tablespace for Tables
def UP_TPARTI='PART' --Archive Tablespace for Indexes
def UP_TUSERS='USERS' --Tablespace for Dictionary Tables
def UP_TSPACEI='IDX' --Tablespace for Dictionary Indexes

--audit\audinit.sql
def AUD_TDEF='USERS' --Default tablespace
def AUD_TTMP='TEMP' --Temporary tablespace

--audit\upgrade\upgrade.sql
def AUD_SERVICE_TUSERS='USERS' --Tablespace for service TABLES (diary_tables, diary_indexes etc.)
def AUD_SERVICE_TSPACEI='IDX' --Tablespace for service INDEXES

--audit\settings\settings.sql
def AUD_TUSERS='USERS' --Tablespace for TABLES (diary1, diary2 ...)
def AUD_TSPACEI='IDX' --Tablespace for INDEXES

--AUDMGR\upgrade\audminit.sql
def AUDM_TDEF='USERS' --Default tablespace
def AUDM_TTMP='TEMP' --Temporary tablespace

--AUDMGR\upgrade\audm.sql
def AUDM_TUSERS='USERS' --Tablespace for tables

--AUDMGR\upgrade\audminit.sql and AUDMGR\upgrade\audm.sql
def AUDM_TSPACEI='IDX' --Tablespace for indexes
def AUDM_OWNER='AUDM' --Schema Name for AUDIT manager

--audit\a_defs.sql and AUDMGR\upgrade\audm.sql
def IBSO_OWNER='IBS' --IBSO schema owner name

-- Path to Oramon.exe utility
def oramon=''

