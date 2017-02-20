spool sys_idx.log
var s varchar2(30);
exec :s := inst_info.downer1
column tmpcol new_value tmpowner noprint
select :s tmpcol from dual;


alter session set sort_area_size=83886080;

prompt PK_ACCESS_GROUPS
alter index PK_ACCESS_GROUPS rebuild compute statistics;

prompt PK_ADDRESS_USERNAME_ADDRESS
alter index PK_ADDRESS_USERNAME_ADDRESS rebuild compute statistics;

prompt IDX_API_LIST_ID
alter index IDX_API_LIST_ID rebuild compute statistics;

prompt PK_API_LIST
alter index PK_API_LIST rebuild compute statistics;

prompt PK_API_OPTIONS
alter index PK_API_OPTIONS rebuild compute statistics;

prompt IDX_DT_API_REPORTS
alter index IDX_DT_API_REPORTS rebuild compute statistics;

prompt PK_API_REPORTS
alter index PK_API_REPORTS rebuild compute statistics;

prompt IDX_API_USAGE
alter index IDX_API_USAGE rebuild compute statistics;

prompt PK_API_USAGE
alter index PK_API_USAGE rebuild compute statistics;

prompt PK_BELONG_GROUPS_ID
alter index PK_BELONG_GROUPS_ID rebuild compute statistics;

prompt IDX_BELONG_GRP_EQ_EQUAL_ID
alter index IDX_BELONG_GRP_EQ_EQUAL_ID rebuild compute statistics;

prompt PK_BELONG_GROUPS_EQUAL
alter index PK_BELONG_GROUPS_EQUAL rebuild compute statistics;

prompt PK_CALENDARS_NAME
alter index PK_CALENDARS_NAME rebuild compute statistics;

prompt UNQ_CALENDARS_ID
alter index UNQ_CALENDARS_ID rebuild compute statistics;

prompt IDX_CALENDAR_VALUE_ALL
alter index IDX_CALENDAR_VALUE_ALL rebuild compute statistics;

prompt IDX_CMR_CHECK_METHOD_ID
alter index IDX_CMR_CHECK_METHOD_ID rebuild compute statistics;

prompt IDX_CMR_METHOD_ID
alter index IDX_CMR_METHOD_ID rebuild compute statistics;

prompt PK_CHECK_METHOD_RIGHTS
alter index PK_CHECK_METHOD_RIGHTS rebuild compute statistics;

prompt IDX_CLASSES_CRITERIA_ID
alter index IDX_CLASSES_CRITERIA_ID rebuild compute statistics;

prompt IDX_CLASSES_ENTITY_ID
alter index IDX_CLASSES_ENTITY_ID rebuild compute statistics;

prompt IDX_CLASSES_INIT_METHOD_ID
alter index IDX_CLASSES_INIT_METHOD_ID rebuild compute statistics;

prompt IDX_CLASSES_PARAM_GROUP_EID
alter index IDX_CLASSES_PARAM_GROUP_EID rebuild compute statistics;

prompt IDX_CLASSES_PARENT_ID
alter index IDX_CLASSES_PARENT_ID rebuild compute statistics;

prompt IDX_CLASSES_TARGET
alter index IDX_CLASSES_TARGET rebuild compute statistics;

prompt IDX_CLASSES_TRIGGER_ID
alter index IDX_CLASSES_TRIGGER_ID rebuild compute statistics;

prompt PK_CLASSES_ID
alter index PK_CLASSES_ID rebuild compute statistics;

prompt IDX_CLASS_ATTRIBUTES_ATTR_ID
alter index IDX_CLASS_ATTRIBUTES_ATTR_ID rebuild compute statistics;

prompt IDX_CLASS_ATTRIBUTES_SELF
alter index IDX_CLASS_ATTRIBUTES_SELF rebuild compute statistics;

prompt PK_CLASS_ATTRIBUTE_CLASS_ID
alter index PK_CLASS_ATTRIBUTE_CLASS_ID rebuild compute statistics;

