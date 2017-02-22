SET WD=%~dp0
SET WD=%WD:\=/%
SET IBSO_VERSION=ibso_16_5_install
goto %1

REM на шаге 0 мы делаем контенер с zip и распаховываем архив базы
:step0
docker build -t ibso:zip -f %WD%ibso/step0/Dockerfile %WD%ibso/step0
docker run --rm -it -v %WD%ibso/step0:/tmp/install ibso:zip /bin/bash /tmp/install/unzip.sh
exit /b

REM на шаге 1 мы устанавливаем oracle
:step1
docker build -t ibso:step1 -f %WD%ibso/step1/Dockerfile %WD%ibso/step1
REM docker rm step1
ECHO "# after contener is started: bash /tmp/install/install"
ECHO "# after installer enter: <enter>"
ECHO "# exit from container: exit"
docker rm ibsostep1
docker run --shm-size=4g -it --name ibsostep1 -v %WD%ibso/step0/database:/tmp/install/database ibso:step1
docker commit ibsostep1 ibso:installed
exit /b

:step2
ECHO "step2_ibso started"
docker build -t ibso:step2 -f %WD%ibso/step2/Dockerfile %WD%ibso
exit /b
REM docker run --name ibsostep2 -it ibso:step2
REM docker rm ibsostep2
REM docker run -it --name ibsostep2 ibso:step2 bash
REM ECHO "su oracle"
REM ECHO "bash work.sh"
REM ECHO "enter: sys"
REM ECHO "enter: system"
REM ECHO "enter: sys"
REM docker rm ibsostep2
REM docker run -it --name ibsostep2 ibso:step2 bash

REM prepare dmp file
REM :step3
REM docker build -t ibso:step3 -f %WD%ibso/step3/Dockerfile %WD%ibso
REM docker run -it --rm  -v %WD%ibso/ibso_16_5_install:/tmp -v %WD%dmp:/dmp ibso:step2 bash -c "cd /dmp && cat ibso_16_6_dmp.zip* > ibso.zip && unzip ibso.zip && gunzip ibs_16_6.dmp.gz"
REM docker run -it --rm -v %WD%ibso/ibso_16_5_install:/tmp -v %WD%dmp:/dmp -v %WD%ibso/step3:/step3 ibso:step2 bash /step3/step3.sh
REM docker run -it --name ibsostep3 -v %WD%ibso/ibso_16_5_install:/tmp -v %WD%dmp:/dmp -v %WD%ibso/step3:/step3 -v %WD%ibso/step3/upgr7493:/upgr ibso:step3 bash -c "bash /step3/step3.sh"
:step3
docker rm -f ibsostep3
docker run -it --name ibsostep3 -v %WD%ibso/ibso_16_5_install:/tmp -v %WD%dmp:/dmp -v %WD%ibso/step3:/step3 ibso:step2 bash /step3/step3.sh
REM docker commit ibsostep3 ibso:step3
exit /b

REM :step4
REM docker run -it --rm  -v %WD%ibso/ibso_16_5_install:/tmp -v %WD%dmp:/dmp ibso:step2 bash
