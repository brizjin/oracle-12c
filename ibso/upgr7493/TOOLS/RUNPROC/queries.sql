PROMPT TABLE QUERIES
CREATE TABLE QUERIES ( TYPE           VARCHAR2(1)
                      ,TEXT           VARCHAR2(2000)
                      ,ID             VARCHAR2(30)
                      ,CODE           VARCHAR2(15)
                      ,USERNAME       VARCHAR2(30)
                      ,CREATED        DATE
) TABLESPACE &&TUSERS;
alter table queries add FAILURES       NUMBER;

ALTER TABLE QUERIES ADD CONSTRAINT pk_queries_id_type PRIMARY KEY (ID,TYPE)
USING INDEX TABLESPACE &&TSPACEI;

PROMPT SEQUENCE QUERIES_ID
CREATE SEQUENCE QUERIES_ID;