prompt IDX_CLASS_INDEXES_CLASS_ID
alter index IDX_CLASS_INDEXES_CLASS_ID rebuild compute statistics;

prompt PK_CLASS_INDEXES_NAME
alter index PK_CLASS_INDEXES_NAME rebuild compute statistics;

prompt PK_CLASS_IND_COLS_NAM_POS
alter index PK_CLASS_IND_COLS_NAM_POS rebuild compute statistics;

prompt UNQ_CLASS_PARTITIONS_CLASS_POS
alter index UNQ_CLASS_PARTITIONS_CLASS_POS rebuild compute statistics;

prompt UNQ_CLASS_PARTITIONS_MIRROR
alter index UNQ_CLASS_PARTITIONS_MIRROR rebuild compute statistics;

prompt PK_CLASS_PART_COLUMNS
alter index PK_CLASS_PART_COLUMNS rebuild compute statistics;

prompt IDX_CLS_REC_FLDS_TARGET
alter index IDX_CLS_REC_FLDS_TARGET rebuild compute statistics;

prompt PK_CLS_REC_FLDS_CLS_ID_QUAL
alter index PK_CLS_REC_FLDS_CLS_ID_QUAL rebuild compute statistics;

prompt PK_CLS_REL_CHILD_PARENT
alter index PK_CLS_REL_CHILD_PARENT rebuild compute statistics;

prompt UNQ_CLS_REL_CHLD_DIST
alter index UNQ_CLS_REL_CHLD_DIST rebuild compute statistics;

prompt UNQ_CLS_REL_PRNT_DIST_CHILD
alter index UNQ_CLS_REL_PRNT_DIST_CHILD rebuild compute statistics;

prompt IDX_CLASSES_RIGHTS_SUBJ_ID
alter index IDX_CLASSES_RIGHTS_SUBJ_ID rebuild compute statistics;

prompt PK_CR_OBJ_ID_SUBJ_ID
alter index PK_CR_OBJ_ID_SUBJ_ID rebuild compute statistics;

prompt IDX_CLASS_RULES_SUBJ_ID
alter index IDX_CLASS_RULES_SUBJ_ID rebuild compute statistics;

prompt PK_CR_CLASS_ID_SUBJ_ID
alter index PK_CR_CLASS_ID_SUBJ_ID rebuild compute statistics;

prompt PK_CLASS_TABLES_CLASS_ID
alter index PK_CLASS_TABLES_CLASS_ID rebuild compute statistics;

prompt UNQ_CLASS_TABLES_CLASS_KEY
alter index UNQ_CLASS_TABLES_CLASS_KEY rebuild compute statistics;

prompt UNQ_CLASS_TABLES_TABLE_NAME
alter index UNQ_CLASS_TABLES_TABLE_NAME rebuild compute statistics;

prompt IDX_CLS_TAB_COLS_MAPPED
alter index IDX_CLS_TAB_COLS_MAPPED rebuild compute statistics;

prompt IDX_CLS_TAB_COLS_TARGET
alter index IDX_CLS_TAB_COLS_TARGET rebuild compute statistics;

prompt PK_CLS_TAB_COLS_CLS_ID_QUAL
alter index PK_CLS_TAB_COLS_CLS_ID_QUAL rebuild compute statistics;

prompt PK_CLIENT_MODULES_FILENAME
alter index PK_CLIENT_MODULES_FILENAME rebuild compute statistics;

prompt IDX_CONTROLS_CRIT_ID
alter index IDX_CONTROLS_CRIT_ID rebuild compute statistics;

prompt IDX_CONTROLS_DEPEND
alter index IDX_CONTROLS_DEPEND rebuild compute statistics;

prompt IDX_CONTROLS_PARENT
alter index IDX_CONTROLS_PARENT rebuild compute statistics;

prompt PK_CONTROLS_ID
alter index PK_CONTROLS_ID rebuild compute statistics;

