set termout off
declare
  c pls_integer;
begin
  select count(*) into c from diary_tables where
    owner = '&&OWNER' and diary_type = &&DIARY_TYPE;
  if c = 0 then
    insert into diary_tables values('&&OWNER', &&DIARY_TYPE, '&&DIARY_SUFFIX',
        '&&DIARY_COLUMNS', '&&DIARY_STEP', null, '&&DIARY_TBS', '&&DIARY_IDX_TBS', '&&TINIT', '&&TNEXT', '&&FREELST');
  else
    update diary_tables set
        diary_suffix = '&&DIARY_SUFFIX',
        diary_fields = '&&DIARY_COLUMNS',
        diary_step = '&&DIARY_STEP',
        tablespace_name = '&&DIARY_TBS',
        idx_tablespace_name = '&&DIARY_IDX_TBS',
        storage_initial = '&&TINIT',
        storage_next =  '&&TNEXT',
        storage_freelists = '&&FREELST'
      where
        owner = '&&OWNER' and diary_type = &&DIARY_TYPE;
  end if;
end;
/
set termout on
