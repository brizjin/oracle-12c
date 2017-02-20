prompt ADMIN_MGR body
CREATE OR REPLACE PACKAGE BODY
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/adm_mgr2.sql $
 *  $Author: tfsservice $
 *  $Revision: 56518 $
 *  $Date:: 2014-11-27 17:42:59 #$
 */
ADMIN_MGR wrapped 
a000000
ab
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
b
97f 35b
SWAekTiCmHj86pfg/Bx0MVSWCn0wgzsr2eIGfHSQKg/upMNqymfs17i+CYNFbGYue9zhaFyq
RtBPGim2BDUyk2feisd+LNq9bAxKVoDjXJJEVmJT2BhuqR4x2BSNcCe9+5Z1VNaN+dVvY7Xi
4Gvx7xTmlff+RFC44Il2BHkfBYEjpM3Jf4txPKckElqG5uo8uK/XscVew3xebFnj8v2c3eIy
6988QG8j+gEwG1ujfjzM/iIP14x9wRub50GvuEKdOelznkdk6jv/0ykjgYtyEk60J8t96wJh
o4/pNz4XubEOySwEAtSDtwSx5wlcbAi2H3WM4s1lMvrNyfmtyEh4EwErG0DVva3sxYYaLmxT
oknlr20pFF+pUFTxVeZQdYQ+9ZVjUjdNH3USQ+Y4Nxe98H6zZC7Vjs+KOGkL8PMWx8cRZ7N8
Tv833gOPDLT5h7EzGzvoLnmg19NTgoZsryXqwXZy0S8WH0r1LKA1DNWiLxfYFbmfXbmLO7HG
KbOntRpMrgPlgF6TXqMDwE9QyJj59V/MYtuqcP+Z9BhNuxDrzrxLRlBDVPfTTaQg8uX1E3Lt
f70+yUeeHUBWSid2OYT64DcuD04jQP44UFvN1w5ruacOnPWHus85Px9dzd9N2GDseEPtj4dP
b7bkzcNn+reGGl+KkTbu9PYqRMzojGWSpILbQBsk985E/lJNH32w4dSs7dM4ZQZgBurxqwxo
8DrGwdd1KDHA4CVobc2QX6tBM7iLiy/ie2mB+qVN+Ch94V159WHuErZMfdn4wvbOGaKxdK8F
GLK2m7JFMzy4vy2de1U77CYH9a8QWbEgkj6qREBJnZjTaCW5xiS20hIw

/
sho err package body admin_mgr
var s varchar2(100)
begin
  if admin_mgr.owner <> admin_mgr.sowner then
    :s := 'grant execute on admin_mgr to '||admin_mgr.owner;
    execute immediate :s;
  end if;
end;
/
print s