prompt UNQ_CONTROLS_METH_ID_POSITION
alter index UNQ_CONTROLS_METH_ID_POSITION rebuild compute statistics;

prompt IDX_CRITERIA_CLASS_ID_FLAGS
alter index IDX_CRITERIA_CLASS_ID_FLAGS rebuild compute statistics;

prompt PK_CRITERIA_ID
alter index PK_CRITERIA_ID rebuild compute statistics;

prompt UNQ_CRITERIA_EXT_ID
alter index UNQ_CRITERIA_EXT_ID rebuild compute statistics;

prompt UNQ_CRITERIA_SRC_ID
alter index UNQ_CRITERIA_SRC_ID rebuild compute statistics;

prompt UQ_CRITERIA_SHORT_NAME
alter index UQ_CRITERIA_SHORT_NAME rebuild compute statistics;

prompt IDX_CRIT_COLUMNS_R_CRIT_ID
alter index IDX_CRIT_COLUMNS_R_CRIT_ID rebuild compute statistics;

prompt UNQ_CRIT_COLUMNS_CRIT_ID_ALIAS
alter index UNQ_CRIT_COLUMNS_CRIT_ID_ALIAS rebuild compute statistics;

prompt IDX_CRIT_COMPLEX_CRITERIA_ID
alter index IDX_CRIT_COMPLEX_CRITERIA_ID rebuild compute statistics;

prompt IDX_CRIT_COMPLEX_JOIN_ID
alter index IDX_CRIT_COMPLEX_JOIN_ID rebuild compute statistics;

prompt IDX_CRIT_CC_CRITERIA_ID
alter index IDX_CRIT_CC_CRITERIA_ID rebuild compute statistics;

prompt IDX_CRITERIA_METHODS_CRIT_ID
alter index IDX_CRITERIA_METHODS_CRIT_ID rebuild compute statistics;

prompt IDX_CRITERIA_METHODS_METHOD_ID
alter index IDX_CRITERIA_METHODS_METHOD_ID rebuild compute statistics;

prompt PK_CR_PRINTS_CR_ID_NAME
alter index PK_CR_PRINTS_CR_ID_NAME rebuild compute statistics;

prompt IDX_CR_PR_COLS_CR_ID_NAME
alter index IDX_CR_PR_COLS_CR_ID_NAME rebuild compute statistics;

prompt IDX_CRITERIA_RIGHTS_CLASS_ID
alter index IDX_CRITERIA_RIGHTS_CLASS_ID rebuild compute statistics;

prompt IDX_CRITERIA_RIGHTS_SUBJ_ID
alter index IDX_CRITERIA_RIGHTS_SUBJ_ID rebuild compute statistics;

prompt IDX_CRIT_RIGHTS_OBJ_SUBJ_CLASS
alter index IDX_CRIT_RIGHTS_OBJ_SUBJ_CLASS rebuild compute statistics;

prompt IDX_CRIT_TRIES_CRITERIA_ID
alter index IDX_CRIT_TRIES_CRITERIA_ID rebuild compute statistics;

prompt PK_CURSORS
alter index PK_CURSORS rebuild compute statistics;

prompt IDX_DEPENDENCIES_REFCED
alter index IDX_DEPENDENCIES_REFCED rebuild compute statistics;

prompt IDX_DEPENDENCIES_REFCING
alter index IDX_DEPENDENCIES_REFCING rebuild compute statistics;

prompt IDX_DICT_CHANGES_MDATE
alter index IDX_DICT_CHANGES_MDATE rebuild compute statistics;

prompt PK_DICT_CHANGES
alter index PK_DICT_CHANGES rebuild compute statistics;

prompt PK_ENTITIES_ID
alter index PK_ENTITIES_ID rebuild compute statistics;

prompt IDX_ERRORS_METHOD_ID
alter index IDX_ERRORS_METHOD_ID rebuild compute statistics;

prompt IDX_FAVORITES_CLASS_ID
alter index IDX_FAVORITES_CLASS_ID rebuild compute statistics;

