def stats=--xrc_xmlparser.
def ws=dbms_output.put_line/*stdio.put_line_buf*/
def dump=/*dump*/null

prompt xrc_xmlparser body
create or replace package body
/*
 *	$HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/xmlprs2.sql $
 *  $Author: Alexey $
 *  $Revision: 15072 $
 *  $Date:: 2012-03-06 13:41:17 #$
 */
xrc_xmlparser is
/**
 * Internal error
 */
INTERNAL_ERR CONSTANT NUMBER := -20000;

/**
 * Other errors
 */
PARSE_ERR CONSTANT NUMBER := -20100;
FILE_ERR CONSTANT NUMBER := -20101;
CONN_ERR CONSTANT NUMBER := -20102;
NULL_ERR CONSTANT NUMBER := -20103;

timesFile varchar2(512);

type TimerRec is record (
	funcName varchar2(30),
    lastStart pls_integer,
    totalTime pls_integer := 0,
    count pls_integer := 0
);

type TimersTable is table of TimerRec index by binary_integer;
timers TimersTable;

/**
 * Package private methods
 */
PROCEDURE raise_app_error(ecode NUMBER, emesg VARCHAR2 := null) IS
BEGIN
   if ecode = PARSE_ERR then
      raise_application_error(ecode,
                              'Error occurred while parsing: ' || emesg);
   elsif ecode = FILE_ERR then
      raise_application_error(ecode,
                              'Error occurred while accessing a file or URL: '
                              || emesg);
   elsif ecode = CONN_ERR then
      raise_application_error(ecode,
                              'Error occurred while making connection: '
                              || emesg);
   elsif ecode = NULL_ERR then
      raise_application_error(ecode, 'Null input is not allowed');
   else
      raise_application_error(INTERNAL_ERR,
                              'An internal error has occurred: ' || emesg);
   end if;
END raise_app_error;

procedure initialize(err out varchar2)
    IS LANGUAGE C
    NAME "initialize" LIBRARY libxml WITH CONTEXT
    PARAMETERS(CONTEXT,
               err                 STRING,
               err     LENGTH      INT,
               err     MAXLEN      INT);

procedure initialize IS
   err VARCHAR2(2048);
BEGIN
   initialize(err);
   if err is not null then
      raise_app_error(INTERNAL_ERR, err);
   end if;
END initialize;

procedure enableTimers(enable boolean, logFile varchar2, err out varchar2)
    IS LANGUAGE C
    NAME "enableTimers" LIBRARY libxml
    PARAMETERS(enable              INT,
               logFile             STRING,
               logFile LENGTH      INT,
               logFile INDICATOR   INT,
               err                 STRING,
               err     LENGTH      INT,
               err     MAXLEN      INT);

procedure enableTimers(enable boolean, logFile varchar2) IS
   err VARCHAR2(2048);
BEGIN
   enableTimers(enable, logFile, err);
   if err is not null then
      raise_app_error(INTERNAL_ERR, err);
   end if;
   if enable then
      timesFile := logFile;
   else
      timesFile := null;
   end if;
   timers.delete;
END enableTimers;

function getHash(funcName varchar2) return binary_integer is
begin
	return dbms_utility.get_hash_value(funcName, 0, 128);
end;

procedure startTimer(funcName varchar2) is
    idx binary_integer := getHash(funcName);
begin
    timers(idx).funcName := funcName;
    timers(idx).lastStart := dbms_utility.get_time;
end;

procedure stopTimer(funcName varchar2) is
    idx binary_integer := getHash(funcName);
begin
    timers(idx).count := timers(idx).count + 1;
    timers(idx).totalTime := timers(idx).totalTime + (dbms_utility.get_time - timers(idx).lastStart);
end;

procedure dump is
	idx binary_integer;
	total pls_integer := 0;
begin
    idx := timers.first;
	while idx is not null loop
		if timers(idx).count > 0 then
			&&ws(timers(idx).funcName || ' tot: ' || timers(idx).totalTime
				|| ', cnt: ' || timers(idx).count
				|| ', avg: ' || (timers(idx).totalTime/timers(idx).count));
			total := total + timers(idx).totalTime;
		else
			&&ws(timers(idx).funcName || ' was not called');
		end if;
	    idx := timers.next(idx);
    end loop;
	&&ws('Total: ' || total);
end;

FUNCTION getReleaseVersion RETURN VARCHAR2 IS
BEGIN
   return '1.4.0.0';
END getReleaseVersion;

FUNCTION getJavaReleaseVersion RETURN VARCHAR2 IS
BEGIN
   raise_app_error(null, 'Not implemented');
--   return xmlparsercover.getJavaReleaseVersion;
END getJavaReleaseVersion;

