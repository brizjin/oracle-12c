alter table criteria_columns modify DATA_SOURCE VARCHAR2(2000);
alter table criteria_columns modify REFERENCE_ID VARCHAR2(256);

alter table criteria_complex_columns modify DATA_SOURCE VARCHAR2(2000);


alter table report_views drop primary key &&D_DROPINDEX;

alter table report_views drop unique(name) &&D_DROPINDEX;

alter table report_views drop constraint NN_REPORT_VIEWS_NAME;

create unique index PK_REPORT_VIEWS_NAME on REPORT_VIEWS(NAME)
  tablespace &&tspacei;

alter table REPORT_VIEWS add constraint PK_REPORT_VIEWS_NAME
  primary key (name);

drop trigger insert_criteria_columns_after;
