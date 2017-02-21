***
*** TOOLS/XML - ������ ��� ������������� ������������ ������� XML Xerces
*** ������ 1.4.1.
***

TOOLS/XML - ����� PL/SQL ������� - ����������� � ����������� XML-������� Xerces.
������ PL/SQL ������ ��������� ��������� ��������� � ������� XML � ����������� DOM-������ �
��������� �������� �������: ���������� DOM-������ � ����������� ��������� XML-���������.

��������� ������/������������ ���������� ��� ���������� ���������
����� ����� platforms.doc

� ������ ������ ����������� ��������� �������.

������� ������ � ��������� ���������:
	parse, parseBuffer, parseClob, getDocument,
	writeToFile, writeToBuffer, writeToClob
	setValidationMode/getValidationMode(���������/���������
	 ������ �������� ��������� �� DTD, �� ��������� �������� ���������)
��������� DOM Document:
	getDocumentElement, createElement, createTextNode (�� ��������� ���� varchar2 � clob)
��������� DOM Node:
	getNodeName, getNodeValue (�� ��������� ���� varchar2 � clob), getNodeType, getParentNode, hasChildNodes,
	getFirstChild, getLastChild, getNextSibling, getAttributes, appendChild, replaceChild, removeChild.
��������� DOM NamedNodeMap:
	item, getLength.
��������� DOM Element:
	setAttribute.
�������:
	encodeBase64/decodeBase64 (�������� � clob)
	getReleaseVersion (���������� ������ XML).

��������� � ������������ SAX-������� Xerces �� ������ ������ �� ����������. 

��������� ��������� �������� � ���� ��������� ����������, �����������
���������� � Oracle � ��������� �������.


-1) ��������� ��������� ������� �������� Oracle ��� ������� � TOOLS\listener.txt

0) ������ � ������������, ���������������� ��������� ����������, ��������� ��
������� ������. �� ����� ��������� � http://supportobject.cft.ru ��������.

1) ��������� ����������

�������� ����� � ����������� �� �������� ���������������� �����
���������. ������ ����������: xml.tar.gz ��� Unix/Linux, xml.zip
��� Win32. �������� ��������� ������������� ������������ ��������,
� ��� ����� ����������� ���������:
1.�) �����. ������������ ��� ���������� �� ������ Oracle/�����������.
1.�) � �������� �������� ���� ����������� � ������� 8i � 9i,
��� ������������� ������ Oracle.
1.�) � �������� �������� ���� ����������� � ������� 32 � 64.
������������ ������ �� �������� 32, ���� � ��� Oracle 9i � ������� extproc32,
���� ���� � ��� Oracle 8i. ���� �� � ��� Oracle 9i � ������� extproc, ��
������������ ������ �� �������� 64. ����� extproc ������� �������� �
��������� ��������� PROGRAM: (PROGRAM = extproc)

���������� ���� ������� �� ���������� ���������

1.1) UNIX/LINUX

��������� � ������� ������������� ��������� ������� ��������
(��������, /u/tools. C�. � TOOLS\listener.txt �. 1).

���������� �����. � ����������� �� ��������� � ������
������������� ������, ����� ������������ ���� �� ��������� ������:
tar xzvf xml.tar.gz
gtar xzvf xml.tar.gz
gunzip -c xml.tar.gz | tar xvf -

����� ������� ����� xml �� ��������� ����������:
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

1.1.1) ����� ����� ����� extproc ��� ����� ���������� �� �������� lib
(���� ������� �������� ��������� ����������). ��� ����� �������� �������
� TOOLS\listener.txt �. 4.

1.1.2) ���� �� ����������� ������� 4.�) ��� 4.�) �� TOOLS\listener.txt, �� ���������,
��� ���������� ����� �������� ����� ���:

������� 4.�) �� ����������� ����������/����������� � ��������� �����:
bash-2.05$ ldd libxml.so
        libxerces-c.so.26 =>     (file not found)
        libc.so.1 =>     /usr/lib/libc.so.1
        libdl.so.1 =>    /usr/lib/libdl.so.1
        /usr/platform/FJSV,GPUZC-M/lib/libc_psr.so.1

������� 4.�) ����� (������ �������� ������ ��� ������� ����, ��� �������
������� file not found. �� ����� ��������� ������ ����� ���� ������.)
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

��� LINUX ����� ���� ��������� ����� 1.2

1.2) ������ LINUX (� ���������� � ������ 1.1)

32bit ������������� �� Red Hat Linux release 7.1 (Seawolf)
������� ���������� �� ��������� �������:
1) glibc-2.2.4-33
2) libstdc++-2.96-112.7.1

64bit ������������ �� SuSE SLES-8 (ia64) VERSION = 8.1
������� ���������� �� ��������� �������:
1) glibc-2.2.5-136
2) libgcc-3.2-29
3) libstdc++-3.2-29

���� ��� ������ �� �����������, �� ����� ��� �������. ��������:
1.2.�) �������� ��� ������ ���:
bash-2.05$ rpm -qi glibc-2.2.5
package glibc-2.2.5 is not installed
1.2.�) ���������
bash-2.05$ rpm -ihv <rpm-����>
...
1.2.�) ����� ���������
bash-2.05$ rpm -qi glibc-2.2.5
Name        : glibc                        Relocations: (not relocateable)
Version     : 2.2.5                             Vendor: UnitedLinux LLC
Release     : 161                           Build Date: Fri 26 Sep 2003 09:40:35
...

1.3) WIN32

���������� ������:
icudt32.dll
icuuc32.dll
xerces-c_2_6.dll
xml.dll
��� ����� xml.dll ����� �������� ����� C:\WINDOWS\System32

2) ����������� ������� ���������� libxml � ��������� ������� xrc_xmldom
� xrc_xmlparser ������������ ��� ���������� UPGRADE. 

��������! ������� ��������� ������� � ����������� ���������� �� ���������� � 
���������� TOOLS\XML\  �������� �� ������ 7.0 � ����

���� ��������� XML ������������ ��������, ���������� ��������� ���������:

2.1) ���������������� ���������� � Oracle.
��� ����� ����� ��������� ������ c_sys.sql �� SQL*Plus �� ��� sys.
�� ������� ������� ���� � libxml.so/xml.dll. � ������� ���
/u/tools/xml/libxml.so ��� /u/tools/xml/libxml.sl ��� C:\oracle\tools\xml\xml.dll

2.2) ���������� ������.
��� ����� ����� ��������� ������ c_all.sql �� SQL*Plus �� ��� ���������.

2.3) � ���� "�������������" ����������������� ��������, ������������ ������
xrc_xmldom, xrc_xmlparser  � ���������� ���������.