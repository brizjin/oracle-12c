prompt constant2
create or replace package constant2 is
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/branches/PLATFORM-9550/IBS/CONSTNT_EXT1.SQL $
 *  $Author: vasiltsov $
 *  $Revision: 85747 $
 *  $Date:: 2015-11-11 09:47:25 #$
 */

--
  PRAGMA RESTRICT_REFERENCES ( constant2, WNDS, WNPS, RNDS, RNPS );

-- TYPE declarations
  type NSTRING_TABLE      is table of nvarchar2(16383) index by binary_integer;
  type NMEMO_TABLE        is table of nvarchar2(2000) index by binary_integer;
  type NSTRING_TABLE_S    is table of nvarchar2(16383)index by varchar2(128);
  type NMEMO_TABLE_S      is table of nvarchar2(4000) index by varchar2(128);

-- Type Size constants
  NSTR_PREC  constant pls_integer  := 128;
  NMEMO_PREC constant pls_integer  := 2000;

-- classes.base_class_id
  GENERIC_NSTRING  constant varchar2(20) := 'NSTRING';
  NMEMO       	   constant varchar2(20) := 'NMEMO';

end constant2;
/
sho err