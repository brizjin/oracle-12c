PROMPT OPENREPORTQUEUE
CREATE OR REPLACE PROCEDURE OPENREPORTQUEUE
(
  pJob          OUT pls_integer,
  pPos          OUT pls_integer,
  pSessID       OUT pls_integer,
  pDomain       OUT USERS.OS_DOMAIN%TYPE,
  pOSUser       OUT USERS.OS_USER%TYPE,
  pParam        OUT ORSA_JOBS_PAR.VALUE%TYPE,
  pServer       IN  ORSA_JOBS.SERVER_EXECUTED%TYPE default null,
  pReuseSession IN BOOLEAN DEFAULT NULL
)
IS
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/rptqueue.sql $
 *  $Revision: 15072 $
 *  $Date:: 2012-03-06 13:41:17 #$
 */
BEGIN
   report_mgr.open(pJob, pPos, pSessID, pDomain, pOSUser, pParam, pServer, pReuseSession);
END;
/
sho err

PROMPT OPENREPORTSESSION
CREATE OR REPLACE PROCEDURE OPENREPORTSESSION
(
  pJob        IN  pls_integer,
  pPos        IN  pls_integer,
  pSessID     OUT pls_integer,
  pDomain     OUT USERS.OS_DOMAIN%TYPE,
  pOSUser     OUT USERS.OS_USER%TYPE,
  pProperties OUT ORSA_JOBS.PROPERTIES%TYPE
)
IS
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/rptqueue.sql $
 *  $Revision: 15072 $
 *  $Date:: 2012-03-06 13:41:17 #$
 */
BEGIN
   report_mgr.open_rpt_session(pJob, pPos, pSessID, pDomain, pOSUser, pProperties);
END;
/
sho err