prompt IDX_FAVORITES_CRITERION_ID
alter index IDX_FAVORITES_CRITERION_ID rebuild compute statistics;

prompt IDX_FAVORITES_METHOD_ID
alter index IDX_FAVORITES_METHOD_ID rebuild compute statistics;

prompt IDX_FAVORITES_PARENT_ID
alter index IDX_FAVORITES_PARENT_ID rebuild compute statistics;

prompt IDX_FAVORITES_USERNAME
alter index IDX_FAVORITES_USERNAME rebuild compute statistics;

prompt PK_FAVORITES_ID
alter index PK_FAVORITES_ID rebuild compute statistics;

prompt IDX_FRM_LOCKS_USER_ID
alter index IDX_FRM_LOCKS_USER_ID rebuild compute statistics;

prompt PK_FRM_LOCKS_OBJ_ID
alter index PK_FRM_LOCKS_OBJ_ID rebuild compute statistics;

prompt FVR_FILTERS_FVR_ID
alter index FVR_FILTERS_FVR_ID rebuild compute statistics;

prompt PK_GUIDE_GROUPS_ID
alter index PK_GUIDE_GROUPS_ID rebuild compute statistics;

prompt IDX_HOST2PLP_METHOD_ID
alter index IDX_HOST2PLP_METHOD_ID rebuild compute statistics;

prompt IDX_HOST_SOURCES_ID
alter index IDX_HOST_SOURCES_ID rebuild compute statistics;

prompt PK_LICENSE_DATA
alter index PK_LICENSE_DATA rebuild compute statistics;

select nvl(owner,:s) tmpcol from project where type='TABLE' and name='LONG_DATA';

prompt IDX_LONG_DATA_CLASS_ID
exec &&tmpowner..admin_mgr.execute_sql('alter index IDX_LONG_DATA_CLASS_ID rebuild compute statistics')

prompt IDX_LONG_DATA_OBJECT_ID
exec &&tmpowner..admin_mgr.execute_sql('alter index IDX_LONG_DATA_OBJECT_ID rebuild compute statistics')

prompt PK_LONG_DATA_ID
exec &&tmpowner..admin_mgr.execute_sql('alter index PK_LONG_DATA_ID rebuild compute statistics')

prompt PK_LRAW_ID
alter index PK_LRAW_ID rebuild compute statistics;

prompt IDX_MACRO_VALUES_MACRO_ID
alter index IDX_MACRO_VALUES_MACRO_ID rebuild compute statistics;

prompt PK_MACRO_VALUES
alter index PK_MACRO_VALUES rebuild compute statistics;

prompt PK_MESSAGES_TOPIC_CODE
alter index PK_MESSAGES_TOPIC_CODE rebuild compute statistics;

prompt IDX_METHODS_CLASS_ID_FLAGS
alter index IDX_METHODS_CLASS_ID_FLAGS rebuild compute statistics;

prompt IDX_METHODS_FORM_ID
alter index IDX_METHODS_FORM_ID rebuild compute statistics;

prompt IDX_METHOD_ID_ACSB_USDRV
alter index IDX_METHOD_ID_ACSB_USDRV rebuild compute statistics;

prompt PK_METHODS_ID
alter index PK_METHODS_ID rebuild compute statistics;

prompt UNQ_METHODS_CLASS_SHORT_NAME
alter index UNQ_METHODS_CLASS_SHORT_NAME rebuild compute statistics;

prompt UNQ_METHODS_EXT_ID
alter index UNQ_METHODS_EXT_ID rebuild compute statistics;

prompt UNQ_METHODS_PACKAGE_NAME
alter index UNQ_METHODS_PACKAGE_NAME rebuild compute statistics;

prompt UNQ_METHODS_SRC_ID
alter index UNQ_METHODS_SRC_ID rebuild compute statistics;

prompt IDX_METHOD_GROUPS_CLASS_ID
alter index IDX_METHOD_GROUPS_CLASS_ID rebuild compute statistics;

