prompt Changing primary key on transitions from (CLASS_ID, ID) to (ID)

alter table transition_rights drop constraint FK_TR_CLASS_ID_OBJ_ID;

alter table transitions drop primary key &&D_DROPINDEX;

create unique index PK_TRANSITIONS_ID
  on transitions (ID)
  tablespace &&tspacei;

alter table transitions add constraint PK_TRANSITIONS_ID PRIMARY KEY(ID);

alter table transition_rights add constraint FK_TR_OBJ_ID foreign key(OBJ_ID) references transitions on delete cascade;


prompt Renaming unique key UQ_CLSID_SNAM to UNQ_TRANSITIONS_CLSID_SNAME on transitions

alter table transitions drop constraint UQ_CLSID_SNAM &&D_DROPINDEX;

create unique index UNQ_TRANSITIONS_CLSID_SNAME
  on transitions (CLASS_ID, SHORT_NAME)
  tablespace &&tspacei;

alter table transitions add constraint UNQ_TRANSITIONS_CLSID_SNAME UNIQUE (CLASS_ID, SHORT_NAME);
