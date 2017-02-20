alter table STATES add CASE_FILTER varchar2(1);

update states set case_filter='1'
 where id in ('PROV','2984') and case_filter is null
   and class_id in ('MAIN_DOCUM','KASSA_DOCUM','OUTBALANCE_DOC');

alter table METHODS  add (EXT_ID varchar2(16), SRC_ID varchar2(16));

create unique index UNQ_METHODS_EXT_ID
  on METHODS(EXT_ID)
  tablespace &&TSPACEI;

create unique index UNQ_METHODS_SRC_ID
  on METHODS(SRC_ID)
  tablespace &&TSPACEI;

alter table METHODS add constraint FK_METHODS_EXT_ID
  foreign key(EXT_ID) references METHODS(ID);

alter table METHODS add constraint FK_METHODS_SRC_ID
  foreign key(SRC_ID) references METHODS(ID);


alter table CRITERIA add (EXT_ID varchar2(16), SRC_ID varchar2(16));

create unique index UNQ_CRITERIA_EXT_ID
  on CRITERIA(EXT_ID)
  tablespace &&TSPACEI;

create unique index UNQ_CRITERIA_SRC_ID
  on CRITERIA(SRC_ID)
  tablespace &&TSPACEI;

alter table CRITERIA add constraint FK_CRITERIA_EXT_ID
  foreign key(EXT_ID) references CRITERIA(ID);

alter table CRITERIA add constraint FK_CRITERIA_SRC_ID
  foreign key(SRC_ID) references CRITERIA(ID);

alter table METHOD_PARAMETERS add SRC_POS number;

alter table METHOD_VARIABLES  add SRC_POS number;

alter table CRITERIA_COLUMNS  add SRC_POS number;

alter table CRITERIA_COLUMNS  add SRC_ALIAS varchar2(30);


