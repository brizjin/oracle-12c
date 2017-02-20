prompt runproc_pkg
create or replace package runproc_pkg as
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/Runproc1.sql $
 *  $Author: verkhovskiy $
 *  $Revision: 34686 $
 *  $Date:: 2013-12-12 16:29:22 #$
 */
  -- BUFTYPE = 'B' - PL/SQL блок
  --           'E' - экспорт
  --           'I' - импорт
  --
  --  для совместимоcти со старым runproc'ом
  function GET_MSG(     PIPENAME    in  varchar2   -- имя pipe
                       ,BUF         out nocopy varchar2   -- запрос
                       ,BUFTYPE     out nocopy varchar2   -- тип запроса
    )return number;
--
  function GET_MSG(     PIPENAME    in  varchar2   -- имя pipe
                       ,BUF         out nocopy varchar2   -- запрос
                       ,BUFTYPE     out nocopy varchar2   -- тип запроса
                       ,ID          out nocopy varchar2)  -- ID запроса
    return number;
--
    function Put_Query(     pText   varchar2
                           ,pId     varchar2
                           ,pCode   varchar2 := null
                           ,pMaxFailures number := null
    ) return number;
--
  function PUT_MSG( PIPENAME in varchar2, MSG in  varchar2 ) return number;
--
  function PUT_MESS(     MSG in varchar2, pID in  varchar2 ) return number;
--
  function PUT_END(     MSG     in  varchar2
                       ,CODE    in  varchar2
                       ,pID     in  varchar2 ) return number;
--
    procedure PUT_COMMAND(p_cmd varchar2);
    function  TEST_SERVER return boolean;
    procedure STOP_SERVER(p_quit boolean default false);
    procedure GET_QUEUE( p_id      in out nocopy varchar2,
                         p_status  in out nocopy pls_integer,
                         p_timeout pls_integer default null);
--
    function AddQuery( pText   varchar2,
                       pTime   date     default null,
                       pCode   varchar2 default null,
                       pType   varchar2 default null,
                       pMaxFailures number default null) return number;
    procedure DropQuery(    pType   varchar2
                           ,pId     varchar2 );
    procedure CheckQuery(   pType   varchar2
                           ,pId     varchar2 );
    procedure UpdQuery(  pId     varchar2,
                         pDate   date,
                         pBroken varchar2,
                         pCheck  boolean default false,
                         pFail   number  default null,
                         pMaxFailures number default null );
    procedure ExecQuery(  pId     varchar2 );
--
end runproc_pkg;
/
sho err

