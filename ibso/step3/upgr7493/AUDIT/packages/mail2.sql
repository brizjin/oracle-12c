prompt mail_mgr body
create or replace package body
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/AUD/mail2.sql $
 *  $Author: ryzhih $
 *  $Revision: 48634 $
 *  $Date:: 2014-07-11 11:51:46 #$
 */
mail_mgr is
--
-- notifications :
    --owner   varchar2(30),
    --event   varchar2(30),
    --status  varchar2(16),
    --subject varchar2(30),
    --message varchar2(30),
    --sender  varchar2(64),
    --name    varchar2(200),
    --description varchar2(1000)
--
    NL constant  varchar2(2) := chr(13)||chr(10);
    db_encoding  varchar2(40);
--
type owner_info is record(
      encode  varchar2(40),
      server  varchar2(64),
      sender  varchar2(64),
      name    varchar2(200),
      need_converting boolean,
      port number,
      auth varchar2(3),    -- авторизация на SMTP сервере
      user varchar2(64),   -- логин для авторизации
      pass varchar2(64),   -- пароль для авторизации
      charset varchar2(40) -- строка кодировки;
    );
type owner_info_tbl is table of owner_info index by binary_integer;
    owners owner_info_tbl;
type msg_info is record(
      c_subj  varchar2(30),
      c_body  varchar2(30),
      c_send  varchar2(64),
      c_name  varchar2(300),
      c_status  varchar2(16),
      c_rcpt    varchar2(1000)
    );
--
-- Функция для преобразования заголовка письма в соответствии со стандартом RFC 2047
-- (преобразование темы письма в base64 и оборачивание в доп. тег с указанием кодировки)
function subj_RFC2047(p_subj varchar2, p_own owner_info) return varchar2 is
    v_block constant number := 24; -- размер блока для utf8 не более 24, для остальных не более 47
    result varchar2(4000);
    v_subj varchar2(4000);
    v_part varchar2(30);
begin
  v_subj := p_subj;
  while nvl(length(v_subj),0) > 0 loop
    v_part := substr(v_subj, 1, v_block);
    result :=
      result || '=?'|| p_own.charset ||'?B?'
      || UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode(UTL_RAW.cast_to_raw(v_part)))
      || '?=';
    v_subj := substr(v_subj, v_block+1);
  end loop;
  return result;
END;
--
procedure fill_owner(p_owner varchar2,p_idx pls_integer) is
  v_rec owner_info;
  l_tmp varchar2(64);
begin
  if db_encoding is null then
    select value into db_encoding from nls_database_parameters where parameter = 'NLS_CHARACTERSET';
  end if;
  v_rec.encode := nvl(utils.get_value(p_owner,'MAIL_ENCODING'),'CL8KOI8R');
  l_tmp := utils.get_value(p_owner,'MAIL_SERVER');
  v_rec.server := nvl(substr(l_tmp,1,instr(l_tmp, ':',-1)-1), l_tmp);
  v_rec.sender := utils.get_value(p_owner,'MAIL_DEF_SENDER');
  v_rec.name   := utils.get_value(p_owner,'MAIL_DEF_SENDER_NAME');
  v_rec.auth   := utils.get_value(p_owner,'MAIL_AUTH');
  v_rec.user   := utils.get_value(p_owner,'MAIL_USER');
  v_rec.pass   := utils.get_value(p_owner,'MAIL_PASS');

  if v_rec.encode='CL8KOI8R' then
    v_rec.charset := 'koi8-r';
  elsif v_rec.encode='CL8MSWIN1251' then
    v_rec.charset := 'windows-1251';
  elsif v_rec.encode='CL8ISO8859P5' then
    v_rec.charset := 'iso-8859-5';
  elsif v_rec.encode='UTF8' then
    v_rec.charset := 'utf-8';
  else
    v_rec.charset := null;
  end if;

  if v_rec.sender is null then
    v_rec.sender := 'Revisor_'||v_rec.server;
  end if;

  begin
    v_rec.port := to_number(ltrim(replace(l_tmp, v_rec.server, ''),':'));
  exception when INVALID_NUMBER then
    v_rec.port := null;
  end;

  v_rec.need_converting := v_rec.encode<>db_encoding;
  --DOSTEXT := 'RU8PC866';
  --UNXTEXT := 'CL8ISO8859P5';
  --WINTEXT := 'CL8MSWIN1251';
  --KOITEXT := 'CL8KOI8R';
  owners(p_idx) := v_rec;

