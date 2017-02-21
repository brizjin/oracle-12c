***
*** TOOLS/XML - пакеты для использования возможностей парсера XML Xerces
*** Версия 1.4.1.
***

TOOLS/XML - набор PL/SQL пакетов - интерфейсов к популярному XML-парсеру Xerces.
Данные PL/SQL пакеты позволяют разбирать документы в формате XML с построением DOM-модели и
выполнять обратный процесс: построение DOM-модели и последующую генерацию XML-документа.

Состояние сборки/тестирования библиотеки для конкретной платформы
можно найти platforms.doc

В данной версии реализованы следующие функции.

Функции чтения и генерации документа:
	parse, parseBuffer, parseClob, getDocument,
	writeToFile, writeToBuffer, writeToClob
	setValidationMode/getValidationMode(установка/получение
	 режима проверки документа по DTD, по умолчанию проверка отключена)
Интерфейс DOM Document:
	getDocumentElement, createElement, createTextNode (со значением типа varchar2 и clob)
Интерфейс DOM Node:
	getNodeName, getNodeValue (со значением типа varchar2 и clob), getNodeType, getParentNode, hasChildNodes,
	getFirstChild, getLastChild, getNextSibling, getAttributes, appendChild, replaceChild, removeChild.
Интерфейс DOM NamedNodeMap:
	item, getLength.
Интерфейс DOM Element:
	setAttribute.
Утилиты:
	encodeBase64/decodeBase64 (работают с clob)
	getReleaseVersion (возвращает версию XML).

Интерфейс к возможностям SAX-парсера Xerces на данные момент не реализован. 

Процедура установки включает в себя установку библиотеки, регистрацию
библиотеки в Oracle и установку пакетов.


-1) Настроить поддержку внешних процедур Oracle как описано в TOOLS\listener.txt

0) Архивы с библиотеками, соответствующими различным платформам, исключены из
данного архива. Их нужно загрузить с http://supportobject.cft.ru отдельно.

1) Установка библиотеки

Возьмите архив с библиотекой из каталога соответствующего вашей
платформе. Архивы называются: xml.tar.gz для Unix/Linux, xml.zip
для Win32. Названия каталогов соответствуют операционным системам,
в них может содержаться следующее:
1.а) Архив. Использовать его независимо от версии Oracle/разрядности.
1.б) В основном каталоге есть подкаталоги с именами 8i и 9i,
они соответствуют версии Oracle.
1.в) В основном каталоге есть подкаталоги с именами 32 и 64.
Использовать версию из каталога 32, если у вас Oracle 9i и запущен extproc32,
либо если у вас Oracle 8i. Если же у вас Oracle 9i и запущен extproc, то
использовать версию из каталога 64. Какой extproc запущен написано в
настройке листенера PROGRAM: (PROGRAM = extproc)

Дальнейшие шаги зависят от конкретной платформы

1.1) UNIX/LINUX

Перейдите в катклог развертывания библиотек внешних процедур
(Например, /u/tools. Cм. в TOOLS\listener.txt п. 1).

Распакуйте архив. В зависимости от платформы и набора
установленных утилит, нужно использовать одну из следующих команд:
tar xzvf xml.tar.gz
gtar xzvf xml.tar.gz
gunzip -c xml.tar.gz | tar xvf -

Будет создана папка xml со следующей структурой:
libxml.so -> libxml.so.1.0
libxml.so.1.0
lib/libicudata.so -> libicudata.so.30.0
lib/libicudata.so.30 -> libicudata.so.30.0
lib/libicudata.so.30.0
lib/libicuuc.so -> libicuuc.so.30.0
lib/libicuuc.so.30 -> libicuuc.so.30.0
lib/libicuuc.so.30.0
lib/libxerces-c.so -> libxerces-c.so.26.0
lib/libxerces-c.so.26 -> libxerces-c.so.26.0
lib/libxerces-c.so.26.0

1.1.1) Далее нужно чтобы extproc мог найти библиотеки из каталога lib
(этот каталог содержит зависимые библиотеки). Как этого добиться описано
в TOOLS\listener.txt п. 4.

1.1.2) Если вы используете вариант 4.а) или 4.б) из TOOLS\listener.txt, то проверить,
что библиотеки стали доступны можно так:

