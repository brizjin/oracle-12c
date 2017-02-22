#!/bin/bash
#cd /dmp
#cat ibso_16_6_dmp.zip* > ibso.zip
#unzip ibso.zip && gunzip ibs_16_6.dmp.gz
#echo "TEST"
#echo "TEST"
#
#su -s /bin/bash oracle -c "sqlplus -S / as sysdba << EOF
#startup;
#EOF"
#echo "TEST2"
#echo "TEST2"


cd /tmp/SCRIPTS/SYSTEM
su -s /bin/bash oracle -c "sqlplus sys/sys as sysdba @/step3/step3.sql"
su -s /bin/bash oracle -c "sqlplus sys/sys as sysdba @init1.sql"

cd /step3/upgr7493/
su -s /bin/bash oracle -c "sqlplus sys/sys as sysdba @./SYS/upgrade.sql"
su -s /bin/bash oracle -c "sqlplus sys/sys as sysdba @utils/c_sys.sql"

cd /step3/upgr7493/audit
su -s /bin/bash oracle -c "sqlplus sys/sys as sysdba @audinit.sql sys/sys"			#audit/first.bat
su -s /bin/bash oracle -c "sqlplus sys/sys as sysdba @c_all load_aud_data aud/aud"	#audit/second.bat

cd /step3/upgr7493/audmgr
su -s /bin/bash oracle -c "sqlplus sys/sys as sysdba @upgrade/audminit.sql"			#audmgr/first.bat
su -s /bin/bash oracle -c "sqlplus sys/sys as sysdba @upgrade/audm.sql"				#audmgr/second.bat
su -s /bin/bash oracle -c "sqlplus sys/sys as sysdba @packages/syslogon.sql"				#audmgr/third.bat
su -s /bin/bash oracle -c "sqlplus sys/sys as sysdba @packages/syslogoff.sql"				#audmgr/logoff.bat




#
#cp /dmp/ibs_16_6.dmp /tmp/INSTALL/CR_DB_ORA12c/ibs_16_6.dmp
#cd /tmp/INSTALL/CR_DB_ORA12c
#su -s /bin/bash oracle -c "bash imp.dp.sh work ibs_16_6.dmp   "
#rm /tmp/INSTALL/CR_DB_ORA12c/ibs_16_6.dmp