prompt IDX_METHOD_GROUPS_PARENT_ID
alter index IDX_METHOD_GROUPS_PARENT_ID rebuild compute statistics;

prompt IDX_METHOD_GROUPS_USERNAME
alter index IDX_METHOD_GROUPS_USERNAME rebuild compute statistics;

prompt PK_METHOD_GROUPS_ID
alter index PK_METHOD_GROUPS_ID rebuild compute statistics;

prompt IDX_METH_GRP_MEMBERS_GROUP_ID
alter index IDX_METH_GRP_MEMBERS_GROUP_ID rebuild compute statistics;

prompt IDX_METH_GRP_MEMBERS_METHOD_ID
alter index IDX_METH_GRP_MEMBERS_METHOD_ID rebuild compute statistics;

prompt IDX_METHOD_PARAMS_CLASS_ID
alter index IDX_METHOD_PARAMS_CLASS_ID rebuild compute statistics;

prompt IDX_METHOD_PARAMS_CRIT_ID
alter index IDX_METHOD_PARAMS_CRIT_ID rebuild compute statistics;

prompt PK_MP_METH_ID_POS
alter index PK_MP_METH_ID_POS rebuild compute statistics;

prompt UNQ_MP_METHOD_ID_SHORT_NAME
alter index UNQ_MP_METHOD_ID_SHORT_NAME rebuild compute statistics;

prompt IDX_METHOD_RIGHTS_CLASS_ID
alter index IDX_METHOD_RIGHTS_CLASS_ID rebuild compute statistics;

prompt IDX_METHOD_RIGHTS_SUBJ_ID
alter index IDX_METHOD_RIGHTS_SUBJ_ID rebuild compute statistics;

prompt PK_MR_OBJ_ID_SUBJ_ID_CLASS_ID
alter index PK_MR_OBJ_ID_SUBJ_ID_CLASS_ID rebuild compute statistics;

prompt IDX_METHOD_VARS_CLASS_ID
alter index IDX_METHOD_VARS_CLASS_ID rebuild compute statistics;

prompt IDX_METHOD_VARS_CRIT_ID
alter index IDX_METHOD_VARS_CRIT_ID rebuild compute statistics;

prompt PK_METH_VAR_METH_ID_POS
alter index PK_METH_VAR_METH_ID_POS rebuild compute statistics;

prompt UNQ_METH_VAR_METHOD_ID_SN
alter index UNQ_METH_VAR_METHOD_ID_SN rebuild compute statistics;

prompt IDX_NUMERATORS_SYS
alter index IDX_NUMERATORS_SYS rebuild compute statistics;

prompt PK_NUMERATORS
alter index PK_NUMERATORS rebuild compute statistics;

prompt UNQ_NUMERATORS_CODE
alter index UNQ_NUMERATORS_CODE rebuild compute statistics;

prompt IDX_NUM_ATTRIBUTES_NUM_ID
alter index IDX_NUM_ATTRIBUTES_NUM_ID rebuild compute statistics;

prompt PK_NUM_ATTRIBUTES
alter index PK_NUM_ATTRIBUTES rebuild compute statistics;

prompt IDX_OBJECTS_OPTIONS_OPTION
alter index IDX_OBJECTS_OPTIONS_OPTION rebuild compute statistics;

prompt PK_OBJECTS_OPTIONS
alter index PK_OBJECTS_OPTIONS rebuild compute statistics;

prompt IDX_OBJECT_RIGHTS_CLASS_ID
alter index IDX_OBJECT_RIGHTS_CLASS_ID rebuild compute statistics;

prompt IDX_OBJECT_RIGHTS_SUBJ_ID
alter index IDX_OBJECT_RIGHTS_SUBJ_ID rebuild compute statistics;

prompt PK_OBJECT_RIGHTS_OID_SID_
alter index PK_OBJECT_RIGHTS_OID_SID_ rebuild compute statistics;

prompt IDX_OBJECT_RIGHTS_EX_CLASS_ID
alter index IDX_OBJECT_RIGHTS_EX_CLASS_ID rebuild compute statistics;

