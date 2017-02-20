@@crt_als
@@u_source

prompt Converting column names to quals in field attr_id of table object_rules
exec rules.upgrade_rules

prompt Converting field format of table criteria_prints
exec Data_Views.Translate_Crit_Prints_Format

prompt Converting COMBO control caption to criteria_id, alias etc. in field caption of table controls
exec forms_mgr.TRANSLATE_CTL_CAPTION

prompt Converting column positions to aliases in field ind of table fvr_filters
exec fvr.translate_fvr_filters_ind

