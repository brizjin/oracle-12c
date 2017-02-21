set echo on

prompt creating indexes

declare
    query varchar2(32767);
begin

    for idx_rec in (select t.diary_suffix table_name, i.index_suffix index_name,
                        i.is_unique, i.index_fields, t.idx_tablespace_name, t.storage_freelists,
                        i.storage_initial, i.storage_next
                      from diary_tables t, diary_indexes i
                      where t.owner = '_AUD' and t.owner=i.owner and t.diary_type=i.diary_type) loop
        query := 'create ';
        if idx_rec.is_unique = 'T' then
            query := query || 'unique ';
        end if;
        query := query || 'index ' || idx_rec.index_name
            || ' on ' || idx_rec.table_name || '(' || upper(idx_rec.index_fields) || ')';

        query := query  || chr(10) || '  pctfree 0 initrans 2 maxtrans 255';
        if idx_rec.idx_tablespace_name is not null then
            query := query  || ' tablespace ' || idx_rec.idx_tablespace_name || ' ';
        end if;

        query := query  || chr(10) || '  storage (';
        if idx_rec.storage_initial is not null then
            query := query  || 'initial ' || idx_rec.storage_initial || ' ';
        end if;
        if idx_rec.storage_next is not null then
            query := query  || 'next ' || idx_rec.storage_next || ' ';
        end if;
        if idx_rec.storage_freelists is not null then
            query := query  || 'freelists ' || idx_rec.storage_freelists || ' ';
        end if;
        query := query  || 'minextents 1 maxextents UNLIMITED pctincrease 0)' || chr(10);
--        utils.put_line(':' || replace(query, chr(10), chr(10) || ':'));
        begin
            utils.execute_sql(query, 'Creating index ' ||idx_rec.index_name);
        exception when others then
            null;
        end;
    end loop;
end;
/

alter table diary add constraint PK_DIARY_ID PRIMARY KEY(ID);

alter table DIARY_PARAM add constraint FK_DIARY_PARAM_DIARY_ID
  foreign key(DIARY_ID) references DIARY(ID)  on delete cascade;

exec utils.create_indexes('&&OWNER', utils.DIARY1)
exec utils.create_indexes('&&OWNER', utils.DIARY2)
exec utils.create_indexes('&&OWNER', utils.DIARY3)
exec utils.create_indexes('&&OWNER', utils.DIARY4)
exec utils.create_indexes('&&OWNER', utils.DIARY5)
exec utils.create_indexes('&&OWNER', utils.DIARY6)
exec utils.create_indexes('&&OWNER', utils.DIARY7)
exec utils.create_indexes('&&OWNER', utils.VALSH)
exec utils.create_indexes('&&OWNER', utils.OSH)
exec utils.create_indexes('&&OWNER', utils.OCH)
exec utils.create_indexes('&&OWNER', utils.DP)
exec utils.create_indexes('&&OWNER', utils.EDH)

set echo off

