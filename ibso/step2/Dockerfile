FROM ibso:installed
MAINTAINER ivan

ADD /ibso_16_5_install/INSTALL/CR_DB_ORA12c/scripts/ $ORACLE_BASE/admin/work/scripts/
RUN chown -R oracle $ORACLE_BASE/admin/work
RUN mkdir -p /db1/oradata/work
RUN chown oracle /db1/oradata/work
#RUN cd /tmp
#RUN rm -rf /tmp/install

#ENV ORACLE_SID ORCL
ENV ORACLE_HOME $ORACLE_BASE/product/12.1.0/dbhome_1
ENV PATH $ORACLE_HOME/bin:$PATH
ENV ORACLE_SID work

WORKDIR $ORACLE_BASE/admin/work/scripts/
#RUN su oracle
#RUN runuser -l oracle -c 'bash $ORACLE_BASE/admin/work/scripts/work.sh'
#
#RUN $ORACLE_HOME/root.sh
#
#RUN mkdir -p $ORACLE_BASE/oradata && chown -R oracle:oinstall $ORACLE_BASE/oradata && chmod -R 775 $ORACLE_BASE/oradata
#RUN mkdir -p $ORACLE_BASE/fast_recovery_area && chown -R oracle:oinstall $ORACLE_BASE/fast_recovery_area && chmod -R 775 $ORACLE_BASE/fast_recovery_area
#
#ADD initORCL.ora $ORACLE_HOME/dbs/initORCL.ora
#ADD createdb.sql $ORACLE_HOME/config/scripts/createdb.sql
#ADD conf_finish.sql $ORACLE_HOME/config/scripts/conf_finish.sql
#ADD create /tmp/create
