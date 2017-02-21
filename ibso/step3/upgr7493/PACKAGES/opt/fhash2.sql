prompt forhash body
CREATE OR REPLACE PACKAGE BODY
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/fhash2.sql $
 *  $Author: Alexey $
 *  $Revision: 15072 $
 *  $Date:: 2012-03-06 13:41:17 #$
 */
forhash is
--
function  init( passwd  varchar2, filename varchar2 ) return pls_integer
  IS LANGUAGE C
    NAME "hashinit" LIBRARY libhash
    PARAMETERS (passwd             STRING,
                passwd   INDICATOR SHORT,
                passwd   LENGTH    SIZE_T,
                filename           STRING,
                filename INDICATOR SHORT,
                RETURN             INT);
--
function  initr( passwd  raw, filename varchar2 ) return pls_integer
  IS LANGUAGE C
    NAME "hashinit" LIBRARY libhash
    PARAMETERS (passwd             RAW,
                passwd   INDICATOR SHORT,
                passwd   LENGTH    SIZE_T,
                filename           STRING,
                filename INDICATOR SHORT,
                RETURN             INT);
--
function  uninit return pls_integer
  IS LANGUAGE C
    NAME "hashuninit" LIBRARY libhash
    PARAMETERS (RETURN             INT);
--
function  calcr(client varchar2, indate varchar2, buf raw, res in out nocopy raw) return pls_integer
  IS LANGUAGE C
    NAME "hashcalc" LIBRARY libhash
    PARAMETERS (client             STRING,
                client   INDICATOR SHORT,
                indate             STRING,
                indate   INDICATOR SHORT,
                buf                RAW,
                buf      INDICATOR SHORT,
                buf      LENGTH    SIZE_T,
                res                RAW,
                res      INDICATOR SHORT,
                res      LENGTH    SIZE_T,
                res      MAXLEN    SIZE_T,
                RETURN             INT);
--
procedure err_msg(err pls_integer, msg in out nocopy varchar2)
  IS LANGUAGE C
    NAME "err_msg" LIBRARY libhash
    PARAMETERS (err                INT,
                err      INDICATOR SHORT,
                msg                STRING,
                msg      INDICATOR SHORT,
                msg      LENGTH    SIZE_T,
                msg      MAXLEN    SIZE_T);
--
procedure close is begin null; end;
--
procedure open  is begin null; end;
--
function  calc (client varchar2, indate varchar2, buf varchar2, res out varchar2) return pls_integer is
    i   pls_integer;
    r   raw(100);
begin
    i := calcr(client,indate,buf,r);
    res := r;
    return i;
end;
--
END forhash;
/
sho err package body forhash