prompt IDX_OBJECT_RIGHTS_EX_RCLASS_ID
alter index IDX_OBJECT_RIGHTS_EX_RCLASS_ID rebuild compute statistics;

prompt IDX_OBJECT_RIGHTS_EX_SUBJ_ID
alter index IDX_OBJECT_RIGHTS_EX_SUBJ_ID rebuild compute statistics;

prompt PK_OBJECT_RIGHTS_EX
alter index PK_OBJECT_RIGHTS_EX rebuild compute statistics;

prompt IDX_OBJ_RIGHT_LST_CLASS_ID
alter index IDX_OBJ_RIGHT_LST_CLASS_ID rebuild compute statistics;

prompt IDX_OBJ_RIGHT_LST_OBJ_ID
alter index IDX_OBJ_RIGHT_LST_OBJ_ID rebuild compute statistics;

prompt PK_OBJ_RIGHT_LST
alter index PK_OBJ_RIGHT_LST rebuild compute statistics;

prompt IDX_OBJECT_RULES_CID_SID
alter index IDX_OBJECT_RULES_CID_SID rebuild compute statistics;

prompt IDX_OBJECT_RULES_SUBJ_ID
alter index IDX_OBJECT_RULES_SUBJ_ID rebuild compute statistics;

prompt PK_OBJ_STATIC
alter index PK_OBJ_STATIC rebuild compute statistics;

select nvl(owner,:s) tmpcol from project where type='TABLE' and name='ORSA_JOBS';

prompt IDX_ORSA_JOBS_CLASS_ID
exec &&tmpowner..admin_mgr.execute_sql('alter index IDX_ORSA_JOBS_CLASS_ID rebuild compute statistics')

prompt IDX_ORSA_JOBS_METHOD_ID
exec &&tmpowner..admin_mgr.execute_sql('alter index IDX_ORSA_JOBS_METHOD_ID rebuild compute statistics')

prompt IDX_ORSA_JOBS_SHED_PRIOR_RUN
exec &&tmpowner..admin_mgr.execute_sql('alter index IDX_ORSA_JOBS_SHED_PRIOR_RUN rebuild compute statistics')

prompt IDX_ORSA_JOBS_USERNAME
exec &&tmpowner..admin_mgr.execute_sql('alter index IDX_ORSA_JOBS_USERNAME rebuild compute statistics')

prompt PK_ORSA_JOBS_JOB_POS
exec &&tmpowner..admin_mgr.execute_sql('alter index PK_ORSA_JOBS_JOB_POS rebuild compute statistics')

prompt IDX_ORSA_JOBS_OUT_JOB_POS_TYPE
exec &&tmpowner..admin_mgr.execute_sql('alter index IDX_ORSA_JOBS_OUT_JOB_POS_TYPE rebuild compute statistics')

prompt PK_ORSA_JOBS_PAR_JOB_POS_PIECE
exec &&tmpowner..admin_mgr.execute_sql('alter index PK_ORSA_JOBS_PAR_JOB_POS_PIECE rebuild compute statistics')

prompt PK_ORSA_PAR_LOB
exec &&tmpowner..admin_mgr.execute_sql('alter index PK_ORSA_PAR_LOB rebuild compute statistics')

prompt PK_PRINTER_MACROS
alter index PK_PRINTER_MACROS rebuild compute statistics;

prompt UNQ_PRINTER_MACROS_NAME
alter index UNQ_PRINTER_MACROS_NAME rebuild compute statistics;

prompt PK_PRINTER_TYPES
alter index PK_PRINTER_TYPES rebuild compute statistics;

prompt UNQ_PRINTER_TYPES_NAME
alter index UNQ_PRINTER_TYPES_NAME rebuild compute statistics;

prompt PK_PROCEDURES
alter index PK_PROCEDURES rebuild compute statistics;

