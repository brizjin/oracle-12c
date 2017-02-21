-- Table OBJECT_RIGHTS_LIST
drop table bk_obj_rights_list;
drop index idx_obj_right_lst_obj_id;
drop index idx_obj_right_lst_class_id;
alter table object_rights_list drop primary key &&D_DROPINDEX;
ALTER TABLE object_rights_list DROP CONSTRAINT fk_object_rights_list_class_id;
ALTER TABLE object_rights_list DROP CONSTRAINT fk_object_rights_list_subj_id;
ALTER TABLE object_rights_list DROP CONSTRAINT nn_object_rights_list_class_id;
rename object_rights_list to bk_obj_rights_list;

CREATE TABLE object_rights_list
 (
  subj_id                    VARCHAR2(30),
  obj_id                     VARCHAR2(128),
  class_id                   VARCHAR2(16),
  allow                      CHAR(1),
  access_group               VARCHAR2(30)
 )
 PCTFREE    10
 PCTUSED    40
 INITRANS   1
 MAXTRANS   255
 TABLESPACE &&tusers
 NOLOGGING
 STORAGE   (
      INITIAL     512K
      NEXT        512K
      PCTINCREASE 0
      MINEXTENTS  1
      MAXEXTENTS  UNLIMITED
   )
/

insert /*+ APPEND */ into object_rights_list (subj_id,obj_id,class_id,allow,access_group)
  (select subj_id,obj_id,class_id,allow,access_group from bk_obj_rights_list);

CREATE  UNIQUE INDEX pk_obj_right_lst
 ON object_rights_list
  ( subj_id,
    obj_id  )
  PCTFREE    10
  INITRANS   2
  MAXTRANS   255
  TABLESPACE &&tspacei
  NOLOGGING
 STORAGE (
   INITIAL     512K
   NEXT        512K
   PCTINCREASE 0
   MINEXTENTS  1
   MAXEXTENTS  UNLIMITED
   )
/

CREATE  INDEX idx_obj_right_lst_obj_id
 ON object_rights_list
  ( obj_id  )
  PCTFREE    10
  INITRANS   2
  MAXTRANS   255
  TABLESPACE &&tspacei
  NOLOGGING
 STORAGE (
   INITIAL     256K
   NEXT        256K
   PCTINCREASE 0
   MINEXTENTS  1
   MAXEXTENTS  UNLIMITED
   )
/

CREATE  INDEX idx_obj_right_lst_class_id
 ON object_rights_list
  ( class_id  )
  PCTFREE    10
  INITRANS   2
  MAXTRANS   255
  TABLESPACE &&tspacei
  NOLOGGING
 STORAGE (
   INITIAL     256K
   NEXT        256K
   PCTINCREASE 0
   MINEXTENTS  1
   MAXEXTENTS  UNLIMITED
   )
/

ALTER TABLE object_rights_list
 ADD CONSTRAINT pk_obj_right_lst PRIMARY KEY (subj_id,obj_id);

ALTER TABLE object_rights_list
 ADD CONSTRAINT fk_object_rights_list_class_id FOREIGN KEY (class_id)
      REFERENCES CLASSES(id) ON DELETE CASCADE;

ALTER TABLE object_rights_list
 ADD CONSTRAINT fk_object_rights_list_subj_id FOREIGN KEY (subj_id)
      REFERENCES USERS(username) ON DELETE CASCADE;

ALTER TABLE object_rights_list
 ADD CONSTRAINT nn_object_rights_list_class_id CHECK (CLASS_ID IS NOT NULL);

ALTER TABLE object_rights_list LOGGING;
ALTER INDEX pk_obj_right_lst   LOGGING;
ALTER INDEX idx_obj_right_lst_obj_id   LOGGING;
ALTER INDEX idx_obj_right_lst_class_id LOGGING;

