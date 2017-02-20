load data
--characterset AMERICAN_AMERICA.CL8MSWIN1251
--delete project where type in ('PACKAGE','TABLE','SEQUENCE')
characterset CL8MSWIN1251
infile 'project.dat'
append
into table PROJECT
FIELDS TERMINATED BY "|"
(
  type  char(16),
  loaddata char(1),
  name  char(30),
  notes char(200)
)
