prompt rcs_lock
create or replace package rcs_lock is
/*
 *	$HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/RCS_LCK1.SQL $
 *  $Author: Alexey $
 *  $Revision: 15072 $
 *  $Date:: 2012-03-06 13:41:17 #$
 */
---------------------
REQUEST_TIMEOUT exception;
pragma exception_init(REQUEST_TIMEOUT, -20991);
---------------------
--  SPECIAL CONSTANTS
--
NL_MODE  constant integer := dbms_lock.nl_mode ;
SS_MODE  constant integer := dbms_lock.ss_mode ;
SX_MODE  constant integer := dbms_lock.sx_mode ;
S_MODE   constant integer := dbms_lock.s_mode  ;
SSX_MODE constant integer := dbms_lock.ssx_mode;
X_MODE   constant integer := dbms_lock.x_mode  ;
--dbms_lock.nl_mode  constant integer := 1;
--dbms_lock.ss_mode  constant integer := 2;	-- Also called 'Intended Share'
--dbms_lock.sx_mode  constant integer := 3;	-- Also called 'Intended Exclusive'
--dbms_lock.s_mode   constant integer := 4;
--dbms_lock.ssx_mode constant integer := 5;
--dbms_lock.x_mode   constant integer := 6;
--  These are the various lock modes (nl -> "NuLl", ss -> "Sub Shared",
--  sx -> "Sub eXclusive", s -> "Shared", ssx -> "Shared Sub eXclusive",
--  x -> "eXclusive").
--
--  A sub-share lock can be used on an aggregate object to indicate that
--  share locks are being aquired on sub-parts of the object.  Similarly, a
--  sub-exclusive lock can be used on an aggregate object to indicate
--  that exclusive locks are being aquired on sub-parts of the object.  A
--  share-sub-exclusive lock indicates that the entire aggregate object
--  has a share lock, but some of the sub-parts may additionally have
--  exclusive locks.
--
--  Lock Compatibility Rules:
--  When another process holds "held", an attempt to get "get" does
--  the following:
--
--  held  get->  NL   SS   SX   S    SSX  X
--  NL           SUCC SUCC SUCC SUCC SUCC SUCC
--  SS           SUCC SUCC SUCC SUCC SUCC fail
--  SX           SUCC SUCC SUCC fail fail fail
--  S            SUCC SUCC fail SUCC fail fail
--  SSX          SUCC SUCC fail fail fail fail
--  X            SUCC fail fail fail fail fail
--
MAXWAIT	constant integer := dbms_lock.maxwait;
-- dbms_lock.maxwait  constant integer := 32767;
-- maxwait means to wait forever

-- Information on user, who locked the resource
orauser		varchar2(30);
userid		varchar2(16);
sessionid	number;
locktime	number;
username	varchar2(256);
usermachine	varchar2(256);
message     varchar2(2000);
status      integer;

----------------------------
--  PROCEDURES AND FUNCTIONS
--
procedure request(
    lock_name   in varchar2,
    lock_mode   in integer  default X_MODE,
    timeout     in integer  default 0,
    release_on_commit in boolean default FALSE,
    p_skip_4    in boolean  default FALSE,
    p_prefix    in varchar2 default null
    );

procedure release(lock_name varchar2, p_skip_4 boolean default FALSE);
procedure sleep(seconds in number);

end;
/
sho err

