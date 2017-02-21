prompt forhash
CREATE OR REPLACE PACKAGE forhash IS
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/fhash1.sql $
 *  $Author: Alexey $
 *  $Revision: 15072 $
 *  $Date:: 2012-03-06 13:41:17 #$
 */
--
    procedure close;
    procedure open;
    function  init( passwd  varchar2, filename varchar2 ) return pls_integer;
    function  initr( passwd  raw, filename varchar2 ) return pls_integer;
    function  uninit return pls_integer;
    function  calc (client varchar2, indate varchar2, buf varchar2, res out varchar2) return pls_integer;
    function  calcr(client varchar2, indate varchar2, buf raw, res in out nocopy raw) return pls_integer;
    procedure err_msg(err pls_integer, msg in out nocopy varchar2);
--
end forhash;
/
show errors

