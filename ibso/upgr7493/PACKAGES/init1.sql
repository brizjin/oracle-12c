-- REBULD INST_INFO PACKAGE.
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/init1.sql $
 *  $Author: petrushov $
 *  $Revision: 66551 $
 *  $Date:: 2015-02-17 15:20:13 #$
 */
PROMPT Creating installation info...
var db_version number
var db_release varchar2(100)

declare
  s1 varchar2(100);
  s2 varchar2(100);
begin
  dbms_utility.db_version(s1,s2);
  :db_release := s1;
  :db_version := substr(s1,1,instr(s1,'.')-1);
end;
/
def AUDITOR=AUD
def db_inst=1
column xxx new_value db_inst noprint
select value xxx from v$parameter where name='cluster_database_instances';
column xxx new_value db_ver noprint
select ltrim(to_char(:db_version)) xxx from dual;
column xxx new_value db_rel noprint
select :db_release xxx from dual;
column xxx new_value oyyy noprint
select to_char(sysdate,'DD-MM-YYYY HH24:MI:SS') xxx from dual;
column xxx new_value oxxx noprint
select user xxx from dual;
CREATE OR REPLACE PACKAGE INST_INFO is
   pragma restrict_references ( inst_info, wnds, wnps, rnds, rnps );
   OWNER      constant varchar2(30):='&&OWNER';
   GOWNER     constant varchar2(30):='&&GOWNER';
   DOWNER1    constant varchar2(30):='&&DOWNER1';
   DOWNER2    constant varchar2(30):='&&DOWNER2';
   AUDITOR    constant varchar2(30):='&&AUDITOR';
   AUDIT_MGR  constant varchar2(30):='&&AUDM_OWNER';
   SOWNER     constant varchar2(30):='&oxxx';
   VERSION    constant varchar2(16):='7.4';
   BUILD_NO   constant pls_integer := 9;
   BUILD_DATE constant varchar2(30):='&oyyy';
   DB_VERSION constant pls_integer :=&&DB_VER;
   DB_RELEASE constant varchar2(30):='&&DB_REL';
   DB_INSTANCES constant pls_integer :=&&DB_INST;
   function   revision return pls_integer;
   pragma restrict_references ( revision, wnds, wnps, rnds );
   function   get_version return varchar2;
   pragma restrict_references ( get_version, wnds, wnps, rnds );
end INST_INFO;
/
sho err
