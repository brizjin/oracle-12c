-- Table OBJECT_RIGHTS_EX
drop table bk_object_rights_ex;
drop index idx_object_rights_ex_subj_id;
drop index idx_object_rights_ex_class_id;
drop index idx_object_rights_ex_rclass_id;
alter table object_rights_ex drop primary key &&D_DROPINDEX;
ALTER TABLE object_rights_ex DROP CONSTRAINT fk_object_rights_ex_class_id;
ALTER TABLE object_rights_ex DROP CONSTRAINT fk_object_rights_ex_r_class_id;
ALTER TABLE object_rights_ex DROP CONSTRAINT fk_object_rights_ex_subj_id;
rename object_rights_ex to bk_object_rights_ex;

CREATE TABLE object_rights_ex
 (
  subj_id                    VARCHAR2(30),
  obj_id                     VARCHAR2(128),
  class_id                   VARCHAR2(16),
  right_class_id             VARCHAR2(16)
 )
 PCTFREE    10
 PCTUSED    40
 INITRANS   1
 MAXTRANS   255
 TABLESPACE &&tusers
 NOLOGGING
 STORAGE   (
      INITIAL     1M
      NEXT        1M
      PCTINCREASE 0
      MINEXTENTS  1
      MAXEXTENTS  UNLIMITED
   )
/

insert /*+ APPEND */ into object_rights_ex (subj_id,obj_id,class_id,right_class_id)
  (select subj_id,obj_id,class_id,right_class_id from bk_object_rights_ex);

CREATE  UNIQUE INDEX pk_object_rights_ex
 ON object_rights_ex
  ( obj_id,
    subj_id,
    right_class_id,
    class_id )
  PCTFREE    10
  INITRANS   2
  MAXTRANS   255
  TABLESPACE &&tspacei
  NOLOGGING
 STORAGE (
   INITIAL     1M
   NEXT        1M
   PCTINCREASE 0
   MINEXTENTS  1
   MAXEXTENTS  UNLIMITED
   )
/

CREATE  INDEX idx_object_rights_ex_subj_id
 ON object_rights_ex
  ( subj_id )
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

CREATE  INDEX idx_object_rights_ex_class_id
 ON object_rights_ex
  ( class_id )
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

CREATE  INDEX idx_object_rights_ex_rclass_id
 ON object_rights_ex
  ( right_class_id )
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

ALTER TABLE object_rights_ex
 ADD CONSTRAINT pk_object_rights_ex PRIMARY KEY (obj_id,subj_id,class_id,right_class_id);

ALTER TABLE object_rights_ex
 ADD CONSTRAINT fk_object_rights_ex_class_id FOREIGN KEY (class_id)
      REFERENCES CLASSES(id) ON DELETE CASCADE;

ALTER TABLE object_rights_ex
 ADD CONSTRAINT fk_object_rights_ex_r_class_id FOREIGN KEY (right_class_id)
      REFERENCES CLASSES(id) ON DELETE CASCADE;

ALTER TABLE object_rights_ex
 ADD CONSTRAINT fk_object_rights_ex_subj_id FOREIGN KEY (subj_id)
      REFERENCES USERS(username) ON DELETE CASCADE;

ALTER TABLE object_rights_ex    LOGGING;
ALTER INDEX pk_object_rights_ex LOGGING;
ALTER INDEX idx_object_rights_ex_subj_id   LOGGING;
ALTER INDEX idx_object_rights_ex_class_id  LOGGING;
ALTER INDEX idx_object_rights_ex_rclass_id LOGGING;

