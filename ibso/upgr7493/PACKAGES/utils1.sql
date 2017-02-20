prompt utils package
CREATE OR REPLACE
PACKAGE UTILS IS
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/utils1.sql $
 *  $Author: almakarov $
 *  $Revision: 55349 $
 *  $Date:: 2014-11-14 14:20:25 #$
 *
 *  DBMS packages entry points for PL/PLUS
 */
--
  /*
     Exception raised for evaluation numeric expressions.
     while assigning result for internal integers (pls_integer,binary_integer)
     when this result cannot fit min/max bounds for these integers (-2147483647..2147483647)
  */
  numeric_overflow exception;
  pragma exception_init(numeric_overflow,-1426);
--
  /*
     Untyped Ref Cursor type
  */
  TYPE REF_CURSOR IS REF CURSOR;
  --SUBTYPE REF_CURSOR IS constant.REPORT_CURSOR;
--
  /*
      Suspend the session for the specified period of time.
      Input parameters:
        seconds
          In seconds, currently the maximum resolution is in hundreths of
          a second (e.g., 1.00, 1.01, .99 are all legal and distinct values).
  */
  procedure sleep(seconds in number);
--
  /*
      Find out the current time in 100th's of a second.
      Output arguments:
        get_time
          The time is the number of 100th's of a second from some
          arbitrary epoch.
  */
  function get_time return number;
--
  /*
      Format the current error stack.  This can be used in exception
        handlers to look at the full error stack.
      Returns the error message and its stack.
        p_stack
          TRUE. Add the error stack to the error message
  */
  function error_stack(p_stack boolean default true) return varchar2;
  pragma restrict_references(error_stack,WNDS,TRUST);
--
  /*
      Format the current call stack.  This can be used an any stored
        procedure or trigger to access the call stack.  This can be
        useful for debugging.
      Output arguments:
        call_stack
          Returns the call stack.  May be up to 2000 bytes.
  */
  function call_stack return varchar2;
  pragma restrict_references(call_stack,WNDS);
--
  /*
      Return an identifier that is unique for all sessions currently
        connected to this database.  Multiple calls to this function
        during the same session will always return the same result.
      Output arguments:
        session_id
          can return up to 24 bytes.
  */
  function session_id return varchar2 deterministic;
  pragma restrict_references(session_id,WNDS,RNDS,WNPS);
--
  /*
      Procedure for users to reclaim unused memory after performing operations
      requiring large amounts of memory (where large is >100K).  Note that
      this procedure should only be used in cases where memory is at a
      premium.
      Examples operations using lots of memory are:
         o  large sorts where entire sort_area_size is used and
            sort_area_size is hundreds of KB
         o  compiling large PL/SQL packages/procedures/functions
         o  storing hundreds of KB of data within PL/SQL indexed tables
  */
  procedure free_memory;
--
  /*
      Deinstantiate all packages in this session.  In other words, free
        all package state.  This is the situation at the beginning of
        a session.
     * P_FREE_ALL = TRUE:
         This frees all the memory associated with each of the
         previously run PL/SQL programs from the session, and,
         consequently, clears the current values of any package
         globals and closes any cached cursors. On subsequent use,
         the PL/SQL program units are re-instantiated and package
         globals are reinitialized. This is essentially the
         same as DBMS_SESSION.RESET_PACKAGE() interface.

     * P_FREE_ALL = FALSE:
         In terms of program semantics, the FALSE
         flag is similar to the TRUE flag
         in that both have the effect of re-initializing all packages.

         However, P_FREE_ALL = FALSE should exhibit much better
         performance than the P_FREE_ALL = TRUE option
         because:

           - packages are reinitialized without actually being freed
           and recreated from scratch. Instead the package memory gets
           reused.

           - any open cursors are closed, semantically speaking. However,
           the cursor resource is not actually freed. It is simply
           returned to the PL/SQL cursor cache. And more importantly,
           the cursor cache is not flushed. Hence, cursors
           corresponding to frequently accessed static SQL in PL/SQL
           will remain cached in the PL/SQL cursor cache and the
           application will not incur the overhead of opening, parsing
           and closing a new cursor for those stmts on subsequent use.

           - the session memory for PL/SQL modules without global state
           (such as types, stored-procedures) will not be freed and
           recreated.
  */
  procedure reset_package(p_free_all boolean default false);
--
  /*
      Equivalent to SQL "ALTER SESSION SET SQL_TRACE ...".
      Input arguments:
        sql_trace
          TRUE or FALSE/NULL.  Turns tracing on or off.
        p_waits
          collect wait events
        p_binds
          collect bind variables values
  */
  procedure set_sql_trace(sql_trace boolean, p_waits boolean default true, p_binds boolean default false);
