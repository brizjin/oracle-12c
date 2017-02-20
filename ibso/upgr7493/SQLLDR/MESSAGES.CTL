load data
--characterset AMERICAN_AMERICA.CL8MSWIN1251
characterset CL8MSWIN1251
infile 'messages.dat'
--replace
append
concatenate 2
--continueif this(1:1)!=' '
into table messages (
topic char(16) terminated by whitespace,
code char(30) terminated by "," "ltrim(rtrim(:code))",
text char(1000)
)
