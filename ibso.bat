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
ECHO "su oracle"
ECHO "bash work.sh"
ECHO "enter: sys"
ECHO "enter: system"
ECHO "enter: sys"
docker rm ibsostep2
docker run -it --name ibsostep2 ibso:step2 bash