--
  /*
      Turn On/Off tracing in session specified.
      Input arguments:
        sid
        serial
          session identifiers
        sql_trace
          TRUE or FALSE/NULL.  Turns tracing on or off.
        p_waits
          collect wait events
        p_binds
          collect bind variables values
  */
  procedure set_sql_trace_in_session(sid pls_integer, serial pls_integer, sql_trace boolean,
                                     p_waits boolean default true, p_binds boolean default false);
  /*
      Set boolean/integer session parameters in session specified.
      Input arguments:
        sid
        serial
          session identifiers
        par_name
          parameter name
        bool_val
          TRUE or FALSE.  Sets boolean parameter. NULL - look at the integer value.
        int_val
          not NULL.  Sets integer parameter. NULL - nothing to do
  */
  procedure set_param_in_session(sid pls_integer, serial pls_integer, par_name varchar2,
                                 bool_val boolean, int_val pls_integer);
--
  /*
      Equivalent to SQL "SET ROLE ...".
      Input arguments:
        role_cmd
          This text is appended to "set role " and then executed as SQL.
  */
  procedure set_role(role_cmd varchar2);
--
  /*
      Determine if the named role is enabled for this session.
      Input arguments:
        rolename
          Name of the role.
      Output arguments:
        is_role_enabled
          TRUE or FALSE depending on whether the role is enabled.
  */
  function is_role_enabled(rolename varchar2) return boolean;
--
  /*
      Equivalent to SQL "ALTER SESSION SET <nls_parameter> = <value>".
      Input arguments:
        param
          The NLS parameter. The parameter name must begin with 'NLS'.
        value
          The value to set the parameter to.  If the parameter is a
          text literal then it will need embedded single-quotes.  For
          example "set_nls('nls_date_format','''DD-MON-YY''')"
  */
  procedure set_nls(param varchar2, value varchar2);
--
  /*
      Compute a hash value for the given string.
      Input arguments:
        name  - The string to be hashed.
        base  - A base value for the returned hash value to start at.
        hash_size -  The desired size of the hash table.
        2147483647 is the maximum size.
      Returns:
        A hash value based on the input string.
        For example, to get a hash value on a string where the hash value
        should be between 1000 and 3047, use 1000 as the base value and
        2048 as the hash_size value.  Using a power of 2 for the hash_size
        parameter works best.
  */
  function hash_value( name varchar2,
                       base      number default 0,
                       hash_size number default 1073741824
                     ) return pls_integer deterministic;
  PRAGMA RESTRICT_REFERENCES(hash_value, WNDS, RNDS, WNPS, RNPS, TRUST);
  function hash_value2( name varchar2,
                        base      number default 0,
                        hash_size number default 1073741824
                      ) return pls_integer deterministic;
  PRAGMA RESTRICT_REFERENCES(hash_value, WNDS, RNDS, WNPS, RNPS, TRUST);
  /* Pack pls_integer into varchar2(4) */
  function Int_Hex(p_idx pls_integer) return varchar2 deterministic;
  PRAGMA RESTRICT_REFERENCES(Int_Hex, WNDS, RNDS, WNPS, RNPS, TRUST);
  /* Unpack varchar2(4) to pls_integer */
  function Hex_Int(p_hex varchar2) return pls_integer deterministic;
  PRAGMA RESTRICT_REFERENCES(Hex_Int, WNDS, RNDS, WNPS, RNPS, TRUST);
  /* Convert string to HEX-string (each char from p_char converted into 2-char HEX representation) */
  function Char_Hex(p_char varchar2) return varchar2 deterministic;
  PRAGMA RESTRICT_REFERENCES(Char_Hex, WNDS, RNDS, WNPS, RNPS, TRUST);
  /* Convert HEX-string to string (2-char HEX representation in p_hex conveted into single char) */
  function Hex_Char(p_hex varchar2) return varchar2 deterministic;
  PRAGMA RESTRICT_REFERENCES(Hex_Char, WNDS, RNDS, WNPS, RNPS, TRUST);
  /* Convert string to HEX-string (each char from p_str converted into 2-char HEX representation) */
  function Str_Hex(p_str varchar2) return varchar2 deterministic;
  PRAGMA RESTRICT_REFERENCES(Str_Hex, WNDS, RNDS, WNPS, RNPS, TRUST);
  /* Convert string to HEX-string (with encoding) */
  function Str_Hex2(p_str varchar2, out_text pls_integer) return varchar2 deterministic;
  PRAGMA RESTRICT_REFERENCES(Str_Hex, WNDS, RNDS, WNPS, RNPS, TRUST);
  /* Convert HEX-string to string (2-char HEX representation in p_str conveted into single char) */
  function Hex_Str(p_str varchar2) return varchar2 deterministic;
  PRAGMA RESTRICT_REFERENCES(Hex_Str, WNDS, RNDS, WNPS, RNPS, TRUST);
  /* Convert HEX-string to string (with decoding) */
  function Hex_Str2(p_str varchar2, in_text pls_integer) return varchar2 deterministic;
  PRAGMA RESTRICT_REFERENCES(Hex_Str, WNDS, RNDS, WNPS, RNPS, TRUST);
  /* Convert string into raw (one to one conversion) */
  function Str_Raw(p_str varchar2) return raw deterministic;
  PRAGMA RESTRICT_REFERENCES(Str_Raw, WNDS, RNDS, WNPS, RNPS, TRUST);
  /* Convert string into raw (with encoding) */
  function Str_Raw2(p_str varchar2, out_text pls_integer) return raw deterministic;
  PRAGMA RESTRICT_REFERENCES(Str_Raw, WNDS, RNDS, WNPS, RNPS, TRUST);
  /* Convert raw into string (one to one conversion) */
  function Raw_Str(p_raw raw) return varchar2 deterministic;
  PRAGMA RESTRICT_REFERENCES(Raw_Str, WNDS, RNDS, WNPS, RNPS, TRUST);
  /* Convert raw into string (with decoding) */
  function Raw_Str2(p_raw raw, in_text pls_integer) return varchar2 deterministic;
  PRAGMA RESTRICT_REFERENCES(Raw_Str, WNDS, RNDS, WNPS, RNPS, TRUST);