FUNCTION parse(url VARCHAR2) RETURN xrc_xmldom.DOMDocument IS
   prs xrc_xmldom.Handle;
   doc xrc_xmldom.DOMDocument;
   err VARCHAR2(2048) := null;
BEGIN
   raise_app_error(null, 'Not implemented');
--   prs := xmlparsercover.newParser;
   raise_app_error(null, 'Not implemented');
--   xmlparsercover.parse(prs, url, err);
   if err is not null then
      raise_app_error(PARSE_ERR, err);
   end if;
   raise_app_error(null, 'Not implemented');
--   doc.ID := xmlparsercover.getDocument(prs);
   return doc;
END parse;

procedure newParser(id out xrc_xmldom.Handle)
    IS LANGUAGE C
    NAME "newParser" LIBRARY libxml
    PARAMETERS(id                  RAW,
               id      LENGTH      INT,
               id      MAXLEN      INT);

FUNCTION newParser RETURN Parser IS
   prs Parser;
BEGIN
   &&stats.startTimer('newParser');
   newParser(prs.ID);
   &&stats.stopTimer('newParser');
   return prs;
END newParser;

procedure parse(id xrc_xmldom.Handle, url VARCHAR2, err out VARCHAR2)
    IS LANGUAGE C
    NAME "parse" LIBRARY libxml WITH CONTEXT
    PARAMETERS(CONTEXT,
               id                  RAW,
               id      LENGTH      INT,
               url                 STRING,
               err                 STRING,
               err     LENGTH      INT,
               err     MAXLEN      INT);

PROCEDURE parse(p Parser, url VARCHAR2) IS
   err VARCHAR2(2048) := null;
BEGIN
   if p.ID is null then
      raise_app_error(NULL_ERR);
   end if;
   &&stats.startTimer('parse');
   parse(p.ID, url, err);
   &&stats.stopTimer('parse');
   if err is not null then
      raise_app_error(PARSE_ERR, err);
   end if;
END parse;

procedure parseBuffer(id xrc_xmldom.Handle, doc VARCHAR2, err out VARCHAR2)
    IS LANGUAGE C
    NAME "parseBuffer" LIBRARY libxml WITH CONTEXT
    PARAMETERS(CONTEXT,
               id                  RAW,
               id      LENGTH      INT,
               doc                 STRING,
               err                 STRING,
               err     LENGTH      INT,
               err     MAXLEN      INT);

PROCEDURE parseBuffer(p Parser, doc VARCHAR2) IS
   err VARCHAR2(2048) := null;
BEGIN
   if p.ID is null then
      raise_app_error(NULL_ERR);
   end if;
   &&stats.startTimer('parseBuffer');
   parseBuffer(p.ID, doc, err);
   &&stats.stopTimer('parseBuffer');
   if err is not null then
      raise_app_error(PARSE_ERR, err);
   end if;
END parseBuffer;

procedure parseClob(id xrc_xmldom.Handle, cl CLOB, err out VARCHAR2)
    IS LANGUAGE C
    NAME "parseClob" LIBRARY libxml WITH CONTEXT
    PARAMETERS(CONTEXT,
               id					RAW,
               id		LENGTH		INT,
               cl					OCILOBLOCATOR,
               cl		CHARSETID	UNSIGNED INT,
               cl		CHARSETFORM	UNSIGNED INT,
               err					STRING,
               err		LENGTH		INT,
               err		MAXLEN		INT);

PROCEDURE parseClob(p Parser, doc CLOB) IS
   err VARCHAR2(2048) := null;
BEGIN
   if p.ID is null or doc is null then
      raise_app_error(NULL_ERR);
   end if;
   &&stats.startTimer('parseClob');
   parseClob(p.ID, doc, err);
   &&stats.stopTimer('parseClob');
   if err is not null then
      raise_app_error(PARSE_ERR, err);
   end if;
END parseClob;

PROCEDURE parseBlob(p Parser, doc BLOB) IS
   err VARCHAR2(2048) := null;
   dest_offs pls_integer := 1;
   src_offs pls_integer := 1;
   warn pls_integer;
   lang_ctx PLS_INTEGER := dbms_lob.default_lang_ctx;
   scid pls_integer := 171;
   destclob clob;
BEGIN
   if p.ID is null or doc is null then
      raise_app_error(NULL_ERR);
   end if;
   --xrc_xmlparser.startTimer('parseBlob');
   dbms_lob.createtemporary(destclob,true);
   dbms_lob.convertToClob(destclob,doc,dbms_lob.LOBMAXSIZE,dest_offs,src_offs,scid,lang_ctx,warn);
   parseClob(p.ID,destclob, err);
   --xrc_xmlparser.stopTimer('parseBlob');
   if err is not null then
      raise_app_error(PARSE_ERR, err);
   end if;
