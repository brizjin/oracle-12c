-- Synchronizations of DICT_CHANGES with dictionary tables

alter trigger dict_changes_changes disable;

BEGIN
   stdio.put_line_buf ('Syncing dict_changes with classes');

   UPDATE dict_changes dc
      SET (dc.mdate_crit, dc.tag) = (SELECT modified, tag
                                       FROM classes
                                      WHERE ID = dc.obj_id)
    WHERE dc.obj_type = class_mgr.dcot_classes
      AND dc.change_type = class_mgr.dcct_classes
      AND EXISTS (SELECT 1 FROM classes WHERE ID = dc.obj_id);

   stdio.put_line_buf ('* ' || SQL%ROWCOUNT || ' rows were updated');

   UPDATE dict_changes dc
      SET ddate = SYSDATE
    WHERE ddate IS NULL
      AND dc.obj_type = class_mgr.dcot_classes
      AND dc.change_type = class_mgr.dcct_classes
      AND NOT EXISTS (SELECT 1 FROM classes WHERE ID = dc.obj_id);

   stdio.put_line_buf ('* ' || SQL%ROWCOUNT || ' rows were marked as deleted');

   INSERT INTO dict_changes
               (cdate, mdate_crit, mdate, tag, obj_type, obj_id, change_type)
      (SELECT modified, modified, nvl(modified, sysdate), tag, class_mgr.dcot_classes, ID,
              class_mgr.dcct_classes
         FROM classes
        WHERE NOT EXISTS (
                 SELECT 1
                   FROM dict_changes
                  WHERE obj_type = class_mgr.dcot_classes
                    AND obj_id = ID
                    AND change_type = class_mgr.dcct_classes));

   stdio.put_line_buf ('* ' || SQL%ROWCOUNT || ' rows were inserted');
END;
/

BEGIN
   stdio.put_line_buf ('Syncing dict_changes with class_attributes');

   UPDATE dict_changes dc
      SET dc.mdate_crit =
                    (SELECT modified
                       FROM class_attributes
                      WHERE attr_id = dc.obj_id AND class_id = dc.change_type)
    WHERE dc.obj_type = class_mgr.dcot_class_attributes
      AND EXISTS (SELECT 1 FROM class_attributes
                   WHERE attr_id = dc.obj_id AND class_id = dc.change_type);

   stdio.put_line_buf ('* ' || SQL%ROWCOUNT || ' rows were updated');

   UPDATE dict_changes dc
      SET ddate = SYSDATE
    WHERE ddate IS NULL
      AND dc.obj_type = class_mgr.dcot_class_attributes
      AND NOT EXISTS (SELECT 1 FROM class_attributes
                       WHERE attr_id = dc.obj_id AND class_id = dc.change_type);

   stdio.put_line_buf ('* ' || SQL%ROWCOUNT || ' rows were marked as deleted');

   INSERT INTO dict_changes
               (cdate, mdate_crit, mdate, obj_type, obj_id, change_type)
      (SELECT modified, modified, nvl(modified, sysdate), class_mgr.dcot_class_attributes,
              attr_id, class_id
         FROM class_attributes
        WHERE NOT EXISTS (
                 SELECT 1
                   FROM dict_changes
                  WHERE obj_type = class_mgr.dcot_class_attributes
                    AND obj_id = attr_id
                    AND change_type = class_id));

   stdio.put_line_buf ('* ' || SQL%ROWCOUNT || ' rows were inserted');
END;
/

