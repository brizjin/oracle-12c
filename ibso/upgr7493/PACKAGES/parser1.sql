prompt plp$parser
create or replace package plp$parser is

/*
 *	$HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/parser1.sql $
 *  $Author: vasiltsov $
 *  $Revision: 86610 $
 *  $Date:: 2015-11-23 13:36:43 #$
 */
 
--# line 2 "plp.y"
/*
 *	_HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/trunk/IBS/PLP.Y 
 *  _Author: vasiltsov 
 *  _Revision: 86608 
 *  _Date:: 2015-11-23 13:25:09 #
 *	_HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/trunk/IBS/plp.l 
 *  _Author: vasiltsov 
 *  _Revision: 85998 
 *  _Date:: 2015-11-13 12:30:42
 */
--
/* $NoKeywords: $ */
--

--# line 18 "PLP.Y"
type YYSTYPE is record (
 
    node    pls_integer  := NULL,
    text    varchar2(2000)  := NULL, -- original text of symbol
    line    pls_integer  := NULL,
    pos     pls_integer  := NULL

);
PRAGMA_ constant pls_integer := 257;
PROCEDURE_ constant pls_integer := 258;
FUNCTION_ constant pls_integer := 259;
TEXT_ constant pls_integer := 260;
PUBLIC_ constant pls_integer := 261;
DECLARE_ constant pls_integer := 262;
BEGIN_ constant pls_integer := 263;
EXCEPTION_ constant pls_integer := 264;
WHEN_ constant pls_integer := 265;
END_ constant pls_integer := 266;
RECORD_ constant pls_integer := 267;
CURSOR_ constant pls_integer := 268;
FUNCPROP_ constant pls_integer := 269;
VARRAY_ constant pls_integer := 270;
NUMBER_ constant pls_integer := 271;
INTEGER_ constant pls_integer := 272;
DATE_ constant pls_integer := 273;
BOOLEAN_ constant pls_integer := 274;
STRING_ constant pls_integer := 275;
NSTRING_ constant pls_integer := 276;
RAW_ constant pls_integer := 277;
LONG_ constant pls_integer := 278;
ROWID_ constant pls_integer := 279;
LOB_ constant pls_integer := 280;
TIMESTAMP_ constant pls_integer := 281;
INTERVAL_ constant pls_integer := 282;
ID_ constant pls_integer := 283;
DBOBJECT_ constant pls_integer := 284;
STRING_CONST_ constant pls_integer := 285;
DIGIT_ constant pls_integer := 286;
BOOLEAN_CONST_ constant pls_integer := 287;
NUMBER_CONST_ constant pls_integer := 288;
IF_ constant pls_integer := 289;
THEN_ constant pls_integer := 290;
ELSIF_ constant pls_integer := 291;
ELSE_ constant pls_integer := 292;
CASE_ constant pls_integer := 293;
LOOP_ constant pls_integer := 294;
WHILE_ constant pls_integer := 295;
FOR_ constant pls_integer := 296;
EXIT_ constant pls_integer := 297;
REVERSE_ constant pls_integer := 298;
CONTINUE_ constant pls_integer := 299;
SAVEPOINT_ constant pls_integer := 300;
ROLLBACK_ constant pls_integer := 301;
COMMIT_ constant pls_integer := 302;
SELECT_ constant pls_integer := 303;
UPDATE_ constant pls_integer := 304;
GROUP_ constant pls_integer := 305;
HAVING_ constant pls_integer := 306;
DELETE_ constant pls_integer := 307;
CONNECT_ constant pls_integer := 308;
START_ constant pls_integer := 309;
LOCATE_ constant pls_integer := 310;
EXACT_ constant pls_integer := 311;
WHERE_ constant pls_integer := 312;
LOCK_ constant pls_integer := 313;
NOWAIT_ constant pls_integer := 314;
WAIT_ constant pls_integer := 315;
ALL_ constant pls_integer := 316;
COLL_ constant pls_integer := 317;
ONE_ constant pls_integer := 318;
ANY_ constant pls_integer := 319;
EXISTS_ constant pls_integer := 320;
INDEX_ constant pls_integer := 321;
LABEL_ constant pls_integer := 322;
RETURN_ constant pls_integer := 323;
CONSTANT_ constant pls_integer := 324;
DEFAULT_ constant pls_integer := 325;
NOSTATIC_ constant pls_integer := 326;
INSERT_ constant pls_integer := 327;
INTO_ constant pls_integer := 328;
ORDER_ constant pls_integer := 329;
BY_ constant pls_integer := 330;
ASC_ constant pls_integer := 331;
DESC_ constant pls_integer := 332;
NULL_ constant pls_integer := 333;
GOTO_ constant pls_integer := 334;
RAISE_ constant pls_integer := 335;
TO_ constant pls_integer := 336;
PERIODS_ constant pls_integer := 337;
TYPE_ constant pls_integer := 338;
REF_ constant pls_integer := 339;
OTHERS_ constant pls_integer := 340;
VAR_ constant pls_integer := 341;
ASSIGN_ constant pls_integer := 342;
SETPAR_ constant pls_integer := 343;
UNION_ constant pls_integer := 344;
MINUS_ constant pls_integer := 345;
INTERSECT_ constant pls_integer := 346;
TABLE_ constant pls_integer := 347;
OR_ constant pls_integer := 348;
AND_ constant pls_integer := 349;
NOT_ constant pls_integer := 350;
IS_ constant pls_integer := 351;
LIKE_ constant pls_integer := 352;
IN_ constant pls_integer := 353;
OUT_ constant pls_integer := 354;
ESCAPE_ constant pls_integer := 355;
OF_ constant pls_integer := 356;
NE_ constant pls_integer := 357;
GE_ constant pls_integer := 358;
LE_ constant pls_integer := 359;
CONCAT_ constant pls_integer := 360;
PRIOR_ constant pls_integer := 361;
DISTINCT_ constant pls_integer := 362;
POWER_ constant pls_integer := 363;
OBJ_TYPE_ constant pls_integer := 364;
OBJ_ID_ constant pls_integer := 365;
OBJ_COLLECTION_ constant pls_integer := 366;
OBJ_STATE_ constant pls_integer := 367;
OBJ_CLASS_ constant pls_integer := 368;
OBJ_PARENT_ constant pls_integer := 369;
OBJ_CLASS_ENTITY_ constant pls_integer := 370;
OBJ_CLASS_PARENT_ constant pls_integer := 371;
OBJ_INIT_ constant pls_integer := 372;
class_ref_ constant pls_integer := 373;
OBJECT_REF_ constant pls_integer := 374;
LOCK_REF_ constant pls_integer := 375;
BLOCK_ constant pls_integer := 376;
SOS_ constant pls_integer := 377;
INVALID_ constant pls_integer := 378;
UNKNOWN_ constant pls_integer := 379;
MODIFIER_ constant pls_integer := 380;
ATTR_ constant pls_integer := 381;
METHOD_ constant pls_integer := 382;
VARMETH_ constant pls_integer := 383;
RTL_ constant pls_integer := 384;
RELATIONAL_ constant pls_integer := 385;
NUMLOW_ constant pls_integer := 386;
NUMHIGH_ constant pls_integer := 387;
MEMO_ constant pls_integer := 388;
NMEMO_ constant pls_integer := 389;
COLLECTION_ constant pls_integer := 390;
DBCLASS_ constant pls_integer := 391;

--# line 136 "PLP.Y"
	-- package header
	function yylex return pls_integer;
	yylval YYSTYPE;
	function  yyparse return pls_integer;
end;
/
show errors