END parseBlob;

PROCEDURE parseDTD(p Parser, url VARCHAR2, root VARCHAR2) IS
   err VARCHAR2(2048) := null;
BEGIN
   if p.ID is null then
      raise_app_error(NULL_ERR);
   end if;
   raise_app_error(null, 'Not implemented');
--   xmlparsercover.parseDTD(p.ID, url, root, err);
   if err is not null then
      raise_app_error(PARSE_ERR, err);
   end if;
END parseDTD;

PROCEDURE parseDTDBuffer(p Parser, dtd VARCHAR2, root VARCHAR2) IS
   err VARCHAR2(2048) := null;
BEGIN
   if p.ID is null then
      raise_app_error(NULL_ERR);
   end if;
   raise_app_error(null, 'Not implemented');
--   xmlparsercover.parseDTDBuffer(p.ID, dtd, root, err);
   if err is not null then
      raise_app_error(PARSE_ERR, err);
   end if;
END parseDTDBuffer;

PROCEDURE parseDTDClob(p Parser, dtd CLOB, root VARCHAR2) IS
   err VARCHAR2(2048) := null;
BEGIN
   if p.ID is null or dtd is null then
      raise_app_error(NULL_ERR);
   end if;
   raise_app_error(null, 'Not implemented');
--   xmlparsercover.parseDTDClob(p.ID, dtd, root, err);
   if err is not null then
      raise_app_error(PARSE_ERR, err);
   end if;
END parseDTDClob;

PROCEDURE setBaseDir(p Parser, dir VARCHAR2) IS
   err VARCHAR2(2048) := null;
   len number;
   lastchr varchar2(1);
BEGIN
   if p.ID is null then
      raise_app_error(NULL_ERR);
   end if;
   len := length(dir);
   lastchr := substr(dir, len, 1);
   if lastchr != '/' then
   raise_app_error(null, 'Not implemented');
--      xmlparsercover.setBaseURL(p.ID, dir || '/', err);
   else
   raise_app_error(null, 'Not implemented');
--      xmlparsercover.setBaseURL(p.ID, dir, err);
   end if;
   if err is not null then
      raise_app_error(FILE_ERR, err);
   end if;
END setBaseDir;

/**
 * Sets warnings TRUE - on, FALSE - off
 */
PROCEDURE showWarnings(p Parser, yes BOOLEAN) IS
   warn NUMBER;
BEGIN
   if p.ID is null then
      raise_app_error(NULL_ERR);
   end if;
   if yes = TRUE then
      warn := 1;
   else
      warn := 0;
   end if;
   raise_app_error(null, 'Not implemented');
--   xmlparsercover.showWarnings(p.ID, warn);
END showWarnings;

procedure freeParser(id xrc_xmldom.Handle)
    IS LANGUAGE C
    NAME "freeParser" LIBRARY libxml
    PARAMETERS(id                  RAW,
               id      LENGTH      INT);

PROCEDURE freeParser(p Parser) IS
BEGIN
   if p.ID is null then
      raise_app_error(NULL_ERR);
   end if;
   &&stats.startTimer('freeParser');
   freeParser(p.ID);
   &&stats.stopTimer('freeParser');
   if timesFile is not null then
     &&dump;
   end if;
END freeParser;

PROCEDURE setErrorLog(p Parser, fileName VARCHAR2) IS
BEGIN
   if p.ID is null then
      raise_app_error(NULL_ERR);
   end if;
   raise_app_error(null, 'Not implemented');
--   xmlparsercover.setErrorLog(p.ID, fileName);
END setErrorLog;

procedure setValidationMode(id xrc_xmldom.Handle, yes PLS_INTEGER)
    IS LANGUAGE C
    NAME "setValidationMode" LIBRARY libxml
    PARAMETERS(id                  RAW,
               id      LENGTH      INT,
               yes                 INT);

PROCEDURE setValidationMode(p Parser, yes BOOLEAN) IS
   valid PLS_INTEGER;
BEGIN
   if p.ID is null then
      raise_app_error(NULL_ERR);
   end if;
   if yes = TRUE then
      valid := 1;
   else
      valid := 0;
   end if;
   setValidationMode(p.ID, valid);
END setValidationMode;

PROCEDURE setPreserveWhitespace(p Parser, yes BOOLEAN) IS
   valid NUMBER;
BEGIN
   if p.ID is null then
      raise_app_error(NULL_ERR);
   end if;
   if yes = TRUE then
      valid := 1;
   else
      valid := 0;
   end if;
   raise_app_error(null, 'Not implemented');
--   xmlparsercover.setPreserveWhitespace(p.ID, valid);
END setPreserveWhitespace;