end;
--
function init_owner(p_owner varchar2) return pls_integer is
  i pls_integer;
begin
  i := dbms_utility.get_hash_value(p_owner,0,2147483647);
  if not owners.exists(i) then
    fill_owner(p_owner,i);
  end if;
  return i;
end;
--
procedure reset_owner(p_owner varchar2) is
begin
  if p_owner is null then
    owners.delete;
  else
    owners.delete(dbms_utility.get_hash_value(p_owner,0,2147483647));
  end if;
end;
--
procedure set_notification(p_owner   varchar2, p_event   varchar2,
                           p_subject varchar2, p_message varchar2,
                           p_sender  varchar2, p_sender_name varchar2,
                           p_description varchar2) is
  v_sender varchar2(100);
  v_name   varchar2(500);
  i pls_integer;
begin
  update notifications set
    subject = nvl(p_subject,subject),
    message = nvl(p_message,message),
    sender  = nvl(p_sender,sender),
    name    = nvl(p_sender_name,name),
    description= nvl(p_description,description)
  where owner = p_owner and event = p_event;
  if sql%notfound then
    if p_sender is null then
      i := init_owner(p_owner);
      v_sender := owners(i).sender;
      v_name := owners(i).name;
    else
      v_sender := p_sender;
      v_name := p_sender_name;
    end if;
    insert into  notifications(owner,event,status,subject,message,sender,name,description)
    values(p_owner,p_event,'ACTIVE',p_subject,p_message,v_sender,v_name,p_description);
  end if;
end;
--
procedure set_notification_status(p_owner varchar2, p_event varchar2, p_status varchar2) is
begin
  if p_status='DELETE' then
    delete from recipients where owner = p_owner and event = p_event;
    delete from notifications where owner = p_owner and event = p_event;
  else
    update notifications set status = nvl(p_status,status)
     where owner = p_owner and event = p_event;
  end if;
end;
--
-- recipients :
    --owner   varchar2(30),
    --event   varchar2(30),
    --status  varchar2(16),
    --email   varchar2(64),
    --name    varchar2(200)
procedure set_recipient(p_owner varchar2, p_event varchar2,
                        p_email varchar2, p_name  varchar2) is
begin
  update recipients set
    name  = nvl(p_name,name)
   where owner = p_owner and event = p_event and email = p_email;
  if sql%notfound then
    insert into recipients(owner,event,status,email,name)
    values(p_owner,p_event,'ACTIVE',p_email,p_name);
  end if;
end;
--
procedure set_recipient_status(p_owner varchar2, p_event  varchar2,
                               p_email varchar2, p_status varchar2) is
begin
  if p_status='DELETE' then
    delete from recipients where owner = p_owner and event = p_event and email = p_email;
  else
    update recipients set status = nvl(p_status,status)
     where owner = p_owner and event = p_event and email = p_email;
  end if;
end;
--
procedure chk_encoding(p_own owner_info, p_text in out nocopy varchar2) as
begin
  if p_own.need_converting then
    p_text := convert(p_text,p_own.encode,db_encoding);
  end if;
end;
--
procedure init_(
  p_owner varchar2, p_event varchar2,
  p_own in out owner_info, p_msg_info in out msg_info
) is
  i pls_integer;
