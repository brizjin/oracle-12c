var db_version number
declare
  s1 varchar2(100);
  s2 varchar2(100);
begin
  dbms_utility.db_version(s1,s2);
  :db_version := substr(s1,1,instr(s1,'.')-1);
end;
/

column xxx new_value cmt9 noprint
select decode(sign(:db_version-10),-1,'--','') xxx from dual;

prompt message body
create or replace package body
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/Message2.sql $
 *  $Author: Alexey $
 *  $Revision: 15072 $
 *  $Date:: 2012-03-06 13:41:17 #$
 */
message as
--
    last_errnum pls_integer;
    last_topic  varchar2(16);
    last_code   varchar2(30);
	last_msg    varchar2(32000);
    --
    LF  constant varchar2(1) := chr(10);
    --
    --type mes_tbl_t is table of varchar2(1000) index by varchar2(50);
    mes "CONSTANT".varchar2_table_s;--mes_tbl_t;
	max_mes_length  pls_integer;	-- limitation of raise_application_error text length
--
    function get_mes_length return pls_integer is
    begin
      if max_mes_length is null then
        max_mes_length := rtl.num_set('PLP_ERROR_MESSAGE_LENGTH');
        if max_mes_length between 11 and 2048 then
          return max_mes_length;
        end if;
        max_mes_length := 2048;
      end if;
      return max_mes_length;
    end;
--
    procedure raise_ ( p_error pls_integer,
                       p_text  varchar2,
                       p_propagate boolean default false
                     ) is
    begin
        raise_application_error( p_error, substr(p_text,1,get_mes_length), p_propagate );
    end;
--
    procedure app_error ( p_error IN varchar2,
        	              p_text  IN varchar2
					    ) is
	begin
		-- length(p_text) <= 2*1024
        last_errnum:= APP_ERROR_NUMBER;
		last_topic := constant.APP_ERROR;
        last_code  := upper(substr(p_error,1,30));
        last_msg   := constant.APP_ERROR || '-' || last_code || ': ' || p_text;
		raise_application_error(APP_ERROR_NUMBER, substr(last_msg,1,get_mes_length), false);
	end app_error;
--
    procedure lock_error ( p_error IN varchar2,
                           p_text  IN varchar2
                         ) is
	begin
		-- length(p_text) <= 2*1024
        last_errnum:= LOCK_ERROR_NUMBER;
        last_topic := constant.LOCK_ERROR;
        last_code  := upper(substr(p_error,1,30));
        last_msg   := constant.LOCK_ERROR || '-' || last_code || ': ' || p_text;
        raise_application_error(LOCK_ERROR_NUMBER, substr(last_msg,1,get_mes_length), false);
    end lock_error;
--
    procedure sys_error ( p_topic varchar2,
                          p_code  varchar2,
                	      p1      varchar2 default NULL,
	                      p2      varchar2 default NULL,
        	              p3      varchar2 default NULL,
                	      p4      varchar2 default NULL,
	                      p5      varchar2 default NULL,
        	              p6      varchar2 default NULL,
                	      p7      varchar2 default NULL,
	                      p8      varchar2 default NULL,
        	              p9      varchar2 default NULL
                	    ) is
	begin
        raise_application_error( SYS_ERROR_NUMBER, substr(get_text(p_topic,p_code,p1,p2,p3,p4,p5,p6,p7,p8,p9),1,get_mes_length), TRUE );
	end sys_error;
--
    procedure error( p_topic varchar2,
                     p_code  varchar2,
                	 p1      varchar2 default NULL,
	                 p2      varchar2 default NULL,
        	         p3      varchar2 default NULL,
                	 p4      varchar2 default NULL,
	                 p5      varchar2 default NULL,
        	         p6      varchar2 default NULL,
                	 p7      varchar2 default NULL,
	                 p8      varchar2 default NULL,
        	         p9      varchar2 default NULL
                	) is
	begin
        raise_application_error( ERROR_NUMBER, substr(get_text(p_topic,p_code,p1,p2,p3,p4,p5,p6,p7,p8,p9),1,get_mes_length), TRUE );
	end error;