procedure getValidationMode(id xrc_xmldom.Handle, yes out PLS_INTEGER)
    IS LANGUAGE C
    NAME "getValidationMode" LIBRARY libxml
    PARAMETERS(id                  RAW,
               id      LENGTH      INT,
               yes                 INT);

FUNCTION getValidationMode(p Parser) RETURN BOOLEAN IS
   valid PLS_INTEGER;
BEGIN
   if p.ID is null then
      raise_app_error(NULL_ERR);
   end if;
   getValidationMode(p.ID, valid);
   if valid = 1 then
      return TRUE;
   else
      return FALSE;
   end if;
END getValidationMode;

/**
 * Sets DTD for validation purposes - MUST be before an xml document is parsed
 */
PROCEDURE setDoctype(p Parser, dtd xrc_xmldom.DOMDocumentType) is
BEGIN
   if p.ID is null then
      raise_app_error(NULL_ERR);
   end if;
   if dtd.ID is null then
      raise_app_error(NULL_ERR);
   end if;
   raise_app_error(null, 'Not implemented');
--   xmlparsercover.setDoctype(p.ID, dtd.ID);
END setDoctype;

/**
 * Gets DTD parsed - MUST be called only after a dtd is parsed
 */
FUNCTION getDoctype(p Parser) RETURN xrc_xmldom.DOMDocumentType is
   err VARCHAR2(2048) := null;
   dtd xrc_xmldom.DOMDocumentType;
BEGIN
   if p.ID is null then
      raise_app_error(NULL_ERR);
   end if;
   raise_app_error(null, 'Not implemented');
--   dtd.ID := xmlparsercover.getDoctype(p.ID);
   return dtd;
END getDoctype;

procedure getDocument(id xrc_xmldom.Handle, doc out xrc_xmldom.Handle)
    IS LANGUAGE C
    NAME "getDocument" LIBRARY libxml
    PARAMETERS(id                  RAW,
               id      LENGTH      INT,
               doc                 RAW,
               doc     LENGTH      INT,
               doc     MAXLEN      INT);

FUNCTION getDocument(p Parser) RETURN xrc_xmldom.DOMDocument IS
   doc xrc_xmldom.DOMDocument;
BEGIN
   if p.ID is null then
      raise_app_error(NULL_ERR);
   end if;
   &&stats.startTimer('getDocument');
   getDocument(p.ID, doc.ID);
   &&stats.stopTimer('getDocument');
   return doc;
END getDocument;

procedure encodeBase64(cl IN OUT CLOB, overwrite PLS_INTEGER, err out varchar2)
    IS LANGUAGE C
    NAME "encodeBase64" LIBRARY libxml WITH CONTEXT
    PARAMETERS(CONTEXT,
               cl						OCILOBLOCATOR,
               cl			CHARSETID	UNSIGNED INT,
               cl			CHARSETFORM	UNSIGNED INT,
               overwrite				INT,
               err						STRING,
               err			LENGTH		INT,
               err			MAXLEN		INT);

PROCEDURE encodeBase64(cl IN OUT CLOB, overwrite BOOLEAN := true) IS
   err VARCHAR2(2048);
   over PLS_INTEGER;
BEGIN
   if cl is null then
      raise_app_error(NULL_ERR);
   end if;
   if overwrite = TRUE then
      over := 1;
   else
      over := 0;
   end if;
   &&stats.startTimer('encodeBase64');
   encodeBase64(cl, over, err);
   &&stats.stopTimer('encodeBase64');
   if err is not null then
      raise_app_error(FILE_ERR, err);
   end if;
END encodeBase64;

procedure decodeBase64(cl IN OUT CLOB, overwrite PLS_INTEGER, err out varchar2)
    IS LANGUAGE C
    NAME "decodeBase64" LIBRARY libxml WITH CONTEXT
    PARAMETERS(CONTEXT,
               cl						OCILOBLOCATOR,
               cl			CHARSETID	UNSIGNED INT,
               cl			CHARSETFORM	UNSIGNED INT,
               overwrite				INT,
               err						STRING,
               err			LENGTH		INT,
               err			MAXLEN		INT);

PROCEDURE decodeBase64(cl IN OUT CLOB, overwrite BOOLEAN := true) IS
   err VARCHAR2(2048);
   over PLS_INTEGER;
BEGIN
   if cl is null then
      raise_app_error(NULL_ERR);
   end if;
   if overwrite = TRUE then
      over := 1;
   else
      over := 0;
   end if;
   &&stats.startTimer('decodeBase64');
   decodeBase64(cl, over, err);
   &&stats.stopTimer('decodeBase64');
   if err is not null then
      raise_app_error(FILE_ERR, err);
   end if;
END decodeBase64;

end;
/
show errors package body xrc_xmlparser

