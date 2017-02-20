FROM ibso:step2
MAINTAINER ivan

ADD /step3/step3.sql /tmp/step3.sql
RUN su -s /bin/bash oracle -c "sqlplus -S / as sysdba @/tmp/step3.sql"