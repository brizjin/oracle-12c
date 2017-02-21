set termout off
declare
  c pls_integer;
begin
  select count(*) into c from diary_indexes where
    owner = '&&OWNER' and diary_type = &&DIARY_TYPE and index_suffix = '&&INDEX_SUFFIX';
  if c = 0 then
    insert into diary_indexes values('&&OWNER', &&DIARY_TYPE, '&&INDEX_SUFFIX',
      '&&INDEX_UNIQUE', '&&INDEX_FIELDS', '&&IINIT', '&&INEXT');
  else
    update diary_indexes set
        is_unique = '&&INDEX_UNIQUE',
        index_fields = '&&INDEX_FIELDS',
        storage_initial = '&&IINIT',
        storage_next =  '&&INEXT'
      where
        owner = '&&OWNER' and diary_type = &&DIARY_TYPE and index_suffix = '&&INDEX_SUFFIX';
  end if;
end;
/
set termout on
