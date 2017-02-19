SET WD=%~dp0
SET WD=%WD:\=/%
SET WD2=c:/ibso/oracle-12c-docker/
SET IBSO_VERSION=ibso_16_5_install
goto %1
:step0
docker run --rm -it -v %WD%step0:/tmp/install oracle-12c:step1 /bin/bash /tmp/install/unzip.sh

:step1
docker build -t oracle-12c:step1 step1
REM docker rm step1
ECHO ENTER COMMAND: bash /tmp/install/install
ECHO ENTER COMMAND: <enter>
ECHO ENTER COMMAND: exit
docker run --shm-size=4g -it --name step1 -v %WD%step0/database:/tmp/install/database oracle-12c:step1 /bin/bash
docker commit step1 oracle-12c:installed
ECHO #step1 finished

:step2
ECHO step2_ibso started
docker build -t oracle-12c:step2_ibso %WD%step2_ibso %IBSO_VERSION%
