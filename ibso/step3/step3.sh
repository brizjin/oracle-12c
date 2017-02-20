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
su -s /bin/bash oracle -c "sqlplus / as sysdba @/step3/step3.sql"
su -s /bin/bash oracle -c "sqlplus / as sysdba @init1.sql"

cp /dmp/ibs_16_6.dmp /tmp/INSTALL/CR_DB_ORA12c/ibs_16_6.dmp
cd /tmp/INSTALL/CR_DB_ORA12c
su -s /bin/bash oracle -c "bash imp.dp.sh work ibs_16_6.dmp   "
#rm /tmp/INSTALL/CR_DB_ORA12c/ibs_16_6.dmp