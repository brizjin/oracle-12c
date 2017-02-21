PROMPT  Package SHORT_VIEWS
CREATE OR REPLACE
Package SHORT_VIEWS IS
/*
 *	$HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/short1.sql $
 *	$Author: Alexey $
 *  $Revision: 15072 $
 *	$Date:: 2012-03-06 13:41:17 #$
 */
Revision	varchar2(10);
MdfDate		varchar2(16);
--------------------------------------------------------------------
-- Создание всех view
---------------------------------------------------------------------
PROCEDURE Create_All;
---------------------------------------------------------------------
-- Создание view для списка фин.счетов
---------------------------------------------------------------------
PROCEDURE Create_Vw_Ac_Fin;
END; -- Package spec
/
sho err

