load data
--characterset AMERICAN_AMERICA.CL8MSWIN1251
infile 'params.dat'
append
into table RTL_PARAMETERS
FIELDS TERMINATED BY ","
(rtl_id char(16),
pos char(5),
par_name char(30),
dir char(1),
flag char(1),
class_id char(16),
siz char(10),
prec char(10))
