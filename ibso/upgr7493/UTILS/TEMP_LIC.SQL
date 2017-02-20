exec dbms_session.reset_package

prompt Temporary License for Primary Installation

declare
  t_lic_id         DBMS_SQL.varchar2s;
  t_lic_limit      DBMS_SQL.Varchar2_Table;
  t_lic_usage      DBMS_SQL.varchar2s;
  t_lic_usage_date DBMS_SQL.date_table;
  t_lic_api_check  DBMS_SQL.varchar2s;
  t_lic_crc_row    DBMS_SQL.number_table;
  t_opt_id         "CONSTANT".REFSTRING_TABLE;
  t_opt_parent_id  "CONSTANT".REFSTRING_TABLE;
  t_opt_name       DBMS_SQL.Varchar2_Table;
  t_opt_type       "CONSTANT".REFSTRING_TABLE;
  t_opt_check_type "CONSTANT".REFSTRING_TABLE;
  t_opt_get_sql    OPT_MGR.Varchar4K_Table;
  t_opt_crc_row    "CONSTANT".NUMBER_TABLE;
  t_opt_crc_tree   "CONSTANT".NUMBER_TABLE;
  t_opt_crc_obj    "CONSTANT".NUMBER_TABLE;
  t_opt_required   "CONSTANT".REFSTRING_TABLE;
  t_opt_version    "CONSTANT".REFSTRING_TABLE;
  t_opt_ver_sql    DBMS_SQL.Varchar2_Table;
  i pls_integer;
  t_obj_type       "CONSTANT".REFSTRING_TABLE;
  t_obj_class_id   "CONSTANT".REFSTRING_TABLE;
  t_obj_short_name "CONSTANT".REFSTRING_TABLE;
  t_obj_option_id  "CONSTANT".REFSTRING_TABLE;
  t_opt_licensed "CONSTANT".VARCHAR2S;
  t_opt_loc "CONSTANT".VARCHAR2S;

LF      constant varchar2(1) := chr(10);
procedure add_array(lic_id varchar2,lic_limit varchar2, lic_usage varchar2,lic_usage_date date,lic_crc_row number,
                    opt_parent_id varchar2, opt_name varchar2, opt_type varchar2, opt_check_type varchar2,
                    opt_get_sql varchar2, opt_crc_row number, opt_crc_tree number, opt_crc_obj number,
                    opt_required varchar2, opt_version varchar2, opt_ver_sql varchar2)  is
i pls_integer;


begin
  i:= nvl(t_lic_id.last,0)+1;
  t_lic_id(i)         := lic_id;
  t_lic_limit(i)      := lic_limit;
  t_lic_usage(i)      := lic_usage;
  t_lic_usage_date(i) := lic_usage_date;
  t_lic_crc_row(i)    := lic_crc_row;
  t_lic_api_check(i)  := 0;
  t_opt_id(i)         := lic_id;
  t_opt_parent_id(i)  := opt_parent_id;
  t_opt_name(i)       := opt_name;
  t_opt_type(i)       := opt_type;
  t_opt_check_type(i) := opt_check_type;
  t_opt_get_sql(i)    := opt_get_sql;
  t_opt_crc_row(i)    := opt_crc_row;
  t_opt_crc_tree(i)   := opt_crc_tree;
  t_opt_crc_obj(i)    := opt_crc_obj;
  t_opt_required(i)   := opt_required;
  t_opt_version(i)    := opt_version;
  t_opt_ver_sql(i)    := opt_ver_sql;
  t_opt_licensed(i)   := 1;
  t_opt_loc(i)        := 0;
end;

procedure add_obj_array(obj_type varchar2, class_id varchar2, short_name varchar2) is
i pls_integer;
begin
    i:= nvl(t_obj_type.last,0)+1;
    t_obj_type(i)        := obj_type;
    t_obj_class_id(i)    := class_id;
    t_obj_short_name(i)  := short_name;
    t_obj_option_id(i)   := 'CORE';
end;

