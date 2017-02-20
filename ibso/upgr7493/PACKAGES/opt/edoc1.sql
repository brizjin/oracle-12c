def ws=--stdio.put_line_buf

var load_edoc varchar2(1)
var load_edoc_gen varchar2(1)
var mess varchar2(1000)

-- Зовем любую процедуру, чтобы избежать
-- ошибки: ... состояние пакета сброшено ...
exec dbms_session.reset_package;
exec edoc_mgr.Put('ss');
exec stdio.put_line_buf(edoc_gen.get_core_interface);

declare
    cur_ver varchar2(10);
    cur_int_ver pls_integer:= 0;
    new_int_ver pls_integer := 1;
    edoc_gen_exist pls_integer:= 0;
begin
    begin
       select 1 into edoc_gen_exist from user_objects
         where object_name='EDOC_GEN' and object_type='PACKAGE';
       begin
          execute immediate '
              begin
                  :result:= edoc_gen.get_core_interface;
              end;' using out cur_int_ver;
       exception when others then null;
       end;
    exception when NO_DATA_FOUND then null;
    end;
    &ws('before define edoc version ');
    execute immediate '
        begin
            :result := edoc_mgr.get_version;
        end;' using out cur_ver;
    &ws('after execute immediate');
    if cur_ver is null or cur_int_ver<>new_int_ver then
      :load_edoc:=1;
      :load_edoc_gen:=1;
      if cur_ver is null then
        :mess:='Устанавливаем стандартные пакеты EDOC_MGR, EDOC_GEN из дистрибутива.';
      else
        :mess:= 'Внимание !!!'||chr(10)||
                'Установленная версия ЭДО не поддерживается данной версией ТЯ.'||chr(10)||
                'Устанавливаем пакеты EDOC_MGR, EDOC_GEN из дистрибутива.';
      end if;
    else
      :load_edoc:=0;
      :load_edoc_gen:=0;
      :mess:= 'Установленная версия ЭДО поддерживается данной версией ТЯ.'||chr(10)||
              'Оставляем пакеты EDOC_MGR, EDOC_GEN без изменений.';
    end if;
exception when others then
    -- Если были ошибки, то либо edoc_mgr не
    -- существует, либо в нем еще нет функций поддержки версий,
    -- либо он содержит ошибки. В этом случае пересоздаем.
    :load_edoc := '1';
    :load_edoc_gen := '1';
    :mess := 'EDOC_MGR не существует, либо слишком старый, либо содержит ошибки.'||chr(10)||
             'Устанавливаем пакеты EDOC_MGR, EDOC_GEN из дистрибутива.';
end;
/

column edoc_spec new_value edoc_spec noprint
select decode(:load_edoc, '1', 'edoc_mg1.sql','dummy') edoc_spec from dual;

column edoc_body new_value edoc_body noprint
select decode(:load_edoc, '1', 'edoc_mg2.plb','dummy') edoc_body from dual;

column edoc_gen_spec new_value edoc_gen_spec noprint
select decode(:load_edoc_gen, '1', 'edoc_gen1.sql','dummy') edoc_gen_spec from dual;

column edoc_gen_body new_value edoc_gen_body noprint
select decode(:load_edoc_gen, '1', 'edoc_gen2.plb','dummy') edoc_gen_body from dual;

print mess

var load_hash varchar2(1)

exec forhash.close

begin
    :load_hash := '1';
    execute immediate '
        begin
            if false then forhash.add_port(null,null); end if;
        end;';
    :load_hash := '0';
    :mess := 'FORHASH использует библиотеку ЭДО hashrpc.'||chr(10)||
             'Оставляем пакет FORHASH без изменений.';
exception when others then
    -- Если была ошибка разбора, то либо пакет forhash не
    -- существует, либо он не использует библиотеку ЭДО hashrpc.
    -- В этом случае пересоздаем.
    :mess := 'FORHASH не существует, либо не использует библиотеку ЭДО hashrpc.'||chr(10)||
             'Устанавливаем стандартный пакет FORHASH из дистрибутива,'||chr(10)||
             'который использует библиотеку libhash.';
end;
/

column xxx new_value hash_spec noprint
select decode(:load_hash, '1', 'fhash1','dummy') xxx from dual;

column xxx new_value hash_body noprint
select decode(:load_hash, '1', 'fhash2','dummy') xxx from dual;

print mess