--
	procedure err ( p_error pls_integer,
                    p_topic varchar2,
                    p_code  varchar2,
                	p1      varchar2 default NULL,
	                p2      varchar2 default NULL,
        	        p3      varchar2 default NULL,
                	p4      varchar2 default NULL,
	                p5      varchar2 default NULL,
        	        p6      varchar2 default NULL,
                	p7      varchar2 default NULL,
	                p8      varchar2 default NULL,
        	        p9      varchar2 default NULL
                  ) is
    begin
        raise_application_error( p_error, substr(get_text(p_topic,p_code,p1,p2,p3,p4,p5,p6,p7,p8,p9),1,get_mes_length), TRUE );
	end err;
--
    function  gettext ( p_topic varchar2,
                        p_code  varchar2,
                	    p1      varchar2 default NULL,
	                    p2      varchar2 default NULL,
        	            p3      varchar2 default NULL,
                	    p4      varchar2 default NULL,
	                    p5      varchar2 default NULL,
        	            p6      varchar2 default NULL,
                	    p7      varchar2 default NULL,
	                    p8      varchar2 default NULL,
                        p9      varchar2 default NULL
                	  ) return varchar2 is
		s varchar2(8000);
    begin
        s := p_topic||'.'||p_code;
        if mes.exists(s) then
          s := mes(s);
        else
		  begin
            select /*+ INDEX(messages) */ text into s
		      from messages
		     where topic = p_topic and code = p_code;
		  exception when NO_DATA_FOUND then
		    s := '%1 %2 %3 %4 %5 %6 %7 %8 %9';
		  end;
          mes(p_topic||'.'||p_code) := s;
        end if;
--
		s := replace(s,'\n',LF);
		s := replace(s,'%1',p1);
		s := replace(s,'%2',p2);
		s := replace(s,'%3',p3);
		s := replace(s,'%4',p4);
		s := replace(s,'%5',p5);
		s := replace(s,'%6',p6);
		s := replace(s,'%7',p7);
		s := replace(s,'%8',p8);
		s := replace(s,'%9',p9);
        return rtrim(s);
--
	exception when VALUE_ERROR then
        return null;
    end gettext;
--
    function  get_text( p_topic varchar2,
                        p_code  varchar2,
                	    p1      varchar2 default NULL,
	                    p2      varchar2 default NULL,
        	            p3      varchar2 default NULL,
                	    p4      varchar2 default NULL,
	                    p5      varchar2 default NULL,
        	            p6      varchar2 default NULL,
                	    p7      varchar2 default NULL,
	                    p8      varchar2 default NULL,
                        p9      varchar2 default NULL
                	  ) return varchar2 is
	begin
        return p_topic||'-'||p_code||': '||gettext(p_topic,p_code,p1,p2,p3,p4,p5,p6,p7,p8,p9);
	end get_text;
--
    function  error_stack return varchar2 is
    begin
      return dbms_utility.format_error_stack &&cmt9. || dbms_utility.format_error_backtrace
      ;
    end;
--
	procedure error_repeat ( p_text varchar2 default NULL ) is
        v_error pls_integer := sqlcode;
        v_msg   varchar2(32767);
	begin
      if v_error <> 0 then
        v_msg := rtrim(dbms_utility.format_error_stack,LF);
        if p_text is not null then
          v_msg := rtrim(p_text,LF)||LF||v_msg;
        end if;
        &&cmt9.v_msg := v_msg||LF||dbms_utility.format_error_backtrace;
        if v_error < -20999 or v_error > -20000 then
          v_error := ERROR_NUMBER;
        end if;
      else
        if p_text is null then
          if last_msg is null then
            v_msg := sqlerrm;
          else
            v_msg := last_msg;
          end if;
        else
          v_msg := p_text;
        end if;
        v_error := nvl(last_errnum, ERROR_NUMBER);
      end if;
      raise_application_error( v_error, substr(v_msg,1,get_mes_length), false );
	end error_repeat;
--
    function  last_error ( p_last_topic OUT varchar2,
                           p_last_code  OUT varchar2,
                           p_last_msg   OUT varchar2,
                           p_clear      IN  boolean default FALSE
                         ) return number is
	begin
        p_last_topic:= last_topic;
		p_last_code := last_code;
        p_last_msg  := last_msg;
        if p_clear then clear; end if;
        return last_errnum;
	end last_error;
--
	function last_message return varchar2 is
	begin
		return last_msg;
	end last_message;
--
    procedure clear(p_reset boolean default false) is
	begin
        last_errnum  := NULL;
        last_topic   := NULL;
        last_code    := NULL;
        last_msg     := NULL;
        if p_reset then
           mes.delete;
           max_mes_length := null;
        end if;
    end clear;
--
end message;
/
show errors package body message

