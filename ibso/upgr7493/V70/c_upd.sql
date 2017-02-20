@@obj_r

CREATE  INDEX idx_obj_right_lst_class_id
 ON object_rights_list
  ( class_id  )
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

CREATE  INDEX idx_object_rights_ex_class_id
 ON object_rights_ex
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

CREATE  INDEX idx_object_rights_ex_rclass_id
 ON object_rights_ex
  ( right_class_id )
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


