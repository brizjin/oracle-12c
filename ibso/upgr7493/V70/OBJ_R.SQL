-- Table OBJECT_RIGHTS
drop table object_rights;

CREATE TABLE object_rights
 (
  subj_id                    VARCHAR2(30),
  obj_id                     VARCHAR2(128),
  class_id                   VARCHAR2(16),
  access_group               VARCHAR2(30)
 )
 PCTFREE    10
 PCTUSED    40
 INITRANS   1
 MAXTRANS   255
 TABLESPACE &&tusers
 STORAGE   (
      INITIAL     1M
      NEXT        1M
      PCTINCREASE 0
      MINEXTENTS  1
      MAXEXTENTS  UNLIMITED
   )
/

CREATE  UNIQUE INDEX pk_object_rights_oid_sid_
 ON object_rights
  ( obj_id,
    subj_id,
    class_id )
  PCTFREE    10
  INITRANS   2
  MAXTRANS   255
  TABLESPACE &&tspacei
 STORAGE (
   INITIAL     512K
   NEXT        512K
   PCTINCREASE 0
   MINEXTENTS  1
   MAXEXTENTS  UNLIMITED
   )
/

CREATE  INDEX idx_object_rights_subj_id
 ON object_rights
  ( subj_id )
  PCTFREE    10
  INITRANS   2
  MAXTRANS   255
  TABLESPACE &&tspacei
 STORAGE (
   INITIAL     256K
   NEXT        256K
   PCTINCREASE 0
   MINEXTENTS  1
   MAXEXTENTS  UNLIMITED
   )
/

CREATE  INDEX idx_object_rights_class_id
 ON object_rights
  ( class_id )
  PCTFREE    10
  INITRANS   2
  MAXTRANS   255
  TABLESPACE &&tspacei
 STORAGE (
   INITIAL     256K
   NEXT        256K
   PCTINCREASE 0
   MINEXTENTS  1
   MAXEXTENTS  UNLIMITED
   )
/

ALTER TABLE object_rights
 ADD CONSTRAINT pk_object_rights_oid_sid_ PRIMARY KEY (obj_id,subj_id,class_id);

ALTER TABLE object_rights
 ADD CONSTRAINT fk_object_rights_class_id FOREIGN KEY (class_id)
      REFERENCES CLASSES(id) ON DELETE CASCADE;

ALTER TABLE object_rights
 ADD CONSTRAINT fk_object_rights_subj_id FOREIGN KEY (subj_id)
      REFERENCES USERS(username) ON DELETE CASCADE;

