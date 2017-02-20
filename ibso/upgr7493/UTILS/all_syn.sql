prompt * creating view all_synonyms_simple
create or replace view
sys.all_synonyms_simple(owner,synonym_name,table_owner,table_name) as
select u.name, o.name, s.owner, s.name
  from sys.user$ u, sys.syn$ s, sys.obj$ o
 where o.obj# = s.obj#
   and o.type# = 5
   and o.owner# = u.user#
   and s.node is null
   and (
        o.owner# in (USERENV('SCHEMAID'), 1 /* PUBLIC */)  /* user's private, any public */
        or /* user has any privs on base object in local database */
        exists
        (select null
           from sys.objauth$ ba, sys.obj$ bo, sys.user$ bu
          where bu.name = s.owner
            and bo.name = s.name
            and bu.user# = bo.owner#
            and ba.obj# = bo.obj#
            and (   ba.grantee# in (select kzsrorol from x$kzsro)
                 or ba.grantor# = USERENV('SCHEMAID')
                )
        )
   )
/
sho err view sys.all_synonyms_simple

