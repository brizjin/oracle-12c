FROM ibso:step2
MAINTAINER ivan

#COPY /* /tmp/step3/
#COPY /ibso_16_5_install /tmp/ibso_16_5_install/
#USER oracle
#RUN sqlplus -S / as sysdba @/tmp/step3/step3.sql
##WORKDIR /tmp/ibso_16_5_install/SCRIPTS/SYSTEM
#RUN cd /tmp/ibso_16_5_install/SCRIPTS/SYSTEM && sqlplus / as sysdba @init1.sql

#RUN rm /tmp/create

# Exposes the default TNS port, as well as the Enterprise Manager Express HTTP
# (8080) and HTTPS (5500) ports.
EXPOSE 1521 5500 8080

ENV PATH=$ORACLE_HOME/bin:$PATH
COPY startdb.sql $ORACLE_HOME/config/scripts/startdb.sql
ADD start /tmp/start
CMD /tmp/start