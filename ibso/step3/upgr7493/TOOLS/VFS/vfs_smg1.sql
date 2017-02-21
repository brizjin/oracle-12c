prompt package vfs_storage_mgr
create or replace package vfs_storage_mgr as
/*
 *	$HeadURL: http://hades.ftc.ru:7382/svn/pltm2/Core/Utils/EXT/vfs_smg1.sql $
 *	$Author: Alexey $
 *	$Revision: 15082 $
 *	$Date:: 2012-03-06 17:34:34 #$
 */

 MAXEXTENTS_UNLIMITED constant integer := 0;
 LOGGING_LOGGING      constant char(7) := 'LOGGING';
 LOGGING_NOLOGGING    constant char(9) := 'NOLOGGING';
 BUFFER_POOL_KEEP     constant char(4) := 'KEEP';
 BOFFER_POOL_RECYCLE  constant char(7) := 'RECYCLE';
 BUFFER_POOL_DEFAULT  constant char(7) := 'DEFAULT';

 ----------------------------------------------------------
 function create_storage(apartition_name in varchar2 default null, adescription in varchar2 default null,
  atablespace_name in varchar2 default null,
  --lob parameters
  achunk in integer default null, apctversion in integer default null, alogging in varchar2 default null,
  --storage parameters
  ainitial in integer default null, anext in integer default null, apctincrease in integer default null,
  aminextents in integer default null, amaxextents in integer default null,
  afreelist_groups in integer default null, afreelists in integer default null,
  abuffer_pool in varchar2 default null
  ) return integer;
 ----------------------------------------------------------
 function get_storage_partition_name(aid in integer default null) return varchar2;
 ----------------------------------------------------------
 function drop_storage(aid in integer default null) return pls_integer;
 function drop_storage(apartition_name in varchar2) return pls_integer;
 ----------------------------------------------------------
 function modify_storage(aid in integer default null,
  apctversion in integer default null, alogging in varchar2 default null,
  anext in integer default null, apctincrease in integer default null,
  amaxextents in integer default null,
  afreelists in integer default null,
  abuffer_pool in varchar2 default null) return pls_integer;
 function modify_storage(apartition_name in varchar2,
  apctversion in integer default null, alogging in varchar2 default null,
  anext in integer default null, apctincrease in integer default null,
  amaxextents in integer default null,
  afreelists in integer default null,
  abuffer_pool in varchar2 default null) return pls_integer;
 ----------------------------------------------------------
 function move_storage(aid in integer default null,
  atablespace_name in varchar2 default null,
  achunk in integer default null, apctversion in integer default null, alogging in varchar2 default null,
  ainitial in integer default null, anext in integer default null, apctincrease in integer default null,
  aminextents in integer default null, amaxextents in integer default null,
  afreelist_groups in integer default null, afreelists in integer default null,
  abuffer_pool in varchar2 default null) return pls_integer;
 function move_storage(apartition_name in varchar2,
  atablespace_name in varchar2 default null,
  achunk in integer default null, apctversion in integer default null, alogging in varchar2 default null,
  ainitial in integer default null, anext in integer default null, apctincrease in integer default null,
  aminextents in integer default null, amaxextents in integer default null,
  afreelist_groups in integer default null, afreelists in integer default null,
  abuffer_pool in varchar2 default null) return pls_integer;
 ----------------------------------------------------------
 function set_storage_description(aid in integer, adescription in varchar2) return pls_integer;
 ----------------------------------------------------------
 function set_default(aid in integer) return pls_integer;
 ----------------------------------------------------------
 function get_default return integer;
 ----------------------------------------------------------

end;
/
sho err
