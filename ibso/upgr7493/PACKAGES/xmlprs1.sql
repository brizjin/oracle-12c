prompt xrc_xmlparser body
create or replace package xrc_xmlparser as
/*
 *	$HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/xmlprs1.sql $
 *  $Author: Alexey $
 *  $Revision: 15072 $
 *  $Date:: 2012-03-06 13:41:17 #$
 */

/**
 * Parser interface type
 */
TYPE Parser IS RECORD ( ID xrc_xmldom.Handle );

PROCEDURE initialize;

procedure enableTimers(enable boolean, logFile varchar2);
procedure startTimer(funcName varchar2);
procedure stopTimer(funcName varchar2);
procedure dump;

/**
 * Return the release version of the Oracle XML Parser for PL/SQL
 */
FUNCTION getReleaseVersion RETURN VARCHAR2;

/**
 * Return the release version of the underlying Oracle XML Parser for Java
 */
FUNCTION getJavaReleaseVersion RETURN VARCHAR2;

/**
 * Parses xml stored in the given url/file and returns the built DOM Document
 */
FUNCTION parse(url VARCHAR2) RETURN xrc_xmldom.DOMDocument;

/**
 * Returns a new parser instance
 */
FUNCTION newParser RETURN Parser;

PROCEDURE freeParser(p Parser);

/**
 * Parses xml stored in the given url/file
 */
PROCEDURE parse(p Parser, url VARCHAR2);

/**
 * Parses xml stored in the given buffer
 */
PROCEDURE parseBuffer(p Parser, doc VARCHAR2);

/**
 * Parses xml stored in the given clob
 */
PROCEDURE parseClob(p Parser, doc CLOB);

/**
* Parses xml stored in the given blob
*/
PROCEDURE parseBlob(p Parser, doc BLOB);

/**
 * Parses the given dtd
 */
PROCEDURE parseDTD(p Parser, url VARCHAR2, root VARCHAR2);

/**
 * Parses the given dtd
 */
PROCEDURE parseDTDBuffer(p Parser, dtd VARCHAR2, root VARCHAR2);

/**
 * Parses the given dtd
 */
PROCEDURE parseDTDClob(p Parser, dtd CLOB, root VARCHAR2);

/**
 * Sets base directory used to resolve relative urls
 */
PROCEDURE setBaseDir(p Parser, dir VARCHAR2);

/**
 * Sets warnings TRUE - on, FALSE - off
 */
PROCEDURE showWarnings(p Parser, yes BOOLEAN);

/**
 * Sets errors to be sent to the specified file
 */
PROCEDURE setErrorLog(p Parser, fileName VARCHAR2);

/**
 * Sets whitespace preserving mode TRUE - on, FALSE - off
 */
PROCEDURE setPreserveWhitespace(p Parser, yes BOOLEAN);

/**
 * Sets validation mode TRUE - validating, FALSE - non validation
 */
PROCEDURE setValidationMode(p Parser, yes BOOLEAN);

/**
 * Gets validation mode
 */
FUNCTION getValidationMode(p Parser) RETURN BOOLEAN;

/**
 * Sets DTD for validation purposes - MUST be before an xml document is parsed
 */
PROCEDURE setDoctype(p Parser, dtd xrc_xmldom.DOMDocumentType);

/**
 * Gets DTD parsed - MUST be called only after a dtd is parsed
 */
FUNCTION getDoctype(p Parser) RETURN xrc_xmldom.DOMDocumentType;

/**
 * Gets DOM Document built by the parser - MUST be called only after a
 * document is parsed
 */
FUNCTION getDocument(p Parser) RETURN xrc_xmldom.DOMDocument;

/**
 * Encodes octets into Base64 data.
 * If overwrite is not true, creates new temporary clob and overwrites LOB locator,
 * it is responsibility of the caller to free this new temporary clob.
 */
PROCEDURE encodeBase64(cl IN OUT CLOB, overwrite BOOLEAN := true);

/**
 * Decodes Base64 data into octets.
 * If overwrite is not true, creates new temporary clob and overwrites LOB locator,
 * it is responsibility of the caller to free this new temporary clob.
 */
PROCEDURE decodeBase64(cl IN OUT CLOB, overwrite BOOLEAN := true);

end xrc_xmlparser;
/
show errors

