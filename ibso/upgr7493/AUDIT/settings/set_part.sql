set termout off
declare
  c pls_integer;
begin
  select count(*) into c from diary_partitions where
    owner = '&&OWNER' and diary_step = '&&DIARY_STEP' and step_number = &&STEP_NUMBER;
  if c = 0 then
    insert into diary_partitions values('&&OWNER', '&&DIARY_STEP', &&STEP_NUMBER, '&&DIARY_TBS', '&&DIARY_IDX_TBS');
  else
    update diary_partitions set
        tablespace_name = '&&DIARY_TBS',
        idx_tablespace_name = '&&DIARY_IDX_TBS'
      where
        owner = '&&OWNER' and diary_step = '&&DIARY_STEP' and step_number = &&STEP_NUMBER;
  end if;
end;
/
set termout on
