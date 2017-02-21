load data
--characterset AMERICAN_AMERICA.CL8MSWIN1251
infile 'entries.dat'
append
into table rtl_entries
FIELDS TERMINATED BY ","
(id char(16),
method_id char(16),
name char(100),
type char(1),
params char(10),
features char(10))
