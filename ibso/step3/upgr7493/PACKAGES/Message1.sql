prompt message
create or replace
package message as
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/Message1.sql $
 *  $Author: Alexey $
 *  $Revision: 15072 $
 *  $Date:: 2012-03-06 13:41:17 #$
 */
    ERROR_NUMBER      constant pls_integer := -20100;
    SYS_ERROR_NUMBER  constant pls_integer := -20200;
    APP_ERROR_NUMBER  constant pls_integer := -20300;
    INFO_ERROR_NUMBER constant pls_integer := -20400;
    LOCK_ERROR_NUMBER constant pls_integer := -20500;
--
    EXEC_EXCEPTION  exception;
    PRAGMA EXCEPTION_INIT(EXEC_EXCEPTION, -20100);
    SYS_EXCEPTION  exception;
    PRAGMA EXCEPTION_INIT(SYS_EXCEPTION,  -20200);
    APP_EXCEPTION  exception;
    PRAGMA EXCEPTION_INIT(APP_EXCEPTION,  -20300);
--
    procedure app_error ( p_error IN varchar2,
        	              p_text  IN varchar2
					    );
    PRAGMA RESTRICT_REFERENCES ( app_error, WNDS, WNPS, TRUST );

    procedure lock_error ( p_error IN varchar2,
                           p_text  IN varchar2
                         );
    PRAGMA RESTRICT_REFERENCES ( lock_error, WNDS, WNPS, TRUST );

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
                	    );
    PRAGMA RESTRICT_REFERENCES ( sys_error, WNDS, WNPS, TRUST );

    procedure error ( p_topic varchar2,
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
                	 );
    PRAGMA RESTRICT_REFERENCES ( error, WNDS, WNPS, TRUST );

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
               );
    PRAGMA RESTRICT_REFERENCES ( err, WNDS, WNPS, TRUST );

    procedure raise_ ( p_error pls_integer,
                       p_text  varchar2,
                       p_propagate boolean default false
                     );
    PRAGMA RESTRICT_REFERENCES ( raise_, WNDS, WNPS, TRUST );

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
                      ) return varchar2 deterministic;
    PRAGMA RESTRICT_REFERENCES ( gettext, WNDS, WNPS, TRUST );

    function get_text ( p_topic varchar2,
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
                	  ) return varchar2 deterministic;
    PRAGMA RESTRICT_REFERENCES ( get_text, WNDS, WNPS );

    function  last_error ( p_last_topic OUT varchar2,
                           p_last_code  OUT varchar2,
                           p_last_msg   OUT varchar2,
                           p_clear      IN  boolean default FALSE
                         ) return number deterministic;
    PRAGMA RESTRICT_REFERENCES ( last_error, WNDS, WNPS, TRUST );

    function  last_message return varchar2 deterministic;
    PRAGMA RESTRICT_REFERENCES ( last_message, WNDS, WNPS );

    procedure clear(p_reset boolean default false);
    PRAGMA RESTRICT_REFERENCES ( clear, WNDS, WNPS, TRUST );

	procedure error_repeat ( p_text varchar2 default NULL );
    PRAGMA RESTRICT_REFERENCES ( error_repeat, WNDS, WNPS, TRUST );

    function  error_stack return varchar2;
    PRAGMA RESTRICT_REFERENCES ( error_stack, WNDS, WNPS, TRUST );

end message;
/
sho err

