alter table class_tables add OWNER VARCHAR2(30);

alter table class_tables add LOG_OWNER VARCHAR2(30);

alter table class_tab_columns add seq_num varchar2(1);

alter table class_partitions add MIRROR_OWNER VARCHAR2(30);

alter table storage_parameters modify (param_value varchar2(100));

drop table t_output;

create global temporary table t_output
  (nline number, text long)
  on commit preserve rows;

create table host_sources(
	id varchar2(30),
	type varchar2(12),
	module varchar2(100),
	code CLOB
)
  tablespace &&tusers
/

create index idx_host_sources_id on host_sources(id)
  tablespace &&tspacei
/


alter table rtl_parameters drop constraint fk_rtl_parameters_rtl_id;
alter table rtl_entries drop constraint fk_rtl_entries_method_id;

alter table dependencies add refs_count number;
alter table dependencies modify referencing_id varchar2(30);


