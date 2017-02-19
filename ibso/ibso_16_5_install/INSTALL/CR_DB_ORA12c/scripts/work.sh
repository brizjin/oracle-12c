#!/bin/sh

OLD_UMASK=`umask`
umask 0027
mkdir -p /db1/oradata/work
mkdir -p $ORACLE_BASE
mkdir -p $ORACLE_BASE/admin/work/adump
mkdir -p $ORACLE_BASE/admin/work/dpdump
mkdir -p $ORACLE_BASE/admin/work/pfile
mkdir -p $ORACLE_BASE/audit
mkdir -p $ORACLE_BASE/cfgtoollogs/dbca/work
mkdir -p $ORACLE_BASE/product/12.1.0/dbhome_1/dbs
umask ${OLD_UMASK}
PERL5LIB=$ORACLE_HOME/rdbms/admin:$PERL5LIB; export PERL5LIB
ORACLE_SID=work; export ORACLE_SID
PATH=$ORACLE_HOME/bin:$PATH; export PATH
echo You should Add this entry in the /etc/oratab: work:$ORACLE_BASE/product/12.1.0/dbhome_1:Y
sqlplus /nolog @$ORACLE_BASE/admin/work/scripts/work.sql
