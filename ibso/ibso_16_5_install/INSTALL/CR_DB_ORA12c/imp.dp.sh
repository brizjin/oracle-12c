#!/bin/sh
##  UNIX - Datapump Database Import
## Usage: ./imp.dp.sh DB_SID LIST_OF_FILE_COMMA_SEPARATED
##Examples:
## ./imp.dp.sh work expdb1_01.dmp
## ./imp.dp.sh work expdb1_01.dmp,expdb2_01.dmp,expdb3_01.dmp

ORACLE_SID=$1; export ORACLE_SID
NLS_LANG=AMERICAN_AMERICA.CL8ISO8859P5; export NLS_LANG
DIRN=`pwd`

echo `date`. Starting import IBS schema to DB $ORACLE_SID.

$ORACLE_HOME/bin/sqlplus -S / as sysdba << EOF
set echo off
create or replace directory DATA_PUMP as '$DIRN';
EOF

$ORACLE_HOME/bin/impdp \'/ as sysdba\' DIRECTORY=DATA_PUMP DUMPFILE=$2 LOGFILE=imp.log PARFILE=imp.dp.par

$ORACLE_HOME/bin/sqlplus -S / as sysdba << EOF
set echo off
drop directory DATA_PUMP;
EOF

echo `date`. Import IBS schema to DB $ORACLE_SID done.
