-- REBULD INST_INFO PACKAGE.
PROMPT Inst_Info Body
CREATE OR REPLACE
PACKAGE BODY INST_INFO is
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/init2.sql $
 *  $Author: VKazakov $
 *  $Revision: 128642 $
 *  $Date:: 2016-11-23 15:59:19 #$
 */
--
   BUILDMINOR constant pls_integer := 3;
--
function revision return pls_integer is
begin
  return buildminor;
end;
--
function get_version return varchar2 is
begin
  return Version||'.'||Build_No||'.'||buildminor;
end;
--
end INST_INFO;
/
sho err
