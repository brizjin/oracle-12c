alter table classes add KEY_ATTR VARCHAR2(16);

alter table classes add DATA_PRECISION_MIN NUMBER;

var mes varchar2(100)

begin
  select '1' into :mes from user_tab_columns
   where table_name='CLASSES' and column_name='PROPERTIES';
  :mes := 'CLASSES.PROPERTIES already exists...';
exception when no_data_found then
  execute immediate 'alter table classes add PROPERTIES VARCHAR2(2000)';
  :mes := 'CLASSES.PROPERTIES column created';
  execute immediate
  'update classes set properties=''|DigitalGrouping Y|'' where base_class_id=''NUMBER'' and kernel=''0'' and data_precision<>0';
  :mes := :mes||chr(10)||'Updated '||sql%rowcount||' values of CLASSES.PROPERTIES for NUMBERs';
  commit;
end;
/

print mes

alter table class_tables add OLD_ID_SOURCE VARCHAR2(100);

alter table class_tables add LOG_TABLE VARCHAR2(30);

alter table class_tables add FLAGS VARCHAR2(30);

alter table class_tab_columns add QUAL_POS NUMBER;

alter table class_tab_columns add FLAGS VARCHAR2(30);

alter table class_tab_columns modify logging varchar2(2);

alter table class_rec_fields  add FLAGS VARCHAR2(30);

create index idx_cls_tab_cols_mapped
  on class_tab_columns(mapped_from) tablespace &&tspacei;

create index idx_cls_rec_flds_target
  on class_rec_fields(target_class_id) tablespace &&tspacei;

create index idx_rpt_obj_name_type
  on report_objects(name,type) tablespace  &&tspacei;

