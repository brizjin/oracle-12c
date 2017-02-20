define DIARY_TYPE=&&DIARY4
define INDEX_SUFFIX='TCODE'
define INDEX_UNIQUE='F'
define INDEX_FIELDS='TOPIC, CODE'
@settings\set_idx

define DIARY_TYPE=&&DIARY5
define INDEX_SUFFIX='AUDSID'
define INDEX_UNIQUE='F'
define INDEX_FIELDS='AUDSID'
@settings\set_idx

define DIARY_TYPE=&&DP
define INDEX_SUFFIX='DIARY_ID'
define INDEX_UNIQUE='F'
define INDEX_FIELDS='DIARY_ID'
@settings\set_idx

define DIARY_TYPE=&&OCH
define INDEX_SUFFIX='OBJ_ID'
define INDEX_UNIQUE='F'
define INDEX_FIELDS='OBJ_ID'
@settings\set_idx

define DIARY_TYPE=&&OSH
define INDEX_SUFFIX='OBJ_ID'
define INDEX_UNIQUE='F'
define INDEX_FIELDS='OBJ_ID'
@settings\set_idx

define DIARY_TYPE=&&VALSH
define INDEX_SUFFIX='OBJ_ID'
define INDEX_UNIQUE='F'
define INDEX_FIELDS='OBJ_ID'
@settings\set_idx
