alter table users add userid number;

drop  trigger USERS_AFTER_INS;


alter table criteria_rights add implicit varchar2(1);

alter table criteria_rights drop primary key drop index;

create index idx_crit_rights_obj_subj_class
  on criteria_rights(obj_id,subj_id,class_id) tablespace &&tspacei;

create index idx_criteria_rights_class_id
  on criteria_rights(class_id) tablespace &&tspacei;


alter table procedure_rights add implicit varchar2(1);

alter table procedure_rights drop primary key drop index;

create index idx_procedure_rights_obj_subj
  on procedure_rights(obj_id,subj_id) tablespace &&tspacei;


create index idx_belong_grp_eq_equal_id
  on belong_groups_equal(equal_id)  tablespace &&tspacei;


create index idx_classes_criteria_id
  on classes(criteria_id) tablespace  &&tspacei;

create index idx_classes_init_method_id
  on classes(init_method_id) tablespace  &&tspacei;

create index idx_classes_trigger_id
  on classes(trigger_id) tablespace  &&tspacei;


create index idx_class_rules_subj_id
  on class_rules(subj_id) tablespace &&tspacei;


create index idx_crit_columns_r_crit_id
  on criteria_columns(ref_crit_id) tablespace  &&tspacei;

create index idx_method_rights_class_id
  on method_rights(class_id) tablespace &&tspacei;

create index idx_num_attributes_num_id
  on num_attributes(num_id) tablespace &&tspacei;

create index idx_transition_rights_class_id
  on transition_rights(class_id) tablespace &&tspacei;

create index idx_trn_meths_ext_id
  on transition_methods(ext_id)  tablespace  &&tspacei;

ALTER TABLE OBJECT_RIGHTS DROP CONSTRAINT FK_OBJECT_RIGHTS_CLASS_ID;
ALTER TABLE OBJECT_RIGHTS DROP CONSTRAINT FK_OBJECT_RIGHTS_SUBJ_ID;

ALTER TABLE OBJECT_RIGHTS_EX DROP CONSTRAINT FK_OBJECT_RIGHTS_EX_CLASS_ID;
ALTER TABLE OBJECT_RIGHTS_EX DROP CONSTRAINT FK_OBJECT_RIGHTS_EX_R_CLASS_ID;
ALTER TABLE OBJECT_RIGHTS_EX DROP CONSTRAINT FK_OBJECT_RIGHTS_EX_SUBJ_ID;

ALTER TABLE OBJECT_RIGHTS_LIST DROP CONSTRAINT FK_OBJECT_RIGHTS_LIST_CLASS_ID;
ALTER TABLE OBJECT_RIGHTS_LIST DROP CONSTRAINT FK_OBJECT_RIGHTS_LIST_SUBJ_ID;

ALTER TABLE CRITERIA_COLUMNS DROP CONSTRAINT FK_CRIT_COLUMNS_R_CRIT_ID;

ALTER TABLE CRITERIA_COLUMNS
  ADD CONSTRAINT FK_CRIT_COLUMNS_R_CRIT_ID FOREIGN KEY (REF_CRIT_ID)
  REFERENCES CRITERIA(ID);

ALTER TABLE PROCEDURE_RIGHTS DROP CONSTRAINT FK_PROC_RGHT_OBJ_ID;

ALTER TABLE PROCEDURE_RIGHTS
  ADD CONSTRAINT FK_PROC_RGHT_OBJ_ID FOREIGN KEY (OBJ_ID)
  REFERENCES PROCEDURES(NAME) ON DELETE CASCADE;

ALTER TABLE SUBJ_EQUAL DROP CONSTRAINT FK_SUBJ_EQUAL_OWNER_ID;

ALTER TABLE HOST2PLP ADD SRC_LINE NUMBER;
ALTER TABLE HOST2PLP MODIFY PLP_LINE NULL;
ALTER TABLE HOST2PLP MODIFY LINE NULL;
ALTER TABLE HOST2PLP MODIFY PLP_POS NULL;
ALTER TABLE HOST2PLP MODIFY POS NULL;