prompt IDX_PROCEDURE_RIGHTS_OBJ_SUBJ
alter index IDX_PROCEDURE_RIGHTS_OBJ_SUBJ rebuild compute statistics;

prompt IDX_PROCEDURE_RIGHTS_SUBJ_ID
alter index IDX_PROCEDURE_RIGHTS_SUBJ_ID rebuild compute statistics;

prompt PK_PROFILES
alter index PK_PROFILES rebuild compute statistics;

prompt PK_PROJECT_NAME_TYPE
alter index PK_PROJECT_NAME_TYPE rebuild compute statistics;

prompt PK_PROJECTS_ID
alter index PK_PROJECTS_ID rebuild compute statistics;

prompt PK_PROJECT_ENTRIES_PID_ID
alter index PK_PROJECT_ENTRIES_PID_ID rebuild compute statistics;

prompt PK_PROJECT_ENTRY_ATTR
alter index PK_PROJECT_ENTRY_ATTR rebuild compute statistics;

select nvl(owner,:s) tmpcol from project where type='TABLE' and name='QUERIES';

prompt PK_QUERIES_ID_TYPE
exec &&tmpowner..admin_mgr.execute_sql('alter index PK_QUERIES_ID_TYPE rebuild compute statistics')

prompt IDX_REPORT_FORMULA_METHOD_ID
alter index IDX_REPORT_FORMULA_METHOD_ID rebuild compute statistics;

prompt IDX_RPT_OBJ_NAME_TYPE
alter index IDX_RPT_OBJ_NAME_TYPE rebuild compute statistics;

prompt PK_RPT_OBJ_METH_NAME_TYPE
alter index PK_RPT_OBJ_METH_NAME_TYPE rebuild compute statistics;

prompt IDX_RPT_PARAM_REL_METHOD_ID
alter index IDX_RPT_PARAM_REL_METHOD_ID rebuild compute statistics;

prompt PK_REPORT_ROLES
alter index PK_REPORT_ROLES rebuild compute statistics;

prompt PK_REPORT_VIEWS_NAME
alter index PK_REPORT_VIEWS_NAME rebuild compute statistics;

prompt IDX_RTL_ENTRIES_METHOD_ID_NAME
alter index IDX_RTL_ENTRIES_METHOD_ID_NAME rebuild compute statistics;

prompt PK_RTL_ENTRIES_ID
alter index PK_RTL_ENTRIES_ID rebuild compute statistics;

prompt IDX_RTL_EVENTS_INSTANCE_TIME
alter index IDX_RTL_EVENTS_INSTANCE_TIME rebuild compute statistics;

prompt IDX_RTL_EVENTS_USER_ID
alter index IDX_RTL_EVENTS_USER_ID rebuild compute statistics;

prompt IDX_RTL_LOCKS_USER_ID
alter index IDX_RTL_LOCKS_USER_ID rebuild compute statistics;

prompt PK_RTL_LOCKS_ID
alter index PK_RTL_LOCKS_ID rebuild compute statistics;

prompt PK_RTL_PARAMS_RTL_ID_POS
alter index PK_RTL_PARAMS_RTL_ID_POS rebuild compute statistics;

prompt PK_RTL_USERS_ID
alter index PK_RTL_USERS_ID rebuild compute statistics;

prompt IDX_SECURITY_DOMAINS_PAR_ID
alter index IDX_SECURITY_DOMAINS_PAR_ID rebuild compute statistics;

prompt IDX_SECURITY_DOMAINS_RES_GRP
alter index IDX_SECURITY_DOMAINS_RES_GRP rebuild compute statistics;

prompt IDX_SECURITY_DOMAINS_REV_GRP
alter index IDX_SECURITY_DOMAINS_REV_GRP rebuild compute statistics;

prompt PK_SECURITY_DOMAINS
alter index PK_SECURITY_DOMAINS rebuild compute statistics;

prompt UNQ_SECURITY_DOMAINS_APP_ID
alter index UNQ_SECURITY_DOMAINS_APP_ID rebuild compute statistics;