begin
  select subject, message, name, status
    into p_msg_info.c_subj, p_msg_info.c_body, p_msg_info.c_name, p_msg_info.c_status
    from notifications where owner=p_owner and event=p_event;
  if p_msg_info.c_status<>'ACTIVE' then
    raise no_data_found;
  end if;
  i := init_owner(p_owner);
  p_own := owners(i);
  p_msg_info.c_send := p_own.sender;
  if p_msg_info.c_name is null then
    p_msg_info.c_name := p_own.name;
  end if;
  if p_msg_info.c_name is null or p_msg_info.c_name=p_msg_info.c_send then
    p_msg_info.c_name := p_msg_info.c_send;
  else
    p_msg_info.c_name := '"'||p_msg_info.c_name||'"<'||p_msg_info.c_send||'>';
    chk_encoding(p_own, p_msg_info.c_name);
  end if;
end;
--
function open_msg(
  p_owner varchar2, p_event varchar2,
  p_own owner_info, p_msg_info in out msg_info
) return utl_smtp.connection is
  v_conn   utl_smtp.connection;
  b        boolean;
  v_ok    boolean;
  procedure chk_recipients(p_set boolean) is
    v_str  varchar2(300);
  begin
    b := true;
    if p_set then
      v_ok := false;
    end if;
    p_msg_info.c_send := null;
    for r in (
      select email,name,status from recipients
       where owner=p_owner and event=p_event and status<>'INACTIVE'
    ) loop
      v_str := null;
      if p_set then
        utl_smtp.rcpt(v_conn,r.email);
        v_ok := true;
        if b and r.status='ACTIVE' then
          if r.name is null or r.name=r.email then
            v_str := r.email;
          else
            v_str := '"'||r.name||'"<'||r.email||'>';
            chk_encoding(p_own, v_str);
          end if;
        end if;
      elsif b and r.status='ACTIVE' then
        v_str := r.email;
      end if;
      if not v_str is null then
        if p_msg_info.c_rcpt is null then
          p_msg_info.c_rcpt := v_str;
        elsif length(p_msg_info.c_rcpt)+1+length(v_str)>1000 then
          b := false;
        else
          p_msg_info.c_rcpt := p_msg_info.c_rcpt||';'||v_str;
        end if;
      end if;
    end loop;
  end;
begin
  if(p_own.port is null) then
    v_conn := utl_smtp.open_connection(p_own.server);
  else
    v_conn := utl_smtp.open_connection(p_own.server, p_own.port);
  end if;
  utl_smtp.ehlo(v_conn, p_own.server);
  -- Авторизация на SMTP сервере
  if (p_own.auth = 'YES') then
    UTL_SMTP.auth(v_conn, p_own.user,p_own.pass, utl_smtp.ALL_SCHEMES);
  end if;
  utl_smtp.mail(v_conn, p_msg_info.c_send);
  chk_recipients(true);
  if not v_ok then
    utl_smtp.quit(v_conn);
    v_conn := null;
    raise no_data_found;
  end if;
  if not b then
    chk_recipients(false);
  end if;
  utl_smtp.open_data(v_conn);
  return v_conn;
end;
--
procedure set_header(p_conn in out utl_smtp.connection, p_name varchar2, p_header varchar2) as
begin
  utl_smtp.write_raw_data(p_conn,utl_raw.cast_to_raw(p_name||': '||p_header||NL));
end;

--
procedure header_msg(p_conn in out utl_smtp.connection, p_own owner_info, p_msg_info msg_info
  , p_format varchar2 default 'plain'
) is
begin
  set_header(p_conn, 'From',p_msg_info.c_name);

  set_header(p_conn, 'To',  p_msg_info.c_rcpt);
  set_header(p_conn, 'MIME-Version','1.0');

  set_header(p_conn, 'Content-Type','text/'||p_format||';'||case when p_own.charset is not null then 'charset="' else null end || p_own.charset ||'"');
  set_header(p_conn, 'Content-Transfer-Encoding','8bit');
