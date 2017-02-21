alter table classes add LOB_STORAGE_GROUP VARCHAR2(30);
alter table class_tables add LOB_PARAM_GROUP VARCHAR2(30);
alter table class_tables modify PARAM_GROUP VARCHAR2(30);