begin

  if AUD.lic_mgr.get_limit('&&OWNER', 'INSTALLATION_ID') is null then

    add_array(lic_id=>'CORE', lic_limit=>null, lic_usage=>'1', lic_usage_date=>null,
              lic_crc_row=>1714658656, opt_parent_id=>null, opt_name=>null, opt_type=>'STRING',
              opt_check_type=>null, opt_get_sql=>null, opt_crc_row=>1105283638, opt_crc_tree=>3995269430,
              opt_crc_obj=>null,opt_required=>null,opt_version=>null,opt_ver_sql=>null);

    add_array(lic_id=>'APPLICATION_ID', lic_limit=>'TEMP', lic_usage=>'1', lic_usage_date=>null,
              lic_crc_row=>1987866448, opt_parent_id=>'CORE', opt_name=>'Application ID', opt_type=>'STRING',
              opt_check_type=>'EQ', opt_crc_row=>2493684872, opt_crc_tree=>null,
              opt_crc_obj=>null,opt_required=>null,opt_version=>null,opt_ver_sql=>null,
              opt_get_sql=>
              'declare s varchar2(100);' || chr(10)||
              'begin' || chr(10) ||
              '  if to_date(inst_info.build_date,''DD-MM-YYYY HH24:MI:SS'') between (sysdate-10) and sysdate' || chr(10)||
              '   then s:=''TEMP''; else s:=''EXPIRED''; end if;' || chr(10)||
              '  :res:=s;' || chr(10)||
              'end;'
              );

    add_array(lic_id=>'ADMIN_GRP_ENABLED', lic_limit=>null, lic_usage=>'1', lic_usage_date=>null,
              lic_crc_row=>4237314594, opt_parent_id=>'CORE', opt_name=>'ADMIN_GRP_ENABLED', opt_type=>'STRING',
              opt_check_type=>'EQ', opt_crc_row=>3919317701, opt_crc_tree=>null,
              opt_crc_obj=>null,opt_required=>null,opt_version=>null,opt_ver_sql=>null,
              opt_get_sql=>null);

    add_array(lic_id=>'INSTALLATION_ID', lic_limit=>'TEMP', lic_usage=>'1', lic_usage_date=>null,
              lic_crc_row=>3650514354, opt_parent_id=>'CORE', opt_name=>'Installation ID', opt_type=>'STRING',
              opt_check_type=>'EQ', opt_crc_row=>4149748291, opt_crc_tree=>null,
              opt_crc_obj=>null,opt_required=>null,opt_version=>null,opt_ver_sql=>null,
              opt_get_sql=>'INSTALLATION_ID');


    add_array(lic_id=>'SYS_NAME', lic_limit=>'Временная лицензия', lic_usage=>'1', lic_usage_date=>null,
              lic_crc_row=>1282685824, opt_parent_id=>'CORE', opt_name=>'System name', opt_type=>'STRING',
              opt_check_type=>'EQ', opt_crc_row=>3495961546, opt_crc_tree=>null,
              opt_crc_obj=>null,opt_required=>null,opt_version=>null,opt_ver_sql=>null,
              opt_get_sql=>'SYS_NAME');


    add_array(lic_id=>'MAX_SESSIONS', lic_limit=>'20', lic_usage=>'1', lic_usage_date=>null,
              lic_crc_row=>1138736534, opt_parent_id=>'CORE', opt_name=>'Registered sessions limit', opt_type=>'NUM',
              opt_check_type=>'EQ', opt_crc_row=>1845629513, opt_crc_tree=>null,
              opt_crc_obj=>null,opt_required=>null,opt_version=>null,opt_ver_sql=>null,
              opt_get_sql=>'MAX_SESSIONS');

    add_array(lic_id=>'MAX_ADMINS', lic_limit=>'10', lic_usage=>'1', lic_usage_date=>null,
              lic_crc_row=>1611266887, opt_parent_id=>'CORE', opt_name=>'Dictionary admininstrators limit', opt_type=>'NUM',
              opt_check_type=>'LS', opt_crc_row=>2701848996, opt_crc_tree=>null,
              opt_crc_obj=>null,opt_required=>null,opt_version=>null,opt_ver_sql=>null,
              opt_get_sql=>
              'cnt number;' || chr(10)||
              'begin' || chr(10) ||
              '  select u(count(1)) in USERS%rowtype where u.[TYPE]=''U''' || chr(10)||
              '  and (u.[LOCK_STATUS] is null or u.[LOCK_STATUS] not in (''DELETED'',''LOCKED''))' || chr(10)||
              '  and (instr(u.[PROPERTIES],''|ADMIN'')>0 or instr(u.[PROPERTIES],''|PICKER'')>0)' || chr(10)||
              '  into cnt;' || chr(10)||
              '  return cnt; ' || chr(10) ||
              'end;'
              );

    add_array(lic_id=>'MAX_UADMINS', lic_limit=>'10', lic_usage=>'1', lic_usage_date=>null,
              lic_crc_row=>1674098979, opt_parent_id=>'CORE', opt_name=>'Access admininstrators limit', opt_type=>'NUM',
              opt_check_type=>'LS', opt_crc_row=>1849582044, opt_crc_tree=>null,
              opt_crc_obj=>null,opt_required=>null,opt_version=>null,opt_ver_sql=>null,
              opt_get_sql=>
              'cnt number;' || chr(10)||
              'begin' || chr(10) ||
              '  select u(count(1)) in USERS%rowtype where u.[TYPE]=''U''' || chr(10)||
              '  and (u.[LOCK_STATUS] is null or u.[LOCK_STATUS] not in (''DELETED'',''LOCKED''))' || chr(10)||
              '  and (instr(u.[PROPERTIES],''|UADMIN'')>0 or instr(u.[PROPERTIES],''|UPICKER'')>0)' || chr(10)||
              '  into cnt;' || chr(10)||
              '  return cnt; ' || chr(10) ||
              'end;'
              );


    add_array(lic_id=>'MAX_USERS', lic_limit=>'100', lic_usage=>'1', lic_usage_date=>null,
              lic_crc_row=>444227462, opt_parent_id=>'CORE', opt_name=>'Navigator users limit', opt_type=>'NUM',
              opt_check_type=>'LS', opt_crc_row=>509687394, opt_crc_tree=>null,
              opt_crc_obj=>null,opt_required=>null,opt_version=>null,opt_ver_sql=>null,
              opt_get_sql=>
              'cnt number;' || chr(10)||
              'begin' || chr(10) ||
              '  select u(count(1)) in USERS%rowtype where u.[TYPE]=''U''' || chr(10)||
              '    and (u.[LOCK_STATUS] is null or u.[LOCK_STATUS] not in (''DELETED'',''LOCKED''))' || chr(10)||
              '    and (instr(u.[PROPERTIES],''|LOCK'')=0 or instr(u.[PROPERTIES],''|REVISOR'')>0)'  || chr(10)||
              '  into cnt;' || chr(10)||
              '  return cnt; ' || chr(10) ||
              'end;'
              );

    add_array(lic_id=>'CHECK_SUM', lic_limit=>'2648331151', lic_usage=>'1', lic_usage_date=>null,
              lic_crc_row=>950082203, opt_parent_id=>'CORE', opt_name=>'CHECK_SUM', opt_type=>'NUM',
              opt_check_type=>'EQ', opt_crc_row=>147479588, opt_crc_tree=>null,
              opt_crc_obj=>null,opt_required=>null,opt_version=>null,opt_ver_sql=>null,
              opt_get_sql=>'CHECK_SUM');



    opt_mgr.prepare_license(true,t_lic_id,t_lic_limit,t_lic_usage,t_lic_usage_date,t_lic_crc_row,t_lic_api_check);
    opt_mgr.install_license;

    opt_mgr.prepare_options(true,t_opt_id,t_opt_parent_id,t_opt_name,t_opt_type,t_opt_check_type,t_opt_get_sql,t_opt_crc_row,
                            t_opt_crc_tree,t_opt_crc_obj,t_opt_required,t_opt_version,t_opt_ver_sql,t_opt_licensed,t_opt_loc);
    opt_mgr.install_options('CORE');

  end if;

end;
/

prompt Check system license values
declare
s varchar2(2000);
begin
   s:= opt_mgr.check_sys_value(false);
   stdio.put_line_buf('Status system values - ' || s);
end;
/