prompt IDX_SECURITY_JOBS
alter index IDX_SECURITY_JOBS rebuild compute statistics;

prompt PK_SECURITY_JOBS
alter index PK_SECURITY_JOBS rebuild compute statistics;

prompt IDX_SDE_DOMAIN_USER
alter index IDX_SDE_DOMAIN_USER rebuild compute statistics;

prompt PK_SEC_DOMAIN_ENTRIES
alter index PK_SEC_DOMAIN_ENTRIES rebuild compute statistics;

prompt IDX_SDE_CHILD_PARENT
alter index IDX_SDE_CHILD_PARENT rebuild compute statistics;

prompt PK_SEC_DOMAIN_EQUALS
alter index PK_SEC_DOMAIN_EQUALS rebuild compute statistics;

prompt PK_SEQUENCES
alter index PK_SEQUENCES rebuild compute statistics;

prompt UNQ_SEQUENCES_STATUS
alter index UNQ_SEQUENCES_STATUS rebuild compute statistics;

prompt PK_SETTINGS_NAME
alter index PK_SETTINGS_NAME rebuild compute statistics;

prompt IDX_SOURCES_NAME
alter index IDX_SOURCES_NAME rebuild compute statistics;

prompt PK_STATES_CLASS_ID_ID
alter index PK_STATES_CLASS_ID_ID rebuild compute statistics;

prompt PK_STORAGE_PARAM_GROUP_NAME
alter index PK_STORAGE_PARAM_GROUP_NAME rebuild compute statistics;

prompt IDX_SE_EQUAL_SUBJ
alter index IDX_SE_EQUAL_SUBJ rebuild compute statistics;

prompt PK_SUBJ_EQUAL
alter index PK_SUBJ_EQUAL rebuild compute statistics;

prompt PK_SYSTEM_OPTIONS
alter index PK_SYSTEM_OPTIONS rebuild compute statistics;

prompt IDX_TOPICS_TOPIC_ID
alter index IDX_TOPICS_TOPIC_ID rebuild compute statistics;

prompt PK_TOPICS_CLASS_OWNER_TOPIC
alter index PK_TOPICS_CLASS_OWNER_TOPIC rebuild compute statistics;

prompt IDX_TRANS_CLASS_STATE_POS
alter index IDX_TRANS_CLASS_STATE_POS rebuild compute statistics;

prompt PK_TRANSITIONS_ID
alter index PK_TRANSITIONS_ID rebuild compute statistics;

prompt UNQ_TRANSITIONS_CLSID_SNAME
alter index UNQ_TRANSITIONS_CLSID_SNAME rebuild compute statistics;

prompt IDX_TRN_METHS_EXT_ID
alter index IDX_TRN_METHS_EXT_ID rebuild compute statistics;

prompt IDX_TRN_METHS_METHOD_ID
alter index IDX_TRN_METHS_METHOD_ID rebuild compute statistics;

prompt PK_TRN_METHS_CLASS_SNAME
alter index PK_TRN_METHS_CLASS_SNAME rebuild compute statistics;

prompt IDX_TRANSITION_RIGHTS_CLASS_ID
alter index IDX_TRANSITION_RIGHTS_CLASS_ID rebuild compute statistics;

prompt IDX_TRANSITION_RIGHTS_SUBJ_ID
alter index IDX_TRANSITION_RIGHTS_SUBJ_ID rebuild compute statistics;

prompt PK_TR_OBJ_ID_SUBJ_ID_CLASS_ID
alter index PK_TR_OBJ_ID_SUBJ_ID_CLASS_ID rebuild compute statistics;

prompt PK_USERS_USERNAME
alter index PK_USERS_USERNAME rebuild compute statistics;

prompt UNQ_USERS_OS_DOMAIN_USER
alter index UNQ_USERS_OS_DOMAIN_USER rebuild compute statistics;

prompt IDX_XDIAG_TYPE_ID
alter index IDX_XDIAG_TYPE_ID rebuild compute statistics;


spool off

