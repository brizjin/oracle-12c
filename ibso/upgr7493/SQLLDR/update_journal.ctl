--id		- ��������� ���� 
--is_before	- 1 - ��������� �� ������ �������, else - �����.
--priority 	- ��������� [1,..) - 
--type_error 	- ��� ������: 1- ����������� (����������� ���������� ����������), else- ����� ������
--action_name 	- ��������� � prompt ����� ����������� �������. ���� �������� ������ ",", �� ������
--             	���������� � ������������� ��������� "%%" (%%action_name%%)
--script 	- pl/sql ����. ���� ���� ����� ������������� � begin <script> end; 
--		������ ������ ���������� � ������������� ��������� "%%" (%%script%%)
load data
--characterset AMERICAN_AMERICA.CL8MSWIN1251
characterset CL8MSWIN1251
infile 'update_journal.dat' "STR '\n'"
APPEND
CONTINUEIF last != "%"
into table update_journal
fields terminated by "," OPTIONALLY ENCLOSED BY '%%'
(id,is_before,priority,type_error,action_name,script char(4000))
