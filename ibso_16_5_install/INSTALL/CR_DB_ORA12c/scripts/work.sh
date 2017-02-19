#!/bin/sh

OLD_UMASK=`umask`
umask 0027
mkdir -p /db1/oradata/work
mkdir -p /u/app/oracle
mkdir -p /u/app/oracle/admin/work/adump
mkdir -p /u/app/oracle/admin/work/dpdump
mkdir -p /u/app/oracle/admin/work/pfile
mkdir -p /u/app/oracle/audit
mkdir -p /u/app/oracle/cfgtoollogs/dbca/work
mkdir -p /u/app/oracle/product/12.1.0/dbhome_1/dbs
umask ${OLD_UMASK}
PERL5LIB=$ORACLE_HOME/rdbms/admin:$PERL5LIB; export PERL5LIB
ORACLE_SID=work; export ORACLE_SID
PATH=$ORACLE_HOME/bin:$PATH; export PATH
echo You should Add this entry in the /etc/oratab: work:/u/app/oracle/product/12.1.0/dbhome_1:Y
/u/app/oracle/product/12.1.0/dbhome_1/bin/sqlplus /nolog @/u/app/oracle/admin/work/scripts/work.sql
