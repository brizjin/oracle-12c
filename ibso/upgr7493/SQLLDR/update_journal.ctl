--id		- первичный ключ 
--is_before	- 1 - выполнять до наката пакетов, else - после.
--priority 	- приоритет [1,..) - 
--type_error 	- тип ошибки: 1- критическая (прекращение выполнения обновления), else- игнор ошибки
--action_name 	- выводится в prompt перед выполнением скрипта. если содержит символ ",", то должно
--             	начинаться и заканчиваться символами "%%" (%%action_name%%)
--script 	- pl/sql блок. этот блок будет оборачиваться в begin <script> end; 
--		всегда должно начинаться и заканчиваться символами "%%" (%%script%%)
load data
--characterset AMERICAN_AMERICA.CL8MSWIN1251
characterset CL8MSWIN1251
infile 'update_journal.dat' "STR '\n'"
APPEND
CONTINUEIF last != "%"
into table update_journal
fields terminated by "," OPTIONALLY ENCLOSED BY '%%'
(id,is_before,priority,type_error,action_name,script char(4000))