BEGIN
   stdio.put_line_buf ('Syncing dict_changes with states');

   UPDATE dict_changes dc
      SET (dc.mdate_crit, dc.tag) =
             (SELECT modified, tag
                FROM states
               WHERE ID = dc.obj_id AND class_id = dc.change_type)
    WHERE dc.obj_type = class_mgr.dcot_states
      AND EXISTS (SELECT 1 FROM states WHERE ID = dc.obj_id AND class_id = dc.change_type);

   stdio.put_line_buf ('* ' || SQL%ROWCOUNT || ' rows were updated');

   UPDATE dict_changes dc
      SET ddate = SYSDATE
    WHERE ddate IS NULL
      AND dc.obj_type = class_mgr.dcot_states
      AND NOT EXISTS (SELECT 1 FROM states WHERE ID = dc.obj_id AND class_id = dc.change_type);

   stdio.put_line_buf ('* ' || SQL%ROWCOUNT || ' rows were marked as deleted');

   INSERT INTO dict_changes
               (cdate, mdate_crit, mdate, tag, obj_type, obj_id, change_type)
      (SELECT modified, modified, nvl(modified, sysdate), tag, class_mgr.dcot_states, ID,
              class_id
         FROM states
        WHERE NOT EXISTS (
                 SELECT 1
                   FROM dict_changes
                  WHERE obj_type = class_mgr.dcot_states
                    AND obj_id = ID
                    AND change_type = class_id));

   stdio.put_line_buf ('* ' || SQL%ROWCOUNT || ' rows were inserted');
END;
/

BEGIN
   stdio.put_line_buf ('Syncing dict_changes with transitions');

   UPDATE dict_changes dc
      SET (dc.mdate_crit, dc.tag) =
             (SELECT modified, tag
                FROM transitions
               WHERE ID = dc.obj_id AND class_id = dc.change_type)
    WHERE dc.obj_type = class_mgr.dcot_transitions
      AND EXISTS (SELECT 1 FROM transitions WHERE ID = dc.obj_id AND class_id = dc.change_type);

   stdio.put_line_buf ('* ' || SQL%ROWCOUNT || ' rows were updated');

   UPDATE dict_changes dc
      SET ddate = SYSDATE
    WHERE ddate IS NULL
      AND dc.obj_type = class_mgr.dcot_transitions
      AND NOT EXISTS (SELECT 1 FROM transitions WHERE ID = dc.obj_id AND class_id = dc.change_type);

   stdio.put_line_buf ('* ' || SQL%ROWCOUNT || ' rows were marked as deleted');

   INSERT INTO dict_changes
               (cdate, mdate_crit, mdate, tag, obj_type, obj_id, change_type)
      (SELECT modified, modified, nvl(modified, sysdate), tag, class_mgr.dcot_transitions, ID,
              class_id
         FROM transitions
        WHERE NOT EXISTS (
                 SELECT 1
                   FROM dict_changes
                  WHERE obj_type = class_mgr.dcot_transitions
                    AND obj_id = ID
                    AND change_type = class_id));

   stdio.put_line_buf ('* ' || SQL%ROWCOUNT || ' rows were inserted');
END;
/

BEGIN
   stdio.put_line_buf ('Syncing dict_changes with methods');

   UPDATE dict_changes dc
      SET (dc.cdate, dc.cuser, dc.mdate_crit, dc.muser_crit, dc.tag) =
             (SELECT created, user_created, modified, user_modified, tag
                FROM methods
               WHERE ID = dc.obj_id)
    WHERE dc.obj_type = class_mgr.dcot_methods
      AND dc.change_type = class_mgr.dcct_methods
      AND EXISTS (SELECT 1 FROM methods WHERE ID = dc.obj_id);

   stdio.put_line_buf ('* ' || SQL%ROWCOUNT || ' rows were updated');

   UPDATE dict_changes dc
      SET ddate = SYSDATE
    WHERE ddate IS NULL
      AND dc.obj_type = class_mgr.dcot_methods
      AND dc.change_type = class_mgr.dcct_methods
      AND NOT EXISTS (SELECT 1 FROM methods WHERE ID = dc.obj_id);

   stdio.put_line_buf ('* ' || SQL%ROWCOUNT || ' rows were marked as deleted');

   INSERT INTO dict_changes
               (cdate, cuser, mdate_crit, muser_crit, mdate, tag, obj_type,
                obj_id, change_type)
      (SELECT created, user_created, modified, user_modified, nvl(modified, sysdate), tag,
              class_mgr.dcot_methods, ID, class_mgr.dcct_methods
         FROM methods
        WHERE NOT EXISTS (
                 SELECT 1
                   FROM dict_changes
                  WHERE obj_type = class_mgr.dcot_methods
                    AND obj_id = ID
                    AND change_type = class_mgr.dcct_methods));

   stdio.put_line_buf ('* ' || SQL%ROWCOUNT || ' rows were inserted');