вариант 4.а) до выставления переменной/копирования в системную папку:
bash-2.05$ ldd libxml.so
        libxerces-c.so.26 =>     (file not found)
        libc.so.1 =>     /usr/lib/libc.so.1
        libdl.so.1 =>    /usr/lib/libdl.so.1
        /usr/platform/FJSV,GPUZC-M/lib/libc_psr.so.1

вариант 4.б) после (Список приведен только для примера того, что пропала
надпись file not found. На вашей платформе список может быть другим.)
bash-2.05$ ldd libxml.so
        libxerces-c.so.26 =>     /u/tools/xml/lib/libxerces-c.so.26
        libc.so.1 =>     /usr/lib/libc.so.1
        libpthread.so.1 =>       /usr/lib/libpthread.so.1
        libnsl.so.1 =>   /usr/lib/libnsl.so.1
        libsocket.so.1 =>        /usr/lib/libsocket.so.1
        libicuuc.so.30 =>        /u/tools/xml/lib/libicuuc.so.30
        libicudata.so.30 =>      /u/tools/xml/lib/libicudata.so.30
        libm.so.1 =>     /usr/lib/libm.so.1
        libgen.so.1 =>   /usr/lib/libgen.so.1
        libdl.so.1 =>    /usr/lib/libdl.so.1
        libmp.so.2 =>    /usr/lib/libmp.so.2
        /usr/platform/FJSV,GPUZC-M/lib/libc_psr.so.1
        libthread.so.1 =>        /usr/lib/libthread.so.1
        librt.so.1 =>    /usr/lib/librt.so.1
        libaio.so.1 =>   /usr/lib/libaio.so.1
        libmd5.so.1 =>   /usr/lib/libmd5.so.1
        /usr/platform/FJSV,GPUZC-M/lib/libmd5_psr.so.1

Для LINUX также надо выполнить пункт 1.2

1.2) Только LINUX (в дополнение к пункту 1.1)

32bit тестировалась на Red Hat Linux release 7.1 (Seawolf)
Требует библиотеки из следующих пакетов:
1) glibc-2.2.4-33
2) libstdc++-2.96-112.7.1

64bit тесировалась на SuSE SLES-8 (ia64) VERSION = 8.1
Требует библиотеки из следующих пакетов:
1) glibc-2.2.5-136
2) libgcc-3.2-29
3) libstdc++-3.2-29

Если эти пакеты не установлены, то нужно это сделать. Например:
1.2.а) проверим что пакета нет:
bash-2.05$ rpm -qi glibc-2.2.5
package glibc-2.2.5 is not installed
1.2.б) установим
bash-2.05$ rpm -ihv <rpm-файл>
...
1.2.в) после установки
bash-2.05$ rpm -qi glibc-2.2.5
Name        : glibc                        Relocations: (not relocateable)
Version     : 2.2.5                             Vendor: UnitedLinux LLC
Release     : 161                           Build Date: Fri 26 Sep 2003 09:40:35
...

1.3) WIN32

Содержимое архива:
icudt32.dll
icuuc32.dll
xerces-c_2_6.dll
xml.dll
Все кроме xml.dll нужно положить папку C:\WINDOWS\System32

2) Регистрация внешней библиотеки libxml и установка пакетов xrc_xmldom
и xrc_xmlparser производится при выполнении UPGRADE. 

Внимание! Скрипты установки пакетов и регистрации библиотеки не включаются в 
подкаталог TOOLS\XML\  апгрейда ТЯ версии 7.0 и выше

Если установка XML производится отдельно, необходимо выполнить следующее:

2.1) Зарегистрировать библиотеку в Oracle.
Для этого нужно выполнить скрипт c_sys.sql из SQL*Plus из под sys.
По запросу указать путь к libxml.so/xml.dll. В примере это
/u/tools/xml/libxml.so или /u/tools/xml/libxml.sl или C:\oracle\tools\xml\xml.dll

2.2) Установить пакеты.
Для этого нужно выполнить скрипт c_all.sql из SQL*Plus из под владельца.

2.3) В АРМе "Администратор" перекомпилировать операции, использующие пакеты
xrc_xmldom, xrc_xmlparser  в глобальных описаниях.