SET WD=%~dp0
SET WD=%WD:\=/%
SET IBSO_VERSION=ibso_16_5_install
goto %1
:step0
docker run --rm -it -v %WD%ibso/step0:/tmp/install oracle-12c:step1 /bin/bash /tmp/install/unzip.sh
exit

:step1
docker build -t ibso:step1 -f %WD%ibso/step1/Dockerfile %WD%ibso/step1
REM docker rm step1
ECHO "ENTER COMMAND: bash /tmp/install/install"
ECHO "ENTER COMMAND: <enter>"
ECHO "ENTER COMMAND: exit"
docker run --shm-size=4g -it --name step1 -v %WD%step0/database:/tmp/install/database ibso:step1 /bin/bash
docker commit step1 ibso:installed
ECHO "#step1 finished"

:step2
ECHO "step2_ibso started"
docker build -t ibso:step2 -f %WD%ibso/step2/Dockerfile %WD%ibso
docker run -it --name ibsostep2 ibso:step2 bash
