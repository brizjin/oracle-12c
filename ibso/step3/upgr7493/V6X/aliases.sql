alter table CRITERIA_COLUMNS add ORDER_BY_POS number;
alter table CRITERIA_COLUMNS add ORDER_BY_TYPE varchar2(1);

alter table CONTROLS add CRIT_ID varchar2(16);
alter table CONTROLS add CRIT_ALIAS varchar2(30);
alter table CONTROLS add CRIT_CLASS_ID varchar(16);

alter table CONTROLS add constraint FK_CONTROLS_CRIT_ID
  foreign key(CRIT_ID) references CRITERIA(ID) on delete set null;

alter table CONTROLS add constraint FK_CONTROLS_CRIT_CLASS_ID
  foreign key(CRIT_CLASS_ID) references CLASSES(ID) on delete set null;


alter table FVR_FILTERS add ALIAS varchar(30);

create table CRITERIA_PRINT_COLUMNS (
  CRITERIA_ID varchar2(16),
  PRINT_NAME varchar2(80),
  ALIAS varchar2(30),
  POSITION NUMBER,
  OPER  VARCHAR2(10),
  WIDTH NUMBER,
  QUOTE VARCHAR2(1),
  ALIGN VARCHAR2(1)
) tablespace &&tusers;


create index IDX_CR_PR_COLS_CR_ID_NAME
  on CRITERIA_PRINT_COLUMNS (CRITERIA_ID, PRINT_NAME)
  tablespace &&tspacei;

alter table CRITERIA_PRINT_COLUMNS add constraint FK_CR_PR_COLS_CR_ID_NAME
  foreign key(CRITERIA_ID, PRINT_NAME) references CRITERIA_PRINTS(CRITERIA_ID, NAME) on delete cascade;