--
  /* Set random seed for evaluation random numbers */
  procedure Randomize(p_seed number default null);
  /* Random numbers generator between 0 and p_base */
  function  Random ( p_base number default 1 ) return number;
  /*
     Evaluate pls_integer values from positive numbers (useful for indexing ID values).
     1) p_num in 0..2147483647 - returns p_num (0..2147483647)
     2) p_num in 2147483648..4294967294  - returns 2147483647-p_num (-1..-2147483647)
     3) p_num > 4294967294 return mod(p_num,4294967295) converted through 1),2) (-2147483647..2147483647)
  */
  function Hash_Id( p_num  number) return pls_integer deterministic;
  PRAGMA RESTRICT_REFERENCES(Hash_Id, WNDS, RNDS, WNPS, RNPS, TRUST);
  /*
     Evaluate pls_integer values from String values (Overloaded for indexing string ID values).
     Simply returns hash value (range 0..2147483647)
  */
  function Hash_Id( p_str  varchar2) return pls_integer deterministic;
  PRAGMA RESTRICT_REFERENCES(Hash_Id, WNDS, RNDS, WNPS, RNPS, TRUST);
  function Hash_Id2( p_str  varchar2) return pls_integer deterministic;
  PRAGMA RESTRICT_REFERENCES(Hash_Id, WNDS, RNDS, WNPS, RNPS, TRUST);
--
  /*
     Open ref cursor for dynamic text in p_select
     If p_raise is true then exception raised if error occured
     otherwise returns true if no errors, returns false if errors present
  */
  function  open_cursor( p_cursor in out nocopy ref_cursor,
                         p_select varchar2,
                         p_raise  boolean  default TRUE,
                         p_vars   pls_integer default NULL,
                         p_value1 varchar2 default NULL,
                         p_value2 varchar2 default NULL,
                         p_value3 varchar2 default NULL,
                         p_value4 varchar2 default NULL,
                         p_value5 varchar2 default NULL
                       ) return boolean;
--
  function concatenate_list(p_cursor in sys_refcursor, p_divider in varchar2) return varchar2;
  function local_transaction_id( create_transaction boolean DEFAULT false) return varchar2;
  --
  /*
     Recall regexp_* functions from standard
  */
  function regexp_replace(source_string Varchar2,
                          pattern Varchar2,
                          replace_string Varchar2 DEFAULT null,
                          position Number DEFAULT 1, 
                          occurrence Number DEFAULT 0,
                          match_parameter Varchar2 DEFAULT null) return varchar2;
  function regexp_count(source_string Varchar2,
                        pattern Varchar2,
                        position Number DEFAULT 1,
                        match_parameter Varchar2 DEFAULT null) return number;
  function regexp_instr(source_string Varchar2,
                        pattern Varchar2,
                        position Number DEFAULT 1,
                        occurrence Number DEFAULT 1,
                        return_option Number DEFAULT 0,
                        match_parameter Varchar2 DEFAULT null,
                        subexpr Number DEFAULT 0) return number;
  function regexp_substr(source_string Varchar2,
                         pattern Varchar2,
                         position Number DEFAULT 1,
                         occurrence Number DEFAULT 1,
                         match_parameter Varchar2 DEFAULT null,
                         subexpr Number DEFAULT 0) return varchar2;
  function regexp_like(source_string Varchar2,
                       pattern Varchar2,
                       match_parameter Varchar2 DEFAULT null) return Boolean;
  --
  function split_string_to_array(
    p_input_string varchar2,
    p_separators   varchar2
  ) return type_string_table;
  --
  function iif(
    condition         boolean,
    output_when_true  varchar2,
    output_when_false varchar2
  ) return varchar2;
  
  function iif(
    condition         boolean,
    output_when_true  pls_integer,
    output_when_false pls_integer
  ) return pls_integer;
  
  /* Заменяет placeholder'ы вида {1}, {2} и т.д. в text на значения p1, p2 и т.д.
     Также заменяет \n и \t в text на chr(10) и chr(9), соответственно*/
  function str_format(
    text varchar2, 
    p1   varchar2 default NULL,
    p2   varchar2 default NULL,
    p3   varchar2 default NULL,
    p4   varchar2 default NULL,
    p5   varchar2 default NULL,
    p6   varchar2 default NULL,
    p7   varchar2 default NULL,
    p8   varchar2 default NULL
  ) return varchar2;
  
END UTILS;
/
show errors