end;
--
procedure close_msg(p_conn in out utl_smtp.connection) is
begin
  utl_smtp.close_data(p_conn);
  utl_smtp.quit(p_conn);
end;
--
procedure send_notify(p_owner varchar2, p_event varchar2,
                      p_subj1 varchar2, p_subj2 varchar2, p_subj3 varchar2,
                      p_mes1  varchar2, p_mes2  varchar2, p_mes3  varchar2,
                      p_mes4  varchar2, p_mes5  varchar2, p_mes6  varchar2,
                      p_mes7  varchar2, p_mes8  varchar2, p_mes9  varchar2) is
  c           utl_smtp.connection;
  v_own       owner_info;
  v_msg_info   msg_info;
  v_mes       varchar2(4000);
begin
  init_(p_owner, p_event, v_own, v_msg_info);
  c := open_msg(p_owner, p_event, v_own, v_msg_info);
  header_msg(c, v_own, v_msg_info);

  v_mes := utils.gettext('SUBJ',v_msg_info.c_subj,p_subj1,p_subj2,p_subj3);
  chk_encoding(v_own, v_mes);
  set_header(c, 'Subject',subj_RFC2047(v_mes,v_own));
  v_mes := utils.gettext('BODY',v_msg_info.c_body,p_mes1,p_mes2,p_mes3,p_mes4,p_mes5,p_mes6,p_mes7,p_mes8,p_mes9);
  chk_encoding(v_own, v_mes);
  utl_smtp.write_raw_data(c,utl_raw.cast_to_raw(NL||v_mes));

  close_msg(c);
exception
  when utl_smtp.transient_error or utl_smtp.permanent_error then
    begin
      utl_smtp.quit(c);
    exception
      when utl_smtp.transient_error or utl_smtp.permanent_error then
        null; -- when the smtp server is down or unavailable, we don't have
              -- a connection to the server. the quit call will raise an
              -- exception that we can ignore.
    end;
    utils.error('FAILED_SMTP',sqlerrm);
  when no_data_found then
    null;
end;
--
procedure send_notify(p_owner varchar2, p_event varchar2, p_subj varchar2, p_body CLOB) is
  v_conn      utl_smtp.connection;
  v_own       owner_info;
  v_msg_info   msg_info;
  v_str       varchar2(4000);
  v_body      clob;
  v_len       number;
  v_amount    number  := 4000;
  v_offset    pls_integer;
begin
  init_(p_owner, p_event, v_own, v_msg_info);
  v_conn := open_msg(p_owner, p_event, v_own, v_msg_info);
  header_msg(v_conn, v_own, v_msg_info, 'html');

  v_str := p_subj;
  chk_encoding(v_own, v_str);
  set_header(v_conn, 'Subject',subj_RFC2047(v_str,v_own));

  dbms_lob.createtemporary(v_body,true);
  v_body := p_body;
  v_len := dbms_lob.getlength(v_body);
  v_offset:= 1;
  utl_smtp.write_raw_data(v_conn, utl_raw.cast_to_raw(NL));
  while v_len > 0 loop
    v_amount := least(v_len, 4000);
    dbms_lob.read(v_body, v_amount, v_offset, v_str);
    chk_encoding(v_own, v_str);
    utl_smtp.write_raw_data(v_conn, utl_raw.cast_to_raw(v_str));
    v_len := v_len - v_amount;
    v_offset := v_offset + v_amount;
  end loop;

  close_msg(v_conn);
exception
  when utl_smtp.transient_error or utl_smtp.permanent_error then
    begin
      utl_smtp.quit(v_conn);
    exception
      when utl_smtp.transient_error or utl_smtp.permanent_error then
        null; -- when the smtp server is down or unavailable, we don't have
              -- a connection to the server. the quit call will raise an
              -- exception that we can ignore.
    end;
    utils.error('ERROR',sqlerrm);
  when no_data_found then
    null;
end;
end;
/
show err package body mail_mgr