END;
/

BEGIN
   stdio.put_line_buf ('Syncing dict_changes with criteria');

   UPDATE dict_changes dc
      SET (dc.mdate_crit, dc.tag) = (SELECT modified, tag
                                       FROM criteria
                                      WHERE ID = dc.obj_id)
    WHERE dc.obj_type = class_mgr.dcot_criteria
      AND dc.change_type = class_mgr.dcct_criteria
      AND EXISTS (SELECT 1 FROM criteria WHERE ID = dc.obj_id);

   stdio.put_line_buf ('* ' || SQL%ROWCOUNT || ' rows were updated');

   UPDATE dict_changes dc
      SET ddate = SYSDATE
    WHERE ddate IS NULL
      AND dc.obj_type = class_mgr.dcot_criteria
      AND dc.change_type = class_mgr.dcct_criteria
      AND NOT EXISTS (SELECT 1 FROM criteria WHERE ID = dc.obj_id);

   stdio.put_line_buf ('* ' || SQL%ROWCOUNT || ' rows were marked as deleted');

   INSERT INTO dict_changes
               (cdate, mdate_crit, mdate, tag, obj_type, obj_id, change_type)
      (SELECT modified, modified, nvl(modified, sysdate), tag, class_mgr.dcot_criteria, ID,
              class_mgr.dcct_criteria
         FROM criteria
        WHERE NOT EXISTS (
                 SELECT 1
                   FROM dict_changes
                  WHERE obj_type = class_mgr.dcot_criteria
                    AND obj_id = ID
                    AND change_type = class_mgr.dcct_criteria));

   stdio.put_line_buf ('* ' || SQL%ROWCOUNT || ' rows were inserted');
END;
/

BEGIN
   stdio.put_line_buf ('Syncing dict_changes with procedures');

   UPDATE dict_changes dc
      SET (dc.mdate_crit, dc.tag) = (SELECT modified, tag
                                       FROM procedures
                                      WHERE ID = dc.obj_id)
    WHERE dc.obj_type = class_mgr.dcot_procedures
      AND dc.change_type = class_mgr.dcct_procedures
      AND EXISTS (SELECT 1 FROM procedures WHERE ID = dc.obj_id);

   stdio.put_line_buf ('* ' || SQL%ROWCOUNT || ' rows were updated');

   UPDATE dict_changes dc
      SET ddate = SYSDATE
    WHERE ddate IS NULL
      AND dc.obj_type = class_mgr.dcot_procedures
      AND dc.change_type = class_mgr.dcct_procedures
      AND NOT EXISTS (SELECT 1 FROM procedures WHERE ID = dc.obj_id);

   stdio.put_line_buf ('* ' || SQL%ROWCOUNT || ' rows were marked as deleted');

   INSERT INTO dict_changes
               (cdate, mdate_crit, mdate, tag, obj_type, obj_id, change_type)
      (SELECT modified, modified, nvl(modified, sysdate), tag, class_mgr.dcot_procedures,
              ID, class_mgr.dcct_procedures
         FROM procedures
        WHERE NOT EXISTS (
                 SELECT 1
                   FROM dict_changes
                  WHERE obj_type = class_mgr.dcot_procedures
                    AND obj_id = ID
                    AND change_type = class_mgr.dcct_procedures));

   stdio.put_line_buf ('* ' || SQL%ROWCOUNT || ' rows were inserted');
END;
/

alter trigger dict_changes_changes enable;
