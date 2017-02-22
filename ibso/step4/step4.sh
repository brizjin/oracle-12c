#!/bin/bash
sqlplus sys/sys as sysdba << EOF
startup;
EOF

cd /dmp
! [ -f /dmp/ibso.zip ] && cat ibso_16_6_dmp.zip* > ibso.zip
! [ -f /dmp/ibs_16_6.dmp.gz ] && unzip ibso.zip
! [ -f /dmp/ibs_16_6.dmp ] && gunzip ibs_16_6.dmp.gz

cp /dmp/ibs_16_6.dmp /tmp/INSTALL/CR_DB_ORA12c/ibs_16_6.dmp
cd /tmp/INSTALL/CR_DB_ORA12c
bash imp.dp.sh work ibs_16_6.dmp
[ -f /tmp/INSTALL/CR_DB_ORA12c/ibs_16_6.dmp ] && rm /tmp/INSTALL/CR_DB_ORA12c/ibs_16_6.dmp