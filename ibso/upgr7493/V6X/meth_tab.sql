alter table method_parameters drop constraint chk_mp_flag;

alter table method_parameters add constraint chk_mp_flag
check(FLAG is not null and FLAG in ('A','B','C','D','T','R'));

alter table method_variables drop constraint chk_meth_var_flag;

alter table method_variables add constraint chk_meth_var_flag
check(FLAG is not null and FLAG in ('A','B','C','D','T','R'));

create index idx_method_params_class_id
  on method_parameters(class_id)
  tablespace &&tspacei;

create index idx_method_vars_class_id
  on method_variables(class_id)
  tablespace &&tspacei;

drop index IDX_DEPENDENCIES_REFCING;

create index idx_dependencies_refcing
  on dependencies(referencing_id)
  tablespace &&tspacei;

create index idx_dependencies_refced
  on dependencies(referenced_id)
  tablespace &&tspacei;


