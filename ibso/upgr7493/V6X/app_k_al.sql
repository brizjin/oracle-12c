-- Table SIGNED_LEVELS

CREATE TABLE signed_levels
(
  id number,
  signed_level               VARCHAR2(4000)
)
 TABLESPACE &&TUSERS;


-- Indexes for SIGNED_LEVELS

CREATE  UNIQUE INDEX pk_signed_levels
 ON signed_levels
  ( id )
 TABLESPACE &&TSPACEI;


-- Constraints for SIGNED_LEVELS

ALTER TABLE signed_levels
 ADD CONSTRAINT pk_signed_levels PRIMARY KEY (id);


-- Table DICT_CHANGES

ALTER TABLE dict_changes ADD (
  msid                       NUMBER,
  access_level               VARCHAR2(32),
  signed_level               number,
  mdate_crit                 DATE,
  muser_crit                 VARCHAR2(30),
  pdate                      DATE,
  puser                      VARCHAR2(30),
  pstorage                   VARCHAR2(128),
  tag                        VARCHAR2(32),
  version_no                 VARCHAR2(32),
  build_no                   VARCHAR2(32),
  hash_value                 VARCHAR2(128),
  cdate                      DATE,
  cuser                      VARCHAR2(30),
  ddate                      DATE,
  duser                      VARCHAR2(30)
);


ALTER TABLE dict_changes DROP constraint NN_DICT_CHANGES_MDATE;
ALTER TABLE dict_changes MODIFY mdate null;
ALTER TABLE dict_changes MODIFY mdate constraint NN_DICT_CHANGES_MDATE NOT NULL;

-- Indexes for DICT_CHANGES

CREATE  INDEX idx_dict_changes_mdate
 ON dict_changes
  ( mdate  )
 TABLESPACE &&TSPACEI;

CREATE  UNIQUE INDEX pk_dict_changes
 ON dict_changes
  ( obj_type,
    obj_id,
    change_type  )
 TABLESPACE &&TSPACEI;

-- Constraints for DICT_CHANGES

ALTER TABLE dict_changes
 ADD CONSTRAINT pk_dict_changes PRIMARY KEY (obj_type,obj_id,change_type);

ALTER TABLE dict_changes
 ADD CONSTRAINT fk_dict_changes FOREIGN KEY (signed_level) REFERENCES signed_levels(id);
